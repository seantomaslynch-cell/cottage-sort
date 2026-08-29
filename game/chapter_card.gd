extends CanvasLayer
class_name ChapterCard
## A brief full-bleed card when a new chapter begins: the realm's palette, its
## name, and a line of flavour. Auto-dismisses; tap to skip. main calls show_card().

signal dismissed

var _bg: ColorRect
var _grad: Control
var _num: Label
var _name: Label
var _flavour: Label
var _root: Control
var _tw: Tween

func _ready() -> void:
	layer = 22
	visible = false

	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed:
			_finish())
	add_child(_root)

	_bg = ColorRect.new()
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(_bg)

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 10)
	box.custom_minimum_size = Vector2(600, 0)
	box.offset_left = -300.0
	box.offset_right = 300.0
	_root.add_child(box)

	_num = _mk(24, Palette.ACCENT_WARM)
	box.add_child(_num)
	_name = _mk(64, Palette.INK)
	box.add_child(_name)
	_flavour = _mk(24, Palette.INK)
	_flavour.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_flavour.custom_minimum_size = Vector2(600, 0)
	box.add_child(_flavour)

func show_card(chapter_index: int, realm: Dictionary) -> void:
	_num.text = "Chapter %d" % (chapter_index + 1)
	_name.text = str(realm.get("name", ""))
	_flavour.text = str(realm.get("flavour", ""))
	_bg.color = realm.get("bg_bot", Palette.BG_DEEP)
	visible = true
	_root.modulate.a = 0.0
	if _tw != null and _tw.is_valid():
		_tw.kill()
	_tw = create_tween()
	_tw.tween_property(_root, "modulate:a", 1.0, 0.35)
	_tw.tween_interval(2.0)
	_tw.tween_property(_root, "modulate:a", 0.0, 0.4)
	_tw.tween_callback(_finish)

func _finish() -> void:
	if not visible:
		return
	if _tw != null and _tw.is_valid():
		_tw.kill()
	visible = false
	dismissed.emit()

func _mk(size: int, col: Color) -> Label:
	var l := Label.new()
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	return l
