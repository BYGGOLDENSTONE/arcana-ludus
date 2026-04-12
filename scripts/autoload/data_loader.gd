extends Node
## Loads card/spread/talisman definitions from JSON data files.

const CardDataScript = preload("res://scripts/resources/card_data.gd")
const CARD_DEFINITIONS_PATH := "res://assets/data/card_definitions.json"

var _cards: Dictionary = {}  # card_id -> CardData


func _ready() -> void:
	_load_card_definitions()


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
