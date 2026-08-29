extends CanvasLayer
class_name Coach
## A single low-key coaching banner for the first few stages. main.gd calls
## show_tip() on load and clear() once the player has the idea.

var _panel: PanelContainer
var _label: Label

func _ready() -> void:
	layer = 12
	visible = false

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_TOP_WIDE)
	center.offset_top = 150.0
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	_panel = PanelContainer.new()
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Palette.CARD
	sb.border_color = Palette.ACCENT
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(16)
	sb.content_margin_left = 22
	sb.content_margin_right = 22
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	sb.shadow_color = Color(0, 0, 0, 0.12)
	sb.shadow_size = 6
	_panel.add_theme_stylebox_override("panel", sb)
	center.add_child(_panel)

	_label = Label.new()
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 24)
	_label.add_theme_color_override("font_color", Palette.INK)
	_label.custom_minimum_size = Vector2(560, 0)
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_panel.add_child(_label)

func show_tip(text: String) -> void:
	_label.text = text
	visible = true
	_panel.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_panel, "modulate:a", 1.0, 0.25)

func clear() -> void:
	if not visible:
		return
	var tw := create_tween()
	tw.tween_property(_panel, "modulate:a", 0.0, 0.3)
	tw.tween_callback(func() -> void: visible = false)
