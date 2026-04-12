extends Resource
## Data for a single position within a spread.

@export var position_id: String = ""
@export var display_name: String = ""
@export var row: int = 0
@export var col: int = 0
@export var suit_affinities: PackedStringArray = []  # suits that score bonus here
@export var number_affinities: PackedInt32Array = []  # card numbers that score bonus here
@export var special_affinities: PackedStringArray = []  # special tags: "major_arcana", "aces", "court", "pairs", "foundation", "chain_closers"

## Runtime state — which card is placed here
var placed_card: Node = null
var placed_reversed: bool = false


func is_occupied() -> bool:
	return placed_card != null


func clear() -> void:
	placed_card = null
	placed_reversed = false


static func create(id: String, name: String, r: int, c: int,
		suits: Array, numbers: Array, specials: Array) -> Resource:
	var script: GDScript = load("res://scripts/resources/spread_position_data.gd")
	var pos: Resource = script.new()
	pos.position_id = id
	pos.display_name = name
	pos.row = r
	pos.col = c
	pos.suit_affinities = PackedStringArray(suits)
	pos.number_affinities = PackedInt32Array(numbers)
	pos.special_affinities = PackedStringArray(specials)
	return pos
