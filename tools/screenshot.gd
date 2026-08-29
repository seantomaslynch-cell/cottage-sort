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

	var cottage := _find(get_root(), "CottageScreen")
	var daily := _find(get_root(), "DailyPanel")
	var shop := _find(get_root(), "ShopPanel")
	var settings := _find(get_root(), "SettingsPanel")
	var levelsel := _find(get_root(), "LevelSelect")
	var booster := _find(get_root(), "BoosterPanel")
	var economy := _find(get_root(), "Economy")

	for o in [cottage, daily, shop, settings, levelsel, booster]:
		if o:
			o.visible = false

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
