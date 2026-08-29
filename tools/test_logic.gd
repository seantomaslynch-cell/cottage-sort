extends SceneTree
## Headless sanity check for the sort logic + generator.
## Run: godot --headless --path . --script res://tools/test_logic.gd

const Levels := preload("res://game/levels.gd")
const Board := preload("res://game/board.gd")
const CAP := 4

func _initialize() -> void:
	var fails := 0
	for stage in Levels.count():
		var data: Dictionary = Levels.build(stage)
		var jars: Array = data["jars"]
		var cfg: Dictionary = Levels.STAGES[stage]
		var hand: bool = Levels.HAND_LEVELS.has(stage)

		# generated stages must match their difficulty knob; hand levels are free-form
		if not hand and jars.size() != cfg["colors"] + cfg["extra"]:
			push_error("stage %d: jar count %d != %d" % [stage, jars.size(), cfg["colors"] + cfg["extra"]])
			fails += 1

		# every colour present appears exactly CAP times, contiguous from 0
		var counts := {}
		for j in jars:
			for v in j:
				counts[v] = int(counts.get(v, 0)) + 1
		for c in counts:
			if int(counts[c]) != CAP:
				push_error("stage %d: colour %d count %d != %d" % [stage, c, int(counts[c]), CAP])
				fails += 1
		for c in counts.size():
			if not counts.has(c):
				push_error("stage %d: colour indices not contiguous from 0" % stage)
				fails += 1

		# not already solved
		var b = Board.new()
		b.jars = _deep(jars)
		if b._is_solved():
			push_error("stage %d: generated already solved" % stage)
			fails += 1

		# independently confirm solvable
		if not _solvable(jars):
			push_error("stage %d: NOT solvable" % stage)
			fails += 1

		b.free()
		print("stage %d  jars=%d colours=%d extra=%d  OK" % [stage, jars.size(), cfg["colors"], cfg["extra"]])

	# solver smoke test: it should find a plan for a fresh board on a few stages
	for stage in [0, 8, 15, 23]:
		if stage >= Levels.count():
			continue
		var jj := _deep(Levels.build(stage)["jars"])
		var sol: Dictionary = SortSolver.solve(jj, 80000)
		if sol.is_empty() or int(sol.get("par", 0)) <= 0 or (sol["move"] as Array).size() != 2:
			push_error("stage %d: solver returned no usable plan" % stage)
			fails += 1
		else:
			print("stage %d  solver par=%d  first move %s" % [stage, int(sol["par"]), str(sol["move"])])

	# a couple of explicit move-logic checks
	var mb = Board.new()
	mb.jars = [[0, 0, 1], [1, 1], []]
	var n1 = mb._apply_move(1, 2)          # pour the two 1s onto empty
	assert(n1 == 2 and mb.jars[2] == [1, 1] and mb.jars[1] == [])
	var n2 = mb._apply_move(0, 1)          # top of jar0 is 1, jar1 empty -> pours one 1
	assert(n2 == 1 and mb.jars[0] == [0, 0])
	var n3 = mb._apply_move(2, 0)          # top of jar0 is 0, jar2 top is 1 -> illegal
	assert(n3 == 0)
	mb.free()
	print("move-logic checks OK")

	# fail-state / move-budget checks
	var fb = Board.new()
	fb.jars = [[0, 1], [1, 0], []]
	fb.move_budget = Board.UNLIMITED
	assert(not fb._is_failed())                 # unlimited -> never fails
	fb.move_budget = 2
	fb.moves = 1
	assert(not fb._is_failed())                 # under budget
	fb.moves = 2
	fb._history = [{"from": 0, "to": 2, "count": 1}]
	assert(fb._is_failed())                     # at budget -> failed
	fb.add_moves(5)
	assert(fb.move_budget == 7 and not fb._is_failed())  # refill clears it
	assert(fb.moves_left() == 5)
	fb.free()
	print("fail-state checks OK")

	# move budget curve: tutorial unlimited, later stages finite and sane
	assert(Levels.move_budget(0) >= 999 and Levels.move_budget(4) >= 999)
	assert(Levels.move_budget(5) < 999 and Levels.move_budget(23) < 999)
	print("move-budget curve OK  (L6=%d, L24=%d)" % [Levels.move_budget(5), Levels.move_budget(23)])

	if fails == 0:
		print("\nALL PASS")
		quit(0)
	else:
		print("\n%d FAILURE(S)" % fails)
		quit(1)

func _deep(a: Array) -> Array:
	var out := []
	for j in a:
		out.append((j as Array).duplicate())
	return out

func _key(jars: Array) -> String:
	var parts := []
	for j in jars:
		parts.append(",".join((j as Array).map(func(x): return str(x))) if not (j as Array).is_empty() else "-")
	parts.sort()
	return "|".join(parts)

func _goal(jars: Array) -> bool:
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

func _run_len(j: Array) -> int:
	if j.is_empty():
		return 0
	var c = j[-1]
	var k := 0
	for i in range(j.size() - 1, -1, -1):
		if j[i] == c:
			k += 1
		else:
			break
	return k

func _solvable(start: Array) -> bool:
	var stack := [_deep(start)]
	var seen := {}
	seen[_key(start)] = true
	var budget := 300000
	while not stack.is_empty() and budget > 0:
		budget -= 1
		var cur: Array = stack.pop_back()
		if _goal(cur):
			return true
		for i in cur.size():
			var src: Array = cur[i]
			if src.is_empty():
				continue
			var run := _run_len(src)
			# pointless: a full single-colour jar
			if run == src.size() and run == CAP:
				continue
			for jdx in cur.size():
				if jdx == i:
					continue
				var dst: Array = cur[jdx]
				if dst.size() >= CAP:
					continue
				if not dst.is_empty() and dst[-1] != src[-1]:
					continue
				if dst.is_empty() and run == src.size():
					continue # moving a whole jar to empty gains nothing
				var nxt := _deep(cur)
				var mv := mini(run, CAP - dst.size())
				for _m in mv:
					nxt[jdx].append(nxt[i].pop_back())
				var k := _key(nxt)
				if not seen.has(k):
					seen[k] = true
					stack.append(nxt)
	return false
