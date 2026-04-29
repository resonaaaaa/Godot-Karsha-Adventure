extends CanvasLayer
signal new_game
@export var key_texture_empty: Texture
@export var key_texture_full: Texture

func _ready() -> void:
	$PauseMenu.hide()
	$PauseMessage.hide()
	$PauseButton.button_pressed = false

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("menu"):
		$PauseButton.button_pressed = not $PauseButton.button_pressed

func show_game_over():
	show_message("GAME OVER")
	await $MessageTimer.timeout
	get_tree().reload_current_scene()
	show_new_game()

func show_game_win():
	show_message("You Win!")


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
		$PauseMessage.show()
		$PauseMenu.popup_centered()
	else :
		$PauseMessage.hide()
		$PauseMenu.hide()

#隐藏菜单时同步恢复运行状态
func _on_pause_menu_popup_hide() -> void:
	if $PauseButton.button_pressed:
		$PauseButton.button_pressed = false
	get_tree().paused = false
	$PauseMessage.hide()

func _on_pause_button_mouse_entered() -> void:
	$PauseText.show()

func _on_pause_button_mouse_exited() -> void:
	$PauseText.hide()

#继续游戏
func _on_continue_button_pressed() -> void:
	get_tree().paused = false
	$PauseMessage.hide()
	$PauseMenu.hide()


func _on_restart_button_pressed() -> void:
	var tree = get_tree()
	if tree.paused:
		tree.paused = false
	$PauseButton.button_pressed = false
	$PauseMessage.hide()
	$PauseMenu.hide()
	$PauseText.hide()
	call_deferred("_reload_scene")

func _reload_scene() -> void:
	get_tree().reload_current_scene()
