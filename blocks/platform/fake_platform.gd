extends StaticBody2D
#假平台：踩上后闪烁0.5秒后消失，1秒后重新出现

@export var disappear_time: float = 0.5
@export var reappear_time: float = 1
@export var blink_interval: float = 0.1

var is_disappeared: bool = false
var _blink_timer: Timer

func _ready() -> void:
	is_disappeared = false
	_blink_timer = Timer.new()
	_blink_timer.wait_time = blink_interval
	_blink_timer.one_shot = false
	add_child(_blink_timer)
	_blink_timer.timeout.connect(_on_blink_timeout)

func _on_blink_timeout() -> void:
	var c: Color = $Sprite2D.modulate
	c.a = 0.25 if c.a > 0.5 else 1.0
	$Sprite2D.modulate = c

func _on_sensor_body_entered(body: Node2D) -> void:
	if body.name == "Player" and not is_disappeared:
		is_disappeared = true
		_blink_timer.start()
		await get_tree().create_timer(disappear_time).timeout
		
		# 停止闪烁并消失
		_blink_timer.stop()
		$Sprite2D.modulate.a = 1.0
		$Sprite2D.visible = false
		if has_node("CollisionShape2D"):
			$CollisionShape2D.set_deferred("disabled", true)
			
		await get_tree().create_timer(reappear_time).timeout
		
		# 恢复原状
		$Sprite2D.visible = true
		if has_node("CollisionShape2D"):
			$CollisionShape2D.set_deferred("disabled", false)
		is_disappeared = false

		
