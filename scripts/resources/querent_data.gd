extends Resource
## Data container for a single querent (client) who requests a tarot reading.

@export var querent_id: String = ""
@export var querent_name: String = ""
@export var question_text: String = ""
@export var question_theme: String = ""  # love, career, money, conflict, spiritual, health, creative
@export var personality_type: String = ""  # curious, believer, skeptic, desperate, shadowed, serene, secretive
@export var target_score: int = 0
@export var gold_reward: int = 0
@export var primary_suit_bonus: String = ""
@export var secondary_suit_bonus: String = ""
@export var special_condition: String = ""
@export var personality_modifier: Dictionary = {}


static func from_dict(data: Dictionary) -> Resource:
	var script := load("res://scripts/resources/querent_data.gd")
	var querent: Resource = script.new()
	querent.querent_id = data.get("querent_id", "")
	querent.querent_name = data.get("querent_name", "")
	querent.question_text = data.get("question_text", "")
	querent.question_theme = data.get("question_theme", "")
	querent.personality_type = data.get("personality_type", "")
	querent.target_score = int(data.get("target_score", 0))
	querent.gold_reward = int(data.get("gold_reward", 0))
	querent.primary_suit_bonus = data.get("primary_suit_bonus", "")
	querent.secondary_suit_bonus = data.get("secondary_suit_bonus", "")
	querent.special_condition = data.get("special_condition", "")
	querent.personality_modifier = data.get("personality_modifier", {})
	return querent
