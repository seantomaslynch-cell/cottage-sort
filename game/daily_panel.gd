extends CanvasLayer
class_name DailyPanel
## The "come back tomorrow" screen: 7-day login cycle, a spin wheel, and the
## rewarded-ad streak readout. Emits intents; main.gd does the granting.

signal claim_login_pressed
signal spin_pressed
signal closed
signal debug_day_pressed

const SpinWheelScene := preload("res://game/spin_wheel.gd")

var _daily: Daily = null

var _login_row: HBoxContainer
var _claim_btn: Button
var _streak_lbl: Label
var _wheel: SpinWheel
var _spin_btn: Button
var _adstreak_lbl: Label
var _toast: Label

func _ready() -> void:
	layer = 25
	visible = false

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.20, 0.15, 0.12, 0.74)
	add_child(dim)

	var title := _label("Daily", 40, Color("f3e9d8"))
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 22.0
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)

	_login_row = HBoxContainer.new()
	_login_row.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_login_row.offset_top = 88.0
	_login_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_login_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_login_row.add_theme_constant_override("separation", 6)
	add_child(_login_row)

	var login_box := VBoxContainer.new()
	login_box.set_anchors_preset(Control.PRESET_TOP_WIDE)
	login_box.offset_top = 184.0
	login_box.alignment = BoxContainer.ALIGNMENT_CENTER
	login_box.add_theme_constant_override("separation", 8)
	add_child(login_box)

	_claim_btn = _button("Claim", 28)
	_claim_btn.custom_minimum_size = Vector2(340, 68)
	_claim_btn.pressed.connect(func() -> void: claim_login_pressed.emit())
	login_box.add_child(_claim_btn)

	_streak_lbl = _label("Login streak: 0 days", 24, Color("f3e9d8"))
	_streak_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	login_box.add_child(_streak_lbl)

	_wheel = SpinWheelScene.new()
	_wheel.position = Vector2(360, 486)
	add_child(_wheel)

	var pointer := Polygon2D.new()
	pointer.polygon = PackedVector2Array([Vector2(0, 20), Vector2(-16, -4), Vector2(16, -4)])
	pointer.color = Color("5b4636")
	pointer.position = Vector2(360, 486 - _wheel.radius - 16)
	add_child(pointer)

	var spin_box := VBoxContainer.new()
	spin_box.set_anchors_preset(Control.PRESET_TOP_WIDE)
	spin_box.offset_top = 660.0
	spin_box.alignment = BoxContainer.ALIGNMENT_CENTER
	spin_box.add_theme_constant_override("separation", 8)
	add_child(spin_box)

	_spin_btn = _button("Spin", 28)
	_spin_btn.custom_minimum_size = Vector2(300, 68)
	_spin_btn.pressed.connect(func() -> void: spin_pressed.emit())
	spin_box.add_child(_spin_btn)

	_adstreak_lbl = _label("Ad-watch streak: 0 / 3", 22, Color("f3e9d8"))
	_adstreak_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	spin_box.add_child(_adstreak_lbl)

	_toast = _label("", 30, Color("f2c14e"))
	_toast.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_toast.offset_top = 812.0
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.modulate.a = 0.0
	add_child(_toast)

	var bottom := HBoxContainer.new()
	bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_left = 24.0
	bottom.offset_right = -24.0
	bottom.offset_top = -110.0
	bottom.offset_bottom = -40.0
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_theme_constant_override("separation", 16)
	add_child(bottom)

	var close := _button("Close", 26)
	close.custom_minimum_size = Vector2(220, 68)
	close.pressed.connect(func() -> void: closed.emit())
	bottom.add_child(close)

	if OS.has_feature("debug"):
		var dbg := _button("+1 day (debug)", 22)
		dbg.custom_minimum_size = Vector2(220, 68)
		dbg.pressed.connect(func() -> void: debug_day_pressed.emit())
		bottom.add_child(dbg)

func set_daily(d: Daily) -> void:
	_daily = d

func open() -> void:
	visible = true
	_wheel.rotation = 0.0
	refresh()

func refresh() -> void:
	if _daily == null:
		return
	for c in _login_row.get_children():
		_login_row.remove_child(c)
		c.queue_free()

	var cur := _daily.current_login_slot()
	var pending := _daily.login_pending()
	var done_before := cur if pending else cur + 1
	for i in Daily.LOGIN_REWARDS.size():
		var st := 0
		if i < done_before:
			st = 2
		elif i == cur and pending:
			st = 1
		_login_row.add_child(_make_cell(i + 1, Daily.LOGIN_REWARDS[i], st))

	if pending:
		_claim_btn.disabled = false
		_claim_btn.text = "Claim  +%d" % _daily.current_login_reward()
	else:
		_claim_btn.disabled = true
		_claim_btn.text = "Claimed - back tomorrow"

	var ls := _daily.login_streak()
	_streak_lbl.text = "Login streak: %d day%s" % [ls, "" if ls == 1 else "s"]

	_spin_btn.disabled = _wheel.is_spinning()
	_spin_btn.text = "Spin  (free)" if _daily.free_spin_available() else "Spin  (Watch)"
	_adstreak_lbl.text = "Ad-watch streak: %d / %d   (chest %d)" % [
		_daily.ad_streak(), Daily.AD_STREAK_TARGET, Daily.AD_STREAK_CHEST]
	_wheel.queue_redraw()

func play_spin(index: int, on_settled: Callable) -> void:
	if _wheel.is_spinning():
		return
	_spin_btn.disabled = true
	_wheel.animate_spin(index, func() -> void:
		if on_settled.is_valid():
			on_settled.call()
		refresh())

func flash(text: String) -> void:
	_toast.text = text
	_toast.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(0.9)
	tw.tween_property(_toast, "modulate:a", 0.0, 0.5)

func _make_cell(day: int, reward: int, state: int) -> Control:
	var p := Panel.new()
	p.custom_minimum_size = Vector2(88, 80)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(10)
	sb.set_border_width_all(3)
	sb.bg_color = Color("efe0c6")
	sb.border_color = Color("cdb891")
	if state == 1:
		sb.bg_color = Color("fff3d6")
		sb.border_color = Color("f2c14e")
		sb.set_border_width_all(4)
	elif state == 2:
		sb.bg_color = Color("d7c6ab")
	p.add_theme_stylebox_override("panel", sb)

	var l := Label.new()
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.text = "Day %d\n%d" % [day, reward]
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", 18)
	l.add_theme_color_override("font_color", Color("5b4636"))
	p.add_child(l)
	return p

func _label(t: String, fs: int, col: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", col)
	return l

func _button(t: String, fs: int) -> Button:
	var b := Button.new()
	b.text = t
	b.add_theme_font_size_override("font_size", fs)
	return b
