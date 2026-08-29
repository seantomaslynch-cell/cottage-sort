extends Node2D
## Entry point. Owns the stage index, the two screens (puzzle / cottage), and
## wires board <-> HUD <-> level select <-> cottage, plus audio, ads, economy, save.
##
## Keys: R restart, N next, U undo, L levels, C cottage, M mute.

const Levels := preload("res://game/levels.gd")
const BoardScene := preload("res://game/board.gd")
const HudScene := preload("res://game/hud.gd")
const AudioScene := preload("res://game/audio.gd")
const AdsScene := preload("res://game/ads.gd")
const LevelSelectScene := preload("res://game/level_select.gd")
const EconomyScene := preload("res://game/economy.gd")
const CottageScreenScene := preload("res://game/cottage_screen.gd")

const FREE_EXTRA_JARS := 1
const COIN_BASE := 20
const COIN_FIRST_CLEAR := 30

var _board: SortBoard
var _hud: GameHUD
var _audio: GameAudio
var _ads: GameAds
var _select: LevelSelect
var _economy: Economy
var _cottage: CottageScreen
var _stage := 0
var _last_earned := 0

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("f3e9d8"))
	SaveData.load_now()

	_audio = AudioScene.new()
	add_child(_audio)
	_audio.muted = bool(SaveData.data.get("muted", false))

	_ads = AdsScene.new()
	add_child(_ads)

	_economy = EconomyScene.new()
	add_child(_economy)

	_board = BoardScene.new()
	_board.audio = _audio
	add_child(_board)

	_hud = HudScene.new()
	add_child(_hud)
	_hud.set_muted(_audio.muted)
	_hud.set_coins(_economy.coins())

	_select = LevelSelectScene.new()
	add_child(_select)

	_cottage = CottageScreenScene.new()
	add_child(_cottage)
	_cottage.set_economy(_economy)

	_board.moved.connect(func(n: int) -> void: _hud.set_moves(n))
	_board.solved.connect(_on_solved)
	_board.changed.connect(_refresh_buttons)

	_hud.restart_pressed.connect(_load_current)
	_hud.next_pressed.connect(_next)
	_hud.undo_pressed.connect(func() -> void: _board.undo())
	_hud.add_jar_pressed.connect(_on_add_jar)
	_hud.levels_pressed.connect(func() -> void: _select.open(Levels.count()))
	_hud.cottage_pressed.connect(_show_cottage)
	_hud.double_pressed.connect(_on_double)
	_hud.mute_toggled.connect(_on_mute_toggled)

	_ads.rewarded_started.connect(func() -> void: _hud.flash("Playing ad..."))

	_select.picked.connect(_on_stage_picked)

	_economy.coins_changed.connect(func(total: int) -> void: _hud.set_coins(total))

	_cottage.closed.connect(_show_puzzle)
	_cottage.buy_pressed.connect(func(id: String) -> void:
		_economy.buy(id)
		_cottage.refresh())
	_cottage.mystery_pressed.connect(_on_mystery)

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
	var first := not SaveData.is_complete(_stage)
	var earned := COIN_BASE + (COIN_FIRST_CLEAR if first else 0)
	_last_earned = earned
	_economy.add_coins(earned)
	var prev_best := SaveData.best_moves(_stage)
	SaveData.mark_complete(_stage, _board.moves)
	_hud.show_win("Cottage corner tidied!", prev_best, _board.moves, earned)

func _on_double() -> void:
	_ads.watch_rewarded(func() -> void:
		_economy.add_coins(_last_earned)
		_hud.mark_doubled())

func _on_mystery() -> void:
	_ads.watch_rewarded(func() -> void:
		var reward := randi_range(15, 55)
		_economy.add_coins(reward)
		_cottage.refresh()
		_cottage.flash("+%d coins" % reward))

func _on_stage_picked(idx: int) -> void:
	_stage = idx
	_show_puzzle()
	_load_current()

func _next() -> void:
	_stage = (_stage + 1) % Levels.count()
	_load_current()

func _show_cottage() -> void:
	_board.visible = false
	_hud.visible = false
	_cottage.open()

func _show_puzzle() -> void:
	_cottage.visible = false
	_board.visible = true
	_hud.visible = true

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if _cottage.visible and event.keycode != KEY_C and event.keycode != KEY_M:
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
		KEY_C:
			if _cottage.visible:
				_show_puzzle()
			else:
				_show_cottage()
		KEY_M:
			_on_mute_toggled(not _audio.muted)
			_hud.set_muted(_audio.muted)
