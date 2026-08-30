extends Node
class_name GameAds
## Ad provider. Two paths behind one API:
##   * simulated stub  — editor / web / headless, or when the plugin is off
##   * Google AdMob     — the cengiz-pz plugin, when USE_ADMOB_PLUGIN is on and
##                        the addon is present on a mobile export
## Callers only ever touch watch_rewarded() / maybe_show_interstitial() /
## interstitial_ready() / request_att() and the signals below. Rewarded videos
## are always offered (opt-in value even for payers); interstitials respect
## `remove_ads` and a cooldown.
##
## API NOTE — the plugin calls below assume the cengiz-pz godot-admob-plugin
## (addon-iface-v2). Confirm these names against the installed version before
## flipping USE_ADMOB_PLUGIN; any missing method/signal just falls back to the
## stub (has_method / has_signal guards everywhere):
##   node       : Admob (scene under addons/AdmobPlugin/)
##   methods    : initialize(), load_rewarded_ad(), show_rewarded_ad(),
##                load_interstitial_ad(), show_interstitial_ad(),
##                request_tracking_authorization()
##   signals    : initialization_completed,
##                rewarded_ad_loaded, rewarded_ad_failed_to_load,
##                rewarded_ad_user_earned_reward,
##                rewarded_ad_dismissed_full_screen_content,
##                rewarded_ad_failed_to_show_full_screen_content,
##                interstitial_ad_loaded, interstitial_ad_failed_to_load,
##                interstitial_ad_dismissed_full_screen_content,
##                tracking_authorization_granted / _denied

signal rewarded_started
signal rewarded_finished(granted: bool)
signal interstitial_shown
signal tracking_authorized(granted: bool)

const INTERSTITIAL_COOLDOWN_MS := 90_000

# --- Real AdMob plugin (github.com/cengiz-pz) -------------------------------
# Binaries land in addons/AdmobPlugin/ via tools/fetch_assets.*. Built against
# Godot 4.4.1 (addon interface v2); flip this to true only after a CI/device
# export confirms the addon loads on this Godot build. Everything degrades to
# the simulated stub when it's false or the addon is absent.
const USE_ADMOB_PLUGIN := false
const ADMOB_ADDON_CFG := "res://addons/AdmobPlugin/plugin.cfg"

var remove_ads := false

var _rewarded_busy := false
var _last_interstitial_ms := -INTERSTITIAL_COOLDOWN_MS
var _admob: Node = null
var _sdk_ready := false
var _att_done := false

var _rewarded_ready := false
var _interstitial_ready := false
var _reward_earned := false
var _pending_reward := Callable()

func _ready() -> void:
	if USE_ADMOB_PLUGIN and _is_mobile() and ResourceLoader.exists(ADMOB_ADDON_CFG):
		_init_admob()

func _is_mobile() -> bool:
	return OS.get_name() in ["Android", "iOS"]

# --- id selection ----------------------------------------------------------

## Test ads in debug builds — tapping a live ad you served yourself gets the
## AdMob account banned. Also forced when the platform's prod id is still the
## placeholder (e.g. an Android build before real ids are added).
func _use_test_ads() -> bool:
	if OS.is_debug_build():
		return true
	var prod := _prod_unit("rewarded")
	return prod == "" or prod.begins_with("ca-app-pub-0000")

func _prod_unit(kind: String) -> String:
	var ios := OS.get_name() == "iOS"
	match kind:
		"rewarded":
			return Config.ADMOB_REWARDED_IOS if ios else Config.ADMOB_REWARDED_ANDROID
		"interstitial":
			return Config.ADMOB_INTERSTITIAL_IOS if ios else Config.ADMOB_INTERSTITIAL_ANDROID
	return ""

func _test_unit(kind: String) -> String:
	var ios := OS.get_name() == "iOS"
	match kind:
		"rewarded":
			return Config.ADMOB_REWARDED_TEST_IOS if ios else Config.ADMOB_REWARDED_TEST_ANDROID
		"interstitial":
			return Config.ADMOB_INTERSTITIAL_TEST_IOS if ios else Config.ADMOB_INTERSTITIAL_TEST_ANDROID
	return ""

func _unit(kind: String) -> String:
	return _test_unit(kind) if _use_test_ads() else _prod_unit(kind)

func _app_id() -> String:
	var ios := OS.get_name() == "iOS"
	if _use_test_ads():
		return Config.ADMOB_APP_ID_TEST_IOS if ios else Config.ADMOB_APP_ID_TEST_ANDROID
	return Config.ADMOB_APP_ID_IOS if ios else Config.ADMOB_APP_ID_ANDROID

# --- plugin bootstrap ----------------------------------------------------------

func _init_admob() -> void:
	for p in ["res://addons/AdmobPlugin/Admob.tscn", "res://addons/AdmobPlugin/admob.tscn"]:
		if ResourceLoader.exists(p):
			_admob = (load(p) as PackedScene).instantiate()
			break
	if _admob == null:
		push_warning("AdmobPlugin present but no Admob scene found; staying on stub")
		return
	add_child(_admob)

	# Some plugin versions want the unit ids set as node properties; others read
	# an AdmobConfig resource from Project Settings. Set what we can, ignore the
	# rest.
	for prop_pair in [
			["rewarded_id", _unit("rewarded")], ["rewarded_ad_id", _unit("rewarded")],
			["interstitial_id", _unit("interstitial")], ["interstitial_ad_id", _unit("interstitial")],
			["is_real", not _use_test_ads()]]:
		if prop_pair[0] in _admob:
			_admob.set(prop_pair[0], prop_pair[1])

	_connect(_admob, "initialization_completed", _on_sdk_init)
	_connect(_admob, "rewarded_ad_loaded", _on_rewarded_loaded)
	_connect(_admob, "rewarded_ad_failed_to_load", _on_rewarded_failed)
	_connect(_admob, "rewarded_ad_user_earned_reward", _on_rewarded_earned)
	_connect(_admob, "rewarded_ad_dismissed_full_screen_content", _on_rewarded_closed)
	_connect(_admob, "rewarded_ad_failed_to_show_full_screen_content", _on_rewarded_closed)
	_connect(_admob, "interstitial_ad_loaded", _on_interstitial_loaded)
	_connect(_admob, "interstitial_ad_failed_to_load", _on_interstitial_failed)
	_connect(_admob, "interstitial_ad_dismissed_full_screen_content", _on_interstitial_closed)
	_connect(_admob, "interstitial_ad_failed_to_show_full_screen_content", _on_interstitial_closed)
	_connect(_admob, "tracking_authorization_granted", _on_att_granted)
	_connect(_admob, "tracking_authorization_denied", _on_att_denied)

	if _admob.has_method("initialize"):
		_admob.initialize()
	else:
		_on_sdk_init()   # older plugins initialise implicitly

func _connect(obj: Object, sig: String, fn: Callable) -> void:
	if obj.has_signal(sig) and not obj.is_connected(sig, fn):
		obj.connect(sig, fn)

func _on_sdk_init(_status = null) -> void:
	_sdk_ready = true
	_load_rewarded()
	_load_interstitial()

func _on_att_granted(_a = null) -> void:
	tracking_authorized.emit(true)

func _on_att_denied(_a = null) -> void:
	tracking_authorized.emit(false)

func _plugin_active() -> bool:
	return _admob != null and _sdk_ready

func _load_rewarded() -> void:
	_rewarded_ready = false
	if _admob != null and _admob.has_method("load_rewarded_ad"):
		_admob.load_rewarded_ad()

func _load_interstitial() -> void:
	_interstitial_ready = false
	if _admob != null and _admob.has_method("load_interstitial_ad"):
		_admob.load_interstitial_ad()

func _on_rewarded_loaded(_a = null) -> void:
	_rewarded_ready = true

func _on_rewarded_failed(_a = null, _b = null) -> void:
	_rewarded_ready = false

func _on_rewarded_earned(_a = null, _b = null) -> void:
	_reward_earned = true

func _on_rewarded_closed(_a = null, _b = null) -> void:
	var granted := _reward_earned
	var cb := _pending_reward
	_pending_reward = Callable()
	_rewarded_busy = false
	rewarded_finished.emit(granted)
	if granted and cb.is_valid():
		cb.call()
	_load_rewarded()   # prefetch the next one

func _on_interstitial_loaded(_a = null) -> void:
	_interstitial_ready = true

func _on_interstitial_failed(_a = null, _b = null) -> void:
	_interstitial_ready = false

func _on_interstitial_closed(_a = null, _b = null) -> void:
	_interstitial_ready = false
	_load_interstitial()

# --- ATT ---------------------------------------------------------------------

## Apple's App Tracking Transparency prompt, once, before the first ad request.
## No-op on Android / web / desktop and when the plugin isn't active.
func request_att() -> void:
	if _att_done:
		return
	_att_done = true
	if _admob != null and _admob.has_method("request_tracking_authorization"):
		_admob.request_tracking_authorization()
	else:
		tracking_authorized.emit(true)   # nothing to ask; treat as allowed

# --- rewarded --------------------------------------------------------------

func watch_rewarded(on_reward: Callable) -> void:
	if _rewarded_busy:
		return
	_rewarded_busy = true
	rewarded_started.emit()

	if _plugin_active() and _rewarded_ready and _admob.has_method("show_rewarded_ad"):
		_reward_earned = false
		_pending_reward = on_reward
		_admob.show_rewarded_ad()
		return   # _on_rewarded_closed resolves it

	# No plugin, or no ad filled: don't punish the player for a fill gap —
	# grant the reward as the stub always has, after a short beat.
	if _plugin_active():
		push_warning("rewarded ad not ready; granting reward without an ad")
	await get_tree().create_timer(0.4).timeout
	_rewarded_busy = false
	rewarded_finished.emit(true)
	if on_reward.is_valid():
		on_reward.call()

# --- interstitial --------------------------------------------------------------

func interstitial_ready() -> bool:
	if remove_ads:
		return false
	return Time.get_ticks_msec() - _last_interstitial_ms >= INTERSTITIAL_COOLDOWN_MS

func maybe_show_interstitial() -> void:
	if not interstitial_ready():
		return
	_last_interstitial_ms = Time.get_ticks_msec()

	if _plugin_active() and _interstitial_ready and _admob.has_method("show_interstitial_ad"):
		_admob.show_interstitial_ad()
		interstitial_shown.emit()
		return

	# Stub / not filled: fire the signal so the HUD's "Ad" beat still plays; a
	# missed interstitial is harmless.
	interstitial_shown.emit()
