extends CanvasLayer
signal new_game
signal retry

var key_texture_empty = preload("res://asset/TileSet/Items/outlineKey.png")
var key_texture_red = preload("res://asset/TileSet/Items/keyRed.png")
var key_texture_green = preload("res://asset/TileSet/Items/keyGreen.png")
var flower_texture_red: Texture2D = preload("res://asset/TileSet/Items/redCrystal.png")
var flower_texture_blue = preload("res://asset/TileSet/Items/blueCrystal.png")
var flower_texture_empty = preload("res://asset/TileSet/Items/outlineCrystal.png")


@onready var master_slider: HSlider = $SettingPanel/VBoxContainer/TabContainer/音频/MasterVolume/HSlider
@onready var music_slider: HSlider = $SettingPanel/VBoxContainer/TabContainer/音频/MusicVolume/HSlider
@onready var sfx_slider: HSlider = $SettingPanel/VBoxContainer/TabContainer/音频/SFXVolume/HSlider
@onready var ui_slider: HSlider = $SettingPanel/VBoxContainer/TabContainer/音频/UIVolume/HSlider
@onready var mute_checkbox: CheckBox = $SettingPanel/VBoxContainer/TabContainer/音频/MuteCheckBox



@onready var title_button: Button = $PauseMenu/VBoxContainer/TitleButton
@onready var exit_warning: PopupPanel = $ExitWarning
@onready var exit_cancel_button: Button = $ExitWarning/VBoxContainer/HBoxContainer/CancleButton
@onready var exit_sure_button: Button = $ExitWarning/VBoxContainer/HBoxContainer/SureButton

@onready var yellow_magic_ui: Label = $YellowGemMagicUI
@onready var green_magic_ui: Label = $GreenGemMagicUI

var audio_settings_ready: bool = false

func _ready() -> void:
	$PauseMenu.hide()
	$PauseMessage.hide()
	$PauseButton.button_pressed = false
	
	# 强制窗口模式，固定 1080x720 分辨率
	var window := get_window()
	window.mode = Window.MODE_WINDOWED
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	window.size = Vector2i(1080, 720)
	window.min_size = Vector2i(1080, 720)
	window.max_size = Vector2i(1080, 720)
	
	master_slider.value_changed.connect(_on_master_volume_changed)
	music_slider.value_changed.connect(_on_music_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	ui_slider.value_changed.connect(_on_ui_volume_changed)
	mute_checkbox.toggled.connect(_on_mute_toggled)
	
	title_button.pressed.connect(_on_title_button_pressed)
	exit_cancel_button.pressed.connect(_on_exit_cancel_button_pressed)
	exit_sure_button.pressed.connect(_on_exit_sure_button_pressed)
	
	_init_audio_settings()
	audio_settings_ready = true

func _init_audio_settings() -> void:
	master_slider.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master"))) * 100
	var bgm_idx = AudioServer.get_bus_index("BGM") if AudioServer.get_bus_index("BGM") >= 0 else AudioServer.get_bus_index("Master")
	music_slider.value = db_to_linear(AudioServer.get_bus_volume_db(bgm_idx)) * 100
	var sfx_idx = AudioServer.get_bus_index("SE") if AudioServer.get_bus_index("SE") >= 0 else AudioServer.get_bus_index("Master")
	sfx_slider.value = db_to_linear(AudioServer.get_bus_volume_db(sfx_idx)) * 100
	var ui_idx = AudioServer.get_bus_index("UI") if AudioServer.get_bus_index("UI") >= 0 else AudioServer.get_bus_index("Master")
	ui_slider.value = db_to_linear(AudioServer.get_bus_volume_db(ui_idx)) * 100
	mute_checkbox.button_pressed = AudioServer.is_bus_mute(AudioServer.get_bus_index("Master"))

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("menu"):
		$PauseButton.button_pressed = not $PauseButton.button_pressed
	_update_magic_cooldown_display()

#更新魔法冷却时间显示（右上角）
func _update_magic_cooldown_display() -> void:
	var player: Node = get_tree().get_first_node_in_group("player")
	if not player:
		return
	
	# 黄宝石魔法（护盾）
	if player.yellow_gem_magic_unlocked:
		yellow_magic_ui.visible = true
		if player.shield_cooldown_timer > 0:
			yellow_magic_ui.text = "黄宝石魔法：%ds" % ceili(player.shield_cooldown_timer)
		else:
			yellow_magic_ui.text = "黄宝石魔法：魔法已就绪"
	else:
		yellow_magic_ui.visible = false
	
	# 绿宝石魔法（缓降）
	if player.green_gem_magic_unlocked:
		green_magic_ui.visible = true
		if player.slow_descent_cooldown_timer > 0:
			green_magic_ui.text = "绿宝石魔法：%ds" % ceili(player.slow_descent_cooldown_timer)
		else:
			green_magic_ui.text = "绿宝石魔法：魔法已就绪"
	else:
		green_magic_ui.visible = false

#死亡后显示重试界面
func show_game_over():
	show_message("GAME OVER")
	await $MessageTimer.timeout
	$RetryButton.show()
	$Message.show()
	$RetryButton.visible = true

func show_game_win():	
	AudioManager.play_se("res://asset/audio/SE/level_completed.wav")	
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
	AudioManager.play_ui("res://asset/audio/UI/start.wav")
	# 禁用按钮防止动画期间受到多次点击
	$StartButton.disabled = true
	
	# 创建渐变动画
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property($StartButton, "modulate:a", 0.0, 0.5)
	tween.tween_property($Message, "modulate:a", 0.0, 0.5)
	await tween.finished
	
	# 隐藏按钮和消息
	$StartButton.hide()
	$Message.hide()
	
	# 恢复透明度和启用状态，以便下次（如重新开始时）能正常显示和点击
	$StartButton.modulate.a = 1.0
	$Message.modulate.a = 1.0
	$StartButton.disabled = false
	
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
	
	$RedFlowerUI.texture = flower_texture_empty
	$BlueFlowerUI.texture = flower_texture_empty
	
	if has_red_flower or has_blue_flower:
		show_flower_ui()
		if has_red_flower:
			set_red_flower_ui()
		if has_blue_flower:
			set_blue_flower_ui()
	else:
		$RedFlowerUI.hide()
		$BlueFlowerUI.hide()

#================================
#暂停菜单设置相关

#检测暂停状态是否切换
func _on_pause_button_toggled(toggled_on: bool) -> void:
	AudioManager.play_ui("res://asset/audio/UI/click.wav")
	var tree = get_tree()
	tree.paused = toggled_on
	if toggled_on:
		$PauseMessage.show()
		$PauseMenu.popup_centered()
	else :
		$PauseMessage.hide()
		$PauseMenu.hide()


func _on_pause_button_mouse_entered() -> void:
	$PauseText.show()

func _on_pause_button_mouse_exited() -> void:
	$PauseText.hide()

#继续游戏
func _on_continue_button_pressed() -> void:
	AudioManager.play_ui("res://asset/audio/UI/start.wav")
	get_tree().paused = false
	$PauseMessage.hide()
	$PauseMenu.hide()
	$PauseButton.button_pressed = false

func _on_restart_button_pressed() -> void:
	AudioManager.play_ui("res://asset/audio/UI/click.wav")
	$PauseMenu.hide()
	$RestartWarning.popup_centered()

func _on_restart_cancel_button_pressed() -> void:
	AudioManager.play_ui("res://asset/audio/UI/click.wav")
	$RestartWarning.hide()
	$PauseMenu.popup_centered()

func _on_restart_sure_button_pressed() -> void:
	AudioManager.play_ui("res://asset/audio/UI/click.wav")
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
	AudioManager.play_ui("res://asset/audio/UI/click.wav")
	$PauseMenu.hide()
	$SettingPanel.popup_centered()

#关闭设置菜单，返回暂停菜单
func _on_setting_close_button_pressed() -> void:
	AudioManager.play_ui("res://asset/audio/UI/click.wav")
	$SettingPanel.hide()
	$PauseMenu.popup_centered()

#返回标题相关
func _on_title_button_pressed() -> void:
	AudioManager.play_ui("res://asset/audio/UI/click.wav")
	$PauseMenu.hide()
	$ExitWarning.popup_centered()

func _on_exit_cancel_button_pressed() -> void:
	AudioManager.play_ui("res://asset/audio/UI/click.wav")
	$ExitWarning.hide()
	$PauseMenu.popup_centered()

func _on_exit_sure_button_pressed() -> void:
	AudioManager.play_ui("res://asset/audio/UI/click.wav")
	var tree = get_tree()
	if tree.paused:
		tree.paused = false
	$PauseButton.button_pressed = false
	$PauseMessage.hide()
	$PauseMenu.hide()
	$PauseText.hide()
	
	$ExitWarning.hide()
	
	
	get_tree().change_scene_to_file("res://title/title.tscn")

#恢复默认设置
func _on_setting_default_button_pressed() -> void:
	AudioManager.play_ui("res://asset/audio/UI/click.wav")
	master_slider.value = 50.0
	music_slider.value = 50.0
	sfx_slider.value = 50.0
	ui_slider.value = 50.0
	mute_checkbox.button_pressed = false

#================
#音量设置相关
func _on_master_volume_changed(value: float) -> void:
	var bus_idx = AudioServer.get_bus_index("Master")
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value / 100.0))
	if audio_settings_ready:
		AudioManager.play_se("res://asset/audio/SE/jump.mp3")

func _on_music_volume_changed(value: float) -> void:
	var bus_idx = AudioServer.get_bus_index("BGM")
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value / 100.0))
	if audio_settings_ready:
		AudioManager.play_se("res://asset/audio/SE/jump.mp3")

func _on_sfx_volume_changed(value: float) -> void:
	var bus_idx = AudioServer.get_bus_index("SE")
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value / 100.0))
	if audio_settings_ready:
		AudioManager.play_se("res://asset/audio/SE/jump.mp3")

func _on_ui_volume_changed(value: float) -> void:
	var bus_idx = AudioServer.get_bus_index("UI")
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value / 100.0))
	if audio_settings_ready:
		AudioManager.play_se("res://asset/audio/SE/jump.mp3")
#静音功能
func _on_mute_toggled(button_pressed: bool) -> void:
	AudioManager.play_ui("res://asset/audio/UI/click.wav")
	var bus_idx = AudioServer.get_bus_index("Master")
	if bus_idx >= 0:
		AudioServer.set_bus_mute(bus_idx, button_pressed)

#死亡后重试
func _on_retry_button_pressed() -> void:
	AudioManager.play_ui("res://asset/audio/UI/start.wav")
	# 禁用按钮防止动画期间受到多次点击
	$RetryButton.disabled = true
	
	# 创建渐变动画
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property($RetryButton, "modulate:a", 0.0, 0.5)
	tween.tween_property($Message, "modulate:a", 0.0, 0.5)
	await tween.finished
	
	var tree = get_tree()
	if tree.paused:
		tree.paused = false
	$PauseButton.button_pressed = false
	$PauseMessage.hide()
	$PauseMenu.hide()
	$PauseText.hide()
	$RetryButton.hide()
	$Message.hide()
	
	# 恢复透明度和启用状态
	$RetryButton.modulate.a = 1.0
	$Message.modulate.a = 1.0
	$RetryButton.disabled = false
	
	emit_signal("retry")
