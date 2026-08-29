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
var _start := 0
var _budget := 200000
var _prefix := "res://play"

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0: _levels = int(a[0])
	if a.size() > 1: _start = int(a[1])
	if a.size() > 2: _budget = int(a[2])
	if a.size() > 3: _prefix = a[3]
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
	if main.has_method("_enter_game"):
		main._enter_game()          # dismiss the Home screen
		await create_timer(0.2).timeout

	# keep any auto-opened overlay (daily login) out of the way
	for cls in ["DailyPanel", "CottageScreen", "ShopPanel", "SettingsPanel"]:
		var o := _find(get_root(), cls)
		if o: o.visible = false

	var totals: Array = []
	for i in _levels:
		var stage: int = _start + i
		main._on_stage_picked(stage)
		await create_timer(0.35).timeout

		var budget: int = board.move_budget
		var path: Array = SortSolver.solve_full(board.jars, _budget)
		var par: int = path.size()

		var stuck := false
		for mv in path:
			if board._is_solved():
				break
			_play_move(board, mv[0], mv[1])
			while board._busy:
				await process_frame
			await create_timer(0.05).timeout
			if board._is_failed():
				stuck = true
				break
		if par == 0:
			stuck = true

		await create_timer(0.5).timeout   # let the win juice / fail panel settle
		var out := "%s_%02d.png" % [_prefix, stage + 1]
		get_root().get_texture().get_image().save_png(ProjectSettings.globalize_path(out))
		var solved: bool = board._is_solved()
		var bstr := ("%d" % budget) if budget < board.UNLIMITED else "-"
		totals.append({"lvl": stage + 1, "moves": board.moves, "par": par,
			"budget": bstr, "solved": solved, "stuck": stuck})
		print("  L%d  played=%d  par=%d  budget=%s  solved=%s%s  -> %s"
			% [stage + 1, board.moves, par, bstr, solved,
			("  <<< STUCK" if stuck and not solved else ""), out])

		if solved:
			main._next()
			await create_timer(0.4).timeout

	print("\nplaythrough summary  (played / par / budget):")
	for r in totals:
		print("  L%-3d %2d / %2d / %-4s  %s"
			% [r["lvl"], r["moves"], r["par"], r["budget"],
			"OK" if r["solved"] else "STUCK"])

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
