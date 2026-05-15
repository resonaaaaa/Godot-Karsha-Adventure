extends Node2D
signal level_completed

func _ready() -> void:
	if has_node("HUD"):
		$HUD.setup_level(1)

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


	
	
