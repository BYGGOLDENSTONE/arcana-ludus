class_name ComboDetector
## Detects cross-element combos and numerological combos in a spread.
## Phase 4: Steam, Wildfire, Growth, Erosion, Forge, Storm +
##          Pairs, Triples, Quads, Number Runs.
## Phase 5.4: Supports all_element_indices (Magician upright — all 4 suits).

## Cross-element combo definitions (suits sorted alphabetically for consistency)
const CROSS_COMBOS := {
	"steam":    { "suits": ["cups", "wands"],      "name": "Steam",    "desc": "Fire + Water" },
	"wildfire": { "suits": ["swords", "wands"],    "name": "Wildfire", "desc": "Fire + Air" },
	"growth":   { "suits": ["cups", "pentacles"],  "name": "Growth",   "desc": "Water + Earth" },
	"erosion":  { "suits": ["pentacles", "swords"], "name": "Erosion", "desc": "Air + Earth" },
	"forge":    { "suits": ["pentacles", "wands"],  "name": "Forge",   "desc": "Fire + Earth" },
	"storm":    { "suits": ["cups", "swords"],      "name": "Storm",   "desc": "Water + Air" },
}


static func detect_cross_element_combos(placed_cards: Array, modifiers: Dictionary = {}) -> Array:
	## Detect adjacent different-suit pairs that trigger elemental combos.
	## modifiers: { all_element_indices: Array } — cards that count as all 4 suits.
	## Returns array of { combo_id, name, description, card_indices }.
	var all_element_indices: Array = modifiers.get("all_element_indices", [])

	var pos_map: Dictionary = {}
	for i in range(placed_cards.size()):
		var pd: Resource = placed_cards[i].position_data
		pos_map["%d,%d" % [pd.row, pd.col]] = i

	var combos: Array = []
	var found: Dictionary = {}

	for i in range(placed_cards.size()):
		var suit_a: String = placed_cards[i].card.card_data.suit
		var suits_a: Array

		if i in all_element_indices:
			suits_a = ["cups", "wands", "swords", "pentacles"]
		elif suit_a == "major":
			continue
		else:
			suits_a = [suit_a]

		var pd: Resource = placed_cards[i].position_data
		# Only check right and down to avoid duplicate pair detection
		for dir in [[0, 1], [1, 0]]:
			var key := "%d,%d" % [pd.row + dir[0], pd.col + dir[1]]
			if not pos_map.has(key):
				continue
			var j: int = pos_map[key]
			var suit_b: String = placed_cards[j].card.card_data.suit
			var suits_b: Array

			if j in all_element_indices:
				suits_b = ["cups", "wands", "swords", "pentacles"]
			elif suit_b == "major":
				continue
			else:
				suits_b = [suit_b]

			var pair_key := "%d-%d" % [mini(i, j), maxi(i, j)]
			for sa in suits_a:
				for sb in suits_b:
					if sa == sb:
						continue
					for combo_id in CROSS_COMBOS:
						var c: Dictionary = CROSS_COMBOS[combo_id]
						var s: Array = c.suits
						if (sa == s[0] and sb == s[1]) or \
						   (sa == s[1] and sb == s[0]):
							var unique_key: String = pair_key + ":" + str(combo_id)
							if not found.has(unique_key):
								found[unique_key] = true
								combos.append({
									"combo_id": combo_id,
									"name": c.name,
									"description": c.desc,
									"card_indices": [i, j],
								})

	return combos


static func detect_numerological_combos(placed_cards: Array) -> Array:
	## Detect pairs, triples, quads, and number runs among minor arcana.
	## Returns array of { type, name, number/numbers, card_indices }.
	var combos: Array = []

	# Group minor arcana card indices by number
	var number_groups: Dictionary = {}
	for i in range(placed_cards.size()):
		var card_data: Resource = placed_cards[i].card.card_data
		if card_data.suit == "major":
			continue
		var num: int = card_data.card_number
		if not number_groups.has(num):
			number_groups[num] = []
		number_groups[num].append(i)

	# Detect quads, triples, pairs (higher rank supersedes lower)
	for num in number_groups:
		var group: Array = number_groups[num]
		var suit_count := _count_unique_suits(group, placed_cards)

		if group.size() >= 4 and suit_count >= 4:
			combos.append({
				"type": "quad",
				"name": "Perfect Harmony",
				"number": num,
				"card_indices": group.duplicate(),
			})
		elif group.size() >= 3 and suit_count >= 3:
			combos.append({
				"type": "triple",
				"name": "Triple",
				"number": num,
				"card_indices": group.slice(0, 3),
			})
		elif group.size() == 2:
			combos.append({
				"type": "pair",
				"name": "Pair",
				"number": num,
				"card_indices": group.duplicate(),
			})

	# Detect number runs (3+ consecutive numbers)
	var sorted_numbers: Array = number_groups.keys()
	sorted_numbers.sort()
	_detect_runs(sorted_numbers, number_groups, combos)

	return combos


static func _count_unique_suits(indices: Array, placed_cards: Array) -> int:
	var suits: Dictionary = {}
	for idx in indices:
		suits[placed_cards[idx].card.card_data.suit] = true
	return suits.size()


static func _detect_runs(
		sorted_nums: Array, groups: Dictionary, combos: Array) -> void:
	if sorted_nums.size() < 3:
		return

	var run_start := 0
	for i in range(1, sorted_nums.size()):
		if sorted_nums[i] != sorted_nums[i - 1] + 1:
			_try_add_run(sorted_nums, run_start, i - 1, groups, combos)
			run_start = i
	_try_add_run(sorted_nums, run_start, sorted_nums.size() - 1, groups, combos)


static func _try_add_run(
		nums: Array, start: int, end_idx: int,
		groups: Dictionary, combos: Array) -> void:
	var length: int = end_idx - start + 1
	if length < 3:
		return

	var run_nums: Array = []
	var indices: Array = []
	for i in range(start, end_idx + 1):
		var num: int = nums[i]
		run_nums.append(num)
		indices.append(groups[num][0])

	combos.append({
		"type": "run",
		"name": "Number Run",
		"numbers": run_nums,
		"length": length,
		"card_indices": indices,
	})
