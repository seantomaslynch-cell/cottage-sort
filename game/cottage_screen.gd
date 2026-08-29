extends CanvasLayer
class_name CottageScreen
## The restore screen: the cottage drawing on top, a row of upgrade slots below,
## a coin balance, a rewarded "mystery box", and a way back to the puzzles.

signal buy_pressed(slot_id: String)
signal mystery_pressed
signal closed

const CottageViewScene := preload("res://game/cottage_view.gd")

var economy: Economy = null

var _title: Label
var _coins: Label
var _view: CottageView
var _slots_box: VBoxContainer
var _toast: Label

func _ready() -> void:
	layer = 15
	visible = false

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color("f3e9d8")
	add_child(bg)

	_title = _label("Your Cottage", 34)
	_title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_title.offset_left = 24.0
	_title.offset_top = 24.0
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_child(_title)

	_coins = _label("Coins: 0", 30)
	_coins.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_coins.offset_right = -24.0
	_coins.offset_top = 26.0
	_coins.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_coins)

	_view = CottageViewScene.new()
	_view.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_view.offset_top = 84.0
	_view.offset_bottom = 84.0 + 520.0
	_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_view)

	_slots_box = VBoxContainer.new()
	_slots_box.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_slots_box.offset_left = 24.0
	_slots_box.offset_right = -24.0
	_slots_box.offset_top = -560.0
	_slots_box.offset_bottom = -150.0
	_slots_box.add_theme_constant_override("separation", 10)
	add_child(_slots_box)

	var buttons := HBoxContainer.new()
	buttons.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	buttons.offset_left = 24.0
	buttons.offset_right = -24.0
	buttons.offset_top = -128.0
	buttons.offset_bottom = -44.0
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 16)
	add_child(buttons)

	var mystery := _button("Mystery box  (Watch)", 24)
	mystery.custom_minimum_size = Vector2(300, 72)
	mystery.pressed.connect(func() -> void: mystery_pressed.emit())
	buttons.add_child(mystery)

	var back := _button("Back to puzzles", 24)
	back.custom_minimum_size = Vector2(260, 72)
	back.pressed.connect(func() -> void: closed.emit())
	buttons.add_child(back)

	_toast = _label("", 30)
	_toast.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_toast.offset_top = 620.0
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.modulate.a = 0.0
	add_child(_toast)

func set_economy(e: Economy) -> void:
	economy = e
	_view.economy = e

func open() -> void:
	visible = true
	refresh()

func refresh() -> void:
	if economy == null:
		return
	_coins.text = "Coins: %d" % economy.coins()
	_title.text = "Your Cottage  -  %d%% restored" % roundi(economy.restored_fraction() * 100.0)
	_view.refresh()

	for c in _slots_box.get_children():
		_slots_box.remove_child(c)
		c.queue_free()

	for s in CottageData.SLOTS:
		var id: String = s["id"]
		var t := economy.tier(id)
		var maxt := CottageData.max_tier(id)

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)

		var name_lbl := _label(s["name"], 26)
		name_lbl.custom_minimum_size = Vector2(120, 0)
		row.add_child(name_lbl)

		var pips := _label(_pips(t, maxt), 26)
		pips.custom_minimum_size = Vector2(110, 0)
		row.add_child(pips)

		var spacer := Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(spacer)

		var btn := _button("", 24)
		btn.custom_minimum_size = Vector2(210, 60)
		if t >= maxt:
			btn.text = "Restored"
			btn.disabled = true
		else:
			btn.text = "Tier %d  -  %d" % [t + 1, economy.next_cost(id)]
			btn.disabled = not economy.can_buy(id)
			var sid := id
			btn.pressed.connect(func() -> void: buy_pressed.emit(sid))
		row.add_child(btn)

		_slots_box.add_child(row)

func flash(text: String) -> void:
	_toast.text = text
	_toast.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(0.9)
	tw.tween_property(_toast, "modulate:a", 0.0, 0.5)

func _pips(t: int, m: int) -> String:
	var s := ""
	for i in m:
		s += "*" if i < t else "-"
	return s

func _label(t: String, fs: int) -> Label:
	var l := Label.new()
	l.text = t
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", Color("5b4636"))
	return l

func _button(t: String, fs: int) -> Button:
	var b := Button.new()
	b.text = t
	b.add_theme_font_size_override("font_size", fs)
	return b
