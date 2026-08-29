extends SceneTree
## Headless checks for chapter mapping.
## Run: godot --headless --path . --script res://tools/test_realms.gd

var _fails := 0

func _ok(cond: bool, msg: String) -> void:
	if cond:
		print("  ok  ", msg)
	else:
		_fails += 1
		push_error("FAIL: " + msg)

func _initialize() -> void:
	_ok(Realms.for_stage(0)["name"] == "Pantry", "stage 0 -> Pantry")
	_ok(Realms.for_stage(7)["name"] == "Pantry", "stage 7 -> Pantry")
	_ok(Realms.for_stage(8)["name"] == "Garden", "stage 8 -> Garden")
	_ok(Realms.for_stage(31)["name"] == "Bakery", "stage 31 -> Bakery")
	_ok(Realms.for_stage(40)["name"] == "Beyond", "stage 40 -> Beyond")
	_ok(Realms.for_stage(999)["name"] == "Beyond", "far endless stays Beyond")
	_ok(Realms.index_for(0) == 0 and Realms.index_for(8) == 1 and Realms.index_for(24) == 3,
		"chapter indices step at the boundaries")
	# every chapter carries the four board colours
	for c in Realms.CHAPTERS:
		_ok(c.has("bg_top") and c.has("bg_bot") and c.has("shelf") and c.has("shelf_dark"),
			"%s has all skin colours" % c["name"])

	if _fails == 0:
		print("\nALL PASS")
		quit(0)
	else:
		print("\n%d FAILURE(S)" % _fails)
		quit(1)
