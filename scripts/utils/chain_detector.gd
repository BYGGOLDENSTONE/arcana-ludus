class_name ChainDetector
## Detects elemental chains (same-suit connected groups) in a spread.
## A chain is 2+ cards of the same suit in adjacent (orthogonal) positions.
## Phase 4: Chain multipliers, Ace starter bonus, 10 closer bonus, Perfect Chain.
## Phase 5.4: Supports wild suit cards (Fool), chain length bonus (Hierophant),
##            excluded indices (Lovers reversed), extra suits (Moon).

static func detect_chains(placed_cards: Array, modifiers: Dictionary = {}) -> Array:
	## Returns array of chain dictionaries.
	## modifiers: { wild_suit_indices, chain_length_bonus,
	##              chain_excluded_indices, extra_suit_cards }

	var wild_indices: Array = modifiers.get("wild_suit_indices", [])
	var length_bonus: int = modifiers.get("chain_length_bonus", 0)
	var excluded: Array = modifiers.get("chain_excluded_indices", [])
	var extra_suits: Dictionary = modifiers.get("extra_suit_cards", {})

	# Build position map: "row,col" -> index in placed_cards
	var pos_map: Dictionary = {}
	for i in range(placed_cards.size()):
		var pd: Resource = placed_cards[i].position_data
		pos_map["%d,%d" % [pd.row, pd.col]] = i

	# Group indices by suit (skip excluded cards)
	var suit_indices: Dictionary = {}
	for i in range(placed_cards.size()):
		if i in excluded:
			continue

		var suit: String = placed_cards[i].card.card_data.suit

		if i in wild_indices:
			# Wild cards join ALL elemental suit groups
			for s in ["cups", "wands", "swords", "pentacles"]:
				if not suit_indices.has(s):
					suit_indices[s] = []
				suit_indices[s].append(i)
		elif suit == "major":
			continue
		else:
			if not suit_indices.has(suit):
				suit_indices[suit] = []
			suit_indices[suit].append(i)

		# Extra suit from Moon (add to second suit group)
		if extra_suits.has(i):
			var extra: String = extra_suits[i]
			if not suit_indices.has(extra):
				suit_indices[extra] = []
			if i not in suit_indices[extra]:
				suit_indices[extra].append(i)

	# Find connected components per suit
	var chains: Array = []
	for suit in suit_indices:
		var components := _find_connected_components(
			suit_indices[suit], placed_cards, pos_map)
		for component in components:
			if component.size() >= 2:
				chains.append(_build_chain_data(component, placed_cards, suit, length_bonus))

	return chains


static func _find_connected_components(
		indices: Array, placed_cards: Array, pos_map: Dictionary) -> Array:
	var index_set: Dictionary = {}
	for idx in indices:
		index_set[idx] = true

	var visited: Dictionary = {}
	var components: Array = []

	for idx in indices:
		if visited.has(idx):
			continue
		var component: Array = []
		var stack: Array = [idx]
		while not stack.is_empty():
			var current: int = stack.pop_back()
			if visited.has(current):
				continue
			visited[current] = true
			component.append(current)
			for neighbor in _get_adjacent_indices(current, placed_cards, pos_map):
				if index_set.has(neighbor) and not visited.has(neighbor):
					stack.append(neighbor)
		components.append(component)

	return components


static func _get_adjacent_indices(
		idx: int, placed_cards: Array, pos_map: Dictionary) -> Array:
	var pd: Resource = placed_cards[idx].position_data
	var neighbors: Array = []
	for dir in [[0, 1], [0, -1], [1, 0], [-1, 0]]:
		var key := "%d,%d" % [pd.row + dir[0], pd.col + dir[1]]
		if pos_map.has(key):
			neighbors.append(pos_map[key])
	return neighbors


static func _build_chain_data(
		indices: Array, placed_cards: Array, suit: String,
		length_bonus: int = 0) -> Dictionary:
	var length: int = indices.size()
	var has_ace := false
	var has_ten := false

	for idx in indices:
		var num: int = placed_cards[idx].card.card_data.card_number
		if num == 1:
			has_ace = true
		elif num == 10:
			has_ten = true

	var perfect := has_ace and has_ten
	# Chain length bonus: treat chain as longer for multiplier tier
	var effective_length: int = length + length_bonus

	return {
		"suit": suit,
		"length": length,
		"card_indices": indices.duplicate(),
		"base_multiplier": _get_chain_multiplier(effective_length),
		"has_ace": has_ace,
		"has_ten": has_ten,
		"ace_bonus_per_card": 2.0 if has_ace else 0.0,
		"ten_multiplier": 1.5 if has_ten else 1.0,
		"perfect_chain": perfect,
		"perfect_multiplier": 2.0 if perfect else 1.0,
	}


static func _get_chain_multiplier(length: int) -> float:
	if length >= 5:
		return 7.0
	match length:
		2: return 1.5
		3: return 2.5
		4: return 4.0
	return 1.0
