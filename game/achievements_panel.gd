extends CanvasLayer
class_name AchievementsPanel
## A scrollable gallery of badges, grouped by category. Earned ones read in full
## colour with a ✓; the rest show a progress bar. Rewards are auto-granted on
## completion (main), so there's no claim step — this is the record.

signal closed

var ach: Achievements = null

var _title: Label
var _list: VBoxContainer

func _ready() -> void:
	layer = 21
	visible = false

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Palette.BG
	add_child(dim)

	_title = _label("Achievements", 34, Palette.INK)
	_title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_title.offset_left = 24.0
	_title.offset_top = 26.0
	add_child(_title)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left = 24.0
	scroll.offset_right = -24.0
	scroll.offset_top = 92.0
	scroll.offset_bottom = -110.0
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 8)
	scroll.add_child(_list)

	var back := _button("Back", 24)
	back.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	back.offset_left = 210.0
	back.offset_right = -210.0
	back.offset_top = -88.0
	back.offset_bottom = -28.0
	back.pressed.connect(func() -> void: closed.emit())
	add_child(back)

func open() -> void:
	visible = true
	_refresh()

func _refresh() -> void:
	if ach == null:
		return
	for c in _list.get_children():
		c.queue_free()
	_title.text = "Achievements   %d / %d" % [ach.unlocked_count(), Achievements.LIST.size()]
	for cat in Achievements.CATS:
		_list.add_child(_header(cat))
		for a in Achievements.LIST:
			if a["cat"] == cat:
				_list.add_child(_row(a))

func _row(a: Dictionary) -> Control:
	var id: String = a["id"]
	var done := ach.unlocked(id)
	var p := ach.progress(id)

	var card := PanelContainer.new()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	var mc := MarginContainer.new()
	for m in ["margin_left", "margin_right"]:
		mc.add_theme_constant_override(m, 14)
	for m in ["margin_top", "margin_bottom"]:
		mc.add_theme_constant_override(m, 10)
	mc.add_child(box)
	card.add_child(mc)

	var top := HBoxContainer.new()
	var nm := _label(a["name"], 24, Palette.INK if done else Palette.INK_FAINT)
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(nm)
	var rw := "+%dc" % int(a["coins"])
	if int(a["gems"]) > 0:
		rw += "  +%dg" % int(a["gems"])
	var tag := _label("✓  earned" if done else rw, 20, Palette.ACCENT_WARM)
	top.add_child(tag)
	box.add_child(top)

	box.add_child(_label(a["desc"], 19, Palette.INK_FAINT))

	if not done:
		var bar := ProgressBar.new()
		bar.max_value = p.y
		bar.value = p.x
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(0, 14)
		box.add_child(bar)
		box.add_child(_label("%d / %d" % [p.x, p.y], 16, Palette.INK_FAINT))
	return card

func _header(text: String) -> Label:
	var l := _label(text, 22, Palette.ACCENT_WARM)
	return l

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
