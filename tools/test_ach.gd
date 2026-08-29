extends SceneTree
## M35 achievements: progress() reads state, scan() grants finished badges once
## and pays out, and re-scanning is a no-op. Backs up / restores save.json.

var _backup := ""
var _had := false

func _initialize() -> void:
	_had = FileAccess.file_exists(SaveData.PATH)
	if _had:
		_backup = FileAccess.open(SaveData.PATH, FileAccess.READ).get_as_text()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveData.PATH))
	change_scene_to_file("res://game/main.tscn")
	_run.call_deferred()

func _run() -> void:
	await create_timer(0.6).timeout
	var fails := 0
	var main := _find_by_script(get_root(), "res://game/main.gd")
	var ach := _find(get_root(), "Achievements")
	var eco := _find(get_root(), "Economy")
	if main == null or ach == null or eco == null:
		_fail("nodes not found"); return
	main._enter_game()
	await create_timer(0.1).timeout

	# nothing earned on a fresh save
	if ach.unlocked_count() != 0:
		fails += 1; push_error("fresh save already has %d achievements" % ach.unlocked_count())
	if ach.is_done("lvl10"):
		fails += 1; push_error("lvl10 done with 0 levels cleared")

	# seed state: 10 cleared, 12 three-starred, best combo 5, a flawless clear
	var comp := {}
	var stars := {}
	for i in 12:
		comp[str(i)] = 6
		stars[str(i)] = 3
	SaveData.data["completed"] = comp
	SaveData.data["stars"] = stars
	SaveData.data["stat_best_combo"] = 5
	SaveData.data["stat_flawless"] = 1

	var p: Vector2i = ach.progress("lvl10")
	if p != Vector2i(10, 10):
		fails += 1; push_error("progress(lvl10) = %s, want (10,10)" % str(p))
	if not ach.is_done("star3_10"):
		fails += 1; push_error("star3_10 not done with 12 three-stars")

	var coins_before: int = eco.coins()
	var granted: Array = []
	ach.granted.connect(func(id, _n, _c, _g): granted.append(id))
	ach.scan()
	await create_timer(0.1).timeout

	for want in ["lvl10", "star3_1", "star3_10", "combo3", "combo5", "flawless"]:
		if not ach.unlocked(want):
			fails += 1; push_error("expected %s unlocked after scan" % want)
	if ach.unlocked("lvl25"):
		fails += 1; push_error("lvl25 unlocked with only 12 cleared")
	if eco.coins() <= coins_before:
		fails += 1; push_error("no coins paid for the earned badges")
	var n_after: int = ach.unlocked_count()

	# re-scan grants nothing new
	granted.clear()
	ach.scan()
	await create_timer(0.05).timeout
	if not granted.is_empty():
		fails += 1; push_error("re-scan granted again: %s" % str(granted))
	if ach.unlocked_count() != n_after:
		fails += 1; push_error("unlocked_count changed on idempotent re-scan")

	_restore()
	if fails == 0:
		print("\nALL PASS  (%d badges earned from the seeded state)" % n_after)
		quit(0)
	else:
		print("\n%d FAILURE(S)" % fails)
		quit(1)

func _fail(m: String) -> void:
	push_error(m); _restore(); quit(1)

func _restore() -> void:
	if _had:
		FileAccess.open(SaveData.PATH, FileAccess.WRITE).store_string(_backup)
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveData.PATH))

func _find(n: Node, cls: String) -> Node:
	var s: Script = n.get_script()
	if s != null and String(s.get_global_name()) == cls:
		return n
	for c in n.get_children():
		var r := _find(c, cls)
		if r: return r
	return null

func _find_by_script(n: Node, path: String) -> Node:
	var s: Script = n.get_script()
	if s != null and s.resource_path == path:
		return n
	for c in n.get_children():
		var r := _find_by_script(c, path)
		if r: return r
	return null
