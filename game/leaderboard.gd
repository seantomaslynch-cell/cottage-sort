extends RefCounted
class_name Leaderboard
## Weekly "stars earned" board. No backend: the other players are deterministic
## bots that grow through the week, with the real player spliced in by their
## actual weekly star total. Swap board() for a real service later.

const NAMES := [
	"Marnie", "Pip", "Bramble", "Willa", "Otis", "Fen", "Clover", "Hazel",
	"Rue", "Bo", "Juniper", "Wren", "Tansy", "Mabel", "Cricket", "Poppy",
	"Sorrel", "Dill", "Nettle", "Fig", "Maple", "Birch", "Ash", "Linden",
]

## Rows [{name, stars, you}] sorted by stars descending. day_of_week is 1..7.
static func board(player_stars: int, week_id: int, day_of_week: int) -> Array:
	var rows: Array = []
	for i in NAMES.size():
		var rng := RandomNumberGenerator.new()
		rng.seed = week_id * 100003 + i * 17
		var rate := rng.randf_range(1.5, 7.5)
		var wobble := rng.randf_range(0.85, 1.15)
		rows.append({
			"name": NAMES[i],
			"stars": maxi(0, int(round(rate * day_of_week * wobble))),
			"you": false,
		})
	rows.append({"name": "You", "stars": player_stars, "you": true})
	rows.sort_custom(func(a, b): return int(a["stars"]) > int(b["stars"]))
	return rows

static func your_rank(rows: Array) -> int:
	for i in rows.size():
		if rows[i]["you"]:
			return i + 1
	return rows.size()

## All-time "furthest level" board. Bot depths are fixed per name (they don't
## move day to day); the real player is spliced in by `player_depth`.
## Rows [{name, depth, you}] sorted by depth descending.
static func depth_board(player_depth: int) -> Array:
	var rows: Array = []
	for i in NAMES.size():
		var rng := RandomNumberGenerator.new()
		rng.seed = i * 2654435761 + 99
		# skew low: most players never leave the authored run
		var d := int(round(pow(rng.randf(), 1.8) * 130.0)) + 6
		rows.append({"name": NAMES[i], "depth": d, "you": false})
	rows.append({"name": "You", "depth": maxi(1, player_depth), "you": true})
	rows.sort_custom(func(a, b): return int(a["depth"]) > int(b["depth"]))
	return rows
