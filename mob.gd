extends Area2D

@export_enum("fly", "walk", "swim") var mob_type: String = "walk"
@export var fly_speed := 150.0
@export var walk_speed := 100.0
@export var swim_speed := 50.0
@export var move_distance := 150.0

var speed := 0.0
var start_x := 0.0
var direction := 1
var is_dead := false

func _ready() -> void:
	start_x = position.x
	$AnimatedSprite2D.play(mob_type)
	
	$ColliShapeFly.disabled = true
	$ColliShapeWalk.disabled = true
	$ColliShapeSwim.disabled = true
	$Dead_fly.hide()
	$Dead_walk.hide()
	$Dead_swim.hide()
	
	if mob_type == "fly":
		speed = fly_speed
		$ColliShapeFly.disabled = false
	elif mob_type == "walk":
		speed = walk_speed
		$ColliShapeWalk.disabled = false
	elif mob_type == "swim":
		speed = swim_speed
		$ColliShapeSwim.disabled = false
		
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if is_dead:
		return
		
	position.x += direction * speed * delta
	
	if direction == 1 and position.x > start_x + move_distance:
		direction = -1
	elif direction == -1 and position.x < start_x - move_distance:
		direction = 1
		
	if direction == -1:
		$AnimatedSprite2D.flip_h = true
	else:
		$AnimatedSprite2D.flip_h = false

func _on_body_entered(body: Node2D) -> void:
	if is_dead:
		return
	if body.is_in_group("player"):
		# 判断玩家是否踩在头上：玩家正在下落，且位置在敌人中心以上
		if body.velocity.y > 0 and body.global_position.y < global_position.y - 10:
			die()
			# 给玩家一个弹跳的反馈
			body.velocity.y = body.jump_velocity * 0.8
		else:
			if body.has_method("player_dead"):
				body.player_dead()

func die() -> void:
	is_dead = true
	$AnimatedSprite2D.hide()
	$ColliShapeFly.set_deferred("disabled", true)
	$ColliShapeWalk.set_deferred("disabled", true)
	$ColliShapeSwim.set_deferred("disabled", true)
	
	if mob_type == "fly":
		$Dead_fly.show()
	elif mob_type == "walk":
		$Dead_walk.show()
	elif mob_type == "swim":
		$Dead_swim.show()
		
	await get_tree().create_timer(1.0).timeout
	if is_inside_tree():
		queue_free()
