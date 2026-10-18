extends Control

func _on_new_game_button_pressed() -> void:
	leaving_menu = true
	GameState.reset()
	get_tree().change_scene_to_file("res://vysvetleni.tscn")

func _on_quit_game_button_pressed() -> void:
	get_tree().quit()


@onready var background_music: AudioStreamPlayer = $BackgroundMusic
@onready var hover_sound: AudioStreamPlayer = $HoverSound
@onready var new_game_button: Button = $VBoxContainer/NewGameButton
@onready var quit_game_button: Button = $VBoxContainer/QuitGameButton
var leaving_menu := false

func _ready():
	background_music.play()
	new_game_button.mouse_entered.connect(_on_button_hovered)
	quit_game_button.mouse_entered.connect(_on_button_hovered)
	hover_sound.finished.connect(_on_hover_sound_finished)

func _on_button_hovered():
	if leaving_menu:
		return
	background_music.stream_paused = true
	hover_sound.stop()
	hover_sound.play()

func _on_hover_sound_finished():
	if not leaving_menu:
		background_music.stream_paused = false
