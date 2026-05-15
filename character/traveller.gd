extends CharacterBody2D

var speed: float = 80.0
@export var target_position = [Vector2.ZERO, Vector2(250, 0), Vector2(90, 0),Vector2(200, 0),Vector2(130, 0),Vector2(30, 0)]
@export var traveller_portrait: Texture2D
@export var player_portrait: Texture2D
var direction: int = 1
var player_in_range: bool = false
var met_player: bool = false
var pause_timer: float = 0.0

@onready var anim = $AnimatedSprite2D

var player_node: Node2D = null
var interact_cooldown: float = 0.0
var start_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	DialogManager.connect("dialog_finished", Callable(self, "_on_dialog_finished"))
	anim.animation_finished.connect(Callable(self, "_on_animation_finished"))
	var sensor = get_node_or_null("sensor")
	if sensor:
		sensor.body_entered.connect(Callable(self, "_on_sensor_body_entered"))
		sensor.body_exited.connect(Callable(self, "_on_sensor_body_exited"))
	start_position = position

func _physics_process(delta: float) -> void:
	if player_in_range or DialogManager.is_dialog_active():
		anim.play("stay")
	else:
		if pause_timer > 0:
			pause_timer -= delta
			anim.play("stay")
			return
		if typeof(target_position) != TYPE_ARRAY or target_position.size() == 0:
			# 没有巡逻点，保持站立
			anim.play("stay")
			return
		# 保证方向索引有效
		if direction < 0 or direction >= target_position.size():
			direction = 0
		var target = start_position + target_position[direction]
		if typeof(target) != TYPE_VECTOR2:
			anim.play("stay")
			return
		var to_vec = target - position
		if to_vec.length() == 0:
			# 已在目标点，切换到下一个并暂停
			direction = (direction + 1) % target_position.size()
			pause_timer = 0.3
			anim.play("stay")
			return
		var movement = to_vec.normalized() * speed * delta
		# 更新动画方向
		if movement.x > 0:
			anim.play("right")
		elif movement.x < 0:
			anim.play("left")
		# 如果这一步会越过目标位置，直接置为目标并停顿
		if movement.length() >= to_vec.length():
			position = target
			direction = (direction + 1) % target_position.size()
			pause_timer = 0.7
		else:
			position += movement

	move_and_slide()

	if player_in_range and Input.is_action_just_pressed("interact") and interact_cooldown <= 0.0:
		if not DialogManager.is_dialog_active():
			if not met_player:
				var dialog_data = [
					{"speaker": "年长旅者", "text": "年轻的冒险者，请留步，大叔我有话要说。", "portrait": traveller_portrait},
					{"speaker": "年长旅者", "text": "前面的路上有怪物出没，你要小心。", "portrait": traveller_portrait},
					{"speaker": "年长旅者", "text": "请尽量避开它们，它们会一击毙命。当然，如果你想挑战它们，那就跳到它们的头上去，给它们狠狠一击吧！哈哈哈！", "portrait": traveller_portrait},
					{"speaker": "卡莎", "text": "谢谢您的提醒，我会小心的。", "portrait": player_portrait},
					{"speaker": "年长旅者", "text": "哈哈哈，不用谢，年轻人。祝你好运！", "portrait": traveller_portrait}
				]
				if player_node and player_node.has_method("set_physics_process"):
					player_node.set_physics_process(false)
				DialogManager.show_dialogue(dialog_data, traveller_portrait, "年长旅者")
			else:
				var dialog_data = [
					{"speaker": "年长旅者", "text": "哦，你又来了！怎么，被那些怪物吓到了吗？哈哈哈！", "portrait": traveller_portrait},
					{"speaker": "卡莎", "text": "不是的！", "portrait": player_portrait}
				]
				if player_node and player_node.has_method("set_physics_process"):
					player_node.set_physics_process(false)
				DialogManager.show_dialogue(dialog_data, traveller_portrait, "年长旅者")

func _on_sensor_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		var tips = get_node_or_null("Tips")
		if tips:
			tips.show()
		player_in_range = true
		player_node = body
		anim.play("stay")
	
func _on_sensor_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		var tips = get_node_or_null("Tips")
		if tips:
			tips.hide()
		player_in_range = false
		player_node = null

func _on_animation_finished() -> void:
	pass

func _on_dialog_finished() -> void:
	interact_cooldown = 0.2
	if not met_player:
		met_player = true
	if player_node and player_node.has_method("set_physics_process"):
		player_node.set_physics_process(true)
	anim.play("stay")
