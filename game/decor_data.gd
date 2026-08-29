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
		{"id": "g_bench", "name": "Garden bench",   "cost": 40,  "color": 5, "shape": 0, "flavour": "Weathered, but it holds two."},
		{"id": "g_pots",  "name": "Flower pots",     "cost": 70,  "color": 0, "shape": 1, "flavour": "Gran's terracotta, chipped just right."},
		{"id": "g_arch",  "name": "Rose arch",       "cost": 120, "color": 6, "shape": 2, "flavour": "It'll be a tunnel of pink by June."},
		{"id": "g_pond",  "name": "Little pond",     "cost": 180, "color": 4, "shape": 0, "flavour": "One frog moved in the first night."},
	],
	"Kitchen": [
		{"id": "k_rug",    "name": "Woven rug",      "cost": 50,  "color": 1, "shape": 0, "flavour": "Warm underfoot on cold mornings."},
		{"id": "k_kettle", "name": "Copper kettle",  "cost": 90,  "color": 5, "shape": 2, "flavour": "Whistles a little flat. Charming."},
		{"id": "k_herbs",  "name": "Herb shelf",     "cost": 140, "color": 2, "shape": 1, "flavour": "Thyme, sage, and something unlabelled."},
		{"id": "k_lamp",   "name": "Warm lamp",      "cost": 210, "color": 1, "shape": 2, "flavour": "Turns the whole room honey-coloured."},
	],
	"Cozy Nook": [
		{"id": "n_chair", "name": "Reading chair",   "cost": 80,  "color": 3, "shape": 0, "flavour": "The cushion remembers you."},
		{"id": "n_books", "name": "Book stack",      "cost": 130, "color": 6, "shape": 1, "flavour": "Half of them are bookmarked halfway."},
		{"id": "n_quilt", "name": "Patchwork quilt", "cost": 200, "color": 0, "shape": 0, "flavour": "Every square was a dress once."},
		{"id": "n_cat",   "name": "Sleepy cat",      "cost": 300, "color": 5, "shape": 3, "flavour": "Came with the cottage. Won't be moved."},
	],
}
const SET_BONUS := 150      # coins, first time a set is completed
const ENDLESS_SET := "Sundries"

## Rotating seasonal sets — one is on offer at a time, changing every 28 days.
const SEASONS := [
	{"name": "Spring", "items": [
		{"id": "s0_wreath", "name": "Blossom wreath", "cost": 90,  "color": 6, "shape": 3, "flavour": "The door's wearing petals."},
		{"id": "s0_tulips", "name": "Tulip row",      "cost": 130, "color": 0, "shape": 1, "flavour": "Closed by dusk, open by nine."},
		{"id": "s0_swing",  "name": "Rope swing",     "cost": 190, "color": 5, "shape": 2, "flavour": "The oak branch has held for decades."},
		{"id": "s0_hutch",  "name": "Bunny hutch",    "cost": 260, "color": 2, "shape": 0, "flavour": "Two in. Soon to be more."},
	]},
	{"name": "Summer", "items": [
		{"id": "s1_awning",  "name": "Striped awning", "cost": 90,  "color": 0, "shape": 0, "flavour": "Shade for the afternoon slump."},
		{"id": "s1_pitcher", "name": "Lemonade stand", "cost": 130, "color": 1, "shape": 2, "flavour": "Honesty box on the gatepost."},
		{"id": "s1_sunfl",   "name": "Sunflowers",     "cost": 190, "color": 1, "shape": 1, "flavour": "Taller than the fence now."},
		{"id": "s1_hammock", "name": "Hammock",        "cost": 260, "color": 4, "shape": 0, "flavour": "For books you won't finish."},
	]},
	{"name": "Autumn", "items": [
		{"id": "s2_pumpkins", "name": "Pumpkin pile",  "cost": 90,  "color": 5, "shape": 0, "flavour": "Three for the step, one for the pie."},
		{"id": "s2_lantern",  "name": "Paper lanterns", "cost": 130, "color": 1, "shape": 2, "flavour": "They sway when the door opens."},
		{"id": "s2_wheat",    "name": "Wheat sheaf",    "cost": 190, "color": 1, "shape": 1, "flavour": "Tied with garden twine."},
		{"id": "s2_scare",    "name": "Scarecrow",      "cost": 260, "color": 2, "shape": 2, "flavour": "The crows are unimpressed."},
	]},
	{"name": "Winter", "items": [
		{"id": "s3_lights",  "name": "String lights",  "cost": 90,  "color": 4, "shape": 3, "flavour": "Warm white, never blinking."},
		{"id": "s3_tree",    "name": "Little fir tree", "cost": 130, "color": 2, "shape": 1, "flavour": "In a pot, to plant out later."},
		{"id": "s3_sled",    "name": "Wooden sled",     "cost": 190, "color": 5, "shape": 0, "flavour": "Waxed runners, ready for the hill."},
		{"id": "s3_snowman", "name": "Snow friend",     "cost": 260, "color": 4, "shape": 2, "flavour": "Coal eyes, carrot nose, borrowed scarf."},
	]},
]

static func season_index() -> int:
	return int(Time.get_unix_time_from_system() / 86400.0 / 28.0) % SEASONS.size()

static func current_season() -> Dictionary:
	return SEASONS[season_index()]

## Items for any set name (fixed, seasonal, or unknown -> []).
static func set_items(name: String) -> Array:
	if SETS.has(name):
		return SETS[name]
	for s in SEASONS:
		if s["name"] == name:
			return s["items"]
	return []

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
	for season in SEASONS:
		for it in season["items"]:
			if it["id"] == id:
				var c: Dictionary = (it as Dictionary).duplicate()
				c["set"] = season["name"]
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
		"flavour": "A little more character for the place.",
	}
