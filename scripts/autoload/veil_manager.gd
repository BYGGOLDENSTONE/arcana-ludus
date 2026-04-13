extends Node
## Tracks the Veil value (0–11), tier transitions, accumulation from cards,
## reduction from light cards, and The Void death condition.

enum VeilTier { CLEAR, GLIMPSE, GAZE, ABYSS, VOID }

const TIER_THRESHOLDS := {
	VeilTier.CLEAR: 0,
	VeilTier.GLIMPSE: 3,
	VeilTier.GAZE: 6,
	VeilTier.ABYSS: 9,
	VeilTier.VOID: 11,
}

## Target score multipliers per tier
const TIER_TARGET_MULTIPLIERS := {
	VeilTier.CLEAR: 1.0,
	VeilTier.GLIMPSE: 1.10,
	VeilTier.GAZE: 1.25,
	VeilTier.ABYSS: 1.50,
	VeilTier.VOID: 1.50,
}

## Dark Major Arcana card IDs (upright = +1 Veil)
const DARK_ARCANA_IDS := ["m13", "m15", "m16", "m18"]  # Death, Devil, Tower, Moon

## Light Major Arcana: card_id -> veil reduction when played upright
const LIGHT_ARCANA_REDUCTION := {
	"m17": 3,   # The Star: -3
	"m19": 2,   # The Sun: -2
	"m14": 2,   # Temperance: -2
}
## Strength (m08) upright: resets Veil to 0
const STRENGTH_ID := "m08"

var veil_value: int = 0
var current_tier: VeilTier = VeilTier.CLEAR
var veil_cap: int = 11  # Can be modified by talismans (Void Crystal)


func reset_veil() -> void:
	var old := veil_value
	veil_value = 0
	current_tier = VeilTier.CLEAR
	EventBus.veil_changed.emit(old, veil_value)


func add_veil(amount: int) -> void:
	if amount == 0:
		return
	var old := veil_value
	veil_value = clampi(veil_value + amount, 0, veil_cap)
	_update_tier()
	EventBus.veil_changed.emit(old, veil_value)
	if veil_value >= veil_cap:
		EventBus.veil_void_triggered.emit()


func reduce_veil(amount: int) -> void:
	add_veil(-amount)


func get_tier() -> VeilTier:
	return current_tier


func get_target_multiplier() -> float:
	return TIER_TARGET_MULTIPLIERS.get(current_tier, 1.0)


func get_adjusted_target(base_target: int) -> int:
	return int(base_target * get_target_multiplier())


## Process Veil changes from a set of placed cards after a row is confirmed.
## cards: Array of { card: Node, card_data: Resource, is_reversed: bool }
func process_placed_cards(cards: Array) -> int:
	var total_veil := 0
	for entry in cards:
		var card_data: Resource = entry.card_data
		var is_reversed: bool = entry.is_reversed
		var card_id: String = card_data.card_id
		var veil_change := 0

		if is_reversed:
			# Reversed cards add Veil
			if card_data.card_type == "major_arcana":
				veil_change = 2
			else:
				veil_change = 1
		else:
			# Upright: check dark arcana (+1) or light arcana (reduction)
			if card_id in DARK_ARCANA_IDS:
				veil_change = 1
			elif card_id == STRENGTH_ID:
				# Strength upright: reset to 0
				var old := veil_value
				veil_value = 0
				_update_tier()
				EventBus.veil_changed.emit(old, veil_value)
				EventBus.veil_card_processed.emit(card_data.card_name, -old)
				continue
			elif LIGHT_ARCANA_REDUCTION.has(card_id):
				veil_change = -LIGHT_ARCANA_REDUCTION[card_id]

		# Check for 6-numbered cards (upright): -1 Veil
		if not is_reversed and card_data.card_number == 6:
			veil_change -= 1

		if veil_change != 0:
			add_veil(veil_change)
			total_veil += veil_change
			EventBus.veil_card_processed.emit(card_data.card_name, veil_change)

	return total_veil


## Called at end of reading: if all cards were upright, reduce Veil by 1.
func process_end_of_reading(all_placed_cards: Array) -> void:
	var any_reversed := false
	for entry in all_placed_cards:
		if entry.is_reversed:
			any_reversed = true
			break
	if not any_reversed:
		add_veil(-1)


## Cleanse ritual: skip querent, reset Veil to 0.
func perform_cleanse() -> void:
	reset_veil()
	EventBus.cleanse_ritual_performed.emit()


func is_void() -> bool:
	return veil_value >= veil_cap


func _update_tier() -> void:
	var old_tier := current_tier
	if veil_value >= veil_cap:
		current_tier = VeilTier.VOID
	elif veil_value >= 9:
		current_tier = VeilTier.ABYSS
	elif veil_value >= 6:
		current_tier = VeilTier.GAZE
	elif veil_value >= 3:
		current_tier = VeilTier.GLIMPSE
	else:
		current_tier = VeilTier.CLEAR

	if current_tier != old_tier:
		EventBus.veil_tier_changed.emit(current_tier)
