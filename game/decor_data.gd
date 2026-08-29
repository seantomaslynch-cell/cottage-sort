extends RefCounted
class_name DecorData
## Decorative items for the Cottage. Three authored sets with a completion
## bonus, then an endless "Sundries" set whose next item always costs more —
## so coins never run out of a sink.
##
## shape hint (drawn in cottage_view): 0 low/rug, 1 plant, 2 lamp, 3 bunting.
## color = index into Palette.BEADS.

const SETS := {
	"Garden": [
		{"id": "g_bench", "name": "Garden bench",   "cost": 40,  "color": 5, "shape": 0},
		{"id": "g_pots",  "name": "Flower pots",     "cost": 70,  "color": 0, "shape": 1},
		{"id": "g_arch",  "name": "Rose arch",       "cost": 120, "color": 6, "shape": 2},
		{"id": "g_pond",  "name": "Little pond",     "cost": 180, "color": 4, "shape": 0},
	],
	"Kitchen": [
		{"id": "k_rug",    "name": "Woven rug",      "cost": 50,  "color": 1, "shape": 0},
		{"id": "k_kettle", "name": "Copper kettle",  "cost": 90,  "color": 5, "shape": 2},
		{"id": "k_herbs",  "name": "Herb shelf",     "cost": 140, "color": 2, "shape": 1},
		{"id": "k_lamp",   "name": "Warm lamp",      "cost": 210, "color": 1, "shape": 2},
	],
	"Cozy Nook": [
		{"id": "n_chair", "name": "Reading chair",   "cost": 80,  "color": 3, "shape": 0},
		{"id": "n_books", "name": "Book stack",      "cost": 130, "color": 6, "shape": 1},
		{"id": "n_quilt", "name": "Patchwork quilt", "cost": 200, "color": 0, "shape": 0},
		{"id": "n_cat",   "name": "Sleepy cat",      "cost": 300, "color": 5, "shape": 3},
	],
}
const SET_BONUS := 150      # coins, first time a set is completed
const ENDLESS_SET := "Sundries"

const _ENDLESS_NAMES := [
	"Wind chime", "Lantern", "Garden gnome", "Bird feeder", "Bunting",
	"Stepping stone", "Sun catcher", "Wind spinner", "Toadstool", "Fairy lights",
]

static func set_names() -> Array:
	return SETS.keys()

static func item(id: String) -> Dictionary:
	for s in SETS:
		for it in SETS[s]:
			if it["id"] == id:
				var c: Dictionary = (it as Dictionary).duplicate()
				c["set"] = s
				return c
	if id.begins_with("sundry_"):
		return endless_item(int(id.trim_prefix("sundry_")))
	return {}

## The n-th endless item. Cost climbs quadratically so it always outpaces income.
static func endless_item(n: int) -> Dictionary:
	var base: String = _ENDLESS_NAMES[n % _ENDLESS_NAMES.size()]
	var suffix := "" if n < _ENDLESS_NAMES.size() else " %d" % (n / _ENDLESS_NAMES.size() + 1)
	return {
		"id": "sundry_%d" % n,
		"name": base + suffix,
		"cost": 120 + n * 40 + n * n * 20,
		"color": n % 8,
		"shape": n % 4,
		"set": ENDLESS_SET,
	}
