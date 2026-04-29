extends CharacterBody2D

@export var speed = 250
@export var jump_velocity = -400
@export var has_key = false
@export var has_diamond = false
@export var push_force := 1800.0
@export var max_horizontal_speed := 450.0
@export var max_vertical_speed := 1200.0
@export var double_jump_enabled = false
@export var double_jump_window := 0.5
var gravity = 800
signal game_over
var is_dead = false
var can_move = false
var double_jump_used := false
@onready var double_jump_timer: Timer = $doubleJumpTimer

func _ready() -> void:
	if double_jump_window > 0.0:
		double_jump_timer.wait_time = double_jump_window
	double_jump_timer.one_shot = true
	double_jump_timer.stop()

#梯子相关参数
var on_ladder = false
var ladder_ref
var climb_speed = 200

# 水平速度和垂直速度全部交给 velocity
func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if not can_move:
		return
	#处理爬梯子的情况
	if on_ladder:
		process_climb(delta)
	else:
		process_normal(delta)

func process_normal(delta):
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
		double_jump_timer.stop()
		double_jump_used = false
		# 跳跃
		if Input.is_action_just_pressed("jump"):
			velocity.y = jump_velocity
			double_jump_used = false
			double_jump_timer.start()
	# 空中二段跳：第一段跳起后的窗口内可触发
	if (
		double_jump_enabled
		and not is_on_floor()
		and not double_jump_used
		and double_jump_timer.time_left > 0.0
		and Input.is_action_just_pressed("jump")
	):
		velocity.y = jump_velocity
		double_jump_used = true
		double_jump_timer.stop()

	# 根据velocity移动并处理碰撞
	move_and_slide()
	# Clamp velocity after collision response to avoid spike from physics feedback
	velocity.x = clamp(velocity.x, -max_horizontal_speed, max_horizontal_speed)
	velocity.y = clamp(velocity.y, -max_vertical_speed, max_vertical_speed)
	_apply_push_to_rigidbodies(delta)

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

func process_climb(delta):
	var horizontal = Input.get_axis("move_left", "move_right")
	var vertical = Input.get_axis("move_up", "move_down")
	velocity.x = horizontal * speed
	velocity.y = vertical * climb_speed
	
	if vertical != 0:
		if $AnimatedSprite2D.animation != "climb":
			$AnimatedSprite2D.play("climb")
		else:
			$AnimatedSprite2D.play()
	else:
		$AnimatedSprite2D.stop() # 停止动画，保持在当前帧

	
	move_and_slide()
	# Clamp velocity after collision response to avoid spike from physics feedback
	velocity.x = clamp(velocity.x, -max_horizontal_speed, max_horizontal_speed)
	velocity.y = clamp(velocity.y, -max_vertical_speed, max_vertical_speed)
	_apply_push_to_rigidbodies(delta)
	
func enter_ladder(ladder):
	on_ladder = true
	ladder_ref = ladder
	velocity = Vector2.ZERO
	if $AnimatedSprite2D.animation != "climb":
		$AnimatedSprite2D.play("climb")

func exit_ladder(ladder = null):
	if not on_ladder:
		return
	if ladder != null and ladder_ref != ladder:
		return
	on_ladder = false
	ladder_ref = null
	#离开梯子时保持水平位置不变，垂直位置稍微调整一下，避免再次触发梯子碰撞
	position.y += 5

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

func on_spire_hit(spire: Node2D) -> void:
	if not is_in_group("player"):
		return
	player_dead()

func _apply_push_to_rigidbodies(delta: float) -> void:
	var slide_count = get_slide_collision_count()
	for i in range(slide_count):
		var collision = get_slide_collision(i)
		var body = collision.get_collider()
		if body is RigidBody2D:
			var input_dir = Input.get_axis("move_left", "move_right")
			if input_dir == 0.0:
				continue
			# Avoid pushing when standing on top of the body
			if collision.get_normal().y < -0.6:
				continue
			var push_dir = Vector2(sign(input_dir), 0.0)
			#施加冲力
			body.apply_central_impulse(push_dir * push_force * delta)

func on_platform_move(movement: Vector2) -> void:
	position += movement
	
	
