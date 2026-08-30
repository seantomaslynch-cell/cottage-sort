extends SceneTree
## Headless checks for SaveData load + the version/migration hook. Backs up and
## restores the real save file so running it doesn't clobber a player's save.
## Run: godot --headless --path . --script res://tools/test_save.gd

var _fails := 0

func _ok(cond: bool, msg: String) -> void:
	if cond:
		print("  ok  ", msg)
	else:
		_fails += 1
		push_error("FAIL: " + msg)

func _path() -> String:
	return ProjectSettings.globalize_path(SaveData.PATH)

func _write(raw: String) -> void:
	var f := FileAccess.open(SaveData.PATH, FileAccess.WRITE)
	f.store_string(raw)
	f = null

func _disk() -> Dictionary:
	var f := FileAccess.open(SaveData.PATH, FileAccess.READ)
	var p: Variant = JSON.parse_string(f.get_as_text())
	return p if typeof(p) == TYPE_DICTIONARY else {}

func _initialize() -> void:
	var had := FileAccess.file_exists(SaveData.PATH)
	var backup := ""
	if had:
		backup = FileAccess.open(SaveData.PATH, FileAccess.READ).get_as_text()

	print("defaults:")
	_ok(int(SaveData.data.get("save_version", -1)) == SaveData.CURRENT_SAVE_VERSION,
		"defaults carry the current save_version")

	print("legacy save (no version) migrates:")
	SaveData.data["muted"] = false
	SaveData.data["sfx_on"] = true
	SaveData.data["coins"] = 0
	_write('{"muted": true, "coins": 500, "future_key": 7}')
	SaveData.load_now()
	_ok(int(SaveData.data["save_version"]) == SaveData.CURRENT_SAVE_VERSION, "stamped to the current version")
	_ok(SaveData.data["sfx_on"] == false, "legacy `muted` folded into sfx_on")
	_ok(int(SaveData.data["coins"]) == 500, "real values preserved through the merge")
	_ok(int(SaveData.data.get("future_key", 0)) == 7, "unknown keys kept (forward-compatible)")
	_ok(int(_disk().get("save_version", 0)) == SaveData.CURRENT_SAVE_VERSION, "migration wrote the version back to disk")

	print("current save loads without a rewrite:")
	SaveData.data["coins"] = 0
	_write('{"save_version": %d, "coins": 123}' % SaveData.CURRENT_SAVE_VERSION)
	var before := FileAccess.get_modified_time(_path())
	SaveData.load_now()
	_ok(int(SaveData.data["coins"]) == 123, "value loaded")
	_ok(int(SaveData.data["save_version"]) == SaveData.CURRENT_SAVE_VERSION, "still current")
	_ok(FileAccess.get_modified_time(_path()) == before, "no needless disk write on an up-to-date save")

	print("missing file is a safe no-op:")
	DirAccess.remove_absolute(_path())
	SaveData.data["coins"] = 42
	SaveData.load_now()
	_ok(int(SaveData.data["coins"]) == 42, "load_now() with no file leaves data untouched")

	if had:
		FileAccess.open(SaveData.PATH, FileAccess.WRITE).store_string(backup)
	else:
		if FileAccess.file_exists(SaveData.PATH):
			DirAccess.remove_absolute(_path())

	if _fails == 0:
		print("\nALL PASS")
		quit(0)
	else:
		print("\n%d FAILURE(S)" % _fails)
		quit(1)
