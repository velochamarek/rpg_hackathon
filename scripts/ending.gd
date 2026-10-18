extends Control
## Obrazovka endingu. Text se vybírá podle GameState.ending.

@onready var title_label: Label = $CenterContainer/VBoxContainer/TitleLabel
@onready var text_label: Label = $CenterContainer/VBoxContainer/TextLabel

# Každý ending: [nadpis, text]
const ENDINGS := {
	"death": [
		"Vyhasnutí",
		"Hlad, zima a únava byly silnější. Simulace pokračuje dál, jen už bez tebe. Kamery se pomalu otočí jinam.",
	],
	"escape": [
		"Útěk",
		"Za stěnou monitorů jsou dveře. Otevřeš je a poprvé v životě nevíš, co bude dál. Je to ten nejkrásnější pocit.",
	],
	"system": [
		"Spokojený občan",
		"Lidé tě mají rádi, máš teplo a plný talíř. Glitche už nevidíš. Sledovanost nikdy nebyla vyšší.",
	],
}


func _ready() -> void:
	var data: Array = ENDINGS.get(GameState.ending, ["Konec hry", ""])
	title_label.text = data[0]
	text_label.text = data[1]


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://MainMenu.tscn")
