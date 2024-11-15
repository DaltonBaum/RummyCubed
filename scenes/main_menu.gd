extends Control


func _ready() -> void:
	%Settings.back_pressed.connect(_on_settings_exit)
	%HowToPlay.back_pressed.connect(_on_how_to_play_exit)

func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/difficulty_menu.tscn")

func _on_daily_button_pressed() -> void:
	PuzzleInfo.start_game(45, 60, Time.get_date_string_from_system())

func _on_settings_button_pressed() -> void:
	_hide_menu()
	%Settings.visible = true

func _on_how_to_play_button_pressed() -> void:
	_hide_menu()
	%HowToPlay.visible = true

func _on_credits_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Credits.tscn")

func _hide_menu() -> void:
	%MainMenuUI.visible = false

func _show_menu() -> void:
	%MainMenuUI.visible = true

func _on_settings_exit() -> void:
	_show_menu()
	%Settings.visible = false

func _on_how_to_play_exit() -> void:
	_show_menu()
	%HowToPlay.visible = false
