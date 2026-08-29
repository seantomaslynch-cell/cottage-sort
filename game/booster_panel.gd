extends CanvasLayer
class_name BoosterPanel
## Quick in-level popup: the six boosters, bought-and-used instantly for gems.

signal use_pressed(id: String)
signal closed

var economy: Economy = null

var _gems_lbl: Label
var _rows: Dictionary = {}   # id -> Button
var _note_lbl: Label

func _ready() -> void:
	layer = 14
	visible = false

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Palette.DIM
	dim.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed:
			closed.emit())
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var card := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Palette.CARD
	sb.border_color = Palette.CARD_BORDER
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(20)
	sb.content_margin_left = 26
	sb.content_margin_right = 26
	sb.content_margin_top = 22
	sb.content_margin_bottom = 22
	card.add_theme_stylebox_override("panel", sb)
	center.add_child(card)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	card.add_child(box)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 20)
	box.add_child(head)
	var title := _label("Boosters", 32)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	_gems_lbl = _label("0 gems", 26)
	_gems_lbl.add_theme_color_override("font_color", Palette.BEADS[4])
	head.add_child(_gems_lbl)

	for id in Boosters.LIST:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)

		var txt := _label("%s\n%s" % [Boosters.NAME[id], Boosters.DESC[id]], 22)
		txt.custom_minimum_size = Vector2(360, 0)
		row.add_child(txt)

		var btn := _button("%d gems" % Boosters.COST[id], 22)
		btn.custom_minimum_size = Vector2(150, 58)
		var bid: String = id
		btn.pressed.connect(func() -> void: use_pressed.emit(bid))
		_rows[id] = btn
		row.add_child(btn)
		box.add_child(row)

	_note_lbl = _label("", 22)
	_note_lbl.add_theme_color_override("font_color", Palette.ACCENT_WARM)
	_note_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_note_lbl.modulate.a = 0.0
	box.add_child(_note_lbl)

	var close := _button("Close", 24)
	close.custom_minimum_size = Vector2(0, 56)
	close.pressed.connect(func() -> void: closed.emit())
	box.add_child(close)

func set_economy(e: Economy) -> void:
	economy = e

func open() -> void:
	visible = true
	refresh()

func refresh() -> void:
	if economy == null:
		return
	var g := economy.gems()
	_gems_lbl.text = "%d gems" % g
	for id in Boosters.LIST:
		_rows[id].disabled = g < int(Boosters.COST[id])

func note(text: String) -> void:
	_note_lbl.text = text
	_note_lbl.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(0.9)
	tw.tween_property(_note_lbl, "modulate:a", 0.0, 0.4)

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
