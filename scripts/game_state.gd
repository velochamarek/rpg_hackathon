extends Node
## Globální stav hry. Zapojit jako Autoload s názvem "GameState".
## Odkudkoli ve hře: GameState.change(komfort, reputace, glitch)
## Příklad čarodějnice: GameState.change(0, -3, 2)

signal stats_changed            # staty se změnily -> HUD se překreslí
signal system_offer             # reputace dosáhla 10 -> nabídka systému
signal true_glitch_unlocked     # glitch dosáhl 10 -> pravý glitch jde najít

const MIN_STAT := 0
const MAX_STAT := 10
const ENDING_SCENE := "res://ending.tscn" # jeste se vytvori

# Startovní hodnoty
const START_COMFORT := 6
const START_REPUTATION := 5
const START_GLITCH := 0

# Po kolika sekundách ubude 1 komfort (pro testování klidně dejte 2.0)
const COMFORT_DECAY_SECONDS := 60.0

var comfort := START_COMFORT
var reputation := START_REPUTATION
var glitch := START_GLITCH

var game_over := false
var ending := ""                # "death", "escape", "system"

var _decay_timer := 0.0
var _offer_sent := false
var _glitch_sent := false


func _process(delta: float) -> void:
	if game_over:
		return
	_decay_timer += delta
	if _decay_timer >= COMFORT_DECAY_SECONDS:
		_decay_timer = 0.0
		change(-1, 0, 0)


## Hlavní funkce pro změnu statů. Kladná čísla přidávají, záporná ubírají.
func change(d_comfort: int, d_reputation: int, d_glitch: int) -> void:
	if game_over:
		return
	comfort = clampi(comfort + d_comfort, MIN_STAT, MAX_STAT)
	reputation = clampi(reputation + d_reputation, MIN_STAT, MAX_STAT)
	glitch = clampi(glitch + d_glitch, MIN_STAT, MAX_STAT)
	stats_changed.emit()
	_check_thresholds()


func _check_thresholds() -> void:
	if comfort <= MIN_STAT:
		end_game("death")
		return

	if reputation >= MAX_STAT and not _offer_sent:
		_offer_sent = true
		system_offer.emit()
	elif reputation < MAX_STAT:
		_offer_sent = false   # když reputace klesne, nabídka může přijít znovu

	if glitch >= MAX_STAT and not _glitch_sent:
		_glitch_sent = true
		true_glitch_unlocked.emit()


## Zavolat, když hráč přijme nabídku systému ("system")
## nebo použije pravý glitch ("escape").
func end_game(ending_id: String) -> void:
	if game_over:
		return
	game_over = true
	ending = ending_id
	print("KONEC HRY: ", ending_id)
	if ResourceLoader.exists(ENDING_SCENE):
		get_tree().call_deferred("change_scene_to_file", ENDING_SCENE)


## Nová hra - vrátí všechno na začátek.
func reset() -> void:
	comfort = START_COMFORT
	reputation = START_REPUTATION
	glitch = START_GLITCH
	game_over = false
	ending = ""
	_decay_timer = 0.0
	_offer_sent = false
	_glitch_sent = false
	stats_changed.emit()
