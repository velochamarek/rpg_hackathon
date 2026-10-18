extends Control
## Finále v katedrále (glitch 100).
## Obraz se roztrhne, objeví se Morwen, napíše svou větu
## a nakonec se nabídnou dva lektvary. Svět se při tom průběžně "trhá".
##
## Lektvary jsou tlačítka se skriptem scene_button.gd:
##   červený -> Ending Id "escape", modrý -> Ending Id "forget".
## Obrázky (katedrála, Morwen) přetáhněte v editoru do uzlů
## Background a Portrait, texty upravíte přímo v labelech.

@export var type_speed := 0.035          # sekund na jedno písmeno Morweniny věty
@export var idle_glitch_min := 2.5       # jak často se svět sám trhne (od–do sekund)
@export var idle_glitch_max := 6.0
@export var shake_strength := 14.0       # jak moc se pozadí při glitchi posune (px)

@onready var background: TextureRect = $Background
@onready var flash: ColorRect = $GlitchFlash
@onready var fade: ColorRect = $Fade
@onready var portrait: TextureRect = $Content/HBox/Portrait
@onready var name_label: Label = $Content/HBox/Right/Name
@onready var speech: Label = $Content/HBox/Right/Speech
@onready var potions: Control = $Content/HBox/Right/Potions

var _rng := RandomNumberGenerator.new()
var _bg_origin := Vector2.ZERO
var _idle_timer: Timer


func _ready() -> void:
	_rng.randomize()
	_bg_origin = background.position

	# Na začátku je všechno schované
	fade.color.a = 1.0
	flash.color.a = 0.0
	portrait.modulate.a = 0.0
	name_label.modulate.a = 0.0
	speech.visible_ratio = 0.0
	potions.modulate.a = 0.0
	_set_potions_enabled(false)

	_idle_timer = Timer.new()
	_idle_timer.one_shot = true
	_idle_timer.timeout.connect(_on_idle_glitch)
	add_child(_idle_timer)

	_play_intro()


func _play_intro() -> void:
	var t := create_tween()
	# 1. Ze tmy se vynoří katedrála
	t.tween_property(fade, "color:a", 0.0, 1.2)
	# 2. Svět praskne
	t.tween_callback(_glitch_burst)
	t.tween_interval(0.7)
	# 3. Objeví se Morwen
	t.tween_property(portrait, "modulate:a", 1.0, 1.0)
	t.parallel().tween_property(name_label, "modulate:a", 1.0, 1.0)
	# 4. Její věta se postupně vypíše
	t.tween_property(speech, "visible_ratio", 1.0, speech.text.length() * type_speed)
	t.tween_interval(0.5)
	# 5. Další trhlina a lektvary
	t.tween_callback(_glitch_burst)
	t.tween_property(potions, "modulate:a", 1.0, 0.8)
	t.tween_callback(_set_potions_enabled.bind(true))
	t.tween_callback(_schedule_idle_glitch)


## Krátké roztrhnutí světa: modrý záblesk a cuknutí pozadí
func _glitch_burst() -> void:
	var t := create_tween()
	for i in 3:
		var offset := Vector2(
			_rng.randf_range(-shake_strength, shake_strength),
			_rng.randf_range(-shake_strength * 0.4, shake_strength * 0.4))
		t.tween_property(flash, "color:a", _rng.randf_range(0.15, 0.4), 0.04)
		t.parallel().tween_property(background, "position", _bg_origin + offset, 0.04)
		t.tween_property(flash, "color:a", 0.0, 0.08)
		t.parallel().tween_property(background, "position", _bg_origin, 0.08)


func _schedule_idle_glitch() -> void:
	_idle_timer.start(_rng.randf_range(idle_glitch_min, idle_glitch_max))


func _on_idle_glitch() -> void:
	_glitch_burst()
	_schedule_idle_glitch()


func _set_potions_enabled(enabled: bool) -> void:
	for child in potions.get_children():
		if child is BaseButton:
			child.disabled = not enabled
