@tool
extends CPUParticles2D
## Hotové částicové efekty pro Moonless. Připojte na uzel CPUParticles2D
## a v Inspectoru vyberte "Druh". Efekt je vidět rovnou v editoru.
##
##   PLAMEN     oheň pochodně (dejte ho na místo plamene)
##   JISKRY     jiskry stoupající z pochodně
##   SVETLUSKY  jantarové tečky poletující po lokaci
##   DUCHOVE    bledě modré chuchvalce (barva glitche)
##   PRACH      jemný prach ve vzduchu
##
## U plošných efektů (světlušky, duchové, prach) nastavte "Oblast"
## a uzel posuňte doprostřed plochy, kde se mají objevovat.

enum Druh { PLAMEN, JISKRY, SVETLUSKY, DUCHOVE, PRACH }

@export var druh: Druh = Druh.SVETLUSKY:
	set(value):
		druh = value
		_nastav()

@export var oblast := Vector2(1920, 1080):
	set(value):
		oblast = value
		_nastav()


func _ready() -> void:
	_nastav()


func _nastav() -> void:
	texture = _tecka()
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = mat
	local_coords = false
	emitting = true
	color_ramp = null
	scale_amount_curve = null

	match druh:
		Druh.PLAMEN:
			amount = 40
			lifetime = 0.6
			preprocess = 0.6
			emission_shape = EMISSION_SHAPE_SPHERE
			emission_sphere_radius = 7.0
			direction = Vector2(0, -1)
			spread = 12.0
			gravity = Vector2(0, -140)
			initial_velocity_min = 15.0
			initial_velocity_max = 35.0
			scale_amount_min = 0.9
			scale_amount_max = 1.3
			scale_amount_curve = _krivka([Vector2(0, 0.6), Vector2(0.2, 1.0), Vector2(1, 0.0)])
			color_ramp = _prechod([Color("fff3b0"), Color("f2a541"), Color("b8621b"), Color(0.5, 0.1, 0.05, 0.0)])
		Druh.JISKRY:
			amount = 14
			lifetime = 1.6
			preprocess = 1.6
			emission_shape = EMISSION_SHAPE_SPHERE
			emission_sphere_radius = 8.0
			direction = Vector2(0, -1)
			spread = 30.0
			gravity = Vector2(0, -30)
			initial_velocity_min = 40.0
			initial_velocity_max = 90.0
			scale_amount_min = 0.12
			scale_amount_max = 0.25
			color_ramp = _prechod([Color("fff3b0"), Color("f2a541"), Color(0.9, 0.3, 0.1, 0.0)])
		Druh.SVETLUSKY:
			amount = 28
			lifetime = 7.0
			preprocess = 7.0
			emission_shape = EMISSION_SHAPE_RECTANGLE
			emission_rect_extents = oblast / 2.0
			direction = Vector2(0, -1)
			spread = 180.0
			gravity = Vector2.ZERO
			initial_velocity_min = 6.0
			initial_velocity_max = 18.0
			scale_amount_min = 0.15
			scale_amount_max = 0.35
			color_ramp = _prechod([Color(0.95, 0.77, 0.43, 0.0), Color(0.95, 0.77, 0.43, 0.9), Color(0.95, 0.77, 0.43, 0.0)])
		Druh.DUCHOVE:
			amount = 10
			lifetime = 9.0
			preprocess = 9.0
			emission_shape = EMISSION_SHAPE_RECTANGLE
			emission_rect_extents = oblast / 2.0
			direction = Vector2(1, -0.3)
			spread = 40.0
			gravity = Vector2.ZERO
			initial_velocity_min = 8.0
			initial_velocity_max = 20.0
			scale_amount_min = 1.2
			scale_amount_max = 2.4
			color_ramp = _prechod([Color(0.62, 0.9, 1, 0.0), Color(0.62, 0.9, 1, 0.22), Color(0.62, 0.9, 1, 0.0)])
		Druh.PRACH:
			amount = 50
			lifetime = 10.0
			preprocess = 10.0
			emission_shape = EMISSION_SHAPE_RECTANGLE
			emission_rect_extents = oblast / 2.0
			direction = Vector2(1, 0.2)
			spread = 60.0
			gravity = Vector2(0, 3)
			initial_velocity_min = 3.0
			initial_velocity_max = 10.0
			scale_amount_min = 0.06
			scale_amount_max = 0.14
			color_ramp = _prechod([Color(0.85, 0.79, 0.64, 0.0), Color(0.85, 0.79, 0.64, 0.35), Color(0.85, 0.79, 0.64, 0.0)])


# Měkká kulatá tečka (aby částice nebyly hranaté čtverečky)
static func _tecka() -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 32
	t.height = 32
	return t


static func _prechod(barvy: Array) -> Gradient:
	var g := Gradient.new()
	var offsets := PackedFloat32Array()
	var colors := PackedColorArray()
	for i in barvy.size():
		offsets.append(float(i) / (barvy.size() - 1))
		colors.append(barvy[i])
	g.offsets = offsets
	g.colors = colors
	return g


static func _krivka(body: Array) -> Curve:
	var c := Curve.new()
	for b in body:
		c.add_point(b)
	return c
