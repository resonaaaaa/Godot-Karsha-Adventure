extends Node2D
signal level_completed

func _ready() -> void:
	AudioManager.play_bgm("res://asset/audio/BGM/level4.mp3")
	if has_node("HUD"):
		$HUD.setup_level(4)
		if not $HUD.retry.is_connected(Callable(self, "_on_hud_retry")):
			$HUD.retry.connect(Callable(self, "_on_hud_retry"))

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
	var mgr = get_tree().current_scene.get_node_or_null("CheckPointManager")
	if mgr:
		mgr.reset()
	$Player.start($StartPosition.position)


func _on_hud_retry() -> void:
	var mgr = get_tree().current_scene.get_node_or_null("CheckPointManager")
	if mgr and mgr.has_checkpoint():
		$Player.start(mgr.get_last_checkpoint_position())
		mgr.apply_checkpoint($Player, $HUD, get_tree().current_scene)
	else:
		$Player.start($StartPosition.position)


	
	
