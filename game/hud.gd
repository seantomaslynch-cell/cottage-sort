extends CanvasLayer
class_name GameHUD
## Placeholder HUD built from code: top bar (level, moves, mute, restart),
## bottom bar (undo, add jar, levels), a fading toast, and a win overlay.

signal restart_pressed
signal next_pressed
signal undo_pressed
signal add_jar_pressed
signal levels_pressed
signal cottage_pressed
signal daily_pressed
signal season_pressed
signal shop_pressed
signal hint_pressed
signal double_pressed
signal add_moves_pressed
signal buy_moves_pressed
signal skip_pressed
signal settings_pressed
signal boost_pressed
signal struggle_pressed
signal mute_toggled(muted: bool)

const BOARD_UNLIMITED := 999

var _status: Label
var _lv := 1
var _mv := 0
var _co := 0
var _gm := 0
var _budget := BOARD_UNLIMITED
var _undo_btn: Button
var _addjar_btn: Button
var _toast: Label
var _win_root: Control
var _win_label: Label
var _win_stars: Label
var _win_best: Label
var _win_coins: Label
var _win_next: Label
var _double_btn: Button
var _win_earned := 0
var _fail_root: Control
var _fail_buy_btn: Button
var _fail_skip_btn: Button
var _fail_struggle_btn: Button
var _nav: Control

func _ready() -> void:
	layer = 10

	var top := HBoxContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 24.0
	top.offset_right = -24.0
	top.offset_top = 26.0
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_theme_constant_override("separation", 14)
	add_child(top)

	_status = _label("Lv 1    0 moves    0c")
	top.add_child(_status)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)

	var menu_btn := _button("Menu")
	menu_btn.pressed.connect(func() -> void: _nav.visible = not _nav.visible)
	top.add_child(menu_btn)

	var restart_btn := _button("Restart")
	restart_btn.pressed.connect(func() -> void: restart_pressed.emit())
	top.add_child(restart_btn)

	_build_nav()

	var bottom := HBoxContainer.new()
	bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_left = 24.0
	bottom.offset_right = -24.0
	bottom.offset_top = -104.0
	bottom.offset_bottom = -28.0
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_theme_constant_override("separation", 10)
	add_child(bottom)

	var bsz := Vector2(100, 64)

	_undo_btn = _button("Undo")
	_undo_btn.custom_minimum_size = bsz
	_undo_btn.pressed.connect(func() -> void: undo_pressed.emit())
	bottom.add_child(_undo_btn)

	var hint_btn := _button("Hint")
	hint_btn.custom_minimum_size = bsz
	hint_btn.pressed.connect(func() -> void: hint_pressed.emit())
	bottom.add_child(hint_btn)

	_addjar_btn = _button("Jar")
	_addjar_btn.custom_minimum_size = bsz
	_addjar_btn.pressed.connect(func() -> void: add_jar_pressed.emit())
	bottom.add_child(_addjar_btn)

	var boost_btn := _button("Boost")
	boost_btn.custom_minimum_size = bsz
	boost_btn.pressed.connect(func() -> void: boost_pressed.emit())
	bottom.add_child(boost_btn)

	var levels_btn := _button("Levels")
	levels_btn.custom_minimum_size = bsz
	levels_btn.pressed.connect(func() -> void: levels_pressed.emit())
	bottom.add_child(levels_btn)

	var cottage_btn := _button("Cottage")
	cottage_btn.custom_minimum_size = bsz
	cottage_btn.pressed.connect(func() -> void: cottage_pressed.emit())
	bottom.add_child(cottage_btn)

	_toast = _label("")
	_toast.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_toast.offset_top = 92.0
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.modulate.a = 0.0
	add_child(_toast)

	_build_win_overlay()
	_build_fail_overlay()

func _build_nav() -> void:
	_nav = Control.new()
	_nav.set_anchors_preset(Control.PRESET_FULL_RECT)
	_nav.visible = false
	add_child(_nav)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.2, 0.15, 0.12, 0.4)
	dim.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed:
			_nav.visible = false)
	_nav.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_nav.add_child(center)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	center.add_child(box)

	var items := [
		["Cottage", cottage_pressed], ["Daily", daily_pressed],
		["Season", season_pressed], ["Shop", shop_pressed],
		["Levels", levels_pressed], ["Settings", settings_pressed],
	]
	for it in items:
		var b := _button(it[0])
		b.custom_minimum_size = Vector2(300, 66)
		var sig: Signal = it[1]
		b.pressed.connect(func() -> void:
			_nav.visible = false
			sig.emit())
		box.add_child(b)

	var close := _button("Close")
	close.custom_minimum_size = Vector2(300, 60)
	close.pressed.connect(func() -> void: _nav.visible = false)
	box.add_child(close)

func _build_fail_overlay() -> void:
	_fail_root = Control.new()
	_fail_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fail_root.visible = false
	add_child(_fail_root)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.36, 0.27, 0.21, 0.55)
	_fail_root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fail_root.add_child(center)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(box)

	var title := _label("Out of moves")
	title.add_theme_font_size_override("font_size", 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var sub := _label("Need a hand with this one?")
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(sub)

	var watch := _button("+5 moves   (Watch)")
	watch.custom_minimum_size = Vector2(320, 70)
	watch.pressed.connect(func() -> void: add_moves_pressed.emit())
	box.add_child(watch)

	_fail_buy_btn = _button("+5 moves   (100 coins)")
	_fail_buy_btn.custom_minimum_size = Vector2(320, 70)
	_fail_buy_btn.pressed.connect(func() -> void: buy_moves_pressed.emit())
	box.add_child(_fail_buy_btn)

	_fail_struggle_btn = _button("Struggle pack   40 gems + 300c + 8 moves   $0.99")
	_fail_struggle_btn.custom_minimum_size = Vector2(320, 64)
	_fail_struggle_btn.add_theme_font_size_override("font_size", 20)
	var ssb := StyleBoxFlat.new()
	ssb.bg_color = Color("f8eed9")
	ssb.border_color = Color("b0553c")
	ssb.set_border_width_all(2)
	ssb.set_corner_radius_all(14)
	ssb.content_margin_left = 14
	ssb.content_margin_right = 14
	ssb.content_margin_top = 10
	ssb.content_margin_bottom = 10
	_fail_struggle_btn.add_theme_stylebox_override("normal", ssb)
	_fail_struggle_btn.pressed.connect(func() -> void: struggle_pressed.emit())
	box.add_child(_fail_struggle_btn)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	box.add_child(row)

	var restart := _button("Restart")
	restart.custom_minimum_size = Vector2(150, 64)
	restart.pressed.connect(func() -> void: restart_pressed.emit())
	row.add_child(restart)

	_fail_skip_btn = _button("Skip   (Watch)")
	_fail_skip_btn.custom_minimum_size = Vector2(180, 64)
	_fail_skip_btn.pressed.connect(func() -> void: skip_pressed.emit())
	row.add_child(_fail_skip_btn)

func _build_win_overlay() -> void:
	_win_root = Control.new()
	_win_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_win_root.visible = false
	add_child(_win_root)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.36, 0.27, 0.21, 0.55)
	_win_root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_win_root.add_child(center)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(box)

	_win_label = _label("Cottage corner tidied!")
	_win_label.add_theme_font_size_override("font_size", 44)
	_win_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_win_label)

	_win_stars = _label("")
	_win_stars.add_theme_font_size_override("font_size", 52)
	_win_stars.add_theme_color_override("font_color", Color("f2c14e"))
	_win_stars.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_win_stars)

	_win_best = _label("")
	_win_best.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_win_best)

	_win_coins = _label("")
	_win_coins.add_theme_font_size_override("font_size", 36)
	_win_coins.add_theme_color_override("font_color", Color("b5654a"))
	_win_coins.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_win_coins)

	_win_next = _label("")
	_win_next.add_theme_font_size_override("font_size", 22)
	_win_next.add_theme_color_override("font_color", Color("8a7a63"))
	_win_next.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_win_next)

	_double_btn = _button("Double coins  (Watch)")
	_double_btn.custom_minimum_size = Vector2(320, 68)
	_double_btn.pressed.connect(func() -> void: double_pressed.emit())
	box.add_child(_double_btn)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	box.add_child(row)

	var cottage_btn := _button("Cottage")
	cottage_btn.custom_minimum_size = Vector2(160, 72)
	cottage_btn.pressed.connect(func() -> void: cottage_pressed.emit())
	row.add_child(cottage_btn)

	var levels_btn := _button("Levels")
	levels_btn.custom_minimum_size = Vector2(160, 72)
	levels_btn.pressed.connect(func() -> void: levels_pressed.emit())
	row.add_child(levels_btn)

	var next_btn := _button("Next")
	next_btn.custom_minimum_size = Vector2(160, 72)
	next_btn.pressed.connect(func() -> void: next_pressed.emit())
	row.add_child(next_btn)

func _label(t: String) -> Label:
	var l := Label.new()
	l.text = t
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", 32)
	l.add_theme_color_override("font_color", Color("5b4636"))
	return l

func _button(t: String) -> Button:
	var b := Button.new()
	b.text = t
	b.add_theme_font_size_override("font_size", 26)
	return b

func set_muted(_m: bool) -> void:
	pass  # sound is toggled from the Settings screen now; kept for the M-key path

func _sync_status() -> void:
	var mv_txt := "%d moves" % _mv
	var warn := false
	if _budget < BOARD_UNLIMITED:
		var left := maxi(0, _budget - _mv)
		mv_txt = "%d / %d moves" % [_mv, _budget]
		warn = left <= 5
	_status.text = "Lv %d   ·   %s   ·   %dc  %dg" % [_lv, mv_txt, _co, _gm]
	_status.add_theme_color_override("font_color", Color("b0553c") if warn else Color("5b4636"))

func set_gems(n: int) -> void:
	_gm = n
	_sync_status()

func set_level(n: int) -> void:
	_lv = n
	_sync_status()

func set_moves(n: int) -> void:
	_mv = n
	_sync_status()

func set_budget(n: int) -> void:
	_budget = n
	_sync_status()

func set_coins(n: int) -> void:
	_co = n
	_sync_status()

func set_undo_enabled(v: bool) -> void:
	_undo_btn.disabled = not v

func set_addjar_enabled(v: bool) -> void:
	_addjar_btn.disabled = not v

func flash(text: String) -> void:
	_toast.text = text
	_toast.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(0.9)
	tw.tween_property(_toast, "modulate:a", 0.0, 0.5)

func set_next_hint(text: String) -> void:
	_win_next.text = text

func show_win(text: String, best: int, current: int, earned: int, stars: int) -> void:
	_win_label.text = text
	_win_stars.text = _stars_str(stars)
	if best > 0 and current > best:
		_win_best.text = "Solved in %d moves  (best %d)" % [current, best]
	else:
		_win_best.text = "Solved in %d moves  -  new best!" % current
	_win_earned = earned
	_win_coins.text = "+%d coins" % earned
	_double_btn.disabled = false
	_double_btn.text = "Double coins  (Watch)"
	_win_root.visible = true

func mark_doubled() -> void:
	_double_btn.disabled = true
	_double_btn.text = "Doubled!"
	_win_coins.text = "+%d coins" % (_win_earned * 2)

func hide_win() -> void:
	_win_root.visible = false

func show_fail(coin_cost: int, coins_have: int, show_skip: bool, show_struggle := false) -> void:
	_fail_buy_btn.text = "+5 moves   (%d coins)" % coin_cost
	_fail_buy_btn.disabled = coins_have < coin_cost
	_fail_skip_btn.visible = show_skip
	_fail_struggle_btn.visible = show_struggle
	_fail_root.visible = true

func hide_fail() -> void:
	_fail_root.visible = false

func fail_open() -> bool:
	return _fail_root.visible

func nav_open() -> bool:
	return _nav.visible

func _stars_str(n: int) -> String:
	var s := ""
	for i in 3:
		s += "*" if i < n else "."
	return s
