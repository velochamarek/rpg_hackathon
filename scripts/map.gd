extends Control
## Mapa. Spustí hru (čas, HUD) a při glitchi 100 ukáže šipku ke katedrále.
## Šipku (Button nebo TextureButton se scene_button.gd) přiřaďte
## v Inspectoru do pole "Cathedral Arrow".

@export var cathedral_arrow: Control

var _pulse: Tween


func _ready() -> void:
	GameState.start()
	GameState.stats_changed.connect(_update_arrow)
	_update_arrow()


func _update_arrow() -> void:
	if cathedral_arrow == null:
		return
	var open := GameState.is_cathedral_open()
	cathedral_arrow.visible = open
	if open and _pulse == null:
		# Šipka jemně pulzuje, aby si jí hráč všiml
		_pulse = create_tween().set_loops()
		_pulse.tween_property(cathedral_arrow, "modulate:a", 0.45, 0.8)
		_pulse.tween_property(cathedral_arrow, "modulate:a", 1.0, 0.8)
	elif not open and _pulse != null:
		_pulse.kill()
		_pulse = null
		cathedral_arrow.modulate.a = 1.0
