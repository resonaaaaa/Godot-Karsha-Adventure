extends CharacterBody2D

var speed = 250
var jump_velocity = -400
var gravity = 800
signal game_over

# 水平速度和垂直速度全部交给 velocity
func _physics_process(delta: float) -> void:
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

	if position.y > 1000:
		game_over.emit()

	# 动画和翻转
	if direction != 0:
		target_animation = "right"
		$AnimatedSprite2D.flip_v = false
		$AnimatedSprite2D.flip_h = direction < 0
	if $AnimatedSprite2D.animation != target_animation:
		$AnimatedSprite2D.play(target_animation)
