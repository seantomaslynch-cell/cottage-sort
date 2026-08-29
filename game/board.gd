extends Node2D
class_name SortBoard
## The sort puzzle board: draws jars, handles taps, animates pours, tracks undo
## history, supports adding spare jars, and plays a small win flourish.
##
## `jars` is the authoritative model and is updated the instant a move is made;
## the pour animation is purely cosmetic and briefly locks input while it runs.

signal moved(count: int)
signal solved
signal changed            # selection / history / jar count changed -> refresh HUD

const CAP := 4
const MAX_EXTRA_JARS := 3
const COLORS: Array[Color] = [
	Color("d97a6c"), # berry
	Color("e6b45e"), # honey
	Color("8fae7d"), # sage
	Color("9b7bab"), # plum
	Color("7fa8c9"), # sky
	Color("c98f6b"), # clay
	Color("d99abf"), # rose
	Color("6fb0a6"), # teal
]

const VIEW_W := 720.0
const JAR_W := 104.0
const JAR_H := 268.0
const ITEM_R := 30.0
const GAP_X := 28.0
const ROW_GAP := 56.0
const TOP_Y := 296.0
const POP_TIME := 0.45

var audio: GameAudio = null

var jars: Array = []              # Array of Array[int], bottom -> top
var selected: int = -1
var moves: int = 0

var _rects: Array[Rect2] = []
var _base_jar_count := 0
var _locked := false              # solved
var _busy := false                # a pour animation is playing
var _history: Array = []          # [{from, to, count}]
var _flying: Array = []           # [{color, from, to, t, dur, delay}]
var _recv_jar := -1
var _recv_count := 0
var _pops: PackedFloat32Array = PackedFloat32Array()
var _rings: Array = []            # [{pos, t, dur}]
var _hint_from := -1
var _hint_to := -1
var _hint_time := 0.0

const HINT_TIME := 2.6

func _ready() -> void:
	set_process(true)

func load_level(data: Dictionary) -> void:
	jars = []
	for j in data.get("jars", []):
		jars.append((j as Array).duplicate())
	_base_jar_count = jars.size()
	selected = -1
	moves = 0
	_locked = false
	_busy = false
	_history.clear()
	_flying.clear()
	_rings.clear()
	_recv_jar = -1
	_recv_count = 0
	_pops = PackedFloat32Array()
	_pops.resize(jars.size())
	_clear_hint()
	_layout()
	queue_redraw()
	changed.emit()

func show_hint(mv: Array) -> void:
	if mv.size() != 2:
		return
	_hint_from = mv[0]
	_hint_to = mv[1]
	_hint_time = HINT_TIME
	queue_redraw()

func _clear_hint() -> void:
	_hint_from = -1
	_hint_to = -1
	_hint_time = 0.0

func can_undo() -> bool:
	return _history.size() > 0 and not _busy and not _locked

func can_add_jar() -> bool:
	return not _locked and not _busy and (jars.size() - _base_jar_count) < MAX_EXTRA_JARS

func extra_jar_count() -> int:
	return jars.size() - _base_jar_count

func add_jar() -> bool:
	if not can_add_jar():
		return false
	jars.append([])
	_pops.resize(jars.size())
	_layout()
	queue_redraw()
	changed.emit()
	_sfx("place", 1.1)
	return true

func undo() -> void:
	if not can_undo():
		return
	var h: Dictionary = _history.pop_back()
	var from_idx: int = h["from"]
	var to_idx: int = h["to"]
	var cnt: int = h["count"]
	for _i in cnt:
		(jars[from_idx] as Array).append((jars[to_idx] as Array).pop_back())
	moves = maxi(0, moves - 1)
	moved.emit(moves)
	selected = -1
	_sfx("pour", 0.85)
	_begin_flight(to_idx, from_idx, cnt)
	changed.emit()

func _unhandled_input(event: InputEvent) -> void:
	if not visible or _locked or _busy:
		return
	var pos := Vector2.INF
	if event is InputEventScreenTouch and event.pressed:
		pos = event.position
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pos = event.position
	if pos == Vector2.INF:
		return

	var hit := _jar_at(pos)
	if hit == -1:
		return

	_clear_hint()

	if selected == -1:
		if not (jars[hit] as Array).is_empty():
			selected = hit
			_sfx("tap")
			queue_redraw()
			changed.emit()
	elif hit == selected:
		selected = -1
		queue_redraw()
		changed.emit()
	else:
		var n := _apply_move(selected, hit)
		if n > 0:
			_history.append({"from": selected, "to": hit, "count": n})
			moves += 1
			moved.emit(moves)
			_sfx("pour")
			_begin_flight(selected, hit, n)
			selected = -1
			changed.emit()
		else:
			_sfx("buzz")
			selected = hit if not (jars[hit] as Array).is_empty() else -1
			queue_redraw()
			changed.emit()

func _apply_move(from_idx: int, to_idx: int) -> int:
	var src: Array = jars[from_idx]
	var dst: Array = jars[to_idx]
	if src.is_empty() or dst.size() >= CAP:
		return 0
	if not dst.is_empty() and dst[-1] != src[-1]:
		return 0
	var n := mini(_top_run_len(src), CAP - dst.size())
	for _i in n:
		dst.append(src.pop_back())
	return n

func _begin_flight(from_idx: int, to_idx: int, n: int) -> void:
	_busy = true
	_recv_jar = to_idx
	_recv_count = n
	_flying.clear()
	var src_size := (jars[from_idx] as Array).size()
	var to_size := (jars[to_idx] as Array).size()
	for k in n:
		var col: int = jars[to_idx][to_size - n + k]
		var start := _item_center(_rects[from_idx], src_size + k)
		var endp := _item_center(_rects[to_idx], to_size - n + k)
		_flying.append({"color": col, "from": start, "to": endp, "t": 0.0, "dur": 0.16, "delay": 0.04 * k})
	queue_redraw()

func _process(delta: float) -> void:
	var redraw := false

	if _busy:
		var all_done := true
		for f in _flying:
			if f["delay"] > 0.0:
				f["delay"] = maxf(0.0, f["delay"] - delta)
				all_done = false
				continue
			f["t"] = minf(f["dur"], f["t"] + delta)
			if f["t"] < f["dur"]:
				all_done = false
		redraw = true
		if all_done:
			_busy = false
			_flying.clear()
			_recv_jar = -1
			_recv_count = 0
			_sfx("place")
			_post_move()

	for i in _pops.size():
		if _pops[i] > 0.0:
			_pops[i] = maxf(0.0, _pops[i] - delta)
			redraw = true

	if not _rings.is_empty():
		for r in _rings:
			r["t"] += delta
		_rings = _rings.filter(func(r): return r["t"] < r["dur"])
		redraw = true

	if _hint_time > 0.0:
		_hint_time = maxf(0.0, _hint_time - delta)
		redraw = true

	if redraw:
		queue_redraw()

func _post_move() -> void:
	if _is_solved():
		_locked = true
		_start_win_juice()
		solved.emit()
	changed.emit()

func _start_win_juice() -> void:
	_sfx("win")
	var i := 0
	for jar in jars:
		if not (jar as Array).is_empty():
			if i < _pops.size():
				_pops[i] = POP_TIME
			var r: Rect2 = _rects[i]
			_rings.append({"pos": r.position + r.size * 0.5, "t": -0.05 * i, "dur": 0.6})
		i += 1

# --- geometry -------------------------------------------------------------

func _layout() -> void:
	_rects.clear()
	var n := jars.size()
	var rows := int(ceil(n / 5.0))
	var per_row := int(ceil(float(n) / rows)) if rows > 0 else n
	var y := TOP_Y
	var i := 0
	while i < n:
		var count := mini(per_row, n - i)
		var row_w := count * JAR_W + (count - 1) * GAP_X
		var x := (VIEW_W - row_w) * 0.5
		for k in count:
			_rects.append(Rect2(x, y, JAR_W, JAR_H))
			x += JAR_W + GAP_X
		y += JAR_H + ROW_GAP
		i += per_row

func _item_center(r: Rect2, slot: int) -> Vector2:
	var step := ITEM_R * 2.0 + 3.0
	return Vector2(r.position.x + r.size.x * 0.5, r.position.y + r.size.y - ITEM_R - 8.0 - slot * step)

func _jar_at(p: Vector2) -> int:
	for i in _rects.size():
		if _rects[i].grow(12.0).has_point(p):
			return i
	return -1

func _top_run_len(jar: Array) -> int:
	if jar.is_empty():
		return 0
	var c: int = jar[-1]
	var k := 0
	for s in range(jar.size() - 1, -1, -1):
		if jar[s] == c:
			k += 1
		else:
			break
	return k

func _is_solved() -> bool:
	for jar in jars:
		var arr: Array = jar
		if arr.is_empty():
			continue
		if arr.size() != CAP:
			return false
		for v in arr:
			if v != arr[0]:
				return false
	return true

# --- drawing ------------------------------------------------------------

func _draw() -> void:
	for i in jars.size():
		_draw_jar(i)
	_draw_hint()
	for f in _flying:
		if f["delay"] > 0.0:
			continue
		var e := _ease_out(f["t"] / f["dur"])
		var p: Vector2 = (f["from"] as Vector2).lerp(f["to"], e) + Vector2(0, -36.0 * sin(PI * e))
		_draw_item(p, COLORS[f["color"]], 1.0)
	for r in _rings:
		if r["t"] <= 0.0:
			continue
		var e2: float = r["t"] / r["dur"]
		var rad := lerpf(18.0, 92.0, e2)
		draw_arc(r["pos"], rad, 0.0, TAU, 40, Color(0.95, 0.78, 0.35, (1.0 - e2) * 0.5), 4.0, true)

func _draw_hint() -> void:
	if _hint_time <= 0.0:
		return
	if _hint_from < 0 or _hint_to < 0 or _hint_from >= _rects.size() or _hint_to >= _rects.size():
		return
	var fade := clampf(_hint_time / HINT_TIME, 0.0, 1.0)
	var pulse := 0.45 + 0.55 * (0.5 + 0.5 * sin(Time.get_ticks_msec() / 130.0))
	var a := fade * pulse
	_round_rect(_rects[_hint_from].grow(6.0), Color(0, 0, 0, 0), Color(0.42, 0.66, 0.90, a), 5, 30)
	_round_rect(_rects[_hint_to].grow(6.0), Color(0, 0, 0, 0), Color(0.42, 0.80, 0.48, a), 5, 30)

func _draw_jar(i: int) -> void:
	var r: Rect2 = _rects[i]
	var pv: float = _pops[i] if i < _pops.size() else 0.0
	var sc := 1.0 + 0.14 * _pop_curve(pv)
	var rr := _scaled(r, sc)
	var center := rr.position + rr.size * 0.5

	_round_rect(rr, Color(1, 1, 1, 0.35), Color("b79b74"), 4, 26)

	var jar: Array = jars[i]
	var shown := jar.size()
	if i == _recv_jar:
		shown -= _recv_count
	var lifted := (i == selected and not _busy)
	var run := _top_run_len(jar) if lifted else 0

	for s in jar.size():
		if s >= shown and not (lifted and s >= jar.size() - run):
			continue
		var base := _item_center(r, s)
		if lifted and s >= jar.size() - run:
			base = Vector2(r.position.x + r.size.x * 0.5, r.position.y - 22.0 - (jar.size() - 1 - s) * (ITEM_R * 2.0 + 3.0))
		var p := center + (base - center) * sc
		_draw_item(p, COLORS[jar[s]], sc)

	if lifted:
		_round_rect(rr.grow(4.0), Color(0, 0, 0, 0), Color("f2c14e"), 4, 28)

func _draw_item(p: Vector2, col: Color, sc: float) -> void:
	draw_circle(p, ITEM_R * sc, col)
	draw_arc(p, ITEM_R * sc, 0.0, TAU, 32, col.darkened(0.18), 3.0, true)

func _round_rect(rect: Rect2, fill: Color, border: Color, border_w: int, radius: int) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(radius)
	draw_style_box(sb, rect)

func _scaled(r: Rect2, s: float) -> Rect2:
	var c := r.position + r.size * 0.5
	var ns := r.size * s
	return Rect2(c - ns * 0.5, ns)

func _pop_curve(t_remaining: float) -> float:
	if t_remaining <= 0.0:
		return 0.0
	var p := 1.0 - t_remaining / POP_TIME
	return sin(p * PI) * (1.0 - p) * 2.2

func _ease_out(x: float) -> float:
	return 1.0 - pow(1.0 - clampf(x, 0.0, 1.0), 3.0)

func _sfx(name: String, pitch := 1.0) -> void:
	if audio != null:
		audio.play(name, pitch)
