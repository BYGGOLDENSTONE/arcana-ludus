extends Node2D
## Manages a row of cards at the bottom of the screen.

signal card_selected(card: Node2D)
signal card_deselected(card: Node2D)

## Card is 350px wide. At scale 0.50 → 175px. At scale 0.75 → 262px.
## Normal spacing: 175 + 20 gap = 195px between centers.
## Selected card extra: (262 - 175) / 2 = 43px each side.
const CARD_WIDTH_NORMAL := 175.0  # 350 * 0.50
const CARD_WIDTH_SELECTED := 262.0  # 350 * 0.75
const GAP := 20.0
const CARD_SPACING := 195.0  # CARD_WIDTH_NORMAL + GAP
const SELECTED_LIFT := 0.0
const ARRANGE_DURATION := 0.25

var cards: Array[Node2D] = []
var selected_card: Node2D = null

@onready var card_container: Node2D = $CardContainer


func add_card(card: Node2D) -> void:
	cards.append(card)
	card_container.add_child(card)
	card.is_in_hand = true
	card.selected.connect(_on_card_selected)
	card.deselected.connect(_on_card_deselected)
	card.drag_started.connect(_on_card_drag_started)
	card.drag_ended.connect(_on_card_drag_ended)
	_arrange_cards()


func remove_card(card: Node2D) -> void:
	if card in cards:
		cards.erase(card)
		card.is_in_hand = false
		if selected_card == card:
			selected_card = null
		card.selected.disconnect(_on_card_selected)
		card.deselected.disconnect(_on_card_deselected)
		card.drag_started.disconnect(_on_card_drag_started)
		card.drag_ended.disconnect(_on_card_drag_ended)
		card_container.remove_child(card)
		_arrange_cards()


func clear_hand() -> void:
	selected_card = null
	for card in cards.duplicate():
		remove_card(card)
		card.queue_free()
	cards.clear()


func _arrange_cards(animate: bool = true) -> void:
	var count := cards.size()
	if count == 0:
		return

	var selected_idx := -1
	if selected_card:
		selected_idx = cards.find(selected_card)

	# Calculate total width
	var extra_space := (CARD_WIDTH_SELECTED - CARD_WIDTH_NORMAL) if selected_idx >= 0 else 0.0
	var total_width := float(count - 1) * CARD_SPACING + extra_space
	var start_x := -total_width * 0.5

	var current_x := start_x
	for i in range(count):
		var card := cards[i]

		# Before selected card, add half the extra space
		if i == selected_idx:
			current_x += extra_space * 0.5

		var target_pos := Vector2(current_x, 0)

		if card == selected_card:
			target_pos.y = SELECTED_LIFT

		card.z_index = i
		if card == selected_card:
			card.z_index = count + 1

		card._original_position = card_container.global_position + target_pos

		if animate:
			var tween := card.create_tween()
			tween.set_ease(Tween.EASE_OUT)
			tween.set_trans(Tween.TRANS_CUBIC)
			tween.tween_property(card, "position", target_pos, ARRANGE_DURATION)
		else:
			card.position = target_pos

		current_x += CARD_SPACING

		# After selected card, add remaining extra space
		if i == selected_idx:
			current_x += extra_space * 0.5


func _on_card_selected(card: Node2D) -> void:
	if selected_card and selected_card != card:
		selected_card.deselect()
	selected_card = card
	_arrange_cards()
	card_selected.emit(card)


func _on_card_deselected(card: Node2D) -> void:
	if selected_card == card:
		selected_card = null
	_arrange_cards()
	card_deselected.emit(card)


func _on_card_drag_started(_card: Node2D) -> void:
	pass


func _on_card_drag_ended(card: Node2D) -> void:
	card._original_position = card_container.global_position + card.position
	_arrange_cards()
