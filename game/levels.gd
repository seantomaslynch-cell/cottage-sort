extends RefCounted
## The authored difficulty curve.
##
## Stages 0-3 are hand-built teaching levels (HAND_LEVELS). Stages 4-39 are
## generated but hand-shaped via per-stage knobs:
##   colors  - number of colours (3-8)
##   extra   - spare empty jars (more = easier)
##   scr     - scramble multiplier (<1 easier / >1 more tangled), default 1.0
##   bm      - move-budget multiplier over the colour-based default, default 1.0
##   flow    - true = no fail state, lenient stars (the habit-forming window)
##
## Shape: teaching (1-4) -> fail-free flow (5-10) -> first challenge (~12) ->
## designed spike (~20) -> relief (21-25) -> rising (26-32) -> hard tail (33-40).
## Past stage 40 the generator runs endlessly with slowly rising scramble.

const STAGES: Array[Dictionary] = [
	# Teaching (authored layouts) --------------------------------------------
	{"colors": 3, "extra": 3, "flow": true},
	{"colors": 3, "extra": 2, "flow": true},
	{"colors": 4, "extra": 3, "flow": true},
	{"colors": 4, "extra": 3, "flow": true},
	# Flow -- fail-free, habit-forming -------------------------------------
	{"colors": 3, "extra": 3, "scr": 0.6, "flow": true},
	{"colors": 3, "extra": 3, "scr": 0.7, "flow": true},
	{"colors": 4, "extra": 3, "scr": 0.7, "flow": true},
	{"colors": 4, "extra": 3, "scr": 0.8, "flow": true},
	{"colors": 4, "extra": 2, "scr": 0.8, "flow": true},
	{"colors": 5, "extra": 3, "scr": 0.8, "flow": true},
	# Warming up -- fail state on, budgets generous ----------------------
	{"colors": 4, "extra": 2, "scr": 0.9, "bm": 1.3},
	{"colors": 5, "extra": 3, "scr": 0.9, "bm": 1.3},
	{"colors": 5, "extra": 2, "scr": 1.0, "bm": 1.2},   # first real challenge
	{"colors": 5, "extra": 2, "scr": 1.0, "bm": 1.2},
	{"colors": 6, "extra": 3, "scr": 1.0, "bm": 1.15},
	{"colors": 6, "extra": 2, "scr": 1.1, "bm": 1.1},
	# First peak -- the designed spike -----------------------------------
	{"colors": 6, "extra": 2, "scr": 1.2, "bm": 0.95},
	{"colors": 6, "extra": 2, "scr": 1.25, "bm": 0.9},
	{"colors": 7, "extra": 3, "scr": 1.2, "bm": 0.9},
	{"colors": 7, "extra": 2, "scr": 1.3, "bm": 0.85},  # spike (~L20)
	{"colors": 7, "extra": 2, "scr": 1.35, "bm": 0.8},
	# Relief -- ease off so it isn't relentless -------------------------
	{"colors": 6, "extra": 3, "scr": 0.9, "bm": 1.3},
	{"colors": 6, "extra": 3, "scr": 1.0, "bm": 1.2},
	{"colors": 7, "extra": 3, "scr": 1.0, "bm": 1.15},
	{"colors": 6, "extra": 2, "scr": 1.1, "bm": 1.1},
	{"colors": 7, "extra": 3, "scr": 1.05, "bm": 1.1},
	# Rising ------------------------------------------------------------
	{"colors": 7, "extra": 2, "scr": 1.1, "bm": 1.0},
	{"colors": 7, "extra": 2, "scr": 1.15, "bm": 0.95},
	{"colors": 8, "extra": 3, "scr": 1.1, "bm": 1.0},
	{"colors": 7, "extra": 2, "scr": 1.25, "bm": 0.9},
	{"colors": 8, "extra": 3, "scr": 1.2, "bm": 0.95},
	{"colors": 8, "extra": 2, "scr": 1.15, "bm": 0.9},
	{"colors": 8, "extra": 3, "scr": 1.25, "bm": 0.9},
	# Hard tail -------------------------------------------------------
	{"colors": 8, "extra": 2, "scr": 1.3, "bm": 0.85},
	{"colors": 8, "extra": 2, "scr": 1.35, "bm": 0.82},
	{"colors": 8, "extra": 3, "scr": 1.4, "bm": 0.85},
	{"colors": 8, "extra": 2, "scr": 1.4, "bm": 0.8},
	{"colors": 8, "extra": 2, "scr": 1.45, "bm": 0.78},
	{"colors": 8, "extra": 3, "scr": 1.5, "bm": 0.8},
	{"colors": 8, "extra": 2, "scr": 1.5, "bm": 0.75},
]

## Hand-authored teaching levels. Each colour appears exactly CAP (4) times.
const HAND_LEVELS: Dictionary = {
	0: {"jars": [[0, 0, 0, 1], [1, 1, 1, 0], []]},
	1: {"jars": [[0, 1, 2, 0], [1, 2, 0, 1], [2, 0, 1, 2], [], []]},
	2: {"jars": [[0, 1, 2, 3], [1, 2, 3, 0], [2, 3, 0, 1], [3, 0, 1, 2], [], []]},
	3: {"jars": [[0, 1, 2, 3], [1, 2, 3, 0], [2, 0, 3, 1], [3, 1, 0, 2], [], [], []]},
}

## Stages 0..FLOW_STAGES-1 never fail (teaching + flow window).
const FLOW_STAGES := 10

static func count() -> int:
	return STAGES.size()

static func _knobs(stage_index: int) -> Dictionary:
	return STAGES[clampi(stage_index, 0, STAGES.size() - 1)]

static func build(stage_index: int) -> Dictionary:
	if HAND_LEVELS.has(stage_index):
		return (HAND_LEVELS[stage_index] as Dictionary).duplicate(true)
	if stage_index < STAGES.size():
		var s := _knobs(stage_index)
		return LevelGen.generate(s["colors"], s["extra"],
			4100 + stage_index * 17, float(s.get("scr", 1.0)))
	# Endless mode past the authored run: 8 colours, 2 spares, scramble creeps up.
	var over := stage_index - STAGES.size()
	var scr := 1.4 + minf(over, 24) * 0.02
	return LevelGen.generate(8, 2, 9000 + stage_index * 17, scr)

static func move_budget(stage_index: int) -> int:
	if stage_index < FLOW_STAGES:
		return 999
	var s := _knobs(stage_index)
	if bool(s.get("flow", false)):
		return 999
	var base := int(s["colors"]) * 4 + 10
	return int(round(base * float(s.get("bm", 1.0))))

## [three_star_max, two_star_max] move counts. Flow / generous stages get very
## lenient 3-star targets; tight stages get harsh ones.
static func star_cutoffs(stage_index: int) -> Array:
	var s := _knobs(stage_index)
	var c: int = s["colors"]
	var m := float(s.get("bm", 1.3 if bool(s.get("flow", false)) else 1.0))
	return [int(round((c * 2 + 6) * m)), int(round((c * 4 + 14) * m))]

static func stars_for(stage_index: int, moves: int) -> int:
	var cut := star_cutoffs(stage_index)
	if moves <= int(cut[0]):
		return 3
	if moves <= int(cut[1]):
		return 2
	return 1
