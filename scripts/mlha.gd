@tool
extends ColorRect
## Plíživá mlha přes celou obrazovku. Přidejte do scény uzel ColorRect,
## připojte tenhle skript a je hotovo: roztáhne se sám a pomalu se valí.
## Na kliknutí nemá vliv (myš propouští skrz).
##
## S rostoucím glitchem mlha postupně modrá do barvy glitche,
## takže hráč vidí, jak se svět kolem něj mění.

@export var barva := Color(0.82, 0.86, 0.93):
	set(v):
		barva = v
		_pouzij()
@export_range(0.0, 1.0) var hustota := 0.75:          # jak moc je mlha neprůhledná
	set(v):
		hustota = v
		_pouzij()
@export_range(0.0, 1.0) var vyska := 0.7:            # jak vysoko od spodu sahá (1 = celá obrazovka)
	set(v):
		vyska = v
		_pouzij()
@export var rychlost := 0.25:                          # jak rychle se valí
	set(v):
		rychlost = v
		_pouzij()
@export var velikost_chuchvalcu := 2.5:               # menší číslo = větší chuchvalce
	set(v):
		velikost_chuchvalcu = v
		_pouzij()
@export_range(0.0, 3.0) var vireni := 1.6:             # jak moc se mlha kroutí a víří (0 = jen plyne)
	set(v):
		vireni = v
		_pouzij()
@export var modrat_s_glitchem := true

const BARVA_GLITCHE := Color("9fe6ff")

const SHADER := """
shader_type canvas_item;
uniform vec4 barva : source_color = vec4(0.82, 0.86, 0.93, 1.0);
uniform float hustota = 0.75;
uniform float vyska = 0.7;
uniform float rychlost = 0.25;
uniform float meritko = 2.5;
uniform float vireni = 1.6;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
	           mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}
float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 5; i++) { v += a * noise(p); p *= 2.0; a *= 0.5; }
	return v;
}
void fragment() {
	vec2 p = vec2(UV.x * 1.78, UV.y) * meritko;
	float t = TIME * rychlost;
	// víření: souřadnice se samy deformují šumem, takže mlha se kroutí a přelévá
	vec2 q = vec2(fbm(p + vec2(t, 0.0)), fbm(p + vec2(5.2, 1.3) - vec2(t * 0.8, t * 0.3)));
	vec2 r = vec2(fbm(p + vireni * q + vec2(1.7 + t * 1.4, 9.2)), fbm(p + vireni * q + vec2(8.3, 2.8 - t * 0.6)));
	float vir = fbm(p + vireni * r + vec2(t * 1.8, 0.0));
	// rychlé cáry, které táhnou přes obraz
	float cary = fbm(p * 2.0 - vec2(t * 3.0, t * 0.6));
	float celkem = vir * 0.75 + cary * 0.35;
	float chuchvalce = smoothstep(0.3, 0.7, celkem);
	float dech = 0.78 + 0.22 * sin(TIME * 1.4) * sin(TIME * 0.37 + 1.0);
	float zdola = smoothstep(1.0 - vyska - 0.3, 1.0 - vyska + 0.3, UV.y);
	COLOR = vec4(barva.rgb, barva.a * chuchvalce * hustota * zdola * dech);
}
"""

var _material: ShaderMaterial


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if get_parent() is Control:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	else:
		# Rodič není Control (např. Node2D): kotvy by daly nulovou velikost,
		# takže mlhu roztáhneme na velikost obrazovky ručně.
		set_anchors_preset(Control.PRESET_TOP_LEFT)
		position = Vector2.ZERO
		size = Vector2(
			ProjectSettings.get_setting("display/window/size/viewport_width"),
			ProjectSettings.get_setting("display/window/size/viewport_height"))
	color = Color.WHITE
	var shader := Shader.new()
	shader.code = SHADER
	_material = ShaderMaterial.new()
	_material.shader = shader
	material = _material
	_pouzij()


func _process(_delta: float) -> void:
	if Engine.is_editor_hint() or not modrat_s_glitchem or _material == null:
		return
	var podil: float = clampf(GameState.glitch / 100.0, 0.0, 1.0) * 0.7
	_material.set_shader_parameter("barva", barva.lerp(BARVA_GLITCHE, podil))


func _pouzij() -> void:
	if _material == null:
		return
	_material.set_shader_parameter("barva", barva)
	_material.set_shader_parameter("hustota", hustota)
	_material.set_shader_parameter("vyska", vyska)
	_material.set_shader_parameter("rychlost", rychlost)
	_material.set_shader_parameter("meritko", velikost_chuchvalcu)
	_material.set_shader_parameter("vireni", vireni)
