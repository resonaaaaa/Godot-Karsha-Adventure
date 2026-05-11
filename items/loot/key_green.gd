extends Area2D
signal get_key_green

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.set_has_key_green(true)
		queue_free()
		get_key_green.emit()
