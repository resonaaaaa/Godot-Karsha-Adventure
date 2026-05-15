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
@export var has_red_flower = false
@export var has_blue_flower = false
#宝石相关
var has_red_gem = false
var has_green_gem = false
var has_blue_gem = false
var has_yellow_gem = false
#推箱子相关
@export var push_force := 1800.0
#速度锁
@export var max_horizontal_speed := 450.0
@export var max_vertical_speed := 1200.0
#二段跳相关
var double_jump_enabled = false
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
@export var green_gem_magic_unlocked = false
@export var blue_gem_magic_unlocked = false
@export var yellow_gem_magic_unlocked = false
#缓降魔法相关
var slow_descent_timer := 0.0
var slow_descent_cooldown_timer := 0.0
var max_slow_descent_time := 3.0
var max_slow_descent_cooldown := 8.0
#护盾相关
var is_shield_active: bool = false
var shield_timer: float = 0.0
var shield_cooldown_timer: float = 0.0
var max_shield_time: float = 5.0
var max_shield_cooldown: float = 3.0

@onready var double_jump_timer: Timer = $doubleJumpTimer
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var cooldown_msg: Label = $CooldownMessage

var tilemap_layers: Array[Node] = []

func _ready() -> void:
	if double_jump_window > 0.0:
		double_jump_timer.wait_time = double_jump_window
	double_jump_timer.one_shot = true
	double_jump_timer.stop()
	if blue_gem_magic_unlocked:
		double_jump_enabled = true
	animated_sprite.animation = "stay"
	animated_sprite.animation_finished.connect(_on_animation_finished)
	call_deferred("_cache_tilemap_layers")
	$MagicShieldParticles.emitting = false

func _process(delta: float) -> void:
	if slow_descent_cooldown_timer > 0:
		slow_descent_cooldown_timer -= delta
	
	if green_gem_magic_unlocked and Input.is_action_just_pressed("slow_descent"):
		if slow_descent_cooldown_timer > 0:
			_show_cooldown_message()
			
	if shield_cooldown_timer > 0:
		shield_cooldown_timer -= delta
		
	if is_shield_active:
		shield_timer -= delta
		if shield_timer <= 0:
			is_shield_active = false
			$MagicShieldParticles.emitting = false
			shield_cooldown_timer = max_shield_cooldown

	if yellow_gem_magic_unlocked and Input.is_action_just_pressed("shield"):
		if shield_cooldown_timer > 0:
			_show_cooldown_message()
		elif not is_shield_active:
			is_shield_active = true
			shield_timer = max_shield_time
			$MagicShieldParticles.emitting = true

var cooldown_tween: Tween

func _show_cooldown_message() -> void:
	cooldown_msg.visible = true
	cooldown_msg.modulate.a = 1.0
	if cooldown_tween:
		cooldown_tween.kill()
	cooldown_tween = create_tween()
	cooldown_tween.tween_interval(1.5)
	cooldown_tween.tween_property(cooldown_msg, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_LINEAR)

#进入场景时初始化玩家状态
func start(pos):
	position = pos
	is_dead = false
	can_move = true
	set_physics_process(true)
	show()

#缓存当前场景中的TileMapLayer和TileMap节点，用于检测特殊Tile
func _cache_tilemap_layers() -> void:
	if get_tree() and get_tree().current_scene:
		tilemap_layers = get_tree().current_scene.find_children("*", "TileMapLayer", true, false)
		var tm = get_tree().current_scene.find_children("*", "TileMap", true, false)
		tilemap_layers.append_array(tm)

#检查玩家所在Tile是否是water，如果是则触发死亡
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



#================================
#物理处理相关

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
		#缓降魔法，按下空格键时进入缓降状态，下降速度减慢
		if green_gem_magic_unlocked and Input.is_action_pressed("slow_descent") and velocity.y >= 0:
			if slow_descent_cooldown_timer > 0:
				velocity.y += gravity * delta
			else:
				if slow_descent_timer <= 0:
					slow_descent_timer = max_slow_descent_time
				slow_descent_timer -= delta
				velocity.y += (gravity * 0.3) * delta
				velocity.y = min(velocity.y, 80.0)
				$slowDescentParticles.emitting = true
				if slow_descent_timer <= 0:
					slow_descent_cooldown_timer = max_slow_descent_cooldown
					slow_descent_timer = 0
		else:
			if slow_descent_timer > 0:
				slow_descent_cooldown_timer = max_slow_descent_cooldown
				slow_descent_timer = 0
				$slowDescentParticles.emitting = false
			velocity.y += gravity * delta
	else:
		if slow_descent_timer > 0:
			slow_descent_cooldown_timer = max_slow_descent_cooldown
			slow_descent_timer = 0
			$slowDescentParticles.emitting = false
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

#================================
#爬梯子相关

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

#===================================
#道具拾取相关

func set_has_key_red(val:bool):
	has_key_red = val

func set_has_key_green(val:bool):
	has_key_green = val

func set_has_red_flower(val:bool):
	has_red_flower = val

func set_has_blue_flower(val:bool):
	has_blue_flower = val

func get_gem(gem_type: String) -> void:
	match gem_type:
		"red":
			has_red_gem = true
			red_gem_magic_unlocked = true
			DialogManager.show_dialogue(["你在红宝石中感知到了炽热的魔力，但你不知道该如何利用它的能量。"], null, "获得红宝石")
		"green":
			has_green_gem = true
			green_gem_magic_unlocked = true
			DialogManager.show_dialogue(["你在绿宝石中感知到了温和的魔力，它的能量正在逐渐进入你的身体。", "现在你能够在跳跃时按下空格键来减缓下降速度！魔法持续时间为3秒，冷却时间为20秒。"], null, "获得绿宝石")
		"blue":
			has_blue_gem = true
			blue_gem_magic_unlocked = true
			double_jump_enabled = true
			DialogManager.show_dialogue(["你在蓝宝石中感知到了灵动的魔力，它的能量正在逐渐进入你的身体。", "现在你能在起跳后再次按下跳跃键来进行二段跳了！"], null, "获得蓝宝石")
		"yellow":
			has_yellow_gem = true
			yellow_gem_magic_unlocked = true
			DialogManager.show_dialogue(["你在黄宝石中感知到了坚韧的魔力，它的能量正在逐渐进入你的身体。", "现在你可以按下T键使用魔法护盾了！护盾持续时间为5秒，冷却时间为30秒。"], null, "获得黄宝石")
	
#================================
#尖刺相关

func on_spire_hit(spire: Node2D) -> void:
	if is_shield_active:
		return
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



#===============================
#跳跃平台相关

func apply_jump_boost(val):
	jump_velocity += val

func remove_jump_boost(val):
	jump_velocity -= val



#===============================
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
	

#===============================
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

#===============================
#平台移动相关

func on_platform_move(movement: Vector2) -> void:
	position += movement
	
