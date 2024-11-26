extends Control

signal resume_pressed


func _ready() -> void:
	%Settings.back_pressed.connect(_on_settings_exit)
	%HowToPlay.back_pressed.connect(_on_how_to_play_exit)
	%SolutionMenu.back_pressed.connect(_on_solution_menu_exit)

func _on_resume_button_pressed() -> void:
	resume_pressed.emit()

func _on_settings_button_pressed() -> void:
	_hide_menu()
	%Settings.visible = true

func _on_how_to_play_button_pressed() -> void:
	_hide_menu()
	%HowToPlay.visible = true

func _on_show_solution_button_pressed() -> void:
	_hide_menu()
	%SolutionMenu.visible = true

func _on_restart_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game_board/game.tscn")

func _on_exit_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _hide_menu() -> void:
	%PauseUI.visible = false

func _show_menu() -> void:
	%PauseUI.visible = true

func _on_settings_exit() -> void:
	_show_menu()
	%Settings.visible = false

func _on_how_to_play_exit() -> void:
	_show_menu()
	%HowToPlay.visible = false

func _on_solution_menu_exit() -> void:
	_show_menu()
	%SolutionMenu.visible = false

func add_solution_groups(groups: Array[Array]) -> void:
	%SolutionMenu.add_solution_groups(groups)
