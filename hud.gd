extends CanvasLayer
signal new_game

func _ready() -> void:
	pass # Replace with function body.

func _process(delta: float) -> void:
	pass

func show_game_over():
	show_message("GAME OVER")
	await $MessageTimer.timeout
	

func show_new_game():
	$Message.text = "Adventure"
	$Message.show()
	$StartButton.show()
	
func show_message(text):
	$Message.text = text
	$Message.show()
	$MessageTimer.start()
	
func _on_start_button_pressed() -> void:
	# 隐藏按钮和消息
	$StartButton.hide()
	$Message.hide()
	new_game.emit()
	
