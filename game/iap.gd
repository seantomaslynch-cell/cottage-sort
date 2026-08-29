extends Node
class_name GameIap
## In-app purchase provider. Stub: purchase() pretends the store dialog
## succeeded. Replace its body with a real store call later and keep the shape;
## `purchased(id)` is the single place that grants an entitlement / fires a
## coin grant (main.gd listens and credits Economy).

signal purchased(product_id: String)
signal restored

const PRODUCTS: Array[Dictionary] = [
	{"id": "remove_ads",   "name": "Remove interstitial ads", "price": "$2.99", "kind": "entitlement"},
	{"id": "coins_small",  "name": "Pouch of coins (500)",    "price": "$0.99", "kind": "coins", "amount": 500},
	{"id": "coins_medium", "name": "Bag of coins (1500)",     "price": "$3.99", "kind": "coins", "amount": 1500},
	{"id": "coins_large",  "name": "Chest of coins (5000)",   "price": "$9.99", "kind": "coins", "amount": 5000},
]

func product(id: String) -> Dictionary:
	for p in PRODUCTS:
		if p["id"] == id:
			return p
	return {}

func has_remove_ads() -> bool:
	return bool(SaveData.data.get("remove_ads", false))

func owns(id: String) -> bool:
	return id == "remove_ads" and has_remove_ads()

func purchase(id: String) -> void:
	var p := product(id)
	if p.is_empty():
		return
	if p.get("kind") == "entitlement":
		SaveData.data["remove_ads"] = true
		SaveData.save_now()
	purchased.emit(id)

func restore() -> void:
	# Stub: entitlements already live in the local save; a real impl would
	# query the store and re-apply them here.
	restored.emit()
