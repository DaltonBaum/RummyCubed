extends Control

signal back_pressed


func _on_back_button_pressed() -> void:
	back_pressed.emit()

func add_solution_groups(groups: Array[Array]) -> void:
	%Board.add_tile_groups(groups)
	_trim_board()

# Remove unused bottom layers of tile slots
func _trim_board() -> void:
	var children := %Board.get_children()
	for row in range(%Board.grid_height-1, 0, -1):
		var is_empty = true
		for col in range(%Board.grid_width):
			if children[row * %Board.grid_width + col].get_child_count() != 0:
				is_empty = false
				break
		if not is_empty:
			break
		%Board.grid_height -= 1
		for col in range(%Board.grid_width):
			children[row * %Board.grid_width + col].free()

# Resize solution board to fit on screen size
func _on_board_holder_resized() -> void:
	var board_size: Vector2 = %Board.size
	var holder_size: Vector2 = %BoardHolder.size
	var scales := holder_size/board_size
	var min_scale: float = min(scales.x, scales.y)
	%Board.scale = Vector2(min_scale, min_scale)
	board_size.x
	%Board.position = Vector2((holder_size.x - board_size.x * min_scale) / 2, 0)
	print(board_size)
	print(holder_size)
	print(%Board.size)
