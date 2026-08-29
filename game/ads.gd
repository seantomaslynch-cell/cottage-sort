extends Node
class_name GameAds
## Ad provider. Today this is a stub that simulates ads; swap the bodies of
## watch_rewarded() / maybe_show_interstitial() for a real SDK later and keep the
## signatures. Rewarded videos are always offered (they're opt-in value even for
## payers); interstitials respect `remove_ads` and a cooldown.

signal rewarded_started
signal rewarded_finished(granted: bool)
signal interstitial_shown
signal tracking_authorized(granted: bool)

const INTERSTITIAL_COOLDOWN_MS := 90_000

# --- Real AdMob plugin (github.com/cengiz-pz) -------------------------------
# The plugin binaries land in addons/AdmobPlugin/ via tools/fetch_assets.*.
# They are built against Godot 4.4.1 (addon interface v2); flip this to true
# only after a CI/device export has confirmed the addon loads on this Godot
# build. Everything below degrades to the simulated stub when it's false or
# the addon is absent — editor, web and headless are unaffected either way.
const USE_ADMOB_PLUGIN := false
const ADMOB_ADDON_CFG := "res://addons/AdmobPlugin/plugin.cfg"

var remove_ads := false

var _rewarded_busy := false
var _last_interstitial_ms := -INTERSTITIAL_COOLDOWN_MS
var _admob: Node = null
var _att_done := false

func _ready() -> void:
	if USE_ADMOB_PLUGIN and _is_mobile() and ResourceLoader.exists(ADMOB_ADDON_CFG):
		_init_admob()

func _is_mobile() -> bool:
	return OS.get_name() in ["Android", "iOS"]

func _init_admob() -> void:
	# The cengiz plugin ships an `Admob` node. Instance whatever entry point the
	# addon provides; guard every call so a shape mismatch can't crash the game.
	for p in ["res://addons/AdmobPlugin/Admob.tscn", "res://addons/AdmobPlugin/admob.tscn"]:
		if ResourceLoader.exists(p):
			_admob = (load(p) as PackedScene).instantiate()
			break
	if _admob == null:
		push_warning("AdmobPlugin present but no Admob scene found; staying on stub")
		return
	add_child(_admob)
	if _admob.has_signal("tracking_authorization_granted"):
		_admob.tracking_authorization_granted.connect(func() -> void:
			tracking_authorized.emit(true))
	if _admob.has_signal("tracking_authorization_denied"):
		_admob.tracking_authorization_denied.connect(func() -> void:
			tracking_authorized.emit(false))
	if _admob.has_method("initialize"):
		_admob.initialize()

## Present Apple's App Tracking Transparency prompt once, before the first ad
## request. No-op on Android / web / desktop and when the plugin isn't active.
func request_att() -> void:
	if _att_done:
		return
	_att_done = true
	if _admob != null and _admob.has_method("request_tracking_authorization"):
		_admob.request_tracking_authorization()
	else:
		tracking_authorized.emit(true)  # nothing to ask; treat as allowed

func watch_rewarded(on_reward: Callable) -> void:
	if _rewarded_busy:
		return
	_rewarded_busy = true
	rewarded_started.emit()
	await get_tree().create_timer(0.4).timeout
	_rewarded_busy = false
	rewarded_finished.emit(true)
	if on_reward.is_valid():
		on_reward.call()

func interstitial_ready() -> bool:
	if remove_ads:
		return false
	return Time.get_ticks_msec() - _last_interstitial_ms >= INTERSTITIAL_COOLDOWN_MS

func maybe_show_interstitial() -> void:
	if not interstitial_ready():
		return
	_last_interstitial_ms = Time.get_ticks_msec()
	interstitial_shown.emit()
