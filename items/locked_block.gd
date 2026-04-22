extends Node2D
signal game_win

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_key:
		queue_free()
		game_win.emit()
	else :
		pass
