extends Node2D
## Main game scene: orchestrates NightManager, ReadingScene, and all UI panels.
## Implements Phase 3 — Game Loop (GDD: Night System, Querent Flow).
## This is the entry point scene for a run.

const READING_SCENE := preload("res://scenes/game/reading_scene.tscn")
const SHOP_SCENE := preload("res://scenes/shop/shop_scene.tscn")

# -- Node references --
@onready var night_manager: Node = $NightManager
@onready var reading_area: Node2D = $ReadingArea

# HUD
@onready var night_label: Label = $UI/HUD/HBoxContainer/NightLabel
@onready var lives_label: Label = $UI/HUD/HBoxContainer/LivesLabel
@onready var gold_label: Label = $UI/HUD/HBoxContainer/GoldLabel
@onready var deck_label: Label = $UI/HUD/HBoxContainer/DeckLabel
@onready var reputation_label: Label = $UI/HUD/HBoxContainer/ReputationLabel

# Querent panel
@onready var querent_panel: PanelContainer = $UI/QuerentPanel
@onready var querent_name_label: Label = $UI/QuerentPanel/MarginContainer/VBoxContainer/QuerentName
@onready var question_text_label: Label = $UI/QuerentPanel/MarginContainer/VBoxContainer/QuestionText
@onready var target_score_label: Label = $UI/QuerentPanel/MarginContainer/VBoxContainer/TargetScore
@onready var personality_label: Label = $UI/QuerentPanel/MarginContainer/VBoxContainer/PersonalityLabel
@onready var accept_button: Button = $UI/QuerentPanel/MarginContainer/VBoxContainer/ButtonRow/AcceptButton
@onready var reject_button: Button = $UI/QuerentPanel/MarginContainer/VBoxContainer/ButtonRow/RejectButton

# Result panel
@onready var result_panel: PanelContainer = $UI/ResultPanel
@onready var result_title: Label = $UI/ResultPanel/MarginContainer/VBoxContainer/ResultTitle
@onready var score_text: Label = $UI/ResultPanel/MarginContainer/VBoxContainer/ScoreText
@onready var result_message: Label = $UI/ResultPanel/MarginContainer/VBoxContainer/ResultMessage
@onready var continue_button: Button = $UI/ResultPanel/MarginContainer/VBoxContainer/ContinueButton

# Night end panel
@onready var night_end_panel: PanelContainer = $UI/NightEndPanel
@onready var night_end_title: Label = $UI/NightEndPanel/MarginContainer/VBoxContainer/NightEndTitle
@onready var night_summary: Label = $UI/NightEndPanel/MarginContainer/VBoxContainer/NightSummary
@onready var next_night_button: Button = $UI/NightEndPanel/MarginContainer/VBoxContainer/NextNightButton

# Game over panel
@onready var game_over_panel: PanelContainer = $UI/GameOverPanel
@onready var game_over_title: Label = $UI/GameOverPanel/MarginContainer/VBoxContainer/GameOverTitle
@onready var game_over_message: Label = $UI/GameOverPanel/MarginContainer/VBoxContainer/GameOverMessage
@onready var restart_button: Button = $UI/GameOverPanel/MarginContainer/VBoxContainer/RestartButton

var _reading_instance: Node2D = null
var _shop_instance: Node2D = null
var _last_score: int = 0
var _last_target: int = 0
var _last_success: bool = false


func _ready() -> void:
	_hide_all_panels()

	# Connect buttons
	accept_button.pressed.connect(_on_accept_pressed)
	reject_button.pressed.connect(_on_reject_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	next_night_button.pressed.connect(_on_next_night_pressed)
	restart_button.pressed.connect(_on_restart_pressed)

	# Connect EventBus signals for UI updates
	EventBus.querent_arrived.connect(_on_querent_arrived)
	EventBus.querent_accepted.connect(_on_querent_accepted)
	EventBus.querent_rejected.connect(_on_querent_rejected)
	EventBus.querent_result.connect(_on_querent_result)
	EventBus.night_started.connect(_on_night_started)
	EventBus.night_ended.connect(_on_night_ended)
	EventBus.gold_changed.connect(_on_gold_changed)
	EventBus.run_ended.connect(_on_run_ended)
	EventBus.deck_shuffled.connect(_update_deck_display)
	EventBus.hand_updated.connect(_on_hand_updated)
	EventBus.card_drawn.connect(_on_card_drawn)

	# Initialize run
	_start_run()


func _start_run() -> void:
	# Initialize deck with starting cards (22 Major Arcana)
	var starting_cards: Array = DataLoader.get_starting_deck()
	DeckManager.init_deck(starting_cards)

	GameManager.start_new_run()
	_update_hud()

	# Start first night
	night_manager.start_night()


# -- EventBus handlers --

func _on_night_started(night_number: int) -> void:
	night_label.text = "Night %d" % night_number
	_update_hud()


func _on_querent_arrived(querent: Resource) -> void:
	_hide_all_panels()
	_show_querent_panel(querent)

	# After min querents: replace Reject with End Night
	if night_manager.can_end_night():
		reject_button.text = "End the Night"
	else:
		reject_button.text = "Reject"


func _on_querent_accepted(_querent: Resource) -> void:
	querent_panel.visible = false
	_show_reading()


func _on_querent_rejected(_querent: Resource) -> void:
	querent_panel.visible = false
	_update_hud()


func _on_querent_result(querent: Resource, score: int, success: bool) -> void:
	_last_score = score
	_last_target = querent.target_score
	_last_success = success

	# Hide reading, show result
	if _reading_instance:
		_reading_instance.cleanup()
		_reading_instance.visible = false

	var total_reward: int = querent.get_meta("total_reward", querent.gold_reward) if success else 0
	var bonus: int = querent.get_meta("bonus_gold", 0) if success else 0
	_show_result_panel(score, querent.target_score, success, total_reward, bonus)
	_update_hud()


func _on_night_ended(night_number: int) -> void:
	_hide_all_panels()
	_show_night_end_panel(night_number)


func _on_gold_changed(_new_amount: int) -> void:
	_update_hud()


func _on_run_ended(_victory: bool) -> void:
	# Don't show game over immediately — let the result panel show first.
	# Game over will be shown after the player acknowledges the result in _on_continue_pressed.
	pass


func _on_hand_updated(_card_count: int) -> void:
	_update_deck_display()


func _on_card_drawn(_card_data: Resource) -> void:
	_update_deck_display()


# -- Button handlers --

func _on_accept_pressed() -> void:
	night_manager.accept_querent()


func _on_reject_pressed() -> void:
	if night_manager.can_end_night():
		night_manager.end_night_by_choice()
	else:
		night_manager.reject_querent()


func _on_continue_pressed() -> void:
	result_panel.visible = false
	night_manager.acknowledge_result()
	_update_hud()

	# If the player died, show game over after they acknowledged the result
	if GameManager.lives <= 0:
		_show_game_over_panel(false)


func _on_next_night_pressed() -> void:
	night_end_panel.visible = false
	_show_shop()


func _on_restart_pressed() -> void:
	# Clean up and restart
	if _reading_instance:
		_reading_instance.cleanup()
		_reading_instance.queue_free()
		_reading_instance = null
	if _shop_instance:
		_shop_instance.queue_free()
		_shop_instance = null
	_hide_all_panels()
	_start_run()


# -- Shop management --

func _show_shop() -> void:
	# Hide game UI so shop is a clean screen
	if _reading_instance:
		_reading_instance.visible = false
	$UI.visible = false

	if _shop_instance:
		_shop_instance.queue_free()
		_shop_instance = null
	_shop_instance = SHOP_SCENE.instantiate()
	add_child(_shop_instance)
	_shop_instance.shop_closed.connect(_on_shop_closed)
	_shop_instance.open_shop()


func _on_shop_closed() -> void:
	if _shop_instance:
		_shop_instance.queue_free()
		_shop_instance = null

	# Restore game UI
	$UI.visible = true
	if _reading_instance:
		_reading_instance.cleanup()

	GameManager.advance_night()
	night_manager.start_night()
	_update_hud()


# -- Reading management --

func _show_reading() -> void:
	if not _reading_instance:
		_reading_instance = READING_SCENE.instantiate()
		reading_area.add_child(_reading_instance)
		_reading_instance.reading_finished.connect(_on_reading_finished)

	_reading_instance.start_reading(night_manager.current_querent)
	_update_deck_display()


func _on_reading_finished(score: int, _target: int) -> void:
	night_manager.on_reading_completed(score)


# -- Panel display --

func _show_querent_panel(querent: Resource) -> void:
	querent_name_label.text = querent.querent_name
	question_text_label.text = "\"%s\"" % querent.question_text
	target_score_label.text = "Target Score: %d" % querent.target_score
	personality_label.text = "%s | %s" % [
		querent.question_theme.capitalize(),
		querent.personality_type.capitalize(),
	]
	querent_panel.visible = true


func _show_result_panel(score: int, target: int, success: bool, total_reward: int, bonus: int) -> void:
	if success:
		result_title.text = "Reading Successful!"
		result_title.add_theme_color_override("font_color", Color(0.90, 0.75, 0.30, 1.0))
		score_text.text = "Score: %d / %d" % [score, target]
		if bonus > 0:
			result_message.text = "+%d Gold earned! (bonus +%d)" % [total_reward, bonus]
		else:
			result_message.text = "+%d Gold earned!" % total_reward
		result_message.add_theme_color_override("font_color", Color(0.90, 0.75, 0.30, 1.0))
	else:
		result_title.text = "Reading Failed..."
		result_title.add_theme_color_override("font_color", Color(0.80, 0.30, 0.25, 1.0))
		score_text.text = "Score: %d / %d" % [score, target]
		result_message.text = "Lost a life..."
		result_message.add_theme_color_override("font_color", Color(0.80, 0.30, 0.25, 1.0))

	result_panel.visible = true


func _show_night_end_panel(night_number: int) -> void:
	night_end_title.text = "Night %d Complete" % night_number
	night_summary.text = "Served %d client%s. Earned %d gold." % [
		night_manager.querents_served,
		"s" if night_manager.querents_served != 1 else "",
		night_manager.total_gold_earned,
	]
	night_end_panel.visible = true


func _show_game_over_panel(victory: bool) -> void:
	if victory:
		game_over_title.text = "Victory!"
		game_over_message.text = "You completed all nights."
	else:
		game_over_title.text = "Game Over"
		game_over_message.text = "You lost all your lives.\nNight reached: %d\nGold earned: %d" % [
			GameManager.current_night,
			GameManager.gold,
		]
	game_over_panel.visible = true


func _hide_all_panels() -> void:
	querent_panel.visible = false
	result_panel.visible = false
	night_end_panel.visible = false
	game_over_panel.visible = false


# -- HUD --

func _update_hud() -> void:
	night_label.text = "Night %d" % GameManager.current_night
	lives_label.text = _lives_string(GameManager.lives, GameManager.max_lives)
	gold_label.text = "Gold: %d" % GameManager.gold
	reputation_label.text = "Rep: x%.1f" % GameManager.reputation
	_update_deck_display()


func _update_deck_display() -> void:
	var remaining := DeckManager.get_remaining_count()
	deck_label.text = "Deck: %d" % remaining


func _lives_string(current: int, max_val: int) -> String:
	var lit := ""
	for i in range(max_val):
		if i < current:
			lit += "O "
		else:
			lit += "X "
	return lit.strip_edges()
