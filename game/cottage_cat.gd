extends Node2D
class_name CottageCat
## The cottage cat — a small procedurally-drawn sleeper that lives on the puzzle
## screen. Breathes gently, stretches when you clear a level, and now and then
## leaves a little gift (main handles the reward).

var _t := 0.0
var _stretch := 0.0        # 0 asleep .. 1 mid-stretch
var _base_scale := 1.0

func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta
	if _stretch > 0.0:
		_stretch = maxf(0.0, _stretch - delta * 1.6)
	queue_redraw()

## A slow luxurious stretch — call on a level clear.
func celebrate() -> void:
	_stretch = 1.0
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(_base_scale * 1.12, _base_scale * 0.92), 0.18).set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "scale", Vector2(_base_scale, _base_scale), 0.5).set_trans(Tween.TRANS_ELASTIC)

func _draw() -> void:
	var breathe := sin(_t * 1.8) * 1.5
	var lift := -6.0 * _stretch
	var body := Color("a99a86")
	var dark := Color("87775f")
	var cream := Color("d9cbb4")

	# contact shadow
	draw_set_transform(Vector2(0, 30 + breathe), 0.0, Vector2(46, 8))
	draw_circle(Vector2.ZERO, 1.0, Color(0, 0, 0, 0.10))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# tail curling around the front
	var tail := PackedVector2Array()
	for i in 16:
		var a := PI * 0.05 + i / 15.0 * PI * 0.95
		tail.append(Vector2(cos(a), sin(a)) * (27.0 + i * 0.35) + Vector2(10, 10 + breathe))
	draw_polyline(tail, dark, 6.5, true)
	draw_circle(tail[tail.size() - 1], 4.5, dark)

	# curled body
	draw_set_transform(Vector2(0, breathe + lift), 0.0, Vector2(1.0, 0.82))
	draw_circle(Vector2(0, 4), 34.0, body)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# head tucked against the body
	var hp := Vector2(-24, -6 + breathe + lift * 1.4)
	draw_circle(hp, 18.0, body)
	# ears
	for s in [-1.0, 1.0]:
		var e := hp + Vector2(9.0 * s, -14.0)
		draw_colored_polygon(PackedVector2Array([
			e + Vector2(-6, 6), e + Vector2(6, 6), e + Vector2(0.0, -8.0)]), body)
		draw_colored_polygon(PackedVector2Array([
			e + Vector2(-3, 5), e + Vector2(3, 5), e + Vector2(0.0, -3.0)]), dark)
	# muzzle + closed eye
	draw_circle(hp + Vector2(-6, 4), 7.0, cream)
	draw_arc(hp + Vector2(4, 0), 5.0, PI * 0.9, PI * 1.9, 8, dark, 2.0, true)
	draw_line(hp + Vector2(-9, 6), hp + Vector2(-3, 6), dark, 1.5)  # nose/mouth
