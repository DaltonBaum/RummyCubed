extends Node2D

@export_range(0, 100) var camera_bounds_percent := 25

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
	%Board.add_tile_groups(PuzzleGenerator.create_puzzle(200, 1694546302, 99, 4))
