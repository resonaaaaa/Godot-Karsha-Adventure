extends Area2D

@export_enum("red", "blue", "green", "yellow") var gem_type: String = "red"
@export var gem_texture_red: Texture2D
@export var gem_texture_blue: Texture2D
@export var gem_texture_green: Texture2D
@export var gem_texture_yellow: Texture2D

func _ready() -> void:
	match gem_type:
		"red":
			$Sprite2D.texture = gem_texture_red
		"blue":
			$Sprite2D.texture = gem_texture_blue
		"green":
			$Sprite2D.texture = gem_texture_green
		"yellow":
			$Sprite2D.texture = gem_texture_yellow

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	match gem_type:
		"red":
			body.get_gem("red")
		"blue":
			body.get_gem("blue")
		"green":
			body.get_gem("green")
		"yellow":	
			body.get_gem("yellow")
	queue_free()
	
