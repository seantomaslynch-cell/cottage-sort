extends RefCounted
class_name SaveData
## Flat JSON save at user://save.json. Tracks per-stage best move count and
## settings. All static -- there's only ever one save.

const PATH := "user://save.json"

static var data: Dictionary = {
	"completed": {},   # str(stage_index) -> best move count
	"muted": false,
	"coins": 0,
	"upgrades": {},    # cottage slot id -> owned tier (0 = none)
	"stars": {},       # str(stage_index) -> best star count (1..3)
	"daily": {
		"streak_len": 0,
		"last_login_day": 0,
		"last_spin_day": 0,
		"ad_streak": 0,
		"ad_last_day": 0,
	},
}

static func load_now() -> void:
	if not FileAccess.file_exists(PATH):
		return
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		for k in parsed:
			data[k] = parsed[k]

static func save_now() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(data))

static func mark_complete(stage: int, moves: int) -> void:
	var key := str(stage)
	var prev: int = int(data["completed"].get(key, 1 << 30))
	if moves < prev:
		data["completed"][key] = moves
	save_now()

static func is_complete(stage: int) -> bool:
	return data["completed"].has(str(stage))

static func best_moves(stage: int) -> int:
	return int(data["completed"].get(str(stage), 0))

static func stars(stage: int) -> int:
	return int(data["stars"].get(str(stage), 0))

static func set_stars(stage: int, s: int) -> void:
	var key := str(stage)
	if s > int(data["stars"].get(key, 0)):
		data["stars"][key] = s
	save_now()

static func total_stars() -> int:
	var n := 0
	for k in data["stars"]:
		n += int(data["stars"][k])
	return n

static func set_muted(m: bool) -> void:
	data["muted"] = m
	save_now()
