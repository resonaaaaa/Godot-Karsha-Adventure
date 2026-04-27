extends Area2D
signal tp


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		$AnimatedSprite2D.show()
		$AnimatedSprite2D.animation = "tp"
		$AnimatedSprite2D.play()
		body.hide()
		await tp
		body.show()
		
func _on_animated_sprite_2d_animation_finished() -> void:
	$AnimatedSprite2D.hide()
	tp.emit()
