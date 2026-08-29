extends Control
class_name CottageView
## Placeholder vector drawing of the first room's cottage. Each part gets warmer
## and gains detail as its upgrade tier rises; tier 0 looks run-down.

var economy: Economy = null

func refresh() -> void:
	queue_redraw()

func _t(id: String) -> int:
	return economy.tier(id) if economy != null else 0

func _mix(dull: Color, warm: Color, t: int, maxt: int) -> Color:
	if t <= 0:
		return dull
	return dull.lerp(warm, clampf(float(t) / float(maxt) + 0.18, 0.0, 1.0))

func _draw() -> void:
	var w := size.x
	var h := size.y
	var ground_y := h * 0.84
	var restored := economy.restored_fraction() if economy != null else 0.0

	# sky gradient (greyer when run-down, bluer as restored)
	var sky_top := Color("aeb7bd").lerp(Color("bfe0f2"), restored)
	var sky_bot := Color("d9d2c4").lerp(Color("eaf6fb"), restored)
	var bands := 14
	for b in bands:
		var tt := float(b) / float(bands - 1)
		draw_rect(Rect2(0, h * float(b) / bands, w, h / bands + 1.0), sky_top.lerp(sky_bot, tt))

	# sun, brighter as the place comes back to life
	draw_circle(Vector2(w * 0.82, h * 0.16), 30.0, Color("f4d98a").lerp(Color("ffe9a8"), restored))
	_cloud(w * 0.22, h * 0.14, 1.0)
	_cloud(w * 0.6, h * 0.24, 0.7)

	# ground
	draw_rect(Rect2(0, ground_y, w, h - ground_y), Color("8a8577").lerp(Color("7fa663"), restored))
	draw_rect(Rect2(0, ground_y, w, 4.0), Color(0, 0, 0, 0.08))

	var house_w := minf(w * 0.60, 400.0)
	var house_h := h * 0.40
	var hx := (w - house_w) * 0.5
	var hy := ground_y - house_h

	_draw_garden(hx, house_w, ground_y, h)
	# house drop shadow
	draw_rect(Rect2(hx + 8, hy + 10, house_w, house_h), Color(0, 0, 0, 0.07))
	_draw_walls(hx, hy, house_w, house_h)
	_draw_roof(hx, hy, house_w, h)
	_draw_door(hx, hy, house_w, house_h)
	_draw_window(hx, hy, house_w, house_h)
	_draw_fence(ground_y, w)
	_draw_decor(w, ground_y)

func _draw_decor(w: float, ground_y: float) -> void:
	if economy == null:
		return
	var owned: Array = economy.decor_owned()
	if owned.is_empty():
		return
	var shown := mini(owned.size(), 12)
	var y := ground_y + 44.0
	var step := (w - 60.0) / float(maxi(1, shown))
	for i in shown:
		var it := DecorData.item(str(owned[i]))
		if it.is_empty():
			continue
		var col: Color = Palette.BEADS[int(it.get("color", 0)) % Palette.BEADS.size()]
		var cx := 40.0 + step * (i + 0.5)
		match int(it.get("shape", 0)):
			1:  # plant
				draw_colored_polygon(PackedVector2Array([
					Vector2(cx - 7, y), Vector2(cx + 7, y), Vector2(cx, y - 18)]), col)
				draw_rect(Rect2(cx - 3, y, 6, 6), Color("7a5230"))
			2:  # lamp
				draw_line(Vector2(cx, y), Vector2(cx, y - 16), Color("7a5230"), 3.0)
				draw_circle(Vector2(cx, y - 18), 6.0, col)
			3:  # bunting
				for k in 3:
					draw_circle(Vector2(cx - 8 + k * 8, y - 6), 3.5,
						Palette.BEADS[(int(it.get("color", 0)) + k) % Palette.BEADS.size()])
			_:  # low / rug / bench
				draw_rect(Rect2(cx - 11, y - 8, 22, 10), col)
				draw_rect(Rect2(cx - 11, y - 8, 22, 10), col.darkened(0.25), false, 2.0)

func _cloud(cx: float, cy: float, s: float) -> void:
	var col := Color(1, 1, 1, 0.75)
	draw_circle(Vector2(cx, cy), 20.0 * s, col)
	draw_circle(Vector2(cx + 22.0 * s, cy + 4.0 * s), 16.0 * s, col)
	draw_circle(Vector2(cx - 20.0 * s, cy + 5.0 * s), 14.0 * s, col)

func _draw_fence(ground_y: float, w: float) -> void:
	var t := _t("garden")
	if t < 1:
		return
	var col := Color("cdb891").lerp(Color("f1e6cf"), clampf(float(t) / 3.0, 0.0, 1.0))
	var top := ground_y - 30.0
	draw_line(Vector2(0, top + 10.0), Vector2(w, top + 10.0), col.darkened(0.1), 4.0)
	draw_line(Vector2(0, top + 22.0), Vector2(w, top + 22.0), col.darkened(0.1), 4.0)
	var x := 8.0
	while x < w:
		draw_rect(Rect2(x, top, 8.0, 34.0), col)
		draw_colored_polygon(PackedVector2Array([
			Vector2(x, top), Vector2(x + 8.0, top), Vector2(x + 4.0, top - 8.0)
		]), col)
		x += 30.0

func _draw_walls(hx: float, hy: float, hw: float, hh: float) -> void:
	var t := _t("walls")
	var col := _mix(Color("8a8577"), Color("d8b98a"), t, 3)
	draw_rect(Rect2(hx, hy, hw, hh), col)
	draw_rect(Rect2(hx, hy, hw, hh), col.darkened(0.32), false, 3.0)
	if t >= 2:
		for i in range(1, 5):
			var y := hy + hh * float(i) / 5.0
			draw_line(Vector2(hx, y), Vector2(hx + hw, y), col.darkened(0.16), 2.0)
	if t >= 3:
		draw_rect(Rect2(hx + 6, hy + 6, hw - 12, 10), col.lightened(0.22))

func _draw_roof(hx: float, hy: float, hw: float, h: float) -> void:
	var t := _t("roof")
	var col := _mix(Color("6b6a67"), Color("b5654a"), t, 3)
	var peak := Vector2(hx + hw * 0.5, hy - h * 0.22)
	var left := Vector2(hx - 18, hy)
	var right := Vector2(hx + hw + 18, hy)
	draw_colored_polygon(PackedVector2Array([left, right, peak]), col)
	draw_polyline(PackedVector2Array([left, peak, right, left]), col.darkened(0.32), 3.0)
	if t >= 2:
		draw_line(left.lerp(peak, 0.12), peak, col.darkened(0.15), 2.0)
		draw_line(right.lerp(peak, 0.12), peak, col.darkened(0.15), 2.0)
	if t >= 3:
		draw_line(Vector2(left.x - 6, left.y + 4), Vector2(right.x + 6, right.y + 4), col.darkened(0.24), 4.0)

func _draw_door(hx: float, hy: float, hw: float, hh: float) -> void:
	var t := _t("door")
	var dw := hw * 0.16
	var dh := hh * 0.42
	var dx := hx + hw * 0.30
	var dy := hy + hh - dh
	var col := _mix(Color("5c5750"), Color("9c6b43"), t, 2)
	draw_rect(Rect2(dx, dy, dw, dh), col)
	draw_rect(Rect2(dx, dy, dw, dh), col.darkened(0.35), false, 2.0)
	if t == 0:
		for i in 3:
			var yy := dy + dh * (0.2 + i * 0.3)
			draw_line(Vector2(dx - 4, yy + 8), Vector2(dx + dw + 4, yy - 8), Color("4a4640"), 4.0)
	else:
		draw_rect(Rect2(dx + dw * 0.2, dy + dh * 0.12, dw * 0.6, dh * 0.34), col.darkened(0.15), false, 2.0)
		draw_rect(Rect2(dx + dw * 0.2, dy + dh * 0.54, dw * 0.6, dh * 0.34), col.darkened(0.15), false, 2.0)
	if t >= 2:
		draw_circle(Vector2(dx + dw * 0.8, dy + dh * 0.5), 3.5, Color("f2c14e"))
		draw_arc(Vector2(dx + dw * 0.5, dy), dw * 0.5, PI, TAU, 20, col.darkened(0.2), 3.0)

func _draw_window(hx: float, hy: float, hw: float, hh: float) -> void:
	var t := _t("window")
	var s := hw * 0.20
	var wx := hx + hw * 0.56
	var wy := hy + hh * 0.20
	var frame := Color("5c5750")
	if t == 0:
		draw_rect(Rect2(wx, wy, s, s), Color("55575a"))
		draw_line(Vector2(wx, wy), Vector2(wx + s, wy + s), Color("3f4043"), 3.0)
		draw_line(Vector2(wx + s, wy), Vector2(wx, wy + s), Color("3f4043"), 3.0)
	else:
		draw_rect(Rect2(wx, wy, s, s), Color("9fc7e0"))
		draw_line(Vector2(wx + s * 0.5, wy), Vector2(wx + s * 0.5, wy + s), frame, 2.0)
		draw_line(Vector2(wx, wy + s * 0.5), Vector2(wx + s, wy + s * 0.5), frame, 2.0)
	draw_rect(Rect2(wx, wy, s, s), frame, false, 3.0)
	if t >= 2:
		var bx := wx - 4
		var by := wy + s
		draw_rect(Rect2(bx, by, s + 8, 10), Color("7a5230"))
		var petals := [Color("e8899b"), Color("f2c14e"), Color("cf9ad4")]
		for i in 3:
			draw_circle(Vector2(bx + 10 + i * (s / 3.0), by), 4.0, petals[i])

func _draw_garden(hx: float, hw: float, ground_y: float, h: float) -> void:
	var t := _t("garden")
	var y := ground_y + 12.0
	if t == 0:
		for i in 6:
			draw_circle(Vector2(hx + 20 + i * (hw / 6.0), y + (i % 2) * 8), 3.0, Color("6b5a44"))
		return
	var n := 8 + t * 4
	for i in n:
		var gx := hx - 30 + i * ((hw + 60) / float(n))
		var gy := y + (i % 3) * 5
		draw_colored_polygon(PackedVector2Array([
			Vector2(gx - 5, gy), Vector2(gx + 5, gy), Vector2(gx, gy - 14)
		]), Color("5f9150"))
	if t >= 2:
		var petals := [Color("e8899b"), Color("f2c14e"), Color("cf9ad4"), Color("f2c14e"), Color("e8899b")]
		for i in 5:
			draw_circle(Vector2(hx + 10 + i * (hw / 5.0), y - 6), 4.0, petals[i])
	if t >= 3:
		draw_rect(Rect2(hx + hw * 0.42, y, 26.0, 44.0), Color("b8a887"))
