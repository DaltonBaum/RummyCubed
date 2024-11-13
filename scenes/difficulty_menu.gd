extends ColorRect


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_easy_button_pressed() -> void:
	PuzzleInfo.size_min = 15
	PuzzleInfo.size_max = 30
	_open_game()

func _on_medium_button_pressed() -> void:
	PuzzleInfo.size_min = 30
	PuzzleInfo.size_max = 45
	_open_game()

func _on_hard_button_pressed() -> void:
	PuzzleInfo.size_min = 45
	PuzzleInfo.size_max = 60
	_open_game()

func _open_game():
	randomize()
	PuzzleInfo.p_seed = randi()
	get_tree().change_scene_to_file("res://scenes/game_board/game.tscn")

func _on_exit_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
