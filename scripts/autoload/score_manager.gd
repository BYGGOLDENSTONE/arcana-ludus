extends Node
## Scoring engine — calculates Insight and Resonance for card placements.
## Phase 2: per-card scoring with position match bonuses.

const MatchCalc = preload("res://scripts/utils/match_calculator.gd")

var current_score: int = 0
var target_score: int = 0
var card_scores: Array = []  # Array of { card, insight, resonance, total, match_level }


func reset_score() -> void:
	current_score = 0
	card_scores.clear()


func set_target(target: int) -> void:
	target_score = target


func score_reading(placed_cards: Array) -> int:
	## Score all placed cards in the spread.
	## placed_cards: Array of { slot, card, position_data }
	## Returns total score.
	reset_score()
	EventBus.scoring_started.emit()

	for placement in placed_cards:
		var card: Node = placement.card
		var pos_data: Resource = placement.position_data
		var card_data: Resource = card.card_data
		var is_reversed: bool = card.is_reversed

		var result := _score_card(card_data, pos_data, is_reversed)
		result.card = card
		card_scores.append(result)
		current_score += result.total
		EventBus.card_scored.emit(card, result.insight, result.resonance)

	EventBus.scoring_completed.emit(current_score)
	return current_score


func _score_card(card_data: Resource, pos_data: Resource, _is_reversed: bool) -> Dictionary:
	## Calculate score for a single card in a position.
	## Phase 2: Base Insight + position match Resonance multiplier.
	var insight: int = card_data.base_insight
	var match_result := MatchCalc.calculate_match(card_data, pos_data)
	var resonance: float = match_result.multiplier
	var total := int(insight * resonance)

	return {
		"insight": insight,
		"resonance": resonance,
		"total": total,
		"match_level": match_result.level,
		"match_reasons": match_result.reasons,
	}


func calculate_card_score(card_data: Resource, position_name: String, is_reversed: bool) -> Dictionary:
	## Legacy API — returns { insight, resonance, total }
	var insight: int = card_data.base_insight
	var resonance := 1.0
	var total := int(insight * resonance)
	return { "insight": insight, "resonance": resonance, "total": total }


func add_score(amount: int) -> void:
	current_score += amount


func is_target_met() -> bool:
	return current_score >= target_score


func get_score_breakdown() -> Array:
	return card_scores
