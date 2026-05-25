extends Area2D
signal collected_red
signal collected_blue

@export_enum("red", "blue") var flower_type: String = "red"
@export var flower_texture_red: Texture2D
@export var flower_texture_blue: Texture2D
@export var flower_texture_empty: Texture2D
@export var initial_empty: bool = false

var collected: bool = false
var sprite_base_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	add_to_group("checkpoint_stateful")
	sprite_base_position = $Sprite2D.position
	collected = initial_empty
	_apply_visual_state(collected)

# 为花朵应用视觉状态，collected 参数为 true 时显示空花朵并禁用监测，false 时根据类型显示对应花朵并启用监测
func _apply_visual_state(is_collected: bool) -> void:
	if is_collected:
		$Sprite2D.texture = flower_texture_empty
		$Sprite2D.position = sprite_base_position + Vector2(0, 12)
		set_deferred("monitoring", false)
	else:
		match flower_type:
			"red":
				$Sprite2D.texture = flower_texture_red
			"blue":
				$Sprite2D.texture = flower_texture_blue
		$Sprite2D.position = sprite_base_position
		set_deferred("monitoring", true)

# 拾取
func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	if collected:
		return

	match flower_type:
		"red":
			emit_signal("collected_red")
			collected = true
			body.set_has_red_flower(true)
		"blue":
			emit_signal("collected_blue")
			collected = true
			body.set_has_blue_flower(true)
	_apply_visual_state(true)
	

func apply_collected_state() -> void:
	collected = true
	_apply_visual_state(true)

func checkpoint_get_state() -> Dictionary:
	return {"collected": collected, "position": position, "flower_type": flower_type}

func checkpoint_set_state(state: Dictionary) -> void:
	if state == null:
		return
	collected = state.get("collected", false)
	_apply_visual_state(collected)
		
