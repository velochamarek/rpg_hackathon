extends Control

const INTRO_TEXT := """Probouzíš se v neznámé vesnici. Je noc. Nevíš, jak ses sem dostal, ani jak dlouho tu jsi. Lidé jsou milí a všechno vypadá normálně… jen na nebi chybí měsíc.

KOMFORT je tvoje síla. Každý rozhovor tě trochu vyčerpá. Když klesne na nulu, je konec.

REPUTACE určuje, kdo s tebou bude mluvit. Někdo se baví jen se slušnými lidmi, jiný jen s vyvrženci.

GLITCH… zatím nedává smysl. Všímej si, co ve světě nesedí.

Klikni na postavu a promluv si s ní."""

const NEXT_SCENE := "res://world.tscn"

@export var start_delay := 1.0   # vteřina ticha na černé obrazovce před začátkem

@onready var text_label: Label = $MarginContainer/VBoxContainer/TextLabel
@onready var continue_button: BaseButton = $MarginContainer/VBoxContainer/ContinueButton
@onready var typing_sound: AudioStreamPlayer = $TypingSound
@onready var end_click: AudioStreamPlayer = $EndClick
@onready var hover_sound: AudioStreamPlayer = get_node_or_null("HoverSound")

var typing := false
var leaving := false
var type_tween: Tween


func _ready() -> void:
	text_label.text = INTRO_TEXT
	text_label.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING
	text_label.visible_characters = 0

	continue_button.modulate.a = 0.0
	continue_button.disabled = true
	continue_button.pressed.connect(_on_continue_pressed)
	if hover_sound:
		continue_button.mouse_entered.connect(hover_sound.play)

	await get_tree().create_timer(start_delay).timeout
	_start_typing()


func _start_typing() -> void:
	typing = true
	var duration := typing_sound.stream.get_length()   # text běží stejně dlouho jako zvuk
	typing_sound.play()
	type_tween = create_tween()
	type_tween.tween_method(_set_shown_chars, 0.0, float(INTRO_TEXT.length()), duration)
	type_tween.finished.connect(_finish_typing)


func _set_shown_chars(count: float) -> void:
	text_label.visible_characters = int(count)


func _finish_typing() -> void:
	if not typing:
		return
	typing = false
	if type_tween and type_tween.is_running():
		type_tween.kill()
	text_label.visible_characters = -1   # celý text
	typing_sound.stop()
	end_click.play()                     # poslední cvak mezerníku

	continue_button.disabled = false
	create_tween().tween_property(continue_button, "modulate:a", 1.0, 0.8)
	continue_button.grab_focus()


# Kliknutí, Enter nebo mezerník během psaní text přeskočí
func _input(event: InputEvent) -> void:
	if not typing:
		return
	var skip: bool = event.is_action_pressed("ui_accept") \
		or (event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT)
	if skip:
		_finish_typing()
		get_viewport().set_input_as_handled()


func _on_continue_pressed() -> void:
	if leaving:
		return
	leaving = true
	continue_button.disabled = true
	var tween := create_tween()
	tween.tween_property($MarginContainer, "modulate:a", 0.0, 0.6)
	await tween.finished
	get_tree().change_scene_to_file(NEXT_SCENE)
