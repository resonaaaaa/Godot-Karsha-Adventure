extends Area2D
signal tp
signal level_completed
@export var is_to:bool = false  #是否是传送到达点，传送到达点的旗帜不显示
@export var end_flag:bool = false  #是否是终点，终点的旗帜显示为特殊颜色
@export var end_flag_texture:Texture2D  #终点旗帜的特殊颜色纹理
@export var tp_destination:NodePath  #传送目的地，仅在is_to为false时有效
var teleporting: bool = false  # 防止同一轮传送被重复触发


func _ready() -> void:
	# 到达点本身不负责传送，只负责在玩家抵达时记录事件快照
	if end_flag:
		$Flag.texture = end_flag_texture
	$AnimatedSprite2D.hide()
	if is_to:
		$Flag.hide()
		teleporting = false

func _on_body_entered(body: Node2D) -> void:
	if teleporting:
		return

	if is_to:
		# 到达点触发到达动画
		if body.is_in_group("player"):
			var scene = get_tree().current_scene
			if scene != null:
				var mgr = scene.get_node_or_null("CheckpointManager")
				if mgr and mgr.has_method("save_event_checkpoint"):
					# 只有在到达点保存快照，这样从传送起点离开不会污染检查点
					mgr.save_event_checkpoint(body, scene.get_node_or_null("HUD"), scene, "teleport_arrival")
			$AnimatedSprite2D.show()
			$AnimatedSprite2D.animation = "tp"
			$AnimatedSprite2D.play()
		return

	if body.is_in_group("player"):
		teleporting = true
		$AnimatedSprite2D.show()
		$AnimatedSprite2D.animation = "tp"
		$AnimatedSprite2D.play()
		body.hide()
		body.set_physics_process(false)
		await tp
		if not end_flag and tp_destination:
			var dest_node = get_node_or_null(tp_destination)
			if dest_node:
				body.global_position = dest_node.global_position
			body.show()
			body.set_physics_process(true)
		teleporting = false


func _on_animated_sprite_2d_animation_finished() -> void:
	$AnimatedSprite2D.hide()
	if end_flag:
		level_completed.emit()
	tp.emit()
