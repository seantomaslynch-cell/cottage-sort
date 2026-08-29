extends Node
class_name GameAds
## Ad provider. Today this is a stub that simulates ads; swap the bodies of
## watch_rewarded() / maybe_show_interstitial() for a real SDK later and keep the
## signatures. Rewarded videos are always offered (they're opt-in value even for
## payers); interstitials respect `remove_ads` and a cooldown.

signal rewarded_started
signal rewarded_finished(granted: bool)
signal interstitial_shown

const INTERSTITIAL_COOLDOWN_MS := 90_000

var remove_ads := false

var _rewarded_busy := false
var _last_interstitial_ms := -INTERSTITIAL_COOLDOWN_MS

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
