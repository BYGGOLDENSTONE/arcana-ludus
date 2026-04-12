extends Node2D
## Manages a fan of cards at the bottom of the screen.

signal card_selected(card: Node2D)
signal card_deselected(card: Node2D)

const FAN_ANGLE_MAX := 20.0  # degrees, total spread
const CARD_SPACING := 120.0
const HOVER_LIFT := -40.0
const SELECTED_LIFT := -100.0
const ARRANGE_DURATION := 0.3

var cards: Array[Node2D] = []
var selected_card: Node2D = null
var _hovered_card: Node2D = null

@onready var card_container: Node2D = $CardContainer


func add_card(card: Node2D) -> void:
	cards.append(card)
	card_container.add_child(card)
	card.is_in_hand = true
	card.hovered.connect(_on_card_hovered)
	card.unhovered.connect(_on_card_unhovered)
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
		card.hovered.disconnect(_on_card_hovered)
		card.unhovered.disconnect(_on_card_unhovered)
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

	var total_width := (count - 1) * CARD_SPACING
	var start_x := -total_width * 0.5

	var angle_step := 0.0
	var start_angle := 0.0
	if count > 1:
		angle_step = FAN_ANGLE_MAX / (count - 1)
		start_angle = -FAN_ANGLE_MAX * 0.5

	for i in range(count):
		var card := cards[i]
		var target_x := start_x + i * CARD_SPACING
		var target_angle := start_angle + i * angle_step if count > 1 else 0.0
		var target_pos := Vector2(target_x, 0)

		# Slight arc: cards at edges are slightly lower
		var normalized := 0.0
		if count > 1:
			normalized = (float(i) / (count - 1)) * 2.0 - 1.0
		target_pos.y += normalized * normalized * 20.0

		# Selected card lifts up
		if card == selected_card:
			target_pos.y += SELECTED_LIFT

		card.z_index = i
		if card == selected_card:
			card.z_index = count + 1
		card._original_position = card_container.global_position + target_pos

		if animate:
			var tween := card.create_tween()
			tween.set_ease(Tween.EASE_OUT)
			tween.set_trans(Tween.TRANS_CUBIC)
			tween.set_parallel(true)
			tween.tween_property(card, "position", target_pos, ARRANGE_DURATION)
			tween.tween_property(card, "rotation_degrees", target_angle, ARRANGE_DURATION)
		else:
			card.position = target_pos
			card.rotation_degrees = target_angle


func _on_card_selected(card: Node2D) -> void:
	# Deselect previous card
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


func _on_card_hovered(card: Node2D) -> void:
	_hovered_card = card
	if not card.is_dragging and not card.is_selected:
		var tween := card.create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(card, "position:y", card.position.y + HOVER_LIFT, 0.15)


func _on_card_unhovered(card: Node2D) -> void:
	if _hovered_card == card:
		_hovered_card = null
	if not card.is_dragging and not card.is_selected:
		_arrange_cards()


func _on_card_drag_started(_card: Node2D) -> void:
	pass


func _on_card_drag_ended(card: Node2D) -> void:
	card._original_position = card_container.global_position + card.position
	_arrange_cards()
