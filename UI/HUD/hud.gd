extends CanvasLayer
signal new_game
signal retry

var key_texture_empty = preload("res://asset/TileSet/Items/outlineKey.png")
var key_texture_red = preload("res://asset/TileSet/Items/keyRed.png")
var key_texture_green = preload("res://asset/TileSet/Items/keyGreen.png")
var flower_texture_red: Texture2D = preload("res://asset/TileSet/Items/redCrystal.png")
var flower_texture_blue = preload("res://asset/TileSet/Items/blueCrystal.png")
var flower_texture_empty = preload("res://asset/Tileset/Items/outlineCrystal.png")

@onready var _red_flower_ui: Sprite2D = $RedFlowerUI
@onready var _blue_flower_ui: Sprite2D = $BlueFlowerUI

@onready var master_slider: HSlider = $SettingPanel/VBoxContainer/TabContainer/音频/MasterVolume/HSlider
@onready var music_slider: HSlider = $SettingPanel/VBoxContainer/TabContainer/音频/MusicVolume/HSlider
@onready var sfx_slider: HSlider = $SettingPanel/VBoxContainer/TabContainer/音频/SFXVolume/HSlider
@onready var ui_slider: HSlider = $SettingPanel/VBoxContainer/TabContainer/音频/UIVolume/HSlider
@onready var mute_checkbox: CheckBox = $SettingPanel/VBoxContainer/TabContainer/音频/MuteCheckBox

@onready var resolution_option: OptionButton = $SettingPanel/VBoxContainer/TabContainer/画面/Resolution/OptionButton
@onready var fullscreen_checkbox: CheckBox = $SettingPanel/VBoxContainer/TabContainer/画面/Fullscreen

func _ready() -> void:
	$PauseMenu.hide()
	$PauseMessage.hide()
	$PauseButton.button_pressed = false
	
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



func _process(delta: float) -> void:
	if Input.is_action_just_pressed("menu"):
		$PauseButton.button_pressed = not $PauseButton.button_pressed

func show_game_over():
	show_message("GAME OVER")
	await $MessageTimer.timeout
	# 不直接重载场景，而是显示重试按钮，让关卡决定如何重置玩家位置
	$RetryButton.show()
	$Message.show()
	$RetryButton.visible = true

func show_game_win():
	show_message("You Win!")


func show_new_game():
	$Message.text = "Adventure"
	$Message.show()
	$StartButton.show()
	$RedKeyUI.texture = key_texture_empty
	$GreenKeyUI.texture = key_texture_empty

func show_message(text):
	$Message.text = text
	$Message.show()
	$MessageTimer.start()
	
func show_saving_massage():
	var saved_message := $SavedMessage
	if saved_message == null:
		return
	if saved_message.has_meta("fade_tween"):
		var old_tween = saved_message.get_meta("fade_tween")
		if old_tween and old_tween.is_valid():
			old_tween.kill()
	var tween = create_tween()
	saved_message.show()
	saved_message.modulate.a = 0.0
	tween.tween_property(saved_message, "modulate:a", 1.0, 0.18)
	tween.tween_interval(0.5)
	tween.tween_property(saved_message, "modulate:a", 0.0, 0.25)
	saved_message.set_meta("fade_tween", tween)
	await tween.finished
	saved_message.hide()
	
func _on_start_button_pressed() -> void:
	# 隐藏按钮和消息
	$StartButton.hide()
	$Message.hide()
	new_game.emit()

func setup_level(level_num: int):
	$RedKeyUI.texture = key_texture_empty
	$GreenKeyUI.texture = key_texture_empty
	$RedFlowerUI.hide()
	$BlueFlowerUI.hide()
	if level_num == 1:
		$RedKeyUI.show()
		$GreenKeyUI.hide()
	else:
		$RedKeyUI.show()
		$GreenKeyUI.show()

#================================
#拾取物UI更新
func show_red_key_ui():
	$RedKeyUI.texture = key_texture_red

func show_green_key_ui():
	$GreenKeyUI.texture = key_texture_green

func show_flower_ui():
	$RedFlowerUI.show()
	$BlueFlowerUI.show()

func set_red_flower_ui():
	$RedFlowerUI.texture = flower_texture_red

func set_blue_flower_ui():
	$BlueFlowerUI.texture = flower_texture_blue

func apply_player_state(state: Dictionary) -> void:
	if state.is_empty():
		return
	$RedKeyUI.texture = key_texture_empty
	$GreenKeyUI.texture = key_texture_empty
	if state.get("has_key_red", false):
		show_red_key_ui()
	if state.get("has_key_green", false):
		show_green_key_ui()
	var has_red_flower = state.get("has_red_flower", false)
	var has_blue_flower = state.get("has_blue_flower", false)
	if has_red_flower or has_blue_flower:
		show_flower_ui()
		if has_red_flower:
			set_red_flower_ui()
		if has_blue_flower:
			set_blue_flower_ui()

#================================
#暂停菜单设置相关

#检测暂停状态是否切换
func _on_pause_button_toggled(toggled_on: bool) -> void:
	var tree = get_tree()
	tree.paused = toggled_on
	if toggled_on:
		$PauseMessage.show()
		$PauseMenu.popup_centered()
	else :
		$PauseMessage.hide()
		$PauseMenu.hide()

#隐藏暂停菜单时同步恢复游戏状态
func _on_pause_menu_popup_hide() -> void:
	if $PauseButton.button_pressed:
		$PauseButton.button_pressed = false
	get_tree().paused = false
	$PauseMessage.hide()

func _on_pause_button_mouse_entered() -> void:
	$PauseText.show()

func _on_pause_button_mouse_exited() -> void:
	$PauseText.hide()

#继续游戏
func _on_continue_button_pressed() -> void:
	get_tree().paused = false
	$PauseMessage.hide()
	$PauseMenu.hide()


func _on_restart_button_pressed() -> void:
	var tree = get_tree()
	if tree.paused:
		tree.paused = false
	$PauseButton.button_pressed = false
	$PauseMessage.hide()
	$PauseMenu.hide()
	$PauseText.hide()
	call_deferred("_reload_scene")

func _reload_scene() -> void:
	get_tree().reload_current_scene()

#================================
#设置菜单相关

#打开设置菜单
func _on_setting_button_pressed() -> void:
	$PauseMenu.hide()
	$SettingPanel.popup_centered()

#关闭设置菜单，返回暂停菜单
func _on_setting_close_button_pressed() -> void:
	$SettingPanel.hide()
	$PauseMenu.popup_centered()

#恢复默认设置
func _on_setting_default_button_pressed() -> void:
	master_slider.value = 50.0
	music_slider.value = 50.0
	sfx_slider.value = 50.0
	ui_slider.value = 50.0
	mute_checkbox.button_pressed = false
	
	resolution_option.selected = 0
	_on_resolution_selected(0)
	
	fullscreen_checkbox.button_pressed = false

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

func _on_retry_button_pressed() -> void:
	var tree = get_tree()
	if tree.paused:
		tree.paused = false
	$PauseButton.button_pressed = false
	$PauseMessage.hide()
	$PauseMenu.hide()
	$PauseText.hide()
	$RetryButton.hide()
	$Message.hide()
	emit_signal("retry")
