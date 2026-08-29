extends CanvasLayer
class_name BoosterPanel
## In-level popup: your booster inventory. Use what you own, or buy more with
## gems (singly or a "stock up" pack). Bundles are also sold via IAP in the Shop.

signal use_pressed(id: String)
signal buy_pressed(id: String)
signal stock_pressed
signal closed

var economy: Economy = null

var _gems_lbl: Label
var _use_btns: Dictionary = {}   # id -> Button
var _buy_btns: Dictionary = {}   # id -> Button
var _stock_btn: Button
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
	box.add_theme_constant_override("separation", 9)
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
		row.add_theme_constant_override("separation", 12)

		var txt := _label("%s\n%s" % [Boosters.NAME[id], Boosters.DESC[id]], 21)
		txt.custom_minimum_size = Vector2(320, 0)
		txt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(txt)

		var bid: String = id
		var use := _button("Use", 21)
		use.custom_minimum_size = Vector2(120, 56)
		use.pressed.connect(func() -> void: use_pressed.emit(bid))
		_use_btns[id] = use
		row.add_child(use)

		var buy := _button("+ %dg" % Boosters.COST[id], 21)
		buy.custom_minimum_size = Vector2(90, 56)
		buy.pressed.connect(func() -> void: buy_pressed.emit(bid))
		_buy_btns[id] = buy
		row.add_child(buy)

		box.add_child(row)

	_stock_btn = _button("Stock up  —  one of each for %d gems" % Boosters.STOCK_ALL_COST, 21)
	_stock_btn.custom_minimum_size = Vector2(0, 54)
	_stock_btn.pressed.connect(func() -> void: stock_pressed.emit())
	box.add_child(_stock_btn)

	_note_lbl = _label("", 22)
	_note_lbl.add_theme_color_override("font_color", Palette.ACCENT_WARM)
	_note_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_note_lbl.modulate.a = 0.0
	box.add_child(_note_lbl)

	var close := _button("Close", 24)
	close.custom_minimum_size = Vector2(0, 54)
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
		var n := economy.booster_count(id)
		_use_btns[id].text = "Use  x%d" % n
		_use_btns[id].disabled = n <= 0
		_buy_btns[id].disabled = g < int(Boosters.COST[id])
	_stock_btn.disabled = g < Boosters.STOCK_ALL_COST

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
