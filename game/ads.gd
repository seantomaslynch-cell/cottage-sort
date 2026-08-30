extends Node
class_name GameAds
## Ad provider. Two paths behind one API:
##   * simulated stub  — editor / web / headless, or when the plugin is off
##   * Google AdMob     — the cengiz-pz plugin (v4.0, iOS only) on a device build
## Callers only ever touch watch_rewarded() / maybe_show_interstitial() /
## interstitial_ready() / request_att() and the signals below. Rewarded videos
## are always offered (opt-in value even for payers); interstitials respect
## `remove_ads` and a cooldown.
##
## The Admob node degrades safely off-device: with no plugin singleton it just
## prints a notice and every call no-ops, so instantiating it anywhere is fine.

signal rewarded_started
signal rewarded_finished(granted: bool)
signal interstitial_shown
signal tracking_authorized(granted: bool)

const INTERSTITIAL_COOLDOWN_MS := 90_000

# The AdMob path only runs on an iOS device export (the plugin is iOS-only and
# its native singleton exists only there). Everywhere else -> the stub.
const USE_ADMOB_PLUGIN := true

var remove_ads := false

var _rewarded_busy := false
var _last_interstitial_ms := -INTERSTITIAL_COOLDOWN_MS
var _admob: Admob = null
var _sdk_ready := false
var _att_done := false

var _reward_earned := false
var _pending_reward := Callable()

func _ready() -> void:
	if USE_ADMOB_PLUGIN and OS.get_name() == "iOS":
		_init_admob()

func _is_mobile() -> bool:
	return OS.get_name() in ["Android", "iOS"]

# --- id selection ----------------------------------------------------------

## Test ads unless this is a genuine App Store build. A TestFlight build is a
## release build, so we also gate on Config.ADS_FORCE_TEST (see the note there).
func _is_real() -> bool:
	return not Config.ADS_FORCE_TEST and not OS.is_debug_build()

# --- plugin bootstrap ----------------------------------------------------------

func _init_admob() -> void:
	_admob = Admob.new()
	_admob.name = "Admob"
	_admob.is_real = _is_real()

	# Ad unit ids: the plugin picks real_* or debug_* off `is_real`.
	_admob.real_application_id = Config.ADMOB_APP_ID_IOS
	_admob.real_interstitial_id = Config.ADMOB_INTERSTITIAL_IOS
	_admob.real_rewarded_id = Config.ADMOB_REWARDED_IOS
	_admob.debug_application_id = Config.ADMOB_APP_ID_TEST_IOS
	_admob.debug_interstitial_id = Config.ADMOB_INTERSTITIAL_TEST_IOS
	_admob.debug_rewarded_id = Config.ADMOB_REWARDED_TEST_IOS

	# ATT + a 4+-appropriate content ceiling.
	_admob.att_enabled = true
	_admob.att_text = Config.ATT_USAGE_DESCRIPTION
	_admob.max_ad_content_rating = AdmobConfig.ContentRating.G

	for id in Config.ADMOB_TEST_DEVICE_IDS:
		pass   # test-device ids are applied via configure_ads(); see plugin

	_admob.initialization_completed.connect(_on_sdk_init)
	_admob.rewarded_ad_loaded.connect(_on_rewarded_loaded)
	_admob.rewarded_ad_failed_to_load.connect(_on_rewarded_failed)
	_admob.rewarded_ad_user_earned_reward.connect(_on_rewarded_earned)
	_admob.rewarded_ad_dismissed_full_screen_content.connect(_on_rewarded_closed)
	_admob.rewarded_ad_failed_to_show_full_screen_content.connect(_on_rewarded_show_failed)
	_admob.interstitial_ad_loaded.connect(_on_interstitial_loaded)
	_admob.interstitial_ad_dismissed_full_screen_content.connect(_on_interstitial_closed)
	_admob.tracking_authorization_granted.connect(_on_att_granted)
	_admob.tracking_authorization_denied.connect(_on_att_denied)
	_admob.consent_info_updated.connect(_on_consent_info)
	_admob.consent_form_dismissed.connect(func(_e = null) -> void: _refresh_ads())

	add_child(_admob)
	_admob.initialize()

func _on_sdk_init(_status = null) -> void:
	_sdk_ready = true
	# EEA/UK consent — best effort; ad loads don't block on it (the SDK serves
	# non-personalised ads until consent is obtained).
	if _admob != null and _admob.has_method("update_consent_info"):
		_admob.update_consent_info(ConsentRequestParameters.new())
	_refresh_ads()

func _on_consent_info(_a = null) -> void:
	if _admob != null and _admob.is_consent_form_available():
		_admob.load_consent_form()
		_admob.show_consent_form()

func _refresh_ads() -> void:
	if _admob == null:
		return
	if not _admob.is_rewarded_ad_loaded():
		_admob.load_rewarded_ad()
	if not _admob.is_interstitial_ad_loaded():
		_admob.load_interstitial_ad()

func _plugin_active() -> bool:
	return _admob != null and _sdk_ready

func _on_att_granted() -> void:
	tracking_authorized.emit(true)

func _on_att_denied() -> void:
	tracking_authorized.emit(false)

# --- rewarded --------------------------------------------------------------

func _on_rewarded_loaded(_ad_id := "") -> void:
	pass   # readiness is queried via _admob.is_rewarded_ad_loaded()

func _on_rewarded_failed(_ad_id := "", _err = null) -> void:
	pass

func _on_rewarded_earned(_ad_id := "", _reward = null) -> void:
	_reward_earned = true

func _on_rewarded_closed(_ad_id := "") -> void:
	_resolve_rewarded()

func _on_rewarded_show_failed(_ad_id := "", _err = null) -> void:
	_resolve_rewarded()

func _resolve_rewarded() -> void:
	var granted := _reward_earned
	var cb := _pending_reward
	_pending_reward = Callable()
	_rewarded_busy = false
	rewarded_finished.emit(granted)
	if granted and cb.is_valid():
		cb.call()
	if _admob != null:
		_admob.load_rewarded_ad()   # prefetch the next

func watch_rewarded(on_reward: Callable) -> void:
	if _rewarded_busy:
		return
	_rewarded_busy = true
	rewarded_started.emit()

	if _plugin_active() and _admob.is_rewarded_ad_loaded():
		_reward_earned = false
		_pending_reward = on_reward
		_admob.show_rewarded_ad()
		return   # _on_rewarded_closed resolves it

	# No plugin, or no ad filled: don't punish the player for a fill gap —
	# grant the reward as the stub always has, after a short beat.
	if _plugin_active():
		push_warning("rewarded ad not ready; granting reward without an ad")
		_admob.load_rewarded_ad()
	await get_tree().create_timer(0.4).timeout
	_rewarded_busy = false
	rewarded_finished.emit(true)
	if on_reward.is_valid():
		on_reward.call()

# --- interstitial --------------------------------------------------------------

func _on_interstitial_loaded(_ad_id := "") -> void:
	pass

func _on_interstitial_closed(_ad_id := "") -> void:
	if _admob != null:
		_admob.load_interstitial_ad()

func interstitial_ready() -> bool:
	if remove_ads:
		return false
	return Time.get_ticks_msec() - _last_interstitial_ms >= INTERSTITIAL_COOLDOWN_MS

func maybe_show_interstitial() -> void:
	if not interstitial_ready():
		return
	_last_interstitial_ms = Time.get_ticks_msec()

	if _plugin_active() and _admob.is_interstitial_ad_loaded():
		_admob.show_interstitial_ad()
		interstitial_shown.emit()
		return

	# Stub / not filled: fire the signal so the HUD's "Ad" beat still plays; a
	# missed interstitial is harmless.
	if _plugin_active():
		_admob.load_interstitial_ad()
	interstitial_shown.emit()

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
