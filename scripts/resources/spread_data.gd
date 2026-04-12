extends Resource
## Data container for a spread layout — defines positions, affinities, and scoring rules.

@export var spread_id: String = ""
@export var spread_name: String = ""
@export var positions: Array = []  # Array of SpreadPositionData
@export var row_count: int = 3
@export var col_count: int = 3


func get_position(index: int) -> Resource:
	if index >= 0 and index < positions.size():
		return positions[index]
	return null


func get_row(row: int) -> Array:
	var result: Array = []
	for i in range(col_count):
		var idx: int = row * col_count + i
		if idx < positions.size():
			result.append(positions[idx])
	return result


func get_col(col: int) -> Array:
	var result: Array = []
	for i in range(row_count):
		var idx: int = i * col_count + col
		if idx < positions.size():
			result.append(positions[idx])
	return result


static func create_standard_spread() -> Resource:
	var script: GDScript = load("res://scripts/resources/spread_data.gd")
	var pos_script: GDScript = load("res://scripts/resources/spread_position_data.gd")
	var spread: Resource = script.new()
	spread.spread_id = "standard_3x3"
	spread.spread_name = "Past, Present, Future"
	spread.row_count = 3
	spread.col_count = 3

	# Row 0: Past
	var p0: Resource = pos_script.create("past_root", "Past — Root", 0, 0,
		["pentacles"], [7, 8, 9, 10], ["foundation"])
	var p1: Resource = pos_script.create("past_event", "Past — Event", 0, 1,
		["swords"], [5, 6, 7, 8], [])
	var p2: Resource = pos_script.create("past_lesson", "Past — Lesson", 0, 2,
		["major"], [], ["major_arcana"])

	# Row 1: Present
	var p3: Resource = pos_script.create("present_self", "Present — Self", 1, 0,
		["wands"], [4, 5, 6, 7], ["court"])
	var p4: Resource = pos_script.create("present_center", "Present — Center", 1, 1,
		[], [], ["pairs"])
	var p5: Resource = pos_script.create("present_other", "Present — Other", 1, 2,
		["cups"], [4, 5, 6, 7], [])

	# Row 2: Future
	var p6: Resource = pos_script.create("future_hope", "Future — Hope", 2, 0,
		["cups"], [1, 2, 3], ["aces"])
	var p7: Resource = pos_script.create("future_path", "Future — Path", 2, 1,
		["major"], [], ["major_arcana"])
	var p8: Resource = pos_script.create("future_destiny", "Future — Destiny", 2, 2,
		["wands"], [8, 9, 10], ["chain_closers"])

	spread.positions = [p0, p1, p2, p3, p4, p5, p6, p7, p8]
	return spread
