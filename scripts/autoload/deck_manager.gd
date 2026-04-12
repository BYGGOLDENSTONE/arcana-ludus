extends Node
## Manages the player's deck, draw pile, discard pile, hand, and sideboard.

var player_deck: Array = []
var draw_pile: Array = []
var discard_pile: Array = []
var hand: Array = []
var sideboard: Array = []  # Cards removed from deck but still owned


func init_deck(cards: Array) -> void:
	player_deck = cards.duplicate()
	draw_pile = cards.duplicate()
	discard_pile.clear()
	hand.clear()
	sideboard.clear()
	shuffle()


func shuffle() -> void:
	draw_pile.shuffle()
	EventBus.deck_shuffled.emit()


func draw(count: int) -> Array:
	var drawn: Array = []
	for i in range(count):
		if draw_pile.is_empty():
			_reshuffle_discard()
		if draw_pile.is_empty():
			break
		var card = draw_pile.pop_back()
		hand.append(card)
		drawn.append(card)
		EventBus.card_drawn.emit(card)
	EventBus.hand_updated.emit(hand.size())
	return drawn


func discard(card: Resource) -> void:
	hand.erase(card)
	discard_pile.append(card)
	EventBus.card_discarded.emit(card)
	EventBus.hand_updated.emit(hand.size())


func return_to_deck(cards: Array) -> void:
	for card in cards:
		hand.erase(card)
		draw_pile.append(card)
	EventBus.hand_updated.emit(hand.size())


func discard_placed(cards: Array) -> void:
	for card in cards:
		discard_pile.append(card)


func add_to_deck(card: Resource) -> void:
	player_deck.append(card)
	draw_pile.append(card)


func remove_from_deck(card: Resource) -> void:
	## Move card to sideboard — still owned, just not in active deck.
	player_deck.erase(card)
	draw_pile.erase(card)
	discard_pile.erase(card)
	hand.erase(card)
	sideboard.append(card)


func return_from_sideboard(card: Resource) -> void:
	## Move card back from sideboard to active deck.
	sideboard.erase(card)
	player_deck.append(card)
	draw_pile.append(card)


func get_remaining_count() -> int:
	return draw_pile.size() + discard_pile.size()


func can_draw_hand(hand_size: int) -> bool:
	return get_remaining_count() >= hand_size


func reshuffle_all() -> void:
	draw_pile = player_deck.duplicate()
	discard_pile.clear()
	hand.clear()
	shuffle()


func _reshuffle_discard() -> void:
	draw_pile = discard_pile.duplicate()
	discard_pile.clear()
	shuffle()
