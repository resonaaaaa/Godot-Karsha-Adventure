extends StaticBody2D
@export var platform_speed = 100.0
#平台的目的地
@export var platform_target_position = [Vector2.ZERO, Vector2(300, 0)]
var direction = 1
var platform_velocity = Vector2.ZERO
var rider = []

func _ready() -> void:
	for i in range(platform_target_position.size()):
		platform_target_position[i] += position

func _physics_process(delta: float) -> void:
	var target = platform_target_position[direction]
	var to_target = target - position
	#防止超出目标点
	if to_target.length() < platform_speed * delta:
		position = target
		#换下一个目的地
		direction = (direction + 1) % platform_target_position.size()
	else:
		platform_velocity = to_target.normalized() * platform_speed
		position += platform_velocity * delta
		for body in rider:
			body.on_platform_move(platform_velocity * delta)


func _on_sensor_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		rider.append(body)


func _on_sensor_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		rider.erase(body)
