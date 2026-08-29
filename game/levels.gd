extends RefCounted
## Stage list. Each stage is just a difficulty knob; the actual jar layout is
## generated (deterministically, solvable) by LevelGen. "extra" is the number of
## spare empty jars -- fewer spares = harder.

const STAGES: Array[Dictionary] = [
	{"colors": 3, "extra": 3},
	{"colors": 3, "extra": 2},
	{"colors": 4, "extra": 3},
	{"colors": 4, "extra": 2},
	{"colors": 4, "extra": 2},
	{"colors": 5, "extra": 3},
	{"colors": 5, "extra": 2},
	{"colors": 5, "extra": 2},
	{"colors": 6, "extra": 3},
	{"colors": 6, "extra": 2},
	{"colors": 6, "extra": 2},
	{"colors": 6, "extra": 2},
	{"colors": 7, "extra": 3},
	{"colors": 7, "extra": 2},
	{"colors": 7, "extra": 2},
	{"colors": 7, "extra": 2},
	{"colors": 8, "extra": 3},
	{"colors": 8, "extra": 2},
	{"colors": 8, "extra": 2},
	{"colors": 8, "extra": 2},
	{"colors": 8, "extra": 2},
	{"colors": 8, "extra": 2},
	{"colors": 8, "extra": 2},
	{"colors": 8, "extra": 2},
]

static func count() -> int:
	return STAGES.size()

static func build(stage_index: int) -> Dictionary:
	var s: Dictionary = STAGES[clampi(stage_index, 0, STAGES.size() - 1)]
	return LevelGen.generate(s["colors"], s["extra"], 4100 + stage_index * 17)

## [three_star_max, two_star_max] move counts for a stage.
static func star_cutoffs(stage_index: int) -> Array:
	var s: Dictionary = STAGES[clampi(stage_index, 0, STAGES.size() - 1)]
	var c: int = s["colors"]
	return [c * 2 + 6, c * 4 + 14]

static func stars_for(stage_index: int, moves: int) -> int:
	var cut := star_cutoffs(stage_index)
	if moves <= int(cut[0]):
		return 3
	if moves <= int(cut[1]):
		return 2
	return 1
