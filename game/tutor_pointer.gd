extends Node2D
class_name TutorPointer
## A chunky bobbing arrow that points up at a screen position. Lives in the
## Coach CanvasLayer so it draws over the board. main sets `target` via
## Coach.point_at().

var target := Vector2.ZERO
var _t := 0.0

func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta
	queue_redraw()

func _draw() -> void:
	if not visible or target == Vector2.ZERO:
		return
	var bob := sin(_t * 4.5) * 7.0
	# tip sits just above the jar and points DOWN at it; body hangs above.
	var tip := target + Vector2(0.0, -10.0 - bob)
	var col := Palette.ACCENT_WARM
	var pts := PackedVector2Array([
		tip,
		tip + Vector2(-17, -20), tip + Vector2(-7, -20),
		tip + Vector2(-7, -46), tip + Vector2(7, -46),
		tip + Vector2(7, -20), tip + Vector2(17, -20),
	])
	draw_colored_polygon(pts, col)
	var outline := pts.duplicate()
	outline.append(tip)
	draw_polyline(outline, col.darkened(0.28), 2.5, true)
