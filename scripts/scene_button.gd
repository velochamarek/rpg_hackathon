extends BaseButton
## Univerzální tlačítko. Funguje na Button i TextureButton.
## V Inspectoru nastavíte, co má udělat:
##
##   Target Scene  – přepne na tuto scénu (mapa, lokace, úvod…)
##   Reset Game    – před přepnutím vynuluje staty (Nová hra, Probudit se znovu)
##   Ending Id     – místo přepnutí ukončí hru tímto koncem
##                   (lektvary: "escape" = červený, "forget" = modrý)

@export_file("*.tscn") var target_scene: String
@export var reset_game := false
@export var ending_id := ""

## Jak moc se tlačítko rozjasní, když na něj najedete myší
@export var hover_brightness := 1.15


func _ready() -> void:
	pressed.connect(_on_pressed)
	mouse_entered.connect(func(): modulate = Color(hover_brightness, hover_brightness, hover_brightness))
	mouse_exited.connect(func(): modulate = Color.WHITE)


func _on_pressed() -> void:
	if ending_id != "":
		GameState.end_game(ending_id)
		return
	if reset_game:
		GameState.reset()
	if target_scene == "":
		push_warning("Tlačítko %s nemá nastavenou cílovou scénu." % name)
		return
	get_tree().change_scene_to_file(target_scene)
