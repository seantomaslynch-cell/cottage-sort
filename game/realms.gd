extends RefCounted
class_name Realms
## Chapters of the authored run, each reskinning the board (background gradient +
## shelf colour) so the world visibly changes as you progress. Mapped loosely to
## the cottage rooms you're restoring.

const CHAPTERS := [
	{"name": "Pantry",   "from": 0,  "bg_top": Color("f4ead8"), "bg_bot": Color("e7d6b8"),
		"shelf": Color("c79a68"), "shelf_dark": Color("9c7345")},
	{"name": "Garden",   "from": 8,  "bg_top": Color("eef1e0"), "bg_bot": Color("dbe6c8"),
		"shelf": Color("9fae7d"), "shelf_dark": Color("74844f")},
	{"name": "Attic",    "from": 16, "bg_top": Color("efe7dd"), "bg_bot": Color("d9cdbd"),
		"shelf": Color("b0906f"), "shelf_dark": Color("7d6349")},
	{"name": "Bakery",   "from": 24, "bg_top": Color("f6ecdd"), "bg_bot": Color("efd9bf"),
		"shelf": Color("d0a878"), "shelf_dark": Color("a37b4d")},
	{"name": "Workshop", "from": 32, "bg_top": Color("e9e6e0"), "bg_bot": Color("d2cabb"),
		"shelf": Color("9c8f7a"), "shelf_dark": Color("6f6352")},
	{"name": "Beyond",   "from": 40, "bg_top": Color("e6e2ea"), "bg_bot": Color("d0c8d6"),
		"shelf": Color("9a8fa6"), "shelf_dark": Color("6d6480")},
]

static func for_stage(stage: int) -> Dictionary:
	var r: Dictionary = CHAPTERS[0]
	for c in CHAPTERS:
		if stage >= int(c["from"]):
			r = c
	return r

static func index_for(stage: int) -> int:
	var idx := 0
	for i in CHAPTERS.size():
		if stage >= int(CHAPTERS[i]["from"]):
			idx = i
	return idx
