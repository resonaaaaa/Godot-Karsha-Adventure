extends Node2D

#玩家触碰了尖刺
func _on_body_entered(body: Node2D) -> void:
	if body.has_method("on_spire_hit"):
		body.on_spire_hit(self)
