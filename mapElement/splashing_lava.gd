extends Area2D

@onready var detection_area = $DetectionArea
@onready var lava_particles = $LavaParticles
@onready var interval_timer = $IntervalTimer
@onready var duration_timer = $DurationTimer

func _ready() -> void:
	detection_area.set_deferred("disabled", true)
	lava_particles.emitting = false
	
	interval_timer.timeout.connect(_on_interval_timer_timeout)
	duration_timer.timeout.connect(_on_duration_timer_timeout)
	body_entered.connect(_on_body_entered)
	
	interval_timer.start()


func _on_interval_timer_timeout() -> void:
	lava_particles.emitting = true
	duration_timer.start()
	
	#先让粒子喷发一段时间再开启碰撞检测，避免玩家在安全区外被粒子碰撞死
	await get_tree().create_timer(0.5).timeout
	detection_area.set_deferred("disabled", false)
	
	for body in get_overlapping_bodies():
		if body.name == "Player" or body.has_method("player_dead"):
			body.player_dead()

func _on_duration_timer_timeout() -> void:
	lava_particles.emitting = false
	detection_area.set_deferred("disabled", true)

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player" or body.has_method("player_dead"):
		body.player_dead()
