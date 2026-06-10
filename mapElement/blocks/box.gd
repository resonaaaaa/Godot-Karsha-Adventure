extends RigidBody2D

@export var push_mass := 2.0
@export var push_friction := 1.2  
@export var push_linear_damp := 2.5  # 线性阻尼
@export var push_angular_damp := 8.0  # 角阻尼，防止箱子被玩家推翻
@export var lock_box_rotation := false  # 锁定箱子旋转，防止被玩家推着转圈圈

var _material: PhysicsMaterial


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Use a dedicated material so friction tuning is local to the box.
	_material = PhysicsMaterial.new()
	_material.friction = push_friction
	_material.bounce = 0.0
	physics_material_override = _material

	mass = push_mass
	linear_damp = push_linear_damp
	angular_damp = push_angular_damp
	lock_rotation = lock_box_rotation

	# 用于 checkpoint 快照/恢复
	add_to_group("checkpoint_stateful")

func checkpoint_get_state() -> Dictionary:
	return {
		"position": position,
		"linear_velocity": linear_velocity if has_method("linear_velocity") else Vector2.ZERO,
		"angular_velocity": angular_velocity if has_method("angular_velocity") else 0.0
	}

func checkpoint_set_state(state: Dictionary) -> void:
	if state == null:
		return
	var pos = state.get("position", position)
	var lv = state.get("linear_velocity", Vector2.ZERO)
	var av = state.get("angular_velocity", 0.0)
	set_deferred("position", pos)
	linear_velocity = lv
	angular_velocity = av

