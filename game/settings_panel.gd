extends CanvasLayer
class_name SettingsPanel
## Settings screen — same shell as Cottage / Shop. Sound, music, haptics
## toggles, restore purchases, and a credits / privacy line.

signal flag_toggled(key: String, value: bool)
signal restore_pressed
signal closed

var _rows: Dictionary = {}   # key -> Button
var _note: Label

func _ready() -> void:
	layer = 19
	visible = false

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Palette.BG
	add_child(bg)

	var title := _label("Settings", 34)
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_left = 24.0
	title.offset_top = 24.0
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_child(title)

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_TOP_WIDE)
	box.offset_left = 40.0
	box.offset_right = -40.0
	box.offset_top = 110.0
	box.add_theme_constant_override("separation", 14)
	add_child(box)

	box.add_child(_toggle_row("sfx_on", "Sound effects"))
	box.add_child(_toggle_row("music_on", "Music"))
	box.add_child(_toggle_row("haptics_on", "Haptics (vibration)"))

	var restore := _button("Restore purchases", 24)
	restore.custom_minimum_size = Vector2(0, 64)
	restore.pressed.connect(func() -> void: restore_pressed.emit())
	box.add_child(restore)

	var credits := _label(
		"Cottage Sort  ·  a cozy sort-and-restore puzzle.\nPrivacy policy: (link goes here at launch)", 17)
	credits.add_theme_color_override("font_color", Palette.INK_FAINT)
	credits.set_anchors_preset(Control.PRESET_TOP_WIDE)
	credits.offset_top = 430.0
	credits.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(credits)

	_note = _label("", 24)
	_note.add_theme_color_override("font_color", Palette.ACCENT_WARM)
	_note.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_note.offset_top = 360.0
	_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_note.modulate.a = 0.0
	add_child(_note)

	var back := _button("Back to puzzles", 24)
	back.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	back.offset_left = 200.0
	back.offset_right = -200.0
	back.offset_top = -110.0
	back.offset_bottom = -42.0
	back.pressed.connect(func() -> void: closed.emit())
	add_child(back)

func note(text: String) -> void:
	_note.text = text
	_note.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(1.0)
	tw.tween_property(_note, "modulate:a", 0.0, 0.5)

func set_flags(sfx: bool, music: bool, haptics: bool) -> void:
	_set_row("sfx_on", sfx)
	_set_row("music_on", music)
	_set_row("haptics_on", haptics)

func open() -> void:
	visible = true

func _toggle_row(key: String, text: String) -> Button:
	var b := _button("%s:  On" % text, 24)
	b.custom_minimum_size = Vector2(0, 66)
	b.set_meta("label", text)
	b.set_meta("on", true)
	b.pressed.connect(func() -> void:
		var on: bool = not bool(b.get_meta("on"))
		_apply_row(b, on)
		flag_toggled.emit(key, on))
	_rows[key] = b
	return b

func _set_row(key: String, on: bool) -> void:
	if _rows.has(key):
		_apply_row(_rows[key], on)

func _apply_row(b: Button, on: bool) -> void:
	b.set_meta("on", on)
	b.text = "%s:  %s" % [b.get_meta("label"), "On" if on else "Off"]

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
