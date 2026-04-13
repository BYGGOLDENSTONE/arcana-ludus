extends Node2D
## A single slot in the spread grid where a card can be placed.
## Phase 4.5: cards placed programmatically (no drag-drop).

signal slot_hovered(slot: Node2D)
signal slot_unhovered(slot: Node2D)

const SLOT_SIZE := Vector2(120, 195)

var position_data: Resource  # SpreadPositionData
var is_occupied: bool = false
var placed_card: Node2D = null
var is_active: bool = true

@onready var background: Panel = $Background
@onready var glow_panel: Panel = $GlowPanel
@onready var name_label: Label = $NameLabel
@onready var affinity_label: Label = $AffinityLabel
@onready var drop_area: Area2D = $DropArea


func _ready() -> void:
	drop_area.mouse_entered.connect(_on_mouse_entered)
	drop_area.mouse_exited.connect(_on_mouse_exited)
	glow_panel.visible = false


func setup(data: Resource) -> void:
	position_data = data
	if name_label:
		name_label.text = data.display_name
	if affinity_label:
		var hints: PackedStringArray = []
		for s in data.suit_affinities:
			hints.append(_suit_icon(s))
		if not data.number_affinities.is_empty():
			var nums := []
			for n in data.number_affinities:
				nums.append(str(n))
			hints.append(",".join(nums))
		affinity_label.text = " ".join(hints) if not hints.is_empty() else ""


func show_match_preview(color: Color) -> void:
	if glow_panel:
		glow_panel.visible = color.a > 0.05
		var style := glow_panel.get_theme_stylebox("panel") as StyleBoxFlat
		if style:
			var new_style := style.duplicate() as StyleBoxFlat
			new_style.bg_color = Color(color.r, color.g, color.b, color.a * 0.3)
			new_style.border_color = color
			glow_panel.add_theme_stylebox_override("panel", new_style)


func clear_match_preview() -> void:
	if glow_panel:
		glow_panel.visible = false


func place_card(card: Node2D) -> void:
	placed_card = card
	is_occupied = true
	if position_data:
		position_data.placed_card = card
		position_data.placed_reversed = card.is_reversed
	clear_match_preview()


func remove_placed_card() -> Node2D:
	var card := placed_card
	placed_card = null
	is_occupied = false
	if position_data:
		position_data.clear()
	return card


func set_active(active: bool) -> void:
	is_active = active
	if background:
		modulate.a = 1.0 if active else 0.4


func set_locked() -> void:
	is_active = false
	if background:
		modulate.a = 0.8


func set_hidden() -> void:
	is_active = false
	modulate.a = 0.0


func get_snap_position() -> Vector2:
	return global_position


func _on_mouse_entered() -> void:
	slot_hovered.emit(self)


func _on_mouse_exited() -> void:
	slot_unhovered.emit(self)


func _suit_icon(suit: String) -> String:
	match suit:
		"wands": return "W"
		"cups": return "C"
		"swords": return "S"
		"pentacles": return "P"
		"major": return "*"
		_: return suit
