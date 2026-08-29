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
const DailyScene := preload("res://game/daily.gd")
const DailyPanelScene := preload("res://game/daily_panel.gd")
const Solver := preload("res://game/solver.gd")
const IapScene := preload("res://game/iap.gd")
const ShopPanelScene := preload("res://game/shop_panel.gd")

const FREE_EXTRA_JARS := 1
const FREE_HINTS := 2
const COIN_BASE := 20
const COIN_FIRST_CLEAR := 30

var _board: SortBoard
var _hud: GameHUD
var _audio: GameAudio
var _ads: GameAds
var _select: LevelSelect
var _economy: Economy
var _cottage: CottageScreen
var _daily: Daily
var _daily_panel: DailyPanel
var _iap: GameIap
var _shop: ShopPanel
var _stage := 0
var _last_earned := 0
var _hints_used := 0

func _ready() -> void:
	RenderingServer.set_default_clear_color(Palette.BG)
	get_window().theme = UiTheme.build()
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

	_daily = DailyScene.new()
	add_child(_daily)

	_daily_panel = DailyPanelScene.new()
	add_child(_daily_panel)
	_daily_panel.set_daily(_daily)

	_iap = IapScene.new()
	add_child(_iap)
	_ads.remove_ads = _iap.has_remove_ads()

	_shop = ShopPanelScene.new()
	add_child(_shop)
	_shop.set_refs(_iap, _economy)

	_board.moved.connect(func(n: int) -> void: _hud.set_moves(n))
	_board.solved.connect(_on_solved)
	_board.changed.connect(_refresh_buttons)

	_hud.restart_pressed.connect(_load_current)
	_hud.next_pressed.connect(_next)
	_hud.undo_pressed.connect(func() -> void: _board.undo())
	_hud.add_jar_pressed.connect(_on_add_jar)
	_hud.levels_pressed.connect(func() -> void: _select.open(Levels.count()))
	_hud.cottage_pressed.connect(_show_cottage)
	_hud.hint_pressed.connect(_on_hint)
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

	_hud.daily_pressed.connect(_open_daily)
	_hud.shop_pressed.connect(func() -> void: _shop.open())
	_daily_panel.closed.connect(func() -> void: _daily_panel.visible = false)

	_shop.closed.connect(func() -> void: _shop.visible = false)
	_shop.buy_pressed.connect(func(id: String) -> void: _iap.purchase(id))
	_shop.restore_pressed.connect(func() -> void:
		_iap.restore()
		_ads.remove_ads = _iap.has_remove_ads()
		_shop.refresh()
		_shop.flash("Restore complete"))
	_iap.purchased.connect(_on_purchased)
	_ads.interstitial_shown.connect(func() -> void: _hud.flash("Ad"))
	_daily_panel.claim_login_pressed.connect(_on_claim_login)
	_daily_panel.spin_pressed.connect(_on_spin)
	_daily_panel.debug_day_pressed.connect(func() -> void:
		_daily.advance_debug_day()
		_daily_panel.refresh())
	_daily.chest_awarded.connect(func(amount: int) -> void:
		_economy.add_coins(amount)
		_daily_panel.flash("Ad-streak chest!  +%d" % amount)
		_hud.flash("Ad-streak chest!  +%d coins" % amount))
	_ads.rewarded_finished.connect(func(granted: bool) -> void:
		if granted:
			_daily.note_ad_watched())

	_load_current()

	if _daily.login_pending():
		_open_daily()

func _load_current() -> void:
	_board.load_level(Levels.build(_stage))
	_hud.set_level(_stage + 1)
	_hud.set_moves(0)
	_hud.hide_win()
	_hints_used = 0
	_refresh_buttons()

func _on_hint() -> void:
	if _board.visible == false or _daily_panel.visible or _cottage.visible:
		return
	if _hints_used < FREE_HINTS:
		_hints_used += 1
		_do_hint()
	else:
		_ads.watch_rewarded(_do_hint)

func _do_hint() -> void:
	var mv := Solver.hint(_board.jars)
	if mv.is_empty():
		_hud.flash("No hint right now")
	else:
		_board.show_hint(mv)

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
	var stars := Levels.stars_for(_stage, _board.moves)
	var earned := COIN_BASE + (COIN_FIRST_CLEAR if first else 0) + stars * 5
	_last_earned = earned
	_economy.add_coins(earned)
	var prev_best := SaveData.best_moves(_stage)
	SaveData.mark_complete(_stage, _board.moves)
	SaveData.set_stars(_stage, stars)
	_hud.show_win("Cottage corner tidied!", prev_best, _board.moves, earned, stars)

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

func _on_purchased(id: String) -> void:
	var p := _iap.product(id)
	if p.get("kind") == "coins":
		_economy.add_coins(int(p["amount"]))
	_ads.remove_ads = _iap.has_remove_ads()
	_shop.refresh()
	_shop.flash("Purchased: %s" % p.get("name", id))

func _open_daily() -> void:
	_daily_panel.open()

func _on_claim_login() -> void:
	var amt := _daily.claim_login()
	if amt > 0:
		_economy.add_coins(amt)
		_daily_panel.flash("+%d coins" % amt)
		_daily_panel.refresh()

func _on_spin() -> void:
	var idx := _daily.roll_spin()
	var grant := func() -> void:
		_daily_panel.play_spin(idx, func() -> void:
			var v := _daily.spin_value(idx)
			_economy.add_coins(v)
			_daily_panel.flash("+%d coins" % v))
	if _daily.free_spin_available():
		_daily.consume_free_spin()
		grant.call()
	else:
		_ads.watch_rewarded(grant)

func _on_stage_picked(idx: int) -> void:
	_stage = idx
	_show_puzzle()
	_load_current()

func _next() -> void:
	_ads.maybe_show_interstitial()
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
	var overlay := _cottage.visible or _daily_panel.visible or _shop.visible
	if overlay and event.keycode != KEY_M:
		# let the matching toggle key still close its own overlay
		if not (_shop.visible and event.keycode == KEY_S) \
				and not (_cottage.visible and event.keycode == KEY_C) \
				and not (_daily_panel.visible and event.keycode == KEY_D):
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
		KEY_H:
			_on_hint()
		KEY_C:
			if _daily_panel.visible or _shop.visible:
				return
			if _cottage.visible:
				_show_puzzle()
			else:
				_show_cottage()
		KEY_D:
			if _cottage.visible or _shop.visible:
				return
			if _daily_panel.visible:
				_daily_panel.visible = false
			else:
				_open_daily()
		KEY_S:
			if _cottage.visible or _daily_panel.visible:
				return
			if _shop.visible:
				_shop.visible = false
			else:
				_shop.open()
		KEY_M:
			_on_mute_toggled(not _audio.muted)
			_hud.set_muted(_audio.muted)
