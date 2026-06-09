extends Node2D

var is_locked: bool = true

func _ready() -> void:
	add_to_group("checkpoint_stateful")
	_apply_locked_state(is_locked)

func _on_area_2d_body_entered(body: Node2D) -> void:
	if not is_locked:
		return
	if body.is_in_group("player") and body.has_key_green:
		AudioManager.play_se("res://asset/audio/SE/block_unlock.wav")
		set_locked(false)

func checkpoint_get_state() -> Dictionary:
	return {"is_locked": is_locked}

func checkpoint_set_state(state: Dictionary) -> void:
	if state == null:
		return
	set_locked(state.get("is_locked", true))

func set_locked(value: bool) -> void:
	_apply_locked_state(value)

func _apply_locked_state(value: bool) -> void:
	is_locked = value
	visible = is_locked
	var sensor = get_node_or_null("sensor")
	if sensor == null:
		sensor = get_node_or_null("Area2D")
	if sensor != null:
		var sensor_shape = sensor.get_node_or_null("CollisionShape2D")
		if sensor_shape != null:
			sensor_shape.set_deferred("disabled", not is_locked)
	var solid_body = get_node_or_null("StaticBody2D")
	if solid_body != null:
		var solid_shape = solid_body.get_node_or_null("CollisionShape2D")
		if solid_shape != null:
			solid_shape.set_deferred("disabled", not is_locked)
