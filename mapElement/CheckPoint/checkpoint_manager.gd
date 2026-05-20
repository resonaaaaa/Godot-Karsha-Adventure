extends Node

var last_checkpoint_position: Vector2 = Vector2.ZERO
var last_checkpoint_id: int = -1
var triggered_ids: Array = []
var has_checkpoint_flag: bool = false
var current_collected_paths: Array[String] = []
var saved_collected_paths: Array[String] = []
var saved_player_state: Dictionary = {}
var saved_task_state: Dictionary = {}
var snapshots: Dictionary = {}

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
		return true
	if id == last_checkpoint_id + 1:
		last_checkpoint_id = id
		last_checkpoint_position = pos
		triggered_ids.append(id)
		has_checkpoint_flag = true
		_capture_checkpoint_state(player, hud)
		snapshots[str(id)] = _build_snapshot(player, hud)
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
	if not current_collected_paths.has(path):
		current_collected_paths.append(path)

func set_task_state(key: String, value) -> void:
	saved_task_state[key] = value

func get_task_state(key: String, default_value = null):
	return saved_task_state.get(key, default_value)

func apply_checkpoint(player: Node, hud: Node, scene: Node) -> void:
	if not has_checkpoint_flag:
		return
	# 优先使用为该 checkpoint 保存的完整 snapshot
	var snap = snapshots.get(str(last_checkpoint_id), null)
	if snap != null:
		if player != null and snap.has("player_state"):
			_apply_player_state(player)
		if hud != null and hud.has_method("apply_player_state") and snap.has("player_state"):
			hud.apply_player_state(snap.player_state)
		# 恢复各类状态节点
		if scene != null and snap.has("nodes"):
			for path in snap.nodes.keys():
				var node = scene.get_node_or_null(path)
				var state = snap.nodes[path]
				if node == null:
					# 节点被移除时，目前不自动重建；可扩展为通过 PackedScene 重建
					continue
				if node.has_method("checkpoint_set_state"):
					node.checkpoint_set_state(state)
			# 恢复被记录为已拾取的节点
			if snap.has("collected_paths"):
				for p in snap.collected_paths:
					var n = scene.get_node_or_null(p)
					if n == null:
						continue
					if n.has_method("apply_collected_state"):
						n.apply_collected_state()
					else:
						n.queue_free()
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
	# player state
	if player != null:
		snap.player_state = _extract_player_state(player)
	# collected paths
	snap.collected_paths = saved_collected_paths.duplicate()
	# 记录所有实现 checkpoint_get_state 的节点
	snap.nodes = {}
	for node in get_tree().get_nodes_in_group("checkpoint_stateful"):
		if not node.is_inside_tree():
			continue
		var path = node.get_path()
		if node.has_method("checkpoint_get_state"):
			snap.nodes[str(path)] = node.checkpoint_get_state()
	return snap

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
