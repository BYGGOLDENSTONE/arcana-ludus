extends Node
## Manages active talismans during a run. Max 5 talismans.
## Provides hook points that the scoring/reading systems call into.

const MAX_TALISMANS := 5

var active_talismans: Array = []  # Array of TalismanData resources
var _effects: Dictionary = {}     # effect_id -> callable dict for hooks


func reset() -> void:
	active_talismans.clear()
	_effects.clear()


func add_talisman(talisman: Resource) -> bool:
	if active_talismans.size() >= MAX_TALISMANS:
		return false
	active_talismans.append(talisman)
	_register_effect(talisman)
	EventBus.talisman_added.emit(talisman)
	return true


func remove_talisman(talisman: Resource) -> void:
	active_talismans.erase(talisman)
	_unregister_effect(talisman)
	EventBus.talisman_removed.emit(talisman)


func has_talisman(effect_id: String) -> bool:
	for t in active_talismans:
		if t.effect_id == effect_id:
			return true
	return false


func get_talisman_count() -> int:
	return active_talismans.size()


## --- Hook entry points called by game systems ---

func on_before_reading() -> void:
	## Called before a reading starts.
	for effect_id in _effects:
		var hooks: Dictionary = _effects[effect_id]
		if hooks.has("before_reading"):
			hooks["before_reading"].call()


func on_card_placed(card_data: Resource, is_reversed: bool, position_index: int) -> void:
	## Called when a card is placed into a spread slot.
	for effect_id in _effects:
		var hooks: Dictionary = _effects[effect_id]
		if hooks.has("on_card_place"):
			hooks["on_card_place"].call(card_data, is_reversed, position_index)


func on_score_card(entry: Dictionary) -> void:
	## Called during scoring for each card. entry has insight, resonance, etc.
	for effect_id in _effects:
		var hooks: Dictionary = _effects[effect_id]
		if hooks.has("on_score"):
			hooks["on_score"].call(entry)


func on_chain(chain: Dictionary) -> void:
	## Called when a chain is detected.
	for effect_id in _effects:
		var hooks: Dictionary = _effects[effect_id]
		if hooks.has("on_chain"):
			hooks["on_chain"].call(chain)


func on_after_reading(all_entries: Array) -> void:
	## Called after a reading is fully scored.
	for effect_id in _effects:
		var hooks: Dictionary = _effects[effect_id]
		if hooks.has("after_reading"):
			hooks["after_reading"].call(all_entries)


## --- Effect Registration ---

func _register_effect(talisman: Resource) -> void:
	var hooks: Dictionary = TalismanEffects.get_hooks(talisman.effect_id)
	if not hooks.is_empty():
		_effects[talisman.effect_id] = hooks


func _unregister_effect(talisman: Resource) -> void:
	_effects.erase(talisman.effect_id)
