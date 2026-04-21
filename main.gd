extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func game_over():
	$HUD.show_game_over()
	$Player.hide()
	$Player.set_physics_process(false)
	$HUD.show_new_game()

	
func _on_hud_new_game() -> void:
	$Player.position = $StartPosition.position
	$Player.show()
	$Player.set_physics_process(true)
	
