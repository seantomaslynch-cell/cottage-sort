extends CanvasLayer
class_name LeaderboardPanel
## Two boards over one list: weekly stars, and all-time furthest level.
## main computes both row sets and calls open().

signal closed

var _head: Label
var _tabs: HBoxContainer
var _list: VBoxContainer
var _tab := "week"

var _week_rows: Array = []
var _week_rank := 0
var _days_left := 0
var _depth_rows: Array = []
var _depth_rank := 0

func _ready() -> void:
	layer = 23
	visible = false

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Palette.BG
	add_child(bg)

	_head = _label("Ranks", 34)
	_head.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_head.offset_left = 24.0
	_head.offset_top = 20.0
	add_child(_head)

	_tabs = HBoxContainer.new()
	_tabs.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_tabs.offset_top = 66.0
	_tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	_tabs.add_theme_constant_override("separation", 10)
	add_child(_tabs)
	for spec in [["This week", "week"], ["All-time", "depth"]]:
		var b := _button(spec[0], 22)
		b.custom_minimum_size = Vector2(210, 56)
		var which: String = spec[1]
		b.pressed.connect(func() -> void: _show(which))
		_tabs.add_child(b)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left = 24.0
	scroll.offset_right = -24.0
	scroll.offset_top = 132.0
	scroll.offset_bottom = -104.0
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
	back.offset_top = -88.0
	back.offset_bottom = -34.0
	back.pressed.connect(func() -> void: closed.emit())
	add_child(back)

func open(week_rows: Array, week_rank: int, days_left: int, depth_rows: Array, depth_rank: int) -> void:
	_week_rows = week_rows
	_week_rank = week_rank
	_days_left = days_left
	_depth_rows = depth_rows
	_depth_rank = depth_rank
	visible = true
	_show("week")

func _show(which: String) -> void:
	_tab = which
	for i in _tabs.get_child_count():
		(_tabs.get_child(i) as Button).disabled = (["week", "depth"][i] == which)
	for c in _list.get_children():
		_list.remove_child(c)
		c.queue_free()

	var rows: Array = _week_rows if which == "week" else _depth_rows
	var rank: int = _week_rank if which == "week" else _depth_rank
	if which == "week":
		_head.text = "Weekly stars   ·   you're #%d   ·   resets in %dd" % [rank, _days_left]
	else:
		_head.text = "Furthest level   ·   you're #%d" % rank

	var shown := mini(rows.size(), 16)
	for i in shown:
		_list.add_child(_row(i + 1, rows[i], which))
	if rank > shown:
		_list.add_child(_label("   ...", 20))
		_list.add_child(_row(rank, rows[rank - 1], which))

func _row(rank: int, r: Dictionary, kind: String) -> Control:
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
	var val := ("%d ★" % int(r["stars"])) if kind == "week" else ("Lv %d" % int(r["depth"]))
	row.add_child(_label(val, 22))
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
