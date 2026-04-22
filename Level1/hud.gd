extends CanvasLayer
signal new_game
@export var key_texture_empty: Texture
@export var key_texture_full: Texture
@export var PauseButton_pause:Texture2D
@export var PauseButton_play:Texture2D

func _ready() -> void:
	pass # Replace with function body.

func _process(delta: float) -> void:
	pass

func show_game_over():
	show_message("GAME OVER")
	await $MessageTimer.timeout
	get_tree().reload_current_scene()
	show_new_game()

func show_game_win():
	show_message("You Win!")
	await $MessageTimer.timeout
	get_tree().reload_current_scene()
	show_new_game()

func show_new_game():
	$Message.text = "Adventure"
	$Message.show()
	$StartButton.show()
	$KeyUI.texture = key_texture_empty
	
func show_message(text):
	$Message.text = text
	$Message.show()
	$MessageTimer.start()
	
func _on_start_button_pressed() -> void:
	# 隐藏按钮和消息
	$StartButton.hide()
	$Message.hide()
	new_game.emit()

func show_key_ui():
	$KeyUI.texture = key_texture_full
	
#检测暂停状态是否切换
func _on_pause_button_toggled(toggled_on: bool) -> void:
	var tree = get_tree()
	tree.paused = toggled_on
	if toggled_on:
		$PauseButton.icon = PauseButton_play
		$PauseMessage.show()
	else :
		$PauseButton.icon = PauseButton_pause
		$PauseMessage.hide()
