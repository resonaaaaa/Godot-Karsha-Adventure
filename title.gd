extends Node2D

@onready var master_slider: HSlider = $"SettingPanel/VBoxContainer/TabContainer/音频/MasterVolume/HSlider"
@onready var music_slider: HSlider = $"SettingPanel/VBoxContainer/TabContainer/音频/MusicVolume/HSlider"
@onready var sfx_slider: HSlider = $"SettingPanel/VBoxContainer/TabContainer/音频/SFXVolume/HSlider"
@onready var ui_slider: HSlider = $"SettingPanel/VBoxContainer/TabContainer/音频/UIVolume/HSlider"
@onready var mute_checkbox: CheckBox = $"SettingPanel/VBoxContainer/TabContainer/音频/MuteCheckBox"

@onready var resolution_option: OptionButton = $"SettingPanel/VBoxContainer/TabContainer/画面/Resolution/OptionButton"
@onready var fullscreen_checkbox: CheckBox = $"SettingPanel/VBoxContainer/TabContainer/画面/Fullscreen"

@onready var default_button: Button = $"SettingPanel/VBoxContainer/HBoxContainer/DefaultButton"
@onready var close_button: Button = $"SettingPanel/VBoxContainer/HBoxContainer/CloseButton"

@onready var exit_button: Button = $VBoxContainer/ExitGame

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	exit_button.pressed.connect(_on_exit_game_pressed)
	default_button.pressed.connect(_on_setting_default_button_pressed)
	close_button.pressed.connect(_on_setting_close_button_pressed)
	
	master_slider.value_changed.connect(_on_master_volume_changed)
	music_slider.value_changed.connect(_on_music_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	ui_slider.value_changed.connect(_on_ui_volume_changed)
	mute_checkbox.toggled.connect(_on_mute_toggled)
	
	resolution_option.item_selected.connect(_on_resolution_selected)
	fullscreen_checkbox.toggled.connect(_on_fullscreen_toggled)

	_init_audio_settings()
	_init_video_settings()

func _init_audio_settings() -> void:
	master_slider.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master"))) * 100
	var bgm_idx = AudioServer.get_bus_index("BGM") if AudioServer.get_bus_index("BGM") >= 0 else AudioServer.get_bus_index("Master")
	music_slider.value = db_to_linear(AudioServer.get_bus_volume_db(bgm_idx)) * 100
	var sfx_idx = AudioServer.get_bus_index("SE") if AudioServer.get_bus_index("SE") >= 0 else AudioServer.get_bus_index("Master")
	sfx_slider.value = db_to_linear(AudioServer.get_bus_volume_db(sfx_idx)) * 100
	var ui_idx = AudioServer.get_bus_index("UI") if AudioServer.get_bus_index("UI") >= 0 else AudioServer.get_bus_index("Master")
	ui_slider.value = db_to_linear(AudioServer.get_bus_volume_db(ui_idx)) * 100
	mute_checkbox.button_pressed = AudioServer.is_bus_mute(AudioServer.get_bus_index("Master"))

func _init_video_settings() -> void:
	fullscreen_checkbox.button_pressed = (get_window().mode == Window.MODE_FULLSCREEN)
	var win_size = get_window().size
	if win_size == Vector2i(1620, 1080):
		resolution_option.selected = 0
	elif win_size == Vector2i(1080, 720):
		resolution_option.selected = 1

func _on_new_game_pressed() -> void:
	$NewGameWarning.popup()

func _on_game_setting_pressed() -> void:
	$SettingPanel.popup()

func _on_exit_game_pressed() -> void:
	get_tree().quit()

func _on_master_volume_changed(value: float) -> void:
	var bus_idx = AudioServer.get_bus_index("Master")
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value / 100.0))

func _on_music_volume_changed(value: float) -> void:
	var bus_idx = AudioServer.get_bus_index("BGM")
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value / 100.0))

func _on_sfx_volume_changed(value: float) -> void:
	var bus_idx = AudioServer.get_bus_index("SE")
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value / 100.0))

func _on_ui_volume_changed(value: float) -> void:
	var bus_idx = AudioServer.get_bus_index("UI")
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value / 100.0))

func _on_mute_toggled(button_pressed: bool) -> void:
	var bus_idx = AudioServer.get_bus_index("Master")
	if bus_idx >= 0:
		AudioServer.set_bus_mute(bus_idx, button_pressed)

func _on_resolution_selected(index: int) -> void:
	if index == 0:
		get_window().size = Vector2i(1620, 1080)
	elif index == 1:
		get_window().size = Vector2i(1080, 720)

func _on_fullscreen_toggled(button_pressed: bool) -> void:
	if button_pressed:
		get_window().mode = Window.MODE_FULLSCREEN
	else:
		get_window().mode = Window.MODE_WINDOWED

func _on_setting_default_button_pressed() -> void:
	master_slider.value = 50.0
	music_slider.value = 50.0
	sfx_slider.value = 50.0
	ui_slider.value = 50.0
	mute_checkbox.button_pressed = false
	
	resolution_option.selected = 0
	_on_resolution_selected(0)
	
	fullscreen_checkbox.button_pressed = false

func _on_setting_close_button_pressed() -> void:
	$SettingPanel.hide()
