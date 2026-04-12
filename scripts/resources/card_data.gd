extends Resource
## Data container for a single tarot card.

@export var card_id: String = ""
@export var card_name: String = ""
@export var card_number: int = 0
@export var suit: String = "major"  # major, cups, wands, swords, pentacles
@export var card_type: String = "major_arcana"  # major_arcana, minor_arcana
@export var base_insight: int = 0
@export var upright_keywords: String = ""
@export var reversed_keywords: String = ""
@export var upright_effect: String = ""
@export var reversed_effect: String = ""
@export var position_affinities: PackedStringArray = []
@export var veil_impact: int = 0
@export var texture_path: String = ""


static func from_dict(data: Dictionary) -> Resource:
	var script := load("res://scripts/resources/card_data.gd")
	var card: Resource = script.new()
	card.card_id = data.get("card_id", "")
	card.card_name = data.get("card_name", "")
	card.card_number = int(data.get("card_number", 0))
	card.suit = data.get("suit", "major")
	card.card_type = data.get("card_type", "major_arcana")
	card.base_insight = int(data.get("base_insight", 0))
	card.upright_keywords = data.get("upright_keywords", "")
	card.reversed_keywords = data.get("reversed_keywords", "")
	card.upright_effect = data.get("upright_effect", "")
	card.reversed_effect = data.get("reversed_effect", "")
	var affinities = data.get("position_affinities", [])
	if affinities is Array:
		card.position_affinities = PackedStringArray(affinities)
	card.veil_impact = int(data.get("veil_impact", 0))
	card.texture_path = data.get("texture_path", "")
	return card
