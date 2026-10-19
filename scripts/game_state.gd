extends Node
## Globální stav hry Moonless (verze 3). Autoload s názvem "GameState".
## Tady je VŠECHNA herní mechanika: staty, batoh, postavy, texty, časový úbytek a konce.
## Ostatní skripty (Dialog, HUD, mapa, katedrála) jen zobrazují a volají funkce níže.
## Všechna čísla a texty odpovídají dokumentu Moonless_pribeh_a_scenare.docx.
##
## Šest postav na reputačním žebříku:
##   město (ves):     beta, anselm
##   okraj (pobřeží): hana, vitek
##   dno (les):       ezechiel, morwen   (jen se svící)
##
## Svíce je světlo do lesa. Vydrží 3 rozhovory v lese, pak dohoří a pro novou
## si hráč musí dojít nahoru k Anselmovi. Tím se hráč musí několikrát vrátit
## do města a hlídat si rovnováhu komfortu, ryb a reputace.
##
## Glitch 100 hru sám neukončí: odemkne na mapě cestu do katedrály
## (GameState.is_cathedral_open()). Smrt při komfortu 0 přijde sama.
##
## Použití z jiných scén:
##   GameState.get_npc("beta")      -> data postavy
##   GameState.can_talk("beta")     -> splňuje hráč podmínku reputace?
##   GameState.interact("beta")     -> provede akci, vrátí
##        {success, exhausted, text, narrator, items}
##   GameState.items                -> batoh, např. {"ryba": 2, "svice": 3}
##   GameState.items_text()         -> "Ryba ×2 · Svíce (ještě 3×)" (pro HUD)

signal stats_changed                       # změnil se kterýkoli stat nebo batoh
signal glitch_gained(amount: int)          # glitch stoupl (pro modré probliknutí)
signal interaction_done(npc_id: String, result: Dictionary)

# --- Parametry ---
const MIN_STAT := 0
const MAX_STAT := 100

const START_COMFORT := 80
const START_GLITCH := 0
const START_REPUTATION := 50

const INTERACTION_COST := 2        # každá interakce, i neúspěšná (ne když postava jen odmítne kvůli vyčerpání)
const DECAY_SECONDS := 30.0        # při testování klidně 2.0; pokud je hra moc těžká, 45.0
const DECAY_AMOUNT := 1
const ENDING_DELAY := 2.5          # kolik sekund má hráč na přečtení odpovědi, než přijde konec
const CANDLE_USES := 3             # na kolik rozhovorů v lese vydrží jedna svíce
const DEBUG_KEYS := false          # testovací klávesy (viz konec souboru); pro testování přepněte na true

# --- Cesty ke scénám (upravte podle toho, jak se u vás scény jmenují) ---
const ENDING_SCENES := {
	"death": "res://endings/death.tscn",     # komfort 0
	"escape": "res://endings/escape.tscn",   # červený lektvar
	"forget": "res://endings/forget.tscn",   # modrý lektvar
}

# --- Postavy ---
# rep_min/rep_max: podmínka reputace
# takes: co hráč zaplatí (ryba se odebere, svíce se o jeden rozhovor upálí)
# gives: co dostane (svíce = nová svíce na CANDLE_USES rozhovorů)
# effects: změny statů, max: kolikrát jde uspět (0 = bez limitu)
# blocked_if_has: když už hráč tenhle předmět má, postava jen odpoví textem "exhausted" a nic to nestojí
# success a narrator jsou seznamy podle počtu úspěšných návštěv, po poslední položce se opakuje poslední.
# Odmítnutí: fail_rep_high (reputace moc vysoká), fail_rep_low (moc nízká),
# fail_item (chybí ryba nebo svíce), exhausted (už nemá co nabídnout, nic to nestojí).
const NPCS := {
	# ---------------------------------------------------------------- MĚSTO
	"beta": {
		"name": "Běta",
		"rep_min": 50, "rep_max": 100,
		"takes": {"ryba": 1}, "gives": {},
		"effects": {"comfort": 35, "glitch": -5},
		"max": 0, "blocked_if_has": "",
		"greeting": "Dobrý den, poutníku. Vypadáš unaveně a hladově.",
		"player_line": "Mám rybu. Uvaříte mi z ní polévku?",
		"success": [
			"Tady máš polévku a kus chleba. Zůstaň tady s námi. Proč bys chodil někam jinam? Tady je ti přece dobře.",
		],
		"narrator": [
			"Polévka tě zahřeje. A najednou si nemůžeš vzpomenout, na co jsi před chvílí myslel.",
			"Běta tě vítá úplně stejnými slovy jako minule. Slovo od slova, se stejným úsměvem.",
			"Stejná polévka, stejný chléb, stejná prasklina v misce. Tady se nic nemění. Nikdy.",
		],
		"fail_rep_low": "Slyšela jsem, s kým se taháš. Pro takové tu nic nemám. Běž pomoct Haně na pobřeží, ať o tobě lidi zase mluví dobře.",
		"fail_rep_high": "",
		"fail_item": "Polévka stojí jednu rybu. Ryby dostaneš od Hany na pobřeží, když jí pomůžeš se sítěmi.",
		"exhausted": "",
	},
	"anselm": {
		"name": "Anselm",
		"rep_min": 60, "rep_max": 100,
		"takes": {"ryba": 1}, "gives": {"svice": 1},
		"effects": {},
		"max": 0, "blocked_if_has": "svice",
		"greeting": "Pokoj s tebou. Do kaple můžou jen poctiví lidé.",
		"player_line": "Potřebuju svíci. Daruju kostelu rybu.",
		"success": [
			"Tady máš svíci. Vydrží ti na tři rozhovory v lese, pak dohoří. A jestli opravdu jdeš do tmy, nejdřív se najez. Z lesa se zpátky leze těžko.",
			"Další svíce? Dobře. Zase vydrží na tři rozhovory. Opatruj se tam dole.",
		],
		"narrator": [
			"Za oltářem stojí řada úplně stejných svící. Jako by je někdo vyrobil podle jedné předlohy.",
			"Anselm ti podává svíci a usmívá se. Úplně stejně jako minule.",
		],
		"fail_rep_low": "Svíce dávám jen poctivým lidem. Pomoz Haně na pobřeží, ať o tobě ves mluví dobře.",
		"fail_rep_high": "",
		"fail_item": "Svíce není zadarmo. Kostel chce dar: jednu rybu.",
		"exhausted": "Svíci ještě máš. Až dohoří, přijď si pro novou.",
	},
	# ---------------------------------------------------------------- OKRAJ
	"hana": {
		"name": "Hana",
		"rep_min": 0, "rep_max": 100,
		"takes": {}, "gives": {"ryba": 1},
		"effects": {"reputation": 10, "comfort": -5},
		"max": 0, "blocked_if_has": "",
		"greeting": "Ty sítě se samy nespraví. Pomůžeš mi?",
		"player_line": "Jasně, pomůžu.",
		"success": [
			"Díky! Tady máš rybu. Ve vsi řeknu, že jsi poctivý člověk.",
			"Zase ty? Výborně. Ryba je tvoje. A dej si pozor na toho barda, Vítka. Plete lidem hlavy.",
		],
		"narrator": [
			"Zeptáš se Hany, jak se jmenuje vesnice. Na chvíli se zarazí… a pak se rychle vrátí k sítím, jako by ses nic neptal.",
			"Spravuješ díru v síti. Tu úplně samou, kterou jsi spravoval minule.",
			"Vlny narážejí na břeh pořád ve stejném rytmu. Raz, dva, tři. Raz, dva, tři. Jako by se opakovala nahrávka.",
		],
		"fail_rep_low": "",
		"fail_rep_high": "",
		"fail_item": "",
		"exhausted": "",
	},
	"vitek": {
		"name": "Vítek",
		"rep_min": 0, "rep_max": 100,
		"takes": {"ryba": 1}, "gives": {},
		"effects": {"glitch": 10, "reputation": -10},
		"max": 3, "blocked_if_has": "",
		"greeting": "Znám písně, které se ve vsi zpívat nesmí. Chceš jednu slyšet? Zadarmo ale nezpívám, chci rybu.",
		"player_line": "Tady máš rybu. Zazpívej.",
		"success": [
			"♪ Obloha je plátno a slunce je lampa… ♪ Víš, o čem to je? Že obloha nad námi není skutečná. Někdo ji namaloval.",
			"♪ Za lesem není nic, jen bílá mlha… ♪ Zkus se někdy podívat za poslední stromy. Svět tam prostě končí.",
			"♪ Ptáci létají v kruzích… ♪ Všiml sis, že ptáci nad mořem létají pořád stejně dokola? Nemůžou jinam.",
		],
		"narrator": [
			"Na vteřinu se celý svět rozmaže, jako když se zasekne obraz. Pak je zase všechno normálně.",
			"Lidé na pobřeží si šeptají, že posloucháš zakázané písně. Tvoje pověst klesá.",
			"Podíváš se na moře. Hejno ptáků krouží pořád ve stejném kruhu.",
		],
		"fail_rep_low": "",
		"fail_rep_high": "",
		"fail_item": "Hladový bard nezpívá. Přines rybu, Hana ti nějakou dá.",
		"exhausted": "Víc písní neznám. Jestli chceš vědět víc, jdi do lesa za prorokem Ezechielem. Ale bez světla tam nic neuvidíš.",
	},
	# ---------------------------------------------------------------- DNO (jen se svící)
	"ezechiel": {
		"name": "Ezechiel",
		"rep_min": 20, "rep_max": 100,
		"takes": {"svice": 1}, "gives": {},
		"effects": {"glitch": 10, "reputation": -15},
		"max": 0, "blocked_if_has": "",
		"greeting": "Ty! Ty to taky slyšíš? To bzučení nad oblohou!",
		"player_line": "Poslouchám. Mluv.",
		"success": [
			"Tenhle svět není skutečný. Je namalovaný, jako kulisa v divadle. Hlouběji v lese žije čarodějnice Morwen, ta ví víc. Ale s oblíbenými lidmi nemluví.",
			"Každý den je tady úplně stejný! Stejné ráno, stejní lidé, stejná slova. Počítám je. Tohle je tisící první.",
			"V katedrále stojí dvě lahve. Jedna tě probudí, druhá tě uspí navždy. Nepleť si je!",
			"Už jsem ti řekl všechno, co vím. Zbytek ví jen Morwen. Ale poslouchej, to bzučení sílí!",
		],
		"narrator": [
			"Když Ezechiel zmlkne, opravdu to uslyšíš. Tiché bzučení někde nad oblohou, jako by tam běžel stroj.",
			"Ves je odsud vidět. Lidé se na tebe dívají. Někdo tě viděl s bláznem.",
			"Mezi stromy proletí průsvitný duch. Na okamžik má tvář někoho ze vsi.",
			"Bzučení nad oblohou je čím dál hlasitější.",
		],
		"fail_rep_low": "Ty už jsi na dně. Nemám ti co říct. Jdi za Morwen, je hlouběji v lese.",
		"fail_rep_high": "",
		"fail_item": "Je tu tma, nevidím ti do tváře. Přines světlo. Kněz Anselm ve vsi má svíce.",
		"exhausted": "",
	},
	"morwen": {
		"name": "Morwen",
		"rep_min": 0, "rep_max": 30,
		"takes": {"svice": 1}, "gives": {},
		"effects": {"glitch": 20, "comfort": -12, "reputation": -10},
		"max": 0, "blocked_if_has": "",
		"greeting": "Kdysi jsem bydlela ve vsi. Pak jsem se začala ptát a musela jsem odejít. Chceš znát pravdu? Bude tě to stát.",
		"player_line": "Zaplatím. Řekni mi pravdu.",
		"success": [
			"Zeptej se kohokoli ve vsi na jeho dětství. Nikdo si nic nepamatuje. Všichni tu jsou teprve pár let.",
			"Na nebi není měsíc. Ne proto, že by ho zapomněli. Schovali ho, protože ukazuje cestu ven.",
			"Ti duchové v lese jsou lidé ze vsi, kteří se ptali moc nahlas. Někdo je vymazal.",
			"Dávej si pozor na tu, co tě krmí. Každá polévka tě nechá trochu zapomenout. Kdo tě sytí, ten tě drží.",
			"Tenhle svět někdo postavil. A ty jsi první, kdo začal vidět, kde jsou švy.",
			"Až se svět začne trhat, jdi do katedrály. Je to jediné místo, které nikdo nedokončil. Tam je cesta ven.",
		],
		"narrator": [
			"Za pravdu platíš: rozbolí tě hlava, jako by tě něco chtělo umlčet. A ve vsi si všimnou, že chodíš do lesa.",
			"Podíváš se na nebe. Tam, kde by měl být měsíc, je jen hladká černá tma.",
			"Kolem chýše se mihne duch. Na okamžik vypadá úplně jako někdo ze vsi.",
			"Z vesnice zaslechneš Bětin smích. Zní přesně stejně jako včera.",
			"Obzor se zachvěje a na okamžik se roztrhne jako plátno. Za ním je jen bílo.",
			"Nad stromy vidíš věž katedrály. Poprvé si všimneš, že nevrhá žádný stín.",
		],
		"fail_rep_low": "",
		"fail_rep_high": "Lidé ve vsi tě ještě mají rádi. S takovými nemluvím. Vrať se, až tě vyženou.",
		"fail_item": "Bez světla mě tu nenajdeš. Přines svíci od kněze Anselma.",
		"exhausted": "",
	},
}

# --- Stav ---
var comfort := START_COMFORT
var glitch := START_GLITCH
var reputation := START_REPUTATION
var items := {}           # batoh: "ryba" = počet ryb, "svice" = kolik rozhovorů v lese svíce ještě vydrží
# Stejný batoh pod jménem z kolegovy verze (používá ho HUD)
var inventory: Dictionary:
	get:
		return items

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
		_lock_and_end()
		return

	_decay_timer += delta
	if _decay_timer >= DECAY_SECONDS:
		_decay_timer = 0.0
		_add("comfort", -DECAY_AMOUNT)
		stats_changed.emit()


## Nová hra: staty na začátek, prázdný batoh, hodiny zatím stojí (běží úvodní text).
func reset() -> void:
	comfort = START_COMFORT
	glitch = START_GLITCH
	reputation = START_REPUTATION
	items = {}
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


## Splňuje hráč podmínku reputace pro akci u tohoto NPC?
func can_talk(npc_id: String) -> bool:
	var npc := get_npc(npc_id)
	if npc.is_empty():
		return false
	return reputation >= npc.rep_min and reputation <= npc.rep_max


## Nemá postava co nabídnout? (vyčerpaný limit, nebo hráč už má, co postava dává)
func is_exhausted(npc_id: String) -> bool:
	var npc := get_npc(npc_id)
	if npc.is_empty():
		return false
	if int(npc.max) > 0 and visits.get(npc_id, 0) >= int(npc.max):
		return true
	return npc.blocked_if_has != "" and has_item(npc.blocked_if_has)


func has_item(item_id: String, amount: int = 1) -> bool:
	return int(items.get(item_id, 0)) >= amount


## Batoh jako text pro HUD, např. "Ryba ×2 · Svíce (ještě 3×)". Prázdný batoh = "prázdný".
func items_text() -> String:
	var parts: Array[String] = []
	var fish := int(items.get("ryba", 0))
	if fish == 1:
		parts.append("Ryba")
	elif fish > 1:
		parts.append("Ryba ×%d" % fish)
	var candle := int(items.get("svice", 0))
	if candle > 0:
		parts.append("Svíce (ještě %d×)" % candle)
	return "prázdný" if parts.is_empty() else " · ".join(parts)


## Stejné jako items_text(), pod jménem z kolegovy verze (používá ho HUD).
func inventory_text() -> String:
	return items_text()


## Hráč zvolil akci u NPC. Vrací {success, exhausted, text, narrator, items}.
## items je řádek se změnami v batohu, např. "+1 ryba" nebo "−1 ryba · nová svíce".
## Odejít nic nestojí, tuhle funkci pro to nevolejte.
func interact(npc_id: String) -> Dictionary:
	var npc := get_npc(npc_id)
	if npc.is_empty() or not running or game_over or _locked:
		return {}

	# Postava nemá co nabídnout: jen to řekne, nic to nestojí
	if is_exhausted(npc_id):
		var r := {"success": false, "exhausted": true, "text": npc.exhausted, "narrator": "", "items": ""}
		interaction_done.emit(npc_id, r)
		return r

	# Každá jiná interakce stojí sílu, i neúspěšná
	_add("comfort", -INTERACTION_COST)

	var result := {"success": false, "exhausted": false, "text": "", "narrator": "", "items": ""}
	if not can_talk(npc_id):
		result.text = npc.fail_rep_high if reputation > npc.rep_max else npc.fail_rep_low
	elif not _has_all(npc.takes):
		result.text = npc.fail_item
	else:
		var changes: Array[String] = []
		for id in npc.takes:
			items[id] = int(items.get(id, 0)) - int(npc.takes[id])
			if id == "svice":
				changes.append("svíce dohořela" if items[id] <= 0 else "svíce vydrží ještě %d×" % items[id])
			else:
				changes.append("−%d ryba" % npc.takes[id])
			if items[id] <= 0:
				items.erase(id)
		for id in npc.gives:
			if id == "svice":
				items[id] = CANDLE_USES
				changes.append("nová svíce (vydrží %d×)" % CANDLE_USES)
			else:
				items[id] = int(items.get(id, 0)) + int(npc.gives[id])
				changes.append("+%d ryba" % npc.gives[id])
		for stat in npc.effects:
			_add(stat, npc.effects[stat])
		visits[npc_id] += 1
		var n: int = visits[npc_id]
		result.success = true
		result.text = _pick(npc.success, n)
		result.narrator = _pick(npc.narrator, n)
		result.items = " · ".join(changes)

	stats_changed.emit()
	interaction_done.emit(npc_id, result)

	# Smrt přijde až po chvíli, aby si hráč stihl přečíst odpověď
	if comfort <= MIN_STAT:
		_lock_and_end()

	return result


## Je katedrála odemčená? (glitch 100) Mapa podle toho ukáže cestu.
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


func _lock_and_end() -> void:
	if _locked:
		return
	_locked = true
	get_tree().create_timer(ENDING_DELAY).timeout.connect(_check_end)


func _check_end() -> void:
	if game_over:
		return
	if comfort <= MIN_STAT:
		end_game("death")


func _has_all(needed: Dictionary) -> bool:
	for id in needed:
		if not has_item(id, int(needed[id])):
			return false
	return true


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


# --- Testovací klávesy (jen když je DEBUG_KEYS = true a hra běží z editoru) ---
# 1 až 6: interakce s Bětou, Anselmem, Hanou, Vítkem, Ezechielem, Morwen (výsledek v Output)
# G: glitch +10   K: komfort −10   R: reputace +10   T: reputace −10   F: +1 ryba   C: nová svíce
func _unhandled_input(event: InputEvent) -> void:
	if not DEBUG_KEYS or not OS.is_debug_build() or not (event is InputEventKey):
		return
	if not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_1: _debug_npc("beta")
		KEY_2: _debug_npc("anselm")
		KEY_3: _debug_npc("hana")
		KEY_4: _debug_npc("vitek")
		KEY_5: _debug_npc("ezechiel")
		KEY_6: _debug_npc("morwen")
		KEY_G: _debug_add("glitch", 10)
		KEY_K: _debug_add("comfort", -10)
		KEY_R: _debug_add("reputation", 10)
		KEY_T: _debug_add("reputation", -10)
		KEY_F:
			items["ryba"] = int(items.get("ryba", 0)) + 1
			stats_changed.emit()
		KEY_C:
			items["svice"] = CANDLE_USES
			stats_changed.emit()


func _debug_npc(npc_id: String) -> void:
	var r := interact(npc_id)
	if r.is_empty():
		print("[TEST] Interakce nejde, hra neběží (jsi na mapě?)")
		return
	print("[TEST] %s: %s" % [get_npc(npc_id).name, "ÚSPĚCH" if r.success else ("NIC NOVÉHO" if r.exhausted else "NEÚSPĚCH")])
	print("       ", r.text)
	if r.narrator != "":
		print("       Vypravěč: ", r.narrator)
	if r.items != "":
		print("       Batoh: ", r.items)
	print("       k%d g%d r%d | %s" % [comfort, glitch, reputation, items_text()])


func _debug_add(stat: String, amount: int) -> void:
	if not running or game_over:
		return
	_add(stat, amount)
	stats_changed.emit()
	
func item_count(item_id: String) -> int:
	return int(items.get(item_id, 0))
