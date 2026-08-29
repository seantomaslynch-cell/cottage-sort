extends Node
class_name GameIap
## In-app purchase provider. Stub: purchase() pretends the store dialog
## succeeded. Replace its body with a real store call later and keep the shape;
## `purchased(id)` is the single place that grants an entitlement / fires a
## coin grant (main.gd listens and credits Economy).

signal purchased(product_id: String)
signal restored

const PRODUCTS: Array[Dictionary] = [
	{"id": "starter_pack",  "name": "Starter pack", "price": "$2.99", "kind": "bundle",
		"gems": 120, "coins": 800, "remove_ads": true},
	{"id": "struggle_pack", "name": "Struggle pack", "price": "$0.99", "kind": "struggle",
		"gems": 40, "coins": 300, "moves": 8},
	{"id": "booster_bundle", "name": "Booster bundle (4 of each)", "price": "$3.99",
		"kind": "boosters", "each": 4},
	{"id": "piggy_crack",   "name": "Crack the piggy bank",   "price": "$4.99", "kind": "piggy"},
	{"id": "remove_ads",   "name": "Remove interstitial ads", "price": "$2.99", "kind": "entitlement"},
	{"id": "gems_small",   "name": "Handful of gems (80)",    "price": "$1.99", "kind": "gems",  "amount": 80},
	{"id": "gems_medium",  "name": "Pouch of gems (250)",     "price": "$4.99", "kind": "gems",  "amount": 250},
	{"id": "gems_large",   "name": "Chest of gems (700)",     "price": "$9.99", "kind": "gems",  "amount": 700},
	{"id": "coins_small",  "name": "Pouch of coins (500)",    "price": "$0.99", "kind": "coins", "amount": 500},
	{"id": "coins_medium", "name": "Bag of coins (1500)",     "price": "$3.99", "kind": "coins", "amount": 1500},
]

func product(id: String) -> Dictionary:
	for p in PRODUCTS:
		if p["id"] == id:
			return p
	return {}

func has_remove_ads() -> bool:
	return bool(SaveData.data.get("remove_ads", false))

func owns(id: String) -> bool:
	if id == "remove_ads":
		return has_remove_ads()
	if id == "starter_pack":
		return bool(SaveData.data.get("starter_bought", false))
	return false

func purchase(id: String) -> void:
	var p := product(id)
	if p.is_empty():
		return
	if p.get("kind") == "entitlement":
		SaveData.data["remove_ads"] = true
		SaveData.save_now()
	elif p.get("kind") == "bundle":
		if bool(p.get("remove_ads", false)):
			SaveData.data["remove_ads"] = true
		SaveData.data["starter_bought"] = true
		SaveData.save_now()
	purchased.emit(id)

func restore() -> void:
	# Stub: entitlements already live in the local save; a real impl would
	# query the store and re-apply them here.
	restored.emit()
