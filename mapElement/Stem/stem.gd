extends Area2D

var texture_normal = preload("res://asset/TileSet/Other/plantStem_vertical.png")
var texture_1 = preload("res://asset/TileSet/Other/plantLeaves_1.png")
var texture_2 = preload("res://asset/TileSet/Other/plantLeaves_3.png")
var texture_3 = preload("res://asset/TileSet/Other/plantBottom_1.png")
var texture_4 = preload("res://asset/TileSet/Other/plantBottom_2.png")

@onready var textures = [texture_normal, texture_1, texture_2, texture_3, texture_4]

func _ready() -> void:
	$Sprite2D.texture = textures[randi() % textures.size()]

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.enter_ladder(self)

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.exit_ladder(self)
