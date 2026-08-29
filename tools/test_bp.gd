extends SceneTree
## Headless checks for the season pass. Backs up / restores the real save.
## Run: godot --headless --path . --script res://tools/test_bp.gd

const BpS := preload("res://game/battle_pass.gd")

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
	SaveData.data["bp"] = {}

	var bp: BattlePass = BpS.new()
	_ok(bp.xp() == 0 and bp.tier_reached() == 0, "fresh season")
	bp.add_xp(250)
	_ok(bp.tier_reached() == 2, "250 XP -> tier 2 (100/tier)")

	var f := bp.claim_free()
	_ok(int(f.get("coins", 0)) > 0 and bp.free_claimed() == 2, "claim_free grants tiers 1-2 and advances")
	_ok(bp.claim_free().is_empty(), "nothing more to claim on the free track")

	_ok(bp.claim_premium().is_empty(), "premium locked without the pass")
	bp.set_owned(true)
	var p := bp.claim_premium()
	_ok(int(p.get("gems", 0)) > 0 and bp.prem_claimed() == 2, "premium track claims after unlock")

	# rewards are deterministic and every 5th free tier carries a booster
	_ok(BattlePass.reward(5, false).has("booster"), "free tier 5 has a booster")
	_ok(int(BattlePass.reward(10, true).get("gems", 0)) >= int(BattlePass.reward(3, true).get("gems", 0)),
		"premium gems don't shrink with tier")

	# tier skip jumps to the next whole tier boundary
	SaveData.data["bp"] = {}
	var bp2: BattlePass = BpS.new()
	bp2.add_xp(130)   # tier 1, 30 into tier 2
	_ok(bp2.skip_cost() > 0, "skip_cost is positive")
	_ok(bp2.buy_skip() and bp2.tier_reached() == 2 and bp2.xp() == 200, "buy_skip -> exactly tier 2")
	bp2.free()

	# season rollover clears state
	bp.debug_day_offset = BattlePass.SEASON_DAYS + 1
	_ok(bp.xp() == 0 and not bp.pass_owned(), "a new season resets xp and ownership")
	bp.free()

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
