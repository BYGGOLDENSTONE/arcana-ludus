extends Node2D
## Shop scene shown between nights. Offers card packs, deck management
## (remove/return cards via sideboard), and talisman purchase/sell.

signal shop_closed()

const PACK_COST := 8
const MIN_DECK_SIZE := 15

var _pack_cards: Array = []
var _pack_state: String = "idle"  # idle, showing
var _shop_talismans: Array = []

# -- Node references --
@onready var gold_label: Label = $UI/TopBar/HBoxContainer/GoldLabel
@onready var deck_count_label: Label = $UI/TopBar/HBoxContainer/DeckCountLabel
@onready var buy_pack_button: Button = $UI/ShopGrid/CardPackSection/VBox/BuyPackButton
@onready var pack_info_label: Label = $UI/ShopGrid/CardPackSection/VBox/PackInfoLabel
@onready var card_display: HBoxContainer = $UI/ShopGrid/CardPackSection/VBox/CardDisplay
@onready var deck_list: VBoxContainer = $UI/ShopGrid/DeckSection/VBox/DeckScroll/DeckList
@onready var sideboard_list: VBoxContainer = $UI/ShopGrid/DeckSection/VBox/SideboardScroll/SideboardList
@onready var deck_info_label: Label = $UI/ShopGrid/DeckSection/VBox/DeckInfoLabel
@onready var talisman_display: VBoxContainer = $UI/ShopGrid/TalismanSection/VBox/TalismanDisplay
@onready var talisman_info_label: Label = $UI/ShopGrid/TalismanSection/VBox/TalismanInfoLabel
@onready var owned_list: VBoxContainer = $UI/ShopGrid/TalismanSection/VBox/OwnedScroll/OwnedList
@onready var leave_button: Button = $UI/LeaveButton


func _ready() -> void:
	buy_pack_button.pressed.connect(_on_buy_pack_pressed)
	leave_button.pressed.connect(_on_leave_pressed)
	EventBus.gold_changed.connect(_on_gold_changed)


func open_shop() -> void:
	_pack_state = "idle"
	_pack_cards.clear()
	_clear_pack_display()
	pack_info_label.text = "Draw a pack to see 3 cards"
	_refresh_gold_display()
	_refresh_deck_list()
	_refresh_sideboard_list()
	_generate_shop_talismans()
	_refresh_owned_talismans()
	_update_button_states()
	visible = true
	EventBus.shop_entered.emit()


# -- Card Pack --

func _on_buy_pack_pressed() -> void:
	if _pack_state == "showing":
		return
	if not GameManager.spend_gold(PACK_COST):
		return
	_generate_pack()
	_update_button_states()


func _generate_pack() -> void:
	_pack_cards.clear()
	_clear_pack_display()

	var all_minor: Array = DataLoader.get_cards_by_type("minor_arcana")
	var deck_ids: Dictionary = {}
	for card in DeckManager.player_deck:
		deck_ids[card.card_id] = true
	for card in DeckManager.sideboard:
		deck_ids[card.card_id] = true

	var available: Array = []
	for card in all_minor:
		if not deck_ids.has(card.card_id):
			available.append(card)

	if available.size() < 3:
		available = all_minor.duplicate()

	available.shuffle()
	for i in range(mini(3, available.size())):
		_pack_cards.append(available[i])

	_show_pack_cards()
	_pack_state = "showing"
	pack_info_label.text = "Pick a card to add to your deck"


func _show_pack_cards() -> void:
	for i in range(_pack_cards.size()):
		var card_data: Resource = _pack_cards[i]
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(180, 100)
		btn.text = "%s\n%s | Insight: %d" % [
			card_data.card_name,
			card_data.suit.capitalize(),
			card_data.base_insight,
		]
		_apply_card_button_style(btn)
		var idx := i
		btn.pressed.connect(_on_pack_card_selected.bind(idx))
		card_display.add_child(btn)


func _on_pack_card_selected(index: int) -> void:
	if _pack_state != "showing":
		return
	if index < 0 or index >= _pack_cards.size():
		return

	var selected: Resource = _pack_cards[index]
	DeckManager.add_to_deck(selected)

	_pack_state = "idle"
	_pack_cards.clear()
	_clear_pack_display()
	pack_info_label.text = "Added %s to your deck!" % selected.card_name

	_refresh_deck_list()
	_update_button_states()


func _clear_pack_display() -> void:
	for child in card_display.get_children():
		child.queue_free()


# -- Deck Management --

func _refresh_deck_list() -> void:
	for child in deck_list.get_children():
		child.queue_free()

	for card_data in DeckManager.player_deck:
		var btn := Button.new()
		btn.text = "%s (%s) — Insight: %d" % [
			card_data.card_name,
			card_data.suit.capitalize(),
			card_data.base_insight,
		]
		btn.custom_minimum_size = Vector2(0, 32)
		_apply_list_button_style(btn)
		btn.pressed.connect(_on_remove_card.bind(card_data))
		deck_list.add_child(btn)

	deck_info_label.text = "Deck: %d cards" % DeckManager.player_deck.size()
	_refresh_gold_display()


func _refresh_sideboard_list() -> void:
	for child in sideboard_list.get_children():
		child.queue_free()

	for card_data in DeckManager.sideboard:
		var btn := Button.new()
		btn.text = "%s (%s) — Insight: %d" % [
			card_data.card_name,
			card_data.suit.capitalize(),
			card_data.base_insight,
		]
		btn.custom_minimum_size = Vector2(0, 32)
		_apply_return_button_style(btn)
		btn.pressed.connect(_on_return_card.bind(card_data))
		sideboard_list.add_child(btn)


func _on_remove_card(card_data: Resource) -> void:
	if DeckManager.player_deck.size() <= MIN_DECK_SIZE:
		deck_info_label.text = "Minimum deck size reached (%d)" % MIN_DECK_SIZE
		return
	DeckManager.remove_from_deck(card_data)
	deck_info_label.text = "Removed %s" % card_data.card_name
	_refresh_deck_list()
	_refresh_sideboard_list()
	_update_button_states()


func _on_return_card(card_data: Resource) -> void:
	DeckManager.return_from_sideboard(card_data)
	deck_info_label.text = "Returned %s to deck" % card_data.card_name
	_refresh_deck_list()
	_refresh_sideboard_list()
	_update_button_states()


# -- Talismans --

func _generate_shop_talismans() -> void:
	_shop_talismans = DataLoader.get_shop_talismans(3)
	_refresh_talisman_display()


func _refresh_talisman_display() -> void:
	for child in talisman_display.get_children():
		child.queue_free()

	for i in range(_shop_talismans.size()):
		var talisman: Resource = _shop_talismans[i]
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(0, 50)
		btn.text = "%s (%s)\n%s — %dg" % [
			talisman.talisman_name,
			talisman.tier.capitalize(),
			talisman.description,
			talisman.cost,
		]
		_apply_talisman_button_style(btn, talisman.tier)
		var idx: int = i
		btn.pressed.connect(_on_buy_talisman.bind(idx))
		talisman_display.add_child(btn)

	if _shop_talismans.is_empty():
		talisman_info_label.text = "No talismans available"
	else:
		talisman_info_label.text = "Owned: %d / %d" % [TalismanManager.get_talisman_count(), TalismanManager.MAX_TALISMANS]


func _on_buy_talisman(index: int) -> void:
	if index < 0 or index >= _shop_talismans.size():
		return
	var talisman: Resource = _shop_talismans[index]

	if TalismanManager.get_talisman_count() >= TalismanManager.MAX_TALISMANS:
		talisman_info_label.text = "Max talismans reached (%d)" % TalismanManager.MAX_TALISMANS
		return

	if not GameManager.spend_gold(talisman.cost):
		talisman_info_label.text = "Not enough gold!"
		return

	TalismanManager.add_talisman(talisman)
	_shop_talismans.remove_at(index)

	talisman_info_label.text = "Bought %s!" % talisman.talisman_name
	_refresh_talisman_display()
	_refresh_owned_talismans()
	_refresh_gold_display()
	_update_button_states()


func _refresh_owned_talismans() -> void:
	for child in owned_list.get_children():
		child.queue_free()

	for talisman in TalismanManager.active_talismans:
		var btn := Button.new()
		btn.text = "%s — %s (sell: %dg)" % [
			talisman.talisman_name,
			talisman.description,
			int(talisman.cost * 0.5),
		]
		btn.custom_minimum_size = Vector2(0, 28)
		_apply_list_button_style(btn)
		btn.pressed.connect(_on_sell_talisman.bind(talisman))
		owned_list.add_child(btn)


func _on_sell_talisman(talisman: Resource) -> void:
	var sell_price: int = int(talisman.cost * 0.5)
	TalismanManager.remove_talisman(talisman)
	GameManager.earn_gold(sell_price)
	talisman_info_label.text = "Sold %s for %dg" % [talisman.talisman_name, sell_price]
	_refresh_owned_talismans()
	_refresh_talisman_display()
	_refresh_gold_display()
	_update_button_states()


func _get_tier_color_tag(tier: String) -> String:
	match tier:
		"common": return "common"
		"uncommon": return "uncommon"
		"rare": return "rare"
		"legendary": return "legendary"
	return "common"


func _apply_talisman_button_style(btn: Button, tier: String) -> void:
	var tier_color: Color
	match tier:
		"common": tier_color = Color(0.7, 0.7, 0.7, 1)
		"uncommon": tier_color = Color(0.4, 0.7, 0.4, 1)
		"rare": tier_color = Color(0.4, 0.5, 0.9, 1)
		"legendary": tier_color = Color(0.9, 0.7, 0.2, 1)
		_: tier_color = Color(0.7, 0.7, 0.7, 1)
	btn.add_theme_color_override("font_color", tier_color)
	btn.add_theme_color_override("font_hover_color", tier_color * 1.2)
	btn.add_theme_font_size_override("font_size", 13)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.06, 0.06, 0.14, 0.9)
	normal.set_border_width_all(1)
	normal.border_color = tier_color * 0.5
	normal.set_corner_radius_all(6)
	normal.set_content_margin_all(8)
	btn.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate()
	hover.bg_color = Color(0.10, 0.10, 0.22, 1)
	hover.border_color = tier_color * 0.8
	btn.add_theme_stylebox_override("hover", hover)


# -- Leave --

func _on_leave_pressed() -> void:
	visible = false
	EventBus.shop_exited.emit()
	shop_closed.emit()


# -- UI Helpers --

func _on_gold_changed(_new_amount: int) -> void:
	_refresh_gold_display()
	_update_button_states()


func _refresh_gold_display() -> void:
	gold_label.text = "Gold: %d" % GameManager.gold
	deck_count_label.text = "Deck: %d" % DeckManager.player_deck.size()


func _update_button_states() -> void:
	var can_buy: bool = GameManager.gold >= PACK_COST and _pack_state != "showing"
	buy_pack_button.disabled = not can_buy
	if _pack_state == "showing":
		buy_pack_button.text = "Pick a card first"
	else:
		buy_pack_button.text = "Draw Pack (%dg)" % PACK_COST

	# Disable remove buttons if deck at minimum
	var can_remove: bool = DeckManager.player_deck.size() > MIN_DECK_SIZE
	for btn in deck_list.get_children():
		if btn is Button:
			btn.disabled = not can_remove


func _apply_card_button_style(btn: Button) -> void:
	btn.add_theme_color_override("font_color", Color(0.85, 0.80, 0.65, 1))
	btn.add_theme_color_override("font_hover_color", Color(0.90, 0.75, 0.30, 1))
	btn.add_theme_font_size_override("font_size", 14)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.08, 0.10, 0.18, 1)
	normal.set_border_width_all(2)
	normal.border_color = Color(0.65, 0.55, 0.30, 0.6)
	normal.set_corner_radius_all(8)
	normal.set_content_margin_all(12)
	btn.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate()
	hover.bg_color = Color(0.12, 0.14, 0.24, 1)
	hover.border_color = Color(0.90, 0.75, 0.30, 0.8)
	btn.add_theme_stylebox_override("hover", hover)


func _apply_list_button_style(btn: Button) -> void:
	btn.add_theme_color_override("font_color", Color(0.85, 0.80, 0.65, 1))
	btn.add_theme_color_override("font_hover_color", Color(0.90, 0.75, 0.30, 1))
	btn.add_theme_font_size_override("font_size", 12)
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.06, 0.08, 0.14, 0.8)
	normal.border_width_bottom = 1
	normal.border_color = Color(0.65, 0.55, 0.30, 0.15)
	normal.content_margin_left = 8.0
	normal.content_margin_top = 2.0
	normal.content_margin_bottom = 2.0
	btn.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate()
	hover.bg_color = Color(0.10, 0.12, 0.20, 0.9)
	hover.border_color = Color(0.80, 0.30, 0.25, 0.6)
	btn.add_theme_stylebox_override("hover", hover)


func _apply_return_button_style(btn: Button) -> void:
	btn.add_theme_color_override("font_color", Color(0.60, 0.55, 0.45, 0.8))
	btn.add_theme_color_override("font_hover_color", Color(0.30, 0.80, 0.40, 1))
	btn.add_theme_font_size_override("font_size", 12)
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.05, 0.07, 0.12, 0.6)
	normal.border_width_bottom = 1
	normal.border_color = Color(0.40, 0.35, 0.25, 0.15)
	normal.content_margin_left = 8.0
	normal.content_margin_top = 2.0
	normal.content_margin_bottom = 2.0
	btn.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate()
	hover.bg_color = Color(0.08, 0.12, 0.10, 0.8)
	hover.border_color = Color(0.30, 0.70, 0.35, 0.5)
	btn.add_theme_stylebox_override("hover", hover)
