extends Node2D
## Renders the 3×3 spread grid and manages card placement into slots.

signal card_placed(slot: Node2D, card: Node2D)
signal all_slots_filled()
signal slot_hover_started(slot: Node2D, card: Node2D)
signal slot_hover_ended(slot: Node2D)

const SpreadSlotScene := preload("res://components/spread/spread_slot.tscn")
const MatchCalc = preload("res://scripts/utils/match_calculator.gd")
const SLOT_SPACING := Vector2(165, 245)
const ROW_LABELS := ["Past", "Present", "Future"]

var spread_data: Resource  # SpreadData
var slots: Array[Node2D] = []
var _dragging_card: Node2D = null

@onready var slot_container: Node2D = $SlotContainer
@onready var row_label_container: Node2D = $RowLabels


func _ready() -> void:
	EventBus.card_drag_started.connect(_on_card_drag_started)
	EventBus.card_drag_ended.connect(_on_card_drag_ended)


func setup(data: Resource) -> void:
	spread_data = data
	_clear_slots()
	_create_slots()
	_create_row_labels()


func _create_slots() -> void:
	for i in range(spread_data.positions.size()):
		var pos_data: Resource = spread_data.positions[i]
		var slot: Node2D = SpreadSlotScene.instantiate()
		slot_container.add_child(slot)

		var grid_pos := Vector2(pos_data.col, pos_data.row)
		var offset := Vector2(
			(grid_pos.x - 1) * SLOT_SPACING.x,
			(grid_pos.y - 1) * SLOT_SPACING.y
		)
		slot.position = offset
		slot.setup(pos_data)
		slot.slot_hovered.connect(_on_slot_hovered)
		slot.slot_unhovered.connect(_on_slot_unhovered)
		slots.append(slot)


func _create_row_labels() -> void:
	for child in row_label_container.get_children():
		child.queue_free()

	for row in range(3):
		var label := Label.new()
		label.text = ROW_LABELS[row]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		label.position = Vector2(
			-1.5 * SLOT_SPACING.x - 30,
			(row - 1) * SLOT_SPACING.y - 8
		)
		label.add_theme_font_size_override("font_size", 14)
		label.add_theme_color_override("font_color", Color(0.7, 0.6, 0.9, 0.7))
		row_label_container.add_child(label)


func _clear_slots() -> void:
	for slot in slots:
		slot.queue_free()
	slots.clear()


func _on_card_drag_started(card: Node2D) -> void:
	_dragging_card = card


func _on_card_drag_ended(card: Node2D, drop_pos: Vector2) -> void:
	if not _dragging_card:
		return

	# Adjust drop position to account for CardVisual offset (card image center vs node origin)
	var visual_center: Vector2 = drop_pos - Vector2(0, 300.0 * card.scale.y)
	var closest_slot: Node2D = _find_closest_slot(visual_center)
	if closest_slot and not closest_slot.is_occupied:
		_place_card_in_slot(card, closest_slot)

	_dragging_card = null
	_clear_all_previews()


func _on_slot_hovered(slot: Node2D) -> void:
	if _dragging_card and not slot.is_occupied:
		var match_result := MatchCalc.calculate_match(
			_dragging_card.card_data, slot.position_data)
		slot.show_match_preview(match_result.color)
		slot_hover_started.emit(slot, _dragging_card)


func _on_slot_unhovered(slot: Node2D) -> void:
	slot.clear_match_preview()
	slot_hover_ended.emit(slot)


func _find_closest_slot(pos: Vector2) -> Node2D:
	var best_slot: Node2D = null
	var best_dist := 200.0  # max snap distance
	for slot in slots:
		if slot.is_occupied:
			continue
		var dist := pos.distance_to(slot.global_position)
		if dist < best_dist:
			best_dist = dist
			best_slot = slot
	return best_slot


func _place_card_in_slot(card: Node2D, slot: Node2D) -> void:
	slot.place_card(card)
	card.is_in_hand = false

	# Reparent card from hand to spread container
	var saved_global_pos := card.global_position
	if card.get_parent():
		card.get_parent().remove_child(card)
	slot_container.add_child(card)
	card.global_position = saved_global_pos

	# CardVisual is at local y=-300, so we offset to center card image on slot
	var visual_offset := Vector2(0, 300.0 * card.scale.y)
	var target_pos: Vector2 = slot.get_snap_position() + visual_offset

	# Animate card snapping into position
	var tween := card.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(card, "global_position", target_pos, 0.25)
	tween.tween_callback(func():
		card.z_index = 10
	)

	card_placed.emit(slot, card)
	EventBus.card_placed_on_spread.emit(card, slot)

	if _all_filled():
		all_slots_filled.emit()
		EventBus.all_spread_slots_filled.emit()


func _all_filled() -> bool:
	for slot in slots:
		if not slot.is_occupied:
			return false
	return true


func _clear_all_previews() -> void:
	for slot in slots:
		if not slot.is_occupied:
			slot.clear_match_preview()


func get_placed_cards() -> Array:
	## Returns array of { slot: Node2D, card: Node2D, position_data: Resource }
	var result: Array = []
	for slot in slots:
		if slot.is_occupied:
			result.append({
				"slot": slot,
				"card": slot.placed_card,
				"position_data": slot.position_data,
			})
	return result


func clear_all_cards() -> void:
	for slot in slots:
		if slot.is_occupied:
			var card: Node2D = slot.remove_placed_card()
			if card:
				card.queue_free()


func get_filled_count() -> int:
	var count := 0
	for slot in slots:
		if slot.is_occupied:
			count += 1
	return count
