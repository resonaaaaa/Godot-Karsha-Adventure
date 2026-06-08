extends Node

var _cache := {}

func _get_stream(path: String) -> AudioStream:
	if not _cache.has(path):
		_cache[path] = load(path)
	return _cache[path]

@onready var bgm_player: AudioStreamPlayer = $BGMPlayer
@onready var se_player: AudioStreamPlayer = $SEPlayer
@onready var ui_player: AudioStreamPlayer = $UIPlayer

func play_bgm(path: String) -> void:
	var s = _get_stream(path)
	if s:
		if bgm_player.playing:
			if bgm_player.stream == s:
				return
			var tween = get_tree().create_tween()
			tween.tween_property(bgm_player, "volume_db", -80.0, 1.0)
			tween.tween_callback(func():
				bgm_player.stream = s
				bgm_player.play()
				var tween2 = get_tree().create_tween()
				tween2.tween_property(bgm_player, "volume_db", 0.0, 1.0)
			)
		else:
			bgm_player.stream = s
			bgm_player.volume_db = -80.0
			bgm_player.play()
			var tween = get_tree().create_tween()
			tween.tween_property(bgm_player, "volume_db", 0.0, 1.0)


func play_se(path: String) -> void:
	var s = _get_stream(path)
	if s:
		se_player.stream = s
		se_player.play()

func play_ui(path: String) -> void:
	var s = _get_stream(path)
	if s:
		ui_player.stream = s
		ui_player.play()
		


	
