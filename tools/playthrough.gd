extends SceneTree
## Scripted playthrough — loads the real game, solves the first N levels with the
## BFS solver, plays the moves with the normal pour animation, and screenshots
## each finished board. Restores save.json afterwards.
##
## Run WITHOUT --headless (needs a real renderer):
##   godot --path . --script res://tools/playthrough.gd -- [levels] [out_prefix]

var _backup := ""
var _had_save := false
var _levels := 5
var _prefix := "res://play"

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0: _levels = int(a[0])
	if a.size() > 1: _prefix = a[1]
	_had_save = FileAccess.file_exists(SaveData.PATH)
	if _had_save:
		_backup = FileAccess.open(SaveData.PATH, FileAccess.READ).get_as_text()
	# start each run from a clean slate so stage/curve are predictable
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveData.PATH))
	change_scene_to_file("res://game/main.tscn")
	_run.call_deferred()

func _run() -> void:
	await create_timer(0.8).timeout
	var main := _find_by_script(get_root(), "res://game/main.gd")
	var board := _find(get_root(), "SortBoard")
	assert(main != null and board != null)

	# keep any auto-opened overlay (daily login) out of the way
	for cls in ["DailyPanel", "CottageScreen", "ShopPanel", "SettingsPanel"]:
		var o := _find(get_root(), cls)
		if o: o.visible = false

	var totals: Array = []
	for stage in _levels:
		main._on_stage_picked(stage)
		await create_timer(0.35).timeout

		var guard := 0
		while not board._is_solved() and guard < 200:
			guard += 1
			var s: Dictionary = SortSolver.solve(board.jars, 20000)
			var mv: Array = s.get("move", [])
			if mv.is_empty():
				push_warning("stage %d: solver stuck after %d moves" % [stage, board.moves])
				break
			_play_move(board, mv[0], mv[1])
			while board._busy:
				await process_frame
			await create_timer(0.06).timeout

		await create_timer(0.5).timeout   # let the win juice settle
		var out := "%s_%02d.png" % [_prefix, stage + 1]
		var img := get_root().get_texture().get_image()
		img.save_png(ProjectSettings.globalize_path(out))
		var solved: bool = board._is_solved()
		totals.append({"lvl": stage + 1, "moves": board.moves, "solved": solved})
		print("  level %d  moves=%d  solved=%s  -> %s" % [stage + 1, board.moves, solved, out])

		if solved:
			main._next()
			await create_timer(0.4).timeout

	print("\nplaythrough summary:")
	for r in totals:
		print("  L%-2d  %2d moves  %s" % [r["lvl"], r["moves"], "OK" if r["solved"] else "STUCK"])

	_restore()
	quit(0)

func _play_move(board: Node, from_idx: int, to_idx: int) -> void:
	board.selected = from_idx
	var n: int = board._apply_move(from_idx, to_idx)
	if n <= 0:
		board.selected = -1
		return
	board._history.append({"from": from_idx, "to": to_idx, "count": n})
	board.moves += 1
	board.moved.emit(board.moves)
	board._sfx("pour")
	board._begin_flight(from_idx, to_idx, n)
	board.selected = -1
	board.changed.emit()

func _restore() -> void:
	if _had_save:
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
