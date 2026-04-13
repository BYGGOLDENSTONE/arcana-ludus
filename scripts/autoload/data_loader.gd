extends Node
## Loads card/spread/talisman definitions from JSON data files.

const CardDataScript = preload("res://scripts/resources/card_data.gd")
const TalismanDataScript = preload("res://scripts/resources/talisman_data.gd")
const CARD_DEFINITIONS_PATH := "res://assets/data/card_definitions.json"
const TALISMAN_DEFINITIONS_PATH := "res://assets/data/talisman_definitions.json"

var _cards: Dictionary = {}  # card_id -> CardData
var _talismans: Dictionary = {}  # talisman_id -> TalismanData


func _ready() -> void:
	_load_card_definitions()
	_load_talisman_definitions()


func _load_card_definitions() -> void:
	if not FileAccess.file_exists(CARD_DEFINITIONS_PATH):
		push_error("DataLoader: card_definitions.json not found at %s" % CARD_DEFINITIONS_PATH)
		return

	var file := FileAccess.open(CARD_DEFINITIONS_PATH, FileAccess.READ)
	var json_text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var err := json.parse(json_text)
	if err != OK:
		push_error("DataLoader: JSON parse error at line %d: %s" % [json.get_error_line(), json.get_error_message()])
		return

	var data: Dictionary = json.data
	var cards_array: Array = data.get("cards", [])

	for card_dict: Dictionary in cards_array:
		var card = CardDataScript.from_dict(card_dict)
		_cards[card.card_id] = card

	print("DataLoader: Loaded %d cards" % _cards.size())


func _load_talisman_definitions() -> void:
	if not FileAccess.file_exists(TALISMAN_DEFINITIONS_PATH):
		push_error("DataLoader: talisman_definitions.json not found at %s" % TALISMAN_DEFINITIONS_PATH)
		return

	var file := FileAccess.open(TALISMAN_DEFINITIONS_PATH, FileAccess.READ)
	var json_text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var err := json.parse(json_text)
	if err != OK:
		push_error("DataLoader: Talisman JSON parse error: %s" % json.get_error_message())
		return

	var data: Dictionary = json.data
	var talismans_array: Array = data.get("talismans", [])

	for t_dict: Dictionary in talismans_array:
		var talisman = TalismanDataScript.from_dict(t_dict)
		_talismans[talisman.talisman_id] = talisman

	print("DataLoader: Loaded %d talismans" % _talismans.size())


func get_talisman(talisman_id: String) -> Resource:
	if _talismans.has(talisman_id):
		return _talismans[talisman_id]
	push_warning("DataLoader: Talisman '%s' not found" % talisman_id)
	return null


func get_all_talismans() -> Array:
	var result: Array = []
	for t in _talismans.values():
		result.append(t)
	return result


func get_talismans_by_tier(tier: String) -> Array:
	var result: Array = []
	for t in _talismans.values():
		if t.tier == tier:
			result.append(t)
	return result


func get_shop_talismans(count: int = 3) -> Array:
	## Returns a random selection of talismans for the shop.
	## Weighted by tier: common 60%, uncommon 30%, rare 10%.
	var pool: Array = []
	for t in _talismans.values():
		# Skip already owned
		if TalismanManager.has_talisman(t.effect_id):
			continue
		match t.tier:
			"common": pool.append_array([t, t, t])  # 3x weight
			"uncommon": pool.append_array([t, t])     # 2x weight
			"rare": pool.append(t)                     # 1x weight
	pool.shuffle()
	var result: Array = []
	var seen: Dictionary = {}
	for t in pool:
		if not seen.has(t.talisman_id):
			seen[t.talisman_id] = true
			result.append(t)
			if result.size() >= count:
				break
	return result


func get_card(card_id: String) -> Resource:
	if _cards.has(card_id):
		return _cards[card_id]
	push_warning("DataLoader: Card '%s' not found" % card_id)
	return null


func get_all_cards() -> Array:
	var result: Array = []
	for card in _cards.values():
		result.append(card)
	return result


func get_cards_by_suit(suit: String) -> Array:
	var result: Array = []
	for card in _cards.values():
		if card.suit == suit:
			result.append(card)
	return result


func get_cards_by_type(card_type: String) -> Array:
	var result: Array = []
	for card in _cards.values():
		if card.card_type == card_type:
			result.append(card)
	return result


func get_demo_deck() -> Array:
	## Returns the 62 demo cards: 22 Major Arcana + 40 Minor Arcana (Ace-10).
	var result: Array = []
	for card in _cards.values():
		result.append(card)
	return result


func get_starting_deck() -> Array:
	var result: Array = []
	for card in _cards.values():
		if card.card_type == "major_arcana":
			result.append(card)
	return result
