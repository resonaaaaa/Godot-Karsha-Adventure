extends Area2D

var speed: float = 80.0
@export var target_position = [Vector2.ZERO, Vector2(250, 0), Vector2(90, 0),Vector2(200, 0),Vector2(130, 0),Vector2(30, 0)]
var direction: int = 1
var player_in_range: bool = false
var met_player: bool = false
var pause_timer: float = 0.0

@onready var anim = $AnimatedSprite2D

var player_node: Node2D = null
var is_shooting: bool = false
var interact_cooldown: float = 0.0
var start_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	DialogManager.connect("dialog_action", Callable(self, "_on_dialog_action"))
	DialogManager.connect("dialog_finished", Callable(self, "_on_dialog_finished"))
	anim.animation_finished.connect(Callable(self, "_on_animation_finished"))


	start_position = position

func _physics_process(delta: float) -> void:
	if interact_cooldown > 0:
		interact_cooldown -= delta

	if is_shooting:
		return
		
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
		# Updating animation direction
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

	if player_in_range and Input.is_action_just_pressed("interact") and interact_cooldown <= 0.0:
		if not DialogManager.is_dialog_active():
			if not met_player:
				#初次对话
				var dialog_data = [
					{"speaker": "？？？", "text": "你好啊，卡莎，欢迎来到月光湖畔。"},
					{"speaker": "卡莎", "text": "你是谁？怎么会知道我的名字？"},
					{"speaker": "？？？", "text": "呵呵呵……你可以叫我希奥娜，不过是一名路过的魔法师而已。"},
					{"speaker": "希奥娜", "text": "来说正事吧。你刚刚从活火山过来吧？想必你已经拿到了红宝石了吧？"},
					{"speaker": "卡莎", "text": "是有这么个东西。我感受到了它里面蕴藏的魔力，但我还不太清楚它的用途。"},
					{"speaker": "希奥娜", "text": "没关系，我对宝石魔法略懂一二，看好了。"},
					{"speaker": "希奥娜", "text": "（演示中...）", "action": "shoot"},
					{"speaker": "卡莎", "text": "哇哦！"},
					{"speaker": "希奥娜", "text": "待会你也可以试着发射一个火球，看到前面那个方块了吗，跟周围不大一样的那个。向它发射火球吧！"},
					{"speaker": "希奥娜", "text": "呵呵呵，别急，除了红宝石，还有各色的宝石藏在世界各处，拿到它们，你就可以使用不同的魔法了。好了，去试试你的新魔法吧！"},
					{"speaker": "", "text": "（提示：按F键发射火球）"}
				]
				# 让玩家无法移动
				if player_node and player_node.has_method("set_physics_process"):
					player_node.set_physics_process(false)
				DialogManager.show_dialogue(dialog_data)
				#玩家解锁魔法
				if player_node:
					player_node.set("red_gem_magic_unlocked", true)
			else:
				# Repeated conversation
				var dialog_data = [
					{"speaker": "希奥娜", "text": "卡莎，你试过魔法了吗？感觉如何？对了，你在活火山有碰到怪物吧？试着对它们发射火球看看。"}
				]
				DialogManager.show_dialogue(dialog_data)

	

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		$Tips.show()
		player_in_range = true
		player_node = body
		if not is_shooting:
			anim.play("stay")
	
func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		$Tips.hide()
		player_in_range = false
		player_node = null

func _on_dialog_action(action_name: String) -> void:
	if action_name == "shoot":
		is_shooting = true
		anim.frame = 0
		anim.play("shooting")
		await $AnimatedSprite2D.animation_finished
		shooting_fireball()

func _on_animation_finished() -> void:
	if anim.animation == "shooting":
		is_shooting = false
		anim.play("stay")

func _on_dialog_finished() -> void:
	interact_cooldown = 0.2
	if not met_player:
		met_player = true
		if player_node and player_node.has_method("set_physics_process"):
			player_node.set_physics_process(true)
	if not is_shooting:
		anim.play("stay")

func shooting_fireball() -> void:
	var Fireball = preload("res://items/fireball.tscn")
	if Fireball:
		var inst = Fireball.instantiate()
		inst.position = global_position + Vector2(-30, 0)
		get_parent().add_child(inst)
		
		if inst.has_method("set_direction"):
			inst.set_direction(Vector2.LEFT)
