extends CharacterBody2D

signal flower_ui_show

@export var keeper_portrait: Texture2D
@export var player_portrait: Texture2D
var gem_scene: PackedScene = preload("res://items/loot/Gem.tscn")

var player_in_range: bool = false
var met_player: bool = false
var dialog_state: int = 0 # 0: 初次, 1: 收集任务进行中, 2: 任务完成
var is_cheering: bool = false
var gem_spawned: bool = false

@export var keeper_name: String = "薇拉"
@export var player_name: String = "卡莎"

@onready var anim = $AnimatedSprite2D
@onready var cure_particle = $CureParticle

var player_node: Node2D = null
var interact_cooldown: float = 0.1

func _ready() -> void:
	DialogManager.connect("dialog_action", Callable(self, "_on_dialog_action"))
	DialogManager.connect("dialog_finished", Callable(self, "_on_dialog_finished"))
	anim.animation_finished.connect(Callable(self, "_on_animation_finished"))
	anim.frame_changed.connect(Callable(self, "_on_frame_changed"))

func _physics_process(delta: float) -> void:
	if interact_cooldown > 0:
		interact_cooldown -= delta

	if is_cheering or DialogManager.is_dialog_active():
		return
		
	if dialog_state < 2:
		anim.play("hurt")
	else:
		anim.play("stay")

	if player_in_range and interact_cooldown <= 0.0:
		if not DialogManager.is_dialog_active():
			if not met_player:
				# 自动触发初次对话
				met_player = true
				var dialog_data = [
					{"speaker": player_name, "text": "你还好吗？你看起来受伤了。", "portrait": player_portrait},
					{"speaker": keeper_name, "text": "你好，冒险者，我叫薇拉。我不慎受伤了，我需要红蓝两种水晶花来治疗自己。你能帮我采集一下吗？", "portrait": keeper_portrait},
					{"speaker": player_name, "text": "叫我卡莎吧。我该怎么找到这些水晶花呢？", "portrait": player_portrait},
					{"speaker": keeper_name, "text": "它们都生长在这些高大植物的顶端，你需要爬上去才能采集到它们。", "portrait": keeper_portrait},
					{"speaker": player_name, "text": "噢，为什么这些植物长得这么高大啊？这里是什么地方？", "portrait": player_portrait},
					{"speaker": keeper_name, "text": "这是密林，这就是这里的特色了。对了，小心植物上的尖刺，它们会伤害你的。", "portrait": keeper_portrait}
				]
				if player_node and player_node.has_method("set_physics_process"):
					player_node.set_physics_process(false)
				DialogManager.show_dialogue(dialog_data, keeper_portrait, keeper_name)
				dialog_state = 1
				emit_signal("flower_ui_show")
			elif Input.is_action_just_pressed("interact"):
				if dialog_state == 1:
					var has_red = player_node.get("has_red_flower") if player_node != null else false
					var has_blue = player_node.get("has_blue_flower") if player_node != null else false
					var dialog_data = []
					
					if not has_red and not has_blue:
						dialog_data = [
							{"speaker": keeper_name, "text": "噢……好疼……", "portrait": keeper_portrait},
							{"speaker": player_name, "text": "我会尽快的！你坚持一下！", "portrait": player_portrait}
						]
					elif has_red and not has_blue:
						dialog_data = [
							{"speaker": player_name, "text": "我采集到了红水晶花了。", "portrait": player_portrait},
							{"speaker": keeper_name, "text": "太好了！我还需要蓝水晶花来完全恢复。你能继续帮我采集吗？", "portrait": keeper_portrait}
						]
					elif not has_red and has_blue:
						dialog_data = [
							{"speaker": player_name, "text": "我采集到了蓝水晶花了。", "portrait": player_portrait},
							{"speaker": keeper_name, "text": "太好了！但我还需要红水晶花来完全恢复。你能继续帮我采集吗？", "portrait": keeper_portrait}
						]
					elif has_red and has_blue:
						dialog_data = [
							{"speaker": player_name, "text": "两种花我都采集到了！", "portrait": player_portrait},
							{"speaker": keeper_name, "text": "太好了！谢谢你，卡莎！", "portrait": keeper_portrait},
							{"speaker": keeper_name, "text": "(使用治愈魔法)", "portrait": keeper_portrait, "action": "cure"},
							{"speaker": keeper_name, "text": "呼，我好多了，谢谢你，卡莎。我这里有颗绿宝石，你拿着吧。", "portrait": keeper_portrait}
						]
						dialog_state = 2
					
					if player_node and player_node.has_method("set_physics_process"):
						player_node.set_physics_process(false)
					DialogManager.show_dialogue(dialog_data, keeper_portrait, keeper_name)
				elif dialog_state == 2:
					var dialog_data = [
						{"speaker": player_name, "text": "你好，薇拉。你感觉怎么样了？", "portrait": player_portrait},
						{"speaker": keeper_name, "text": "谢谢你，卡莎！我现在感觉好多了，你看！", "portrait": keeper_portrait, "action": "cheer"},
						{"speaker": keeper_name, "text": "你真是个好冒险者！使用绿宝石的力量，继续你的冒险吧！祝你好运！", "portrait": keeper_portrait}
					]
					if player_node and player_node.has_method("set_physics_process"):
						player_node.set_physics_process(false)
					DialogManager.show_dialogue(dialog_data, keeper_portrait, keeper_name)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		$Tips.show()
		player_in_range = true
		player_node = body
	
func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		$Tips.hide()
		player_in_range = false
		player_node = null

func _on_dialog_action(action_name: String) -> void:
	if action_name == "cure":
		is_cheering = true
		anim.play("cure")
	elif action_name == "cheer":
		is_cheering = true
		anim.play("cheer")

func _on_frame_changed() -> void:
	if anim.animation == "cure" and anim.frame == 10:
		if cure_particle:
			cure_particle.emitting = true

func _on_animation_finished() -> void:
	if anim.animation == "cheer" or anim.animation == "cure":
		is_cheering = false
		anim.play("stay")

func _on_dialog_finished() -> void:
	interact_cooldown = 0.2
	if player_node and player_node.has_method("set_physics_process"):
		player_node.set_physics_process(true)
	
	if dialog_state == 2 and not gem_spawned:
		gem_spawned = true
		if gem_scene:
			var gem = gem_scene.instantiate()
			gem.gem_type = "green"
			gem.global_position = global_position + Vector2(45, 0)
			get_parent().add_child(gem)
