extends CanvasLayer
## HUD se staty. Vzhled se upravuje ve scéně hud.tscn v editoru,
## tenhle skript jen dosazuje hodnoty z GameState.
## Zapojit jako Autoload: res://hud.tscn s názvem "HUD" (pod GameState).
##
## Barvu statu změníte v editoru u uzlu Name (Theme Overrides → Colors).
## Skript si ji při startu přečte a použije i pro dílky.

const DANGER := Color("e05a4f")        # barva komfortu, když dochází
const DANGER_THRESHOLD := 0.2          # pod 20 % komfortu
const EMPTY_PIP := Color(1, 1, 1, 0.08)

@onready var rows := {
	"comfort": $Panel/VBox/ComfortRow,
	"reputation": $Panel/VBox/ReputationRow,
	"glitch": $Panel/VBox/GlitchRow,
}

var _base_colors := {}
var _last := {}


func _ready() -> void:
	for key in rows:
		var name_label: Label = rows[key].get_node("Name")
		_base_colors[key] = name_label.get_theme_color("font_color")
	GameState.stats_changed.connect(_update)
	_update()


func _process(_delta: float) -> void:
	# Ukázat jen během hry, ne v menu ani na endingu
	visible = GameState.running and not GameState.game_over


func _update() -> void:
	for key in rows:
		var row: Control = rows[key]
		var value: int = GameState.get(key)
		var max_value: int = GameState.MAX_STAT
		var ratio := float(value) / max_value

		var color: Color = _base_colors[key]
		if key == "comfort" and ratio <= DANGER_THRESHOLD:
			color = DANGER

		var name_label: Label = row.get_node("Name")
		name_label.add_theme_color_override("font_color", color)

		var pips := row.get_node("Pips").get_children()
		var filled := int(round(ratio * pips.size()))
		for i in pips.size():
			pips[i].color = color if i < filled else EMPTY_PIP

		var value_label: Label = row.get_node("Value")
		value_label.text = "%d/%d" % [value, max_value]

		# Krátký záblesk řádku, když se hodnota změnila
		if _last.has(key) and _last[key] != value:
			_flash(row)
		_last[key] = value


func _flash(node: Control) -> void:
	node.modulate = Color(1.8, 1.8, 1.8)
	create_tween().tween_property(node, "modulate", Color.WHITE, 0.4)
