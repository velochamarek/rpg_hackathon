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
	# Tlačítka pojmenovaná podle postavy (fungují v jakékoli scéně, i na mapě)
	"tlacitko_beta": "beta",
	"tlacitko_hana": "hana",
	"tlacitko_vitek": "vitek",
	"tlacitko_morwen": "morwen",
	"tlacitko_anselm": "anselm",
	"tlacitko_ezechiel": "ezechiel",
}

const ASSETS := "res://moonless_godot_assets/"

# Portréty postav ve složce PORTRAIT_FOLDER.
const PORTRAIT_FOLDER := "res://moonless_godot_assets/portrety/"
const PORTRAIT_FILES := {
	"hana": "rybarka_hana.png",
	"morwen": "morwen_carodejka.png",
	"beta": "obchodnice_beta.png",
	"vitek": "zpevak_vitek.png",
	"anselm": "knez_anselm.png",
	"ezechiel": "prorok_ezechiel.png",
}
# Záloha: když soubor výše chybí, hledá se <id>.webp/.jpg/.jpeg/.png (např. hana.png)
const PORTRAIT_EXTENSIONS := ["webp", "jpg", "jpeg", "png"]

# Po skončení rozhovoru se hráč vrátí na mapu (pokud už na ní není).
const RETURN_TO_MAP := true
const MAP_SCENE := "res://map.tscn"
const DARK_SIDE := ["vitek", "ezechiel", "morwen"]   # tyhle postavy mají jméno bledě modře

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
var _loot: Label          # "+1 ryba", "−1 ryba" pod odpovědí
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
	# Scéna, která už byla načtená před Dialogem (např. spuštění mapy přes F6)
	_link_existing.call_deferred(get_tree().root)


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
	_loot.text = ""
	_loot.hide()
	_portrait.texture = _find_portrait(npc_id)
	_action.text = npc["player_line"]
	_action.show()
	_leave.text = "Odejít"
	_panel.show()
	is_open = true


func close() -> void:
	_panel.hide()
	is_open = false
	current_npc = ""


## Hráč rozhovor ukončil sám (Odejít / Pokračovat): zavřít a vrátit na mapu.
func _on_leave_pressed() -> void:
	close()
	if not RETURN_TO_MAP:
		return
	# Když hra končí (smrt, katedrála), o další scéně rozhoduje GameState
	if GameState.game_over or not GameState.running or GameState.comfort <= GameState.MIN_STAT:
		return
	var current := get_tree().current_scene
	if current and current.scene_file_path == MAP_SCENE:
		return
	if ResourceLoader.exists(MAP_SCENE):
		get_tree().change_scene_to_file.call_deferred(MAP_SCENE)
	else:
		push_warning("Dialog: mapa '%s' neexistuje, zkontrolujte MAP_SCENE" % MAP_SCENE)


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
	var loot: String = result.get("loot", "")
	_loot.text = loot
	_loot.visible = loot != ""
	_action.hide()
	_leave.text = "Pokračovat"


func _on_node_added(node: Node) -> void:
	if node is BaseButton and LINKS.has(String(node.name)) and not node.has_meta("_dialog_linked"):
		node.set_meta("_dialog_linked", true)
		var npc_id: String = LINKS[String(node.name)]
		node.pressed.connect(func(): open(npc_id))
		# Tlačítka postav jsou na mapě, takže vstup na mapu spustí hru
		GameState.start.call_deferred()


func _link_existing(node: Node) -> void:
	_on_node_added(node)
	for child in node.get_children():
		_link_existing(child)


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


func _find_portrait(npc_id: String) -> Texture2D:
	if PORTRAIT_FILES.has(npc_id):
		var named: String = PORTRAIT_FOLDER + PORTRAIT_FILES[npc_id]
		if ResourceLoader.exists(named):
			return load(named)
	for ext in PORTRAIT_EXTENSIONS:
		var path: String = PORTRAIT_FOLDER + npc_id + "." + ext
		if ResourceLoader.exists(path):
			return load(path)
	push_warning("Dialog: nenašel jsem portrét '%s' ve složce %s" % [npc_id, PORTRAIT_FOLDER])
	return null


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
	_loot = _label(_font_body, 20, C_AMBER)
	col.add_child(_loot)
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
	_leave.pressed.connect(_on_leave_pressed)
	buttons.add_child(_leave)
	_panel.hide()

	_flash = ColorRect.new()
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash)
	_flash.hide()
