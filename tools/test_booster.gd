extends SceneTree
## Headless checks for gems + boosters. Backs up / restores the real save.
## Run: godot --headless --path . --script res://tools/test_booster.gd

const EconomyS := preload("res://game/economy.gd")
const BoardS := preload("res://game/board.gd")

var _fails := 0

func _ok(cond: bool, msg: String) -> void:
	if cond:
		print("  ok  ", msg)
	else:
		_fails += 1
		push_error("FAIL: " + msg)

func _initialize() -> void:
	var had := FileAccess.file_exists(SaveData.PATH)
	var backup := ""
	if had:
		backup = FileAccess.open(SaveData.PATH, FileAccess.READ).get_as_text()
	SaveData.data["gems"] = 0
	SaveData.data["coins"] = 0

	print("gems:")
	var e: Economy = EconomyS.new()
	e.add_gems(10)
	_ok(e.gems() == 10, "add_gems")
	_ok(e.spend_gems(3) and e.gems() == 7, "spend_gems deducts")
	_ok(not e.spend_gems(100) and e.gems() == 7, "spend_gems refuses when short")
	e.free()

	print("inventory:")
	SaveData.data["boosters"] = {}
	var inv: Economy = EconomyS.new()
	_ok(inv.booster_count("magnet") == 0, "starts empty")
	inv.add_booster("magnet", 3)
	_ok(inv.booster_count("magnet") == 3, "add_booster")
	_ok(inv.use_booster("magnet") and inv.booster_count("magnet") == 2, "use_booster decrements")
	inv.add_booster("magnet", -5)
	_ok(inv.booster_count("magnet") == 0, "count clamps at 0")
	_ok(not inv.use_booster("magnet"), "use_booster fails when empty")
	inv.free()

	print("booster data:")
	_ok(Boosters.LIST.size() >= 6, "at least 6 boosters")
	for id in Boosters.LIST:
		_ok(Boosters.NAME.has(id) and Boosters.DESC.has(id) and Boosters.COST.has(id),
			"%s has name/desc/cost" % id)

	print("board effects:")
	var b = BoardS.new()

	b.load_level({"jars": [[1, 0], [2, 0], [0, 3], [1, 1], []]})
	var before := _max_run(b, 0)
	b.magnet()
	_ok(_max_run(b, 0) > before, "magnet grows the biggest run of a colour (%d -> %d)" % [before, _max_run(b, 0)])

	b.load_level({"jars": [[0, 0, 0], [1, 1, 1, 1], [2, 2, 2, 2], [0], []]})
	var solved := [false]
	b.solved.connect(func() -> void: solved[0] = true)
	b.autoplay(3)
	_ok(solved[0], "autoplay finishes a near-solved board")
	_ok(b.moves == 0, "autoplay does not spend moves")

	b.load_level({"jars": [[0, 1], [1, 0], []]})
	var jc: int = b.jars.size()
	b.force_add_jar()
	_ok(int(b.jars.size()) == jc + 1, "force_add_jar adds a jar")

	# effects report failure when the board is busy/locked (so main won't consume it)
	b.load_level({"jars": [[0, 1], [1, 0], []]})
	b._busy = true
	_ok(b.magnet() == false and b.autoplay(3) == false and b.force_add_jar() == false,
		"boosters fail while the board is busy")
	b._busy = false
	b.load_level({"jars": [[0, 0, 0, 0], [1, 1, 1, 1], []]})   # already solved
	_ok(b.autoplay(3) == false, "autoplay returns false when already solved")

	# a booster reshapes the board -> undo history is dropped, no stale replay
	b.load_level({"jars": [[0, 1, 0], [1, 0, 1], [1, 0], []]})
	b._apply_move(0, 3)                 # a real move -> would be in history
	b._history = [{"from": 0, "to": 3, "count": 1}]
	b.magnet()
	_ok(b._history.is_empty(), "magnet clears the undo history")
	b.undo()                           # must be a safe no-op, not a crash
	_ok(true, "undo after a booster is a safe no-op")
	b.free()

	print("iap:")
	var gm := GameIap.new()
	var p := gm.product("gems_medium")
	_ok(p.get("kind") == "gems" and int(p.get("amount", 0)) == 250, "gems_medium product shape")
	gm.free()

	if had:
		FileAccess.open(SaveData.PATH, FileAccess.WRITE).store_string(backup)
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveData.PATH))

	if _fails == 0:
		print("\nALL PASS")
		quit(0)
	else:
		print("\n%d FAILURE(S)" % _fails)
		quit(1)

func _max_run(b, colour: int) -> int:
	var best := 0
	for j in b.jars:
		var run := 0
		for v in j:
			run = run + 1 if v == colour else 0
			best = maxi(best, run)
	return best
