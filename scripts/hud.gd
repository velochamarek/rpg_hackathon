extends CanvasLayer
## Ukazatele statů nahoře na obrazovce. Připojit na uzel HUD (CanvasLayer).

@onready var comfort_bar: ProgressBar = $HBoxContainer/ComfortBar
@onready var reputation_bar: ProgressBar = $HBoxContainer/ReputationBar
@onready var glitch_bar: ProgressBar = $HBoxContainer/GlitchBar


func _ready() -> void:
	GameState.stats_changed.connect(_update)
	_update()


func _update() -> void:
	comfort_bar.value = GameState.comfort
	reputation_bar.value = GameState.reputation
	glitch_bar.value = GameState.glitch
