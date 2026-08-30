extends SceneTree
## Rasterise store/icon.svg to the PNGs the iOS build + App Store listing need.
## Run: godot --headless --path . --script res://tools/make_icon.gd

func _initialize() -> void:
	var f := FileAccess.open("res://store/icon.svg", FileAccess.READ)
	if f == null:
		push_error("store/icon.svg not found")
		quit(1)
		return
	var svg := f.get_as_text()

	# 1024 master for App Store Connect (RGB8, no alpha — Apple requires opaque).
	var master := Image.new()
	if master.load_svg_from_string(svg, 1.0) != OK:
		push_error("SVG rasterise failed")
		quit(1)
		return
	if master.get_width() != 1024 or master.get_height() != 1024:
		master.resize(1024, 1024, Image.INTERPOLATE_LANCZOS)
	master.convert(Image.FORMAT_RGB8)
	master.save_png("res://store/icon_1024.png")
	print("wrote store/icon_1024.png  %dx%d" % [master.get_width(), master.get_height()])

	# In-project icon the Godot iOS/Android/Web export scales from (1024, alpha).
	var app := Image.new()
	app.load_svg_from_string(svg, 1.0)
	if app.get_width() != 1024:
		app.resize(1024, 1024, Image.INTERPOLATE_LANCZOS)
	app.save_png("res://icon.png")
	print("wrote icon.png  %dx%d" % [app.get_width(), app.get_height()])

	# keep the root icon.svg in sync with the store source
	var out := FileAccess.open("res://icon.svg", FileAccess.WRITE)
	out.store_string(svg)
	out = null
	print("synced icon.svg")

	quit()
