extends Area2D

var player_in_range: bool = false
@export var dialogue_lines: Array = [
	"在这个世界上，隐藏着许多未解之谜。",
	"这是告示板的第二页：\n多加小心前面的路，魔法师可能会在附近出没！",
	"最后一页：祝你好运，冒险者！"
]
var portrait_tex: Texture2D = null

func _unhandled_input(event: InputEvent) -> void:
	if player_in_range and event.is_action_pressed("interact"):
		if not DialogManager.is_dialog_active():
			get_viewport().set_input_as_handled()
			DialogManager.show_dialogue(dialogue_lines, portrait_tex, "告示板")

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		$Label.show()
		player_in_range = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		$Label.hide()
		player_in_range = false
		if DialogManager.has_method("hide_dialogue"):
			DialogManager.hide_dialogue()
