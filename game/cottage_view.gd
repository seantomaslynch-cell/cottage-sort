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

func _kitchen_shown() -> bool:
	if economy == null:
		return false
	return _t("stove") + _t("table") + _t("dresser") + _t("floor") > 0

func _draw() -> void:
	var w := size.x
	var h := size.y * (0.60 if _kitchen_shown() else 1.0)
	var ground_y := h * 0.84
	var restored := economy.restored_fraction() if economy != null else 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260829   # stable scenery layout

	# sky gradient (greyer when run-down, warm blue as restored)
	var sky_top := Color("aeb7bd").lerp(Color("bcdcf0"), restored)
	var sky_bot := Color("dcd6c8").lerp(Color("f3ead6"), restored)
	var bands := 20
	for b in bands:
		var tt := float(b) / float(bands - 1)
		draw_rect(Rect2(0, h * float(b) / bands, w, h / bands + 1.0), sky_top.lerp(sky_bot, tt))
	Art.paper(self, Rect2(0, 0, w, h), 0.6)

	# sun with a soft glow, warmer as the place comes back to life
	var sun := Vector2(w * 0.80, h * 0.15)
	var sun_col := Color("f4d98a").lerp(Color("ffe6a0"), restored)
	Art.glow(self, sun, 90.0, sun_col)
	draw_circle(sun, 30.0, sun_col)
	Art.cloud(self, w * 0.24, h * 0.13, 1.0, 0.8)
	Art.cloud(self, w * 0.58, h * 0.22, 0.7, 0.7)
	Art.cloud(self, w * 0.9, h * 0.30, 0.55, 0.6)

	# rolling hills behind the house (two layers, greener as restored)
	var hill_far := Color("9fb0a6").lerp(Color("a9c58f"), restored)
	var hill_near := Color("8ea583").lerp(Color("8fb06b"), restored)
	_draw_hill(w, ground_y - 74.0, 120.0, hill_far, 0.35)
	_draw_hill(w, ground_y - 30.0, 90.0, hill_near, 0.75)
	# distant tree line
	for i in 9:
		var tx := w * (0.05 + 0.11 * i) + rng.randf_range(-16, 16)
		Art.tree(self, Vector2(tx, ground_y - 36.0), rng.randf_range(70, 104),
			hill_near.darkened(0.12), rng.randf_range(-0.2, 0.2))

	# ground
	var grass_col := Color("8a8577").lerp(Color("83ac5f"), restored)
	draw_rect(Rect2(0, ground_y, w, h - ground_y), grass_col)
	draw_rect(Rect2(0, ground_y, w, 4.0), Color(0, 0, 0, 0.08))
	Art.grass(self, 0, w, ground_y + 2.0, grass_col.lightened(0.10), rng)

	var house_w := minf(w * 0.60, 400.0)
	var house_h := h * 0.40
	var hx := (w - house_w) * 0.5
	var hy := ground_y - house_h

	# flanking trees (behind the house, palette greens)
	Art.tree(self, Vector2(hx - 24.0, ground_y + 4.0), house_h * 0.86, Color("7fa06a").lerp(Color("6f9a55"), restored), -0.15)
	Art.tree(self, Vector2(hx + house_w + 24.0, ground_y + 4.0), house_h * 0.72, Color("86a774").lerp(Color("79a35e"), restored), 0.15)

	_draw_garden(hx, house_w, ground_y, h)
	# house contact shadow
	Art.ground_shadow(self, Vector2(hx + house_w * 0.5, hy + house_h + 4.0), house_w * 0.52, 10.0, 0.11)
	_draw_walls(hx, hy, house_w, house_h)
	_draw_roof(hx, hy, house_w, h)
	_draw_door(hx, hy, house_w, house_h)
	_draw_window(hx, hy, house_w, house_h)
	# warm light spilling from the window once it's glazed
	if _t("window") >= 1:
		Art.glow(self, Vector2(hx + house_w * 0.56 + house_w * 0.10, hy + house_h * 0.20 + house_w * 0.10),
			70.0 * (0.6 + 0.2 * restored), Color("ffdf9e"))
	_draw_fence(ground_y, w)

	# foreground details
	Art.bush(self, Vector2(w * 0.10, ground_y + 26.0), 26.0, Color("7ea061"))
	Art.bush(self, Vector2(w * 0.92, ground_y + 30.0), 30.0, Color("789a5c"))
	if restored > 0.15:
		var petals := [Color("e8899b"), Color("f2c14e"), Color("cf9ad4"), Color("f0a6b4")]
		for i in 7:
			Art.flower(self, Vector2(w * (0.06 + 0.13 * i) + rng.randf_range(-10, 10), ground_y + rng.randf_range(24, 46)),
				petals[i % petals.size()], rng.randf_range(4.0, 6.0))
	Art.bird(self, Vector2(w * 0.30, h * 0.12), 7.0)
	Art.bird(self, Vector2(w * 0.40, h * 0.09), 5.0)

	_draw_decor(w, ground_y)

	if _kitchen_shown():
		_draw_kitchen(0.0, size.y * 0.62, w, size.y * 0.38)

## A cross-section of the Kitchen along the bottom strip. Each fitting gains
## detail and warmth with its tier so buying them has a visible payoff.
func _draw_kitchen(x: float, y: float, w: float, kh: float) -> void:
	var restored := economy.restored_fraction() if economy != null else 0.0
	var wall := Color("d9c6ac").lerp(Color("ecdcc1"), restored)
	var floor_c := _mix(Color("b6a37f"), Color("cdae82"), _t("floor"), 2)
	draw_rect(Rect2(x, y, w, kh), wall)
	Art.paper(self, Rect2(x, y, w, kh), 0.8)
	var fy := y + kh * 0.60
	draw_rect(Rect2(x, fy, w, kh * 0.40), floor_c)
	draw_line(Vector2(x, fy), Vector2(x + w, fy), floor_c.darkened(0.22), 3.0)
	if _t("floor") >= 2:
		var bx := x + 10.0
		while bx < x + w:
			draw_line(Vector2(bx, fy), Vector2(bx, y + kh), floor_c.darkened(0.12), 1.0)
			bx += 34.0
	# warm ceiling glow once anything's restored in here
	Art.glow(self, Vector2(x + w * 0.5, y + 6.0), w * 0.5, Color("ffe6b0"))

	_kitchen_stove(x + w * 0.14, fy, kh)
	_kitchen_table(x + w * 0.5, fy, kh)
	_kitchen_dresser(x + w * 0.84, y + kh * 0.14, fy, kh)

func _kitchen_stove(cx: float, fy: float, kh: float) -> void:
	var t := _t("stove")
	var bw := 78.0
	var bh := kh * 0.42
	var col := _mix(Color("8b8377"), Color("c7c1b6"), t, 3)
	draw_rect(Rect2(cx - bw * 0.5, fy - bh, bw, bh), col)
	draw_rect(Rect2(cx - bw * 0.5, fy - bh, bw, bh), col.darkened(0.3), false, 2.0)
	# burners on top
	for s in [-1.0, 1.0]:
		draw_circle(Vector2(cx + s * bw * 0.24, fy - bh - 3.0), 9.0, col.darkened(0.25))
	if t == 0:
		draw_line(Vector2(cx - bw * 0.4, fy - bh * 0.3), Vector2(cx + bw * 0.4, fy - bh * 0.7), Color("6a6258"), 3.0)
	if t >= 1:
		draw_rect(Rect2(cx - bw * 0.34, fy - bh * 0.66, bw * 0.68, bh * 0.42), Color("2f2a24"))  # oven window
		if t >= 2:
			draw_arc(Vector2(cx, fy - bh * 0.45), bw * 0.28, PI, TAU, 16, Color("ffb85e"), 3.0)  # a warm glow inside
	if t >= 2:
		draw_rect(Rect2(cx - bw * 0.6, fy - bh - 22.0, bw * 1.2, 10.0), col.lightened(0.1))  # extractor hood
	if t >= 3:
		Art.potted(self, Vector2(cx + bw * 0.5 + 14.0, fy), 0.6, Color("8fae7d"))
		draw_circle(Vector2(cx - bw * 0.3, fy - bh - 30.0), 4.0, Color("c98f6b"))  # a hanging cup

func _kitchen_table(cx: float, fy: float, kh: float) -> void:
	var t := _t("table")
	var tw := 96.0
	var th := 8.0
	var top_y := fy - kh * 0.34
	var col := _mix(Color("9a8768"), Color("caa878"), t, 2)
	draw_rect(Rect2(cx - tw * 0.5, top_y, tw, th), col)
	for s in [-1.0, 1.0]:
		draw_rect(Rect2(cx + s * tw * 0.4 - 3.0, top_y + th, 6.0, fy - top_y - th), col.darkened(0.15))
	if t == 0:
		draw_line(Vector2(cx - tw * 0.4, top_y - 4.0), Vector2(cx + tw * 0.1, top_y - 1.0), Color("6a5c45"), 2.0)  # a crack
	if t >= 1:
		draw_circle(Vector2(cx - tw * 0.2, top_y - 6.0), 6.0, Color("e6b45e"))  # a bowl
		draw_circle(Vector2(cx + tw * 0.16, top_y - 5.0), 5.0, Color("d97a6c"))
	if t >= 2:
		# a little vase of flowers
		draw_rect(Rect2(cx - 4.0, top_y - 20.0, 8.0, 14.0), Color("9fc7e0"))
		for i in 3:
			draw_circle(Vector2(cx - 6.0 + i * 6.0, top_y - 22.0), 3.5, [Color("e8899b"), Color("f2c14e"), Color("cf9ad4")][i])

func _kitchen_dresser(cx: float, top_y: float, fy: float, _kh: float) -> void:
	var t := _t("dresser")
	var dw := 92.0
	var dh := fy - top_y
	var col := _mix(Color("8f8069"), Color("bf9d74"), t, 3)
	draw_rect(Rect2(cx - dw * 0.5, top_y, dw, dh), col)
	draw_rect(Rect2(cx - dw * 0.5, top_y, dw, dh), col.darkened(0.3), false, 2.0)
	for i in 3:
		var sy := top_y + dh * (0.2 + i * 0.28)
		draw_line(Vector2(cx - dw * 0.5, sy), Vector2(cx + dw * 0.5, sy), col.darkened(0.22), 2.0)
		if t >= 1:
			for k in 3:
				var px := cx - dw * 0.34 + k * dw * 0.34
				var pcol: Color = Palette.BEADS[(i + k) % Palette.BEADS.size()]
				if t == 1 and (i + k) % 2 == 1:
					continue
				draw_arc(Vector2(px, sy - 4.0), 6.0, PI, TAU, 10, pcol.darkened(0.05), 3.0)  # plates on edge
	if t >= 2:
		draw_rect(Rect2(cx - dw * 0.5, top_y - 10.0, dw, 10.0), col.lightened(0.12))  # cornice
	if t >= 3:
		Art.potted(self, Vector2(cx, top_y - 12.0), 0.5, Color("8fae7d"))

func _draw_hill(w: float, base_y: float, amp: float, col: Color, phase: float) -> void:
	var pts := PackedVector2Array()
	pts.append(Vector2(0, base_y + amp))
	var steps := 24
	for i in steps + 1:
		var x := w * float(i) / steps
		var y := base_y - sin(float(i) / steps * PI + phase * PI) * amp * 0.5 - amp * 0.2
		pts.append(Vector2(x, y))
	pts.append(Vector2(w, base_y + amp))
	draw_colored_polygon(pts, col)


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
