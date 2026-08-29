extends SceneTree
## Loads the game, lets it settle, shows the requested screen, writes a PNG of
## the viewport, and restores the save file it borrowed.
##
## Run WITHOUT --headless (needs a real renderer):
##   godot --path . --script res://tools/screenshot.gd -- res://shot.png [board|cottage|daily|shop]

var _backup := ""
var _had_save := false

func _initialize() -> void:
	_had_save = FileAccess.file_exists(SaveData.PATH)
	if _had_save:
		_backup = FileAccess.open(SaveData.PATH, FileAccess.READ).get_as_text()
	change_scene_to_file("res://game/main.tscn")
	_run.call_deferred()

func _run() -> void:
	await create_timer(1.0).timeout

	var args := OS.get_cmdline_user_args()
	var out: String = args[0] if args.size() > 0 else "res://shot.png"
	var mode: String = args[1] if args.size() > 1 else "board"
	var arg_stage: int = int(args[2]) if args.size() > 2 else -1

	var main := _find_by_script(get_root(), "res://game/main.gd")
	if mode == "story":
		var st := _find(get_root(), "IntroStory")
		if st:
			st.show_story()
		await create_timer(0.6).timeout
	elif mode == "home":
		if main and main.has_method("_show_home"):
			main._show_home()
		await create_timer(0.6).timeout
	elif main and main.has_method("_enter_game"):
		main._enter_game()          # leave the Home screen for the board
		await create_timer(0.3).timeout

	if mode == "chapter" and main:
		main._on_stage_picked(8)          # first Garden level -> chapter card
		await create_timer(0.7).timeout
	elif arg_stage >= 0:
		if main and main.has_method("_on_stage_picked"):
			main._on_stage_picked(arg_stage)
			await create_timer(0.5).timeout

	var cottage := _find(get_root(), "CottageScreen")
	var daily := _find(get_root(), "DailyPanel")
	var shop := _find(get_root(), "ShopPanel")
	var settings := _find(get_root(), "SettingsPanel")
	var levelsel := _find(get_root(), "LevelSelect")
	var booster := _find(get_root(), "BoosterPanel")
	var bp := _find(get_root(), "BattlePassPanel")
	var hud := _find(get_root(), "GameHUD")
	var economy := _find(get_root(), "Economy")

	var home := _find(get_root(), "HomeScreen")
	for o in [cottage, daily, shop, settings, levelsel, booster, bp]:
		if o and mode != "home":
			o.visible = false
	if home and mode != "home":
		home.visible = false

	match mode:
		"cottage":
			if economy:
				economy.add_coins(400)
				for slot in ["roof", "walls", "garden", "window", "door"]:
					economy.buy(slot)
			if cottage:
				cottage.open()
		"cottage_decor":
			if economy:
				economy.add_coins(3000)
				for slot in ["roof", "walls", "garden"]:
					economy.buy(slot)
				for did in ["g_bench", "g_pots", "k_rug", "n_chair"]:
					economy.buy_decor(did)
			if cottage:
				cottage.open()
				if cottage.has_method("_show_tab"):
					cottage._show_tab("decorate")
		"daily":
			if daily:
				daily.open()
		"shop":
			if economy:
				economy.piggy_add(140)
			if shop:
				if shop.has_method("set_starter_secs"):
					shop.set_starter_secs(41 * 3600)
				shop.open()
		"settings":
			if settings:
				settings.open()
		"booster":
			if economy:
				economy.add_gems(12)
			if booster:
				booster.open()
		"fail":
			if hud:
				hud.show_fail(100, 50, true, true)
		"season":
			if bp and bp.bp:
				bp.bp.add_xp(340)
				bp.open()
		"trophies", "stats", "collection":
			var apanel := _find(get_root(), "ProgressPanel")
			if economy:
				economy.add_coins(1500)
				for slot in ["roof", "walls", "garden"]:
					economy.buy(slot)
				for did in ["g_bench", "g_pots", "k_rug", "n_chair", "n_cat"]:
					economy.buy_decor(did)
			SaveData.data["completed"] = {}
			SaveData.data["stars"] = {}
			for i in 12:
				SaveData.data["completed"][str(i)] = 6
				SaveData.data["stars"][str(i)] = (3 if i % 2 == 0 else 2)
			SaveData.data["stat_best_combo"] = 4
			SaveData.data["stat_flawless"] = 1
			SaveData.data["stat_deepest"] = 14
			SaveData.data["stat_days_played"] = 6
			SaveData.data["stat_coins_earned"] = 2400
			var ach := _find(get_root(), "Achievements")
			if ach:
				ach.scan()
			if apanel:
				apanel.open("badges" if mode == "trophies" else mode)

	await create_timer(0.7).timeout

	var img := get_root().get_texture().get_image()
	var err := img.save_png(ProjectSettings.globalize_path(out))
	print("screenshot(", mode, ") -> ", ProjectSettings.globalize_path(out), "  err=", err)

	if _had_save:
		FileAccess.open(SaveData.PATH, FileAccess.WRITE).store_string(_backup)
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveData.PATH))

	quit(0 if err == OK else 1)

func _find(n: Node, cls: String) -> Node:
	var s: Script = n.get_script()
	if s != null and String(s.get_global_name()) == cls:
		return n
	for c in n.get_children():
		var r := _find(c, cls)
		if r:
			return r
	return null

func _find_by_script(n: Node, path: String) -> Node:
	var s: Script = n.get_script()
	if s != null and s.resource_path == path:
		return n
	for c in n.get_children():
		var r := _find_by_script(c, path)
		if r:
			return r
	return null
