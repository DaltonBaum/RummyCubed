extends Node2D

@export_range(0, 100) var camera_bounds_percent := 10
@export var starting_margin_percent := Vector2i(10, 20)
var completion_time := 0.0
var disabled := false

func _ready() -> void:
	# Setup camera
	_setup_cam()
	
	# Setup board
	var puzzle := PuzzleGenerator.create_puzzle(PuzzleInfo.size_min, PuzzleInfo.size_max, PuzzleInfo.p_seed)
	%Board.add_tile_groups(puzzle[1])
	%Board.board_completed.connect(_on_board_complete)
	completion_time = 0
	
	# Setup pause menu
	DragManager.disabled = false
	%PauseMenu.add_solution_groups(puzzle[0])
	%PauseMenu.resume_pressed.connect(_on_pause_resumed)

func _setup_cam() -> void:
	var board_pos: Vector2 = %Board.global_position
	var board_size: Vector2 = %Board.get_combined_minimum_size()
	var window_size: Vector2 = get_window().size
	var camera_bounds_margin := window_size * camera_bounds_percent / 100
	
	# Limit camera position
	%Camera.limit_left = board_pos.x - camera_bounds_margin.x
	%Camera.limit_top = board_pos.y - camera_bounds_margin.y
	%Camera.limit_right = board_pos.x + board_size.x + camera_bounds_margin.x
	%Camera.limit_bottom = board_pos.y + board_size.y + camera_bounds_margin.y
	
	# Limit camera zooming
	var zooms := window_size / (board_size + (camera_bounds_margin * 2))
	var min_zoom: float = max(zooms.x, zooms.y)
	%Camera.min_zoom = min_zoom
	%Camera.max_zoom = min_zoom * 3
	
	# Set starting position and zoom
	var starting_zooms := window_size / board_size / (100 + starting_margin_percent.x) * 100
	var starting_zoom: float = max(starting_zooms.x, starting_zooms.y)
	var pos_x: float = board_pos.x + (board_size.x / 2)
	var pos_y: float = board_pos.y + (window_size.y / 2 / starting_zoom) - (window_size.y * starting_margin_percent.y / 100 / starting_zoom)
	%Camera.position = Vector2(pos_x, pos_y)
	%Camera.zoom = Vector2(starting_zoom, starting_zoom)

func _process(delta: float) -> void:
	# Update stopwatch/display
	if !disabled:
		completion_time += delta
		%Stopwatch.text = PuzzleInfo.format_time(completion_time)

func _on_board_complete() -> void:
	if is_inside_tree():
		var tree := get_tree()
		PuzzleInfo.time_to_complete = completion_time
		tree.change_scene_to_file("res://scenes/victory_screen.tscn")

func _on_pause_pressed() -> void:
	%PauseOverlay.visible = true
	DragManager.disabled = true
	DragManager.cancel_drag()
	%Camera.disabled = true
	disabled = true

func _on_pause_resumed() -> void:
	%PauseOverlay.visible = false
	DragManager.disabled = false
	%Camera.disabled = false
	disabled = false
