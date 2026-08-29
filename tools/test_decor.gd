extends SceneTree
## Headless checks for the endless decor meta. Backs up / restores the real save.
## Run: godot --headless --path . --script res://tools/test_decor.gd

const EconomyS := preload("res://game/economy.gd")

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
	SaveData.data["decor"] = []
	SaveData.data["decor_sets_done"] = []
	SaveData.data["coins"] = 0

	print("endless catalog:")
	var costs := []
	for i in 9:
		costs.append(int(DecorData.endless_item(i)["cost"]))
	var rising := true
	for i in range(1, costs.size()):
		if costs[i] <= costs[i - 1]:
			rising = false
	_ok(rising, "endless cost strictly rises: %s" % str(costs))
	_ok(DecorData.endless_item(3)["id"] == "sundry_3", "endless ids follow the index")

	print("buying the endless sink:")
	var e: Economy = EconomyS.new()
	SaveData.data["coins"] = 10_000_000
	var last_cost := 0
	for step in 5:
		var it := e.next_endless()
		_ok(not e.owns_decor(it["id"]), "next_endless() offers an unowned item (%s)" % it["id"])
		_ok(int(it["cost"]) > last_cost, "  and it costs more than the last (%d > %d)" % [int(it["cost"]), last_cost])
		last_cost = int(it["cost"])
		_ok(e.buy_decor(it["id"]), "  bought %s" % it["id"])
	_ok(e.decor_count() == 5, "decor_count tracks purchases")

	print("set completion:")
	var got := ["", 0]
	e.set_completed.connect(func(name: String, bonus: int) -> void:
		got[0] = name
		got[1] = bonus)
	for it in DecorData.SETS["Garden"]:
		_ok(e.buy_decor(it["id"]), "bought Garden item %s" % it["id"])
	_ok(got[0] == "Garden" and got[1] == DecorData.SET_BONUS, "completing Garden fires set_completed")
	_ok(e.sets_complete_count() == 1, "sets_complete_count == 1")
	_ok(e.owns_decor("g_bench"), "ownership persisted in save data")
	# a partial second set does not fire
	got[0] = ""
	e.buy_decor(DecorData.SETS["Kitchen"][0]["id"])
	_ok(got[0] == "", "a partial set does not complete")
	e.free()

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
