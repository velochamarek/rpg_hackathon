extends Node
## Globální stav hry Moonless. Autoload s názvem "GameState".
## Všechna čísla a texty odpovídají dokumentu moonless.docx.
##
## Glitch 100 hru sám neukončí: odemkne na mapě šipku ke katedrále
## (GameState.is_cathedral_open()). Smrt při komfortu 0 přijde sama.
##
## Použití z jiných scén:
##   GameState.get_npc("beta")      -> data NPC (jméno, úvodní věta, replika hráče)
##   GameState.can_talk("beta")     -> splňuje hráč podmínku reputace?
##   GameState.interact("beta")     -> provede akci, vrátí {success, text, narrator}

signal stats_changed                       # změnil se kterýkoli stat
signal glitch_gained(amount: int)          # glitch stoupl (pro modré probliknutí)
signal interaction_done(npc_id: String, result: Dictionary)

# --- Parametry (kapitola 3 a 9) ---
const MIN_STAT := 0
const MAX_STAT := 100

const START_COMFORT := 70
const START_GLITCH := 0
const START_REPUTATION := 50

const INTERACTION_COST := 2        # každá interakce, i neúspěšná
const DECAY_SECONDS := 30.0        # při testování klidně 2.0; pokud je hra moc těžká, 45.0
const DECAY_AMOUNT := 1
const ENDING_DELAY := 2.5          # kolik sekund má hráč na přečtení odpovědi, než přijde konec

# --- Cesty ke scénám (upravte podle toho, jak se u vás scény jmenují) ---
const ENDING_SCENES := {
	"death": "res://endings/death.tscn",     # komfort 0
	"escape": "res://endings/escape.tscn",   # červený lektvar
	"forget": "res://endings/forget.tscn",   # modrý lektvar
}

# --- NPC (kapitola 4, 5 a 2) ---
# success a narrator jsou seznamy podle počtu úspěšných návštěv.
# Po poslední položce se opakuje poslední.
const NPCS := {
	"beta": {
		"name": "Běta",
		"rep_min": 60,
		"rep_max": 100,
		"effects": {"comfort": 30, "glitch": -5},
		"greeting": "Dobrý den, poutníku. Vypadáš unaveně.",
		"player_line": "Nemáte prosím něco k jídlu?",
		"success": [
			"Na, vezmi si polévku a kus chleba. Proč bys chodil někam jinam? Tady je ti přece dobře.",
		],
		"fail": "Neznám tě dost dobře. Nejdřív ukaž, že jsi poctivý člověk. Třeba Hana u moře by pomoc potřebovala.",
		"narrator": [
			"Polévka tě zahřeje. Na chvíli si nemůžeš vzpomenout, co tě vlastně trápilo.",
			"Běta tě vítá stejnými slovy jako minule. Slovo od slova.",
			"Stejná polévka, stejný chléb, stejná kůrka. Jestli tu zůstaneš, bude to tak navždy.",
		],
	},
	"hana": {
		"name": "Hana",
		"rep_min": 0,
		"rep_max": 100,
		"effects": {"reputation": 20, "comfort": -10},
		"greeting": "Ty sítě se samy nespraví. Nepomůžeš?",
		"player_line": "Pomůžu.",
		"success": [
			"Díky, máš šikovné ruce. Řeknu ve vsi, že jsi poctivý člověk. A na toho barda nedej, plete lidem hlavy.",
		],
		"fail": "",
		"narrator": [
			"Zeptáš se Hany, jak se jmenuje vesnice. Zamyslí se… a pak se rychle vrátí k sítím.",
			"Spravuješ díru v síti. Tu samou, kterou jsi spravoval minule.",
			"Vlny narážejí na břeh pořád ve stejném rytmu. Raz, dva, tři. Raz, dva, tři.",
		],
	},
	"vitek": {
		"name": "Vítek",
		"rep_min": 20,
		"rep_max": 100,
		"effects": {"glitch": 10, "reputation": -15},
		"greeting": "Znám jednu píseň, kterou ve vsi zpívat nesmím. Chceš ji slyšet?",
		"player_line": "Zazpívej mi ji.",
		"success": [
			"…za lesem není nic, jen bílá mlha a ticho…",
			"…každé ráno stejné ráno, každý chléb stejný chléb…",
			"…ptáci létají v kruzích, protože jinam nesmí…",
			"…a kdo se ptá, proč je to tak, ten brzy zapomene…",
		],
		"fail": "Promiň, kamaráde. Kdyby mě s tebou někdo viděl, už mě nepustí do žádné hospody.",
		"narrator": [
			"Podíváš se k lesu. Za posledními stromy opravdu není nic, jen bílá mlha.",
			"Hospodský celý večer leští pořád stejný korbel.",
			"Nad návsí krouží hejno ptáků. Dokonalý kruh, pořád dokola.",
			"Na chvíli se ti zatmí před očima. Když se vzpamatuješ, nevíš, co jsi chtěl říct.",
		],
	},
	"morwen": {
		"name": "Morwen",
		"rep_min": 0,
		"rep_max": 20,
		"effects": {"glitch": 15, "comfort": -15},
		"greeting": "Kdysi jsem bydlela ve vsi. Pak jsem začala klást otázky. Zase jeden, co se chce probudit? Pravda něco stojí.",
		"player_line": "Zaplatím. Řekni mi pravdu.",
		"success": [
			"Všiml sis, že nikdo ve vsi nemá vzpomínky starší než pár let? Zeptej se jich.",
			"Na nebi není měsíc, protože ho nikdo nenamaloval. Tenhle svět je jen obraz.",
			"Tenhle svět někdo postavil. A ty jsi jediný, kdo začal vidět švy.",
			"Už jsi skoro tam. Ještě kousek a svět se začne trhat.",
		],
		"fail": "Lidé tě ještě mají rádi. S takovým nemluvím. Vrať se, až tě vyženou.",
		"narrator": [
			"Zvedne se vítr a rozbolí tě hlava, jako by tě něco chtělo umlčet.",
			"Podíváš se do studny u chýše. Hladina neodráží nic, ani nebe.",
			"Mezi stromy proletí duch. Na okamžik vypadá jako někdo ze vsi.",
			"Obzor se zachvěje a na okamžik se roztrhne jako plátno.",
		],
	},
}

# --- Stav ---
var comfort := START_COMFORT
var glitch := START_GLITCH
var reputation := START_REPUTATION

var running := false      # běží odčítání komfortu a je vidět HUD
var game_over := false
var ending := ""          # "death", "escape", "forget"
var visits := {}          # počet úspěšných návštěv každého NPC

var _decay_timer := 0.0
var _locked := false      # konec už je rozhodnutý, další interakce nejdou


func _ready() -> void:
	reset()


func _process(delta: float) -> void:
	if not running or game_over:
		return

	# Hlídá smrt pořád, ať komfort klesl jakkoli
	if not _locked and comfort <= MIN_STAT:
		_locked = true
		get_tree().create_timer(ENDING_DELAY).timeout.connect(_check_end)
		return

	_decay_timer += delta
	if _decay_timer >= DECAY_SECONDS:
		_decay_timer = 0.0
		_add("comfort", -DECAY_AMOUNT)
		stats_changed.emit()


## Nová hra: staty na začátek, hodiny zatím stojí (běží úvodní text).
func reset() -> void:
	comfort = START_COMFORT
	glitch = START_GLITCH
	reputation = START_REPUTATION
	running = false
	game_over = false
	ending = ""
	_decay_timer = 0.0
	_locked = false
	visits = {}
	for id in NPCS:
		visits[id] = 0
	stats_changed.emit()


## Spustí odčítání komfortu a zobrazí HUD. Volá se při vstupu na mapu.
func start() -> void:
	if not running and not game_over and not _locked:
		running = true


func get_npc(npc_id: String) -> Dictionary:
	return NPCS.get(npc_id, {})


## Splňuje hráč podmínku reputace pro akci u tohoto NPC?
func can_talk(npc_id: String) -> bool:
	var npc := get_npc(npc_id)
	if npc.is_empty():
		return false
	return reputation >= npc.rep_min and reputation <= npc.rep_max


## Hráč zvolil akci u NPC. Vrací {success, text, narrator}.
## Odejít nic nestojí, tuhle funkci pro to nevolejte.
func interact(npc_id: String) -> Dictionary:
	var npc := get_npc(npc_id)
	if npc.is_empty() or not running or game_over or _locked:
		return {}

	# Každá interakce stojí sílu, i neúspěšná
	_add("comfort", -INTERACTION_COST)

	var result := {"success": false, "text": npc.fail, "narrator": ""}
	if can_talk(npc_id):
		for stat in npc.effects:
			_add(stat, npc.effects[stat])
		visits[npc_id] += 1
		var n: int = visits[npc_id]
		result.success = true
		result.text = _pick(npc.success, n)
		result.narrator = _pick(npc.narrator, n)

	stats_changed.emit()
	interaction_done.emit(npc_id, result)

	# Smrt přijde až po chvíli, aby si hráč stihl přečíst odpověď
	if comfort <= MIN_STAT:
		_locked = true
		get_tree().create_timer(ENDING_DELAY).timeout.connect(_check_end)

	return result


## Je katedrála odemčená? (glitch 100) Mapa podle toho ukáže šipku.
func is_cathedral_open() -> bool:
	return glitch >= MAX_STAT


## Volá scéna katedrály při vstupu: zastaví čas a další interakce.
func enter_cathedral() -> void:
	running = false
	_locked = true


## Ukončí hru a přepne na obrazovku konce ("death", "escape", "forget").
## Lektvary v katedrále volají tuhle funkci.
func end_game(ending_id: String) -> void:
	if game_over:
		return
	game_over = true
	running = false
	ending = ending_id
	print("KONEC HRY: ", ending_id)
	if ENDING_SCENES.has(ending_id):
		get_tree().call_deferred("change_scene_to_file", ENDING_SCENES[ending_id])


# Glitch 100 hru neukončuje, jen odemkne katedrálu na mapě
func _check_end() -> void:
	if game_over:
		return
	if comfort <= MIN_STAT:
		end_game("death")


func _add(stat: String, amount: int) -> void:
	match stat:
		"comfort":
			comfort = clampi(comfort + amount, MIN_STAT, MAX_STAT)
		"reputation":
			reputation = clampi(reputation + amount, MIN_STAT, MAX_STAT)
		"glitch":
			var before := glitch
			glitch = clampi(glitch + amount, MIN_STAT, MAX_STAT)
			if glitch > before:
				glitch_gained.emit(glitch - before)


func _pick(list: Array, visit_number: int) -> String:
	if list.is_empty():
		return ""
	return list[mini(visit_number - 1, list.size() - 1)]


# --- Testovací klávesy (jen při spuštění z editoru) ---
# 1 až 4: interakce s Bětou, Hanou, Vítkem, Morwen (výsledek v Output)
# G: glitch +10   K: komfort −10   R: reputace +10   T: reputace −10
func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build() or not (event is InputEventKey):
		return
	if not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_1: _debug_npc("beta")
		KEY_2: _debug_npc("hana")
		KEY_3: _debug_npc("vitek")
		KEY_4: _debug_npc("morwen")
		KEY_G: _debug_add("glitch", 10)
		KEY_K: _debug_add("comfort", -10)
		KEY_R: _debug_add("reputation", 10)
		KEY_T: _debug_add("reputation", -10)


func _debug_npc(npc_id: String) -> void:
	var r := interact(npc_id)
	if r.is_empty():
		print("[TEST] Interakce nejde, hra neběží (jsi na mapě?)")
		return
	print("[TEST] %s: %s" % [get_npc(npc_id).name, "ÚSPĚCH" if r.success else "NEÚSPĚCH"])
	print("       ", r.text)
	if r.narrator != "":
		print("       Vypravěč: ", r.narrator)


func _debug_add(stat: String, amount: int) -> void:
	if not running or game_over:
		return
	_add(stat, amount)
	stats_changed.emit()
