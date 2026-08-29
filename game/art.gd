extends RefCounted
class_name Art
## Shared procedural art helpers — palette-locked so every screen stays coherent
## and any retheme is still one file (Palette). Everything draws into a passed
## CanvasItem `ci`; nothing here holds state except a cached grain texture.

# ------------------------------------------------------------------ paper grain
static var _grain: ImageTexture = null

static func grain() -> ImageTexture:
	if _grain != null:
		return _grain
	var n := FastNoiseLite.new()
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX
	n.frequency = 0.10
	n.seed = 7
	var s := 128
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	for y in s:
		for x in s:
			var v := n.get_noise_2d(float(x), float(y)) * 0.5 + 0.5   # 0..1
			var a := (v - 0.5) * 0.06 + 0.03                          # very faint
			img.set_pixel(x, y, Color(0.0, 0.0, 0.0, clampf(a, 0.0, 0.08)))
	_grain = ImageTexture.create_from_image(img)
	return _grain

## Tile the faint grain over `rect` to kill flat-gradient banding.
static func paper(ci: CanvasItem, rect: Rect2, strength := 1.0) -> void:
	var t := grain()
	var ts := t.get_size()
	var mod := Color(1, 1, 1, strength)
	var y := rect.position.y
	while y < rect.end.y:
		var x := rect.position.x
		while x < rect.end.x:
			ci.draw_texture_rect(t, Rect2(x, y, ts.x, ts.y), false, mod)
			x += ts.x
		y += ts.y

## Soft stacked drop shadow under a small rounded shape (blob-sized).
static func soft_shadow(ci: CanvasItem, center: Vector2, rx: float, _ry: float, alpha := 0.12) -> void:
	for i in 4:
		var k := float(i)
		ci.draw_circle(center + Vector2(0, k * 1.6), rx + k * 3.0,
			Color(0, 0, 0, alpha * (1.0 - k / 4.0)))

## Wide flat contact shadow on the ground under a building / large object.
static func ground_shadow(ci: CanvasItem, center: Vector2, half_w: float, half_h := 12.0, alpha := 0.12) -> void:
	ci.draw_set_transform(center, 0.0, Vector2(half_w, half_h))
	for i in 3:
		var k := float(i)
		ci.draw_circle(Vector2(0, k * 0.10), 1.0 - k * 0.22, Color(0, 0, 0, alpha * (1.0 - k / 3.0)))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

# ------------------------------------------------------------------------ plants
## Leafy tree: trunk + three stacked canopy blobs with a sun-side highlight.
static func tree(ci: CanvasItem, base: Vector2, h: float, green: Color, lean := 0.0) -> void:
	var trunk_w := h * 0.09
	var top := base + Vector2(lean * h * 0.12, -h * 0.62)
	ci.draw_line(base, top, Color("7a5230"), trunk_w, true)
	ci.draw_line(base, top, Color("8a5f3a"), trunk_w * 0.5, true)
	var blobs := [
		{"c": top + Vector2(0, -h * 0.06), "r": h * 0.30},
		{"c": top + Vector2(-h * 0.16, h * 0.04), "r": h * 0.24},
		{"c": top + Vector2(h * 0.16, h * 0.05), "r": h * 0.24},
	]
	for b in blobs:
		soft_shadow(ci, b["c"] + Vector2(0, b["r"] * 0.5), b["r"], b["r"], 0.06)
	for b in blobs:
		ci.draw_circle(b["c"], b["r"], green.darkened(0.10))
	for b in blobs:
		ci.draw_circle(b["c"] - Vector2(b["r"] * 0.28, b["r"] * 0.30), b["r"] * 0.62, green)
		ci.draw_circle(b["c"] - Vector2(b["r"] * 0.42, b["r"] * 0.44), b["r"] * 0.30, green.lightened(0.16))

static func bush(ci: CanvasItem, center: Vector2, r: float, green: Color) -> void:
	for o in [Vector2(-r * 0.7, 0), Vector2(r * 0.7, 0), Vector2(0, -r * 0.35)]:
		ci.draw_circle(center + o, r * 0.72, green.darkened(0.08))
	ci.draw_circle(center + Vector2(-r * 0.2, -r * 0.3), r * 0.5, green.lightened(0.12))

## Little clump of grass blades along a baseline.
static func grass(ci: CanvasItem, x0: float, x1: float, y: float, green: Color, rng: RandomNumberGenerator) -> void:
	var x := x0
	while x < x1:
		var hh := rng.randf_range(6.0, 16.0)
		var sway := rng.randf_range(-4.0, 4.0)
		ci.draw_line(Vector2(x, y), Vector2(x + sway, y - hh), green.darkened(0.05), 2.0, true)
		x += rng.randf_range(5.0, 11.0)

static func flower(ci: CanvasItem, pos: Vector2, petal: Color, s := 5.0) -> void:
	ci.draw_line(pos, pos + Vector2(0, s * 2.2), Color("6f9150"), 2.0, true)
	for a in range(5):
		var ang := TAU * float(a) / 5.0
		ci.draw_circle(pos + Vector2(cos(ang), sin(ang)) * s * 0.9, s * 0.6, petal)
	ci.draw_circle(pos, s * 0.55, Palette.ACCENT)

static func cloud(ci: CanvasItem, cx: float, cy: float, s: float, a := 0.85) -> void:
	var col := Color(1, 1, 1, a)
	ci.draw_circle(Vector2(cx, cy), 22.0 * s, col)
	ci.draw_circle(Vector2(cx + 24.0 * s, cy + 5.0 * s), 17.0 * s, col)
	ci.draw_circle(Vector2(cx - 22.0 * s, cy + 6.0 * s), 15.0 * s, col)
	ci.draw_circle(Vector2(cx + 2.0 * s, cy + 10.0 * s), 20.0 * s, col)

static func bird(ci: CanvasItem, pos: Vector2, s: float, col := Color("5b4636")) -> void:
	ci.draw_line(pos + Vector2(-s, 0), pos, col, 2.0, true)
	ci.draw_line(pos, pos + Vector2(s, -s * 0.4), col, 2.0, true)
	ci.draw_line(pos + Vector2(s, -s * 0.4), pos + Vector2(s * 2.0, 0), col, 2.0, true)

## Warm radial-ish glow (stacked translucent discs) — sun, lamplight, window.
static func glow(ci: CanvasItem, center: Vector2, r: float, col: Color) -> void:
	for i in 5:
		var k := float(i) / 5.0
		ci.draw_circle(center, r * (0.4 + k * 0.9), Color(col.r, col.g, col.b, 0.12 * (1.0 - k)))

# ------------------------------------------------------------------ potted plant
static func potted(ci: CanvasItem, base: Vector2, scale := 1.0, green := Color("8fae7d")) -> void:
	var pw := 34.0 * scale
	var ph := 30.0 * scale
	ground_shadow(ci, base + Vector2(0, 1), pw * 0.5, 5.0, 0.09)
	# foliage
	for o in [Vector2(-pw * 0.28, -ph * 0.7), Vector2(pw * 0.28, -ph * 0.7), Vector2(0, -ph * 1.05)]:
		ci.draw_circle(base + o, pw * 0.42, green.darkened(0.08))
	ci.draw_circle(base + Vector2(-pw * 0.1, -ph * 1.0), pw * 0.3, green.lightened(0.14))
	# a couple of upright leaves
	for dx in [-0.2, 0.15, 0.4]:
		ci.draw_line(base + Vector2(pw * dx, -ph * 0.4),
			base + Vector2(pw * dx * 1.6, -ph * 1.5), green.darkened(0.02), 3.0, true)
	# terracotta pot (trapezoid)
	var top_y := base.y - ph * 0.35
	ci.draw_colored_polygon(PackedVector2Array([
		base + Vector2(-pw * 0.5, top_y - base.y), base + Vector2(pw * 0.5, top_y - base.y),
		base + Vector2(pw * 0.34, 0), base + Vector2(-pw * 0.34, 0)]), Palette.ACCENT_WARM)
	ci.draw_rect(Rect2(base.x - pw * 0.5, top_y, pw, ph * 0.16), Palette.ACCENT_WARM.lightened(0.10))
