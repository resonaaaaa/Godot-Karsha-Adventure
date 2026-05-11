extends CharacterBody2D

@export var speed = 250
@export var jump_velocity = -400
var gravity = 800
signal game_over
var is_dead = false
var can_move = false
#道具相关
@export var has_key_red = false
@export var has_key_green = false
@export var has_diamond = false
#推箱子相关
@export var push_force := 1800.0
#速度锁
@export var max_horizontal_speed := 450.0
@export var max_vertical_speed := 1200.0
#二段跳相关
@export var double_jump_enabled = false
@export var double_jump_window := 0.5
var double_jump_used := false
#攻击相关
var is_attacking := false
var attack_facing := 1
@export var fireball_scene: PackedScene = preload("res://items/fireball.tscn")
#梯子相关参数
var on_ladder = false
var ladder_ref
var climb_speed = 200
#魔法相关
@export var red_gem_magic_unlocked = false

@onready var double_jump_timer: Timer = $doubleJumpTimer
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var tilemap_layers: Array[Node] = []

func _ready() -> void:
	if double_jump_window > 0.0:
		double_jump_timer.wait_time = double_jump_window
	double_jump_timer.one_shot = true
	double_jump_timer.stop()
	animated_sprite.animation = "stay"
	animated_sprite.animation_finished.connect(_on_animation_finished)
	call_deferred("_cache_tilemap_layers")

func _cache_tilemap_layers() -> void:
	if get_tree() and get_tree().current_scene:
		tilemap_layers = get_tree().current_scene.find_children("*", "TileMapLayer", true, false)
		var tm = get_tree().current_scene.find_children("*", "TileMap", true, false)
		tilemap_layers.append_array(tm)

#检查玩家所在位置是否有水，如果有则触发死亡
func _check_water_tiles() -> void:
	for layer in tilemap_layers:
		var local_pos = layer.to_local(global_position)
		var map_pos = layer.local_to_map(local_pos)
		
		if layer.has_method("get_cell_tile_data"):
			
			var tile_data: TileData
			if layer is TileMapLayer:
				tile_data = layer.get_cell_tile_data(map_pos)
			else:
				tile_data = layer.get_cell_tile_data(0, map_pos) # 默认检查第0层

			if tile_data:
				var is_water = tile_data.get_custom_data("water")
				if is_water:
					player_dead()
					return

func start(pos):
	position = pos
	is_dead = false
	can_move = true
	set_physics_process(true)
	show()



# 水平速度和垂直速度全部交给 velocity
func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if not can_move:
		return
		
	_check_water_tiles()
	if is_dead:
		return
		
	#处理爬梯子的情况
	if on_ladder:
		process_climb(delta)
	else:
		process_normal(delta)

func process_normal(delta):
	if is_attacking:
		velocity.x = 0
		if not is_on_floor():
			velocity.y += gravity * delta
		else:
			velocity.y = 0
		move_and_slide()
		velocity.x = clamp(velocity.x, -max_horizontal_speed, max_horizontal_speed)
		velocity.y = clamp(velocity.y, -max_vertical_speed, max_vertical_speed)
		_apply_push_to_rigidbodies(delta)
		return

	var target_animation = "stay"
	# direction：-1左，1右，0静止
	var direction = 0

	if Input.is_action_pressed("move_left"):
		direction -= 1
	if Input.is_action_pressed("move_right"):
		direction += 1

	if Input.is_action_just_pressed("attack"):
		if not is_attacking and shoot_fireball():
			return

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
		#$doubleJumpParticles.global_position = global_position
		$doubleJumpParticles.emitting = true

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
		animated_sprite.flip_v = false
		animated_sprite.flip_h = direction < 0
	if animated_sprite.animation != target_animation:
		animated_sprite.play(target_animation)

func process_climb(delta):
	var horizontal = Input.get_axis("move_left", "move_right")
	var vertical = Input.get_axis("move_up", "move_down")
	velocity.x = horizontal * speed
	velocity.y = vertical * climb_speed
	if Input.is_action_just_pressed("attack"):
		if not is_attacking and shoot_fireball():
			return
	
	if vertical != 0:
		if animated_sprite.animation != "climb":
			animated_sprite.play("climb")
		else:
			animated_sprite.play()
	else:
		animated_sprite.stop() # 停止动画，保持在当前帧

	
	move_and_slide()
	#速度锁
	velocity.x = clamp(velocity.x, -max_horizontal_speed, max_horizontal_speed)
	velocity.y = clamp(velocity.y, -max_vertical_speed, max_vertical_speed)
	_apply_push_to_rigidbodies(delta)
	
func enter_ladder(ladder):
	on_ladder = true
	ladder_ref = ladder
	velocity = Vector2.ZERO
	if animated_sprite.animation != "climb":
		animated_sprite.play("climb")

func exit_ladder(ladder = null):
	if not on_ladder:
		return
	if ladder != null and ladder_ref != ladder:
		return
	on_ladder = false
	ladder_ref = null
	#离开梯子时保持水平位置不变，垂直位置稍微调整一下，避免再次触发梯子碰撞
	position.y += 5

func set_has_key_red(val:bool):
	has_key_red = val

func set_has_key_green(val:bool):
	has_key_green = val
	
func on_spire_hit(spire: Node2D) -> void:
	if not is_in_group("player"):
		return
	player_dead()

func player_dead():
	if is_dead:
		return
	is_dead = true
	can_move = false
	set_physics_process(false)
	animated_sprite.play("hurt")
	await get_tree().create_timer(1).timeout
	game_over.emit()	


#跳跃平台相关
func apply_jump_boost(val):
	jump_velocity += val

func remove_jump_boost(val):
	jump_velocity -= val

func set_has_diamond(val:bool):
	has_diamond = val



#发射火球相关

#发射火球，返回是否成功发射
func shoot_fireball() -> bool:
	if red_gem_magic_unlocked == false:
		return false

	#在梯子上禁用火球发射
	if on_ladder:
		return false
	if is_attacking:
		return false
	if fireball_scene == null:
		return false
	is_attacking = true
	attack_facing = -1 if animated_sprite.flip_h else 1
	animated_sprite.play("shooting_fireball")
	return true

#实例化火球，设置其方向和位置
func _spawn_fireball() -> void:
	if fireball_scene == null:
		return
	var fireball = fireball_scene.instantiate()
	fireball.global_position = global_position + Vector2(attack_facing * 20.0, -6.0)	
	if fireball.has_method("set_direction"):
		fireball.set_direction(Vector2(attack_facing, 0.0))
	get_tree().current_scene.add_child(fireball)

func _on_animation_finished() -> void:
	if animated_sprite.animation != "shooting_fireball":
		return
	if not is_attacking:
		return
	is_attacking = false
	_spawn_fireball()
	


#推箱子相关

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
	
