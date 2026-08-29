extends RefCounted
class_name Boosters
## The six in-level boosters. Bought-and-used instantly for gems from the
## Boosters popup (no inventory yet — bundles can come later).

const LIST := ["moves8", "undos3", "jar1", "hints3", "magnet", "headstart"]

const NAME := {
	"moves8": "+8 moves",
	"undos3": "+3 undos",
	"jar1": "+1 spare jar",
	"hints3": "+3 hints",
	"magnet": "Colour magnet",
	"headstart": "Head start",
}

const DESC := {
	"moves8": "More room to breathe",
	"undos3": "Three take-backs this level",
	"jar1": "An extra spare jar",
	"hints3": "Three more nudges",
	"magnet": "Gather one colour into a jar",
	"headstart": "Auto-play the best 3 moves",
}

const COST := {   # gems
	"moves8": 3,
	"undos3": 2,
	"jar1": 2,
	"hints3": 2,
	"magnet": 4,
	"headstart": 5,
}
