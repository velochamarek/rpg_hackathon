@tool
extends Node2D
## Mihotavá záře pochodně. Připojte na Sprite2D nebo PointLight2D.
## U Sprite2D bez obrázku si záři (jantarový kruh) vytvoří sama.

@export var sila := 0.35          # jak moc se záře mihotá (0 = vůbec)
@export var rychlost := 7.0       # jak rychle
@export var velikost := 260.0     # průměr záře v pixelech (jen u Sprite2D bez obrázku)

var _sum := FastNoiseLite.new()
var _cas := 0.0
var _zakladni_scale := Vector2.ONE
var _zakladni_energie := 1.0


func _ready() -> void:
	_sum.frequency = 0.5
	_sum.seed = randi()
	_zakladni_scale = scale
	var uzel: Node = self
	if uzel is Sprite2D and uzel.texture == null:
		uzel.texture = _zare()
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		material = mat
	if uzel is PointLight2D:
		_zakladni_energie = uzel.energy


func _process(delta: float) -> void:
	_cas += delta * rychlost
	var n := _sum.get_noise_1d(_cas * 10.0)          # −1 až 1
	modulate.a = clampf(0.85 + n * sila * 0.6, 0.0, 1.0)
	scale = _zakladni_scale * (1.0 + n * sila * 0.15)
	var uzel: Node = self
	if uzel is PointLight2D:
		uzel.energy = _zakladni_energie * (1.0 + n * sila)


func _zare() -> GradientTexture2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.35, 1.0])
	g.colors = PackedColorArray([Color(1, 0.8, 0.45, 0.55), Color(0.95, 0.55, 0.2, 0.25), Color(0.9, 0.4, 0.1, 0.0)])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = int(velikost)
	t.height = int(velikost)
	return t
