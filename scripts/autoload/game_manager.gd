extends Node
## Manages run state, current act/querent, and player lives.

enum GameState { MENU, IN_RUN, READING, SCORING, SHOP, GAME_OVER }

var current_state: GameState = GameState.MENU
var current_act: int = 1
var current_querent_index: int = 0
var lives: int = 3
var max_lives: int = 3
var gold: int = 0


func start_new_run() -> void:
	current_state = GameState.IN_RUN
	current_act = 1
	current_querent_index = 0
	lives = max_lives
	gold = 0
	EventBus.run_started.emit()


func end_run(victory: bool) -> void:
	current_state = GameState.GAME_OVER
	EventBus.run_ended.emit(victory)


func lose_life() -> void:
	lives -= 1
	if lives <= 0:
		end_run(false)
