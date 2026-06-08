extends Node2D

@onready var player: AnimatedSprite2D = $Player
@onready var path_2d: Path2D = $Path2D
@onready var credits_root: Control = $CreditsLayer/CreditsRoot
@onready var credits_scroll_container: ScrollContainer = $CreditsLayer/CreditsRoot/CreditsScroll
@onready var credits_label: RichTextLabel = $CreditsLayer/CreditsRoot/CreditsScroll/CreditsText
@onready var return_button: Button = $CreditsLayer/CreditsRoot/ReturnButton

const TITLE_SCENE_PATH := "res://title/title.tscn"
enum EndState {
	MOVE_ALONG_PATH,
	WAIT_DIALOG,
	SHOW_CREDITS,
	RETURNING
}

@export var path_speed: float = 180.0
@export var credits_scroll_speed: float = 38.0
@export var credits_auto_return_delay: float = 1.0
@export_multiline var end_dialogue_text: String = ""

var state: EndState = EndState.MOVE_ALONG_PATH
var credits_auto_return_timer: float = -1.0
var credits_scroll_started: bool = false
var path_progress: float = 0.0
var path_length: float = 0.0
var _last_player_x: float = 0.0
var _credits_fade_tween: Tween

func _ready() -> void:
	AudioManager.play_bgm("res://asset/audio/BGM/end.mp3")
	return_button.pressed.connect(_on_return_button_pressed)
	return_button.visible = false
	credits_root.visible = false
	_setup_path_motion()

	var dialog_finished_callable := Callable(self, "_on_dialog_finished")
	if not DialogManager.is_connected("dialog_finished", dialog_finished_callable):
		DialogManager.connect("dialog_finished", dialog_finished_callable)

func _process(delta: float) -> void:
	match state:
		EndState.MOVE_ALONG_PATH:
			_update_player_motion(delta)
		EndState.SHOW_CREDITS:
			_update_credits_scroll(delta)

func _setup_path_motion() -> void:
	if path_2d == null or path_2d.curve == null or player == null:
		return
	path_length = path_2d.curve.get_baked_length()
	
	path_progress = path_2d.curve.get_closest_offset(player.global_position)
	player.global_position = path_2d.to_global(path_2d.curve.sample_baked(path_progress))
	_last_player_x = player.global_position.x
	player.play("walk")

func _update_player_motion(delta: float) -> void:
	if player == null or path_2d == null or path_2d.curve == null:
		return
	
	path_progress = min(path_progress + path_speed * delta, path_length)
	var p := path_2d.curve.sample_baked(path_progress)
	player.global_position = path_2d.to_global(p)


	if not player.is_playing():
		player.play("walk")

	#保证玩家始终面向前进方向
	if player.global_position.x != _last_player_x:
		player.flip_h = player.global_position.x < _last_player_x
		_last_player_x = player.global_position.x

	if player.global_position.x >= get_viewport_rect().size.x + 20:
		state = EndState.WAIT_DIALOG
		player.stop()
		DialogManager.show_dialogue(_get_end_dialogue_lines(), null, "旁白")

func _on_dialog_finished() -> void:
	if state != EndState.WAIT_DIALOG:
		return
	_show_credits()

func _show_credits() -> void:
	state = EndState.SHOW_CREDITS
	credits_root.visible = true
	credits_root.modulate = Color(1.0, 1.0, 1.0, 0.0)
	return_button.visible = true
	return_button.disabled = true
	player.visible = false
	credits_scroll_container.scroll_vertical = 0
	credits_auto_return_timer = -1.0
	credits_scroll_started = false
	if is_instance_valid(_credits_fade_tween):
		_credits_fade_tween.kill()
	_credits_fade_tween = create_tween()
	_credits_fade_tween.tween_property(credits_root, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.8)
	_credits_fade_tween.tween_callback(func () -> void:
		return_button.disabled = false
	)
	call_deferred("_start_credits_scroll")

func _start_credits_scroll() -> void:
	# wait until the v scrollbar has a meaningful max_value
	var vbar = credits_scroll_container.get_v_scroll_bar()
	if vbar == null:
		# try again next frame
		call_deferred("_start_credits_scroll")
		return
	if vbar.max_value <= 0:
		# content not measured yet, retry next frame
		call_deferred("_start_credits_scroll")
		return
	# ready to start
	credits_scroll_container.scroll_vertical = 0
	credits_scroll_started = true

func _update_credits_scroll(delta: float) -> void:
	if credits_auto_return_timer >= 0.0:
		credits_auto_return_timer -= delta
		if credits_auto_return_timer <= 0.0:
			_go_to_title()
		return

	if credits_root == null or not credits_root.visible:
		return

	var max_scroll := int(credits_scroll_container.get_v_scroll_bar().max_value)
	if max_scroll <= 0:
		return
	credits_scroll_started = true

	var next_scroll := int(min(float(credits_scroll_container.scroll_vertical) + credits_scroll_speed * delta, float(max_scroll)))
	credits_scroll_container.scroll_vertical = next_scroll

	if credits_scroll_started and credits_scroll_container.scroll_vertical >= max_scroll:
		credits_auto_return_timer = credits_auto_return_delay

func _on_return_button_pressed() -> void:
	AudioManager.play_ui("res://asset/audio/UI/click.wav")
	_go_to_title()

func _go_to_title() -> void:
	if state == EndState.RETURNING:
		return
	state = EndState.RETURNING
	get_tree().change_scene_to_file(TITLE_SCENE_PATH)

func _get_end_dialogue_lines() -> Array[String]:
	var lines: Array[String] = []
	for line in end_dialogue_text.split("\n", false):
		var trimmed := line.strip_edges()
		if not trimmed.is_empty():
			lines.append(trimmed)
	return lines
