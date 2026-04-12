extends Node
## Orchestrates a single night of gameplay: querent flow, reading triggers,
## result evaluation, and night-end transitions.
## This node owns NO UI. It manages state and emits signals via EventBus.

const QuerentGen = preload("res://scripts/utils/querent_generator.gd")
const HAND_SIZE := 12
const REJECT_REPUTATION_PENALTY := -0.1
const MIN_QUERENTS_BASE := 3
const SCORE_BONUS_GOLD_RATE := 0.1

var current_querent: Resource = null
var querents_served: int = 0
var querents_total: int = 0
var night_active: bool = false
var total_gold_earned: int = 0

var _waiting_for_querent_decision: bool = false
var _waiting_for_reading: bool = false
var _waiting_for_result_ack: bool = false


func start_night() -> void:
	night_active = true
	querents_served = 0
	querents_total = 0
	total_gold_earned = 0
	current_querent = null

	DeckManager.reshuffle_all()
	EventBus.night_started.emit(GameManager.current_night)
	_generate_next_querent()


func can_end_night() -> bool:
	## Player can choose to end after serving minimum querents.
	return querents_total >= MIN_QUERENTS_BASE + GameManager.current_night


func _generate_next_querent() -> void:
	if not night_active:
		return

	# Auto-end only if deck can't support another reading
	if not DeckManager.can_draw_hand(HAND_SIZE):
		_end_night()
		return

	current_querent = QuerentGen.generate(GameManager.current_night, querents_served)
	_waiting_for_querent_decision = true
	EventBus.querent_arrived.emit(current_querent)


func accept_querent() -> void:
	if not _waiting_for_querent_decision or current_querent == null:
		return
	_waiting_for_querent_decision = false

	querents_total += 1
	GameManager.current_state = GameManager.GameState.READING
	EventBus.querent_accepted.emit(current_querent)

	_waiting_for_reading = true
	EventBus.reading_started.emit()


func reject_querent() -> void:
	if not _waiting_for_querent_decision or current_querent == null:
		return
	_waiting_for_querent_decision = false

	querents_total += 1
	GameManager.modify_reputation(REJECT_REPUTATION_PENALTY)
	EventBus.querent_rejected.emit(current_querent)

	GameManager.current_querent_index += 1
	current_querent = null

	await get_tree().create_timer(0.5).timeout
	_generate_next_querent()


func end_night_by_choice() -> void:
	## Player chose to end the night early.
	if not _waiting_for_querent_decision:
		return
	_waiting_for_querent_decision = false
	current_querent = null
	_end_night()


func on_reading_completed(score: int) -> void:
	if not _waiting_for_reading:
		return
	_waiting_for_reading = false

	var target: int = current_querent.target_score
	var success: bool = score >= target

	if success:
		var base_reward: int = current_querent.gold_reward
		var excess: int = maxi(0, score - target)
		var bonus: int = int(excess * SCORE_BONUS_GOLD_RATE)
		var total_reward: int = base_reward + bonus
		GameManager.earn_gold(total_reward)
		total_gold_earned += total_reward
		current_querent.set_meta("bonus_gold", bonus)
		current_querent.set_meta("total_reward", total_reward)
	else:
		GameManager.lose_life()

	querents_served += 1
	GameManager.current_querent_index += 1
	GameManager.current_state = GameManager.GameState.IN_RUN

	EventBus.querent_result.emit(current_querent, score, success)
	_waiting_for_result_ack = true


func acknowledge_result() -> void:
	if not _waiting_for_result_ack:
		return
	_waiting_for_result_ack = false

	if GameManager.lives <= 0:
		return

	_check_continue_or_end()


func _check_continue_or_end() -> void:
	if DeckManager.can_draw_hand(HAND_SIZE):
		current_querent = null
		_generate_next_querent()
	else:
		_end_night()


func _end_night() -> void:
	night_active = false
	GameManager.current_state = GameManager.GameState.SHOP
	EventBus.night_ended.emit(GameManager.current_night)
