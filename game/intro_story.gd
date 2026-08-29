extends CanvasLayer
class_name IntroStory
## One warm paragraph, shown once, the first time a new player presses Play.
## "Begin" dismisses it for good (SaveData.story_seen).

signal begun

var _root: Control

func _ready() -> void:
	layer = 31
	visible = false

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Palette.BG
	add_child(bg)

	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 26)
	box.custom_minimum_size = Vector2(560, 0)
	box.offset_left = -280.0
	box.offset_right = 280.0
	box.offset_top = -240.0
	_root.add_child(box)

	var head := _label("Gran's cottage", 40, Palette.INK)
	box.add_child(head)

	var body := _label(
		"She left it to you — roof sagging, garden gone wild, a sleepy cat "
		+ "who came with the place and won't be moved.\n\n"
		+ "A good sort-out and it'll be home again. One shelf at a time.",
		24, Palette.INK)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(560, 0)
	box.add_child(body)

	var begin := _button("Begin", 28)
	begin.custom_minimum_size = Vector2(260, 78)
	begin.pressed.connect(_finish)
	box.add_child(begin)

func show_story() -> void:
	visible = true
	_root.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_root, "modulate:a", 1.0, 0.4)

func _finish() -> void:
	SaveData.data["story_seen"] = true
	SaveData.save_now()
	visible = false
	begun.emit()

func _label(t: String, fs: int, col: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", col)
	return l

func _button(t: String, fs: int) -> Button:
	var b := Button.new()
	b.text = t
	b.add_theme_font_size_override("font_size", fs)
	return b
