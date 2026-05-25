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

func _onready():
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
			pause_timer = 0.6
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
					{"speaker": "学者", "text": "你好啊，年轻的朋友！请问你是在冒险吗？", "portrait": scholar_portrait},
					{"speaker": player_name, "text": "是的，学者先生，请叫我卡莎。您怎么会在这种地方？", "portrait": player_portrait},
					{"speaker": scholar_name, "text": "哈哈，我叫拉贝尔。俗话说得好，'读万卷书，行万里路'！我在云游世界，记录各种见闻。", "portrait": scholar_portrait},
					{"speaker": player_name, "text": "喔？那么拉贝尔先生了解这片森林吗？", "portrait": player_portrait},
					{"speaker": scholar_name, "text": "呵呵呵，真惭愧，我对这片森林了解得并不多，但简单讲讲还是可以的。我去过许多地方，这里的恶劣环境真的能在所有地方里排在前列。", "portrait": scholar_portrait},
					{"speaker": player_name, "text": "我才刚到这里，能给我说说吗？", "portrait": player_portrait},
					{"speaker": scholar_name, "text": "当然了。这里叫毒沼密林，到处都是毒气与泥沼。如果你不慎吸入毒气，多半会命不久矣。而如果不慎跌入泥沼，也很难脱身。这里的高大植株遮蔽了阳光，让这里更加阴暗潮湿。", "portrait": scholar_portrait},	
					{"speaker": player_name, "text": "听起来真可怕啊！", "portrait": player_portrait},
					{"speaker": scholar_name, "text": "哈哈哈，冒险者的世界不就是这样吗？不过别担心，你看我一介学者，不也穿过了这片森林吗？", "portrait": scholar_portrait},
					{"speaker": player_name, "text": "谢谢你的鼓励，拉贝尔先生！我会小心的。", "portrait": player_portrait},
				]
				if player_node and player_node.has_method("set_physics_process"):
					player_node.set_physics_process(false)
				DialogManager.show_dialogue(dialog_data, scholar_portrait, scholar_name)
				_save_event_checkpoint("scholar_first_dialog")
			else:
				var dialog_data = [
					{"speaker": scholar_name, "text": "怎么了卡莎，你有什么有趣的故事要和我分享吗？" + player_name + "。", "portrait": scholar_portrait},
					{"speaker": player_name, "text": "暂时还没有！", "portrait": player_portrait},
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
	var mgr = scene.get_node_or_null("CheckpointManager")
	if mgr and mgr.has_method("save_event_checkpoint"):
		# 学者对话结束后再写入，这样 met_player 状态会和玩家复活点一起保存
		mgr.save_event_checkpoint(player_node, scene.get_node_or_null("HUD"), scene, pending_event_checkpoint_source)
	pending_event_checkpoint_source = ""
