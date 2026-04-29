extends Node

@export var level_paths: PackedStringArray = [
	"res://Level1/Level1.tscn",
	"res://Level2/level2.tscn"
]
@export var loading_scene_path := "res://loading.tscn"

var current_index := 0

func _ready() -> void:
	# 等待主场景加载完毕后，接管当前关卡
	call_deferred("_init_current_scene")
	# 监控所有后续加入的场景节点，防止被HUD reload后失去连接
	get_tree().node_added.connect(_on_node_added)

func _on_node_added(node: Node) -> void:
	if node == get_tree().current_scene:
		_wire_level(node)
	elif node.is_in_group("level") or node.has_signal("level_completed"):
		_wire_level(node)

func _init_current_scene() -> void:
	var scene = get_tree().current_scene
	if scene != null:
		_wire_level(scene)
		# 匹配当前场景是在哪个索引
		for i in range(level_paths.size()):
			if level_paths[i] == scene.scene_file_path:
				current_index = i
				break

# 接收关卡完成信号
func _on_level_completed() -> void:
	var next_index := (current_index + 1) % level_paths.size()
	_load_level(next_index)

#加载关卡
func _load_level(index: int) -> void:
	current_index = index
	
	# 显示Loading界面
	var loading: Node = _show_loading()
	
	# 等待确保Loading渲染
	await get_tree().create_timer(0.2).timeout
	
	# 由Godot自行切换场景
	var err = get_tree().change_scene_to_file(level_paths[index])
	if err != OK:
		_hide_loading(loading)
		return
	
	#等待新场景进入树
	await get_tree().create_timer(0.5).timeout
	
	var new_scene = get_tree().current_scene
	if new_scene != null:
		_wire_level(new_scene)
		_reset_player_properties(new_scene)
	
	_hide_loading(loading)

# 连接新场景的关卡完成信号
func _wire_level(level: Node) -> void:
	if level.has_signal("level_completed") and not level.level_completed.is_connected(_on_level_completed):
		level.level_completed.connect(_on_level_completed)

#重置玩家属性
func _reset_player_properties(level: Node) -> void:
	var player := level.get_node_or_null("Player")
	if player == null:
		return
	if player.has_method("set_has_key"):
		player.set_has_key(false)
	else:
		player.set("has_key", false)

func _show_loading() -> Node:
	if loading_scene_path.is_empty():
		return Node.new()
	if not ResourceLoader.exists(loading_scene_path):
		return Node.new()
	var packed := load(loading_scene_path) as PackedScene
	if packed == null:
		return Node.new()
	var loading: Node = packed.instantiate()
	add_child(loading)
	return loading

func _hide_loading(loading: Node) -> void:
	if loading == null:
		return
	if not loading.is_inside_tree():
		return
	loading.queue_free()
