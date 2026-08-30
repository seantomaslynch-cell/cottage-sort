extends RefCounted
## The authored difficulty curve.
##
## Stages 0-3 are hand-built teaching levels (HAND_LEVELS). Stages 4-39 are
## generated but hand-shaped via per-stage knobs:
##   colors  - number of colours (3-9)
##   extra   - spare empty jars (more = easier)
##   scr     - scramble multiplier (<1 easier / >1 more tangled), default 1.0
##   bm      - move-budget multiplier over the colour-based default, default 1.0
##   flow    - true = no fail state, lenient stars (the habit-forming window)
##
## Shape: teaching (1-4) -> fail-free flow (5-10) -> first challenge (~12) ->
## designed spike (~20) -> relief (21-25) -> rising (26-32) -> hard tail (33-40),
## then five 16-level acts (L41-120) that each open with relief + a deep-run
## flow breather, build, hit a two-level peak, and wind down — each act a touch
## harder than the last. Past stage 120 endless mode ramps scramble within a
## colour tier, then steps the colour count up (capped at the palette).

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

	# --- Act 3: Orchard  (L41-56) ----------------------
	{"colors": 6, "extra": 3, "scr": 0.95, "bm": 1.3},
	{"colors": 7, "extra": 3, "scr": 1.0, "bm": 1.25},
	{"colors": 7, "extra": 2, "scr": 1.05, "bm": 1.2},
	{"colors": 5, "extra": 3, "scr": 0.7, "flow": true},
	{"colors": 7, "extra": 3, "scr": 1.05, "bm": 1.1},
	{"colors": 7, "extra": 2, "scr": 1.1, "bm": 1.05},
	{"colors": 8, "extra": 3, "scr": 1.1, "bm": 1.0},
	{"colors": 8, "extra": 2, "scr": 1.15, "bm": 0.98},
	{"colors": 7, "extra": 2, "scr": 1.2, "bm": 0.95},
	{"colors": 8, "extra": 3, "scr": 1.2, "bm": 0.95},
	{"colors": 8, "extra": 2, "scr": 1.25, "bm": 0.92},
	{"colors": 8, "extra": 2, "scr": 1.4, "bm": 0.82},
	{"colors": 8, "extra": 2, "scr": 1.48, "bm": 0.78},
	{"colors": 7, "extra": 3, "scr": 1.15, "bm": 1.0},
	{"colors": 8, "extra": 3, "scr": 1.2, "bm": 0.98},
	{"colors": 7, "extra": 2, "scr": 1.1, "bm": 1.05},
	# --- Act 4: Cellar  (L57-72) ----------------------
	{"colors": 6, "extra": 3, "scr": 0.98, "bm": 1.28},
	{"colors": 7, "extra": 3, "scr": 1.03, "bm": 1.23},
	{"colors": 7, "extra": 2, "scr": 1.08, "bm": 1.18},
	{"colors": 5, "extra": 3, "scr": 0.73, "flow": true},
	{"colors": 7, "extra": 3, "scr": 1.08, "bm": 1.08},
	{"colors": 7, "extra": 2, "scr": 1.13, "bm": 1.03},
	{"colors": 8, "extra": 3, "scr": 1.13, "bm": 0.98},
	{"colors": 8, "extra": 2, "scr": 1.18, "bm": 0.96},
	{"colors": 7, "extra": 2, "scr": 1.23, "bm": 0.93},
	{"colors": 8, "extra": 3, "scr": 1.23, "bm": 0.93},
	{"colors": 8, "extra": 2, "scr": 1.28, "bm": 0.9},
	{"colors": 8, "extra": 2, "scr": 1.43, "bm": 0.8},
	{"colors": 8, "extra": 2, "scr": 1.51, "bm": 0.76},
	{"colors": 7, "extra": 3, "scr": 1.18, "bm": 0.98},
	{"colors": 8, "extra": 3, "scr": 1.23, "bm": 0.96},
	{"colors": 7, "extra": 2, "scr": 1.13, "bm": 1.03},
	# --- Act 5: Loft  (L73-88) ----------------------
	{"colors": 6, "extra": 3, "scr": 1.01, "bm": 1.26},
	{"colors": 7, "extra": 3, "scr": 1.06, "bm": 1.21},
	{"colors": 7, "extra": 2, "scr": 1.11, "bm": 1.16},
	{"colors": 5, "extra": 3, "scr": 0.76, "flow": true},
	{"colors": 7, "extra": 3, "scr": 1.11, "bm": 1.06},
	{"colors": 7, "extra": 2, "scr": 1.16, "bm": 1.01},
	{"colors": 8, "extra": 3, "scr": 1.16, "bm": 0.96},
	{"colors": 8, "extra": 2, "scr": 1.21, "bm": 0.94},
	{"colors": 7, "extra": 2, "scr": 1.26, "bm": 0.91},
	{"colors": 8, "extra": 3, "scr": 1.26, "bm": 0.91},
	{"colors": 8, "extra": 2, "scr": 1.31, "bm": 0.88},
	{"colors": 8, "extra": 2, "scr": 1.46, "bm": 0.78},
	{"colors": 8, "extra": 2, "scr": 1.54, "bm": 0.74},
	{"colors": 7, "extra": 3, "scr": 1.21, "bm": 0.96},
	{"colors": 8, "extra": 3, "scr": 1.26, "bm": 0.94},
	{"colors": 7, "extra": 2, "scr": 1.16, "bm": 1.01},
	# --- Act 6: Meadow  (L89-104) ----------------------
	{"colors": 6, "extra": 3, "scr": 1.04, "bm": 1.24},
	{"colors": 7, "extra": 3, "scr": 1.09, "bm": 1.19},
	{"colors": 7, "extra": 2, "scr": 1.14, "bm": 1.14},
	{"colors": 5, "extra": 3, "scr": 0.79, "flow": true},
	{"colors": 7, "extra": 3, "scr": 1.14, "bm": 1.04},
	{"colors": 7, "extra": 2, "scr": 1.19, "bm": 0.99},
	{"colors": 8, "extra": 3, "scr": 1.19, "bm": 0.94},
	{"colors": 8, "extra": 2, "scr": 1.24, "bm": 0.92},
	{"colors": 7, "extra": 2, "scr": 1.29, "bm": 0.89},
	{"colors": 8, "extra": 3, "scr": 1.29, "bm": 0.89},
	{"colors": 8, "extra": 2, "scr": 1.34, "bm": 0.86},
	{"colors": 8, "extra": 2, "scr": 1.49, "bm": 0.76},
	{"colors": 8, "extra": 2, "scr": 1.57, "bm": 0.72},
	{"colors": 7, "extra": 3, "scr": 1.24, "bm": 0.94},
	{"colors": 8, "extra": 3, "scr": 1.29, "bm": 0.92},
	{"colors": 7, "extra": 2, "scr": 1.19, "bm": 0.99},
	# --- Act 7: Hearth  (L105-120) ----------------------
	{"colors": 6, "extra": 3, "scr": 1.07, "bm": 1.22},
	{"colors": 7, "extra": 3, "scr": 1.12, "bm": 1.17},
	{"colors": 7, "extra": 2, "scr": 1.17, "bm": 1.12},
	{"colors": 5, "extra": 3, "scr": 0.82, "flow": true},
	{"colors": 7, "extra": 3, "scr": 1.17, "bm": 1.02},
	{"colors": 7, "extra": 2, "scr": 1.22, "bm": 0.97},
	{"colors": 8, "extra": 3, "scr": 1.22, "bm": 0.92},
	{"colors": 8, "extra": 2, "scr": 1.27, "bm": 0.9},
	{"colors": 7, "extra": 2, "scr": 1.32, "bm": 0.87},
	{"colors": 8, "extra": 3, "scr": 1.32, "bm": 0.87},
	{"colors": 8, "extra": 2, "scr": 1.37, "bm": 0.84},
	{"colors": 8, "extra": 2, "scr": 1.52, "bm": 0.74},
	{"colors": 8, "extra": 2, "scr": 1.6, "bm": 0.7},
	{"colors": 7, "extra": 3, "scr": 1.27, "bm": 0.92},
	{"colors": 8, "extra": 3, "scr": 1.32, "bm": 0.9},
	{"colors": 7, "extra": 2, "scr": 1.22, "bm": 0.97},
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

## "Tidy pour" variant (AUDIT_CONTENT §3b): these stages get one sealed keepsake
## jar — a lidded jar holding a complete stack of KEEPSAKE_COLOR that stays
## untouchable until every other jar is sorted, then its lid pops off. It is
## already a finished stack, so it adds a cosy reveal beat, not difficulty.
## One mid-act build level in each of the four L41-120 acts.
const KEEPSAKE_COLOR := 8
const LIDDED_STAGES := [46, 62, 78, 94]

static func has_lid(stage_index: int) -> bool:
	return stage_index in LIDDED_STAGES

## Endless mode: levels per colour tier before the colour count steps up.
const ENDLESS_TIER_LEN := 12

static func count() -> int:
	return STAGES.size()

static func _knobs(stage_index: int) -> Dictionary:
	return STAGES[clampi(stage_index, 0, STAGES.size() - 1)]

## Difficulty knobs for ANY stage, including endless mode past the authored run.
static func _shape(stage_index: int) -> Dictionary:
	if stage_index < STAGES.size():
		return _knobs(stage_index)
	var over := stage_index - STAGES.size()
	var tier := over / ENDLESS_TIER_LEN
	var colors: int = mini(8 + tier, Palette.BEADS.size())
	var within := over - tier * ENDLESS_TIER_LEN
	var scr := 1.35 + float(within) / float(ENDLESS_TIER_LEN) * 0.45
	return {"colors": colors, "extra": 2, "scr": scr, "bm": 0.8}

static func build(stage_index: int) -> Dictionary:
	# Authored run: frozen + pre-verified in game/level_data.gd (regenerate with
	# tools/bake_levels.gd). No runtime solver stall, puzzles stable across builds.
	if stage_index >= 0 and stage_index < LevelData.STAGES.size():
		var d := (LevelData.STAGES[stage_index] as Dictionary).duplicate(true)
		if has_lid(stage_index):
			# Append a sealed keepsake jar. It's a finished stack of an otherwise
			# unused colour, so the solver / par / budget are unchanged (BFS
			# never moves a full uniform jar), and the win check still passes.
			var js: Array = d["jars"]
			js.append([KEEPSAKE_COLOR, KEEPSAKE_COLOR, KEEPSAKE_COLOR, KEEPSAKE_COLOR])
			d["lock"] = [js.size() - 1]
		return d
	# Endless: colour tier + rising scramble. LevelGen verifies each board.
	var sh := _shape(stage_index)
	return LevelGen.generate(int(sh["colors"]), int(sh["extra"]),
		9000 + stage_index * 17, float(sh["scr"]))

## Shortest known solution length for a stage (0 for hand levels / if unknown).
## LevelGen verifies every generated board and reports this.
static func par_for(stage_index: int) -> int:
	return int(build(stage_index).get("par", 0))

static func move_budget(stage_index: int) -> int:
	if stage_index < FLOW_STAGES:
		return 999
	var s := _shape(stage_index)
	if bool(s.get("flow", false)):
		return 999
	var base := int(s["colors"]) * 4 + 10
	var formula := int(round(base * float(s.get("bm", 1.0))))
	# Never ship a budget below what the level actually needs: give the solver's
	# shortest path (BFS) or greedy estimate ~18% headroom.
	var par := par_for(stage_index)
	if par > 0:
		return maxi(formula, int(ceil(par * 1.18)))
	return formula

## [three_star_max, two_star_max] move counts. Flow / generous stages get very
## lenient 3-star targets; tight stages get harsh ones.
static func star_cutoffs(stage_index: int) -> Array:
	var s := _shape(stage_index)
	var c: int = s["colors"]
	var m := float(s.get("bm", 1.3 if bool(s.get("flow", false)) else 1.0))
	var three := int(round((c * 2 + 6) * m))
	var two := int(round((c * 4 + 14) * m))
	# When BFS gave an exact par, anchor the cutoffs to it so a tight budget
	# can't make 3 stars impossible.
	var lvl := build(stage_index)
	if bool(lvl.get("exact", false)) and int(lvl.get("par", 0)) > 0:
		var par: int = lvl["par"]
		three = maxi(three, int(ceil(par * 1.08)))
		two = maxi(two, int(ceil(par * 1.5)))
	return [three, two]

static func stars_for(stage_index: int, moves: int) -> int:
	var cut := star_cutoffs(stage_index)
	if moves <= int(cut[0]):
		return 3
	if moves <= int(cut[1]):
		return 2
	return 1
