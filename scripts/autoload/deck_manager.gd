extends Node
## Manages the player's deck, draw pile, discard pile, and hand.

var player_deck: Array = []
var draw_pile: Array = []
var discard_pile: Array = []
var hand: Array = []


func init_deck(cards: Array) -> void:
	player_deck = cards.duplicate()
	draw_pile = cards.duplicate()
	discard_pile.clear()
	hand.clear()
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


func _reshuffle_discard() -> void:
	draw_pile = discard_pile.duplicate()
	discard_pile.clear()
	shuffle()
