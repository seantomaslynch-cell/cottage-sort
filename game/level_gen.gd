extends RefCounted
class_name LevelGen
## Procedural level generator for the sort loop.
##
## Builds puzzles by starting from the SOLVED state and applying random pours,
## then VERIFIES the result is solvable (BFS, falling back to randomised greedy
## playouts). Unsolvable candidates are reseeded, and if a seed family keeps
## failing the scramble is eased until one passes — so every level `generate()`
## returns is solvable, and carries a `par` (shortest known solution length).
## Generation is deterministic for a given seed and cached per session.

const CAP := 4

static var _cache: Dictionary = {}

## scramble_mult scales how thoroughly the board is mixed: <1 = closer to solved
## (easier), >1 = more tangled (harder). The stage list uses it to shape the curve.
## Returns {"jars": Array, "par": int, "exact": bool}.
static func generate(num_colors: int, extra_jars: int, rng_seed: int, scramble_mult := 1.0) -> Dictionary:
	var key := "%d_%d_%d_%d" % [num_colors, extra_jars, rng_seed, int(round(scramble_mult * 100))]
	if _cache.has(key):
		return _cache[key].duplicate(true)

	var result := _search(num_colors, extra_jars, rng_seed, scramble_mult)
	_cache[key] = result
	return result.duplicate(true)

# --- generate + verify loop --------------------------------------------------

static func _search(num_colors: int, extra_jars: int, rng_seed: int, scramble_mult: float) -> Dictionary:
	var mult := scramble_mult
	for ease in 6:                       # progressively softer scrambles if stuck
		for attempt in 40:              # reseeds at this scramble strength
			var jars := _build(num_colors, extra_jars, rng_seed + ease * 1000 + attempt, mult)
			var check := _verify(jars)
			if check["ok"]:
				return {"jars": jars, "par": int(check["par"]), "exact": bool(check["exact"])}
		mult = maxf(0.6, mult * 0.85)
	# Extremely unlikely fallback: a light scramble is essentially always solvable.
	var j := _build(num_colors, extra_jars, rng_seed, 0.6)
	var c := _verify(j)
	return {"jars": j, "par": int(c.get("par", num_colors * 4)), "exact": bool(c.get("exact", false))}

static func _verify(jars: Array) -> Dictionary:
	var bfs := SortSolver.solve(jars, 60000)
	if not bfs.is_empty() and bfs.has("par"):
		return {"ok": true, "par": int(bfs["par"]), "exact": true}
	var g := SortSolver.greedy_solve(jars, 500, 300)
	if g >= 0:
		return {"ok": true, "par": g, "exact": false}
	return {"ok": false, "par": -1, "exact": false}

# --- raw scramble ----------------------------------------------------------

static func _build(num_colors: int, extra_jars: int, rng_seed: int, scramble_mult: float) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	var jar_count := num_colors + extra_jars

	var jars: Array = []
	for c in num_colors:
		var j: Array = []
		for _k in CAP:
			j.append(c)
		jars.append(j)
	for _e in extra_jars:
		jars.append([])

	var target := maxi(12, int(round((26 + num_colors * 10) * scramble_mult)))
	var last := Vector2i(-1, -1)
	var done := 0
	var guard := 0
	while done < target and guard < target * 60:
		guard += 1
		var s := rng.randi_range(0, jar_count - 1)
		var src: Array = jars[s]
		if src.is_empty():
			continue
		var run := _top_run(src)
		var cnt := rng.randi_range(1, run)
		# Keep the scramble reversible: never strip a whole run off a jar that
		# still has other colours under it (its reverse pour would be illegal).
		if cnt == run and run < src.size():
			continue
		var d := rng.randi_range(0, jar_count - 1)
		if d == s:
			continue
		var dst: Array = jars[d]
		if CAP - dst.size() < cnt:
			continue
		var col: int = src[-1]
		# Don't stack onto an existing same-colour run — keeps the placed group's
		# size exact so its reverse pulls back exactly what we put down.
		if not dst.is_empty() and dst[-1] == col:
			continue
		if last == Vector2i(d, s):
			continue                       # don't immediately undo the last step
		for _i in cnt:
			src.pop_back()
			dst.append(col)
		last = Vector2i(s, d)
		done += 1

	if _is_goal(jars):
		return _build(num_colors, extra_jars, rng_seed + 1, scramble_mult)
	return jars

static func _top_run(j: Array) -> int:
	if j.is_empty():
		return 0
	var c: int = j[-1]
	var k := 0
	for i in range(j.size() - 1, -1, -1):
		if j[i] == c:
			k += 1
		else:
			break
	return k

static func _is_goal(jars: Array) -> bool:
	for j in jars:
		var a: Array = j
		if a.is_empty():
			continue
		if a.size() != CAP:
			return false
		for v in a:
			if v != a[0]:
				return false
	return true
