extends CanvasLayer
class_name CottageScreen
## Your Cottage. Two tabs over the same drawing:
##   Restore  — the 5 structural upgrade slots (a finite "100%" goal)
##   Decorate — an endless decor catalog + collection sets (the coin sink)

signal buy_pressed(slot_id: String)
signal decor_buy_pressed(decor_id: String)
signal mystery_pressed
signal closed

const CottageViewScene := preload("res://game/cottage_view.gd")

var economy: Economy = null

var _title: Label
var _coins: Label
var _view: CottageView
var _tab := "restore"
var _tab_restore: Button
var _tab_decor: Button
var _slots_box: VBoxContainer
var _decor_scroll: ScrollContainer
var _decor_list: VBoxContainer
var _toast: Label

func _ready() -> void:
	layer = 15
	visible = false

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Palette.BG
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
	_view.offset_top = 82.0
	_view.offset_bottom = 82.0 + 400.0
	_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_view)

	var tabs := HBoxContainer.new()
	tabs.set_anchors_preset(Control.PRESET_TOP_WIDE)
	tabs.offset_top = 496.0
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs.add_theme_constant_override("separation", 12)
	add_child(tabs)
	_tab_restore = _button("Restore", 24)
	_tab_restore.custom_minimum_size = Vector2(190, 58)
	_tab_restore.pressed.connect(func() -> void: _show_tab("restore"))
	tabs.add_child(_tab_restore)
	_tab_decor = _button("Decorate", 24)
	_tab_decor.custom_minimum_size = Vector2(190, 58)
	_tab_decor.pressed.connect(func() -> void: _show_tab("decorate"))
	tabs.add_child(_tab_decor)

	_slots_box = VBoxContainer.new()
	_slots_box.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_slots_box.offset_left = 24.0
	_slots_box.offset_right = -24.0
	_slots_box.offset_top = -708.0
	_slots_box.offset_bottom = -150.0
	_slots_box.add_theme_constant_override("separation", 10)
	add_child(_slots_box)

	_decor_scroll = ScrollContainer.new()
	_decor_scroll.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_decor_scroll.offset_left = 24.0
	_decor_scroll.offset_right = -24.0
	_decor_scroll.offset_top = 566.0
	_decor_scroll.anchor_bottom = 1.0
	_decor_scroll.offset_bottom = -150.0
	_decor_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_decor_scroll.visible = false
	add_child(_decor_scroll)
	_decor_list = VBoxContainer.new()
	_decor_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_decor_list.add_theme_constant_override("separation", 8)
	_decor_scroll.add_child(_decor_list)

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
	_toast.add_theme_color_override("font_color", Palette.ACCENT_WARM)
	_toast.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_toast.offset_top = 524.0
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.modulate.a = 0.0
	add_child(_toast)

func set_economy(e: Economy) -> void:
	economy = e
	_view.economy = e

func open() -> void:
	visible = true
	_show_tab(_tab)

func _show_tab(which: String) -> void:
	_tab = which
	var on_restore := which == "restore"
	_slots_box.visible = on_restore
	_decor_scroll.visible = not on_restore
	_tab_restore.disabled = on_restore
	_tab_decor.disabled = not on_restore
	refresh()

func refresh() -> void:
	if economy == null:
		return
	_coins.text = "Coins: %d" % economy.coins()
	_title.text = "Your Cottage  -  %d%% restored" % roundi(economy.restored_fraction() * 100.0)
	_view.refresh()
	if _tab == "restore":
		_refresh_restore()
	else:
		_refresh_decor()

func _refresh_restore() -> void:
	_clear(_slots_box)
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

		row.add_child(_grow())

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

func _refresh_decor() -> void:
	_clear(_decor_list)

	var summary := _label("Decor collected: %d      Sets complete: %d / %d" % [
		economy.decor_count(), economy.sets_complete_count(), DecorData.SETS.size()], 22)
	summary.add_theme_color_override("font_color", Palette.INK_FAINT)
	_decor_list.add_child(summary)

	for set_name in DecorData.set_names():
		var pr := economy.set_progress(set_name)
		_decor_list.add_child(_set_header("%s   (%d / %d)" % [set_name, pr.x, pr.y]))
		for it in DecorData.SETS[set_name]:
			_decor_list.add_child(_decor_row(it))

	_decor_list.add_child(_set_header("%s   (never ends)" % DecorData.ENDLESS_SET))
	_decor_list.add_child(_decor_row(economy.next_endless()))

func _decor_row(it: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var name_lbl := _label(it["name"], 24)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_lbl)

	var id: String = it["id"]
	var btn := _button("", 22)
	btn.custom_minimum_size = Vector2(200, 56)
	if economy.owns_decor(id):
		btn.text = "Owned"
		btn.disabled = true
	else:
		btn.text = "Buy  %d" % int(it["cost"])
		btn.disabled = not economy.can_buy_decor(id)
		btn.pressed.connect(func() -> void: decor_buy_pressed.emit(id))
	row.add_child(btn)
	return row

func flash(text: String) -> void:
	_toast.text = text
	_toast.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(1.0)
	tw.tween_property(_toast, "modulate:a", 0.0, 0.5)

func _set_header(text: String) -> Label:
	var l := _label(text, 22)
	l.add_theme_color_override("font_color", Palette.ACCENT_WARM)
	return l

func _clear(node: Node) -> void:
	for c in node.get_children():
		node.remove_child(c)
		c.queue_free()

func _grow() -> Control:
	var c := Control.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return c

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
	l.add_theme_color_override("font_color", Palette.INK)
	return l

func _button(t: String, fs: int) -> Button:
	var b := Button.new()
	b.text = t
	b.add_theme_font_size_override("font_size", fs)
	return b
