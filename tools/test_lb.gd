extends SceneTree
## Headless checks for the ghost leaderboard.
## Run: godot --headless --path . --script res://tools/test_lb.gd

var _fails := 0

func _ok(cond: bool, msg: String) -> void:
	if cond:
		print("  ok  ", msg)
	else:
		_fails += 1
		push_error("FAIL: " + msg)

func _initialize() -> void:
	var a := Leaderboard.board(20, 5, 3)
	var b := Leaderboard.board(20, 5, 3)
	_ok(_stars(a) == _stars(b), "board is deterministic for a given week/day")

	var c := Leaderboard.board(20, 5, 6)
	_ok(_total(c) > _total(a), "bots grow later in the week")

	_ok(a.size() == Leaderboard.NAMES.size() + 1, "you are spliced into the field")
	_ok(_is_sorted(a), "rows sorted by stars desc")

	var lo := Leaderboard.board(0, 5, 4)
	var hi := Leaderboard.board(9999, 5, 4)
	_ok(Leaderboard.your_rank(hi) == 1, "a huge score ranks first")
	_ok(Leaderboard.your_rank(lo) == lo.size(), "zero ranks last")

	# different weeks -> different bot field
	_ok(_stars(Leaderboard.board(20, 5, 3)) != _stars(Leaderboard.board(20, 6, 3)),
		"a new week reshuffles the bots")

	if _fails == 0:
		print("\nALL PASS")
		quit(0)
	else:
		print("\n%d FAILURE(S)" % _fails)
		quit(1)

func _stars(rows: Array) -> Array:
	return rows.map(func(r): return int(r["stars"]))

func _total(rows: Array) -> int:
	var t := 0
	for r in rows:
		t += int(r["stars"])
	return t

func _is_sorted(rows: Array) -> bool:
	for i in range(1, rows.size()):
		if int(rows[i]["stars"]) > int(rows[i - 1]["stars"]):
			return false
	return true
