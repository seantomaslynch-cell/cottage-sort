extends RefCounted
class_name DealData
## One rotating discounted offer a day, deterministic by local date. In the stub
## the "discount" is a bonus on the granted amount (prices are just labels);
## swap for real store price points when the IAP SDK goes in.

const POOL: Array[Dictionary] = [
	{"id": "gems_small",     "bonus": 0.30},
	{"id": "coins_medium",   "bonus": 0.25},
	{"id": "booster_bundle", "bonus": 0.50},
	{"id": "gems_medium",    "bonus": 0.20},
	{"id": "coins_small",    "bonus": 0.40},
]

static func day() -> int:
	var bias: int = Time.get_time_zone_from_system().get("bias", 0)
	return int((Time.get_unix_time_from_system() + bias * 60) / 86400.0)

static func today() -> Dictionary:
	return POOL[day() % POOL.size()]

static func claimed_today() -> bool:
	return int(SaveData.data.get("deal_bought_day", -1)) == day()

static func mark_claimed() -> void:
	SaveData.data["deal_bought_day"] = day()
	SaveData.save_now()
