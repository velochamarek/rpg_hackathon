class_name Pozdravy
## Úvodní věty postav podle situace: reputace, batoh, počet návštěv a glitch.
## Postava tak na hráče reaguje podle toho, kým se ve vsi stal.
##
## Použití (v dialog.gd místo npc.greeting):
##   Pozdravy.text(npc_id)
##
## Pravidla se procházejí shora dolů a vyhraje první, které sedí.
## Když nesedí žádné, použije se původní "greeting" z GameState.NPCS.
##
## Podmínky (všechny nepovinné):
##   rep_min / rep_max   rozsah reputace
##   item                hráč tenhle předmět MÁ
##   no_item             hráč tenhle předmět NEMÁ
##   min_visits          aspoň tolik úspěšných návštěv u této postavy
##   min_glitch          aspoň takový glitch

const PRAVIDLA := {
	"beta": [
		{"item": "svice", "rep_min": 50, "text": "Svíce? Na co ti je svíce, poutníku? V noci se přece spí."},
		{"rep_min": 80, "text": "Á, náš nejmilejší host! Polévka je ještě teplá, sedni si."},
		{"rep_max": 19, "text": "Ty se sem ještě odvažuješ? Děti, dovnitř!"},
		{"rep_max": 49, "text": "Hm. Zase ty. Lidé o tobě všelijak mluví."},
		{"min_glitch": 70, "text": "Dobrý den, poutníku. Vypadáš unaveně. Dobrý den, poutníku. Vypadáš… unaveně."},
	],
	"anselm": [
		{"item": "svice", "rep_max": 29, "text": "Svíci ti nevezmu. Ale trápí mě, kam ti teď svítí."},
		{"item": "svice", "text": "Svíce ti pořád svítí? Modlím se, abys ji nosil domů, ne do lesa."},
		{"rep_min": 80, "text": "Synu! Celá ves o tobě mluví jen v dobrém. Kaple je ti otevřená."},
		{"rep_max": 29, "text": "Tady se modlí slušní lidé. Ty bys měl spíš zpytovat svědomí."},
		{"rep_max": 49, "text": "Pokoj s tebou… Slyšel jsem, že tě viděli u moře s bardem."},
		{"rep_max": 59, "text": "Pokoj s tebou, synu. Jsi tu nový. Kaple je pro poctivé, uvidíme, jestli mezi ně patříš."},
	],
	"hana": [
		{"rep_min": 80, "text": "Hele, nejlepší pomocník na pobřeží! Sítě už na tebe čekají."},
		{"rep_max": 29, "text": "Ve vsi o tobě mluví ošklivě. Ale ryby to nezajímá. Pomůžeš?"},
		{"min_visits": 3, "text": "Zase ty? Výborně. Ty sítě se samy nespraví."},
	],
	"vitek": [
		{"min_visits": 3, "text": "Kamaráde! Moje písně už znáš všechny. Ale posedět u ohně můžeš."},
		{"rep_min": 70, "text": "Pst, ne tak nahlas. Takový vážený člověk a chce slyšet zakázanou píseň?"},
		{"rep_max": 29, "text": "Konečně někdo, kdo se nebojí. Sedni si, tady tě nikdo neuslyší."},
	],
	"ezechiel": [
		{"rep_min": 71, "text": "Smrdíš polévkou a kadidlem! Co tu chceš?"},
		{"rep_max": 19, "text": "Ty už to bzučení slyšíš hlasitěji než já. Já ti nestačím. Jdi za ní."},
		{"min_visits": 1, "text": "Vrátil ses! Bzučí to čím dál víc, slyšíš? Slyšíš?"},
	],
	"morwen": [
		{"no_item": "svice", "text": "Kdo to tam ve tmě šramotí? Bez světla tě nevidím. A ty mě taky ne."},
		{"rep_min": 31, "text": "Voníš vesnicí. Pořád ještě patříš jim."},
		{"min_glitch": 85, "text": "Slyšíš to praskání? To se trhá svět. Už jen kousek."},
		{"min_visits": 1, "text": "Vrátil ses. Jizvy se hojí pomalu, že?"},
	],
}


static func text(npc_id: String) -> String:
	for pravidlo in PRAVIDLA.get(npc_id, []):
		if _sedi(pravidlo, npc_id):
			return pravidlo["text"]
	return GameState.get_npc(npc_id).get("greeting", "")


static func _sedi(p: Dictionary, npc_id: String) -> bool:
	if GameState.reputation < p.get("rep_min", 0):
		return false
	if GameState.reputation > p.get("rep_max", 100):
		return false
	if p.has("item") and GameState.item_count(p["item"]) <= 0:
		return false
	if p.has("no_item") and GameState.item_count(p["no_item"]) > 0:
		return false
	if GameState.visits.get(npc_id, 0) < p.get("min_visits", 0):
		return false
	if GameState.glitch < p.get("min_glitch", 0):
		return false
	return true
