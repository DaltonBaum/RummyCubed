extends Node2D

@export_range(0, 100) var camera_bounds_percent := 25
var completion_time := 0.0

func _ready() -> void:
	# Limit camera movement to prevent user from getting lost
	# POORLY DONE, LIKELY NEEDS REWORK
	var board_pos: Vector2 = %Board.global_position
	var board_size: Vector2 = %Board.get_combined_minimum_size()
	var camera_bounds_margin := get_window().size * camera_bounds_percent / 100
	%Camera.limit_left = board_pos.x - camera_bounds_margin.x
	%Camera.limit_top = board_pos.y - camera_bounds_margin.y
	%Camera.limit_right = board_pos.x + board_size.x + camera_bounds_margin.x
	%Camera.limit_bottom = board_pos.y + board_size.y + camera_bounds_margin.y
	%Camera.position = (board_pos + board_size) / 2
	
	# Setup board
	%Board.add_tile_groups(PuzzleGenerator.create_puzzle(PuzzleInfo.size_min, PuzzleInfo.size_max, PuzzleInfo.p_seed))
	%Board.board_completed.connect(_on_board_complete)
	completion_time = 0

func _process(delta: float) -> void:
	# Update stopwatch/display
	completion_time += delta
	%Stopwatch.text = PuzzleInfo.format_time(completion_time)

func _on_board_complete() -> void:
	PuzzleInfo.time_to_complete = completion_time
	get_tree().change_scene_to_file("res://scenes/victory_screen.tscn")
