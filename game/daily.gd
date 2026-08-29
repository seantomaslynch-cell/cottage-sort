extends Node
class_name Daily
## Retention systems: a 7-day login-reward cycle (exponential-ish curve), a
## once-a-day spin, and a 3-day "watched a rewarded ad" streak that pays a chest.
## State lives in SaveData.data["daily"]; day = whole UTC days since epoch, plus
## an in-memory debug offset so QA can march forward without waiting.

signal changed
signal chest_awarded(amount: int)

const LOGIN_REWARDS := [25, 40, 60, 90, 130, 180, 300]
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

func today() -> int:
	return int(Time.get_unix_time_from_system() / 86400.0) + debug_day_offset

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

func _streak_if_claimed_now() -> int:
	var d := _d()
	var last := int(d.get("last_login_day", 0))
	var streak := int(d.get("streak_len", 0))
	var t := today()
	if last != 0 and t == last + 1:
		return streak + 1
	if last != 0 and t == last:
		return streak
	return 1

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
	var new_streak := _streak_if_claimed_now()
	d["streak_len"] = new_streak
	d["last_login_day"] = today()
	_commit(d)
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
