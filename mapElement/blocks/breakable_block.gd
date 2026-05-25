extends StaticBody2D

var broken: bool = false

func _ready() -> void:
	add_to_group("checkpoint_stateful")

func break_block():
	# 不直接释放，改为隐藏并禁用碰撞，便于 checkpoint 恢复
	broken = true
	visible = false
	$CollisionShape2D.set_deferred("disabled", true)

func checkpoint_get_state() -> Dictionary:
	return {"broken": broken}

func checkpoint_set_state(state: Dictionary) -> void:
	if state == null:
		return
	var b = state.get("broken", false)
	broken = b
	if broken:
		visible = false
		$CollisionShape2D.set_deferred("disabled", true)
	else:
		visible = true
		$CollisionShape2D.set_deferred("disabled", false)
