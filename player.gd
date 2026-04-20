extends Area2D
var speed = 250
var screen_size = Vector2.ZERO
var pos = Vector2(60,80)

func _ready() -> void:
	screen_size = get_viewport_rect().size
	start()


func _process(delta: float) -> void:
	var target_anim = "stay"
	var velocity = Vector2.ZERO

	if Input.is_action_pressed("move_left"):
		target_anim = "right"
		velocity.x -= 1
		
	if Input.is_action_pressed("move_right"):
		target_anim = "right"
		velocity.x += 1

	if velocity.x != 0:
		velocity = velocity.normalized() * speed
		position += velocity * delta
		position = position.clamp(Vector2.ZERO, screen_size)
		$AnimatedSprite2D.flip_v = false
		$AnimatedSprite2D.flip_h = velocity.x < 0

	if $AnimatedSprite2D.animation != target_anim:
		$AnimatedSprite2D.play(target_anim)
	
func start():
	position = pos
		
