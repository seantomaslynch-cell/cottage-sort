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
const BattlePassScene := preload("res://game/battle_pass.gd")
const BattlePassPanelScene := preload("res://game/battle_pass_panel.gd")
const LeaderboardPanelScene := preload("res://game/leaderboard_panel.gd")
const HomeScreenScene := preload("res://game/home_screen.gd")
const ChapterCardScene := preload("res://game/chapter_card.gd")
const AchievementsScene := preload("res://game/achievements.gd")
const ProgressPanelScene := preload("res://game/progress_panel.gd")
const IntroStoryScene := preload("res://game/intro_story.gd")
const CottageCatScene := preload("res://game/cottage_cat.gd")

const FREE_EXTRA_JARS := 1
const FREE_HINTS := 2
const FREE_UNDOS := 3
const COIN_BASE := 20
const COIN_FIRST_CLEAR := 30
const MOVES_PER_REFILL := 5
const MOVES_COIN_COST := 100
const PAR_BONUS := 30

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
var _bp: BattlePass
var _bp_panel: BattlePassPanel
var _lb_panel: LeaderboardPanel
var _home: HomeScreen
var _chapter_card: ChapterCard
var _ach: Achievements
var _progress: ProgressPanel
var _story: IntroStory
var _cat: CottageCat
var _session_popups_done := false
var _new_player := false
var _stage := 0
var _last_earned := 0
var _hints_used := 0
var _undos_used := 0
var _stage_fails := 0
var _jackpot_active := false
var _last_chapter := -1
var _ftue_active := false

var _theme: Theme

func _ready() -> void:
	RenderingServer.set_default_clear_color(Palette.BG)
	_theme = UiTheme.build()
	get_window().theme = _theme
	SaveData.load_now()
	_stage = maxi(0, int(SaveData.data.get("last_stage", 0)))
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
	# iOS: show the App Tracking Transparency prompt once, before any ad request.
	if OS.get_name() == "iOS":
		_ads.request_att()

	_economy = EconomyScene.new()
	add_child(_economy)

	_board = BoardScene.new()
	_board.audio = _audio
	add_child(_board)

	_cat = CottageCatScene.new()
	_cat.position = Vector2(158, 1060)
	_cat.scale = Vector2(1.2, 1.2)
	_cat._base_scale = 1.2
	_cat.visible = false
	add_child(_cat)

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

	_bp = BattlePassScene.new()
	add_child(_bp)
	_bp_panel = BattlePassPanelScene.new()
	add_child(_bp_panel)
	_bp_panel.set_pass(_bp)

	_lb_panel = LeaderboardPanelScene.new()
	add_child(_lb_panel)

	_chapter_card = ChapterCardScene.new()
	add_child(_chapter_card)

	_ach = AchievementsScene.new()
	add_child(_ach)
	_ach.set_refs(_economy, _daily, _bp)
	_ach.granted.connect(_on_achievement)
	_progress = ProgressPanelScene.new()
	add_child(_progress)
	_progress.set_refs(_economy, _daily, _bp, _ach)
	_progress.closed.connect(func() -> void: _progress.visible = false)
	_economy.changed.connect(func() -> void: _ach.scan())
	_daily.changed.connect(func() -> void: _ach.scan())
	_bp.changed.connect(func() -> void: _ach.scan())

	_story = IntroStoryScene.new()
	add_child(_story)
	_story.begun.connect(func() -> void: _enter_game())

	_home = HomeScreenScene.new()
	add_child(_home)
	_home.set_economy(_economy)
	_home.play_pressed.connect(func() -> void:
		if _new_player and not bool(SaveData.data.get("story_seen", false)):
			_home.close()
			_story.show_story()
		else:
			_enter_game())
	_home.cottage_pressed.connect(func() -> void: _enter_game(_show_cottage))
	_home.daily_pressed.connect(func() -> void: _enter_game(_open_daily))
	_home.shop_pressed.connect(func() -> void: _enter_game(_open_shop))
	_home.season_pressed.connect(func() -> void: _enter_game(func() -> void: _bp_panel.open()))
	_home.settings_pressed.connect(func() -> void: _enter_game(func() -> void: _settings.open()))

	_board.moved.connect(func(n: int) -> void:
		_hud.set_moves(n)
		if _ftue_active:
			_on_ftue_moved(n)
		elif n >= 2:
			_coach.clear())
	_board.solved.connect(_on_solved)
	_board.failed.connect(_on_failed)
	_board.combo.connect(_on_combo)
	_board.changed.connect(_refresh_buttons)

	_hud.restart_pressed.connect(_load_current)
	_hud.next_pressed.connect(_next)
	_hud.undo_pressed.connect(_on_undo)
	_hud.add_moves_pressed.connect(_on_add_moves)
	_hud.buy_moves_pressed.connect(_on_buy_moves)
	_hud.skip_pressed.connect(func() -> void: _ads.watch_rewarded(_next))
	_hud.struggle_pressed.connect(func() -> void: _iap.purchase("struggle_pack"))
	_hud.add_jar_pressed.connect(_on_add_jar)
	_hud.levels_pressed.connect(func() -> void: _select.open(Levels.count()))
	_hud.cottage_pressed.connect(_show_cottage)
	_hud.hint_pressed.connect(_on_hint)
	_hud.double_pressed.connect(_on_double)
	_hud.combo_double_pressed.connect(_on_combo_double)
	_hud.mute_toggled.connect(_on_mute_toggled)

	_ads.rewarded_started.connect(func() -> void: _hud.flash("Playing ad..."))

	_select.picked.connect(_on_stage_picked)

	_economy.coins_changed.connect(func(total: int) -> void: _hud.set_coins(total))
	_economy.gems_changed.connect(func(total: int) -> void:
		_hud.set_gems(total)
		_booster.refresh())

	_cottage.closed.connect(_show_puzzle)
	_cottage.buy_pressed.connect(func(id: String) -> void:
		if _economy.buy(id):
			_first_time_flourish()
		_cottage.refresh())
	_cottage.decor_buy_pressed.connect(func(id: String) -> void:
		if _economy.buy_decor(id):
			_analytics.log_event("decor_buy", {"id": id})
			if not bool(SaveData.data.get("ft_decor", false)):
				SaveData.data["ft_decor"] = true
				SaveData.save_now()
				_cottage.flash("Your first touch of home  ♥")
		_cottage.refresh())
	_economy.set_completed.connect(func(set_name: String, bonus: int) -> void:
		_economy.add_coins(bonus)
		_cottage.flash("%s set complete!   +%d" % [set_name, bonus])
		_cottage.refresh()
		_analytics.log_event("decor_set", {"set": set_name, "bonus": bonus}))
	_cottage.mystery_pressed.connect(_on_mystery)

	_hud.daily_pressed.connect(_open_daily)
	_hud.season_pressed.connect(func() -> void: _bp_panel.open())
	_hud.shop_pressed.connect(_open_shop)
	_hud.home_pressed.connect(_show_home)
	_hud.progress_pressed.connect(func() -> void: _progress.open("badges"))

	_bp_panel.closed.connect(func() -> void: _bp_panel.visible = false)
	_bp_panel.unlock_pressed.connect(func() -> void: _iap.purchase("battle_pass"))
	_bp_panel.claim_free_pressed.connect(func() -> void: _grant_bp(_bp.claim_free()))
	_bp_panel.claim_premium_pressed.connect(func() -> void: _grant_bp(_bp.claim_premium()))
	_bp_panel.skip_pressed.connect(_on_bp_skip)
	_bp.changed.connect(func() -> void:
		if _bp_panel.visible:
			_bp_panel.refresh())
	_hud.settings_pressed.connect(func() -> void: _settings.open())
	_hud.boost_pressed.connect(func() -> void:
		if _board.visible and not _hud.fail_open():
			_booster.open())

	_booster.closed.connect(func() -> void: _booster.visible = false)
	_booster.use_pressed.connect(_on_use_booster)
	_booster.buy_pressed.connect(func(id: String) -> void:
		var cost: int = Boosters.COST.get(id, 0)
		if _economy.spend_gems(cost):
			_economy.add_booster(id, 1)
			_economy.piggy_add(1 + cost / 2)
			_booster.refresh()
		else:
			_booster.note("Not enough gems"))
	_booster.stock_pressed.connect(func() -> void:
		if _economy.spend_gems(Boosters.STOCK_ALL_COST):
			for bid in Boosters.LIST:
				_economy.add_booster(bid, 1)
			_economy.piggy_add(6)
			_booster.refresh()
		else:
			_booster.note("Not enough gems"))

	_settings.closed.connect(func() -> void: _settings.visible = false)
	_settings.restore_pressed.connect(func() -> void:
		_iap.restore()
		_ads.remove_ads = _iap.has_remove_ads()
		_settings.note("Restore complete"))
	_settings.flag_toggled.connect(_on_setting_toggled)
	_daily_panel.closed.connect(func() -> void: _daily_panel.visible = false)

	_shop.closed.connect(func() -> void: _shop.visible = false)
	_shop.buy_pressed.connect(func(id: String) -> void: _iap.purchase(id))
	_shop.season_bundle_pressed.connect(_on_season_bundle)
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
	_daily_panel.jackpot_pressed.connect(_start_jackpot)
	_daily_panel.ranks_pressed.connect(_open_ranks)
	_daily_panel.buy_freeze_pressed.connect(_on_buy_freeze)
	_daily.streak_frozen.connect(func(streak: int) -> void:
		_daily_panel.flash("Freeze used — your %d-day streak is safe" % streak)
		_hud.flash("Streak freeze used — your login streak held"))
	_lb_panel.closed.connect(func() -> void: _lb_panel.visible = false)
	_daily_panel.debug_day_pressed.connect(func() -> void:
		_daily.advance_debug_day()
		_bp.debug_day_offset = _daily.debug_day_offset   # keep the season clock in sync for QA
		_daily_panel.refresh())
	_daily.chest_awarded.connect(func(amount: int) -> void:
		_economy.add_coins(amount)
		_economy.add_gems(1)
		_economy.piggy_add(3)
		_economy.add_booster(Boosters.LIST[randi() % Boosters.LIST.size()], 1)
		_daily_panel.flash("Ad-streak chest!  +%d  +1 gem  +1 booster" % amount)
		_hud.flash("Ad-streak chest!  +%d coins, +1 gem, +1 booster" % amount))
	_ads.rewarded_finished.connect(func(granted: bool) -> void:
		if granted:
			_daily.note_ad_watched()
			_analytics.log_event("ad_reward"))

	# Window.theme doesn't reach Controls under a CanvasLayer, so push it onto
	# the top Control of every screen explicitly.
	for scr in [_hud, _cottage, _daily_panel, _shop, _select, _settings, _booster, _bp_panel, _lb_panel, _home, _chapter_card, _progress, _story]:
		_apply_theme(scr)

	_last_chapter = Realms.index_for(_stage)   # so the card only fires on a real change
	_load_current()

	_analytics.log_event("session_start", {"new_player": _new_player})
	_platform.schedule_daily_reminder(24)
	_platform.schedule_streak_warning(20)

	var day := _daily.today()
	if day != int(SaveData.data.get("stat_last_played_day", 0)):
		SaveData.data["stat_last_played_day"] = day
		SaveData.data["stat_days_played"] = int(SaveData.data.get("stat_days_played", 0)) + 1
		SaveData.save_now()
	# Remove-ads owners get a small daily gem stipend — makes the SKU feel
	# subscription-lite and lifts its conversion.
	const AD_FREE_STIPEND := 3
	if _iap.has_remove_ads() and day != int(SaveData.data.get("stipend_day", -1)):
		SaveData.data["stipend_day"] = day
		SaveData.save_now()
		_economy.add_gems(AD_FREE_STIPEND)
		_hud.flash("Ad-free bonus  —  +%d gems" % AD_FREE_STIPEND)
	_ach.scan()
	if _new_player:
		SaveData.data["intro_seen"] = true
		SaveData.save_now()

	# Boot into the Home screen; the board waits behind Play.
	_board.visible = false
	_hud.visible = false
	_show_home()

func _apply_theme(n: Node) -> void:
	if n is Control:
		n.theme = _theme
		return
	for c in n.get_children():
		_apply_theme(c)

func _load_current() -> void:
	_jackpot_active = false
	if int(SaveData.data.get("last_stage", 0)) != _stage:
		SaveData.data["last_stage"] = _stage
		SaveData.save_now()
	if _stage > int(SaveData.data.get("stat_deepest", 0)):
		SaveData.data["stat_deepest"] = _stage
		SaveData.save_now()
	if _ach != null:
		_ach.scan()
	var realm := Realms.for_stage(_stage)
	_board.realm = realm
	RenderingServer.set_default_clear_color(realm["bg_top"])
	_board.load_level(Levels.build(_stage))
	_board.move_budget = Levels.move_budget(_stage)
	_hud.set_chapter(realm["name"])
	_hud.set_level(_stage + 1)
	_hud.set_budget(_board.move_budget)
	_hud.set_moves(0)
	_hud.hide_win()
	_hud.hide_fail()
	_hud.hide_combo_offer()
	_hints_used = 0
	_undos_used = 0
	_stage_fails = 0
	_maybe_start_ftue()
	if not _ftue_active:
		_coach_for_stage()
	var ch := Realms.index_for(_stage)
	if _stage >= 4 and ch != _last_chapter and not _home.visible:
		_chapter_card.show_card(ch, realm)
	_last_chapter = ch
	# One-time heads-up the first time moves become limited.
	if not _ftue_active and _stage == Levels.FLOW_STAGES \
			and not bool(SaveData.data.get("ftue_budget_seen", false)):
		SaveData.data["ftue_budget_seen"] = true
		SaveData.save_now()
		_coach.show_tip("Moves are limited from here. Run low? Watch an ad, spend coins, or just restart — no lives, ever.")
	# One-time note the first time a level has a sealed keepsake jar.
	if not _ftue_active and Levels.has_lid(_stage) \
			and not bool(SaveData.data.get("lid_tip_seen", false)):
		SaveData.data["lid_tip_seen"] = true
		SaveData.save_now()
		_coach.show_tip("That jar has a lid. Tidy every other jar and it'll pop open on its own.")
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

# --- First-time user experience (M33) --------------------------------------
# Level 1 only, once ever: guide every pour with a pointer and a locked board,
# celebrate the first success, then explain what the coins are for.

func _maybe_start_ftue() -> void:
	_ftue_active = false
	_board.tutorial_lock = false
	_board.tutorial_move = []
	_coach.stop_pointing()
	if _stage != 0 or _jackpot_active:
		return
	if SaveData.is_complete(0) or bool(SaveData.data.get("ftue_done", false)):
		return
	_ftue_active = true
	_ftue_point_next()

func _ftue_point_next() -> void:
	if not _ftue_active:
		return
	var mv: Array = Solver.hint(_board.jars)
	if mv.size() != 2:
		_ftue_finish()
		return
	_board.tutorial_lock = true
	_board.tutorial_move = mv
	if _board.moves == 0:
		_coach.show_tip("Tap the jar the arrow points to, then the next one.")
	else:
		_coach.show_tip("Keep going — pour matching colours together.")
	_coach.point_at(_board.jar_center(int(mv[0])))

func _on_ftue_moved(n: int) -> void:
	_coach.stop_pointing()
	if n == 1:
		_hud.flash("Nice!")
		_audio.play("win", 1.4)
	if _board._is_solved():
		return   # _on_solved wraps up
	_ftue_point_next()

func _ftue_finish() -> void:
	_ftue_active = false
	_board.tutorial_lock = false
	_board.tutorial_move = []
	_coach.stop_pointing()
	if not bool(SaveData.data.get("ftue_done", false)):
		SaveData.data["ftue_done"] = true
		SaveData.save_now()

func _on_undo() -> void:
	if not _board.can_undo():
		return
	if _undos_used < FREE_UNDOS:
		_undos_used += 1
		_board.undo()
	else:
		_ads.watch_rewarded(func() -> void: _board.undo())

const COMBO_WORDS := ["", "", "Nice!", "Great!", "Superb!", "Unreal!"]

func _on_combo(n: int) -> void:
	if _jackpot_active:
		return
	if n > int(SaveData.data.get("stat_best_combo", 0)):
		SaveData.data["stat_best_combo"] = n
	var bonus := n * 5
	_economy.add_coins(bonus)   # -> economy.changed -> _ach.scan()
	var word: String = COMBO_WORDS[mini(n, COMBO_WORDS.size() - 1)]
	_hud.flash("%s  x%d combo   +%d" % [word, n, bonus])
	_analytics.log_event("combo", {"n": n, "stage": _stage})
	# A strong combo earns a transient rewarded offer to double just that bonus.
	if n >= 4:
		_hud.offer_combo_double(n, bonus)

func _on_achievement(id: String, aname: String, coins: int, gems: int) -> void:
	if coins > 0:
		_economy.add_coins(coins)
	if gems > 0:
		_economy.add_gems(gems)
	var reward := ("  +%dc" % coins) if coins > 0 else ""
	if gems > 0:
		reward += "  +%dg" % gems
	_hud.flash("Achievement — %s%s" % [aname, reward])
	_analytics.log_event("achievement", {"id": id})

func _on_failed() -> void:
	_coach.clear()
	_stage_fails += 1
	var struggle := _struggle_available()
	_analytics.log_event("level_fail",
		{"stage": _stage, "moves": _board.moves, "n": _stage_fails, "offer": struggle})
	_hud.show_fail(MOVES_COIN_COST, _economy.coins(), _stage_fails >= 2, struggle)

## The struggle pack: shown on the fail screen from the 2nd (through 4th) fail
## on a stage, at most once per day.
func _struggle_available() -> bool:
	if _stage_fails < 2 or _stage_fails > 4:
		return false
	return int(SaveData.data.get("struggle_bought_day", -1)) != _daily.today()

func _on_use_booster(id: String) -> void:
	if _economy.booster_count(id) <= 0:
		_booster.note("None left — buy one below")
		_booster.refresh()
		return
	var ok := _apply_booster(id)
	if not ok:
		_booster.note("Can't use that right now")
		return
	_economy.add_booster(id, -1)   # consume only on a real effect
	_analytics.log_event("booster_used", {"id": id})
	_booster.visible = false
	_hud.flash("%s" % Boosters.NAME.get(id, id))
	_refresh_buttons()

func _apply_booster(id: String) -> bool:
	match id:
		"moves8":
			_board.add_moves(8)
			_hud.set_budget(_board.move_budget)
			return true
		"undos3":
			_undos_used = maxi(0, _undos_used - 3)
			return true
		"jar1":
			return _board.force_add_jar()
		"hints3":
			_hints_used = maxi(0, _hints_used - 3)
			return true
		"magnet":
			return _board.magnet()
		"headstart":
			return _board.autoplay(3)
	return false

func _on_claim_week() -> void:
	var amt := _daily.claim_week()
	if amt > 0:
		SaveData.data["stat_week_chests"] = int(SaveData.data.get("stat_week_chests", 0)) + 1
		_economy.add_coins(amt)
		_economy.add_booster(Boosters.LIST[randi() % Boosters.LIST.size()], 1)
		_bp.add_xp(50)
		_daily_panel.flash("Weekly chest!  +%d coins  +1 booster" % amt)
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
	_hud.hide_combo_offer()
	if _jackpot_active:
		_finish_jackpot()
		return
	var was_ftue := _ftue_active
	_ftue_finish()
	_cat.celebrate()
	# The cat leaves a little gift on the first level cleared each day (not the
	# tutorial level, so it isn't the very first thing a new player sees).
	if not was_ftue and _daily.today() != int(SaveData.data.get("cat_gift_day", -1)):
		SaveData.data["cat_gift_day"] = _daily.today()
		var gift := randi_range(30, 55)
		_economy.add_coins(gift)
		_hud.flash("The cat left you something  —  +%d coins" % gift)
		_analytics.log_event("cat_gift", {"coins": gift})
	var first := not SaveData.is_complete(_stage)
	var stars := Levels.stars_for(_stage, _board.moves)
	var flawless := stars == 3 and _undos_used == 0 and _hints_used == 0
	if flawless:
		SaveData.data["stat_flawless"] = int(SaveData.data.get("stat_flawless", 0)) + 1
	# Beat par: a soft skill target under the stars, from L11 on.
	var par := Levels.par_for(_stage) if _stage >= Levels.FLOW_STAGES else 0
	var under_par := par > 0 and _board.moves <= par
	var earned := COIN_BASE + (COIN_FIRST_CLEAR if first else 0) + stars * 5 + (PAR_BONUS if under_par else 0)
	_last_earned = earned
	_economy.add_coins(earned)
	var prev_best := SaveData.best_moves(_stage)
	SaveData.mark_complete(_stage, _board.moves)
	SaveData.set_stars(_stage, stars)
	_daily.note_level_cleared(stars, under_par, _hints_used > 0)
	_economy.piggy_add(2)
	_bp.add_xp(10 + (stars - 1) * 5)
	if first and stars == 3:
		_economy.add_gems(1)   # a taste of the premium currency for skilful play
	_analytics.log_event("level_complete",
		{"stage": _stage, "moves": _board.moves, "stars": stars, "first": first})

	# Endless milestone chests: L50, L75, L100, then every 25 — once each.
	var lvl := _stage + 1
	if not was_ftue and lvl >= 50 and (lvl - 50) % 25 == 0 \
			and lvl > int(SaveData.data.get("endless_milestone", 0)):
		SaveData.data["endless_milestone"] = lvl
		var mi := (lvl - 50) / 25
		var mc := 300 + mi * 100
		var mg := 3 + mi
		_economy.add_coins(mc)
		_economy.add_gems(mg)
		_economy.add_booster(Boosters.LIST[randi() % Boosters.LIST.size()], 1)
		_cat.celebrate()
		_hud.flash("Level %d milestone!  +%d coins  +%d gems  +1 booster" % [lvl, mc, mg])
		_analytics.log_event("endless_milestone", {"level": lvl})

	var left := _daily.week_goal() - _daily.week_progress()
	var teach_stars := stars >= 2 and not bool(SaveData.data.get("ftue_stars_seen", false))
	if was_ftue:
		_hud.set_next_hint("Coins rebuild your cottage — try the Cottage button")
	elif teach_stars:
		SaveData.data["ftue_stars_seen"] = true
		SaveData.save_now()
		_hud.set_next_hint("Fewer moves earns more stars — and more coins.")
	elif left > 0 and left <= 5 and not _daily.week_claimed():
		_hud.set_next_hint("%d more this week for a %d-coin chest" % [left, Daily.WEEK_CHEST])
	else:
		var ni := Realms.index_for(_stage) + 1
		var togo := (int(Realms.CHAPTERS[ni]["from"]) - _stage - 1) if ni < Realms.CHAPTERS.size() else 0
		if togo > 0:
			_hud.set_next_hint("%d corner%s to the %s" % [togo, "" if togo == 1 else "s", Realms.CHAPTERS[ni]["name"]])
		else:
			_hud.set_next_hint("Next: Level %d" % (_stage + 2))

	var win_title := "You did it!" if was_ftue else "Cottage corner tidied!"
	_hud.show_win(win_title, prev_best, _board.moves, earned, stars, flawless and not was_ftue, par, under_par)
	if under_par:
		_analytics.log_event("under_par", {"stage": _stage, "moves": _board.moves, "par": par})
	if was_ftue:
		_hud.pulse_cottage()

	_ach.scan()   # stars/levels changed via SaveData, not economy.changed

	if SaveData.data["completed"].size() >= 5:
		_platform.request_review()

func _on_double() -> void:
	_ads.watch_rewarded(func() -> void:
		_economy.add_coins(_last_earned)
		_hud.mark_doubled())

func _on_combo_double() -> void:
	var bonus := _hud.combo_bonus()
	_ads.watch_rewarded(func() -> void:
		_economy.add_coins(bonus)
		_hud.flash("Combo doubled   +%d" % bonus)
		_analytics.log_event("combo_double", {"bonus": bonus, "stage": _stage}))

func _on_season_bundle() -> void:
	if int(SaveData.data.get("season_bundle_id", -1)) == DecorData.season_id():
		return
	if not _economy.spend_gems(DecorData.SEASON_BUNDLE_GEMS):
		_shop.flash("Not enough gems")
		return
	SaveData.data["season_bundle_id"] = DecorData.season_id()
	SaveData.save_now()
	var got := 0
	for it in DecorData.current_season()["items"]:
		if _economy.grant_decor(it["id"]):
			got += 1
	_shop.refresh()
	_shop.flash("%s bundle claimed  —  %d piece%s" % [
		DecorData.current_season()["name"], got, "" if got == 1 else "s"])
	_analytics.log_event("season_bundle", {"season": DecorData.season_id(), "got": got})

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
		"struggle":
			_economy.add_gems(int(p.get("gems", 0)))
			_economy.add_coins(int(p.get("coins", 0)))
			_board.add_moves(int(p.get("moves", 0)))
			_hud.set_budget(_board.move_budget)
			_hud.hide_fail()
			SaveData.data["struggle_bought_day"] = _daily.today()
			SaveData.save_now()
			_hud.flash("Struggle pack — +%d gems, +%d coins" % [int(p.get("gems", 0)), int(p.get("coins", 0))])
			msg = ""
		"boosters":
			for bid in Boosters.LIST:
				_economy.add_booster(bid, int(p.get("each", 0)))
			_booster.refresh()
			msg = "Booster bundle — %d of each" % int(p.get("each", 0))
		"pass":
			_bp.set_owned(true)
			_bp_panel.refresh()
			msg = "Season pass unlocked!"
	# First gem pack is doubled — converts non-payers.
	if str(p.get("kind")) == "gems" and not bool(SaveData.data.get("first_gem_buy", false)):
		SaveData.data["first_gem_buy"] = true
		SaveData.save_now()
		_economy.add_gems(int(p["amount"]))
		msg = "First purchase — doubled!  +%d gems" % int(p["amount"])

	# Rotating daily deal — a bonus on today's featured product, once per day.
	var deal := DealData.today()
	if id == str(deal["id"]) and not DealData.claimed_today():
		DealData.mark_claimed()
		var bonus := float(deal["bonus"])
		match str(p.get("kind")):
			"gems":  _economy.add_gems(int(round(float(p["amount"]) * bonus)))
			"coins": _economy.add_coins(int(round(float(p["amount"]) * bonus)))
			"boosters":
				var extra := int(ceil(float(p.get("each", 0)) * bonus))
				for bid in Boosters.LIST:
					_economy.add_booster(bid, extra)
				_booster.refresh()
		msg = "Daily deal bonus applied!"
		_analytics.log_event("daily_deal", {"id": id})

	_ads.remove_ads = _iap.has_remove_ads()
	_shop.refresh()
	if msg != "":
		_shop.flash(msg)

func _on_bp_skip() -> void:
	if _bp.tier_reached() >= BattlePass.TIERS:
		return
	var cost := _bp.skip_cost()
	if _economy.spend_gems(cost):
		_bp.buy_skip()
		_analytics.log_event("bp_skip", {"cost": cost, "tier": _bp.tier_reached()})
		_bp_panel.flash("Tier %d!" % _bp.tier_reached())
	else:
		_bp_panel.flash("Not enough gems")
	_bp_panel.refresh()

func _open_daily() -> void:
	_daily_panel.open()

func _start_jackpot() -> void:
	if not _daily.jackpot_available():
		return
	_daily.consume_jackpot()
	_jackpot_active = true
	_daily_panel.visible = false
	_coach.clear()
	_hud.hide_win()
	_hud.hide_fail()
	_hints_used = 0
	_undos_used = 0
	_stage_fails = 0
	_board.realm = Realms.CHAPTERS[0]
	_board.load_level(LevelGen.generate(4, 3, _daily.jackpot_seed(), 0.7))
	_board.move_budget = _board.UNLIMITED
	_hud.set_title_override("Daily Jackpot")
	_hud.set_budget(_board.UNLIMITED)
	_hud.set_moves(0)
	_analytics.log_event("jackpot_start")
	_refresh_buttons()

func _open_ranks() -> void:
	_daily_panel.visible = false
	var dow := _daily.day_of_week()
	var wrows := Leaderboard.board(_daily.week_stars(), _daily.week_id(), dow)
	var drows := Leaderboard.depth_board(int(SaveData.data.get("stat_deepest", 0)) + 1)
	_lb_panel.open(wrows, Leaderboard.your_rank(wrows), 8 - dow,
		drows, Leaderboard.your_rank(drows))

func _finish_jackpot() -> void:
	_jackpot_active = false
	SaveData.data["stat_jackpot_wins"] = int(SaveData.data.get("stat_jackpot_wins", 0)) + 1
	_economy.add_coins(Daily.JACKPOT_COINS)
	_economy.add_gems(Daily.JACKPOT_GEMS)
	_analytics.log_event("jackpot_win")
	_hud.flash("Daily jackpot!  +%d coins, +%d gems" % [Daily.JACKPOT_COINS, Daily.JACKPOT_GEMS])
	_load_current()

func _grant_bp(r: Dictionary) -> void:
	if r.is_empty():
		return
	if int(r.get("coins", 0)) > 0:
		_economy.add_coins(int(r["coins"]))
	if int(r.get("gems", 0)) > 0:
		_economy.add_gems(int(r["gems"]))
	for bid in r.get("boosters", []):
		_economy.add_booster(bid, 1)
	_bp_panel.refresh()
	_analytics.log_event("bp_claim", {"coins": int(r.get("coins", 0)), "gems": int(r.get("gems", 0))})

func _on_claim_login() -> void:
	var amt := _daily.claim_login()
	if amt > 0:
		_economy.add_coins(amt)
		_bp.add_xp(10)
		_daily_panel.flash("+%d coins" % amt)
		_daily_panel.refresh()

func _on_buy_freeze() -> void:
	if _daily.freezes() >= Daily.FREEZE_CAP:
		return
	if _economy.spend_gems(Daily.FREEZE_GEM_COST):
		_daily.add_freeze(1)
		_daily_panel.flash("Streak freeze added")
	else:
		_daily_panel.flash("Not enough gems")
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

## One-time little celebrations for cottage milestones.
func _first_time_flourish() -> void:
	if not bool(SaveData.data.get("ft_upgrade", false)):
		SaveData.data["ft_upgrade"] = true
		SaveData.save_now()
		_cottage.flash("The cottage remembers this.")
	for room in CottageData.ROOMS:
		var full := true
		for s in room["slots"]:
			if _economy.tier(s["id"]) < CottageData.max_tier(s["id"]):
				full = false
				break
		var key := "ft_room_" + str(room["name"])
		if full and not bool(SaveData.data.get(key, false)):
			SaveData.data[key] = true
			SaveData.save_now()
			_cottage.flash("The %s is fully restored!" % room["name"])
			_analytics.log_event("room_restored", {"room": room["name"]})

func _show_cottage() -> void:
	_board.visible = false
	_hud.visible = false
	_cat.visible = false
	_cottage.open()

func _show_puzzle() -> void:
	_cottage.visible = false
	_board.visible = true
	_hud.visible = true
	_cat.visible = not _jackpot_active

func _show_home() -> void:
	_board.visible = false
	_hud.visible = false
	_cat.visible = false
	for o in [_cottage, _daily_panel, _shop, _settings, _bp_panel, _lb_panel, _select, _booster, _progress]:
		o.visible = false
	_home.configure(_stage, SaveData.data["completed"].size(),
		SaveData.total_stars(), _daily.login_pending())
	_home.open()

## Leave Home for the puzzle; optionally open a meta screen once there. Runs the
## once-per-session pop-ups (daily / starter) the first time.
func _enter_game(then_open := Callable()) -> void:
	_home.close()
	_show_puzzle()
	if not _session_popups_done:
		_session_popups_done = true
		if _daily.login_pending() and not _new_player:
			_open_daily()
		elif _starter_secs_left() > 0 and not bool(SaveData.data.get("starter_shown_once", false)):
			SaveData.data["starter_shown_once"] = true
			SaveData.save_now()
			_hud.flash("Starter pack in the Shop — %dh left" % int(ceil(_starter_secs_left() / 3600.0)))
	if then_open.is_valid():
		then_open.call()

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if _hud.fail_open() or _hud.nav_open() or _booster.visible:
		return
	var overlay := _cottage.visible or _daily_panel.visible or _shop.visible or _settings.visible or _bp_panel.visible or _lb_panel.visible or _progress.visible or _home.visible or _story.visible
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
				_open_shop()
		KEY_M:
			_on_mute_toggled(not _audio.muted)
			_hud.set_muted(_audio.muted)
