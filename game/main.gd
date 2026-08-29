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
const CoachScene := preload("res://game/coach.gd")
const SettingsPanelScene := preload("res://game/settings_panel.gd")
const AnalyticsScene := preload("res://game/analytics.gd")
const PlatformScene := preload("res://game/platform.gd")
const BoosterPanelScene := preload("res://game/booster_panel.gd")

const FREE_EXTRA_JARS := 1
const FREE_HINTS := 2
const FREE_UNDOS := 3
const COIN_BASE := 20
const COIN_FIRST_CLEAR := 30
const MOVES_PER_REFILL := 5
const MOVES_COIN_COST := 100

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
var _coach: Coach
var _settings: SettingsPanel
var _analytics: Analytics
var _platform: Platform
var _booster: BoosterPanel
var _new_player := false
var _stage := 0
var _last_earned := 0
var _hints_used := 0
var _undos_used := 0
var _stage_fails := 0

var _theme: Theme

func _ready() -> void:
	RenderingServer.set_default_clear_color(Palette.BG)
	_theme = UiTheme.build()
	get_window().theme = _theme
	SaveData.load_now()
	_new_player = not bool(SaveData.data.get("intro_seen", false))
	if int(SaveData.data.get("starter_seen_at", 0)) == 0:
		SaveData.data["starter_seen_at"] = int(Time.get_unix_time_from_system())
		SaveData.save_now()

	SaveData.migrate_audio_flags()
	_audio = AudioScene.new()
	add_child(_audio)
	_audio.sfx_on = bool(SaveData.data.get("sfx_on", true))
	_audio.music_on = bool(SaveData.data.get("music_on", true))
	_audio.haptics_on = bool(SaveData.data.get("haptics_on", true))
	_audio.apply_music()

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
	_hud.set_gems(_economy.gems())

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

	_coach = CoachScene.new()
	add_child(_coach)

	_settings = SettingsPanelScene.new()
	add_child(_settings)
	_settings.set_flags(_audio.sfx_on, _audio.music_on, _audio.haptics_on)

	_analytics = AnalyticsScene.new()
	add_child(_analytics)
	_platform = PlatformScene.new()
	add_child(_platform)

	_booster = BoosterPanelScene.new()
	add_child(_booster)
	_booster.set_economy(_economy)

	_board.moved.connect(func(n: int) -> void:
		_hud.set_moves(n)
		if n >= 2:
			_coach.clear())
	_board.solved.connect(_on_solved)
	_board.failed.connect(_on_failed)
	_board.changed.connect(_refresh_buttons)

	_hud.restart_pressed.connect(_load_current)
	_hud.next_pressed.connect(_next)
	_hud.undo_pressed.connect(_on_undo)
	_hud.add_moves_pressed.connect(_on_add_moves)
	_hud.buy_moves_pressed.connect(_on_buy_moves)
	_hud.skip_pressed.connect(func() -> void: _ads.watch_rewarded(_next))
	_hud.add_jar_pressed.connect(_on_add_jar)
	_hud.levels_pressed.connect(func() -> void: _select.open(Levels.count()))
	_hud.cottage_pressed.connect(_show_cottage)
	_hud.hint_pressed.connect(_on_hint)
	_hud.double_pressed.connect(_on_double)
	_hud.mute_toggled.connect(_on_mute_toggled)

	_ads.rewarded_started.connect(func() -> void: _hud.flash("Playing ad..."))

	_select.picked.connect(_on_stage_picked)

	_economy.coins_changed.connect(func(total: int) -> void: _hud.set_coins(total))
	_economy.gems_changed.connect(func(total: int) -> void:
		_hud.set_gems(total)
		_booster.refresh())

	_cottage.closed.connect(_show_puzzle)
	_cottage.buy_pressed.connect(func(id: String) -> void:
		_economy.buy(id)
		_cottage.refresh())
	_cottage.decor_buy_pressed.connect(func(id: String) -> void:
		if _economy.buy_decor(id):
			_analytics.log_event("decor_buy", {"id": id})
		_cottage.refresh())
	_economy.set_completed.connect(func(set_name: String, bonus: int) -> void:
		_economy.add_coins(bonus)
		_cottage.flash("%s set complete!   +%d" % [set_name, bonus])
		_cottage.refresh()
		_analytics.log_event("decor_set", {"set": set_name, "bonus": bonus}))
	_cottage.mystery_pressed.connect(_on_mystery)

	_hud.daily_pressed.connect(_open_daily)
	_hud.shop_pressed.connect(_open_shop)
	_hud.settings_pressed.connect(func() -> void: _settings.open())
	_hud.boost_pressed.connect(func() -> void:
		if _board.visible and not _hud.fail_open():
			_booster.open())

	_booster.closed.connect(func() -> void: _booster.visible = false)
	_booster.use_pressed.connect(_on_use_booster)

	_settings.closed.connect(func() -> void: _settings.visible = false)
	_settings.restore_pressed.connect(func() -> void:
		_iap.restore()
		_ads.remove_ads = _iap.has_remove_ads()
		_settings.note("Restore complete"))
	_settings.flag_toggled.connect(_on_setting_toggled)
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
	_daily_panel.week_claim_pressed.connect(_on_claim_week)
	_daily_panel.debug_day_pressed.connect(func() -> void:
		_daily.advance_debug_day()
		_daily_panel.refresh())
	_daily.chest_awarded.connect(func(amount: int) -> void:
		_economy.add_coins(amount)
		_economy.add_gems(1)
		_economy.piggy_add(3)
		_daily_panel.flash("Ad-streak chest!  +%d  +1 gem" % amount)
		_hud.flash("Ad-streak chest!  +%d coins, +1 gem" % amount))
	_ads.rewarded_finished.connect(func(granted: bool) -> void:
		if granted:
			_daily.note_ad_watched()
			_analytics.log_event("ad_reward"))

	# Window.theme doesn't reach Controls under a CanvasLayer, so push it onto
	# the top Control of every screen explicitly.
	for scr in [_hud, _cottage, _daily_panel, _shop, _select, _settings, _booster]:
		_apply_theme(scr)

	_load_current()

	_analytics.log_event("session_start", {"new_player": _new_player})
	_platform.schedule_daily_reminder(24)
	_platform.schedule_streak_warning(20)

	# A brand-new player gets a clean first session: no daily pop-up over an
	# unexplained board. It opens from the next launch on.
	if _daily.login_pending() and not _new_player:
		_open_daily()
	if _new_player:
		SaveData.data["intro_seen"] = true
		SaveData.save_now()
	elif _starter_secs_left() > 0 and not bool(SaveData.data.get("starter_shown_once", false)):
		SaveData.data["starter_shown_once"] = true
		SaveData.save_now()
		_hud.flash("Starter pack in the Shop — %dh left" % int(ceil(_starter_secs_left() / 3600.0)))

func _apply_theme(n: Node) -> void:
	if n is Control:
		n.theme = _theme
		return
	for c in n.get_children():
		_apply_theme(c)

func _load_current() -> void:
	_board.load_level(Levels.build(_stage))
	_board.move_budget = Levels.move_budget(_stage)
	_hud.set_level(_stage + 1)
	_hud.set_budget(_board.move_budget)
	_hud.set_moves(0)
	_hud.hide_win()
	_hud.hide_fail()
	_hints_used = 0
	_undos_used = 0
	_stage_fails = 0
	_coach_for_stage()
	_analytics.log_event("level_start", {"stage": _stage, "budget": _board.move_budget})
	_refresh_buttons()

func _coach_for_stage() -> void:
	if _stage > 3 or SaveData.is_complete(_stage):
		_coach.clear()
		return
	match _stage:
		0: _coach.show_tip("Tap a jar to pick it up, then tap another to pour matching colours on top.")
		1: _coach.show_tip("Some jars are mixed. Look for a pour that frees a whole colour.")
		2: _coach.show_tip("Wrong move? Tap Undo below to take it back.")
		3: _coach.show_tip("Out of room? The Jar button gives you a spare to work with.")

func _on_undo() -> void:
	if not _board.can_undo():
		return
	if _undos_used < FREE_UNDOS:
		_undos_used += 1
		_board.undo()
	else:
		_ads.watch_rewarded(func() -> void: _board.undo())

func _on_failed() -> void:
	_coach.clear()
	_stage_fails += 1
	_analytics.log_event("level_fail", {"stage": _stage, "moves": _board.moves, "n": _stage_fails})
	_hud.show_fail(MOVES_COIN_COST, _economy.coins(), _stage_fails >= 2)

func _on_use_booster(id: String) -> void:
	var cost: int = Boosters.COST.get(id, 0)
	if not _economy.spend_gems(cost):
		_booster.note("Not enough gems")
		return
	match id:
		"moves8":
			_board.add_moves(8)
			_hud.set_budget(_board.move_budget)
		"undos3":
			_undos_used = maxi(0, _undos_used - 3)
		"jar1":
			_board.force_add_jar()
		"hints3":
			_hints_used = maxi(0, _hints_used - 3)
		"magnet":
			_board.magnet()
		"headstart":
			_board.autoplay(3)
	_economy.piggy_add(1 + cost / 2)   # using boosters feeds the piggy bank
	_analytics.log_event("booster", {"id": id, "cost": cost})
	_booster.visible = false
	_hud.flash("%s" % Boosters.NAME.get(id, id))
	_refresh_buttons()

func _on_claim_week() -> void:
	var amt := _daily.claim_week()
	if amt > 0:
		_economy.add_coins(amt)
		_daily_panel.flash("Weekly chest!  +%d" % amt)
		_daily_panel.refresh()
		_analytics.log_event("week_chest", {"amount": amt})

func _on_add_moves() -> void:
	_ads.watch_rewarded(func() -> void:
		_board.add_moves(MOVES_PER_REFILL)
		_hud.set_budget(_board.move_budget)
		_hud.hide_fail())

func _on_buy_moves() -> void:
	if _economy.coins() < MOVES_COIN_COST:
		return
	_economy.add_coins(-MOVES_COIN_COST)
	_board.add_moves(MOVES_PER_REFILL)
	_hud.set_budget(_board.move_budget)
	_hud.hide_fail()

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
	_audio.sfx_on = not muted
	SaveData.set_muted(muted)
	_settings.set_flags(_audio.sfx_on, _audio.music_on, _audio.haptics_on)

func _on_setting_toggled(key: String, value: bool) -> void:
	match key:
		"sfx_on": _audio.sfx_on = value
		"music_on":
			_audio.music_on = value
			_audio.apply_music()
		"haptics_on":
			_audio.haptics_on = value
			if value:
				_audio.haptic_for("place")
	SaveData.set_flag(key, value)

func _on_solved() -> void:
	_coach.clear()
	var first := not SaveData.is_complete(_stage)
	var stars := Levels.stars_for(_stage, _board.moves)
	var earned := COIN_BASE + (COIN_FIRST_CLEAR if first else 0) + stars * 5
	_last_earned = earned
	_economy.add_coins(earned)
	var prev_best := SaveData.best_moves(_stage)
	SaveData.mark_complete(_stage, _board.moves)
	SaveData.set_stars(_stage, stars)
	_daily.note_level_cleared()
	_economy.piggy_add(2)
	if first and stars == 3:
		_economy.add_gems(1)   # a taste of the premium currency for skilful play
	_analytics.log_event("level_complete",
		{"stage": _stage, "moves": _board.moves, "stars": stars, "first": first})

	var left := Daily.WEEK_GOAL - _daily.week_progress()
	if left > 0 and left <= 5 and not _daily.week_claimed():
		_hud.set_next_hint("%d more this week for a %d-coin chest" % [left, Daily.WEEK_CHEST])
	else:
		_hud.set_next_hint("Next: Level %d" % (_stage + 2))

	_hud.show_win("Cottage corner tidied!", prev_best, _board.moves, earned, stars)

	if SaveData.data["completed"].size() >= 5:
		_platform.request_review()

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

const STARTER_WINDOW_SEC := 48 * 3600

func _open_shop() -> void:
	_shop.set_starter_secs(_starter_secs_left())
	_shop.open()

func _starter_secs_left() -> int:
	if bool(SaveData.data.get("starter_bought", false)):
		return -1
	var seen := int(SaveData.data.get("starter_seen_at", 0))
	var left := STARTER_WINDOW_SEC - (int(Time.get_unix_time_from_system()) - seen)
	return left if left > 0 else -1

func _on_purchased(id: String) -> void:
	var p := _iap.product(id)
	_analytics.log_event("iap", {"id": id})
	var msg := "Purchased: %s" % p.get("name", id)
	match str(p.get("kind")):
		"coins":
			_economy.add_coins(int(p["amount"]))
		"gems":
			_economy.add_gems(int(p["amount"]))
		"piggy":
			var amt := _economy.piggy_crack()
			_economy.add_gems(amt)
			msg = "Piggy bank cracked!  +%d gems" % amt
		"bundle":
			_economy.add_gems(int(p.get("gems", 0)))
			_economy.add_coins(int(p.get("coins", 0)))
			msg = "Starter pack unlocked!"
	_ads.remove_ads = _iap.has_remove_ads()
	_shop.refresh()
	_shop.flash(msg)

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
	_stage += 1   # unbounded — past the authored list, build() runs endless mode
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
	if _hud.fail_open() or _hud.nav_open() or _booster.visible:
		return
	var overlay := _cottage.visible or _daily_panel.visible or _shop.visible or _settings.visible
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
			_on_undo()
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
