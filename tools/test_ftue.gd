extends SceneTree
## M33 FTUE check: on a fresh save, Level 1 starts locked to the guided pour,
## every guided move is accepted, the board solves, and ftue_done is set so it
## never runs again. Backs up / restores the real save.json.

var _backup := ""
var _had := false

func _initialize() -> void:
	_had = FileAccess.file_exists(SaveData.PATH)
	if _had:
		_backup = FileAccess.open(SaveData.PATH, FileAccess.READ).get_as_text()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveData.PATH))
	change_scene_to_file("res://game/main.tscn")
	_run.call_deferred()

func _run() -> void:
	await create_timer(0.6).timeout
	var fails := 0
	var main := _find_by_script(get_root(), "res://game/main.gd")
	var board := _find(get_root(), "SortBoard")
	if main == null or board == null:
		_fail("main/board not found"); return

	if not board.tutorial_lock:
		fails += 1; push_error("FTUE: board not locked on L1")
	if board.tutorial_move.size() != 2:
		fails += 1; push_error("FTUE: no tutorial_move set")
	if not main._ftue_active:
		fails += 1; push_error("FTUE: _ftue_active false on L1")

	# a tap on a jar that ISN'T the guided source must be ignored
	var wrong := -1
	for i in board.jars.size():
		if i != int(board.tutorial_move[0]) and not (board.jars[i] as Array).is_empty():
			wrong = i; break
	if wrong != -1:
		board._unhandled_input(_tap(board, wrong))
		if board.selected != -1:
			fails += 1; push_error("FTUE: a non-guided jar was selectable")

	# play the guided moves
	var guard := 0
	while not board._is_solved() and guard < 30:
		guard += 1
		var mv: Array = board.tutorial_move
		if mv.size() != 2:
			fails += 1; push_error("FTUE: tutorial_move cleared mid-tutorial"); break
		var n: int = board._apply_move(int(mv[0]), int(mv[1]))
		if n <= 0:
			fails += 1; push_error("FTUE: guided move %s was illegal" % str(mv)); break
		board._history.append({"from": mv[0], "to": mv[1], "count": n})
		board.moves += 1
		board.moved.emit(board.moves)
		board._begin_flight(int(mv[0]), int(mv[1]), n)
		while board._busy:
			await process_frame
		await create_timer(0.03).timeout

	if not board._is_solved():
		fails += 1; push_error("FTUE: board never solved")
	await create_timer(0.3).timeout
	if main._ftue_active:
		fails += 1; push_error("FTUE: still active after solve")
	if board.tutorial_lock:
		fails += 1; push_error("FTUE: board still locked after solve")
	if not bool(SaveData.data.get("ftue_done", false)):
		fails += 1; push_error("FTUE: ftue_done not saved")

	_restore()
	if fails == 0:
		print("\nALL PASS  (FTUE: locked -> guided -> solved -> ftue_done)")
		quit(0)
	else:
		print("\n%d FAILURE(S)" % fails)
		quit(1)

func _tap(board: Node, jar: int) -> InputEventScreenTouch:
	var e := InputEventScreenTouch.new()
	e.pressed = true
	e.position = board.jar_center(jar) + Vector2(0, 40)
	return e

func _fail(msg: String) -> void:
	push_error(msg); _restore(); quit(1)

func _restore() -> void:
	if _had:
		FileAccess.open(SaveData.PATH, FileAccess.WRITE).store_string(_backup)
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveData.PATH))

func _find(n: Node, cls: String) -> Node:
	var s: Script = n.get_script()
	if s != null and String(s.get_global_name()) == cls:
		return n
	for c in n.get_children():
		var r := _find(c, cls)
		if r: return r
	return null

func _find_by_script(n: Node, path: String) -> Node:
	var s: Script = n.get_script()
	if s != null and s.resource_path == path:
		return n
	for c in n.get_children():
		var r := _find_by_script(c, path)
		if r: return r
	return null
