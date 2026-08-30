extends Node
class_name Economy
## Coin balance + cottage upgrade ownership, persisted through SaveData.
## Emits signals so the HUD and cottage screen can refresh.

signal coins_changed(total: int)
signal gems_changed(total: int)
signal changed
signal set_completed(set_name: String, bonus: int)

func coins() -> int:
	return int(SaveData.data.get("coins", 0))

func gems() -> int:
	return int(SaveData.data.get("gems", 0))

func add_gems(n: int) -> void:
	if n == 0:
		return
	SaveData.data["gems"] = maxi(0, gems() + n)
	SaveData.save_now()
	gems_changed.emit(gems())
	changed.emit()

func spend_gems(n: int) -> bool:
	if gems() < n:
		return false
	SaveData.data["gems"] = gems() - n
	SaveData.save_now()
	gems_changed.emit(gems())
	changed.emit()
	return true

# --- piggy bank ----------------------------------------------------------------

const PIGGY_MAX := 250        # base cap
const PIGGY_MAX_BIG := 500    # after the first crack — whales fill + crack it again

func piggy() -> int:
	return int(SaveData.data.get("piggy", 0))

## The current cap: it grows the first time the bank is cracked.
func piggy_max() -> int:
	return PIGGY_MAX_BIG if bool(SaveData.data.get("piggy_cracked_once", false)) else PIGGY_MAX

func piggy_add(n: int) -> void:
	var v := mini(piggy_max(), piggy() + n)
	if v == piggy():
		return
	SaveData.data["piggy"] = v
	SaveData.save_now()
	changed.emit()

func piggy_full() -> bool:
	return piggy() >= piggy_max()

## Empty the bank and return what was in it (call after the IAP succeeds).
func piggy_crack() -> int:
	var amt := piggy()
	SaveData.data["piggy"] = 0
	SaveData.data["piggy_cracked_once"] = true
	SaveData.save_now()
	changed.emit()
	return amt

# --- booster inventory -------------------------------------------------------

func booster_count(id: String) -> int:
	return int((SaveData.data.get("boosters", {}) as Dictionary).get(id, 0))

func add_booster(id: String, n: int) -> void:
	var b: Dictionary = SaveData.data.get("boosters", {})
	b[id] = maxi(0, int(b.get(id, 0)) + n)
	SaveData.data["boosters"] = b
	SaveData.save_now()
	changed.emit()

func use_booster(id: String) -> bool:
	if booster_count(id) <= 0:
		return false
	add_booster(id, -1)
	return true

func add_coins(n: int) -> void:
	if n == 0:
		return
	SaveData.data["coins"] = maxi(0, coins() + n)
	if n > 0:
		SaveData.data["stat_coins_earned"] = int(SaveData.data.get("stat_coins_earned", 0)) + n
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

# --- decor (the endless coin sink) -----------------------------------------

func decor_owned() -> Array:
	return SaveData.data.get("decor", [])

func owns_decor(id: String) -> bool:
	return id in decor_owned()

func decor_count() -> int:
	return decor_owned().size()

func _endless_bought() -> int:
	var n := 0
	for id in decor_owned():
		if str(id).begins_with("sundry_"):
			n += 1
	return n

## The next Sundries item on offer — always unowned, always pricier.
func next_endless() -> Dictionary:
	return DecorData.endless_item(_endless_bought())

func set_progress(set_name: String) -> Vector2i:
	var items := DecorData.set_items(set_name)
	if items.is_empty():
		return Vector2i.ZERO
	var have := 0
	for it in items:
		if owns_decor(it["id"]):
			have += 1
	return Vector2i(have, items.size())

func sets_complete_count() -> int:
	return (SaveData.data.get("decor_sets_done", []) as Array).size()

func can_buy_decor(id: String) -> bool:
	var it := DecorData.item(id)
	return not it.is_empty() and not owns_decor(id) and coins() >= int(it["cost"])

func buy_decor(id: String) -> bool:
	if not can_buy_decor(id):
		return false
	var it := DecorData.item(id)
	SaveData.data["coins"] = coins() - int(it["cost"])
	var owned: Array = decor_owned()
	owned.append(id)
	SaveData.data["decor"] = owned

	var set_name: String = it.get("set", "")
	var newly_done := ""
	if not DecorData.set_items(set_name).is_empty() and set_name != DecorData.ENDLESS_SET:
		var done: Array = SaveData.data.get("decor_sets_done", [])
		if not set_name in done and _set_full(set_name):
			done.append(set_name)
			SaveData.data["decor_sets_done"] = done
			newly_done = set_name

	SaveData.save_now()
	coins_changed.emit(coins())
	changed.emit()
	if newly_done != "":
		set_completed.emit(newly_done, DecorData.SET_BONUS)
	return true

func _set_full(set_name: String) -> bool:
	var items := DecorData.set_items(set_name)
	if items.is_empty():
		return false
	for it in items:
		if not owns_decor(it["id"]):
			return false
	return true
