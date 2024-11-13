extends Control


func _on_easy_button_pressed() -> void:
	PuzzleInfo.start_game(15, 30)

func _on_medium_button_pressed() -> void:
	PuzzleInfo.start_game(30, 45)

func _on_hard_button_pressed() -> void:
	PuzzleInfo.start_game(45, 60)


func _on_exit_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
