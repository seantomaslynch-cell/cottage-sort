extends SceneTree
## M37: the intro story shows once and sets `story_seen`; the cottage cat exists
## and `celebrate()` is safe to call. Backs up / restores save.json.

var _backup := ""
var _had := false

func _initialize() -> void:
	_had = FileAccess.file_exists(SaveData.PATH)
	if _had:
		_backup = FileAccess.open(SaveData.PATH, FileAccess.READ).get_as_text()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveData.PATH))
	change_scene_to_file("res://game/main.tscn")
	_run.call_deferred()

func _run() -> void:
	await create_timer(0.5).timeout
	var fails := 0
	var story := _find(get_root(), "IntroStory")
	var cat := _find(get_root(), "CottageCat")
	if story == null or cat == null:
		push_error("IntroStory / CottageCat not found"); _restore(); quit(1); return

	if bool(SaveData.data.get("story_seen", false)):
		fails += 1; push_error("story_seen already true on a fresh save")

	var begun := [false]
	story.begun.connect(func() -> void: begun[0] = true)
	story.show_story()
	if not story.visible:
		fails += 1; push_error("story card not visible after show_story()")
	story._finish()
	await create_timer(0.1).timeout
	if story.visible:
		fails += 1; push_error("story card still visible after Begin")
	if not bool(SaveData.data.get("story_seen", false)):
		fails += 1; push_error("story_seen not saved after Begin")
	if not begun[0]:
		fails += 1; push_error("begun signal not emitted")

	# the cat should draw + celebrate without error
	cat.visible = true
	cat.celebrate()
	await create_timer(0.1).timeout

	if int(SaveData.data.get("cat_gift_day", -1)) != -1:
		fails += 1; push_error("cat_gift_day not -1 on a fresh save")

	_restore()
	if fails == 0:
		print("\nALL PASS  (intro story one-shot + cat companion)")
		quit(0)
	else:
		print("\n%d FAILURE(S)" % fails)
		quit(1)

func _restore() -> void:
	if _had:
		FileAccess.open(SaveData.PATH, FileAccess.WRITE).store_string(_backup)
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveData.PATH))

func _find(n: Node, cls: String) -> Node:
	var s: Script = n.get_script()
	if s != null and String(s.get_global_name()) == cls:
		return n
	for c in n.get_children():
		var r := _find(c, cls)
		if r: return r
	return null
