extends Node2D
## Visual and interactive representation of a single tarot card.

signal clicked(card: Node2D)
signal selected(card: Node2D)
signal deselected(card: Node2D)
signal drag_started(card: Node2D)
signal drag_ended(card: Node2D)
signal hovered(card: Node2D)
signal unhovered(card: Node2D)

## Card size: 350x600 original
## At NORMAL_SCALE 0.50 → 175x300 rendered pixels
## At SELECTED_SCALE 0.75 → 262x450 rendered pixels
const NORMAL_SCALE := Vector2(0.50, 0.50)
const SELECTED_SCALE := Vector2(0.75, 0.75)
const DRAG_OPACITY := 0.85
const FLIP_DURATION := 0.4
const DRAG_THRESHOLD := 8.0

const CardDataScript = preload("res://scripts/resources/card_data.gd")
var card_data: Resource
var is_reversed: bool = false
var is_face_up: bool = true
var is_in_hand: bool = false
var is_dragging: bool = false
var is_hovered: bool = false
var is_selected: bool = false

var _drag_offset: Vector2 = Vector2.ZERO
var _original_position: Vector2 = Vector2.ZERO
var _original_z_index: int = 0
var _mouse_press_pos: Vector2 = Vector2.ZERO
var _mouse_pressed: bool = false

@onready var card_visual: Node2D = $CardVisual
@onready var card_front: Node2D = $CardVisual/CardFront
@onready var card_back_sprite: Sprite2D = $CardVisual/CardBack
@onready var card_image: Sprite2D = $CardVisual/CardFront/CardImage
@onready var card_frame: Sprite2D = $CardVisual/CardFront/CardFrame
@onready var name_label: Label = $CardVisual/CardFront/NameLabel
@onready var value_label: Label = $CardVisual/CardFront/ValueLabel
@onready var reversed_indicator: Sprite2D = $CardVisual/CardFront/ReversedIndicator
@onready var hover_area: Area2D = $HoverArea
@onready var select_glow: Panel = $CardVisual/SelectGlow


func _ready() -> void:
	scale = NORMAL_SCALE
	hover_area.mouse_entered.connect(_on_mouse_entered)
	hover_area.mouse_exited.connect(_on_mouse_exited)
	if select_glow:
		select_glow.visible = false


func setup(data: Resource) -> void:
	card_data = data
	is_face_up = true
	_update_visuals()


func _update_visuals() -> void:
	if not card_data:
		return

	var texture := load(card_data.texture_path) as Texture2D
	if texture and card_image:
		card_image.texture = texture

	if name_label:
		name_label.text = card_data.card_name
	if value_label:
		value_label.text = str(card_data.base_insight)

	if reversed_indicator:
		reversed_indicator.visible = is_reversed

	if card_visual:
		card_visual.rotation = PI if is_reversed else 0.0

	_update_face_visibility()


func _update_face_visibility() -> void:
	if card_front:
		card_front.visible = is_face_up
	if card_back_sprite:
		card_back_sprite.visible = not is_face_up


func select() -> void:
	if is_selected:
		return
	is_selected = true
	if select_glow:
		select_glow.visible = true
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "scale", SELECTED_SCALE, 0.2)
	selected.emit(self)
	EventBus.card_clicked.emit(self)


func deselect() -> void:
	if not is_selected:
		return
	is_selected = false
	if select_glow:
		select_glow.visible = false
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "scale", NORMAL_SCALE, 0.15)
	deselected.emit(self)


func flip_orientation() -> void:
	var tween := create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(card_visual, "scale:x", 0.0, FLIP_DURATION * 0.5)
	tween.tween_callback(_toggle_reversed)
	tween.tween_property(card_visual, "scale:x", 1.0, FLIP_DURATION * 0.5)
	tween.tween_callback(func():
		EventBus.card_flipped.emit(self, is_reversed)
	)


func reveal() -> void:
	if is_face_up:
		return
	var tween := create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(card_visual, "scale:x", 0.0, FLIP_DURATION * 0.5)
	tween.tween_callback(func():
		is_face_up = true
		_update_face_visibility()
	)
	tween.tween_property(card_visual, "scale:x", 1.0, FLIP_DURATION * 0.5)


func hide_card() -> void:
	if not is_face_up:
		return
	var tween := create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(card_visual, "scale:x", 0.0, FLIP_DURATION * 0.5)
	tween.tween_callback(func():
		is_face_up = false
		_update_face_visibility()
	)
	tween.tween_property(card_visual, "scale:x", 1.0, FLIP_DURATION * 0.5)


func _toggle_reversed() -> void:
	is_reversed = not is_reversed
	if reversed_indicator:
		reversed_indicator.visible = is_reversed
	if card_visual:
		card_visual.rotation = PI if is_reversed else 0.0


func _input(event: InputEvent) -> void:
	if not is_hovered:
		return

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_mouse_pressed = true
				_mouse_press_pos = mb.global_position
			else:
				if _mouse_pressed:
					var distance := _mouse_press_pos.distance_to(mb.global_position)
					if is_dragging:
						_end_drag()
					elif distance < DRAG_THRESHOLD:
						if is_selected:
							deselect()
						else:
							select()
					_mouse_pressed = false
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			if is_face_up:
				flip_orientation()

	elif event is InputEventMouseMotion and _mouse_pressed:
		var distance := _mouse_press_pos.distance_to(event.global_position)
		if distance >= DRAG_THRESHOLD and not is_dragging:
			_start_drag(_mouse_press_pos)
		if is_dragging:
			global_position = event.global_position + _drag_offset


func _start_drag(mouse_pos: Vector2) -> void:
	is_dragging = true
	_drag_offset = global_position - mouse_pos
	_original_position = global_position
	_original_z_index = z_index
	z_index = 100
	modulate.a = DRAG_OPACITY
	drag_started.emit(self)
	EventBus.card_drag_started.emit(self)


func _end_drag() -> void:
	if not is_dragging:
		return
	is_dragging = false
	z_index = _original_z_index
	modulate.a = 1.0
	drag_ended.emit(self)
	EventBus.card_drag_ended.emit(self, global_position)
	_return_to_hand()


func _return_to_hand() -> void:
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "global_position", _original_position, 0.3)


func _on_mouse_entered() -> void:
	is_hovered = true
	hovered.emit(self)
	EventBus.card_hovered.emit(self)


func _on_mouse_exited() -> void:
	is_hovered = false
	unhovered.emit(self)
	EventBus.card_unhovered.emit(self)
