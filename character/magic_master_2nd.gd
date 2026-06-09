extends Area2D

var speed: float = 80.0
@export var target_position = [Vector2.ZERO, Vector2(250, 0), Vector2(90, 0),Vector2(200, 0),Vector2(130, 0),Vector2(30, 0)]
@export var master_portrait: Texture2D
@export var player_portrait: Texture2D
var direction: int = 1
var player_in_range: bool = false
var met_player: bool = false
var pause_timer: float = 0.0
var master_name: String = "希奥娜"
var player_name: String = "卡莎"

@onready var anim = $AnimatedSprite2D

var player_node: Node2D = null
var is_shooting: bool = false
var interact_cooldown: float = 0.0
var start_position: Vector2 = Vector2.ZERO
var pending_event_checkpoint_source: String = ""

func _ready() -> void:
	DialogManager.connect("dialog_action", Callable(self, "_on_dialog_action"))
	DialogManager.connect("dialog_finished", Callable(self, "_on_dialog_finished"))
	add_to_group("checkpoint_stateful")
	anim.animation_finished.connect(Callable(self, "_on_animation_finished"))
	$MagicShieldParticles.emitting = false


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

	if player_in_range and Input.is_action_just_pressed("interact") and interact_cooldown <= 0.0:
		if not DialogManager.is_dialog_active():
			if not met_player:
				#初次对话
				var dialog_data = [
					{"speaker": player_name, "text": "希奥娜老师！我们居然又见面了！原来那个机关门是您设下的！", "portrait": player_portrait},
					{"speaker": master_name, "text": "哈哈，卡莎，你言重了，我不过指点一二而已，称不上老师。倒是你触类旁通，居然把其他宝石魔法也学会了。", "portrait": master_portrait},
					{"speaker": master_name, "text": "没错，那道门确实是我设下的，活火山内部毕竟过于危险，如果一般人贸然进入，后果不堪设想。不过你居然解开了它，看来你很有智慧啊。", "portrait": master_portrait},
					{"speaker": player_name, "text": "嘿嘿，您过奖了，我也是得到了一些指点。", "portrait": player_portrait},
					{"speaker": master_name, "text": "呵呵呵，红宝石就在这活火山的某处，它的能量相比其他宝石更为强大，可能比较难掌握。我先给你演示一遍红宝石魔法吧，看好了。", "portrait": master_portrait},
					{"speaker": master_name, "text": "（演示中...）", "action": "shoot","portrait": master_portrait,},
					{"speaker": master_name, "text": "除了炸开方块，拿来防身也是个好选择，去吧，卡莎。", "portrait": master_portrait},
					{"speaker": player_name, "text": "太棒了！谢谢希奥娜老师！", "portrait": player_portrait}
				]
				# 让玩家无法移动
				if player_node and player_node.has_method("set_physics_process"):
					player_node.set_physics_process(false)
				DialogManager.show_dialogue(dialog_data, master_portrait, master_name)
				_save_event_checkpoint("magic_master_first_dialog")
			else:
				#再次对话
				if player_node and player_node.has_method("set_physics_process"):
					player_node.set_physics_process(false)
				if player_node.has_gem == true:
					var dialog_data = [
						{"speaker": master_name, "text": "卡莎，找到红宝石了吗？有没有学会魔法？", "portrait": master_portrait},
						{"speaker": player_name, "text": "嗯，我找到了红宝石！还学会了它的魔法！", "portrait": player_portrait},
						{"speaker": master_name, "text": "我就知道这难不倒你，继续冒险吧！", "portrait": master_portrait}
					]
					DialogManager.show_dialogue(dialog_data, master_portrait, master_name)
				else:
					var dialog_data = [
						{"speaker": master_name, "text": "卡莎，找到红宝石了吗？有没有学会魔法？", "portrait": master_portrait},
						{"speaker": player_name, "text": "还没有呢，我还在找,但感觉快找到了！", "portrait": player_portrait},
						{"speaker": master_name, "text": "加油，卡莎！红宝石的能量很强大，掌握了它，你的冒险会更顺利的。", "portrait": master_portrait}
					]
					DialogManager.show_dialogue(dialog_data, master_portrait, master_name)

	

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
		#确保master朝向右边发射火球
		anim.flip_h = true
		anim.play("shooting")
		await $AnimatedSprite2D.animation_finished
		shooting_fireball()


func _on_animation_finished() -> void:
	if anim.animation == "shooting":
		is_shooting = false
		anim.flip_h = false
		anim.play("stay")

func _on_dialog_finished() -> void:
	interact_cooldown = 0.2
	if not met_player:
		met_player = true
		if player_node and player_node.has_method("set_physics_process"):
			player_node.set_physics_process(true)
	if not is_shooting:
		anim.play("stay")
	_commit_event_checkpoint()

func _save_event_checkpoint(source_name: String) -> void:
	pending_event_checkpoint_source = source_name

func _commit_event_checkpoint() -> void:
	if pending_event_checkpoint_source == "":
		return
	var scene = get_tree().current_scene
	if scene == null:
		return
	var mgr = scene.get_node_or_null("CheckPointManager")
	if mgr and mgr.has_method("save_event_checkpoint"):
		# 对话结束后再写入事件快照，确保 NPC 状态和玩家位置都是完成时刻的版本
		mgr.save_event_checkpoint(player_node, scene.get_node_or_null("HUD"), scene, pending_event_checkpoint_source)
	pending_event_checkpoint_source = ""

func checkpoint_get_state() -> Dictionary:
	return {"met_player": met_player, "position": position, "direction": direction}

func checkpoint_set_state(state: Dictionary) -> void:
	if state == null:
		return
	met_player = state.get("met_player", false)
	var pos = state.get("position", null)
	if pos != null:
		set_deferred("position", pos)
	direction = state.get("direction", direction)

func shooting_fireball() -> void:
	var Fireball = preload("res://items/fireball.tscn")
	if Fireball:
		var inst = Fireball.instantiate()
		inst.position = global_position + Vector2(30, 0)
		get_parent().add_child(inst)
		
		if inst.has_method("set_direction"):
			inst.set_direction(Vector2.RIGHT)
