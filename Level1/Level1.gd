extends Node2D
signal level_completed

func _ready() -> void:
	if has_node("HUD"):
		$HUD.setup_level(1)
		_connect_crystal_signals()

func game_over():
	$HUD.show_game_over()
	$Player.hide()
	$Player.set_physics_process(false)

func game_win():
	$HUD.show_game_win()
	$Player.hide()
	$Player.set_physics_process(false)
	await get_tree().create_timer(1.5).timeout
	level_completed.emit()

func _on_hud_new_game() -> void:
	$Player.start($StartPosition.position)


func _connect_crystal_signals() -> void:
	var root = get_tree().current_scene
	if not root:
		return
	_scan_and_connect(root)


func _scan_and_connect(node: Node) -> void:
	if not node:
		return
	var sc = null
	if node.get_script() != null:
		sc = node.get_script()
	if sc and sc.resource_path and sc.resource_path.ends_with("crystal_flower.gd"):
		if not node.is_connected("collected", self, "_on_flower_collected"):
			node.connect("collected", Callable(self, "_on_flower_collected"))
		# if the flower is already collected (initial_empty), HUD is already empty by default
	for child in node.get_children():
		_scan_and_connect(child)


func _on_flower_collected(flower_type: String) -> void:
	if not has_node("HUD"):
		return
	if flower_type == "red":
		$HUD.show_red_flower_ui(true)
	elif flower_type == "blue":
		$HUD.show_blue_flower_ui(true)
	
	
