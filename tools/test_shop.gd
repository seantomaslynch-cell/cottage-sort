extends SceneTree
## Headless checks for the IAP stub and interstitial gating.
## Run: godot --headless --path . --script res://tools/test_shop.gd

const IapS := preload("res://game/iap.gd")
const AdsS := preload("res://game/ads.gd")

var _fails := 0

func _ok(cond: bool, msg: String) -> void:
	if cond:
		print("  ok  ", msg)
	else:
		_fails += 1
		push_error("FAIL: " + msg)

func _initialize() -> void:
	var had := FileAccess.file_exists(SaveData.PATH)
	var backup := ""
	if had:
		backup = FileAccess.open(SaveData.PATH, FileAccess.READ).get_as_text()
	SaveData.data["remove_ads"] = false
	SaveData.data["coins"] = 0

	print("iap:")
	var iap: GameIap = IapS.new()
	_ok(not iap.owns("remove_ads"), "remove_ads not owned initially")
	_ok(not iap.has_remove_ads(), "has_remove_ads false initially")
	var got := [""]
	iap.purchased.connect(func(id: String) -> void: got[0] = id)
	iap.purchase("remove_ads")
	_ok(got[0] == "remove_ads", "purchased signal fired")
	_ok(iap.has_remove_ads(), "remove_ads owned after purchase")
	_ok(bool(SaveData.data["remove_ads"]), "save flag persisted")
	var cp := iap.product("coins_medium")
	_ok(cp.get("kind") == "coins" and int(cp.get("amount", 0)) == 1500, "coins_medium product shape")
	_ok(iap.product("nope").is_empty(), "unknown product -> empty")
	iap.free()

	print("interstitial gating:")
	var ads: GameAds = AdsS.new()
	var shown := [0]
	ads.interstitial_shown.connect(func() -> void: shown[0] += 1)
	ads.remove_ads = true
	ads.maybe_show_interstitial()
	_ok(shown[0] == 0, "suppressed when remove_ads owned")
	ads.remove_ads = false
	ads._last_interstitial_ms = -1_000_000
	ads.maybe_show_interstitial()
	_ok(shown[0] == 1, "shows once cooldown elapsed")
	ads.maybe_show_interstitial()
	_ok(shown[0] == 1, "second call suppressed by cooldown")
	ads.free()

	if had:
		FileAccess.open(SaveData.PATH, FileAccess.WRITE).store_string(backup)
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveData.PATH))

	if _fails == 0:
		print("\nALL PASS")
		quit(0)
	else:
		print("\n%d FAILURE(S)" % _fails)
		quit(1)
