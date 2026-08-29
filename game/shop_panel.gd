extends CanvasLayer
class_name ShopPanel
## Store screen. Same shell as the Cottage screen: opaque cream page, left title,
## coin balance top-right, a list of rows, and a centred bottom button row.
## Lists IAP products; emits intents, main.gd does the buy.

signal buy_pressed(product_id: String)
signal restore_pressed
signal closed

var _iap: GameIap = null
var _economy: Economy = null

var _title: Label
var _coins: Label
var _list: VBoxContainer
var _toast: Label

func _ready() -> void:
	layer = 18
	visible = false

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Palette.BG
	add_child(bg)

	_title = _label("Shop", 34)
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

	var note := _label(
		"Rewarded videos stay - they're optional bonuses.\nThis only removes full-screen interstitials.", 18)
	note.add_theme_color_override("font_color", Palette.INK_FAINT)
	note.set_anchors_preset(Control.PRESET_TOP_WIDE)
	note.offset_top = 80.0
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(note)

	_list = VBoxContainer.new()
	_list.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_list.offset_left = 24.0
	_list.offset_right = -24.0
	_list.offset_top = 156.0
	_list.add_theme_constant_override("separation", 10)
	add_child(_list)

	_toast = _label("", 30)
	_toast.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_toast.offset_top = 560.0
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.modulate.a = 0.0
	add_child(_toast)

	var buttons := HBoxContainer.new()
	buttons.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	buttons.offset_left = 24.0
	buttons.offset_right = -24.0
	buttons.offset_top = -128.0
	buttons.offset_bottom = -44.0
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 16)
	add_child(buttons)

	var restore := _button("Restore purchases", 24)
	restore.custom_minimum_size = Vector2(300, 72)
	restore.pressed.connect(func() -> void: restore_pressed.emit())
	buttons.add_child(restore)

	var close := _button("Back to puzzles", 24)
	close.custom_minimum_size = Vector2(260, 72)
	close.pressed.connect(func() -> void: closed.emit())
	buttons.add_child(close)

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

		var name_lbl := _label("%s\n%s" % [p["name"], p["price"]], 24)
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_lbl)

		var btn := _button("", 24)
		btn.custom_minimum_size = Vector2(210, 60)
		if _iap.owns(p["id"]):
			btn.text = "Owned"
			btn.disabled = true
		else:
			btn.text = "Buy"
			var pid: String = p["id"]
			btn.pressed.connect(func() -> void: buy_pressed.emit(pid))
		row.add_child(btn)

		_list.add_child(row)

func flash(text: String) -> void:
	_toast.text = text
	_toast.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(0.9)
	tw.tween_property(_toast, "modulate:a", 0.0, 0.5)

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
