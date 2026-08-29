extends Node2D
## Entry point. Owns the stage index and wires board <-> HUD <-> level select,
## plus the audio, ads stub, and save.
##
## Keys: R restart, N next, U undo, L levels, M mute.

const Levels := preload("res://game/levels.gd")
const BoardScene := preload("res://game/board.gd")
const HudScene := preload("res://game/hud.gd")
const AudioScene := preload("res://game/audio.gd")
const AdsScene := preload("res://game/ads.gd")
const LevelSelectScene := preload("res://game/level_select.gd")

const FREE_EXTRA_JARS := 1

var _board: SortBoard
var _hud: GameHUD
var _audio: GameAudio
var _ads: GameAds
var _select: LevelSelect
var _stage := 0

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("f3e9d8"))
	SaveData.load_now()

	_audio = AudioScene.new()
	add_child(_audio)
	_audio.muted = bool(SaveData.data.get("muted", false))

	_ads = AdsScene.new()
	add_child(_ads)

	_board = BoardScene.new()
	_board.audio = _audio
	add_child(_board)

	_hud = HudScene.new()
	add_child(_hud)
	_hud.set_muted(_audio.muted)

	_select = LevelSelectScene.new()
	add_child(_select)

	_board.moved.connect(func(n: int) -> void: _hud.set_moves(n))
	_board.solved.connect(_on_solved)
	_board.changed.connect(_refresh_buttons)

	_hud.restart_pressed.connect(_load_current)
	_hud.next_pressed.connect(_next)
	_hud.undo_pressed.connect(func() -> void: _board.undo())
	_hud.add_jar_pressed.connect(_on_add_jar)
	_hud.levels_pressed.connect(func() -> void: _select.open(Levels.count()))
	_hud.mute_toggled.connect(_on_mute_toggled)

	_ads.rewarded_started.connect(func() -> void: _hud.flash("Playing ad..."))

	_select.picked.connect(_on_stage_picked)

	_load_current()

func _load_current() -> void:
	_board.load_level(Levels.build(_stage))
	_hud.set_level(_stage + 1)
	_hud.set_moves(0)
	_hud.hide_win()
	_refresh_buttons()

func _refresh_buttons() -> void:
	_hud.set_undo_enabled(_board.can_undo())
	_hud.set_addjar_enabled(_board.can_add_jar())

func _on_add_jar() -> void:
	if not _board.can_add_jar():
		return
	if _board.extra_jar_count() < FREE_EXTRA_JARS:
		_board.add_jar()
	else:
		_ads.watch_rewarded(func() -> void:
			_board.add_jar()
			_hud.flash("Extra jar added"))

func _on_mute_toggled(muted: bool) -> void:
	_audio.muted = muted
	SaveData.set_muted(muted)

func _on_solved() -> void:
	var prev_best := SaveData.best_moves(_stage)
	SaveData.mark_complete(_stage, _board.moves)
	_hud.show_win("Cottage corner tidied!", prev_best, _board.moves)

func _on_stage_picked(idx: int) -> void:
	_stage = idx
	_load_current()

func _next() -> void:
	_stage = (_stage + 1) % Levels.count()
	_load_current()

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_R:
			_load_current()
		KEY_N:
			_next()
		KEY_U:
			_board.undo()
		KEY_L:
			_select.open(Levels.count())
		KEY_M:
			_on_mute_toggled(not _audio.muted)
			_hud.set_muted(_audio.muted)
