extends StaticBody2D

var texture_red_up = preload("res://asset/TileSet/Other/doorRed_top.png")
var texture_red_mid = preload("res://asset/TileSet/Other/doorRed_lock.png")
var texture_red_down = preload("res://asset/TileSet/Other/doorRed.png")
#预加载完成后才可调用(onready)，否则读取到的是空值
@onready var texture_red = [texture_red_up, texture_red_mid, texture_red_down]

var texture_green_up = preload("res://asset/TileSet/Other/doorGreen_top.png")
var texture_green_mid = preload("res://asset/TileSet/Other/doorGreen_lock.png")
var texture_green_down = preload("res://asset/TileSet/Other/doorGreen.png")
@onready var texture_green = [texture_green_up, texture_green_mid, texture_green_down]

var texture_open_up = preload("res://asset/TileSet/Other/doorOpen_top.png")
var texture_open_mid = preload("res://asset/TileSet/Other/doorOpen.png")
var texture_open_down = preload("res://asset/TileSet/Other/doorOpen.png")
@onready var texture_open = [texture_open_up, texture_open_mid, texture_open_down]

var is_open = false
@export_enum("red", "green") var color = "red"

@export var is_lever_controlled = false
@export var correct_solution = {}    #使用字典存储每个开关对应的正确状态

func _ready() -> void:
	is_open = false
	add_to_group("checkpoint_stateful")
	if color == "red":
		$Sprite/TextureDoorUp.texture = texture_red[0]
		$Sprite/TextureDoorMid.texture = texture_red[1]
		$Sprite/TextureDoorDown.texture = texture_red[2]
	else:
		$Sprite/TextureDoorUp.texture = texture_green[0]
		$Sprite/TextureDoorMid.texture = texture_green[1]
		$Sprite/TextureDoorDown.texture = texture_green[2]

func checkpoint_get_state() -> Dictionary:
	return {"is_open": is_open}

func checkpoint_set_state(state: Dictionary) -> void:
	if state == null:
		return
	var open = state.get("is_open", false)
	door_switch_toggled(open)

func lever_toggled(lever_id: int, switch_state: int) -> void:
	if not is_lever_controlled:
		return
	#检查当前所有开关状态是否满足条件
	for id in correct_solution.keys():
		var required_state = correct_solution[id]
		var current_state = DialogManager.get_lever_state(id)
		if current_state != required_state:
			door_switch_toggled(false)
			return
	door_switch_toggled(true)	

func door_switch_toggled(is_on: bool) -> void:
	if is_open == is_on:
		return
	is_open = is_on
	AudioManager.play_se("res://asset/audio/SE/door.wav")
	if is_open:
		#禁用碰撞
		$CollisionShape2D.disabled = true
		$Sprite/TextureDoorUp.texture = texture_open[0]
		$Sprite/TextureDoorMid.texture = texture_open[1]
		$Sprite/TextureDoorDown.texture = texture_open[2]
	else:
		$CollisionShape2D.disabled = false
		if color == "red":
			$Sprite/TextureDoorUp.texture = texture_red[0]
			$Sprite/TextureDoorMid.texture = texture_red[1]
			$Sprite/TextureDoorDown.texture = texture_red[2]
		else:
			$Sprite/TextureDoorUp.texture = texture_green[0]
			$Sprite/TextureDoorMid.texture = texture_green[1]
			$Sprite/TextureDoorDown.texture = texture_green[2]
	
