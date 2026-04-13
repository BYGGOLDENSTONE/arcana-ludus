extends Node
## Global signal bus for cross-component communication.
## All cross-system signals are declared here. No logic.

# -- Card signals --
signal card_clicked(card: Node)
signal card_flipped(card: Node, is_reversed: bool)
signal card_hovered(card: Node)
signal card_unhovered(card: Node)

# -- Hand signals --
signal hand_updated(card_count: int)
signal hand_selection_changed(selected_count: int)

# -- Deck signals --
signal deck_shuffled()
signal card_drawn(card_data: Resource)
signal card_discarded(card_data: Resource)

# -- Spread signals (Phase 2) --
signal card_placed_on_spread(card: Node, slot: Node)
signal all_spread_slots_filled()
signal spread_cleared()

# -- Scoring signals (Phase 2+) --
signal scoring_started()
signal card_scored(card: Node, insight: int, resonance: float)
signal scoring_completed(total_score: int)

# -- Chain & Combo signals (Phase 4) --
signal chain_detected(chain_data: Dictionary)
signal combo_detected(combo_data: Dictionary)

# -- Row phase signals (Phase 4.5) --
signal row_phase_changed(phase: int, row_name: String)
signal row_placed(row: int, cards: Array)
signal row_scored(row: int, row_score: int, total_score: int)

# -- Veil signals (Phase 5+) --
signal veil_changed(old_value: int, new_value: int)
signal veil_tier_changed(new_tier: int)

# -- Game flow signals (Phase 3+) --
signal run_started()
signal run_ended(victory: bool)
signal querent_arrived(querent_data: Resource)
signal reading_started()
signal reading_completed(score: int, target: int)
signal shop_entered()
signal shop_exited()
signal night_started(night_number: int)
signal night_ended(night_number: int)
signal querent_accepted(querent_data: Resource)
signal querent_rejected(querent_data: Resource)
signal querent_result(querent_data: Resource, score: int, success: bool)
signal gold_changed(new_amount: int)
