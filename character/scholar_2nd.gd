"""
学者 (第2次出现)
在第四关再次出现的学者，行动逻辑与第三关基本一致。会给玩家解开谜题。

"""


extends CharacterBody2D

var speed: float = 80.0
@export var target_position = [Vector2.ZERO, Vector2(110,0),Vector2(-30,0),Vector2(70,0)]
@export var scholar_portrait: Texture2D
@export var player_portrait: Texture2D
var direction: int = 1
var player_in_range: bool = false
var met_player: bool = false
var pause_timer: float = 0.0

var player_node: Node2D = null
var interact_cooldown: float = 0.0
var start_position: Vector2 = Vector2.ZERO
var pending_event_checkpoint_source: String = ""

var scholar_name: String = "拉贝尔"
var player_name: String = "卡莎"

@onready var anim = $AnimatedSprite2D

func _ready():
	DialogManager.connect("dialog_action", Callable(self, "_on_dialog_action"))
	DialogManager.connect("dialog_finished", Callable(self, "_on_dialog_finished"))
	start_position = position
	add_to_group("checkpoint_stateful")

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


func _physics_process(delta: float) -> void:
	if interact_cooldown > 0:
		interact_cooldown -= delta

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
				var dialog_data = [
					{"speaker": player_name, "text": "拉贝尔先生！我们又见面了！", "portrait": player_portrait},
					{"speaker": scholar_name, "text": "哈哈，卡莎，你果然没被毒沼密林困住。", "portrait": scholar_portrait},
					{"speaker": player_name, "text": "托您的福！", "portrait": player_portrait},
					{"speaker": player_name, "text": "这儿真热啊，您在这做什么呢？", "portrait": player_portrait},
					{"speaker": scholar_name, "text": "我在观察这儿的植物，它们居然能在这种恶劣的环境中生存，真有趣。", "portrait": scholar_portrait},
					{"speaker": player_name, "text": "听起来好专业。啊。对了，您知道下面的门怎么打开吗？这里的拉杆也太多了。", "portrait": player_portrait},
					{"speaker": scholar_name, "text": "嗯……我想它一定是采用了某种特殊的计数方式。你看，它写着向左是0，向右是1，看来是采用的二进制计数。", "portrait": scholar_portrait},	
					{"speaker": player_name, "text": "二进制？", "portrait": player_portrait},
					{"speaker": scholar_name, "text": "嗯……9用二进制表示，应该是1001，你可以试试看。", "portrait": scholar_portrait},
					{"speaker": player_name, "text": "非常感谢您！我这就试试！", "portrait": player_portrait},
				]
				if player_node and player_node.has_method("set_physics_process"):
					player_node.set_physics_process(false)
				DialogManager.show_dialogue(dialog_data, scholar_portrait, scholar_name)
				_save_event_checkpoint("scholar_first_dialog")
			else:
				var dialog_data = [
					{"speaker": scholar_name, "text": "怎么样，解开了吗？", "portrait": scholar_portrait},
				]
				if player_node and player_node.has_method("set_physics_process"):
					player_node.set_physics_process(false)
				DialogManager.show_dialogue(dialog_data, scholar_portrait, scholar_name)
				_save_event_checkpoint("scholar_repeat_dialog")


func _on_sensor_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		$Tips.show()
		player_in_range = true
		player_node = body
		anim.play("stay")


func _on_sensor_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		$Tips.hide()
		player_in_range = false
		player_node = null


func _on_dialog_finished() -> void:
	if not player_in_range:
		return
	interact_cooldown = 0.2
	if not met_player:
		met_player = true
	if player_node and player_node.has_method("set_physics_process"):
		player_node.set_physics_process(true)
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
		# 学者对话结束后再写入，这样 met_player 状态会和玩家复活点一起保存
		mgr.save_event_checkpoint(player_node, scene.get_node_or_null("HUD"), scene, pending_event_checkpoint_source)
	pending_event_checkpoint_source = ""
