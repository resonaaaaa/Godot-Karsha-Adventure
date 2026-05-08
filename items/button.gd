extends Node2D
var pressed := false
signal button_pressed
signal button_released

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


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
