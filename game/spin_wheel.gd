extends Node2D
class_name SpinWheel
## Drawn prize wheel for the daily spin. Draws SPIN segments centred on its own
## origin; animate_spin() rotates so the chosen segment lands under the pointer
## (which the panel draws separately, at the top, not rotating).

const SEG_COLORS := [
	Color("d97a6c"), Color("e6b45e"), Color("8fae7d"), Color("7fa8c9"),
	Color("9b7bab"), Color("c98f6b"), Color("d99abf"), Color("6fb0a6"),
]

var radius := 148.0
var _spinning := false

func is_spinning() -> bool:
	return _spinning

func _draw() -> void:
	var n := Daily.SPIN.size()
	var seg := TAU / n
	var font := ThemeDB.fallback_font
	for i in n:
		var a0 := i * seg
		var pts := PackedVector2Array([Vector2.ZERO])
		for s in 13:
			var a := a0 + seg * float(s) / 12.0
			pts.append(Vector2(cos(a), sin(a)) * radius)
		draw_colored_polygon(pts, SEG_COLORS[i % SEG_COLORS.size()])
		var mid := a0 + seg * 0.5
		var lp := Vector2(cos(mid), sin(mid)) * radius * 0.6
		var txt := str(Daily.SPIN[i]["value"])
		var tw := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_CENTER, -1, 24).x
		draw_string(font, lp - Vector2(tw * 0.5, -8), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("3a2f27"))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 72, Color("b79b74"), 5.0, true)
	draw_circle(Vector2.ZERO, 12.0, Color("5b4636"))

func animate_spin(target_index: int, on_done: Callable) -> void:
	if _spinning:
		return
	_spinning = true
	var n := Daily.SPIN.size()
	var seg := TAU / n
	var target := -PI / 2.0 - (target_index * seg + seg * 0.5) + TAU * 6.0
	rotation = 0.0
	var tw := create_tween()
	tw.tween_property(self, "rotation", target, 2.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func() -> void:
		rotation = fposmod(target, TAU)
		_spinning = false
		if on_done.is_valid():
			on_done.call())
