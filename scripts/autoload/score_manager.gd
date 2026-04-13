extends Node
## Scoring engine — Phase 5: supports per-row partial scoring, full resolution,
## Veil tier bonuses, and querent theme bonuses.
## Resolution: Base Insight → Position Match → Chains → Cross-Element →
##             Numerological → Veil Tier → Querent Theme

const MatchCalc = preload("res://scripts/utils/match_calculator.gd")
const ChainDetect = preload("res://scripts/utils/chain_detector.gd")
const ComboDetect = preload("res://scripts/utils/combo_detector.gd")

var current_score: int = 0
var target_score: int = 0
var card_scores: Array = []
var detected_chains: Array = []
var detected_combos: Array = []
var meta_effects: Array = []


func reset_score() -> void:
	current_score = 0
	card_scores.clear()
	detected_chains.clear()
	detected_combos.clear()
	meta_effects.clear()


func set_target(target: int) -> void:
	target_score = target


func score_row(row_cards: Array, all_placed_cards: Array) -> int:
	## Score a single row's cards in the context of all placed cards so far.
	## row_cards: Array of { slot, card, position_data } for this row only
	## all_placed_cards: Array of { slot, card, position_data } for all placed so far (incl this row)
	## Returns the row's score contribution.

	var row_score := 0

	# Calculate base insight + position match for row cards only
	var row_entries: Array = []
	for placed in row_cards:
		var card: Node = placed.card
		var pos_data: Resource = placed.position_data
		var card_data: Resource = card.card_data

		var match_result := MatchCalc.calculate_match(card_data, pos_data)

		var entry := {
			"card": card,
			"card_data": card_data,
			"position_data": pos_data,
			"is_reversed": card.is_reversed,
			"base_insight": card_data.base_insight,
			"insight": card_data.base_insight,
			"base_resonance": match_result.multiplier,
			"resonance": match_result.multiplier,
			"match_level": match_result.level,
			"match_reasons": match_result.reasons,
			"chain_bonuses": [] as Array[String],
			"combo_bonuses": [] as Array[String],
			"total": 0,
		}
		row_entries.append(entry)
		card_scores.append(entry)

	# Calculate totals for this row's entries
	for entry in row_entries:
		entry.total = int(entry.insight * entry.resonance)
		row_score += entry.total

	current_score += row_score
	return row_score


func score_reading(placed_cards: Array) -> int:
	## Full scoring with chains and combos across all placed cards.
	## Called after the final row (Future) is placed.
	## placed_cards: Array of { slot, card, position_data }
	## Returns total score.
	reset_score()
	EventBus.scoring_started.emit()

	# --- Step 1: Base Insight + Position Match Resonance ---
	for i in range(placed_cards.size()):
		var card: Node = placed_cards[i].card
		var pos_data: Resource = placed_cards[i].position_data
		var card_data: Resource = card.card_data

		var match_result := MatchCalc.calculate_match(card_data, pos_data)

		card_scores.append({
			"card": card,
			"card_data": card_data,
			"position_data": pos_data,
			"is_reversed": card.is_reversed,
			"base_insight": card_data.base_insight,
			"insight": card_data.base_insight,
			"base_resonance": match_result.multiplier,
			"resonance": match_result.multiplier,
			"match_level": match_result.level,
			"match_reasons": match_result.reasons,
			"chain_bonuses": [] as Array[String],
			"combo_bonuses": [] as Array[String],
			"total": 0,
		})

	# --- Step 2: Elemental Chain Multipliers ---
	detected_chains = ChainDetect.detect_chains(placed_cards)
	for chain in detected_chains:
		TalismanManager.on_chain(chain)
		_apply_chain_bonus(chain)
		EventBus.chain_detected.emit(chain)

	# --- Step 3: Cross-Element Combos ---
	var cross_combos := ComboDetect.detect_cross_element_combos(placed_cards)
	for combo in cross_combos:
		_apply_cross_element_combo(combo)
		detected_combos.append(combo)
		EventBus.combo_detected.emit(combo)

	# --- Step 4: Numerological Combos ---
	var num_combos := ComboDetect.detect_numerological_combos(placed_cards)
	for combo in num_combos:
		_apply_numerological_combo(combo)
		detected_combos.append(combo)
		EventBus.combo_detected.emit(combo)

	# --- Step 5: Talisman on_score hooks ---
	for entry in card_scores:
		TalismanManager.on_score_card(entry)

	# --- Step 6: Veil Tier Bonuses ---
	_apply_veil_tier_bonuses()

	# --- Step 7: Talisman after_reading hooks ---
	TalismanManager.on_after_reading(card_scores)

	# --- Final: Calculate per-card totals and sum ---
	for entry in card_scores:
		entry.total = int(entry.insight * entry.resonance)
		current_score += entry.total
		EventBus.card_scored.emit(entry.card, entry.insight, entry.resonance)

	EventBus.scoring_completed.emit(current_score)
	return current_score


func _apply_chain_bonus(chain: Dictionary) -> void:
	var multiplier: float = chain.base_multiplier
	var suit_name: String = chain.suit.capitalize()

	for idx in chain.card_indices:
		card_scores[idx].resonance *= multiplier
		card_scores[idx].chain_bonuses.append("%s Chain x%.1f" % [suit_name, multiplier])

	if chain.has_ace:
		for idx in chain.card_indices:
			card_scores[idx].resonance += chain.ace_bonus_per_card
			card_scores[idx].chain_bonuses.append("Ace starter +2")

	if chain.has_ten:
		for idx in chain.card_indices:
			card_scores[idx].resonance *= chain.ten_multiplier
			card_scores[idx].chain_bonuses.append("10 closer x1.5")

	if chain.perfect_chain:
		for idx in chain.card_indices:
			card_scores[idx].resonance *= chain.perfect_multiplier
			card_scores[idx].chain_bonuses.append("Perfect Chain x2")


func _apply_cross_element_combo(combo: Dictionary) -> void:
	match combo.combo_id:
		"steam":
			for idx in combo.card_indices:
				card_scores[idx].insight *= 2
				card_scores[idx].combo_bonuses.append("Steam: Insight x2")
		"wildfire":
			for i in range(card_scores.size()):
				card_scores[i].insight += 3
				card_scores[i].combo_bonuses.append("Wildfire: +3 Insight")
		"growth":
			meta_effects.append({
				"type": "gold_multiplier", "value": 2, "source": "Growth"
			})
			for idx in combo.card_indices:
				card_scores[idx].combo_bonuses.append("Growth: Gold x2")
		"erosion":
			var idx_a: int = combo.card_indices[0]
			var idx_b: int = combo.card_indices[1]
			var ins_a: int = card_scores[idx_a].base_insight
			var ins_b: int = card_scores[idx_b].base_insight
			if ins_a <= ins_b:
				card_scores[idx_b].resonance += float(ins_a) * 0.5
				card_scores[idx_a].combo_bonuses.append("Erosion: gave +%d Res" % int(ins_a * 0.5))
				card_scores[idx_b].combo_bonuses.append("Erosion: +%d Resonance" % int(ins_a * 0.5))
			else:
				card_scores[idx_a].resonance += float(ins_b) * 0.5
				card_scores[idx_b].combo_bonuses.append("Erosion: gave +%d Res" % int(ins_b * 0.5))
				card_scores[idx_a].combo_bonuses.append("Erosion: +%d Resonance" % int(ins_b * 0.5))
		"forge":
			for idx in combo.card_indices:
				card_scores[idx].insight += 2
				card_scores[idx].combo_bonuses.append("Forge: +2 Insight")
			meta_effects.append({
				"type": "permanent_upgrade", "value": 2, "source": "Forge",
				"card_indices": combo.card_indices.duplicate(),
			})
		"storm":
			for idx in combo.card_indices:
				card_scores[idx].resonance *= 2.0
				card_scores[idx].combo_bonuses.append("Storm: Resonance x2")
			meta_effects.append({
				"type": "veil_change", "value": 2, "source": "Storm"
			})


func _apply_numerological_combo(combo: Dictionary) -> void:
	match combo.type:
		"pair":
			for idx in combo.card_indices:
				card_scores[idx].insight += 5
				card_scores[idx].combo_bonuses.append("Pair: +5 Insight")
		"triple":
			for idx in combo.card_indices:
				card_scores[idx].resonance *= 2.0
				card_scores[idx].combo_bonuses.append("Triple: Resonance x2")
		"quad":
			for idx in combo.card_indices:
				card_scores[idx].resonance *= 5.0
				card_scores[idx].combo_bonuses.append("Perfect Harmony: Resonance x5")
		"run":
			for idx in combo.card_indices:
				card_scores[idx].insight += 5
				card_scores[idx].combo_bonuses.append("Run: +5 Insight")


func _apply_veil_tier_bonuses() -> void:
	var tier: int = VeilManager.get_tier()
	if tier == VeilManager.VeilTier.CLEAR:
		return

	for entry in card_scores:
		match tier:
			VeilManager.VeilTier.GLIMPSE:
				# Reversed cards gain +50% Resonance
				if entry.is_reversed:
					entry.resonance *= 1.5
					entry.combo_bonuses.append("Veil Glimpse: Reversed +50%% Res")
			VeilManager.VeilTier.GAZE:
				# Reversed cards gain x2 Resonance
				if entry.is_reversed:
					entry.resonance *= 2.0
					entry.combo_bonuses.append("Veil Gaze: Reversed x2 Res")
			VeilManager.VeilTier.ABYSS, VeilManager.VeilTier.VOID:
				# ALL cards gain x2 Resonance
				entry.resonance *= 2.0
				entry.combo_bonuses.append("Veil Abyss: ALL x2 Res")


func calculate_card_score(card_data: Resource, _position_name: String, _is_reversed: bool) -> Dictionary:
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


func get_detected_chains() -> Array:
	return detected_chains


func get_detected_combos() -> Array:
	return detected_combos


func get_meta_effects() -> Array:
	return meta_effects
