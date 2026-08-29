extends RefCounted
## Stage list. Each stage is just a difficulty knob; the actual jar layout is
## generated (deterministically, solvable) by LevelGen. "extra" is the number of
## spare empty jars -- fewer spares = harder.

const STAGES: Array[Dictionary] = [
	{"colors": 3, "extra": 2},
	{"colors": 3, "extra": 2},
	{"colors": 4, "extra": 2},
	{"colors": 4, "extra": 2},
	{"colors": 5, "extra": 2},
	{"colors": 5, "extra": 2},
	{"colors": 6, "extra": 2},
	{"colors": 6, "extra": 2},
	{"colors": 7, "extra": 2},
	{"colors": 7, "extra": 2},
	{"colors": 8, "extra": 2},
	{"colors": 8, "extra": 2},
]

static func count() -> int:
	return STAGES.size()

static func build(stage_index: int) -> Dictionary:
	var s: Dictionary = STAGES[clampi(stage_index, 0, STAGES.size() - 1)]
	return LevelGen.generate(s["colors"], s["extra"], 4100 + stage_index * 17)
