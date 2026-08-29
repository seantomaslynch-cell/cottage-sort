extends Node
class_name GameAudio
## Sound + haptics. Preloads the placeholder WAVs and plays them by name; runs a
## looping ambient music bed; buzzes the device on key events. Missing streams
## and non-mobile platforms are handled silently.

var sfx_on := true
var music_on := true
var haptics_on := true

# legacy alias used by the quick M-key mute path
var muted: bool:
	get: return not sfx_on
	set(v): sfx_on = not v

const SOUNDS := {
	"tap": "res://game/audio/tap.wav",
	"place": "res://game/audio/place.wav",
	"pour": "res://game/audio/pour.wav",
	"buzz": "res://game/audio/buzz.wav",
	"win": "res://game/audio/win.wav",
}
const MUSIC := "res://game/audio/music.wav"

# device buzz length (ms) per event
const HAPTIC := {
	"tap": 8, "pour": 14, "place": 10, "buzz": 26, "win": 40,
}

var _players: Dictionary = {}
var _music: AudioStreamPlayer

func _ready() -> void:
	for key in SOUNDS:
		var p := AudioStreamPlayer.new()
		p.stream = load(SOUNDS[key]) as AudioStream
		add_child(p)
		_players[key] = p

	_music = AudioStreamPlayer.new()
	_music.stream = load(MUSIC) as AudioStream
	_music.volume_db = -6.0
	_music.finished.connect(func() -> void:
		if music_on and _music.stream != null:
			_music.play())
	add_child(_music)

func play(sound: String, pitch := 1.0) -> void:
	if not sfx_on:
		return
	var p: AudioStreamPlayer = _players.get(sound)
	if p == null or p.stream == null:
		return
	p.pitch_scale = pitch
	p.play()

func haptic_for(sound: String) -> void:
	if not haptics_on:
		return
	var ms: int = HAPTIC.get(sound, 0)
	if ms > 0:
		Input.vibrate_handheld(ms)

func apply_music() -> void:
	if _music.stream == null:
		return
	if music_on and not _music.playing:
		_music.play()
	elif not music_on and _music.playing:
		_music.stop()

func _exit_tree() -> void:
	if _music != null:
		_music.stop()
