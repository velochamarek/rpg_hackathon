extends Control
## Betčin obchůdek: kliknutím na chleba si hráč koupí jídlo.
## Pravidla (reputace ≥ 60, +30 komfortu, −5 glitche, −2 za interakci) řeší GameState.

const DEKUJI := "Děkuji, přijď zas."

@onready var rec: Label = $Dialog/VBox/Rec
@onready var chleba: BaseButton = $Chleba


func _ready() -> void:
	GameState.start()   # aby šlo testovat i přes F6
	rec.text = GameState.get_npc("beta").greeting
	chleba.pressed.connect(_on_chleba)


func _on_chleba() -> void:
	var result: Dictionary = GameState.interact("beta")
	if result.is_empty():
		return
	if result.success:
		rec.text = DEKUJI
	else:
		rec.text = result.text   # „Neznám tě dost dobře… Hana u moře…“

	# krátká pauza proti dvojkliku
	chleba.disabled = true
	await get_tree().create_timer(0.6).timeout
	if is_instance_valid(chleba):
		chleba.disabled = false
