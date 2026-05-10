extends Area2D

@export var speed := 700.0
@export var life_time := 1.0
@export var explosion_time := 0.4

var direction := Vector2.RIGHT
var _exploding := false

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var explosion_particles: GPUParticles2D = $ExplosionParticles

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	_explode_after_delay()

func set_direction(dir: Vector2) -> void:
	if dir.length() == 0.0:
		return
	direction = dir.normalized()
	$Sprite2D.flip_h = direction.x < 0.0
		

func _physics_process(delta: float) -> void:
	if _exploding:
		return
	global_position += direction * speed * delta

func _on_body_entered(body: Node) -> void:
	if _exploding:
		return
	if body.is_in_group("player"):
		return
	if body.has_method("die"):
		body.die()
	if body.has_method("break_block"):
		body.break_block()
	_explode()

func _on_area_entered(area: Area2D) -> void:
	if _exploding:
		return
	if area.has_method("die"):
		area.die()
		_explode()

func _explode_after_delay() -> void:
	await get_tree().create_timer(life_time).timeout
	_explode()

func _explode() -> void:
	if _exploding:
		return
	_exploding = true
	if collision != null:
		collision.set_deferred("disabled", true)
	if sprite != null:
		sprite.hide()
	if explosion_particles != null:
		explosion_particles.emitting = true
	await get_tree().create_timer(explosion_time).timeout
	if is_inside_tree():
		queue_free()
