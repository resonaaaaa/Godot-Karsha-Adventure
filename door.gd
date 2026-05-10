extends StaticBody2D
#机关门：在玩家拉下开关后打开，没有碰撞体积，打开后玩家进入时会被传送到屋子里。
#屋子里有magician master，他会教授player使用宝石魔法。
#为屋子创建一个新场景，实现对话框。
#增加一个flag，防止玩家重复进入屋子里。

@export var open: bool = false
@export var door_open_texture: Texture2D
@export var door_closed_texture: Texture2D
@export var teleport_position: Vector2
var has_entered: bool = false

func _ready() -> void:
	$Sprite.texture = door_closed_texture

func open_door() -> void:
	open = true
	$Sprite.texture = door_open_texture

func _on_body_entered(body: Node2D) -> void:
	if open:
		if body.name == "Player" and not has_entered:
			has_entered = true
			body.position = teleport_position
	else:
		pass
