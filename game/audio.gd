extends Node
class_name GameAudio
## Tiny sound manager. Preloads the placeholder WAVs and plays them by name.
## Missing streams are ignored so the game still runs without audio imported.

var muted := false

const SOUNDS := {
	"tap": "res://game/audio/tap.wav",
	"place": "res://game/audio/place.wav",
	"pour": "res://game/audio/pour.wav",
	"buzz": "res://game/audio/buzz.wav",
	"win": "res://game/audio/win.wav",
}

var _players: Dictionary = {}

func _ready() -> void:
	for key in SOUNDS:
		var stream := load(SOUNDS[key]) as AudioStream
		var p := AudioStreamPlayer.new()
		p.stream = stream
		add_child(p)
		_players[key] = p

func play(sound: String, pitch := 1.0) -> void:
	if muted:
		return
	var p: AudioStreamPlayer = _players.get(sound)
	if p == null or p.stream == null:
		return
	p.pitch_scale = pitch
	p.play()
