extends RefCounted
class_name SaveData
## Flat JSON save at user://save.json. Tracks per-stage best move count and
## settings. All static -- there's only ever one save.

const PATH := "user://save.json"

static var data: Dictionary = {
	"completed": {},   # str(stage_index) -> best move count
	"muted": false,    # legacy; migrated to sfx_on on load
	"sfx_on": true,
	"music_on": true,
	"haptics_on": true,
	"coins": 0,
	"gems": 0,         # premium currency (earned slowly, bought via IAP)
	"piggy": 0,        # gems accrued in the piggy bank; cracked by one IAP
	"starter_seen_at": 0,      # unix time of first launch (starter-pack window)
	"starter_bought": false,
	"starter_shown_once": false,
	"struggle_bought_day": -1, # day the struggle pack was last bought (once/day cap)
	"boosters": {},    # booster id -> owned count
	"bp": {},          # battle pass: season_id, xp, owned, free_claimed, prem_claimed
	"upgrades": {},    # cottage slot id -> owned tier (0 = none)
	"decor": [],       # owned decor ids (incl. "sundry_N")
	"decor_sets_done": [],  # authored decor sets already bonused
	"stars": {},       # str(stage_index) -> best star count (1..3)
	"remove_ads": false,
	"intro_seen": false,   # set true after the first session; gates the daily auto-open
	"last_stage": 0,           # resume here on next launch
	"ftue_done": false,        # L1 guided tutorial completed
	"ftue_budget_seen": false, # shown the "moves are limited now" heads-up
	"ftue_stars_seen": false,  # shown the star-rating explainer
	"story_seen": false,       # shown the one-paragraph intro
	"cat_gift_day": -1,        # last day the cottage cat left a gift
	"achievements": {},        # id -> true once earned
	"stat_deepest": 0,         # furthest stage index reached
	"stat_flawless": 0,        # 3-star clears with no undo/hint
	"stat_best_combo": 0,      # highest combo multiplier landed
	"stat_week_chests": 0,     # weekly chests claimed (lifetime)
	"stat_jackpot_wins": 0,    # daily jackpots won
	"stat_days_played": 0,     # distinct days the game was opened
	"stat_last_played_day": 0,
	"stat_coins_earned": 0,    # lifetime coins earned
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
	data["sfx_on"] = not m
	save_now()

static func set_flag(key: String, v: bool) -> void:
	data[key] = v
	save_now()

## Fold the legacy `muted` key into sfx_on for saves made before settings existed.
static func migrate_audio_flags() -> void:
	if bool(data.get("muted", false)) and bool(data.get("sfx_on", true)):
		data["sfx_on"] = false
