extends GridContainer

@export var grid_width := 15
@export var grid_height := 15
var tile_scene := preload("res://scenes/game_board/tile.tscn")
var tile_slot_scene := preload("res://scenes/game_board/tile_slot.tscn")

var invalid_tiles := {}
var board_valid := false

func _ready() -> void:
	columns = grid_width
	for i in grid_width * grid_height:
		var tile_slot := tile_slot_scene.instantiate()
		tile_slot.index = i
		tile_slot.tile_added.connect(_tile_added)
		tile_slot.tile_removed.connect(_tile_removed)
		add_child(tile_slot)
	
	# Dummy tiles
	var a: Array[Array] = []
	for c in TileInfo.Colors.values():
		var b: Array[TileInfo] = []
		for i in range(1, 14):
			b.append(TileInfo.new(i, c))
		a.append(b)
		a.append(b)
	add_tile_groups(a)

# Method to call to place starting state on the board
func add_tile_groups(groups: Array[Array]):
	var row := 0
	var column := 0
	for group in groups:
		if len(group) + column > grid_width:
			column = 0
			row += 2
		for info: TileInfo in group:
			var tile := tile_scene.instantiate()
			tile.update_info(info)
			get_child(row * grid_width + column).add_child(tile)
			column += 1
		column += 1

# The methods below use call_deferred to ensure the operating order for each frame is:
# 1 - listen for all tile changes
# 2 - check if the groups modified by tile changes are invalid or valid
# 3 - check if the entire board is valid and in a static state (no tiles currently being dragged)

# Listener for when a tile is added to a slot
func _tile_added(index: int) -> void:
	call_deferred("_check_group", index)

# Listener for when a tile is removed from a slot
func _tile_removed(index: int) -> void:
	invalid_tiles.erase(index)
	get_children()[index].set_invalid(false)
	call_deferred("_check_group", index-1)
	call_deferred("_check_group", index+1)

# Changes the group at/around index to be valid or invalid
func _check_group(index: int) -> void:
	var limits := _get_group_indexes(index)
	var invalid_group := _is_group_invalid(limits[0], limits[1])
	var children := get_children()

	for i in range(limits[0], limits[1], 1):
		if invalid_group:
			invalid_tiles[i] = null
		else:
			invalid_tiles.erase(i)
		children[i].set_invalid(invalid_group)
	call_deferred("_check_board")

# Gets the start/end index of the group at/around index
func _get_group_indexes(index: int) -> Array[int]:
	var lower_limit := index - (index % grid_width) - 1
	var upper_limit := lower_limit + grid_width + 1
	var children := get_children()
	for i in range(index, lower_limit, -1):
		var info: TileInfo = children[i].get_info()
		if info == null:
			lower_limit = i
			break
	for i in range(index, upper_limit, 1):
		var info: TileInfo = children[i].get_info()
		if info == null:
			upper_limit = i
			break
	return [lower_limit + 1, upper_limit]

# Determines if the group between lower_index and upper_index is valid or not
func _is_group_invalid(lower_index: int, upper_index: int) -> bool:
	var children := get_children()
	if upper_index - lower_index < 3:
		return true
	var info1: TileInfo = children[lower_index].get_info()
	var old_info: TileInfo = children[lower_index + 1].get_info()
	var relation := _get_relation(info1, old_info)
	if relation == TileInfo.Relations.INVALID:
		return true
	var seen := {info1: null, old_info: null}
	for i in range(lower_index + 2, upper_index, 1):
		var new_info: TileInfo = children[i].get_info()
		if _get_relation(old_info, new_info) != relation or new_info in seen:
			return true
		seen[new_info] = null
		old_info = new_info
	return false

# Gets the relation between two sets of TileInfo where info1 is on the left of info2
func _get_relation(info1: TileInfo, info2: TileInfo) -> TileInfo.Relations:
	if info1.color == info2.color:
		if info2.num - info1.num == 1:
			return TileInfo.Relations.RUN
	else:
		if info1.num == info2.num:
			return TileInfo.Relations.SET
	return TileInfo.Relations.INVALID

# Checks if the entire board is valid and in a static state 
func _check_board() -> void:
	if len(invalid_tiles) != 0 or DragManager.is_currently_dragging() or board_valid:
		return
	print("Valid Board")
	#get_tree().change_scene_to_file("res://scenes/credits.tscn")
	#board_valid = true
	
