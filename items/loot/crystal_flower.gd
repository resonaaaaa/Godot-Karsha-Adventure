extends Area2D
signal collected_red
signal collected_blue

@export_enum("red", "blue") var flower_type: String = "red"
@export var flower_texture_red: Texture2D
@export var flower_texture_blue: Texture2D
@export var flower_texture_empty: Texture2D
@export var initial_empty: bool = false

var collected: bool = false

func _ready() -> void:
	if initial_empty:
		$Sprite2D.texture = flower_texture_empty
		$Sprite2D.position += Vector2(0, 12)
		collected = true
		return

	match flower_type:
		"red":
			$Sprite2D.texture = flower_texture_red
		"blue":
			$Sprite2D.texture = flower_texture_blue

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	if collected:
		return

	match flower_type:
		"red":
			emit_signal("collected_red")
			collected = true
			$Sprite2D.texture = flower_texture_empty
			$Sprite2D.position += Vector2(0, 12)
			set_deferred("monitoring", false)
			body.set_has_red_flower(true)
		"blue":
			emit_signal("collected_blue")
			collected = true
			$Sprite2D.texture = flower_texture_empty
			$Sprite2D.position += Vector2(0, 12)
			set_deferred("monitoring", false)
			body.set_has_blue_flower(true)
		
