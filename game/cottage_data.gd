extends RefCounted
class_name CottageData
## Structural upgrade slots, grouped into rooms. Each slot has an ordered list of
## tier costs (coins). Owning tier N means the first N costs are paid; tier 0 is
## run-down. SLOTS is the flat view used by the economy.

const ROOMS: Array[Dictionary] = [
	{"name": "Cottage", "slots": [
		{"id": "roof",   "name": "Roof",   "tiers": [40, 90, 160]},
		{"id": "walls",  "name": "Walls",  "tiers": [50, 120, 220]},
		{"id": "window", "name": "Window", "tiers": [30, 75]},
		{"id": "door",   "name": "Door",   "tiers": [35, 85]},
		{"id": "garden", "name": "Garden", "tiers": [45, 100, 190]},
	]},
	{"name": "Kitchen", "slots": [
		{"id": "stove",   "name": "Stove",   "tiers": [70, 150, 260]},
		{"id": "table",   "name": "Table",   "tiers": [60, 130]},
		{"id": "dresser", "name": "Dresser", "tiers": [80, 170, 300]},
		{"id": "floor",   "name": "Floor",   "tiers": [55, 120]},
	]},
]

static var SLOTS: Array = _flatten()

static func _flatten() -> Array:
	var out: Array = []
	for room in ROOMS:
		out.append_array(room["slots"])
	return out

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
