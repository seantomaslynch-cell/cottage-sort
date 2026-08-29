extends CanvasLayer
class_name ShopPanel
## Simple store screen. Lists IAP products; emits intents, main.gd does the buy.

signal buy_pressed(product_id: String)
signal restore_pressed
signal closed

var _iap: GameIap = null
var _economy: Economy = null

var _coins: Label
var _list: VBoxContainer

func _ready() -> void:
	layer = 18
	visible = false

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color("f3e9d8")
	add_child(bg)

	var title := _label("Shop", 38, Color("5b4636"))
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 24.0
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)

	_coins = _label("Coins: 0", 28, Color("5b4636"))
	_coins.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_coins.offset_top = 74.0
	_coins.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_coins)

	var note := _label(
		"Rewarded videos stay - they're optional bonuses.\nThis only removes full-screen interstitials.",
		18, Color("8a7a63"))
	note.set_anchors_preset(Control.PRESET_TOP_WIDE)
	note.offset_top = 116.0
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(note)

	_list = VBoxContainer.new()
	_list.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_list.offset_left = 40.0
	_list.offset_right = -40.0
	_list.offset_top = 190.0
	_list.add_theme_constant_override("separation", 14)
	add_child(_list)

	var bottom := HBoxContainer.new()
	bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_left = 24.0
	bottom.offset_right = -24.0
	bottom.offset_top = -110.0
	bottom.offset_bottom = -40.0
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_theme_constant_override("separation", 16)
	add_child(bottom)

	var restore := _button("Restore purchases", 24)
	restore.custom_minimum_size = Vector2(280, 68)
	restore.pressed.connect(func() -> void: restore_pressed.emit())
	bottom.add_child(restore)

	var close := _button("Close", 26)
	close.custom_minimum_size = Vector2(200, 68)
	close.pressed.connect(func() -> void: closed.emit())
	bottom.add_child(close)

func set_refs(iap: GameIap, economy: Economy) -> void:
	_iap = iap
	_economy = economy

func open() -> void:
	visible = true
	refresh()

func refresh() -> void:
	if _iap == null:
		return
	_coins.text = "Coins: %d" % (_economy.coins() if _economy else 0)

	for c in _list.get_children():
		_list.remove_child(c)
		c.queue_free()

	for p in GameIap.PRODUCTS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)

		var name_lbl := _label("%s\n%s" % [p["name"], p["price"]], 22, Color("5b4636"))
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_lbl)

		var btn := _button("", 24)
		btn.custom_minimum_size = Vector2(180, 64)
		if _iap.owns(p["id"]):
			btn.text = "Owned"
			btn.disabled = true
		else:
			btn.text = "Buy"
			var pid: String = p["id"]
			btn.pressed.connect(func() -> void: buy_pressed.emit(pid))
		row.add_child(btn)

		_list.add_child(row)

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
