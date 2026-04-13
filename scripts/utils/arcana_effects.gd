class_name ArcanaEffects
## Implements all 22 Major Arcana unique upright/reversed effects.
## Integrated into ScoreManager scoring pipeline (Step 3: card-specific effects).
##
## Three phases:
##   1. get_chain_modifiers()  — pre-chain/combo adjustments (wild suits, chain control)
##   2. apply_effects()        — insight/resonance modifications
##   3. apply_post_effects()   — Veil changes, life healing, gold

## 3x3 grid adjacency (index -> adjacent indices)
const GRID_ADJACENCY := {
	0: [1, 3],
	1: [0, 2, 4],
	2: [1, 5],
	3: [0, 4, 6],
	4: [1, 3, 5, 7],
	5: [2, 4, 8],
	6: [3, 7],
	7: [4, 6, 8],
	8: [5, 7],
}


## Returns modifiers that affect chain/combo detection behavior.
static func get_chain_modifiers(card_scores: Array) -> Dictionary:
	var mods := {
		"wild_suit_indices": [] as Array,
		"chain_length_bonus": 0,
		"chains_disabled": false,
		"all_element_indices": [] as Array,
		"chain_excluded_indices": [] as Array,
		"extra_suit_cards": {} as Dictionary,
		"multiplier_lock": false,
	}

	for i in range(card_scores.size()):
		var entry: Dictionary = card_scores[i]
		var cd: Resource = entry.card_data
		if cd.card_type != "major_arcana":
			continue

		match cd.card_id:
			"m00":  # The Fool upright: wild suit for chains
				if not entry.is_reversed:
					mods.wild_suit_indices.append(i)
			"m01":  # The Magician upright: all 4 elements for combos
				if not entry.is_reversed:
					mods.all_element_indices.append(i)
			"m05":  # The Hierophant
				if not entry.is_reversed:
					mods.chain_length_bonus += 1
				else:
					mods.chains_disabled = true
			"m06":  # The Lovers reversed: adjacent cards excluded from chains
				if entry.is_reversed:
					for adj_idx in _get_adjacent(i, card_scores.size()):
						if adj_idx not in mods.chain_excluded_indices:
							mods.chain_excluded_indices.append(adj_idx)
			"m13":  # Death reversed: all multipliers locked to 1.0
				if entry.is_reversed:
					mods.multiplier_lock = true
			"m18":  # The Moon upright: random second suit for all cards
				if not entry.is_reversed:
					var suits := ["cups", "wands", "swords", "pentacles"]
					for j in range(card_scores.size()):
						var original: String = card_scores[j].card_data.suit
						if original != "major":
							var other := suits.filter(func(s: String) -> bool: return s != original)
							mods.extra_suit_cards[j] = other[randi() % other.size()]
						else:
							mods.extra_suit_cards[j] = suits[randi() % suits.size()]

	return mods


## Apply scoring effects (insight/resonance) to card_scores.
## Returns array of effect description strings for UI.
static func apply_effects(card_scores: Array) -> Array:
	var effects: Array = []

	# Collect Major Arcana positions
	var arcana_map: Dictionary = {}  # card_id -> { index, is_reversed }
	for i in range(card_scores.size()):
		var cd: Resource = card_scores[i].card_data
		if cd.card_type == "major_arcana":
			arcana_map[cd.card_id] = {"index": i, "is_reversed": card_scores[i].is_reversed}

	if arcana_map.is_empty():
		return effects

	# Process in card order (m00 → m21) for deterministic stacking
	var ordered_ids: Array = arcana_map.keys()
	ordered_ids.sort()

	for card_id in ordered_ids:
		var info: Dictionary = arcana_map[card_id]
		var idx: int = info.index
		var is_rev: bool = info.is_reversed

		match card_id:
			"m00": _apply_fool(card_scores, idx, is_rev, effects)
			"m01": _apply_magician(card_scores, idx, is_rev, effects)
			"m02": _apply_high_priestess(card_scores, idx, is_rev, effects)
			"m03": _apply_empress(card_scores, idx, is_rev, effects)
			"m04": _apply_emperor(card_scores, idx, is_rev, effects)
			"m05": _apply_hierophant(card_scores, idx, is_rev, effects)
			"m06": _apply_lovers(card_scores, idx, is_rev, effects)
			"m07": _apply_chariot(card_scores, idx, is_rev, effects)
			"m08": _apply_strength(card_scores, idx, is_rev, effects)
			"m09": _apply_hermit(card_scores, idx, is_rev, effects)
			"m10": _apply_wheel(card_scores, idx, is_rev, effects)
			"m11": _apply_justice(card_scores, idx, is_rev, effects)
			"m12": _apply_hanged_man(card_scores, idx, is_rev, effects)
			"m13": _apply_death(card_scores, idx, is_rev, effects)
			"m14": _apply_temperance(card_scores, idx, is_rev, effects)
			"m15": _apply_devil(card_scores, idx, is_rev, effects)
			"m16": _apply_tower(card_scores, idx, is_rev, effects)
			"m17": _apply_star(card_scores, idx, is_rev, effects)
			"m18": _apply_moon(card_scores, idx, is_rev, effects)
			"m19": _apply_sun(card_scores, idx, is_rev, effects)
			"m20": _apply_judgement(card_scores, idx, is_rev, effects)
			"m21": _apply_world(card_scores, idx, is_rev, effects)

	return effects


## Apply post-scoring effects (Veil adjustments, life healing).
## Called after all scoring bonuses are resolved.
static func apply_post_effects(card_scores: Array) -> void:
	for i in range(card_scores.size()):
		var cd: Resource = card_scores[i].card_data
		if cd.card_type != "major_arcana":
			continue
		var is_rev: bool = card_scores[i].is_reversed

		match cd.card_id:
			"m08":  # Strength reversed: extra +1 Veil (total +3)
				if is_rev:
					VeilManager.add_veil(1)
			"m14":  # Temperance reversed: reduce by 1 (total +1 instead of +2)
				if is_rev:
					VeilManager.reduce_veil(1)
			"m15":  # Devil
				if not is_rev:
					VeilManager.add_veil(2)  # Extra +2 (total +3 with dark arcana +1)
				else:
					VeilManager.reduce_veil(4)  # Net -2 (base +2, extra -4)
			"m16":  # Tower upright: extra +1 (total +2)
				if not is_rev:
					VeilManager.add_veil(1)
			"m17":  # Star upright: heal 1 life
				if not is_rev:
					GameManager.heal_life(1)
			"m18":  # Moon upright: extra +1 (total +2)
				if not is_rev:
					VeilManager.add_veil(1)


# =============================================================================
# Individual Card Effects
# =============================================================================

static func _apply_fool(scores: Array, idx: int, is_reversed: bool, effects: Array) -> void:
	if not is_reversed:
		# Wild card for chains (handled in chain_modifiers) + +5 Insight to all
		for i in range(scores.size()):
			scores[i].insight += 5
			scores[i].combo_bonuses.append("Fool: +5 Insight")
		effects.append("The Fool: +5 Insight to all cards")
	else:
		# x2 Resonance to the next card (by spread position)
		if idx + 1 < scores.size():
			scores[idx + 1].resonance *= 2.0
			scores[idx + 1].combo_bonuses.append("Fool Reversed: x2 Resonance")
			effects.append("The Fool Reversed: x2 Resonance to next card")


static func _apply_magician(scores: Array, idx: int, is_reversed: bool, effects: Array) -> void:
	if not is_reversed:
		# All 4 elements present for cross-element combos (handled in chain_modifiers)
		scores[idx].combo_bonuses.append("Magician: All elements active")
		effects.append("The Magician: All elements present for combos")
	else:
		# Simplified from "choose card from draw pile": +15 Insight to self
		scores[idx].insight += 15
		scores[idx].combo_bonuses.append("Magician Reversed: +15 Insight")
		effects.append("The Magician Reversed: +15 Insight (dark knowledge)")


static func _apply_high_priestess(scores: Array, idx: int, is_reversed: bool, effects: Array) -> void:
	if not is_reversed:
		# +10 Insight to self if any Cups card present in spread
		var cups_present := false
		for entry in scores:
			if entry.card_data.suit == "cups":
				cups_present = true
				break
		if cups_present:
			scores[idx].insight += 10
			scores[idx].combo_bonuses.append("High Priestess: Cups +10 Insight")
			effects.append("The High Priestess: +10 Insight (Cups present)")
	else:
		# Resonance doubled for self (hidden knowledge)
		scores[idx].resonance *= 2.0
		scores[idx].combo_bonuses.append("High Priestess Reversed: x2 Resonance")
		effects.append("The High Priestess Reversed: x2 Resonance")


static func _apply_empress(scores: Array, idx: int, is_reversed: bool, effects: Array) -> void:
	if not is_reversed:
		# Cups and Pentacles +5 Insight, adjacent cards +3 Insight
		for i in range(scores.size()):
			if scores[i].card_data.suit in ["cups", "pentacles"]:
				scores[i].insight += 5
				scores[i].combo_bonuses.append("Empress: +5 Insight")
		for adj in _get_adjacent(idx, scores.size()):
			scores[adj].insight += 3
			scores[adj].combo_bonuses.append("Empress Nurture: +3 Insight")
		effects.append("The Empress: Cups/Pentacles +5, adjacent +3 Insight")
	else:
		# Random suit loses -3 Insight, all Major Arcana +10 Insight
		var suits_found: Array = []
		for entry in scores:
			if entry.card_data.suit != "major" and entry.card_data.suit not in suits_found:
				suits_found.append(entry.card_data.suit)
		if not suits_found.is_empty():
			var cursed: String = suits_found[randi() % suits_found.size()]
			for i in range(scores.size()):
				if scores[i].card_data.suit == cursed:
					scores[i].insight = maxi(scores[i].insight - 3, 0)
					scores[i].combo_bonuses.append("Empress Reversed: -3 Insight")
		for i in range(scores.size()):
			if scores[i].card_data.card_type == "major_arcana":
				scores[i].insight += 10
				scores[i].combo_bonuses.append("Empress Reversed: +10 Insight")
		effects.append("The Empress Reversed: suit cursed, Major Arcana +10")


static func _apply_emperor(scores: Array, idx: int, is_reversed: bool, effects: Array) -> void:
	if not is_reversed:
		# Wands and Swords +5 Resonance. Position match bonuses x1.5
		for i in range(scores.size()):
			if scores[i].card_data.suit in ["wands", "swords"]:
				scores[i].resonance += 5.0
				scores[i].combo_bonuses.append("Emperor: +5 Resonance")
			# Enhance position match bonus by 50%
			if scores[i].base_resonance > 1.0:
				var match_bonus: float = scores[i].base_resonance - 1.0
				scores[i].resonance += match_bonus * 0.5
				scores[i].combo_bonuses.append("Emperor Structure: match x1.5")
		effects.append("The Emperor: Wands/Swords +5 Res, match x1.5")
	else:
		# No position match, all Insight x1.5
		for i in range(scores.size()):
			scores[i].resonance = 1.0
			scores[i].insight = int(scores[i].insight * 1.5)
			scores[i].combo_bonuses.append("Emperor Reversed: x1.5 Insight, no match")
		effects.append("The Emperor Reversed: all Insight x1.5, no position match")


static func _apply_hierophant(scores: Array, idx: int, is_reversed: bool, effects: Array) -> void:
	if not is_reversed:
		# Chain length bonus handled in modifiers. Court cards +5 Insight
		for i in range(scores.size()):
			var num: int = scores[i].card_data.card_number
			if num >= 11 and num <= 14:
				scores[i].insight += 5
				scores[i].combo_bonuses.append("Hierophant: Court +5")
		effects.append("The Hierophant: chains +1 tier, Court +5 Insight")
	else:
		# Chains disabled (modifier). Each unique suit x1.5 Resonance (multiplicative)
		var unique_suits: Dictionary = {}
		for entry in scores:
			if entry.card_data.suit != "major":
				unique_suits[entry.card_data.suit] = true
		var suit_count: int = unique_suits.size()
		if suit_count > 0:
			var mult: float = pow(1.5, suit_count)
			for i in range(scores.size()):
				scores[i].resonance *= mult
				scores[i].combo_bonuses.append("Hierophant Rebellion: %d suits x%.1f" % [suit_count, mult])
		effects.append("The Hierophant Reversed: chains broken, %d suits x%.1f" % [
			suit_count, pow(1.5, suit_count)])


static func _apply_lovers(scores: Array, idx: int, is_reversed: bool, effects: Array) -> void:
	var adjacent: Array = _get_adjacent(idx, scores.size())
	if not is_reversed:
		# Top 2 adjacent cards combine their Resonance
		if adjacent.size() >= 2:
			# Sort adjacent by resonance descending
			adjacent.sort_custom(func(a: int, b: int) -> bool:
				return scores[a].resonance > scores[b].resonance)
			var a: int = adjacent[0]
			var b: int = adjacent[1]
			var combined: float = scores[a].resonance + scores[b].resonance
			scores[a].resonance = combined
			scores[b].resonance = combined
			scores[a].combo_bonuses.append("Lovers Union: combined Res %.1f" % combined)
			scores[b].combo_bonuses.append("Lovers Union: combined Res %.1f" % combined)
			effects.append("The Lovers: Union — combined Resonance %.1f" % combined)
		elif adjacent.size() == 1:
			scores[adjacent[0]].resonance *= 2.0
			scores[adjacent[0]].combo_bonuses.append("Lovers Union: x2 Resonance")
			effects.append("The Lovers: Union — x2 Resonance")
	else:
		# Adjacent cards x2 Resonance each (chain exclusion in modifiers)
		for adj in adjacent:
			scores[adj].resonance *= 2.0
			scores[adj].combo_bonuses.append("Lovers Separation: x2 Resonance")
		effects.append("The Lovers Reversed: adjacent x2, can't chain")


static func _apply_chariot(scores: Array, idx: int, is_reversed: bool, effects: Array) -> void:
	if not is_reversed:
		# Each card placed after this gets cumulative +3 Insight
		var bonus := 0
		for i in range(idx + 1, scores.size()):
			bonus += 3
			scores[i].insight += bonus
			scores[i].combo_bonuses.append("Chariot Momentum: +%d Insight" % bonus)
		if bonus > 0:
			effects.append("The Chariot: Momentum — +3/+6/+9... Insight")
	else:
		# Last card gets x3 Resonance
		var last: int = scores.size() - 1
		if last >= 0:
			scores[last].resonance *= 3.0
			scores[last].combo_bonuses.append("Chariot Reversed: x3 Resonance")
			effects.append("The Chariot Reversed: last card x3 Resonance")


static func _apply_strength(scores: Array, idx: int, is_reversed: bool, effects: Array) -> void:
	if not is_reversed:
		# +5 Resonance to all cards (Veil reset already handled by VeilManager)
		for i in range(scores.size()):
			scores[i].resonance += 5.0
			scores[i].combo_bonuses.append("Strength: +5 Resonance")
		effects.append("Strength: +5 Resonance to all")
	else:
		# All Resonance x1.5 (extra Veil +1 in post_effects)
		for i in range(scores.size()):
			scores[i].resonance *= 1.5
			scores[i].combo_bonuses.append("Strength Reversed: x1.5 Resonance")
		effects.append("Strength Reversed: all Resonance x1.5")


static func _apply_hermit(scores: Array, idx: int, is_reversed: bool, effects: Array) -> void:
	if not is_reversed:
		# If this is the only Major Arcana in spread → x3 Resonance to self
		var major_count := 0
		for entry in scores:
			if entry.card_data.card_type == "major_arcana":
				major_count += 1
		if major_count == 1:
			scores[idx].resonance *= 3.0
			scores[idx].combo_bonuses.append("Hermit Solitude: x3 Resonance")
			effects.append("The Hermit: Solitude — x3 Resonance (only Major)")
		else:
			effects.append("The Hermit: Solitude not met (%d Major Arcana)" % major_count)
	else:
		# Adjacent cards -5 Insight, self Insight x3
		for adj in _get_adjacent(idx, scores.size()):
			scores[adj].insight = maxi(scores[adj].insight - 5, 0)
			scores[adj].combo_bonuses.append("Hermit Isolation: -5 Insight")
		scores[idx].insight *= 3
		scores[idx].combo_bonuses.append("Hermit Isolation: x3 Insight")
		effects.append("The Hermit Reversed: adjacent -5, self x3 Insight")


static func _apply_wheel(scores: Array, idx: int, is_reversed: bool, effects: Array) -> void:
	if not is_reversed:
		# Random positive effect from pool of 10
		var roll: int = randi() % 10
		match roll:
			0:  # +10 Insight to all
				for i in range(scores.size()):
					scores[i].insight += 10
					scores[i].combo_bonuses.append("Wheel: +10 Insight")
				effects.append("Wheel of Fortune: +10 Insight to all!")
			1:  # +20 Resonance to self
				scores[idx].resonance += 20.0
				scores[idx].combo_bonuses.append("Wheel: +20 Resonance")
				effects.append("Wheel of Fortune: +20 Resonance!")
			2:  # x2 Resonance to self
				scores[idx].resonance *= 2.0
				scores[idx].combo_bonuses.append("Wheel: x2 Resonance")
				effects.append("Wheel of Fortune: x2 Resonance!")
			3:  # +15 Insight to random other card
				var others: Array = []
				for i in range(scores.size()):
					if i != idx:
						others.append(i)
				if not others.is_empty():
					var target: int = others[randi() % others.size()]
					scores[target].insight += 15
					scores[target].combo_bonuses.append("Wheel: +15 Insight")
				effects.append("Wheel of Fortune: +15 Insight to random card!")
			4:  # +5 Resonance to all
				for i in range(scores.size()):
					scores[i].resonance += 5.0
					scores[i].combo_bonuses.append("Wheel: +5 Resonance")
				effects.append("Wheel of Fortune: +5 Resonance to all!")
			5:  # +8 Insight to all
				for i in range(scores.size()):
					scores[i].insight += 8
					scores[i].combo_bonuses.append("Wheel: +8 Insight")
				effects.append("Wheel of Fortune: +8 Insight to all!")
			6:  # x1.5 Resonance to all
				for i in range(scores.size()):
					scores[i].resonance *= 1.5
					scores[i].combo_bonuses.append("Wheel: x1.5 Resonance")
				effects.append("Wheel of Fortune: x1.5 Resonance to all!")
			7:  # +25 Insight to self
				scores[idx].insight += 25
				scores[idx].combo_bonuses.append("Wheel: +25 Insight")
				effects.append("Wheel of Fortune: +25 Insight!")
			8:  # Adjacent cards +10 Resonance
				for adj in _get_adjacent(idx, scores.size()):
					scores[adj].resonance += 10.0
					scores[adj].combo_bonuses.append("Wheel: +10 Resonance")
				effects.append("Wheel of Fortune: adjacent +10 Resonance!")
			9:  # -1 Veil
				VeilManager.reduce_veil(1)
				effects.append("Wheel of Fortune: Veil -1!")
	else:
		# +20 Resonance (guaranteed) + random penalty
		scores[idx].resonance += 20.0
		scores[idx].combo_bonuses.append("Wheel Reversed: +20 Resonance")
		var penalty: int = randi() % 5
		match penalty:
			0:  # All -5 Insight
				for i in range(scores.size()):
					scores[i].insight = maxi(scores[i].insight - 5, 1)
					scores[i].combo_bonuses.append("Wheel Reversed: -5 Insight")
			1:  # Random card -10 Insight
				var target: int = randi() % scores.size()
				scores[target].insight = maxi(scores[target].insight - 10, 1)
				scores[target].combo_bonuses.append("Wheel Reversed: -10 Insight")
			2:  # All Resonance x0.75
				for i in range(scores.size()):
					if i != idx:
						scores[i].resonance *= 0.75
						scores[i].combo_bonuses.append("Wheel Reversed: x0.75 Res")
			3:  # Self Insight halved
				scores[idx].insight = maxi(scores[idx].insight / 2, 1)
				scores[idx].combo_bonuses.append("Wheel Reversed: Insight halved")
			4:  # Adjacent -3 Resonance
				for adj in _get_adjacent(idx, scores.size()):
					scores[adj].resonance = maxf(scores[adj].resonance - 3.0, 0.1)
					scores[adj].combo_bonuses.append("Wheel Reversed: -3 Resonance")
		effects.append("Wheel of Fortune Reversed: +20 Res, bad luck penalty")


static func _apply_justice(scores: Array, idx: int, is_reversed: bool, effects: Array) -> void:
	var upright_count := 0
	var reversed_count := 0
	for entry in scores:
		if entry.is_reversed:
			reversed_count += 1
		else:
			upright_count += 1

	if not is_reversed:
		# If upright/reversed counts differ by at most 1 → all Resonance x2
		if absi(upright_count - reversed_count) <= 1:
			for i in range(scores.size()):
				scores[i].resonance *= 2.0
				scores[i].combo_bonuses.append("Justice Balance: x2 Resonance")
			effects.append("Justice: Balance achieved — all x2 Resonance!")
		else:
			effects.append("Justice: Balance not met (%d up / %d rev)" % [upright_count, reversed_count])
	else:
		# Dominant orientation x2, minority x0.5
		var dominant_is_upright: bool = upright_count >= reversed_count
		for i in range(scores.size()):
			if scores[i].is_reversed == dominant_is_upright:
				# Minority
				scores[i].resonance *= 0.5
				scores[i].combo_bonuses.append("Justice Imbalance: x0.5 Res")
			else:
				# Dominant
				scores[i].resonance *= 2.0
				scores[i].combo_bonuses.append("Justice Imbalance: x2 Res")
		effects.append("Justice Reversed: dominant x2, minority x0.5")


static func _apply_hanged_man(scores: Array, idx: int, is_reversed: bool, effects: Array) -> void:
	if not is_reversed:
		# Sacrifice: self Insight distributed to all others, self scores 0
		var sacrificed: int = scores[idx].insight
		scores[idx].insight = 0
		scores[idx].resonance = 0.0
		scores[idx].combo_bonuses.append("Hanged Man: Sacrificed")
		var others: int = scores.size() - 1
		if others > 0:
			var share: int = maxi(sacrificed / others, 1)
			for i in range(scores.size()):
				if i != idx:
					scores[i].insight += share
					scores[i].combo_bonuses.append("Hanged Man Sacrifice: +%d Insight" % share)
		effects.append("The Hanged Man: Sacrificed %d Insight to others" % sacrificed)
	else:
		# All reversed cards gain +50% Insight (dual perspective)
		for i in range(scores.size()):
			if scores[i].is_reversed:
				var bonus: int = scores[i].insight / 2
				scores[i].insight += bonus
				scores[i].combo_bonuses.append("Hanged Man Reversed: +50%% Insight")
		effects.append("The Hanged Man Reversed: reversed cards +50%% Insight")


static func _apply_death(scores: Array, idx: int, is_reversed: bool, effects: Array) -> void:
	if not is_reversed:
		# Destroy lowest-Insight card, gain its Insight x3 as Resonance
		var lowest_idx := -1
		var lowest_ins := 999999
		for i in range(scores.size()):
			if i == idx:
				continue
			if scores[i].insight < lowest_ins:
				lowest_ins = scores[i].insight
				lowest_idx = i
		if lowest_idx >= 0:
			scores[lowest_idx].insight = 0
			scores[lowest_idx].resonance = 0.0
			scores[lowest_idx].combo_bonuses.append("Death: Transformed")
			var gained: float = lowest_ins * 3.0
			scores[idx].resonance += gained
			scores[idx].combo_bonuses.append("Death Transform: +%.0f Resonance" % gained)
			effects.append("Death: Transformed card for +%.0f Resonance" % gained)
	else:
		# All multipliers locked to 1.0 (via modifier), all +30 Insight
		for i in range(scores.size()):
			scores[i].resonance = 1.0
			scores[i].insight += 30
			scores[i].combo_bonuses.append("Death Stagnation: +30 Insight, Res=1")
		effects.append("Death Reversed: Stagnation — +30 Insight, multipliers locked")


static func _apply_temperance(scores: Array, idx: int, is_reversed: bool, effects: Array) -> void:
	if not is_reversed:
		# All cards +3 Insight (Veil -2 already handled by VeilManager)
		for i in range(scores.size()):
			scores[i].insight += 3
			scores[i].combo_bonuses.append("Temperance: +3 Insight")
		effects.append("Temperance: all +3 Insight, smooth scoring")
	else:
		# Highest Insight card gets x3 Resonance (post: Veil -1)
		var best_idx := 0
		var best_ins := 0
		for i in range(scores.size()):
			if scores[i].insight > best_ins:
				best_ins = scores[i].insight
				best_idx = i
		scores[best_idx].resonance *= 3.0
		scores[best_idx].combo_bonuses.append("Temperance Reversed: x3 Resonance")
		effects.append("Temperance Reversed: best card x3 Resonance")


static func _apply_devil(scores: Array, idx: int, is_reversed: bool, effects: Array) -> void:
	if not is_reversed:
		# x2 Resonance to entire spread (post: extra +2 Veil)
		for i in range(scores.size()):
			scores[i].resonance *= 2.0
			scores[i].combo_bonuses.append("Devil Temptation: x2 Resonance")
		effects.append("The Devil: Temptation — all x2 Resonance, +3 Veil")
	else:
		# Veil freedom: Resonance -25% (post: Veil -4 for net -2)
		for i in range(scores.size()):
			scores[i].resonance *= 0.75
			scores[i].combo_bonuses.append("Devil Breaking Free: x0.75 Res")
		effects.append("The Devil Reversed: Breaking free — x0.75 Res, Veil -2")


static func _apply_tower(scores: Array, idx: int, is_reversed: bool, effects: Array) -> void:
	if not is_reversed:
		# All Resonance x2 (simplified from "clear and rescore"). Post: +1 Veil
		for i in range(scores.size()):
			scores[i].resonance *= 2.0
			scores[i].combo_bonuses.append("Tower Destruction: x2 Resonance")
		effects.append("The Tower: Destruction — all x2 Resonance")
	else:
		# Protection: +10 flat Insight to all
		for i in range(scores.size()):
			scores[i].insight += 10
			scores[i].combo_bonuses.append("Tower Avoidance: +10 Insight")
		effects.append("The Tower Reversed: Avoidance — all +10 Insight")


static func _apply_star(scores: Array, idx: int, is_reversed: bool, effects: Array) -> void:
	if not is_reversed:
		# All +5 Insight (Veil -3 and heal handled elsewhere)
		for i in range(scores.size()):
			scores[i].insight += 5
			scores[i].combo_bonuses.append("Star Hope: +5 Insight")
		effects.append("The Star: Hope — all +5 Insight, heal 1 life")
	else:
		# +15 Resonance to all reversed cards
		for i in range(scores.size()):
			if scores[i].is_reversed:
				scores[i].resonance += 15.0
				scores[i].combo_bonuses.append("Star Despair: +15 Resonance")
		effects.append("The Star Reversed: reversed cards +15 Resonance")


static func _apply_moon(scores: Array, idx: int, is_reversed: bool, effects: Array) -> void:
	if not is_reversed:
		# Random second suit for chains (handled in modifiers). Post: +1 Veil
		scores[idx].combo_bonuses.append("Moon Illusion: random suits active")
		effects.append("The Moon: Illusion — random second suits for chains")
	else:
		# Clarity: +10 Insight to all
		for i in range(scores.size()):
			scores[i].insight += 10
			scores[i].combo_bonuses.append("Moon Clarity: +10 Insight")
		effects.append("The Moon Reversed: Clarity — all +10 Insight")


static func _apply_sun(scores: Array, idx: int, is_reversed: bool, effects: Array) -> void:
	if not is_reversed:
		# All Insight x1.3 (Veil -2 handled by VeilManager)
		for i in range(scores.size()):
			scores[i].insight = int(scores[i].insight * 1.3)
			scores[i].combo_bonuses.append("Sun Joy: x1.3 Insight")
		effects.append("The Sun: Joy — all Insight x1.3")
	else:
		# All Resonance x2
		for i in range(scores.size()):
			scores[i].resonance *= 2.0
			scores[i].combo_bonuses.append("Sun Eclipse: x2 Resonance")
		effects.append("The Sun Reversed: Eclipse — all x2 Resonance")


static func _apply_judgement(scores: Array, idx: int, is_reversed: bool, effects: Array) -> void:
	if not is_reversed:
		# Simplified from "retrieve from discard": all cards +15 Insight
		for i in range(scores.size()):
			scores[i].insight += 15
			scores[i].combo_bonuses.append("Judgement Rebirth: +15 Insight")
		effects.append("Judgement: Rebirth — all +15 Insight")
	else:
		# All cards +10 Insight
		for i in range(scores.size()):
			scores[i].insight += 10
			scores[i].combo_bonuses.append("Judgement Reversed: +10 Insight")
		effects.append("Judgement Reversed: all +10 Insight")


static func _apply_world(scores: Array, idx: int, is_reversed: bool, effects: Array) -> void:
	# Check which elemental suits are present
	var suits_present: Dictionary = {}
	var has_wild := false
	var has_all_elements := false
	for i in range(scores.size()):
		var suit: String = scores[i].card_data.suit
		if suit != "major":
			suits_present[suit] = true
		elif scores[i].card_data.card_id == "m00" and not scores[i].is_reversed:
			has_wild = true
		elif scores[i].card_data.card_id == "m01" and not scores[i].is_reversed:
			has_all_elements = true

	var all_four: bool = has_wild or has_all_elements or suits_present.size() >= 4

	if not is_reversed:
		# All 4 suits present → x5 Resonance to all
		if all_four:
			for i in range(scores.size()):
				scores[i].resonance *= 5.0
				scores[i].combo_bonuses.append("World Completion: x5 Resonance!")
			effects.append("The World: Completion — ALL x5 Resonance!")
		else:
			effects.append("The World: Incomplete (%d/4 suits)" % suits_present.size())
	else:
		# Missing suits: -25% Resonance each. Present suits' cards: x2 Resonance
		var all_suits := ["cups", "wands", "swords", "pentacles"]
		var missing_count := 0
		for s in all_suits:
			if not suits_present.has(s):
				missing_count += 1
		# Penalty for missing suits
		if missing_count > 0:
			var penalty: float = pow(0.75, missing_count)
			for i in range(scores.size()):
				scores[i].resonance *= penalty
				scores[i].combo_bonuses.append("World Incomplete: x%.2f Res" % penalty)
		# Bonus for present suits
		for i in range(scores.size()):
			if suits_present.has(scores[i].card_data.suit):
				scores[i].resonance *= 2.0
				scores[i].combo_bonuses.append("World Reversed: present suit x2")
		effects.append("The World Reversed: %d missing (x0.75 each), present x2" % missing_count)


# =============================================================================
# Helpers
# =============================================================================

static func _get_adjacent(idx: int, total: int) -> Array:
	if not GRID_ADJACENCY.has(idx):
		return []
	var result: Array = []
	for adj in GRID_ADJACENCY[idx]:
		if adj < total:
			result.append(adj)
	return result
