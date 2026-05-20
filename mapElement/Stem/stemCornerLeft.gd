extends Area2D

var _texture = preload("res://asset/TileSet/Other/plantStem_cornerLeft.png")

func _ready() -> void:
	$Sprite2D.texture = _texture
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.enter_ladder(self)

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.exit_ladder(self)
