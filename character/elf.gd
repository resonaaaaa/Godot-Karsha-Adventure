"""
精灵 
在关卡前期出现的NPC，提供关于贤者的线索。
和其他NPC的逻辑类似，会进行巡逻，玩家接近时会停下来和玩家对话。对话内容根据是否第一次见面而不同。
"""

extends CharacterBody2D

var speed: float = 80.0
@export var target_position = [Vector2.ZERO, Vector2(250, 0), Vector2(90, 0),Vector2(200, 0),Vector2(130, 0),Vector2(30, 0)]
@export var elf_portrait: Texture2D
@export var player_portrait: Texture2D
var direction: int = 1
var player_in_range: bool = false
var met_player: bool = false
var pause_timer: float = 0.0

@onready var anim = $AnimatedSprite2D

var player_node: Node2D = null
var interact_cooldown: float = 0.0
var start_position: Vector2 = Vector2.ZERO
var pending_event_checkpoint_source: String = ""

func _ready() -> void:
	DialogManager.connect("dialog_finished", Callable(self, "_on_dialog_finished"))
	anim.animation_finished.connect(Callable(self, "_on_animation_finished"))
	var sensor = get_node_or_null("sensor")
	if sensor:
		sensor.body_entered.connect(Callable(self, "_on_sensor_body_entered"))
		sensor.body_exited.connect(Callable(self, "_on_sensor_body_exited"))
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
					{"speaker":"卡莎","text":"你好，美丽的精灵小姐！这儿真热啊！","portrait":player_portrait},
					{"speaker":"精灵","text":"此处非寻常之地，汝一凡人，何故至此？","portrait":elf_portrait},
					{"speaker":"卡莎","text":"你们精灵讲话好难懂……我是卡莎，致力于探索这个世界！","portrait":player_portrait},
					{"speaker":"精灵","text":"原来如是。汝颇有胆识。听闻近日一贤者入此火山深处修行，若得遇之，或可有所获。","portrait":elf_portrait},
					{"speaker":"卡莎","text":"贤者？谢谢你告诉我这个消息，精灵小姐！","portrait":player_portrait}
					
				]
				if player_node and player_node.has_method("set_physics_process"):
					player_node.set_physics_process(false)
				DialogManager.show_dialogue(dialog_data, elf_portrait, "精灵")
				_save_event_checkpoint("elf_first_dialog")
			else:
				var dialog_data = [
					{"speaker": "精灵", "text": "可曾寻到贤者？", "portrait": elf_portrait},
					{"speaker": "卡莎", "text": "我还在寻找怎么进入火山内部的方法……", "portrait": player_portrait}
				]
				if player_node and player_node.has_method("set_physics_process"):
					player_node.set_physics_process(false)
				DialogManager.show_dialogue(dialog_data, elf_portrait, "精灵")
				_save_event_checkpoint("elf_repeat_dialog")
			return

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

func _on_animation_finished() -> void:
	pass

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
	var mgr = scene.get_node_or_null("CheckPointManager")
	if mgr and mgr.has_method("save_event_checkpoint"):
		mgr.save_event_checkpoint(player_node, scene.get_node_or_null("HUD"), scene, pending_event_checkpoint_source)
	pending_event_checkpoint_source = ""
