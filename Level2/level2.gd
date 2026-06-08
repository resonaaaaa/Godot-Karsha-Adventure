extends Node2D
signal level_completed

func _ready() -> void:
	AudioManager.play_bgm("res://asset/audio/BGM/level2.mp3")
	var tp_mater_from = get_node_or_null("items/tp/tp_mater_from")
	if tp_mater_from:
		tp_mater_from.body_entered.connect(_on_tp_mater_from_body_entered)
	var tp_quit_from = get_node_or_null("items/tp/tp_quit_from")
	if tp_quit_from:
		tp_quit_from.body_entered.connect(_on_tp_quit_from_body_entered)
	if has_node("HUD"):
		$HUD.setup_level(2)
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
	await get_tree().create_timer(2).timeout
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

func _on_tp_mater_from_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		AudioManager.play_bgm("res://asset/audio/BGM/magic_master.mp3")

func _on_tp_quit_from_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		AudioManager.play_bgm("res://asset/audio/BGM/level2.mp3")
	
	
