extends Node
class_name Economy
## Coin balance + cottage upgrade ownership, persisted through SaveData.
## Emits signals so the HUD and cottage screen can refresh.

signal coins_changed(total: int)
signal changed

func coins() -> int:
	return int(SaveData.data.get("coins", 0))

func add_coins(n: int) -> void:
	if n == 0:
		return
	SaveData.data["coins"] = maxi(0, coins() + n)
	SaveData.save_now()
	coins_changed.emit(coins())
	changed.emit()

func tier(slot_id: String) -> int:
	return int((SaveData.data.get("upgrades", {}) as Dictionary).get(slot_id, 0))

func next_cost(slot_id: String) -> int:
	return CottageData.cost(slot_id, tier(slot_id))

func is_maxed(slot_id: String) -> bool:
	return tier(slot_id) >= CottageData.max_tier(slot_id)

func can_buy(slot_id: String) -> bool:
	var c := next_cost(slot_id)
	return c >= 0 and coins() >= c

func buy(slot_id: String) -> bool:
	if not can_buy(slot_id):
		return false
	var c := next_cost(slot_id)
	SaveData.data["coins"] = coins() - c
	var ups: Dictionary = SaveData.data.get("upgrades", {})
	ups[slot_id] = tier(slot_id) + 1
	SaveData.data["upgrades"] = ups
	SaveData.save_now()
	coins_changed.emit(coins())
	changed.emit()
	return true

## 0.0 (run-down) .. 1.0 (fully restored) across every tier of every slot.
func restored_fraction() -> float:
	var have := 0
	for s in CottageData.SLOTS:
		have += tier(s["id"])
	return float(have) / float(maxi(1, CottageData.total_tiers()))
