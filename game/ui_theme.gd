extends RefCounted
class_name UiTheme
## Builds the shared Godot Theme at runtime: rounded honey buttons with proper
## hover / pressed / disabled states, soft cards, warm text. Applied to the
## Window in main.gd so every Control picks it up.

const FONT_PATH := "res://game/assets/fonts/Fredoka.ttf"

static func build() -> Theme:
	var t := Theme.new()
	t.default_font_size = 26

	# Cozy rounded UI face (SIL OFL). Falls back to Godot's default if the asset
	# pack hasn't been fetched yet — see tools/fetch_assets.{sh,ps1}.
	if ResourceLoader.exists(FONT_PATH):
		var base := load(FONT_PATH)
		if base is Font:
			var fv := FontVariation.new()
			fv.base_font = base as Font
			fv.variation_opentype = {"wght": 480}
			t.default_font = fv
			t.set_font("font", "Button", fv)
			t.set_font("font", "Label", fv)

	# Buttons get a thicker bottom border — a soft "lip" that reads as a raised
	# key; on press the lip shrinks so the button visibly sinks.
	var normal := _sb(Palette.BTN, Palette.BTN_BORDER, 2)
	_lip(normal, 5)
	var hover := _sb(Palette.BTN_HOVER, Palette.ACCENT, 2)
	_lip(hover, 5)
	var pressed := _sb(Palette.BTN_PRESSED, Palette.ACCENT_WARM, 2)
	_lip(pressed, 1)
	pressed.content_margin_top = 12
	pressed.content_margin_bottom = 8
	var disabled := _sb(Color(Palette.BTN_DISABLED, 0.7), Palette.BTN_BORDER, 2)
	disabled.shadow_size = 0

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

	var card := _sb(Palette.CARD, Palette.CARD_BORDER, 2, 22)
	card.shadow_size = 10
	card.shadow_color = Color(Palette.INK_DARK.r, Palette.INK_DARK.g, Palette.INK_DARK.b, 0.10)
	card.shadow_offset = Vector2(0, 4)
	card.border_color = Palette.CARD_BORDER.lerp(Palette.ACCENT_WARM, 0.12)
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
	s.anti_aliasing = true
	s.content_margin_left = 18
	s.content_margin_right = 18
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	s.shadow_color = Color(0, 0, 0, 0.10)
	s.shadow_size = 4
	s.shadow_offset = Vector2(0, 3)
	return s

## Thicken the bottom border and darken it a touch for a raised-key look.
static func _lip(s: StyleBoxFlat, px: int) -> void:
	s.border_width_bottom = px
	s.border_color = s.border_color.darkened(0.06)
