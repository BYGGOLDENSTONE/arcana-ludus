extends Node2D
## Gameplay scene: draw hand, place cards row-by-row, score progressively.
## Phase 4.5 — Row-by-row click-select placement (Past → Present → Future).
## Called by GameScene; does NOT create its own deck.

signal reading_finished(score: int, target: int)

const CARD_SCENE := preload("res://components/card/card.tscn")
const SpreadDataScript = preload("res://scripts/resources/spread_data.gd")
const HAND_SIZE := 12
const CARDS_PER_ROW := 3
const ROW_NAMES: Array[String] = ["Past", "Present", "Future"]

enum RowPhase { PAST = 0, PRESENT = 1, FUTURE = 2, DONE = 3 }

@onready var hand: Node2D = $Hand
@onready var spread: Node2D = $SpreadRenderer
@onready var phase_button: Button = $UI/ReadButton
@onready var score_label: Label = $UI/ScoreLabel
@onready var target_label: Label = $UI/TargetLabel
@onready var info_label: Label = $UI/InfoLabel
@onready var placed_count_label: Label = $UI/PlacedCountLabel
@onready var querent_info_label: Label = $UI/QuerentInfoLabel
@onready var veil_label: Label = $UI/VeilLabel

var _reading_active: bool = false
var _base_target: int = 0
var _current_phase: RowPhase = RowPhase.PAST
var _current_querent: Resource = null
var _hand_card_data: Array = []
var _row_scores: Array[int] = [0, 0, 0]


func _ready() -> void:
	phase_button.pressed.connect(_on_confirm_pressed)
	phase_button.disabled = true

	EventBus.card_hovered.connect(_on_card_hovered)
	EventBus.card_unhovered.connect(_on_card_unhovered)
	EventBus.card_flipped.connect(_on_card_flipped)

	hand.selection_changed.connect(_on_selection_changed)

	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not _reading_active or _current_phase == RowPhase.DONE:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE:
			if hand.get_selected_count() == CARDS_PER_ROW:
				_confirm_placement()
				get_viewport().set_input_as_handled()


func start_reading(querent: Resource) -> void:
	_current_querent = querent
	_reading_active = true
	_current_phase = RowPhase.PAST
	_row_scores = [0, 0, 0]
	visible = true

	# Clear previous reading
	spread.clear_all_cards()

	# Create the standard 3x3 spread
	var spread_data: Resource = SpreadDataScript.create_standard_spread()
	spread.setup(spread_data)

	# Set target from querent (adjusted for Veil tier)
	_base_target = querent.target_score
	ScoreManager.set_target(VeilManager.get_adjusted_target(_base_target))
	ScoreManager.reset_score()
	_update_target_display()
	_update_veil_display()

	# Display querent info
	_update_querent_display()

	# Trigger talisman before_reading hooks
	TalismanManager.on_before_reading()

	# Draw hand from DeckManager
	_draw_hand()

	# Activate first row
	spread.set_active_row(0)

	score_label.text = "Score: 0"
	_update_phase_display()
	phase_button.disabled = true


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


func _on_selection_changed(count: int) -> void:
	if _current_phase == RowPhase.DONE:
		return

	phase_button.disabled = count != CARDS_PER_ROW

	if count == CARDS_PER_ROW:
		phase_button.text = "Space: Place %s" % ROW_NAMES[_current_phase]
		info_label.text = "3 cards selected. Press Space or click the button to place them."
	elif count > 0:
		info_label.text = "Select %d more card%s for %s row." % [
			CARDS_PER_ROW - count,
			"s" if (CARDS_PER_ROW - count) > 1 else "",
			ROW_NAMES[_current_phase],
		]
		phase_button.text = "%d / %d selected" % [count, CARDS_PER_ROW]
	else:
		_update_phase_display()


func _on_confirm_pressed() -> void:
	if hand.get_selected_count() == CARDS_PER_ROW:
		_confirm_placement()


func _confirm_placement() -> void:
	if _current_phase == RowPhase.DONE:
		return

	var selected: Array = hand.get_selected_cards().duplicate()
	if selected.size() != CARDS_PER_ROW:
		return

	var row: int = int(_current_phase)

	# Place cards first (while still in hand, so global_position is correct for animation)
	spread.place_cards_in_row(row, selected)

	# Then remove from hand tracking (don't free — spread owns them now)
	hand.remove_cards(selected)

	# Lock the row
	spread.lock_row(row)

	# Emit row placed signal
	EventBus.row_placed.emit(row, selected)

	# Process Veil accumulation for placed cards
	var veil_entries: Array = []
	for card_node in selected:
		veil_entries.append({
			"card": card_node,
			"card_data": card_node.card_data,
			"is_reversed": card_node.is_reversed,
		})
	VeilManager.process_placed_cards(veil_entries)

	# Update target based on new Veil tier
	ScoreManager.set_target(VeilManager.get_adjusted_target(_base_target))
	_update_target_display()
	_update_veil_display()

	# Score this row
	if _current_phase == RowPhase.FUTURE:
		# Final row: full scoring with chains and combos across all 9 cards
		_do_full_scoring()
	else:
		# Partial scoring for this row
		_do_row_scoring(row)

	# Advance phase
	_advance_phase()


func _do_row_scoring(row: int) -> void:
	var row_cards: Array = spread.get_row_placed_cards(row)
	var all_cards: Array = spread.get_placed_cards()
	var row_score: int = ScoreManager.score_row(row_cards, all_cards)
	_row_scores[row] = row_score

	EventBus.row_scored.emit(row, row_score, ScoreManager.current_score)

	# Update score display
	score_label.text = "Score: %d" % ScoreManager.current_score

	# Show row score breakdown on cards
	_show_row_breakdown(row)


func _do_full_scoring() -> void:
	var all_cards: Array = spread.get_placed_cards()
	var total: int = ScoreManager.score_reading(all_cards)

	# Process end-of-reading Veil bonus (all-upright = -1)
	var veil_entries: Array = []
	for entry in all_cards:
		veil_entries.append({
			"card": entry.card,
			"card_data": entry.card.card_data,
			"is_reversed": entry.card.is_reversed,
		})
	VeilManager.process_end_of_reading(veil_entries)
	_update_veil_display()

	score_label.text = "Score: %d" % total

	# Show full breakdown
	_show_full_breakdown()

	# Build result text
	var target: int = ScoreManager.target_score
	var met: bool = ScoreManager.is_target_met()

	var result_parts: Array = []
	if met:
		result_parts.append("Score %d / %d -- SUCCESS!" % [total, target])
	else:
		result_parts.append("Score %d / %d -- Not enough..." % [total, target])

	var chains: Array = ScoreManager.get_detected_chains()
	if not chains.is_empty():
		var chain_names: Array = []
		for chain in chains:
			chain_names.append("%s(%d) x%.1f" % [
				chain.suit.capitalize(), chain.length, chain.base_multiplier])
			if chain.perfect_chain:
				chain_names[-1] += " PERFECT!"
		result_parts.append("Chains: %s" % ", ".join(chain_names))

	var combos: Array = ScoreManager.get_detected_combos()
	if not combos.is_empty():
		var combo_names: Array = []
		for combo in combos:
			combo_names.append(combo.name)
		result_parts.append("Combos: %s" % ", ".join(combo_names))

	# Show Veil tier info if active
	var tier: int = VeilManager.get_tier()
	if tier != VeilManager.VeilTier.CLEAR:
		var tier_names: Array[String] = ["Clear", "Glimpse", "Gaze", "Abyss", "VOID"]
		result_parts.append("Veil: %d (%s)" % [VeilManager.veil_value, tier_names[tier]])

	info_label.text = " | ".join(result_parts)


func _advance_phase() -> void:
	match _current_phase:
		RowPhase.PAST:
			_current_phase = RowPhase.PRESENT
			spread.set_active_row(1, true)
			_update_phase_display()
		RowPhase.PRESENT:
			_current_phase = RowPhase.FUTURE
			spread.set_active_row(2, true)
			_update_phase_display()
		RowPhase.FUTURE:
			_current_phase = RowPhase.DONE
			_reading_active = false
			_finish_reading()

	EventBus.row_phase_changed.emit(int(_current_phase),
		ROW_NAMES[_current_phase] if _current_phase != RowPhase.DONE else "Done")


func _finish_reading() -> void:
	phase_button.text = "Reading Complete"
	phase_button.disabled = true
	placed_count_label.text = "9 / 9 placed"

	# Return unused hand cards to draw pile, discard placed cards
	_return_cards_to_deck()

	# Notify parent that reading is done
	reading_finished.emit(ScoreManager.current_score, ScoreManager.target_score)


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
	spread.clear_all_cards()
	hand.clear_hand()
	_hand_card_data.clear()
	_current_querent = null
	_current_phase = RowPhase.PAST
	_reading_active = false
	visible = false


func _update_phase_display() -> void:
	if _current_phase == RowPhase.DONE:
		placed_count_label.text = "9 / 9 placed"
		phase_button.text = "Reading Complete"
		phase_button.disabled = true
		return

	var row_name: String = ROW_NAMES[_current_phase]
	var cards_remaining: int = hand.cards.size()
	placed_count_label.text = "%s Row | %d cards in hand" % [row_name, cards_remaining]
	info_label.text = "Select 3 cards for the %s row. Right-click to reverse." % row_name
	phase_button.text = "Select 3 cards"
	phase_button.disabled = true


func _show_row_breakdown(row: int) -> void:
	var row_cards: Array = spread.get_row_placed_cards(row)
	for entry_data in row_cards:
		var card: Node = entry_data.card
		# Find this card's score entry
		for score_entry in ScoreManager.card_scores:
			if score_entry.card == card:
				var value_lbl: Label = card.get_node_or_null("CardVisual/CardFront/ValueLabel")
				if value_lbl:
					value_lbl.text = "%d" % score_entry.total
				break


func _show_full_breakdown() -> void:
	var breakdown: Array = ScoreManager.get_score_breakdown()
	for entry in breakdown:
		var card: Node = entry.card
		var value_lbl: Label = card.get_node_or_null("CardVisual/CardFront/ValueLabel")
		if value_lbl:
			value_lbl.text = "%d" % entry.total


func _update_target_display() -> void:
	var tier: int = VeilManager.get_tier()
	if tier != VeilManager.VeilTier.CLEAR:
		target_label.text = "Target: %d (Veil +%d%%)" % [
			ScoreManager.target_score,
			int((VeilManager.get_target_multiplier() - 1.0) * 100),
		]
	else:
		target_label.text = "Target: %d" % ScoreManager.target_score


func _update_veil_display() -> void:
	if not veil_label:
		return
	var tier_names: Array[String] = ["Clear", "Glimpse", "Gaze", "Abyss", "VOID"]
	var tier: int = VeilManager.get_tier()
	veil_label.text = "Veil: %d / %d (%s)" % [VeilManager.veil_value, VeilManager.veil_cap, tier_names[tier]]

	# Color-code by tier
	match tier:
		VeilManager.VeilTier.CLEAR:
			veil_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
		VeilManager.VeilTier.GLIMPSE:
			veil_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.85, 1.0))
		VeilManager.VeilTier.GAZE:
			veil_label.add_theme_color_override("font_color", Color(0.6, 0.3, 0.8, 1.0))
		VeilManager.VeilTier.ABYSS:
			veil_label.add_theme_color_override("font_color", Color(0.85, 0.2, 0.2, 1.0))
		VeilManager.VeilTier.VOID:
			veil_label.add_theme_color_override("font_color", Color(1.0, 0.0, 0.0, 1.0))


func _on_card_hovered(card: Node) -> void:
	if not card.card_data or _current_phase == RowPhase.DONE:
		return
	var orientation: String = "REVERSED" if card.is_reversed else "Upright"
	var selected_text: String = " [SELECTED]" if card.is_selected else ""
	info_label.text = "%s | %s | Insight: %d | %s%s" % [
		card.card_data.card_name,
		card.card_data.suit.capitalize(),
		card.card_data.base_insight,
		orientation,
		selected_text,
	]


func _on_card_unhovered(_card: Node) -> void:
	if _current_phase == RowPhase.DONE:
		return
	_update_phase_display()


func _on_card_flipped(card: Node, is_reversed: bool) -> void:
	if not card.card_data:
		return
	var orientation: String = "REVERSED" if is_reversed else "Upright"
	info_label.text = "%s flipped to %s" % [card.card_data.card_name, orientation]
