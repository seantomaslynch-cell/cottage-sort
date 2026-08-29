extends CanvasLayer
class_name GameHUD
## Placeholder HUD built from code: top bar (level, moves, mute, restart),
## bottom bar (undo, add jar, levels), a fading toast, and a win overlay.

signal restart_pressed
signal next_pressed
signal undo_pressed
signal add_jar_pressed
signal levels_pressed
signal mute_toggled(muted: bool)

var _level_label: Label
var _moves_label: Label
var _mute_btn: Button
var _undo_btn: Button
var _addjar_btn: Button
var _toast: Label
var _win_root: Control
var _win_label: Label
var _win_best: Label
var _muted := false

func _ready() -> void:
	layer = 10

	var top := HBoxContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 24.0
	top.offset_right = -24.0
	top.offset_top = 26.0
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_theme_constant_override("separation", 14)
	add_child(top)

	_level_label = _label("Level 1")
	top.add_child(_level_label)
	_moves_label = _label("Moves: 0")
	top.add_child(_moves_label)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)

	_mute_btn = _button("Sound: on")
	_mute_btn.pressed.connect(_on_mute)
	top.add_child(_mute_btn)

	var restart_btn := _button("Restart")
	restart_btn.pressed.connect(func() -> void: restart_pressed.emit())
	top.add_child(restart_btn)

	var bottom := HBoxContainer.new()
	bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_left = 24.0
	bottom.offset_right = -24.0
	bottom.offset_top = -104.0
	bottom.offset_bottom = -28.0
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_theme_constant_override("separation", 18)
	add_child(bottom)

	_undo_btn = _button("Undo")
	_undo_btn.custom_minimum_size = Vector2(150, 72)
	_undo_btn.pressed.connect(func() -> void: undo_pressed.emit())
	bottom.add_child(_undo_btn)

	_addjar_btn = _button("Add jar")
	_addjar_btn.custom_minimum_size = Vector2(150, 72)
	_addjar_btn.pressed.connect(func() -> void: add_jar_pressed.emit())
	bottom.add_child(_addjar_btn)

	var levels_btn := _button("Levels")
	levels_btn.custom_minimum_size = Vector2(150, 72)
	levels_btn.pressed.connect(func() -> void: levels_pressed.emit())
	bottom.add_child(levels_btn)

	_toast = _label("")
	_toast.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_toast.offset_top = 92.0
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.modulate.a = 0.0
	add_child(_toast)

	_build_win_overlay()

func _build_win_overlay() -> void:
	_win_root = Control.new()
	_win_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_win_root.visible = false
	add_child(_win_root)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.36, 0.27, 0.21, 0.55)
	_win_root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_win_root.add_child(center)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(box)

	_win_label = _label("Cottage corner tidied!")
	_win_label.add_theme_font_size_override("font_size", 44)
	_win_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_win_label)

	_win_best = _label("")
	_win_best.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_win_best)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	box.add_child(row)

	var levels_btn := _button("Levels")
	levels_btn.custom_minimum_size = Vector2(180, 72)
	levels_btn.pressed.connect(func() -> void: levels_pressed.emit())
	row.add_child(levels_btn)

	var next_btn := _button("Next")
	next_btn.custom_minimum_size = Vector2(180, 72)
	next_btn.pressed.connect(func() -> void: next_pressed.emit())
	row.add_child(next_btn)

func _label(t: String) -> Label:
	var l := Label.new()
	l.text = t
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", 32)
	l.add_theme_color_override("font_color", Color("5b4636"))
	return l

func _button(t: String) -> Button:
	var b := Button.new()
	b.text = t
	b.add_theme_font_size_override("font_size", 26)
	return b

func _on_mute() -> void:
	_muted = not _muted
	set_muted(_muted)
	mute_toggled.emit(_muted)

func set_muted(m: bool) -> void:
	_muted = m
	_mute_btn.text = "Sound: off" if m else "Sound: on"

func set_level(n: int) -> void:
	_level_label.text = "Level %d" % n

func set_moves(n: int) -> void:
	_moves_label.text = "Moves: %d" % n

func set_undo_enabled(v: bool) -> void:
	_undo_btn.disabled = not v

func set_addjar_enabled(v: bool) -> void:
	_addjar_btn.disabled = not v

func flash(text: String) -> void:
	_toast.text = text
	_toast.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(0.9)
	tw.tween_property(_toast, "modulate:a", 0.0, 0.5)

func show_win(text: String, best: int, current: int) -> void:
	_win_label.text = text
	if best > 0 and current > best:
		_win_best.text = "Solved in %d moves  (best %d)" % [current, best]
	else:
		_win_best.text = "Solved in %d moves  -  new best!" % current
	_win_root.visible = true

func hide_win() -> void:
	_win_root.visible = false
