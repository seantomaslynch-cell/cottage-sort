extends SceneTree
## Composite raw game captures (tools/screenshot.gd -> store/raw/*.png, 720x1280)
## into 1290x2796 App Store screenshots with a headline and a framed device shot.
## Run WITHOUT --headless (needs a renderer):
##   godot --path . --script res://tools/make_store_shots.gd

const W := 1290
const H := 2796
const FONT := "res://game/assets/fonts/Fredoka.ttf"

const SHOTS := [
	{"src": "board_12",   "title": "Pour colours together\nuntil every jar is tidy"},
	{"src": "board_38",   "title": "Chase the glowing\ncolour for a bonus"},
	{"src": "cottage",    "title": "Every clear rebuilds\nGran's cottage"},
	{"src": "collection", "title": "Collect decor and\nfill every room"},
	{"src": "daily",      "title": "Daily rewards, streaks\nand a weekly event"},
]

var _font: FontFile
var _vp: SubViewport
var _root: Control
var _i := 0

func _initialize() -> void:
	_font = load(FONT)
	_vp = SubViewport.new()
	_vp.size = Vector2i(W, H)
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(_vp)
	_root = Control.new()
	_root.size = Vector2(W, H)
	_vp.add_child(_root)
	_render_next.call_deferred()

func _render_next() -> void:
	if _i >= SHOTS.size():
		quit()
		return
	var shot: Dictionary = SHOTS[_i]
	for c in _root.get_children():
		_root.remove_child(c)
		c.queue_free()
	_build(shot)
	await process_frame
	await process_frame
	await process_frame
	var img := _vp.get_texture().get_image()
	img.convert(Image.FORMAT_RGB8)
	var out := "res://store/screenshots/%02d_%s.png" % [_i + 1, shot["src"]]
	img.save_png(out)
	print("wrote ", out, "  ", img.get_size())
	_i += 1
	_render_next.call_deferred()

func _build(shot: Dictionary) -> void:
	var grad := Gradient.new()
	grad.set_color(0, Color("f6ecda"))
	grad.set_color(1, Color("e5d3b2"))
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill_to = Vector2(0, 1)
	gt.width = W
	gt.height = H
	var bg := TextureRect.new()
	bg.texture = gt
	bg.size = Vector2(W, H)
	_root.add_child(bg)

	var title := Label.new()
	title.text = shot["title"]
	title.add_theme_font_override("font", _font)
	title.add_theme_font_size_override("font_size", 94)
	title.add_theme_color_override("font_color", Color("5b4636"))
	title.add_theme_constant_override("line_spacing", 14)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(95, 156)
	title.size = Vector2(W - 190, 360)
	_root.add_child(title)

	var raw := Image.load_from_file("res://store/raw/%s.png" % shot["src"])
	var tex := ImageTexture.create_from_image(raw)
	var shot_w := 1140.0
	var scale := shot_w / float(raw.get_width())
	var shot_h := float(raw.get_height()) * scale   # keep the real aspect — no stretch
	var x := (W - shot_w) * 0.5
	var y := 512.0

	var shadow := ColorRect.new()
	shadow.color = Color(0.29, 0.22, 0.14, 0.20)
	shadow.position = Vector2(x - 16, y + 24)
	shadow.size = Vector2(shot_w + 32, shot_h + 32)
	_root.add_child(shadow)

	var frame := ColorRect.new()
	frame.color = Color("b0906a")
	frame.position = Vector2(x - 9, y - 9)
	frame.size = Vector2(shot_w + 18, shot_h + 18)
	_root.add_child(frame)

	var pic := TextureRect.new()
	pic.texture = tex
	pic.position = Vector2(x, y)
	pic.size = Vector2(shot_w, shot_h)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_SCALE
	_root.add_child(pic)

	var mark := Label.new()
	mark.text = "Cottage Sort"
	mark.add_theme_font_override("font", _font)
	mark.add_theme_font_size_override("font_size", 60)
	mark.add_theme_color_override("font_color", Color("a8977f"))
	mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mark.position = Vector2(0, y + shot_h + 58)
	mark.size = Vector2(W, 84)
	_root.add_child(mark)
