extends CanvasLayer
class_name LevelSelect
## Overlay grid of stages. A dot marks a cleared stage. Emits picked(index).

signal picked(stage_index: int)
signal closed

var _grid: GridContainer

func _ready() -> void:
	layer = 20
	visible = false

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.20, 0.15, 0.12, 0.78)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 22)
	center.add_child(box)

	var title := Label.new()
	title.text = "Choose a corner"
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color("f3e9d8"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	_grid = GridContainer.new()
	_grid.columns = 4
	_grid.add_theme_constant_override("h_separation", 16)
	_grid.add_theme_constant_override("v_separation", 16)
	box.add_child(_grid)

	var close := Button.new()
	close.text = "Close"
	close.add_theme_font_size_override("font_size", 26)
	close.pressed.connect(_on_close)
	box.add_child(close)

func open(total: int) -> void:
	for c in _grid.get_children():
		c.queue_free()
	for i in total:
		var b := Button.new()
		if SaveData.is_complete(i):
			b.text = "%d\n%s" % [i + 1, _stars(SaveData.stars(i))]
		else:
			b.text = str(i + 1)
		b.custom_minimum_size = Vector2(104, 96)
		b.add_theme_font_size_override("font_size", 24)
		var idx := i
		b.pressed.connect(func() -> void:
			visible = false
			picked.emit(idx))
		_grid.add_child(b)
	visible = true

func _on_close() -> void:
	visible = false
	closed.emit()

func _stars(n: int) -> String:
	var s := ""
	for i in 3:
		s += "*" if i < n else "."
	return s
