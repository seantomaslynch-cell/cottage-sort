extends RefCounted
class_name LevelGen
## Procedural level generator for the sort loop.
##
## Builds puzzles by starting from the SOLVED state and applying random
## "reverse-legal" pours. Replaying that sequence backwards is always a valid
## solution, so every generated level is guaranteed solvable -- no solver needed.
## Generation is deterministic for a given seed, and cached per session.

const CAP := 4

static var _cache: Dictionary = {}

static func generate(num_colors: int, extra_jars: int, rng_seed: int) -> Dictionary:
	var key := "%d_%d_%d" % [num_colors, extra_jars, rng_seed]
	if _cache.has(key):
		return _cache[key].duplicate(true)

	var result := _build(num_colors, extra_jars, rng_seed)
	_cache[key] = result
	return result.duplicate(true)

static func _build(num_colors: int, extra_jars: int, rng_seed: int) -> Dictionary:
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

	var target := 26 + num_colors * 10
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
		var d := rng.randi_range(0, jar_count - 1)
		if d == s:
			continue
		var dst: Array = jars[d]
		if CAP - dst.size() < cnt:
			continue
		if last == Vector2i(d, s):
			continue # don't immediately undo the previous scramble step
		var col: int = src[-1]
		for _i in cnt:
			src.pop_back()
			dst.append(col)
		last = Vector2i(s, d)
		done += 1

	if _is_goal(jars):
		return _build(num_colors, extra_jars, rng_seed + 1)
	return {"jars": jars}

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
