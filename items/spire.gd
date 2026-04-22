extends Node2D
signal hit

#玩家触碰了尖刺
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		hit.emit()
