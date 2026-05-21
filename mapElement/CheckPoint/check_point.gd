extends Area2D

@export var id: int = 1
var activated: bool = false
var scene

func _ready() -> void:
	scene = get_tree().current_scene
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body: Node) -> void:
	if activated:
		return
		
	if body.is_in_group("player"):
		if not scene:
			return
		var mgr = scene.get_node_or_null("CheckpointManager")
		if not mgr:
			return
		var hud = scene.get_node_or_null("HUD")
		var ok = mgr.register_checkpoint(id, global_position, body, hud)
		
		if ok:
			activated = true
			if hud:
				hud.show_saving_massage()
		# 触发时可以播放动画或发出信号（如需扩展）
