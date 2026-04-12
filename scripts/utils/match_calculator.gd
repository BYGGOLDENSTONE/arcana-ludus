class_name MatchCalculator
## Calculates card-to-position match quality.
## Returns match level and corresponding Resonance multiplier.

enum MatchLevel { PERFECT, GOOD, NEUTRAL, MISMATCH }

const MATCH_MULTIPLIERS := {
	MatchLevel.PERFECT: 2.0,
	MatchLevel.GOOD: 1.5,
	MatchLevel.NEUTRAL: 1.0,
	MatchLevel.MISMATCH: 0.9,
}

const MATCH_COLORS := {
	MatchLevel.PERFECT: Color(0.83, 0.66, 0.26, 0.8),   # Gold
	MatchLevel.GOOD: Color(0.2, 0.8, 0.3, 0.6),          # Green
	MatchLevel.NEUTRAL: Color(1, 1, 1, 0.0),              # Invisible
	MatchLevel.MISMATCH: Color(0.8, 0.2, 0.2, 0.3),      # Faint red
}


static func calculate_match(card_data: Resource, position: Resource) -> Dictionary:
	## Returns { level: MatchLevel, multiplier: float, color: Color, reasons: Array[String] }
	var score := 0
	var reasons: Array[String] = []

	# Suit affinity check
	var suit_match := _check_suit_affinity(card_data, position)
	score += suit_match.score
	reasons.append_array(suit_match.reasons)

	# Number affinity check
	var num_match := _check_number_affinity(card_data, position)
	score += num_match.score
	reasons.append_array(num_match.reasons)

	# Special affinity check
	var special_match := _check_special_affinity(card_data, position)
	score += special_match.score
	reasons.append_array(special_match.reasons)

	# Determine match level from total score
	var level: MatchLevel
	if score >= 3:
		level = MatchLevel.PERFECT
	elif score >= 1:
		level = MatchLevel.GOOD
	elif score == 0:
		level = MatchLevel.NEUTRAL
	else:
		level = MatchLevel.MISMATCH

	return {
		"level": level,
		"multiplier": MATCH_MULTIPLIERS[level],
		"color": MATCH_COLORS[level],
		"reasons": reasons,
	}


static func _check_suit_affinity(card_data: Resource, position: Resource) -> Dictionary:
	var result := { "score": 0, "reasons": [] as Array[String] }
	if position.suit_affinities.is_empty():
		return result

	var card_suit: String = card_data.suit
	if card_suit == "major":
		# Major Arcana match "major" affinity positions
		if "major" in position.suit_affinities:
			result.score = 2
			result.reasons.append("Major Arcana in arcana position")
		return result

	if card_suit in position.suit_affinities:
		result.score = 2
		result.reasons.append("%s matches position affinity" % card_suit.capitalize())
	else:
		# Has affinities but card doesn't match → slight mismatch
		result.score = -1
		result.reasons.append("%s doesn't match position" % card_suit.capitalize())

	return result


static func _check_number_affinity(card_data: Resource, position: Resource) -> Dictionary:
	var result := { "score": 0, "reasons": [] as Array[String] }
	if position.number_affinities.is_empty():
		return result

	var card_number: int = card_data.card_number
	if card_number in position.number_affinities:
		result.score = 1
		result.reasons.append("Number %d matches position" % card_number)

	return result


static func _check_special_affinity(card_data: Resource, position: Resource) -> Dictionary:
	var result := { "score": 0, "reasons": [] as Array[String] }
	if position.special_affinities.is_empty():
		return result

	for affinity in position.special_affinities:
		match affinity:
			"major_arcana":
				if card_data.card_type == "major_arcana":
					result.score += 2
					result.reasons.append("Major Arcana bonus position")
			"aces":
				if card_data.card_number == 1:
					result.score += 2
					result.reasons.append("Ace in hope position")
			"court":
				if card_data.card_type == "court":
					result.score += 1
					result.reasons.append("Court card in self position")
			"foundation":
				if card_data.card_number == 4:
					result.score += 1
					result.reasons.append("Foundation card (4)")
			"chain_closers":
				if card_data.card_number == 10:
					result.score += 2
					result.reasons.append("Chain closer (10) in destiny position")
			"pairs":
				# Pairs bonus handled at spread level during scoring
				pass

	return result
