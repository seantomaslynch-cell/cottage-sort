extends Node
class_name Daily
## Retention systems: a 7-day login-reward cycle (exponential-ish curve), a
## once-a-day spin, and a 3-day "watched a rewarded ad" streak that pays a chest.
## State lives in SaveData.data["daily"]; day = whole UTC days since epoch, plus
## an in-memory debug offset so QA can march forward without waiting.

signal changed
signal chest_awarded(amount: int)
signal streak_frozen(streak: int)   # a missed day was covered by a freeze token

const LOGIN_REWARDS := [25, 40, 60, 90, 130, 180, 300]
const FREEZE_CAP := 2
const FREEZE_GEM_COST := 10
const AD_STREAK_TARGET := 3
const AD_STREAK_CHEST := 150
const SPIN := [
	{"value": 15, "weight": 22},
	{"value": 30, "weight": 18},
	{"value": 50, "weight": 12},
	{"value": 20, "weight": 20},
	{"value": 40, "weight": 14},
	{"value": 100, "weight": 5},
	{"value": 25, "weight": 18},
	{"value": 60, "weight": 8},
]

var debug_day_offset := 0

## Whole days since the epoch, in the player's LOCAL timezone, plus the QA
## offset. Local so "daily reset" lands near local midnight, not UTC midnight.
func today() -> int:
	var bias: int = Time.get_time_zone_from_system().get("bias", 0)
	return int((Time.get_unix_time_from_system() + bias * 60) / 86400.0) + debug_day_offset

func _d() -> Dictionary:
	var d: Dictionary = SaveData.data.get("daily", {})
	SaveData.data["daily"] = d
	return d

func _commit(d: Dictionary) -> void:
	SaveData.data["daily"] = d
	SaveData.save_now()
	changed.emit()

# --- login rewards ----------------------------------------------------------

func login_pending() -> bool:
	return today() != int(_d().get("last_login_day", 0))

func _slot_for(streak: int) -> int:
	return (maxi(1, streak) - 1) % LOGIN_REWARDS.size()

# --- streak freeze --------------------------------------------------------
# A token that covers a single missed day so a long login streak survives one
# slip. One is granted free each week (capped), and more can be bought for gems.

func freezes() -> int:
	return int(_d().get("freezes", 1))

func add_freeze(n: int) -> void:
	var d := _d()
	d["freezes"] = clampi(freezes() + n, 0, FREEZE_CAP)
	_commit(d)

## What the streak becomes if the login is claimed right now, and whether a
## freeze token would be spent to get there.
func _resolve_streak() -> Dictionary:
	var d := _d()
	var last := int(d.get("last_login_day", 0))
	var streak := int(d.get("streak_len", 0))
	var t := today()
	if last == 0:
		return {"streak": 1, "freeze_used": false}
	if t == last:
		return {"streak": maxi(1, streak), "freeze_used": false}
	if t == last + 1:
		return {"streak": streak + 1, "freeze_used": false}
	# Exactly one missed day, and a token in hand -> keep the streak going.
	if t == last + 2 and freezes() > 0 and streak >= 1:
		return {"streak": streak + 1, "freeze_used": true}
	return {"streak": 1, "freeze_used": false}

func _streak_if_claimed_now() -> int:
	return int(_resolve_streak()["streak"])

func current_login_slot() -> int:
	return _slot_for(_streak_if_claimed_now())

func current_login_reward() -> int:
	return LOGIN_REWARDS[current_login_slot()]

func login_streak() -> int:
	return int(_d().get("streak_len", 0))

func claim_login() -> int:
	if not login_pending():
		return 0
	var d := _d()
	var res := _resolve_streak()
	var new_streak: int = res["streak"]
	if bool(res["freeze_used"]):
		d["freezes"] = maxi(0, freezes() - 1)
	d["streak_len"] = new_streak
	d["last_login_day"] = today()
	_commit(d)
	if bool(res["freeze_used"]):
		streak_frozen.emit(new_streak)
	return LOGIN_REWARDS[_slot_for(new_streak)]

# --- spin -----------------------------------------------------------------

func free_spin_available() -> bool:
	return today() != int(_d().get("last_spin_day", 0))

func roll_spin() -> int:
	var total := 0
	for s in SPIN:
		total += int(s["weight"])
	var r := randi_range(1, total)
	var acc := 0
	for i in SPIN.size():
		acc += int(SPIN[i]["weight"])
		if r <= acc:
			return i
	return SPIN.size() - 1

func consume_free_spin() -> void:
	var d := _d()
	d["last_spin_day"] = today()
	_commit(d)

func spin_value(index: int) -> int:
	return int(SPIN[index]["value"])

# --- rewarded-ad streak -------------------------------------------------------

func ad_streak() -> int:
	return int(_d().get("ad_streak", 0))

func note_ad_watched() -> void:
	var d := _d()
	var t := today()
	var last := int(d.get("ad_last_day", 0))
	if t == last:
		return
	var streak := int(d.get("ad_streak", 0))
	streak = streak + 1 if (last != 0 and t == last + 1) else 1
	d["ad_last_day"] = t
	if streak >= AD_STREAK_TARGET:
		d["ad_streak"] = 0
		_commit(d)
		chest_awarded.emit(AD_STREAK_CHEST)
		return
	d["ad_streak"] = streak
	_commit(d)

# --- debug --------------------------------------------------------------------

func advance_debug_day() -> void:
	debug_day_offset += 1
	changed.emit()

# --- daily jackpot ----------------------------------------------------------
# One special board a day. You must WIN it to claim the prize (audit: reinforces
# the core loop instead of a passive login bonus).

const JACKPOT_COINS := 150
const JACKPOT_GEMS := 3

func jackpot_available() -> bool:
	return today() != int(_d().get("last_jackpot_day", -1))

func jackpot_seed() -> int:
	return 77000 + today()

## Consume the day's attempt (call when the board is started).
func consume_jackpot() -> void:
	var d := _d()
	d["last_jackpot_day"] = today()
	_commit(d)

# --- weekly event (rotates by week) --------------------------------------

const WEEK_CHEST := 200
const WEEK_EVENTS := [
	{"id": "clear",  "label": "Clear %d levels this week",      "goal": 15},
	{"id": "stars",  "label": "Earn %d stars this week",        "goal": 30},
	{"id": "par",    "label": "Beat par on %d levels this week", "goal": 6},
	{"id": "nohint", "label": "%d clears with no hint",         "goal": 8},
]

func week_id() -> int:
	return int(today() / 7.0)

func week_event() -> Dictionary:
	return WEEK_EVENTS[week_id() % WEEK_EVENTS.size()]

func week_goal() -> int:
	return int(week_event()["goal"])

func week_label() -> String:
	return str(week_event()["label"]) % week_goal()

func _week() -> Dictionary:
	var d := _d()
	if int(d.get("week_id", -1)) != week_id():
		var rollover := d.has("week_id")   # not the very first call for this save
		d["week_id"] = week_id()
		d["week_prog"] = 0
		d["week_stars"] = 0
		d["week_claimed"] = false
		if rollover:
			d["freezes"] = clampi(int(d.get("freezes", 1)) + 1, 0, FREEZE_CAP)
		_commit(d)
	return d

func week_progress() -> int:
	return mini(int(_week().get("week_prog", 0)), week_goal())

func week_goal_met() -> bool:
	return int(_week().get("week_prog", 0)) >= week_goal()

func week_claimed() -> bool:
	return bool(_week().get("week_claimed", false))

## Called on every clear with the outcome, so the active event can score it.
func note_level_cleared(stars: int = 1, under_par: bool = false, used_hint: bool = false) -> void:
	var d := _week()
	if bool(d.get("week_claimed", false)):
		return
	d["week_stars"] = int(d.get("week_stars", 0)) + maxi(0, stars)   # kept for the leaderboard
	var inc := 0
	match str(week_event()["id"]):
		"clear":  inc = 1
		"stars":  inc = maxi(0, stars)
		"par":    inc = 1 if under_par else 0
		"nohint": inc = 1 if not used_hint else 0
	if inc > 0:
		d["week_prog"] = int(d.get("week_prog", 0)) + inc
	_commit(d)

func week_stars() -> int:
	return int(_week().get("week_stars", 0))

func day_of_week() -> int:
	return today() % 7 + 1

func claim_week() -> int:
	var d := _week()
	if not week_goal_met() or bool(d.get("week_claimed", false)):
		return 0
	d["week_claimed"] = true
	_commit(d)
	return WEEK_CHEST
