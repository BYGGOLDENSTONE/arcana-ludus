extends Node
## Global signal bus for cross-component communication.
## All cross-system signals are declared here. No logic.

# -- Card signals --
signal card_clicked(card: Node)
signal card_drag_started(card: Node)
signal card_drag_ended(card: Node, global_pos: Vector2)
signal card_flipped(card: Node, is_reversed: bool)
signal card_hovered(card: Node)
signal card_unhovered(card: Node)

# -- Hand signals --
signal hand_updated(card_count: int)

# -- Deck signals --
signal deck_shuffled()
signal card_drawn(card_data: Resource)
signal card_discarded(card_data: Resource)

# -- Scoring signals (Phase 2+) --
signal scoring_started()
signal card_scored(card: Node, insight: int, resonance: float)
signal scoring_completed(total_score: int)

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
