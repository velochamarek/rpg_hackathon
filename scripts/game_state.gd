extends Node
## Globální stav hry Moonless. Autoload s názvem "GameState".
##
## Verze 2 podle README: tři patra (město, okraj, dno), šest postav
## a inventář (ryby, svíce). Čísla jsou ověřená simulací: k útěku je potřeba
## všech šest postav, ale pořadí si hráč volí sám (17 nejkratších výherních postupů).
##
## Glitch 100 hru sám neukončí: odemkne na mapě tlačítko ke katedrále
## (GameState.is_cathedral_open()). Smrt při komfortu 0 přijde sama.
##
## Použití z jiných scén:
##   GameState.get_npc("beta")      -> data NPC (jméno, úvodní věta, replika hráče)
##   GameState.can_talk("beta")     -> splňuje hráč teď všechny podmínky?
##   GameState.interact("beta")     -> provede akci, vrátí {success, text, narrator, loot}

signal stats_changed                       # změnil se kterýkoli stat nebo inventář
signal glitch_gained(amount: int)          # glitch stoupl (pro modré probliknutí)
signal interaction_done(npc_id: String, result: Dictionary)

# --- Parametry ---
const MIN_STAT := 0
const MAX_STAT := 100

const START_COMFORT := 80
const START_GLITCH := 0
const START_REPUTATION := 50

const INTERACTION_COST := 2        # každá interakce, i neúspěšná (kromě "už nic nemám")
const DECAY_SECONDS := 30.0        # při testování klidně 2.0; pokud je hra moc těžká, 45.0
const DECAY_AMOUNT := 1
const ENDING_DELAY := 2.5          # kolik sekund má hráč na přečtení odpovědi, než přijde konec

# --- Předměty ---
const ITEM_NAMES := {
	"ryba": "Ryba",
	"svice": "Svíce",
}
const KEY_ITEMS := ["svice"]       # klíčové předměty se v batohu ukazují bez počtu

# --- Cesty ke scénám ---
const ENDING_SCENES := {
	"death": "res://endings/death.tscn",     # komfort 0
	"escape": "res://endings/escape.tscn",   # červený lektvar
	"forget": "res://endings/forget.tscn",   # modrý lektvar
}

# --- NPC: tři patra podle README ---
#   MĚSTO  (vesnice)  Běta, Anselm    – chtějí vysokou reputaci, dávají jídlo a světlo
#   OKRAJ  (pobřeží)  Hana, Vítek     – dostupní vždy, ryby a písně
#   DNO    (les)      Ezechiel, Morwen – chtějí nízkou reputaci, dávají glitch, berou reputaci
#
# rep_min/rep_max  podmínka reputace
# takes            předměty, které akce spotřebuje (a hráč je musí mít)
# needs            předměty, které hráč musí mít, ale nespotřebují se
# gives            předměty, které hráč dostane
# effects          změna statů
# max_visits       kolik úspěšných návštěv má smysl (pak "exhausted" a nic se neděje)
# fail_rep         odmítnutí kvůli reputaci (fail_rep_high / fail_rep_low, pokud se liší směr)
# fail_item        odmítnutí kvůli chybějícímu předmětu
# success / narrator  seznamy podle počtu úspěšných návštěv
const NPCS := {
	# ======================= MĚSTO =======================
	"beta": {
		"name": "Běta",
		"rep_min": 50, "rep_max": 100,
		"takes": {"ryba": 1}, "needs": {}, "gives": {},
		"effects": {"comfort": 35, "glitch": -5},
		"max_visits": 99,
		"greeting": "Dobrý den, poutníku. Vypadáš unaveně.",
		"player_line": "Mám rybu. Uvaříte mi z ní polévku?",
		"success": [
			"Na, vezmi si polévku a kus chleba. Proč bys chodil někam jinam? Tady je ti přece dobře.",
		],
		"fail_rep": "Slyšela jsem, s kým se taháš. Pro takové tu nic nemám. Ať ti Hana u moře nejdřív spraví pověst.",
		"fail_item": "Polévka něco stojí, poutníku. Přines rybu. Hana u moře ti nějakou dá za práci.",
		"exhausted": "",
		"narrator": [
			"Polévka tě zahřeje. Na chvíli si nemůžeš vzpomenout, co tě vlastně trápilo.",
			"Běta tě vítá stejnými slovy jako minule. Slovo od slova.",
			"Stejná polévka, stejný chléb, stejná kůrka. Jestli tu zůstaneš, bude to tak navždy.",
		],
	},
	"anselm": {
		"name": "Anselm",
		"rep_min": 60, "rep_max": 100,
		"takes": {"ryba": 1}, "needs": {}, "gives": {"svice": 1},
		"effects": {},
		"max_visits": 1,
		"greeting": "Pokoj s tebou, synu. Kaple je otevřená všem poctivým.",
		"player_line": "Potřebuju svíci z kaple. Daruju kostelu rybu.",
		"success": [
			"Ať ti svítí na cestu. Domů, doufám. Ne do lesa.",
		],
		"fail_rep": "Kaple je pro poctivé. Nejdřív ať o tobě ves mluví dobře.",
		"fail_item": "Bůh nic nežádá. Kostel ano. Přines dar.",
		"exhausted": "Svíci už máš. Opatruj plamen, víc jich nemám.",
		"narrator": [
			"Svíce hoří, ale vosk neubývá. Ani po hodině.",
		],
	},
	# ======================= OKRAJ =======================
	"hana": {
		"name": "Hana",
		"rep_min": 0, "rep_max": 100,
		"takes": {}, "needs": {}, "gives": {"ryba": 1},
		"effects": {"reputation": 10, "comfort": -5},
		"max_visits": 99,
		"greeting": "Ty sítě se samy nespraví. Nepomůžeš?",
		"player_line": "Pomůžu.",
		"success": [
			"Díky, máš šikovné ruce. Tady máš rybu. Řeknu ve vsi, že jsi poctivý člověk.",
			"Zase ty? Výborně. Ryba je tvoje. A na toho barda nedej, plete lidem hlavy.",
		],
		"fail_rep": "", "fail_item": "", "exhausted": "",
		"narrator": [
			"Zeptáš se Hany, jak se jmenuje vesnice. Zamyslí se… a pak se rychle vrátí k sítím.",
			"Spravuješ díru v síti. Tu samou, kterou jsi spravoval minule.",
			"Vlny narážejí na břeh pořád ve stejném rytmu. Raz, dva, tři. Raz, dva, tři.",
		],
	},
	"vitek": {
		"name": "Vítek",
		"rep_min": 0, "rep_max": 100,
		"takes": {"ryba": 1}, "needs": {}, "gives": {},
		"effects": {"glitch": 10, "reputation": -10},
		"max_visits": 3,
		"greeting": "Znám jednu píseň, kterou ve vsi zpívat nesmím. Chceš ji slyšet? Zadarmo ale nezpívám.",
		"player_line": "Tady máš rybu. Zazpívej.",
		"success": [
			"…a obloha je jen plátno a slunce je lampa na šňůře…",
			"…za lesem není nic, jen bílá mlha a ticho…",
			"…ptáci létají v kruzích, protože jinam nesmí…",
		],
		"fail_rep": "",
		"fail_item": "Hladový bard nezpívá. Přines rybu.",
		"exhausted": "Víc slok neznám. Prorok Ezechiel v lese o tom káže, já o tom jen zpívám.",
		"narrator": [
			"Na chvíli se ti rozmaže svět.",
			"Lidé z pobřeží si šuškají, že posloucháš zakázané písně.",
			"Nad mořem krouží hejno ptáků. Dokonalý kruh, pořád dokola.",
		],
	},
	# ======================= DNO =======================
	"ezechiel": {
		"name": "Ezechiel",
		"rep_min": 20, "rep_max": 70,
		"takes": {}, "needs": {}, "gives": {},
		"effects": {"glitch": 10, "reputation": -15},
		"max_visits": 3,
		"greeting": "Ty! Ty je taky slyšíš? To bzučení za oblohou!",
		"player_line": "Poslouchám. Mluv.",
		"success": [
			"Svět je namalovaný. Na okraji lesa bydlí ta, která ví víc. Ale nejdřív tě lidi musí přestat mít rádi.",
			"Každé ráno je to samé ráno! Počítal jsem je. Tisíc a jedno, tisíc a jedno!",
			"Dvě lahve v katedrále. Jedna tě probudí, druhá ukolébá. Nepleť si je!",
		],
		"fail_rep": "Smrdíš městem. Jdi pryč.",
		"fail_rep_high": "Smrdíš městem. Jdi pryč.",
		"fail_rep_low": "Ty už jsi moc daleko. Nemám ti co říct. Jdi za ní.",
		"fail_item": "",
		"exhausted": "Řekl jsem všechno, co bzučí. Zbytek ví jen ona. Čarodějnice.",
		"narrator": [
			"Když Ezechiel zmlkne, opravdu to slyšíš. Tiché bzučení za oblohou.",
			"Ves za tebou ztichne. Někdo tě viděl s bláznem.",
			"Mezi stromy proletí duch. Na okamžik vypadá jako někdo ze vsi.",
		],
	},
	"morwen": {
		"name": "Morwen",
		"rep_min": 0, "rep_max": 30,
		"takes": {}, "needs": {"svice": 1}, "gives": {},
		"effects": {"glitch": 15, "comfort": -12, "reputation": -10},
		"max_visits": 4,
		"greeting": "Zase jeden, co se chce probudit. Pravda něco stojí.",
		"player_line": "Zaplatím. Řekni mi pravdu.",
		"success": [
			"Všiml sis, že nikdo ve vsi nemá vzpomínky starší než pár let? Zeptej se jich.",
			"Měsíc se neodráží ve studni, protože žádný měsíc není. Schovali ho, protože ukazuje cestu ven.",
			"Dávej si pozor na tu, co tě krmí. Kdo tě sytí, ten tě drží.",
			"Tenhle svět někdo postavil. A ty jsi jediný, kdo začal vidět švy. Až se začne trhat, jdi do katedrály.",
		],
		"fail_rep": "Lidé tě ještě mají rádi. S takovým nemluvím. Vrať se, až tě vyženou.",
		"fail_item": "Ve tmě mě nenajdeš. Přijď se světlem. Kněz ve vsi má svíce, ale dává je jen poctivým.",
		"exhausted": "Víc ti neřeknu. Bard u moře zná písně, které jsem ho kdysi naučila.",
		"narrator": [
			"Za pravdu platíš krví. Ve vsi si všimnou jizev.",
			"Podíváš se na nebe. Tam, kde by měl být měsíc, je jen hladká tma.",
			"Z vesnice zaslechneš Bětin smích. Zní přesně stejně jako včera.",
			"Obzor se zachvěje a na okamžik se roztrhne jako plátno.",
		],
	},
}

# --- Stav ---
var comfort := START_COMFORT
var glitch := START_GLITCH
var reputation := START_REPUTATION
var items := {}           # inventář: {"ryba": 2, "svice": 1}

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
	items = {}
	for id in ITEM_NAMES:
		items[id] = 0
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
## Pokud předchozí hra skončila, začne automaticky novou (staty na začátek).
func start() -> void:
	if game_over:
		reset()
	if not running and not _locked:
		running = true


func get_npc(npc_id: String) -> Dictionary:
	return NPCS.get(npc_id, {})


func item_count(item_id: String) -> int:
	return items.get(item_id, 0)


## Text inventáře pro HUD, např. "Ryba ×2 · Svíce". Prázdný inventář = "".
func inventory_text() -> String:
	var parts := PackedStringArray()
	for id in ITEM_NAMES:
		var n := item_count(id)
		if n <= 0:
			continue
		parts.append(ITEM_NAMES[id] if id in KEY_ITEMS else "%s ×%d" % [ITEM_NAMES[id], n])
	return " · ".join(parts)


## Splňuje hráč teď všechny podmínky pro úspěšnou akci u tohoto NPC?
func can_talk(npc_id: String) -> bool:
	return _fail_reason(npc_id) == ""


## Hráč zvolil akci u NPC. Vrací {success, text, narrator, loot}.
## Odejít nic nestojí, tuhle funkci pro to nevolejte.
func interact(npc_id: String) -> Dictionary:
	var npc := get_npc(npc_id)
	if npc.is_empty() or not running or game_over or _locked:
		return {}

	var reason := _fail_reason(npc_id)
	var result := {"success": false, "text": "", "narrator": "", "loot": ""}

	if reason == "exhausted":
		# Postava už nemá co nabídnout: jen odpoví, nic to nestojí
		result.text = npc.exhausted
		interaction_done.emit(npc_id, result)
		return result

	# Každá jiná interakce stojí sílu, i neúspěšná
	_add("comfort", -INTERACTION_COST)

	if reason != "":
		result.text = npc.get(reason, "")
	else:
		var loot := PackedStringArray()
		for id in npc.takes:
			items[id] = item_count(id) - npc.takes[id]
			loot.append("−%d %s" % [npc.takes[id], ITEM_NAMES[id].to_lower()])
		for id in npc.gives:
			items[id] = item_count(id) + npc.gives[id]
			loot.append("+%d %s" % [npc.gives[id], ITEM_NAMES[id].to_lower()])
		for stat in npc.effects:
			_add(stat, npc.effects[stat])
		visits[npc_id] += 1
		var n: int = visits[npc_id]
		result.success = true
		result.text = _pick(npc.success, n)
		result.narrator = _pick(npc.narrator, n)
		result.loot = ", ".join(loot)

	stats_changed.emit()
	interaction_done.emit(npc_id, result)

	# Smrt přijde až po chvíli, aby si hráč stihl přečíst odpověď
	if comfort <= MIN_STAT:
		_locked = true
		get_tree().create_timer(ENDING_DELAY).timeout.connect(_check_end)

	return result


## Je katedrála odemčená? (glitch 100) Mapa podle toho ukáže tlačítko.
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


# "" = může uspět, jinak název klíče s odpovědí:
# "exhausted", "fail_rep" (nebo "fail_rep_high" / "fail_rep_low"), "fail_item"
func _fail_reason(npc_id: String) -> String:
	var npc := get_npc(npc_id)
	if npc.is_empty():
		return "fail_rep"
	if visits.get(npc_id, 0) >= npc.max_visits:
		return "exhausted"
	if reputation > npc.rep_max:
		return "fail_rep_high" if npc.has("fail_rep_high") else "fail_rep"
	if reputation < npc.rep_min:
		return "fail_rep_low" if npc.has("fail_rep_low") else "fail_rep"
	for id in npc.takes:
		if item_count(id) < npc.takes[id]:
			return "fail_item"
	for id in npc.needs:
		if item_count(id) < npc.needs[id]:
			return "fail_item"
	return ""


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


func _debug_npc(npc_id: String) -> void:
	var r := interact(npc_id)
	if r.is_empty():
		print("[TEST] Interakce nejde, hra neběží (jsi na mapě?)")
		return
	print("[TEST] %s: %s %s" % [get_npc(npc_id).name, "ÚSPĚCH" if r.success else "NEÚSPĚCH", r.loot])
	print("       ", r.text)
	if r.narrator != "":
		print("       Vypravěč: ", r.narrator)
	print("       komfort %d, glitch %d, reputace %d, %s" % [comfort, glitch, reputation, inventory_text()])


func _debug_add(stat: String, amount: int) -> void:
	if not running or game_over:
		return
	_add(stat, amount)
	stats_changed.emit()
