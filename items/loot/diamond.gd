extends Area2D
signal get_diamond

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.set_has_diamond(true)
		queue_free()
		get_diamond.emit()
