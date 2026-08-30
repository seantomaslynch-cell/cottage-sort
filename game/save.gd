extends RefCounted
class_name SaveData
## Flat JSON save at user://save.json. Tracks per-stage best move count and
## settings. All static -- there's only ever one save.

const PATH := "user://save.json"

## Bump when a save-format change needs a migration step in `_migrate()`.
const CURRENT_SAVE_VERSION := 1

static var data: Dictionary = {
	"save_version": CURRENT_SAVE_VERSION,
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
	"lid_tip_seen": false,     # shown the "sealed keepsake jar" note
	"rush_tip_seen": false,    # shown the "colour rush" note
	"story_seen": false,       # shown the one-paragraph intro
	"cat_gift_day": -1,        # last day the cottage cat left a gift
	"ft_upgrade": false,       # first cottage upgrade bought
	"ft_decor": false,         # first decor bought
	"endless_milestone": 0,    # highest endless milestone level already rewarded
	"first_gem_buy": false,    # first gem pack -> doubled
	"deal_bought_day": -1,     # last day the rotating daily deal was taken
	"stipend_day": -1,         # last day the ad-free gem stipend was paid
	"piggy_cracked_once": false,  # unlocks the bigger piggy bank
	"season_bundle_id": -1,    # last season number whose decor bundle was bought
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
		# The on-disk version, read before the merge — the in-memory default
		# already holds CURRENT_SAVE_VERSION, so a save without the key would
		# otherwise look up to date.
		var from := int((parsed as Dictionary).get("save_version", 0))
		for k in parsed:
			data[k] = parsed[k]
		_migrate(from)

## Bring an older on-disk save up to CURRENT_SAVE_VERSION. Runs once, right
## after load. Each step must be idempotent (safe to re-run). `from` is the
## version the file was written at; 0 = pre-versioning.
static func _migrate(from: int) -> void:
	if from >= CURRENT_SAVE_VERSION:
		data["save_version"] = CURRENT_SAVE_VERSION
		return
	if from < 1:
		migrate_audio_flags()   # legacy `muted` -> `sfx_on`
	# future: if from < 2: ...
	data["save_version"] = CURRENT_SAVE_VERSION
	save_now()

static var _coalescing := false   # a same-frame flush is already scheduled
static var _dirty := false         # writes were suppressed since the last flush

## Persist the save. The first call in a frame writes immediately (so state is
## durable right away); any further calls in the same frame are collapsed into a
## single trailing write at end-of-frame. This keeps bursty callers — a 10-tier
## battle-pass claim, an achievement cascade — from doing ~30 file writes in one
## frame, which matters on mobile.
static func save_now() -> void:
	if _coalescing:
		_dirty = true
		return
	_write()
	var loop := Engine.get_main_loop()
	if loop is SceneTree:
		_coalescing = true
		(loop as SceneTree).process_frame.connect(_end_frame_flush, CONNECT_ONE_SHOT)

static func _end_frame_flush() -> void:
	_coalescing = false
	if _dirty:
		_write()
		_dirty = false

## Force any coalesced write to disk right now (call on quit / app-pause).
static func flush() -> void:
	if _dirty:
		_write()
		_dirty = false

static func _write() -> void:
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

## v0 -> v1 migration step (also safe to call directly). Folds the legacy
## `muted` key into `sfx_on` for saves made before the settings screen existed.
static func migrate_audio_flags() -> void:
	if bool(data.get("muted", false)) and bool(data.get("sfx_on", true)):
		data["sfx_on"] = false
