extends Control

func _on_new_game_button_pressed() -> void:
	get_tree().change_scene_to_file("res://world.tscn")

func _on_quit_game_button_pressed() -> void:
	get_tree().quit()
