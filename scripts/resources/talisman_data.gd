extends Resource
## Data container for a single talisman.

@export var talisman_id: String = ""
@export var talisman_name: String = ""
@export var description: String = ""
@export var tier: String = "common"  # common, uncommon, rare, legendary
@export var cost: int = 0
@export var effect_id: String = ""  # maps to effect logic in TalismanEffects


static func from_dict(data: Dictionary) -> Resource:
	var script := load("res://scripts/resources/talisman_data.gd")
	var talisman: Resource = script.new()
	talisman.talisman_id = data.get("talisman_id", "")
	talisman.talisman_name = data.get("talisman_name", "")
	talisman.description = data.get("description", "")
	talisman.tier = data.get("tier", "common")
	talisman.cost = int(data.get("cost", 0))
	talisman.effect_id = data.get("effect_id", "")
	return talisman
