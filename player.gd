extends CharacterBody2D

@export var speed = 250
@export var jump_velocity = -400
@export var has_key = false
@export var has_diamond = false
var gravity = 800
signal game_over
var is_dead = false
var can_move = false

# 水平速度和垂直速度全部交给 velocity
func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if not can_move:
		return
	var target_animation = "stay"
	# direction：-1左，1右，0静止
	var direction = 0

	if Input.is_action_pressed("move_left"):
		direction -= 1
	if Input.is_action_pressed("move_right"):
		direction += 1

	velocity.x = direction * speed

	# 重力
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0
		# 跳跃
		if Input.is_action_just_pressed("jump"):
			velocity.y = jump_velocity

	# 根据velocity移动并处理碰撞
	move_and_slide()

	if position.y > 2000:
		player_dead()
		return

	# 动画和翻转
	if direction != 0:
		target_animation = "right"
		$AnimatedSprite2D.flip_v = false
		$AnimatedSprite2D.flip_h = direction < 0
	if $AnimatedSprite2D.animation != target_animation:
		$AnimatedSprite2D.play(target_animation)

func set_has_key(val:bool):
	has_key = val
	
func player_dead():
	if is_dead:
		return
	is_dead = true
	can_move = false
	set_physics_process(false)
	$AnimatedSprite2D.play("hurt")
	await get_tree().create_timer(1).timeout
	game_over.emit()	
	
func apply_jump_boost(val):
	jump_velocity += val

func remove_jump_boost(val):
	jump_velocity -= val

func set_has_diamond(val:bool):
	has_diamond = val
	
func start(pos):
	position = pos
	is_dead = false
	can_move = true
	set_physics_process(true)
	show()

	
	
