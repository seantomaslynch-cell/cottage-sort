extends SceneTree
## Headless checks for the daily/retention logic. Backs up and restores the real
## save file so running it doesn't clobber a player's progress.
## Run: godot --headless --path . --script res://tools/test_daily.gd

const DailyS := preload("res://game/daily.gd")

var _fails := 0

func _ok(cond: bool, msg: String) -> void:
	if cond:
		print("  ok  ", msg)
	else:
		_fails += 1
		push_error("FAIL: " + msg)

func _initialize() -> void:
	var had_save := FileAccess.file_exists(SaveData.PATH)
	var backup := ""
	if had_save:
		backup = FileAccess.open(SaveData.PATH, FileAccess.READ).get_as_text()

	_reset()
	_test_login()
	_reset()
	_test_login_wrap()
	_reset()
	_test_spin()
	_reset()
	_test_ad_streak()
	_reset()
	_test_weekly()

	if had_save:
		FileAccess.open(SaveData.PATH, FileAccess.WRITE).store_string(backup)
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveData.PATH))

	if _fails == 0:
		print("\nALL PASS")
		quit(0)
	else:
		print("\n%d FAILURE(S)" % _fails)
		quit(1)

func _reset() -> void:
	SaveData.data["daily"] = {
		"streak_len": 0, "last_login_day": 0, "last_spin_day": 0,
		"ad_streak": 0, "ad_last_day": 0,
	}

func _test_weekly() -> void:
	print("weekly event:")
	var d: Daily = DailyS.new()
	_ok(d.week_progress() == 0 and not d.week_goal_met(), "starts empty")
	var g := d.week_goal()
	_ok(g > 0 and d.week_label().length() > 0, "this week's event has a goal and label")
	# a 3-star, under-par, no-hint clear scores 1 toward every event type
	for i in g - 1:
		d.note_level_cleared(1, true, false)
	_ok(d.week_progress() == g - 1 and not d.week_goal_met(), "one short of goal")
	d.note_level_cleared(1, true, false)
	_ok(d.week_goal_met() and not d.week_claimed(), "goal met, unclaimed")
	_ok(d.claim_week() == DailyS.WEEK_CHEST, "claim pays the chest")
	_ok(d.claim_week() == 0 and d.week_claimed(), "second claim pays nothing")
	d.debug_day_offset = 7  # next week
	_ok(d.week_progress() == 0 and not d.week_claimed(), "resets on a new week")

	_ok(d.jackpot_available(), "jackpot available on a fresh day")
	d.consume_jackpot()
	_ok(not d.jackpot_available(), "jackpot consumed for the day")
	d.debug_day_offset = 8
	_ok(d.jackpot_available(), "jackpot back the next day")
	d.free()

func _test_login() -> void:
	print("login cycle:")
	var d: Daily = DailyS.new()
	_ok(d.login_pending(), "pending on first ever launch")
	_ok(d.current_login_reward() == 25, "first reward is 25")
	_ok(d.claim_login() == 25, "claim day 1 -> 25")
	_ok(not d.login_pending(), "not pending right after claim")
	_ok(d.claim_login() == 0, "second claim same day -> 0")
	_ok(d.login_streak() == 1, "streak 1")

	d.debug_day_offset = 1
	_ok(d.login_pending(), "pending next day")
	_ok(d.claim_login() == 40, "claim day 2 -> 40")
	d.debug_day_offset = 2
	_ok(d.claim_login() == 60, "claim day 3 -> 60")
	_ok(d.login_streak() == 3, "streak 3")

	d.debug_day_offset = 8  # skipped days 4..7
	_ok(d.login_pending(), "pending after a gap")
	_ok(d.claim_login() == 25, "gap resets to day 1 -> 25")
	_ok(d.login_streak() == 1, "streak reset to 1")
	d.free()

func _test_login_wrap() -> void:
	print("login 7-day wrap:")
	var d: Daily = DailyS.new()
	var expected := [25, 40, 60, 90, 130, 180, 300, 25]
	for i in expected.size():
		d.debug_day_offset = i
		var got := d.claim_login()
		_ok(got == expected[i], "day %d -> %d (got %d)" % [i + 1, expected[i], got])
	d.free()

func _test_spin() -> void:
	print("spin:")
	var d: Daily = DailyS.new()
	_ok(d.free_spin_available(), "free spin available day 1")
	d.consume_free_spin()
	_ok(not d.free_spin_available(), "no free spin after consuming")
	d.debug_day_offset = 1
	_ok(d.free_spin_available(), "free spin back next day")

	var seen := {}
	var high := 0
	var low := 0
	for i in 20000:
		var idx := d.roll_spin()
		seen[idx] = int(seen.get(idx, 0)) + 1
		if d.spin_value(idx) == 100:
			high += 1
		if d.spin_value(idx) == 15:
			low += 1
	_ok(seen.size() == DailyS.SPIN.size(), "every segment can come up")
	_ok(low > high, "low-value (weight 22) beats jackpot (weight 5): %d vs %d" % [low, high])
	d.free()

func _test_ad_streak() -> void:
	print("ad-watch streak:")
	var d: Daily = DailyS.new()
	var chest := [0]
	d.chest_awarded.connect(func(amt: int) -> void: chest[0] += amt)

	d.note_ad_watched()
	_ok(d.ad_streak() == 1, "day 1 -> streak 1")
	d.note_ad_watched()
	_ok(d.ad_streak() == 1, "same day again -> still 1")
	d.debug_day_offset = 1
	d.note_ad_watched()
	_ok(d.ad_streak() == 2, "day 2 -> streak 2")
	d.debug_day_offset = 2
	d.note_ad_watched()
	_ok(chest[0] == DailyS.AD_STREAK_CHEST, "day 3 -> chest awarded")
	_ok(d.ad_streak() == 0, "streak resets after chest")

	d.debug_day_offset = 10  # long gap
	d.note_ad_watched()
	_ok(d.ad_streak() == 1, "gap -> streak restarts at 1")
	d.free()
