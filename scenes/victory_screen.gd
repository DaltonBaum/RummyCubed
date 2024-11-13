extends Control


func _ready() -> void:
	%TimeHolder.text = PuzzleInfo.format_time(PuzzleInfo.time_to_complete)


func _on_continue_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/difficulty_menu.tscn")


func _on_exit_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
