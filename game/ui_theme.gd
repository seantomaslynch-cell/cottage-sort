extends RefCounted
class_name UiTheme
## Builds the shared Godot Theme at runtime: rounded honey buttons with proper
## hover / pressed / disabled states, soft cards, warm text. Applied to the
## Window in main.gd so every Control picks it up.

static func build() -> Theme:
	var t := Theme.new()
	t.default_font_size = 26

	var normal := _sb(Palette.BTN, Palette.BTN_BORDER, 3)
	var hover := _sb(Palette.BTN_HOVER, Palette.ACCENT, 3)
	var pressed := _sb(Palette.BTN_PRESSED, Palette.ACCENT_WARM, 3)
	var disabled := _sb(Palette.BTN_DISABLED, Palette.BTN_BORDER, 2)
	disabled.bg_color.a = 0.7

	t.set_stylebox("normal", "Button", normal)
	t.set_stylebox("hover", "Button", hover)
	t.set_stylebox("pressed", "Button", pressed)
	t.set_stylebox("disabled", "Button", disabled)
	t.set_stylebox("focus", "Button", _sb(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0))
	t.set_color("font_color", "Button", Palette.INK)
	t.set_color("font_hover_color", "Button", Palette.INK)
	t.set_color("font_pressed_color", "Button", Palette.INK_DARK)
	t.set_color("font_disabled_color", "Button", Palette.INK_FAINT)
	t.set_color("font_focus_color", "Button", Palette.INK)

	var card := _sb(Palette.CARD, Palette.CARD_BORDER, 2, 20)
	t.set_stylebox("panel", "Panel", card)
	t.set_stylebox("panel", "PanelContainer", card)

	t.set_color("font_color", "Label", Palette.INK)

	return t

static func _sb(fill: Color, border: Color, border_w: int, radius: int = 16) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = border
	s.set_border_width_all(border_w)
	s.set_corner_radius_all(radius)
	s.content_margin_left = 18
	s.content_margin_right = 18
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	s.shadow_color = Color(0, 0, 0, 0.10)
	s.shadow_size = 3
	s.shadow_offset = Vector2(0, 2)
	return s
