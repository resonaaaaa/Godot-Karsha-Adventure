extends Area2D


func _ready() -> void:
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if not body.is_shield_active:
			body.on_thorns_hit()
		else:
			body.enter_ladder(self)

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.exit_ladder(self)
