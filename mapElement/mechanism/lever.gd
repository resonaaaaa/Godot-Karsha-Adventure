extends Area2D

signal lever_toggled(lever_id: int, switch_state: int)

@export_enum("red", "green") var color = "red"
var texture_red_right = preload("res://asset/TileSet/Other/switchRed_right.png")
var texture_red_left = preload("res://asset/TileSet/Other/switchRed_left.png")
var texture_red_mid = preload("res://asset/TileSet/Other/switchRed_mid.png")

@export var lever_id: int = 0

var texture_green_right = preload("res://asset/TileSet/Other/switchGreen_right.png")
var texture_green_left = preload("res://asset/TileSet/Other/switchGreen_left.png")
var texture_green_mid = preload("res://asset/TileSet/Other/switchGreen_mid.png")

var player_in_range = false
var player_node = null

var interact_cooldown = 0.2
var left_offset = Vector2(-9, 5)
var right_offset = Vector2(9, 5)


enum SwitchState { LEFT, MID, RIGHT }
var switch_state = SwitchState.MID


func _ready() -> void:
	match color:
		"red":
			$Sprite2D.texture = texture_red_mid
		"green":
			$Sprite2D.texture = texture_green_mid

func _physics_process(delta: float) -> void:
	if interact_cooldown > 0:
		interact_cooldown -= delta

	if player_in_range and Input.is_action_just_pressed("interact") and interact_cooldown <= 0:
		#玩家在左侧,向左拨一次
		if player_node.global_position.x < global_position.x:
			switch_state = switch_state - 1 if switch_state > SwitchState.LEFT else SwitchState.LEFT
		#玩家在右侧,向右拨一次
		else:
			switch_state = switch_state + 1 if switch_state < SwitchState.RIGHT else SwitchState.RIGHT

		AudioManager.play_se("res://asset/audio/SE/lever.wav")
		lever_toggled.emit(lever_id, switch_state)

		match color:
			"red":
				match switch_state:
					SwitchState.LEFT:
						$Sprite2D.texture = texture_red_left
						$Sprite2D.position = left_offset
					SwitchState.MID:
						$Sprite2D.texture = texture_red_mid
						$Sprite2D.position = Vector2.ZERO
					SwitchState.RIGHT:
						$Sprite2D.texture = texture_red_right
						$Sprite2D.position = right_offset
			"green":
				match switch_state:
					SwitchState.LEFT:
						$Sprite2D.texture = texture_green_left
						$Sprite2D.position = left_offset
					SwitchState.MID:
						$Sprite2D.texture = texture_green_mid
						$Sprite2D.position = Vector2.ZERO
					SwitchState.RIGHT:
						$Sprite2D.texture = texture_green_right
						$Sprite2D.position = right_offset
		interact_cooldown = 0.2

func _on_sensor_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = true
		player_node = body
		$Tips.show()

func _on_sensor_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		player_node = null
		$Tips.hide()
