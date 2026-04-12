class_name QuerentGenerator
## Generates randomized querents with personality, theme, and scaling difficulty.

const QuerentDataScript = preload("res://scripts/resources/querent_data.gd")

const FIRST_NAMES: PackedStringArray = [
	"Elena", "Marcus", "Celeste", "Orion", "Isadora",
	"Felix", "Mirabel", "Dorian", "Sage", "Leander",
	"Thalia", "Cassius", "Ivy", "Rowan", "Seraphina",
]

const TITLES: PackedStringArray = [
	"the Wanderer", "the Scholar", "the Merchant", "the Lover", "the Widow",
	"the Sailor", "the Herbalist", "the Knight", "the Dreamer", "the Stranger",
]

const QUESTION_POOLS: Dictionary = {
	"love": [
		"Will I find love?",
		"Is this relationship right for me?",
		"Does my heart lead true?",
	],
	"career": [
		"Should I take this new path?",
		"Will my venture succeed?",
		"Am I meant for greater things?",
	],
	"money": [
		"Will fortune smile upon me?",
		"Should I risk my savings?",
		"Is prosperity near?",
	],
	"conflict": [
		"How do I resolve this dispute?",
		"Should I fight or yield?",
		"Who speaks the truth?",
	],
	"spiritual": [
		"What is my true purpose?",
		"How do I find inner peace?",
		"What does the universe ask of me?",
	],
	"health": [
		"Will I recover?",
		"How can I find balance?",
		"What ails my spirit?",
	],
	"creative": [
		"Should I pursue my art?",
		"Will my creation be worthy?",
		"Where does inspiration hide?",
	],
}

const THEME_SUIT_MAP: Dictionary = {
	"love": {"primary": "cups", "secondary": "wands"},
	"career": {"primary": "wands", "secondary": "pentacles"},
	"money": {"primary": "pentacles", "secondary": "cups"},
	"conflict": {"primary": "swords", "secondary": "wands"},
	"spiritual": {"primary": "major", "secondary": ""},
	"health": {"primary": "pentacles", "secondary": "cups"},
	"creative": {"primary": "wands", "secondary": "cups"},
}

const PERSONALITY_MODIFIERS: Dictionary = {
	"curious": {"target_score_multiplier": 0.85, "variety_bonus": true},
	"believer": {"veil_bonus_multiplier": 1.5},
	"skeptic": {"target_score_multiplier": 1.20, "veil_bonuses_disabled": true},
	"desperate": {"target_score_multiplier": 1.40, "reward_multiplier": 3.0},
	"shadowed": {"starting_veil": 3, "reward_type": "talisman"},
	"serene": {"reversed_veil": false},
	"secretive": {"hidden_positions": 2},
}


static func generate(night_number: int, querent_index: int) -> Resource:
	var first_name: String = FIRST_NAMES[randi() % FIRST_NAMES.size()]
	var title: String = TITLES[randi() % TITLES.size()]
	var full_name := "%s, %s" % [first_name, title]

	var themes: Array = QUESTION_POOLS.keys()
	var theme: String = themes[randi() % themes.size()]
	var questions: Array = QUESTION_POOLS[theme]
	var question: String = questions[randi() % questions.size()]

	var personality: String = _weighted_random(_get_personality_weights(night_number))
	var modifier: Dictionary = PERSONALITY_MODIFIERS.get(personality, {})

	# Target scales by night, small random variance within a night (not by querent_index)
	var base_target := 120 + night_number * 100
	var variance := randi_range(-15, 15)
	var target_score := int((base_target + variance) * modifier.get("target_score_multiplier", 1.0))

	# Base gold scales by night; bonus gold from score excess handled by NightManager
	var gold_reward := int((15 + night_number * 8) * modifier.get("reward_multiplier", 1.0))
	if personality == "shadowed":
		gold_reward = 0

	var suit_info: Dictionary = THEME_SUIT_MAP.get(theme, {"primary": "", "secondary": ""})

	var querent: Resource = QuerentDataScript.new()
	querent.querent_id = "q_%s_n%d_i%d" % [personality, night_number, querent_index]
	querent.querent_name = full_name
	querent.question_text = question
	querent.question_theme = theme
	querent.personality_type = personality
	querent.target_score = target_score
	querent.gold_reward = gold_reward
	querent.primary_suit_bonus = suit_info["primary"]
	querent.secondary_suit_bonus = suit_info["secondary"]
	querent.personality_modifier = modifier
	return querent


static func _get_personality_weights(night_number: int) -> Dictionary:
	if night_number <= 1:
		return {
			"curious": 40, "believer": 25, "serene": 30,
			"skeptic": 5, "desperate": 0, "shadowed": 0, "secretive": 0,
		}
	elif night_number == 2:
		return {
			"curious": 30, "believer": 25, "serene": 20,
			"skeptic": 15, "desperate": 5, "shadowed": 5, "secretive": 0,
		}
	else:
		return {
			"curious": 15, "believer": 20, "serene": 10,
			"skeptic": 20, "desperate": 15, "shadowed": 15, "secretive": 5,
		}


static func _weighted_random(weights: Dictionary) -> String:
	var total := 0.0
	for w in weights.values():
		total += float(w)

	var roll := randf() * total
	var cumulative := 0.0
	for key in weights:
		cumulative += float(weights[key])
		if roll < cumulative:
			return key

	# Fallback: return last key
	return weights.keys().back()
