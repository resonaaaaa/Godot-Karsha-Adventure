extends Area2D

@export_enum("red", "blue", "green", "yellow") var gem_type: String = "red"
@export var gem_texture_red: Texture2D
@export var gem_texture_blue: Texture2D
@export var gem_texture_green: Texture2D
@export var gem_texture_yellow: Texture2D

func _ready() -> void:
	match gem_type:
		"red":
			$Sprite2D.texture = gem_texture_red
		"blue":
			$Sprite2D.texture = gem_texture_blue
		"green":
			$Sprite2D.texture = gem_texture_green
		"yellow":
			$Sprite2D.texture = gem_texture_yellow
	add_to_group("checkpoint_stateful")

func _set_collected(collected: bool) -> void:
	set_deferred("monitoring", not collected)
	visible = not collected

func apply_collected_state() -> void:
	_set_collected(true)

func checkpoint_get_state() -> Dictionary:
	return {"collected": not visible, "position": position, "type": gem_type}

func checkpoint_set_state(state: Dictionary) -> void:
	if state == null:
		return
	var collected = state.get("collected", false)
	_set_collected(collected)

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	AudioManager.play_se("res://asset/audio/SE/pickup.wav")
	var mgr = get_tree().current_scene.get_node_or_null("CheckPointManager")
	# 不再在拾取时立即记录至 CheckpointManager，checkpoint 由快照时刻从节点自身状态导出
	match gem_type:
		"red":
			body.get_gem("red")
		"blue":
			body.get_gem("blue")
		"green":
			body.get_gem("green")
		"yellow":	
			body.get_gem("yellow")
	_set_collected(true)
	
