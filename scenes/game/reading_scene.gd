extends Node2D
## Main gameplay scene: draw hand, place cards in 3×3 spread, trigger reading.

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

var _reading_active: bool = false
var _scoring_done: bool = false


func _ready() -> void:
	read_button.pressed.connect(_on_read_pressed)
	read_button.disabled = true

	EventBus.card_placed_on_spread.connect(_on_card_placed_on_spread)
	EventBus.all_spread_slots_filled.connect(_on_all_slots_filled)
	EventBus.card_hovered.connect(_on_card_hovered)
	EventBus.card_unhovered.connect(_on_card_unhovered)
	EventBus.card_flipped.connect(_on_card_flipped)

	spread.card_placed.connect(_on_spread_card_placed)

	_setup_reading()


func _setup_reading() -> void:
	_reading_active = true
	_scoring_done = false

	# Clear previous reading's cards from spread
	spread.clear_all_cards()

	# Create the standard 3×3 spread
	var spread_data: Resource = SpreadDataScript.create_standard_spread()
	spread.setup(spread_data)

	# Set a target score (placeholder — will come from querent system in Phase 3)
	ScoreManager.set_target(300)
	_update_target_display()

	# Draw hand from deck
	_draw_hand()

	score_label.text = "Score: 0"
	info_label.text = "Drag cards onto the spread. Right-click to flip upright/reversed."
	read_button.text = "Read"
	read_button.disabled = true
	_update_placed_count()


func _draw_hand() -> void:
	hand.clear_hand()

	var all_cards: Array = DataLoader.get_demo_deck()
	if all_cards.is_empty():
		info_label.text = "No cards loaded!"
		return

	all_cards.shuffle()
	var draw_count := mini(HAND_SIZE, all_cards.size())

	for i in range(draw_count):
		var card_instance: Node2D = CARD_SCENE.instantiate()
		hand.add_card(card_instance)
		card_instance.setup(all_cards[i])


func _on_card_placed_on_spread(card: Node, _slot: Node) -> void:
	# Remove card from hand tracking
	hand.remove_card(card)
	_update_placed_count()


func _on_spread_card_placed(_slot: Node2D, _card: Node2D) -> void:
	pass


func _on_all_slots_filled() -> void:
	read_button.disabled = false
	info_label.text = "All positions filled! Press 'Read' to score the reading."


func _on_read_pressed() -> void:
	if _scoring_done:
		# Reset for next reading
		_setup_reading()
		return

	read_button.disabled = true
	_reading_active = false

	var placed_cards: Array = spread.get_placed_cards()
	var total := ScoreManager.score_reading(placed_cards)

	# Display results
	score_label.text = "Score: %d" % total
	var target := ScoreManager.target_score
	var met := ScoreManager.is_target_met()

	if met:
		info_label.text = "Reading complete! Score %d / %d — SUCCESS! Gold earned." % [total, target]
	else:
		info_label.text = "Reading complete! Score %d / %d — Not enough..." % [total, target]

	# Show per-card breakdown
	_show_score_breakdown()

	_scoring_done = true
	read_button.text = "Next Reading"
	read_button.disabled = false


func _show_score_breakdown() -> void:
	var breakdown: Array = ScoreManager.get_score_breakdown()
	for entry in breakdown:
		var card: Node = entry.card
		if card.has_method("get") or true:
			# Update the value label on the card to show actual score
			var value_label: Label = card.get_node_or_null("CardVisual/CardFront/ValueLabel")
			if value_label:
				value_label.text = "%d" % entry.total


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
