extends Control


func _on_settings_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/settings.tscn")


func _on_restart_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game_board/game.tscn")


func _on_exit_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
