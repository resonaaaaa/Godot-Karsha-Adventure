extends Node2D

@export var block_activated_work: Texture
@export var block_activated_wait: Texture
@export var block_inactive: Texture
@export var boost_val = -300
var jump_boost_active = false	
var block_is_active = false

func _ready() -> void:
	$Block/Sprite2D.texture = block_inactive

#玩家踩上传感器
func _on_sensor_body_entered(body: Node2D) -> void:
	if not block_is_active:
		return
	if jump_boost_active:
		return
	if body.is_in_group("player"):
		body.apply_jump_boost(boost_val)
		jump_boost_active = true
		$Block/Sprite2D.texture = block_activated_work

#玩家离开传感器
func _on_sensor_body_exited(body: Node2D) -> void:
	if not block_is_active:
		return
	if not jump_boost_active:
		return
	if body.is_in_group("player"):
		body.remove_jump_boost(boost_val)
		jump_boost_active = false
		$Block/Sprite2D.texture = block_activated_wait
		
func set_block_active():
	block_is_active = true
	$Block/Sprite2D.texture = block_activated_wait

func set_block_inactive():
	block_is_active = false
	$Block/Sprite2D.texture = block_inactive
	
