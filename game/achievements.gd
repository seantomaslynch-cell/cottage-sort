extends Node
class_name Achievements
## Badges. Each is a pure function of persisted state (SaveData + Economy +
## Daily + BattlePass, plus a few lifetime `stat_*` counters main bumps).
## Completion is detected automatically; the reward is granted on the spot and
## the badge is recorded in SaveData.data["achievements"].

signal granted(id: String, name: String, coins: int, gems: int)

const CATS := ["Progress", "Skill", "Cottage", "Habit"]

const LIST: Array[Dictionary] = [
	# id, name, desc, cat, goal, coins, gems
	{"id": "lvl10",  "name": "Getting Tidy",     "desc": "Clear 10 levels",           "cat": "Progress", "goal": 10,  "coins": 100, "gems": 0},
	{"id": "lvl25",  "name": "House Proud",      "desc": "Clear 25 levels",           "cat": "Progress", "goal": 25,  "coins": 200, "gems": 0},
	{"id": "lvl50",  "name": "Sorted",          "desc": "Clear 50 levels",           "cat": "Progress", "goal": 50,  "coins": 300, "gems": 2},
	{"id": "lvl100", "name": "Spotless",        "desc": "Clear 100 levels",          "cat": "Progress", "goal": 100, "coins": 500, "gems": 5},
	{"id": "ch3",    "name": "Three Rooms In",   "desc": "Reach the Attic",           "cat": "Progress", "goal": 17,  "coins": 150, "gems": 0},
	{"id": "curve",  "name": "The Grand Tour",   "desc": "Clear all 40 story levels", "cat": "Progress", "goal": 40,  "coins": 400, "gems": 3},

	{"id": "star3_1",  "name": "First Sparkle",  "desc": "Earn 3 stars on a level",   "cat": "Skill", "goal": 1,  "coins": 60,  "gems": 0},
	{"id": "star3_10", "name": "Perfectionist",  "desc": "3-star 10 levels",          "cat": "Skill", "goal": 10, "coins": 150, "gems": 0},
	{"id": "star3_30", "name": "Immaculate",     "desc": "3-star 30 levels",          "cat": "Skill", "goal": 30, "coins": 300, "gems": 2},
	{"id": "flawless", "name": "Flawless",       "desc": "3-star with no undo or hint", "cat": "Skill", "goal": 1, "coins": 100, "gems": 1},
	{"id": "combo3",   "name": "On a Roll",      "desc": "Land a x3 combo",           "cat": "Skill", "goal": 3,  "coins": 80,  "gems": 0},
	{"id": "combo5",   "name": "Unstoppable",    "desc": "Land a x5 combo",           "cat": "Skill", "goal": 5,  "coins": 200, "gems": 2},

	{"id": "up1",       "name": "Handy",         "desc": "Buy your first upgrade",    "cat": "Cottage", "goal": 1,   "coins": 40,  "gems": 0},
	{"id": "room1",     "name": "Room Restored", "desc": "Fully restore any room",    "cat": "Cottage", "goal": 1,   "coins": 200, "gems": 0},
	{"id": "restored",  "name": "Home Sweet Home", "desc": "Restore the cottage 100%", "cat": "Cottage", "goal": 100, "coins": 500, "gems": 5},
	{"id": "set1",      "name": "Collector",     "desc": "Complete a decor set",      "cat": "Cottage", "goal": 1,   "coins": 150, "gems": 0},
	{"id": "decor25",   "name": "Well Furnished", "desc": "Own 25 decor pieces",      "cat": "Cottage", "goal": 25,  "coins": 250, "gems": 2},
	{"id": "endless60", "name": "Beyond",        "desc": "Reach Level 60",            "cat": "Cottage", "goal": 60,  "coins": 300, "gems": 3},
	{"id": "endless100", "name": "Homesteader", "desc": "Reach Level 100",           "cat": "Cottage", "goal": 100, "coins": 500, "gems": 5},

	{"id": "login3",  "name": "Regular",        "desc": "3-day login streak",        "cat": "Habit", "goal": 3,  "coins": 80,  "gems": 0},
	{"id": "login7",  "name": "Devoted",        "desc": "7-day login streak",        "cat": "Habit", "goal": 7,  "coins": 200, "gems": 2},
	{"id": "week1",   "name": "Weekly Win",     "desc": "Claim a weekly chest",      "cat": "Habit", "goal": 1,  "coins": 120, "gems": 0},
	{"id": "jack1",   "name": "Jackpot!",       "desc": "Win a daily jackpot",       "cat": "Habit", "goal": 1,  "coins": 100, "gems": 1},
	{"id": "bp15",    "name": "Pass Halfway",   "desc": "Reach battle-pass tier 15", "cat": "Habit", "goal": 15, "coins": 150, "gems": 0},
	{"id": "bp30",    "name": "Full Pass",      "desc": "Reach battle-pass tier 30", "cat": "Habit", "goal": 30, "coins": 300, "gems": 3},
]

var _eco: Economy
var _daily: Daily
var _bp: BattlePass

func set_refs(economy: Economy, daily: Daily, bp: BattlePass) -> void:
	_eco = economy
	_daily = daily
	_bp = bp

static func def(id: String) -> Dictionary:
	for a in LIST:
		if a["id"] == id:
			return a
	return {}

func _stat(key: String) -> int:
	return int(SaveData.data.get(key, 0))

func _completed() -> int:
	return (SaveData.data.get("completed", {}) as Dictionary).size()

func _stars3() -> int:
	var n := 0
	for k in SaveData.data.get("stars", {}):
		if int(SaveData.data["stars"][k]) >= 3:
			n += 1
	return n

func _rooms_full() -> int:
	var n := 0
	for room in CottageData.ROOMS:
		var full := true
		for s in room["slots"]:
			if _eco == null or _eco.tier(s["id"]) < CottageData.max_tier(s["id"]):
				full = false
				break
		if full:
			n += 1
	return n

func _upgrades_bought() -> int:
	var n := 0
	if _eco != null:
		for s in CottageData.SLOTS:
			n += _eco.tier(s["id"])
	return n

## have / goal for a badge (have is capped at goal).
func progress(id: String) -> Vector2i:
	var d := def(id)
	if d.is_empty():
		return Vector2i.ZERO
	var g: int = d["goal"]
	var have := 0
	match id:
		"lvl10", "lvl25", "lvl50", "lvl100": have = _completed()
		"ch3", "endless60", "endless100": have = _stat("stat_deepest") + 1
		"curve":
			for i in 40:
				if (SaveData.data.get("completed", {}) as Dictionary).has(str(i)):
					have += 1
		"star3_1", "star3_10", "star3_30": have = _stars3()
		"flawless": have = _stat("stat_flawless")
		"combo3", "combo5": have = _stat("stat_best_combo")
		"up1": have = _upgrades_bought()
		"room1": have = _rooms_full()
		"restored": have = roundi(_eco.restored_fraction() * 100.0) if _eco != null else 0
		"set1": have = _eco.sets_complete_count() if _eco != null else 0
		"decor25": have = _eco.decor_count() if _eco != null else 0
		"login3", "login7": have = _daily.login_streak() if _daily != null else 0
		"week1": have = _stat("stat_week_chests")
		"jack1": have = _stat("stat_jackpot_wins")
		"bp15", "bp30": have = _bp.tier_reached() if _bp != null else 0
	return Vector2i(mini(have, g), g)

func is_done(id: String) -> bool:
	var p := progress(id)
	return p.x >= p.y and p.y > 0

func unlocked(id: String) -> bool:
	return bool((SaveData.data.get("achievements", {}) as Dictionary).get(id, false))

func unlocked_count() -> int:
	var n := 0
	for a in LIST:
		if unlocked(a["id"]):
			n += 1
	return n

var _scanning := false

## Detect any newly-finished badges, record + reward them, emit `granted` each.
func scan() -> void:
	if _scanning:
		return
	_scanning = true
	var ach: Dictionary = SaveData.data.get("achievements", {})
	var dirty := false
	for a in LIST:
		var id: String = a["id"]
		if not bool(ach.get(id, false)) and is_done(id):
			ach[id] = true
			dirty = true
			granted.emit(id, a["name"], int(a["coins"]), int(a["gems"]))
	if dirty:
		SaveData.data["achievements"] = ach
		SaveData.save_now()
	_scanning = false
