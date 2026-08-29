extends CanvasLayer
class_name HomeScreen
## The front door. Title, the cottage as a living backdrop, a big Play button,
## and shortcuts to the meta screens. Shown on launch; Play drops into the
## current level. main owns the wiring.

signal play_pressed
signal cottage_pressed
signal daily_pressed
signal shop_pressed
signal season_pressed
signal settings_pressed

const CottageViewScene := preload("res://game/cottage_view.gd")

var economy: Economy = null

var _view: CottageView
var _play: Button
var _sub: Label
var _stats: Label
var _row: HBoxContainer
var _daily_btn: Button
var _new_player := true

func _ready() -> void:
	layer = 30
	visible = false

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Palette.BG
	add_child(bg)

	var title := _label("Cottage Sort", 60, Palette.INK)
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 60.0
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)

	_sub = _label("sort it out · settle in", 22, Palette.INK_FAINT)
	_sub.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_sub.offset_top = 138.0
	_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_sub)

	_view = CottageViewScene.new()
	_view.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_view.offset_top = 178.0
	_view.offset_bottom = 178.0 + 384.0
	_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_view)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_TOP_WIDE)
	center.offset_top = 700.0
	add_child(center)
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 22)
	center.add_child(col)

	_play = _button("Play", 30)
	_play.custom_minimum_size = Vector2(320, 88)
	_play.pressed.connect(func() -> void: play_pressed.emit())
	col.add_child(_play)

	_row = HBoxContainer.new()
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_row.add_theme_constant_override("separation", 12)
	col.add_child(_row)
	for spec in [
		["Cottage", cottage_pressed], ["Daily", daily_pressed],
		["Shop", shop_pressed], ["Season", season_pressed],
		["Settings", settings_pressed],
	]:
		var b := _button(spec[0], 20)
		b.custom_minimum_size = Vector2(126, 58)
		var sig: Signal = spec[1]
		b.pressed.connect(func() -> void: sig.emit())
		_row.add_child(b)
		if spec[0] == "Daily":
			_daily_btn = b

	_stats = _label("", 20, Palette.INK_FAINT)
	_stats.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_stats.offset_top = -70.0
	_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_stats)

func set_economy(e: Economy) -> void:
	economy = e
	_view.economy = e

## stage is 0-based; levels_cleared / stars for the stats line.
func configure(stage: int, levels_cleared: int, stars: int, daily_pending: bool) -> void:
	_new_player = levels_cleared == 0
	_play.text = "Start" if _new_player else "Play  ·  Level %d" % (stage + 1)
	_sub.text = "a run-down cottage, and time to tidy" if _new_player else "sort it out · settle in"
	_row.visible = not _new_player
	if _new_player:
		_stats.text = ""
	else:
		_stats.text = "%d corners tidied   ·   %d★   ·   %d%% restored" % [
			levels_cleared, stars,
			roundi(economy.restored_fraction() * 100.0) if economy != null else 0]
	if _daily_btn != null:
		_daily_btn.text = "Daily !" if daily_pending else "Daily"

func open() -> void:
	visible = true
	_view.refresh()

func close() -> void:
	visible = false

func _label(t: String, size: int, col: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	return l

func _button(t: String, size: int) -> Button:
	var b := Button.new()
	b.text = t
	b.add_theme_font_size_override("font_size", size)
	return b
