extends Node
class_name GameAds
## Rewarded-ad stub. Simulates a short ad and then grants the reward.
## Replace watch_rewarded()'s body with a real SDK call later; keep the shape:
## caller passes a Callable that runs only on a completed view.

signal rewarded_started
signal rewarded_finished(granted: bool)

var _busy := false

func watch_rewarded(on_reward: Callable) -> void:
	if _busy:
		return
	_busy = true
	rewarded_started.emit()
	await get_tree().create_timer(0.4).timeout
	_busy = false
	rewarded_finished.emit(true)
	if on_reward.is_valid():
		on_reward.call()
