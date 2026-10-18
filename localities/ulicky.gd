extends Control
## Temné uličky: Vítek při každé návštěvě zazpívá další sloku.
## Pravidla (reputace ≥ 20, +10 glitche, −15 reputace, −2 komfortu) řeší GameState.

const NIC_NEMAM := "Už pro tebe nic nemám, kamaráde. Všechno, co jsem znal, jsem ti zazpíval."

# Časy jsou v sekundách OD ZAČÁTKU DANÉ SLOKY (souboru), ne celé písně.
# Zatím jsou odhadnuté – dolaďte je podle poslechu.
const SLOKY := [
	{
		"audio": "res://audio/vitek_sloka1.ogg",
		"lines": [
			[4.3, "Šel jsem až tam, kde končí cesta,"],
			[9.8, "kde poslední smrk u brodu stál."],
			[15.2, "Nečekal tam les ani jiná města,"],
			[20.7, "jen bílá mlha a ticho dál."],
			[26.1, "Tak nalej, hospodo, ať zpívám dál,"],
			[31.6, "než zapomenu, co jsem znal."],
		],
	},
	{
		"audio": "res://audio/vitek_sloka2.ogg",
		"lines": [
			[0.5, "Ráno se budím, kohout zpívá,"],
			[7.3, "na stole chléb, jak včera byl."],
			[14.0, "Hospodská stejně se usmívá,"],
			[20.8, "jak by ten den už tisíckrát žil."],
			[27.5, "Tak nalej, hospodo, ať zpívám dál,"],
			[34.3, "než zapomenu, co jsem znal."],
		],
	},
	{
		"audio": "res://audio/vitek_sloka3.ogg",
		"lines": [
			[0.3, "Ptáci nad návsí v kruzích létají,"],
			[5.5, "jako by jinam nesměli."],
			[10.7, "Hvězdy jak hřebíky v plátně se blýskají,"],
			[15.9, "jen měsíc nikdo neviděl."],
		],
	},
	{
		"audio": "res://audio/vitek_sloka4.ogg",
		"lines": [
			[0.3, "Ptal jsem se lidí, proč je to tak,"],
			[4.6, "proč každý večer zní stejný zvon."],
			[9.0, "Usmáli se a nalili, a pak…"],
			[13.3, "pak už nevím. Zapomněl jsem, na co jsem se ptal."],
		],
	},
]

@onready var vitek: BaseButton = $Vitek
@onready var dialog: Control = $Dialog
@onready var text_label: Label = $Dialog/VBox/Text
@onready var vypravec: Label = $Dialog/VBox/Vypravec
@onready var volby: Control = $Dialog/VBox/Volby
@onready var zazpivej: Button = $Dialog/VBox/Volby/Zazpivej
@onready var zavrit: Button = $Dialog/VBox/Volby/Zavrit
@onready var odejit: Control = $Odejit
@onready var zpev: AudioStreamPlayer = $Zpev

var _lines: Array = []
var _singing := false
var _narrator := ""


func _ready() -> void:
	GameState.start()   # aby šlo testovat i přes F6
	dialog.visible = false
	zazpivej.text = GameState.get_npc("vitek").player_line   # „Zazpívej mi ji.“
	vitek.pressed.connect(_otevrit)
	zazpivej.pressed.connect(_on_zazpivej)
	zavrit.pressed.connect(_zavrit)
	zpev.finished.connect(_on_konec_pisne)


func _process(_delta: float) -> void:
	if not _singing:
		return
	# Ukáže verš, který se právě zpívá
	var t: float = zpev.get_playback_position()
	var current := ""
	for line in _lines:
		if t >= line[0]:
			current = line[1]
	text_label.text = current


func _otevrit() -> void:
	if _singing:
		return
	dialog.visible = true
	vypravec.text = ""
	text_label.text = GameState.get_npc("vitek").greeting
	_ukaz_volby(true, "Nic, díky.")


func _zavrit() -> void:
	dialog.visible = false


func _on_zazpivej() -> void:
	var slyseno: int = GameState.visits["vitek"]

	# 5. a další návštěva: nic nestojí, nic nedá
	if slyseno >= SLOKY.size():
		text_label.text = NIC_NEMAM
		_ukaz_volby(false, "Odejít")
		return

	var result: Dictionary = GameState.interact("vitek")
	if result.is_empty():
		return
	if not result.success:
		text_label.text = result.text   # reputace pod 20
		_ukaz_volby(false, "Odejít")
		return

	_zacni_zpivat(SLOKY[slyseno], result.narrator)


func _zacni_zpivat(sloka, narrator: String) -> void:
	_singing = true
	_narrator = narrator
	_lines = sloka.lines
	volby.visible = false
	odejit.visible = false     # během písně nejde odejít
	vitek.disabled = true
	text_label.text = ""
	zpev.stream = load(sloka.audio)
	zpev.play()


func _on_konec_pisne() -> void:
	_singing = false
	vypravec.text = _narrator   # modrá věta vypravěče (glitch)
	odejit.visible = true
	vitek.disabled = false
	_ukaz_volby(false, "Díky.")


func _ukaz_volby(muze_zpivat: bool, text_zavrit: String) -> void:
	volby.visible = true
	zazpivej.visible = muze_zpivat
	zavrit.text = text_zavrit
