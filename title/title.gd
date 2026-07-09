extends Node2D

@onready var master_slider: HSlider = $"SettingPanel/VBoxContainer/TabContainer/音频/MasterVolume/HSlider"
@onready var music_slider: HSlider = $"SettingPanel/VBoxContainer/TabContainer/音频/MusicVolume/HSlider"
@onready var sfx_slider: HSlider = $"SettingPanel/VBoxContainer/TabContainer/音频/SFXVolume/HSlider"
@onready var ui_slider: HSlider = $"SettingPanel/VBoxContainer/TabContainer/音频/UIVolume/HSlider"
@onready var mute_checkbox: CheckBox = $"SettingPanel/VBoxContainer/TabContainer/音频/MuteCheckBox"

@onready var default_button: Button = $"SettingPanel/VBoxContainer/HBoxContainer/DefaultButton"
@onready var close_button: Button = $"SettingPanel/VBoxContainer/HBoxContainer/CloseButton"

@onready var exit_button: Button = $VBoxContainer/ExitGame
@onready var continue_button: Button = $VBoxContainer/ContinueGame
@onready var sure_button: Button = $NewGameWarning/VBoxContainer/HBoxContainer/SureButton
@onready var cancel_button: Button = $NewGameWarning/VBoxContainer/HBoxContainer/CancleButton

var audio_settings_ready: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	AudioManager.play_bgm("res://asset/audio/BGM/title.mp3")
	
	# 强制窗口模式，固定 1080x720 分辨率
	var window := get_window()
	window.mode = Window.MODE_WINDOWED
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	window.size = Vector2i(1080, 720)
	window.min_size = Vector2i(1080, 720)
	window.max_size = Vector2i(1080, 720)
	
	exit_button.pressed.connect(_on_exit_game_pressed)
	continue_button.pressed.connect(_on_continue_game_pressed)
	sure_button.pressed.connect(_on_sure_button_pressed)
	cancel_button.pressed.connect(_on_cancel_button_pressed)
	
	default_button.pressed.connect(_on_setting_default_button_pressed)
	close_button.pressed.connect(_on_setting_close_button_pressed)
	
	master_slider.value_changed.connect(_on_master_volume_changed)
	music_slider.value_changed.connect(_on_music_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	ui_slider.value_changed.connect(_on_ui_volume_changed)
	mute_checkbox.toggled.connect(_on_mute_toggled)

	_init_audio_settings()
	audio_settings_ready = true
	
	if Game.save_data.get("unlocked_levels", 0) > 0:
		continue_button.disabled = false
	else:
		continue_button.disabled = true

func _init_audio_settings() -> void:
	var settings = Game.save_data.get("settings", {})
	master_slider.value = settings.get("master_volume", 50.0)
	music_slider.value = settings.get("bgm_volume", 50.0)
	sfx_slider.value = settings.get("sfx_volume", 50.0)
	ui_slider.value = settings.get("ui_volume", 50.0)
	mute_checkbox.button_pressed = settings.get("mute", false)

func _on_new_game_pressed() -> void:
	AudioManager.play_ui("res://asset/audio/UI/click.wav")
	if Game.save_data.get("unlocked_levels", 0) > 0:
		$NewGameWarning.popup()
	else:
		_start_new_game()

func _on_continue_game_pressed() -> void:
	AudioManager.play_ui("res://asset/audio/UI/start.wav")
	var level = min(Game.save_data.get("unlocked_levels", 0), Game.level_paths.size() - 1)
	Game._load_level(level)

func _on_sure_button_pressed() -> void:
	AudioManager.play_ui("res://asset/audio/UI/click.wav")
	$NewGameWarning.hide()
	_start_new_game()

func _on_cancel_button_pressed() -> void:
	AudioManager.play_ui("res://asset/audio/UI/click.wav")
	$NewGameWarning.hide()

func _start_new_game() -> void:
	Game.save_data["unlocked_levels"] = 0
	Game._save_game()
	Game._load_start_scene()

func _on_game_setting_pressed() -> void:
	AudioManager.play_ui("res://asset/audio/UI/click.wav")
	$SettingPanel.popup()

func _on_exit_game_pressed() -> void:
	AudioManager.play_ui("res://asset/audio/UI/click.wav")
	get_tree().quit()

func _on_master_volume_changed(value: float) -> void:
	var bus_idx = AudioServer.get_bus_index("Master")
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value / 100.0))
	if audio_settings_ready:
		AudioManager.play_se("res://asset/audio/SE/jump.mp3")
	Game.save_data["settings"]["master_volume"] = value
	Game._save_game()

func _on_music_volume_changed(value: float) -> void:
	var bus_idx = AudioServer.get_bus_index("BGM")
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value / 100.0))
	if audio_settings_ready:
		AudioManager.play_se("res://asset/audio/SE/jump.mp3")
	Game.save_data["settings"]["bgm_volume"] = value
	Game._save_game()

func _on_sfx_volume_changed(value: float) -> void:
	var bus_idx = AudioServer.get_bus_index("SE")
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value / 100.0))
	if audio_settings_ready:
		AudioManager.play_se("res://asset/audio/SE/jump.mp3")
	Game.save_data["settings"]["sfx_volume"] = value
	Game._save_game()

func _on_ui_volume_changed(value: float) -> void:
	var bus_idx = AudioServer.get_bus_index("UI")
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value / 100.0))
	if audio_settings_ready:
		AudioManager.play_se("res://asset/audio/SE/jump.mp3")
	Game.save_data["settings"]["ui_volume"] = value
	Game._save_game()

func _on_mute_toggled(button_pressed: bool) -> void:
	AudioManager.play_ui("res://asset/audio/UI/click.wav")
	var bus_idx = AudioServer.get_bus_index("Master")
	if bus_idx >= 0:
		AudioServer.set_bus_mute(bus_idx, button_pressed)
	Game.save_data["settings"]["mute"] = button_pressed
	Game._save_game()

func _on_setting_default_button_pressed() -> void:
	AudioManager.play_ui("res://asset/audio/UI/click.wav")
	master_slider.value = 50.0
	music_slider.value = 50.0
	sfx_slider.value = 50.0
	ui_slider.value = 50.0
	mute_checkbox.button_pressed = false
	
	Game._save_game()

func _on_setting_close_button_pressed() -> void:
	AudioManager.play_ui("res://asset/audio/UI/click.wav")
	$SettingPanel.hide()
