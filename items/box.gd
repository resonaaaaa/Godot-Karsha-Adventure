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


# Called every frame. 'delta' is the elapsed time since the previous frame.
