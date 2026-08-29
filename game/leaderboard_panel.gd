extends CanvasLayer
class_name LeaderboardPanel
## Weekly star ranking. main computes the rows and calls show_board().

signal closed

var _head: Label
var _list: VBoxContainer

func _ready() -> void:
	layer = 23
	visible = false

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Palette.BG
	add_child(bg)

	_head = _label("Weekly ranks", 34)
	_head.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_head.offset_left = 24.0
	_head.offset_top = 22.0
	add_child(_head)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_TOP_WIDE)
	scroll.offset_left = 24.0
	scroll.offset_right = -24.0
	scroll.offset_top = 84.0
	scroll.anchor_bottom = 1.0
	scroll.offset_bottom = -110.0
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 4)
	scroll.add_child(_list)

	var back := _button("Back to puzzles", 24)
	back.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	back.offset_left = 200.0
	back.offset_right = -200.0
	back.offset_top = -92.0
	back.offset_bottom = -36.0
	back.pressed.connect(func() -> void: closed.emit())
	add_child(back)

func show_board(rows: Array, your_rank: int, days_left: int) -> void:
	_head.text = "Weekly ranks   ·   you're #%d   ·   resets in %dd" % [your_rank, days_left]
	for c in _list.get_children():
		_list.remove_child(c)
		c.queue_free()
	var shown := mini(rows.size(), 16)
	for i in shown:
		_list.add_child(_row(i + 1, rows[i]))
	if your_rank > shown:
		_list.add_child(_label("   ...", 20))
		_list.add_child(_row(your_rank, rows[your_rank - 1]))
	visible = true

func _row(rank: int, r: Dictionary) -> Control:
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 9
	sb.content_margin_bottom = 9
	sb.bg_color = Palette.BTN_HOVER if r.get("you", false) else Color(0, 0, 0, 0)
	if r.get("you", false):
		sb.border_color = Palette.ACCENT
		sb.set_border_width_all(2)
	panel.add_theme_stylebox_override("panel", sb)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	panel.add_child(row)
	var rk := _label("#%d" % rank, 22)
	rk.custom_minimum_size = Vector2(64, 0)
	row.add_child(rk)
	var nm := _label(str(r["name"]), 22)
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(nm)
	row.add_child(_label("%d *" % int(r["stars"]), 22))
	return panel

func _label(t: String, fs: int) -> Label:
	var l := Label.new()
	l.text = t
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", Palette.INK)
	return l

func _button(t: String, fs: int) -> Button:
	var b := Button.new()
	b.text = t
	b.add_theme_font_size_override("font_size", fs)
	return b
