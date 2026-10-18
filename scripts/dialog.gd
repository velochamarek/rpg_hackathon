extends CanvasLayer
## MOONLESS – dialogové okno. Autoload s názvem "Dialog" (pod GameState a HUD).
## Nic nepočítá: všechno (staty, podmínky, texty) bere z GameState.
##
## Samo se napojí na tlačítka podle jejich jména, jakmile se objeví ve scéně
## (stačí mít tlačítka pojmenovaná podle LINKS níže). Při kliknutí otevře rozhovor.
## Ručně se dá rozhovor otevřít i odkudkoliv:  Dialog.open("hana")

# Jméno tlačítka ve scéně -> id postavy v GameState.NPCS
# Další postavu přidáte jedním řádkem, např.  "tlacitko_ves": "beta",
const LINKS := {
	"tlacitko_pobrezi": "hana",
	"tlacitko_les": "morwen",
}

const ASSETS := "res://moonless_godot_assets/"
const PORTRAITS := {
	"beta": "portrety/beta.png",
	"hana": "portrety/hana.png",
	"vitek": "portrety/vitek.png",
	"morwen": "portrety/morwen.png",
}
const DARK_SIDE := ["vitek", "morwen"]   # tyhle postavy mají jméno bledě modře

const C_NIGHT := Color("#0E1015")
const C_PANEL := Color("#15171D")
const C_STONE := Color("#4A5162")
const C_TEXT := Color("#E6DCC2")
const C_GOLD := Color("#F2C46D")
const C_AMBER := Color("#F2A541")
const C_EMBER := Color("#B8621B")
const C_GHOST := Color("#9FE6FF")
const FLASH_ALPHA := 0.3

var current_npc := ""
var is_open := false

var _font_title: Font
var _font_body: Font
var _panel: PanelContainer
var _portrait: TextureRect
var _name: Label
var _text: Label
var _narrator: Label
var _action: Button
var _leave: Button
var _flash: ColorRect


func _ready() -> void:
	layer = 5
	_font_title = _load(ASSETS + "fonts/GrenzeGotisch.ttf")
	_font_body = _load(ASSETS + "fonts/Alegreya.ttf")
	_build()
	GameState.glitch_gained.connect(_on_glitch_gained)
	get_tree().node_added.connect(_on_node_added)


func _process(_delta: float) -> void:
	# Když hra skončí nebo se otevřou lektvary, okno zmizí samo
	if is_open and (not GameState.running or GameState.game_over):
		close()


## Otevře rozhovor s postavou (id podle GameState.NPCS: "beta", "hana", "vitek", "morwen").
func open(npc_id: String) -> void:
	if is_open or GameState.game_over:
		return
	var npc: Dictionary = GameState.get_npc(npc_id)
	if npc.is_empty():
		push_warning("Dialog: postava '%s' v GameState neexistuje" % npc_id)
		return
	GameState.start()
	if not GameState.running:
		return
	current_npc = npc_id
	_name.text = npc["name"]
	_name.add_theme_color_override("font_color", C_GHOST if npc_id in DARK_SIDE else C_GOLD)
	_text.text = _quote(npc["greeting"])
	_narrator.text = ""
	_narrator.hide()
	_portrait.texture = _load(ASSETS + PORTRAITS.get(npc_id, ""))
	_action.text = npc["player_line"]
	_action.show()
	_leave.text = "Odejít"
	_panel.show()
	is_open = true


func close() -> void:
	_panel.hide()
	is_open = false
	current_npc = ""


func _on_action_pressed() -> void:
	var result: Dictionary = GameState.interact(current_npc)
	if result.is_empty():
		close()
		return
	var text: String = result.get("text", "")
	_text.text = _quote(text) if text != "" else "„Teď ne.“"
	var narrator: String = result.get("narrator", "")
	_narrator.text = narrator
	_narrator.visible = narrator != ""
	_action.hide()
	_leave.text = "Pokračovat"


func _on_node_added(node: Node) -> void:
	if node is BaseButton and LINKS.has(String(node.name)):
		var npc_id: String = LINKS[String(node.name)]
		node.pressed.connect(func(): open(npc_id))
		# Tlačítka postav jsou na mapě, takže vstup na mapu spustí hru
		GameState.start.call_deferred()


func _on_glitch_gained(_amount: int) -> void:
	_flash.color = Color(C_GHOST, 0.0)
	_flash.show()
	var t := create_tween()
	t.tween_property(_flash, "color:a", FLASH_ALPHA, 0.08)
	t.tween_property(_flash, "color:a", 0.0, 0.35)
	t.tween_callback(_flash.hide)


# ---------------------------------------------------------------- pomocné
func _quote(s: String) -> String:
	return "„" + s + "“"


func _load(path: String) -> Resource:
	if path != ASSETS and ResourceLoader.exists(path):
		return load(path)
	push_warning("Dialog: nenašel jsem soubor " + path)
	return null


func _box(bg: Color, border: Color, border_w: int, margin: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_content_margin_all(margin)
	return sb


func _label(font: Font, size: int, color: Color) -> Label:
	var l := Label.new()
	if font:
		l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


func _button(bg: Color, fg: Color, border: Color) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 50)
	b.focus_mode = Control.FOCUS_NONE
	if _font_body:
		b.add_theme_font_override("font", _font_body)
	b.add_theme_font_size_override("font_size", 21)
	for state in ["font_color", "font_hover_color", "font_pressed_color"]:
		b.add_theme_color_override(state, fg)
	var normal := _box(bg, border, 2, 0)
	normal.content_margin_left = 22
	normal.content_margin_right = 22
	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = bg.lightened(0.12) if bg.a > 0 else Color(border, 0.15)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	return b


func _build() -> void:
	_panel = PanelContainer.new()
	_panel.anchor_left = 0.0
	_panel.anchor_right = 1.0
	_panel.anchor_top = 1.0
	_panel.anchor_bottom = 1.0
	_panel.offset_left = 40
	_panel.offset_right = -40
	_panel.offset_top = -280
	_panel.offset_bottom = -32
	_panel.add_theme_stylebox_override("panel", _box(Color(C_PANEL, 0.95), C_EMBER, 2, 20))
	add_child(_panel)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	_panel.add_child(row)

	var frame := PanelContainer.new()
	frame.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	frame.add_theme_stylebox_override("panel", _box(C_NIGHT, C_STONE, 2, 0))
	row.add_child(frame)
	_portrait = TextureRect.new()
	_portrait.custom_minimum_size = Vector2(160, 200)
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	frame.add_child(_portrait)

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 8)
	row.add_child(col)
	_name = _label(_font_title, 34, C_GOLD)
	col.add_child(_name)
	_text = _label(_font_body, 23, C_TEXT)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size = Vector2(300, 0)
	col.add_child(_text)
	_narrator = _label(_font_body, 20, C_GHOST)
	_narrator.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_narrator.custom_minimum_size = Vector2(300, 0)
	col.add_child(_narrator)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(spacer)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 14)
	col.add_child(buttons)
	_action = _button(C_AMBER, C_PANEL, C_AMBER)
	_action.pressed.connect(_on_action_pressed)
	buttons.add_child(_action)
	_leave = _button(Color(0, 0, 0, 0), C_TEXT, C_STONE)
	_leave.pressed.connect(close)
	buttons.add_child(_leave)
	_panel.hide()

	_flash = ColorRect.new()
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash)
	_flash.hide()
