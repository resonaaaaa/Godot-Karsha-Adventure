extends Area2D
signal get_key_green

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		var mgr = get_tree().current_scene.get_node_or_null("CheckpointManager")
		if mgr:
			mgr.record_collected(self)
		body.set_has_key_green(true)
		queue_free()
		get_key_green.emit()
