extends Node2D
## Gameplay scene: draw hand from DeckManager, place cards in 3x3 spread, score.
## Implements Phase 3 — refactored to work within the Night/Run flow.
## Called by GameScene; does NOT create its own deck.

signal reading_finished(score: int, target: int)

const CARD_SCENE := preload("res://components/card/card.tscn")
const SpreadDataScript = preload("res://scripts/resources/spread_data.gd")
const HAND_SIZE := 12

@onready var hand: Node2D = $Hand
@onready var spread: Node2D = $SpreadRenderer
@onready var read_button: Button = $UI/ReadButton
@onready var score_label: Label = $UI/ScoreLabel
@onready var target_label: Label = $UI/TargetLabel
@onready var info_label: Label = $UI/InfoLabel
@onready var placed_count_label: Label = $UI/PlacedCountLabel
@onready var querent_info_label: Label = $UI/QuerentInfoLabel

var _reading_active: bool = false
var _scoring_done: bool = false
var _current_querent: Resource = null
var _hand_card_data: Array = []  # CardData resources drawn from DeckManager


func _ready() -> void:
	read_button.pressed.connect(_on_read_pressed)
	read_button.disabled = true

	EventBus.card_placed_on_spread.connect(_on_card_placed_on_spread)
	EventBus.all_spread_slots_filled.connect(_on_all_slots_filled)
	EventBus.card_hovered.connect(_on_card_hovered)
	EventBus.card_unhovered.connect(_on_card_unhovered)
	EventBus.card_flipped.connect(_on_card_flipped)

	spread.card_placed.connect(_on_spread_card_placed)

	# Hide until start_reading is called
	visible = false


func start_reading(querent: Resource) -> void:
	_current_querent = querent
	_reading_active = true
	_scoring_done = false
	visible = true

	# Clear previous reading
	spread.clear_all_cards()

	# Create the standard 3x3 spread
	var spread_data: Resource = SpreadDataScript.create_standard_spread()
	spread.setup(spread_data)

	# Set target from querent
	ScoreManager.set_target(querent.target_score)
	_update_target_display()

	# Display querent info
	_update_querent_display()

	# Draw hand from DeckManager
	_draw_hand()

	score_label.text = "Score: 0"
	info_label.text = "Drag cards onto the spread. Right-click to flip upright/reversed."
	read_button.text = "Read"
	read_button.disabled = true
	_update_placed_count()


func _draw_hand() -> void:
	hand.clear_hand()
	_hand_card_data.clear()

	var drawn_cards: Array = DeckManager.draw(HAND_SIZE)
	if drawn_cards.is_empty():
		info_label.text = "No cards to draw!"
		return

	_hand_card_data = drawn_cards

	for card_data in drawn_cards:
		var card_instance: Node2D = CARD_SCENE.instantiate()
		hand.add_card(card_instance)
		card_instance.setup(card_data)


func _update_querent_display() -> void:
	if not _current_querent or not querent_info_label:
		return
	querent_info_label.text = "%s | %s | %s" % [
		_current_querent.querent_name,
		_current_querent.question_theme.capitalize(),
		_current_querent.personality_type.capitalize(),
	]


func _on_card_placed_on_spread(card: Node, _slot: Node) -> void:
	hand.remove_card(card)
	_update_placed_count()


func _on_spread_card_placed(_slot: Node2D, _card: Node2D) -> void:
	pass


func _on_all_slots_filled() -> void:
	read_button.disabled = false
	info_label.text = "All positions filled! Press 'Read' to score the reading."


func _on_read_pressed() -> void:
	if _scoring_done:
		# Scoring already shown; this press is handled by GameScene via signal
		return

	read_button.disabled = true
	_reading_active = false

	var placed_cards: Array = spread.get_placed_cards()
	var total := ScoreManager.score_reading(placed_cards)

	# Display results
	score_label.text = "Score: %d" % total
	var target := ScoreManager.target_score
	var met := ScoreManager.is_target_met()

	# Build result text with chain/combo summary
	var result_parts: Array = []
	if met:
		result_parts.append("Score %d / %d -- SUCCESS!" % [total, target])
	else:
		result_parts.append("Score %d / %d -- Not enough..." % [total, target])

	var chains := ScoreManager.get_detected_chains()
	if not chains.is_empty():
		var chain_names: Array = []
		for chain in chains:
			chain_names.append("%s(%d) x%.1f" % [
				chain.suit.capitalize(), chain.length, chain.base_multiplier])
			if chain.perfect_chain:
				chain_names[-1] += " PERFECT!"
		result_parts.append("Chains: %s" % ", ".join(chain_names))

	var combos := ScoreManager.get_detected_combos()
	if not combos.is_empty():
		var combo_names: Array = []
		for combo in combos:
			combo_names.append(combo.name)
		result_parts.append("Combos: %s" % ", ".join(combo_names))

	info_label.text = " | ".join(result_parts)

	_show_score_breakdown()
	_scoring_done = true

	# Return unused hand cards to draw pile, discard placed cards
	_return_cards_to_deck()

	# Notify parent that reading is done
	reading_finished.emit(total, target)


func _return_cards_to_deck() -> void:
	# Collect card_data from cards still in hand
	var unused_data: Array = []
	for card_node in hand.cards.duplicate():
		if card_node.card_data:
			unused_data.append(card_node.card_data)
	DeckManager.return_to_deck(unused_data)

	# Collect card_data from placed cards and discard them
	var placed_data: Array = []
	var placed_cards: Array = spread.get_placed_cards()
	for entry in placed_cards:
		var card_node: Node2D = entry.card
		if card_node.card_data:
			placed_data.append(card_node.card_data)
	DeckManager.discard_placed(placed_data)


func cleanup() -> void:
	## Clean up the reading scene so it can be reused or freed.
	spread.clear_all_cards()
	hand.clear_hand()
	_hand_card_data.clear()
	_current_querent = null
	visible = false


func _show_score_breakdown() -> void:
	var breakdown: Array = ScoreManager.get_score_breakdown()
	for entry in breakdown:
		var card: Node = entry.card
		var value_lbl: Label = card.get_node_or_null("CardVisual/CardFront/ValueLabel")
		if value_lbl:
			value_lbl.text = "%d" % entry.total


func _update_placed_count() -> void:
	var filled: int = spread.get_filled_count()
	placed_count_label.text = "%d / 9 placed" % filled
	if filled > 0 and filled < 9:
		read_button.disabled = true
		read_button.text = "Read"


func _update_target_display() -> void:
	target_label.text = "Target: %d" % ScoreManager.target_score


func _on_card_hovered(card: Node) -> void:
	if not card.card_data or _scoring_done:
		return
	var orientation := "Reversed" if card.is_reversed else "Upright"
	info_label.text = "%s | %s | Insight: %d | %s" % [
		card.card_data.card_name,
		card.card_data.suit.capitalize(),
		card.card_data.base_insight,
		orientation
	]


func _on_card_unhovered(_card: Node) -> void:
	if _scoring_done:
		return
	var filled: int = spread.get_filled_count()
	if filled >= 9:
		info_label.text = "All positions filled! Press 'Read' to score the reading."
	else:
		info_label.text = "Drag cards onto the spread. Right-click to flip upright/reversed."


func _on_card_flipped(card: Node, is_reversed: bool) -> void:
	if not card.card_data:
		return
	var orientation := "REVERSED" if is_reversed else "Upright"
	info_label.text = "%s flipped to %s" % [card.card_data.card_name, orientation]
