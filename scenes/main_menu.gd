extends Control


func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/difficulty_menu.tscn")


func _on_daily_button_pressed() -> void:
	PuzzleInfo.start_game(45, 60, Time.get_date_string_from_system())


func _on_settings_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/settings.tscn")


func _on_how_to_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/how_to_play.tscn")


func _on_credits_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/credits.tscn")
