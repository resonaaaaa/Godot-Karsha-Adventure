extends Node

var last_checkpoint_position: Vector2 = Vector2.ZERO
var last_checkpoint_id: int = -1
var triggered_ids: Array = []
var has_checkpoint_flag: bool = false
var current_collected_paths: Array = []
var saved_collected_paths: Array = []
var saved_player_state: Dictionary = {}
var saved_task_state: Dictionary = {}
var snapshots: Dictionary = {}
var world_snapshot: Dictionary = {}

func register_checkpoint(id: int, pos: Vector2, player: Node = null, hud: Node = null) -> bool:
	# 首次触发任意 id 都允许；之后只允许按顺序触发（id == last_id + 1）
	if id in triggered_ids:
		return false
	if triggered_ids.is_empty():
		last_checkpoint_id = id
		last_checkpoint_position = pos
		triggered_ids.append(id)
		has_checkpoint_flag = true
		_capture_checkpoint_state(player, hud)
		snapshots[str(id)] = _build_snapshot(player, hud)
		world_snapshot = snapshots[str(id)]
		return true
	if id == last_checkpoint_id + 1:
		last_checkpoint_id = id
		last_checkpoint_position = pos
		triggered_ids.append(id)
		has_checkpoint_flag = true
		_capture_checkpoint_state(player, hud)
		snapshots[str(id)] = _build_snapshot(player, hud)
		world_snapshot = snapshots[str(id)]
		return true
	return false

func get_last_checkpoint_position() -> Vector2:
	return last_checkpoint_position

func has_checkpoint() -> bool:
	return has_checkpoint_flag

func record_collected(node: Node) -> void:
	if node == null:
		return
	if not node.is_inside_tree():
		return
	var path := node.get_path()
	# 采集状态现在从节点自身的 checkpoint_get_state() 中导出，
	# 因此这个记录函数不再主动维护全局列表以避免拾取后立即污染检查点快照。
	return

func set_task_state(key: String, value) -> void:
	saved_task_state[key] = value

func get_task_state(key: String, default_value = null):
	return saved_task_state.get(key, default_value)

func apply_checkpoint(player: Node, hud: Node, scene: Node) -> void:
	if not has_checkpoint_flag:
		return
	var snap = _get_active_snapshot()
	if snap != null:
		# 使用当前快照恢复世界，而不是旧的 saved_* 缓存
		_apply_snapshot(snap, player, hud, scene)
		return
	# 后备：兼容旧逻辑
	if player != null:
		_apply_player_state(player)
	if hud != null and hud.has_method("apply_player_state"):
		hud.apply_player_state(saved_player_state)
	if scene != null:
		_apply_collected(scene)

func _build_snapshot(player: Node, hud: Node) -> Dictionary:
	var snap: Dictionary = {}
	# 保存“当前世界此刻”的快照
	# player state
	if player != null:
		snap.player_state = _extract_player_state(player)
	# collected paths：从所有实现 checkpoint_get_state 的节点中派生
	var collected_paths:Array = []
	for node in get_tree().get_nodes_in_group("checkpoint_stateful"):
		if not node.is_inside_tree():
			continue
		if node.has_method("checkpoint_get_state"):
			var st = node.checkpoint_get_state()
			if typeof(st) == TYPE_DICTIONARY and st.get("collected", false):
				collected_paths.append(str(node.get_path()))
	snap.collected_paths = collected_paths
	# 记录所有实现 checkpoint_get_state 的节点
	snap.nodes = {}
	for node in get_tree().get_nodes_in_group("checkpoint_stateful"):
		if not node.is_inside_tree():
			continue
		var path = node.get_path()
		if node.has_method("checkpoint_get_state"):
			snap.nodes[str(path)] = node.checkpoint_get_state()
	return snap

func save_world_snapshot(player: Node = null, hud: Node = null, scene: Node = null) -> void:
	# 如果没有传入 player，尝试从场景中获取保证 player_state 写入快照
	var local_player = player
	if local_player == null and scene != null:
		local_player = scene.get_node_or_null("Player")
	world_snapshot = _build_snapshot(local_player, hud)
	if scene != null and world_snapshot.has("nodes"):
		# 保持当前世界快照与现状同步，方便后续恢复
		world_snapshot.scene_path = scene.get_path()

func save_event_checkpoint(player: Node = null, hud: Node = null, scene: Node = null, source_name: String = "") -> void:
	# 事件型检查点要同时刷新世界快照和玩家重生点
	# 这样事件完成后，死亡重试会回到该事件完成时的位置
	# 尽量确保 player_state 被捕获：若未提供 player，则从场景查找名为 "Player" 的节点
	var local_player = player
	if local_player == null and scene != null:
		local_player = scene.get_node_or_null("Player")
	if local_player != null and local_player is Node2D:
		last_checkpoint_position = local_player.global_position
	has_checkpoint_flag = true
	_capture_checkpoint_state(local_player, hud)
	world_snapshot = _build_snapshot(local_player, hud)
	if source_name != "":
		world_snapshot.source_name = source_name
		snapshots[source_name] = world_snapshot
	if scene != null:
		world_snapshot.scene_path = scene.get_path()

func _get_active_snapshot() -> Dictionary:
	if not world_snapshot.is_empty():
		return world_snapshot
	if snapshots.has(str(last_checkpoint_id)):
		return snapshots.get(str(last_checkpoint_id), null)
	return {}

func _apply_snapshot(snap: Dictionary, player: Node, hud: Node, scene: Node) -> void:
	if snap == null:
		return
	if player != null and snap.has("player_state"):
		_apply_player_state_from_dict(player, snap.player_state)
	if hud != null and hud.has_method("apply_player_state") and snap.has("player_state"):
		hud.apply_player_state(snap.player_state)
	if scene != null and snap.has("nodes"):
		for path in snap.nodes.keys():
			var node = scene.get_node_or_null(path)
			var state = snap.nodes[path]
			if node == null:
				continue
			if node.has_method("checkpoint_set_state"):
				node.checkpoint_set_state(state)
		# 恢复拾取物：先基于节点状态恢复（checkpoint_set_state），再对快照里标记为已拾取的路径调用 apply_collected_state
		if snap.has("collected_paths"):
			for p in snap.collected_paths:
				var n = scene.get_node_or_null(p)
				if n == null:
					continue
				if n.has_method("apply_collected_state"):
					n.apply_collected_state()
				else:
					n.queue_free()
		# 同步内存中的已拾取路径，保证后续 checkpoint/record 操作基于恢复后的状态
		if snap.has("collected_paths"):
			current_collected_paths = snap.collected_paths.duplicate()
		else:
			current_collected_paths.clear()

func _apply_player_state_from_dict(player: Node, state: Dictionary) -> void:
	if state == null or state.is_empty():
		return
	player.has_key_red = state.get("has_key_red", false)
	player.has_key_green = state.get("has_key_green", false)
	player.has_red_flower = state.get("has_red_flower", false)
	player.has_blue_flower = state.get("has_blue_flower", false)
	player.has_red_gem = state.get("has_red_gem", false)
	player.has_green_gem = state.get("has_green_gem", false)
	player.has_blue_gem = state.get("has_blue_gem", false)
	player.has_yellow_gem = state.get("has_yellow_gem", false)
	player.red_gem_magic_unlocked = state.get("red_gem_magic_unlocked", false)
	player.green_gem_magic_unlocked = state.get("green_gem_magic_unlocked", false)
	player.blue_gem_magic_unlocked = state.get("blue_gem_magic_unlocked", false)
	player.yellow_gem_magic_unlocked = state.get("yellow_gem_magic_unlocked", false)
	player.double_jump_enabled = state.get("double_jump_enabled", false)

func reset() -> void:
	last_checkpoint_position = Vector2.ZERO
	last_checkpoint_id = -1
	triggered_ids.clear()
	has_checkpoint_flag = false
	current_collected_paths.clear()
	saved_collected_paths.clear()
	saved_player_state.clear()
	saved_task_state.clear()

func _capture_checkpoint_state(player: Node, hud: Node) -> void:
	saved_collected_paths = current_collected_paths.duplicate()
	if player != null:
		saved_player_state = _extract_player_state(player)
	if hud != null and hud.has_method("apply_player_state"):
		hud.apply_player_state(saved_player_state)

func _extract_player_state(player: Node) -> Dictionary:
	return {
		"has_key_red": player.has_key_red,
		"has_key_green": player.has_key_green,
		"has_red_flower": player.has_red_flower,
		"has_blue_flower": player.has_blue_flower,
		"has_red_gem": player.has_red_gem,
		"has_green_gem": player.has_green_gem,
		"has_blue_gem": player.has_blue_gem,
		"has_yellow_gem": player.has_yellow_gem,
		"red_gem_magic_unlocked": player.red_gem_magic_unlocked,
		"green_gem_magic_unlocked": player.green_gem_magic_unlocked,
		"blue_gem_magic_unlocked": player.blue_gem_magic_unlocked,
		"yellow_gem_magic_unlocked": player.yellow_gem_magic_unlocked,
		"double_jump_enabled": player.double_jump_enabled
	}

func _apply_player_state(player: Node) -> void:
	if saved_player_state.is_empty():
		return
	player.has_key_red = saved_player_state.get("has_key_red", false)
	player.has_key_green = saved_player_state.get("has_key_green", false)
	player.has_red_flower = saved_player_state.get("has_red_flower", false)
	player.has_blue_flower = saved_player_state.get("has_blue_flower", false)
	player.has_red_gem = saved_player_state.get("has_red_gem", false)
	player.has_green_gem = saved_player_state.get("has_green_gem", false)
	player.has_blue_gem = saved_player_state.get("has_blue_gem", false)
	player.has_yellow_gem = saved_player_state.get("has_yellow_gem", false)
	player.red_gem_magic_unlocked = saved_player_state.get("red_gem_magic_unlocked", false)
	player.green_gem_magic_unlocked = saved_player_state.get("green_gem_magic_unlocked", false)
	player.blue_gem_magic_unlocked = saved_player_state.get("blue_gem_magic_unlocked", false)
	player.yellow_gem_magic_unlocked = saved_player_state.get("yellow_gem_magic_unlocked", false)
	player.double_jump_enabled = saved_player_state.get("double_jump_enabled", false)

func _apply_collected(scene: Node) -> void:
	for path in saved_collected_paths:
		var node := scene.get_node_or_null(path)
		if node == null:
			continue
		if node.has_method("apply_collected_state"):
			node.apply_collected_state()
		else:
			node.queue_free()
