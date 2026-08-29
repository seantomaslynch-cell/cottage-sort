extends RefCounted
class_name SortSolver
## Breadth-first solver for the sort board. Used for the hint button (first move
## of a shortest solution from the current state) and, in tests, to sanity-check
## generated levels. Falls back to a cheap heuristic if BFS blows its budget.

const CAP := 4

static func hint(jars: Array) -> Array:
	var s := solve(jars, 30000)
	if s.has("move") and not (s["move"] as Array).is_empty():
		return s["move"]
	return _heuristic(jars)

## {"move": [from, to], "par": int} for a shortest solution, or {} if not found
## within `budget` explored states.
static func solve(start: Array, budget := 30000) -> Dictionary:
	if _goal(start):
		return {"move": [], "par": 0}
	var start_key := _key(start)
	var q: Array = [_dup(start)]
	var qkeys: Array = [start_key]
	var parent := {start_key: null}
	var head := 0
	while head < q.size():
		if parent.size() > budget:
			return {}
		var cur: Array = q[head]
		var cur_key: String = qkeys[head]
		head += 1
		for mv in _moves(cur):
			var nxt := _apply(cur, mv)
			var k := _key(nxt)
			if parent.has(k):
				continue
			parent[k] = {"prev": cur_key, "mv": mv}
			if _goal(nxt):
				return _reconstruct(parent, k)
			q.append(nxt)
			qkeys.append(k)
	return {}

static func _reconstruct(parent: Dictionary, goal_key: String) -> Dictionary:
	var moves: Array = []
	var k: Variant = goal_key
	while parent.get(k) != null:
		var step: Dictionary = parent[k]
		moves.push_front(step["mv"])
		k = step["prev"]
	return {"move": moves[0] if not moves.is_empty() else [], "par": moves.size(), "path": moves}

## Full shortest move list [[from, to], ...] for a solution, or [] if none found
## within `budget`. Used by tools/playthrough.gd.
static func solve_full(start: Array, budget := 120000) -> Array:
	var s := solve(start, budget)
	return s.get("path", [])

static func _moves(jars: Array) -> Array:
	var out: Array = []
	var n := jars.size()
	for i in n:
		var src: Array = jars[i]
		if src.is_empty():
			continue
		var run := _run_len(src)
		if run == src.size() and run == CAP:
			continue
		for j in n:
			if j == i:
				continue
			var dst: Array = jars[j]
			if dst.size() >= CAP:
				continue
			if not dst.is_empty() and dst[-1] != src[-1]:
				continue
			if dst.is_empty() and run == src.size():
				continue
			out.append([i, j])
	return out

static func _apply(jars: Array, mv: Array) -> Array:
	var out := _dup(jars)
	var src: Array = out[mv[0]]
	var dst: Array = out[mv[1]]
	var n := mini(_run_len(src), CAP - dst.size())
	for _i in n:
		dst.append(src.pop_back())
	return out

static func _dup(jars: Array) -> Array:
	var out: Array = []
	for j in jars:
		out.append((j as Array).duplicate())
	return out

static func _run_len(j: Array) -> int:
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

static func _goal(jars: Array) -> bool:
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

static func _key(jars: Array) -> String:
	var parts: Array = []
	for j in jars:
		var a: Array = j
		parts.append(",".join(a.map(func(x): return str(x))) if not a.is_empty() else "-")
	parts.sort()
	return "|".join(parts)

static func _heuristic(jars: Array) -> Array:
	var legal := _moves(jars)
	for mv in legal:
		var after := _apply(jars, mv)
		var d: Array = after[mv[1]]
		if d.size() == CAP and _run_len(d) == CAP:
			return mv
	for mv in legal:
		if (_apply(jars, mv)[mv[0]] as Array).is_empty():
			return mv
	for mv in legal:
		if not (jars[mv[1]] as Array).is_empty():
			return mv
	return legal[0] if not legal.is_empty() else []
