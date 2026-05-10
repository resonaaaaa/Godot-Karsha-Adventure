extends CanvasLayer

@onready var panel = $Panel
@onready var portrait = $Panel/MarginContainer/HBoxContainer/Portrait
@onready var name_label = $Panel/MarginContainer/HBoxContainer/VBoxContainer/Name
@onready var text_label = $Panel/MarginContainer/HBoxContainer/VBoxContainer/Text

signal dialog_action(action_name)
signal dialog_finished

var lines: Array = []
var idx: int = 0
var just_shown: bool = false
var current_portrait: Texture2D = null
var current_name: String = ""

func _ready():
	panel.visible = false
	

func show_dialogue(p_lines: Array, default_portrait: Texture2D = null, default_name: String = "") -> void:
	lines = p_lines.duplicate()
	idx = 0
	just_shown = true
	current_portrait = default_portrait
	current_name = default_name
	
	panel.visible = true
	_show_current()

func _show_current() -> void:
	if idx >= 0 and idx < lines.size():
		var line_data = lines[idx]
		var text_to_show = ""
		
		if typeof(line_data) == TYPE_DICTIONARY:
			text_to_show = line_data.get("text", "")
			if line_data.has("speaker"):
				current_name = line_data["speaker"]
			if line_data.has("portrait"):
				var tex = line_data["portrait"]
				if typeof(tex) == TYPE_STRING:
					current_portrait = load(tex)
				else:
					current_portrait = tex
			if line_data.has("action"):
				emit_signal("dialog_action", line_data["action"])
		else:
			text_to_show = str(line_data)
			
		if current_portrait != null:
			portrait.texture = current_portrait
			portrait.visible = true
		else:
			portrait.visible = false
			
		if current_name == "":
			name_label.visible = false
		else:
			name_label.text = current_name
			name_label.visible = true
			
		text_label.text = text_to_show
	else:
		_close()

func _close() -> void:
	panel.visible = false
	lines.clear()
	idx = 0
	emit_signal("dialog_finished")

func is_dialog_active() -> bool:
	return panel.visible

func hide_dialogue() -> void:
	_close()

func _unhandled_input(event: InputEvent) -> void:
	if is_dialog_active() and event.is_action_pressed("interact"):
		if just_shown:
			just_shown = false
			return
		get_viewport().set_input_as_handled()
		idx += 1
		if idx < lines.size():
			_show_current()
		else:
			_close()

func next() -> void:
	# 外部调用的翻页/关闭方法，等同于按下交互键的效果
	if just_shown:
		just_shown = false
		return
	idx += 1
	if idx < lines.size():
		_show_current()
	else:
		_close()
