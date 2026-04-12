extends Node2D
## Phase 1 test scene: displays a hand of cards, supports select, drag, and flip.

const CARD_SCENE := preload("res://components/card/card.tscn")
const HAND_SIZE := 7

@onready var hand: Node2D = $Hand
@onready var draw_button: Button = $UI/DrawButton
@onready var info_label: Label = $UI/InfoLabel


func _ready() -> void:
	draw_button.pressed.connect(_on_draw_pressed)
	EventBus.card_hovered.connect(_on_card_hovered)
	EventBus.card_unhovered.connect(_on_card_unhovered)
	EventBus.card_flipped.connect(_on_card_flipped)
	EventBus.card_clicked.connect(_on_card_selected)
	_draw_new_hand()


func _draw_new_hand() -> void:
	hand.clear_hand()

	var all_cards := DataLoader.get_demo_deck()
	if all_cards.is_empty():
		info_label.text = "No cards loaded!"
		return

	all_cards.shuffle()
	var draw_count := mini(HAND_SIZE, all_cards.size())

	for i in range(draw_count):
		var card_instance = CARD_SCENE.instantiate()
		hand.add_card(card_instance)
		card_instance.setup(all_cards[i])

	info_label.text = "Click to select | Right-click to flip | Drag to move | %d cards" % draw_count


func _on_draw_pressed() -> void:
	_draw_new_hand()


func _on_card_selected(card: Node2D) -> void:
	if card.card_data:
		var orientation := "REVERSED" if card.is_reversed else "Upright"
		info_label.text = "SELECTED: %s | %s | Insight: %d | %s" % [
			card.card_data.card_name,
			card.card_data.suit.capitalize(),
			card.card_data.base_insight,
			orientation
		]


func _on_card_hovered(card: Node2D) -> void:
	if card.card_data and not card.is_selected:
		var orientation := "Reversed" if card.is_reversed else "Upright"
		info_label.text = "%s | %s | Insight: %d | %s" % [
			card.card_data.card_name,
			card.card_data.suit.capitalize(),
			card.card_data.base_insight,
			orientation
		]


func _on_card_unhovered(_card: Node2D) -> void:
	if hand.selected_card and hand.selected_card.card_data:
		var sc = hand.selected_card
		var orientation := "REVERSED" if sc.is_reversed else "Upright"
		info_label.text = "SELECTED: %s | %s | Insight: %d | %s" % [
			sc.card_data.card_name,
			sc.card_data.suit.capitalize(),
			sc.card_data.base_insight,
			orientation
		]
	else:
		info_label.text = "Click to select | Right-click to flip | Drag to move | %d cards" % hand.cards.size()


func _on_card_flipped(card: Node2D, is_reversed: bool) -> void:
	if card.card_data:
		var orientation := "REVERSED" if is_reversed else "Upright"
		info_label.text = "%s flipped to %s" % [card.card_data.card_name, orientation]
