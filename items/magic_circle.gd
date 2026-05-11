extends Area2D
signal tp
signal level_completed
@export var is_to:bool = false  #是否是传送到达点，传送到达点的旗帜不显示
@export var end_flag:bool = false  #是否是终点，终点的旗帜显示为特殊颜色
@export var end_flag_texture:Texture2D  #终点旗帜的特殊颜色纹理
@export var tp_destination:NodePath  #传送目的地，仅在is_to为false时有效
var one_shot:bool = false  #是否已经触发过一次传送，防止重复触发


func _ready() -> void:
	if end_flag:
		$Flag.texture = end_flag_texture
	$AnimatedSprite2D.hide()
	if is_to:
		$Flag.hide()
	one_shot = false

func _on_body_entered(body: Node2D) -> void:
	if one_shot:
		return

	if is_to:
		# 到达点触发到达动画
		if body.is_in_group("player"):
			$AnimatedSprite2D.show()
			$AnimatedSprite2D.animation = "tp"
			$AnimatedSprite2D.play()
			one_shot = true
		return

	if body.is_in_group("player"):
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


func _on_animated_sprite_2d_animation_finished() -> void:
	$AnimatedSprite2D.hide()
	if end_flag:
		level_completed.emit()
	tp.emit()
