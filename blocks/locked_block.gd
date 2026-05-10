extends Node2D

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_key:
		queue_free()
	else :
		pass
