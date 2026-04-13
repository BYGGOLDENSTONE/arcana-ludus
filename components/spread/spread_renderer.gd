extends Node2D
## Renders the 3×3 spread grid and manages row-by-row card placement.
## Phase 4.5: no drag-drop. Cards placed programmatically per row.

signal card_placed(slot: Node2D, card: Node2D)
signal row_filled(row: int)
signal all_slots_filled()

const SpreadSlotScene := preload("res://components/spread/spread_slot.tscn")
const MatchCalc = preload("res://scripts/utils/match_calculator.gd")
const SLOT_SPACING := Vector2(165, 245)
const ROW_LABELS := ["Past", "Present", "Future"]
const ROW_NAMES := ["past", "present", "future"]

var spread_data: Resource  # SpreadData
var slots: Array[Node2D] = []
var _active_row: int = -1

@onready var slot_container: Node2D = $SlotContainer
@onready var row_label_container: Node2D = $RowLabels


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
		label.add_theme_color_override("font_color", Color(0.78, 0.70, 0.50, 0.7))
		row_label_container.add_child(label)


func _clear_slots() -> void:
	for slot in slots:
		slot.queue_free()
	slots.clear()


func set_active_row(row: int, animate: bool = false) -> void:
	_active_row = row
	for i in range(slots.size()):
		var slot: Node2D = slots[i]
		var slot_row: int = slot.position_data.row
		if slot_row == row:
			if animate and slot.modulate.a < 0.1:
				slot.is_active = true
				var tween := slot.create_tween()
				tween.set_ease(Tween.EASE_OUT)
				tween.set_trans(Tween.TRANS_CUBIC)
				tween.tween_property(slot, "modulate:a", 1.0, 0.35)
			else:
				slot.set_active(true)
		elif slot.is_occupied:
			slot.set_locked()
		elif slot_row > row:
			slot.set_hidden()
		else:
			slot.set_active(false)

	# Update row labels
	var labels := row_label_container.get_children()
	for r in range(labels.size()):
		var label: Label = labels[r]
		if r == row:
			label.visible = true
			if animate:
				label.modulate.a = 0.0
				var tween := label.create_tween()
				tween.tween_property(label, "modulate:a", 1.0, 0.35)
			label.add_theme_color_override("font_color", Color(0.90, 0.75, 0.30, 1.0))
		elif r < row:
			label.visible = true
			label.add_theme_color_override("font_color", Color(0.50, 0.45, 0.35, 0.5))
		else:
			label.visible = false


func place_cards_in_row(row: int, card_nodes: Array) -> void:
	## Place cards into the given row's slots (auto-assign left to right).
	var row_slots := get_row_slots(row)
	for i in range(mini(card_nodes.size(), row_slots.size())):
		var card: Node2D = card_nodes[i]
		var slot: Node2D = row_slots[i]
		_place_card_in_slot(card, slot, i)


func _place_card_in_slot(card: Node2D, slot: Node2D, delay_index: int) -> void:
	slot.place_card(card)
	card.is_in_hand = false
	card.is_locked = true

	# Reparent card from hand to spread container
	var saved_global_pos := card.global_position
	if card.get_parent():
		card.get_parent().remove_child(card)
	slot_container.add_child(card)
	card.global_position = saved_global_pos

	# CardVisual is at local y=-300, so offset to center card image on slot
	var visual_offset := Vector2(0, 300.0 * card.scale.y)
	var target_pos: Vector2 = slot.get_snap_position() + visual_offset

	# Staggered animation for each card in the row
	var tween := card.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	if delay_index > 0:
		tween.tween_interval(delay_index * 0.12)
	tween.tween_property(card, "global_position", target_pos, 0.3)
	tween.tween_property(card, "scale", card.NORMAL_SCALE, 0.15)
	tween.tween_callback(func():
		card.z_index = 10
		if card.select_glow:
			card.select_glow.visible = false
	)

	card_placed.emit(slot, card)
	EventBus.card_placed_on_spread.emit(card, slot)


func lock_row(row: int) -> void:
	for slot in get_row_slots(row):
		slot.set_locked()


func get_row_slots(row: int) -> Array:
	var result: Array = []
	for slot in slots:
		if slot.position_data.row == row:
			result.append(slot)
	# Sort by column
	result.sort_custom(func(a, b): return a.position_data.col < b.position_data.col)
	return result


func is_row_filled(row: int) -> bool:
	for slot in get_row_slots(row):
		if not slot.is_occupied:
			return false
	return true


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


func get_row_placed_cards(row: int) -> Array:
	var result: Array = []
	for slot in get_row_slots(row):
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
