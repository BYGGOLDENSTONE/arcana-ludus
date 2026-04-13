extends Node2D
## Manages a row of cards at the bottom of the screen.
## Phase 4.5: supports multi-select (up to MAX_SELECTED cards).

signal card_selected(card: Node2D)
signal card_deselected(card: Node2D)
signal selection_changed(count: int)

const CARD_WIDTH_NORMAL := 105.0  # 350 * 0.30
const CARD_WIDTH_SELECTED := 133.0  # 350 * 0.38
const GAP := 12.0
const CARD_SPACING := 117.0  # CARD_WIDTH_NORMAL + GAP
const ARRANGE_DURATION := 0.25
const MAX_SELECTED := 3

var cards: Array[Node2D] = []
var selected_cards: Array[Node2D] = []

@onready var card_container: Node2D = $CardContainer


func add_card(card: Node2D) -> void:
	cards.append(card)
	card_container.add_child(card)
	card.is_in_hand = true
	card.selected.connect(_on_card_selected)
	card.deselected.connect(_on_card_deselected)
	_arrange_cards()


func remove_card(card: Node2D) -> void:
	if card in cards:
		cards.erase(card)
		card.is_in_hand = false
		if card in selected_cards:
			selected_cards.erase(card)
		if card.selected.is_connected(_on_card_selected):
			card.selected.disconnect(_on_card_selected)
		if card.deselected.is_connected(_on_card_deselected):
			card.deselected.disconnect(_on_card_deselected)
		if card.get_parent() == card_container:
			card_container.remove_child(card)
		_arrange_cards()


func remove_cards(cards_to_remove: Array) -> void:
	for card in cards_to_remove:
		if card in cards:
			cards.erase(card)
			card.is_in_hand = false
			if card in selected_cards:
				selected_cards.erase(card)
			if card.selected.is_connected(_on_card_selected):
				card.selected.disconnect(_on_card_selected)
			if card.deselected.is_connected(_on_card_deselected):
				card.deselected.disconnect(_on_card_deselected)
			if card.get_parent() == card_container:
				card_container.remove_child(card)
	_arrange_cards()
	selection_changed.emit(selected_cards.size())
	EventBus.hand_selection_changed.emit(selected_cards.size())


func clear_hand() -> void:
	selected_cards.clear()
	for card in cards.duplicate():
		remove_card(card)
		card.queue_free()
	cards.clear()


func deselect_all() -> void:
	for card in selected_cards.duplicate():
		card.deselect()
	selected_cards.clear()
	selection_changed.emit(0)
	EventBus.hand_selection_changed.emit(0)


func get_selected_cards() -> Array[Node2D]:
	return selected_cards


func get_selected_count() -> int:
	return selected_cards.size()


func _arrange_cards(animate: bool = true) -> void:
	var count := cards.size()
	if count == 0:
		return

	# Calculate total width accounting for selected cards being wider
	var total_width := 0.0
	for i in range(count):
		if cards[i] in selected_cards:
			total_width += CARD_WIDTH_SELECTED
		else:
			total_width += CARD_WIDTH_NORMAL
		if i < count - 1:
			total_width += GAP

	var start_x := -total_width * 0.5
	var current_x := start_x

	for i in range(count):
		var card := cards[i]
		var is_sel := card in selected_cards
		var card_w := CARD_WIDTH_SELECTED if is_sel else CARD_WIDTH_NORMAL

		var target_pos := Vector2(current_x + card_w * 0.5, 0)

		card.z_index = i
		if is_sel:
			card.z_index = count + 1

		card._original_position = card_container.global_position + target_pos

		if animate:
			var tween := card.create_tween()
			tween.set_ease(Tween.EASE_OUT)
			tween.set_trans(Tween.TRANS_CUBIC)
			tween.tween_property(card, "position", target_pos, ARRANGE_DURATION)
		else:
			card.position = target_pos

		current_x += card_w + GAP


func _on_card_selected(card: Node2D) -> void:
	if selected_cards.size() >= MAX_SELECTED:
		# Already at max — reject the selection
		card.deselect()
		return
	if card not in selected_cards:
		selected_cards.append(card)
	_arrange_cards()
	card_selected.emit(card)
	selection_changed.emit(selected_cards.size())
	EventBus.hand_selection_changed.emit(selected_cards.size())


func _on_card_deselected(card: Node2D) -> void:
	if card in selected_cards:
		selected_cards.erase(card)
	_arrange_cards()
	card_deselected.emit(card)
	selection_changed.emit(selected_cards.size())
	EventBus.hand_selection_changed.emit(selected_cards.size())
