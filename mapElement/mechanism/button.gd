extends Node2D
var pressed := false
signal button_pressed
signal button_released

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("checkpoint_stateful")

func _set_pressed_state(p: bool) -> void:
	pressed = p
	if pressed:
		$Block/ButtonReleased.hide()
		$Block/ButtonPressed.show()
	else:
		$Block/ButtonPressed.hide()
		$Block/ButtonReleased.show()

func checkpoint_get_state() -> Dictionary:
	return {"pressed": pressed}

func checkpoint_set_state(state: Dictionary) -> void:
	if state == null:
		return
	var p = state.get("pressed", false)
	_set_pressed_state(p)
	# 恢复时触发相应信号，保证连锁反应一致
	if p:
		button_pressed.emit()
	else:
		button_released.emit()


func _on_sensor_body_entered(body: Node2D) -> void:
	if (body.is_in_group("player") or body.is_in_group("box")) and not pressed:
		pressed = true
		$Block/ButtonReleased.hide()
		$Block/ButtonPressed.show()
		button_pressed.emit()


func _on_sensor_body_exited(body: Node2D) -> void:
	if (body.is_in_group("player") or body.is_in_group("box")) and pressed:
		pressed = false
		await get_tree().create_timer(0.3).timeout 
		$Block/ButtonPressed.hide()
		$Block/ButtonReleased.show()
		button_released.emit()
