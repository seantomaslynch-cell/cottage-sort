extends Node
class_name BattlePass
## A 28-day seasonal track. XP comes from play; tiers unlock at fixed XP.
## Every tier has a free reward; the premium reward needs the season pass IAP.
## State lives in SaveData.data["bp"], keyed by season id so it self-resets.

signal changed

const TIERS := 30
const XP_PER_TIER := 100
const SEASON_DAYS := 28

var debug_day_offset := 0   # kept in sync with Daily by main for QA

func _today() -> int:
	var bias: int = Time.get_time_zone_from_system().get("bias", 0)
	return int((Time.get_unix_time_from_system() + bias * 60) / 86400.0) + debug_day_offset

func season_id() -> int:
	return int(_today() / float(SEASON_DAYS))

func days_left() -> int:
	return SEASON_DAYS - (_today() % SEASON_DAYS)

func _bp() -> Dictionary:
	var d: Dictionary = SaveData.data.get("bp", {})
	if int(d.get("season_id", -1)) != season_id():
		d = {"season_id": season_id(), "xp": 0, "owned": false,
			"free_claimed": 0, "prem_claimed": 0}
		SaveData.data["bp"] = d
		SaveData.save_now()
	return d

func xp() -> int:
	return int(_bp().get("xp", 0))

func tier_reached() -> int:
	return mini(TIERS, xp() / XP_PER_TIER)

func add_xp(n: int) -> void:
	if n <= 0:
		return
	var d := _bp()
	d["xp"] = int(d.get("xp", 0)) + n
	SaveData.data["bp"] = d
	SaveData.save_now()
	changed.emit()

func pass_owned() -> bool:
	return bool(_bp().get("owned", false))

func set_owned(v: bool) -> void:
	var d := _bp()
	d["owned"] = v
	SaveData.data["bp"] = d
	SaveData.save_now()
	changed.emit()

func free_claimed() -> int:
	return int(_bp().get("free_claimed", 0))

func prem_claimed() -> int:
	return int(_bp().get("prem_claimed", 0))

## Claim every unlocked-but-unclaimed reward on a track. Returns a merged
## {coins, gems, boosters:[ids]} dict of what was granted.
func claim_free() -> Dictionary:
	return _claim("free_claimed", false)

func claim_premium() -> Dictionary:
	if not pass_owned():
		return {}
	return _claim("prem_claimed", true)

func _claim(key: String, premium: bool) -> Dictionary:
	var d := _bp()
	var from := int(d.get(key, 0))
	var to := tier_reached()
	if to <= from:
		return {}
	var total := {"coins": 0, "gems": 0, "boosters": []}
	for t in range(from + 1, to + 1):
		var r := reward(t, premium)
		total["coins"] += int(r.get("coins", 0))
		total["gems"] += int(r.get("gems", 0))
		if r.has("booster"):
			total["boosters"].append(r["booster"])
	d[key] = to
	SaveData.data["bp"] = d
	SaveData.save_now()
	changed.emit()
	return total

## Deterministic reward for a 1-based tier.
static func reward(tier: int, premium: bool) -> Dictionary:
	if premium:
		var r := {"gems": 4 + tier / 5}
		if tier % 3 == 0:
			r["booster"] = _boost(tier)
		if tier == TIERS:
			r["gems"] = 60
		return r
	var f := {"coins": 40 + tier * 6}
	if tier % 5 == 0:
		f["booster"] = _boost(tier)
	return f

static func _boost(tier: int) -> String:
	return Boosters.LIST[tier % Boosters.LIST.size()]
