extends RefCounted
class_name CottageData
## The first room: a fixed list of upgrade slots. Each slot has an ordered list
## of tier costs (in coins). Owning tier N means the first N costs have been
## paid. Tier 0 = untouched / run-down.

const SLOTS: Array[Dictionary] = [
	{"id": "roof",   "name": "Roof",   "tiers": [40, 90, 160]},
	{"id": "walls",  "name": "Walls",  "tiers": [50, 120, 220]},
	{"id": "window", "name": "Window", "tiers": [30, 75]},
	{"id": "door",   "name": "Door",   "tiers": [35, 85]},
	{"id": "garden", "name": "Garden", "tiers": [45, 100, 190]},
]

static func slot(id: String) -> Dictionary:
	for s in SLOTS:
		if s["id"] == id:
			return s
	return {}

static func max_tier(id: String) -> int:
	return (slot(id).get("tiers", []) as Array).size()

## Cost to go from `current_tier` to the next one, or -1 if already maxed.
static func cost(id: String, current_tier: int) -> int:
	var tiers: Array = slot(id).get("tiers", [])
	if current_tier < 0 or current_tier >= tiers.size():
		return -1
	return int(tiers[current_tier])

static func total_tiers() -> int:
	var n := 0
	for s in SLOTS:
		n += (s["tiers"] as Array).size()
	return n
