extends RefCounted
class_name Realms
## Chapters of the authored run, each reskinning the board (background gradient +
## shelf colour) so the world visibly changes as you progress. Mapped loosely to
## the cottage rooms you're restoring.

## `bead_tint` — every bead is lerped 12% toward this so each chapter's jars
## feel a little different (jammy in the Pantry, fresh in the Garden, …) while
## staying distinguishable.
const CHAPTERS := [
	{"name": "Pantry",   "from": 0,  "bg_top": Color("f4ead8"), "bg_bot": Color("e7d6b8"),
		"shelf": Color("c79a68"), "shelf_dark": Color("9c7345"), "bead_tint": Color("e8c07a"),
		"flavour": "Start where the clutter's thickest — Gran's pantry shelves."},
	{"name": "Garden",   "from": 8,  "bg_top": Color("eef1e0"), "bg_bot": Color("dbe6c8"),
		"shelf": Color("9fae7d"), "shelf_dark": Color("74844f"), "bead_tint": Color("bcd39a"),
		"flavour": "Out back, everything's overgrown. The roses remember, though."},
	{"name": "Attic",    "from": 16, "bg_top": Color("efe7dd"), "bg_bot": Color("d9cdbd"),
		"shelf": Color("b0906f"), "shelf_dark": Color("7d6349"), "bead_tint": Color("c9bda9"),
		"flavour": "Dust, boxes, and everything Gran never threw away."},
	{"name": "Bakery",   "from": 24, "bg_top": Color("f6ecdd"), "bg_bot": Color("efd9bf"),
		"shelf": Color("d0a878"), "shelf_dark": Color("a37b4d"), "bead_tint": Color("f0d0a0"),
		"flavour": "Flour still in the air. Let's get it working again."},
	{"name": "Workshop", "from": 32, "bg_top": Color("e9e6e0"), "bg_bot": Color("d2cabb"),
		"shelf": Color("9c8f7a"), "shelf_dark": Color("6f6352"), "bead_tint": Color("aab0bc"),
		"flavour": "Tools everywhere. There's an order to it, somewhere."},
	{"name": "Orchard",  "from": 40, "bg_top": Color("f3ecda"), "bg_bot": Color("e3e0bf"),
		"shelf": Color("c6a06a"), "shelf_dark": Color("94703f"), "bead_tint": Color("e9c884"),
		"flavour": "Windfalls in the long grass, and a ladder against the tree."},
	{"name": "Cellar",   "from": 56, "bg_top": Color("e4e2df"), "bg_bot": Color("cdcac6"),
		"shelf": Color("8f8778"), "shelf_dark": Color("5f594d"), "bead_tint": Color("b6bcc0"),
		"flavour": "Cool and dark. Jars of preserves you don't remember making."},
	{"name": "Loft",     "from": 72, "bg_top": Color("f4ecd9"), "bg_bot": Color("ecdcbc"),
		"shelf": Color("cda876"), "shelf_dark": Color("9c7a4c"), "bead_tint": Color("f1d59c"),
		"flavour": "A slant of afternoon light, and dust hanging in it."},
	{"name": "Meadow",   "from": 88, "bg_top": Color("ecf1df"), "bg_bot": Color("d6e6c4"),
		"shelf": Color("a3b581"), "shelf_dark": Color("788a54"), "bead_tint": Color("c5dba0"),
		"flavour": "Past the fence, the field just goes on. Bees everywhere."},
	{"name": "Hearth",   "from": 104, "bg_top": Color("f5e8d8"), "bg_bot": Color("efd3bb"),
		"shelf": Color("c78e63"), "shelf_dark": Color("9a5f3f"), "bead_tint": Color("f0c396"),
		"flavour": "The fire's caught at last. Everything glows a little."},
	{"name": "Beyond",   "from": 120, "bg_top": Color("e6e2ea"), "bg_bot": Color("d0c8d6"),
		"shelf": Color("9a8fa6"), "shelf_dark": Color("6d6480"), "bead_tint": Color("c3bcd4"),
		"flavour": "Past the last room, the tidying just… keeps going."},
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
