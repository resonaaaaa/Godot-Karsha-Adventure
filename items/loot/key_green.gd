extends Area2D
signal get_key_green

func _ready() -> void:
	add_to_group("checkpoint_stateful")

func _set_collected(collected: bool) -> void:
	set_deferred("monitoring", not collected)
	visible = not collected

func apply_collected_state() -> void:
	_set_collected(true)

func checkpoint_get_state() -> Dictionary:
	return {"collected": not visible, "position": position}

func checkpoint_set_state(state: Dictionary) -> void:
	if state == null:
		return
	var collected = state.get("collected", false)
	_set_collected(collected)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		AudioManager.play_se("res://asset/audio/SE/pickup.wav")
		body.set_has_key_green(true)
		_set_collected(true)
		get_key_green.emit()
