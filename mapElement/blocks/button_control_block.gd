extends StaticBody2D

var is_active: bool = false

func _ready() -> void:
	add_to_group("checkpoint_stateful")
	_set_block_state(is_active)

func checkpoint_get_state() -> Dictionary:
	return {"is_active": is_active}

func checkpoint_set_state(state: Dictionary) -> void:
	if state == null:
		return
	var active = state.get("is_active", false)
	_set_block_state(active)

func set_block_active() -> void:
	_set_block_state(true)

func set_block_inactive() -> void:
	_set_block_state(false)

func _set_block_state(active: bool) -> void:
	is_active = active
	$Sprite2D.visible = not is_active
	$CollisionShape2D.set_deferred("disabled", is_active)
