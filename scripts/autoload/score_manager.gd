extends Node
## Scoring engine — calculates Insight and Resonance for card placements.

var current_score: int = 0
var target_score: int = 0


func reset_score() -> void:
	current_score = 0


func set_target(target: int) -> void:
	target_score = target


func calculate_card_score(card_data: Resource, _position_name: String, _is_reversed: bool) -> Dictionary:
	## Returns { insight: int, resonance: float, total: int }
	## Skeleton — full implementation in Phase 2.
	var insight: int = card_data.base_insight
	var resonance := 1.0
	var total := int(insight * resonance)
	return { "insight": insight, "resonance": resonance, "total": total }


func add_score(amount: int) -> void:
	current_score += amount


func is_target_met() -> bool:
	return current_score >= target_score
