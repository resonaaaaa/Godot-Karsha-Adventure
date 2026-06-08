extends Node2D

var opening_lines: Array = [
	"欢迎来到卡莎的冒险！",
	"这是一个充满魔法和谜题的世界，等待着勇敢的冒险者去探索。",
	"在旅途中，你将遇到各种挑战和敌人，但也会结识新的朋友。",
    "准备好了？出发吧，冒险者！"
]

@onready var player: AnimatedSprite2D = $Player
var is_moving: bool = false

func _ready() -> void:
	AudioManager.play_bgm("res://asset/audio/BGM/start.mp3")
	DialogManager.connect("dialog_finished", Callable(self, "_on_dialog_finished"))
	DialogManager.show_dialogue(opening_lines, null, "旁白")
	

func _on_dialog_finished() -> void:
	DialogManager.disconnect("dialog_finished", Callable(self, "_on_dialog_finished"))
	is_moving = true
	if player:
		player.play("walk")

func _process(delta: float) -> void:
	if is_moving and player:
		player.position.x += 200 * delta
		if player.position.x > get_viewport_rect().size.x + 100:
			is_moving = false
			Game._load_level(0)
