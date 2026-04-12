extends Node
## Tracks the Veil value (0–11) and tier transitions.

enum VeilTier { CLEAR, GLIMPSE, GAZE, ABYSS, VOID }

const TIER_THRESHOLDS := {
	VeilTier.CLEAR: 0,
	VeilTier.GLIMPSE: 3,
	VeilTier.GAZE: 6,
	VeilTier.ABYSS: 9,
	VeilTier.VOID: 11,
}

var veil_value: int = 0
var current_tier: VeilTier = VeilTier.CLEAR


func reset_veil() -> void:
	var old := veil_value
	veil_value = 0
	current_tier = VeilTier.CLEAR
	EventBus.veil_changed.emit(old, veil_value)


func add_veil(amount: int) -> void:
	var old := veil_value
	veil_value = clampi(veil_value + amount, 0, 11)
	_update_tier()
	EventBus.veil_changed.emit(old, veil_value)


func reduce_veil(amount: int) -> void:
	add_veil(-amount)


func get_tier() -> VeilTier:
	return current_tier


func _update_tier() -> void:
	var old_tier := current_tier
	if veil_value >= 11:
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
