extends GridContainer

@export var grid_width := 15
@export var grid_height := 15
var tile_scene := preload("res://scenes/game_board/tile.tscn")
var tile_slot_scene := preload("res://scenes/game_board/tile_slot.tscn")

var invalid_tiles := {}
var board_valid := false
var max_tries := 50

enum Colors {
	RED,
	BLUE,
	BLACK,
	GREEN
}

enum Relations { 
	STRAIGHT, 
	MATCH, 
	NONE 
}

func _ready() -> void:
	columns = grid_width
	for i in grid_width * grid_height:
		var tile_slot := tile_slot_scene.instantiate()
		tile_slot.index = i
		tile_slot.tile_added.connect(_tile_added)
		tile_slot.tile_removed.connect(_tile_removed)
		add_child(tile_slot)
	
	## Dummy tiles
	#var a: Array[Array] = []
	#for c in TileInfo.Colors.values():
		#var b: Array[TileInfo] = []
		#for i in range(1, 14):
			#b.append(TileInfo.new(i, c))
		#a.append(b)
		#a.append(b)
	#add_tile_groups(a)
	var g = create_graph(13, 2, Colors.values())
	var puzzle = select_tiles(g, 50)
	var sum = 0
	for arr in puzzle:
		for value in arr:
			sum += 1
	print(sum)
	add_tile_groups(puzzle)

# Method to call to place starting state on the board
func add_tile_groups(groups: Array):
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


func create_graph(nums: int, decks: int, colors: Array) -> Dictionary:
	var g = {}
	for num in range(1, nums + 1):
		for color in colors:
			for deck in range(0, decks):
				var tile = TileInfo.new(num, color, deck)
				g[tile] = { "relation": Relations.NONE, "connections": [] }
	connect_graph(g)
	return g

# Connects nodes in the graph based on tile properties
func connect_graph(g: Dictionary) -> void:
	for node in g.keys():
		for node2 in g.keys():
			if node.same(node2):
				continue
			if node.color == node2.color and abs(node.num - node2.num) == 1 and node.deck == node2.deck:
				g[node]["connections"].append({"node": node2, "relation": Relations.STRAIGHT})
			elif node.num == node2.num and node.deck == node2.deck:
				g[node]["connections"].append({"node": node2, "relation": Relations.MATCH})


# Random selection of tiles and groups to generate valid board state
func select_tiles(g: Dictionary, count: int) -> Array:
	var chosen_numbers_decks = []
	var board = []
	while count != 0:
		if count > 3:
			var match_or_straight = randi_range(0, 1)
			if match_or_straight == 0:
				var match_array = []
				var tile_num = randi_range(1, 13)
				var deck_num = randi_range(0,1)
				var random_color = randi_range(0,3)
				var random_match_size = randi_range(2,3)
				while ({"tile_num": tile_num, "deck_num": deck_num}) in chosen_numbers_decks:
					tile_num = randi_range(1, 13)
					deck_num = randi_range(0,1)
				chosen_numbers_decks.append({"tile_num": tile_num, "deck_num": deck_num})
				for tile in g:
					if tile.num == tile_num && tile.deck == deck_num && tile.color == random_color:
						for conn in g[tile]["connections"]:
							if conn["relation"] == Relations.MATCH:
								match_array.append(conn["node"])
								if match_array.size() == random_match_size:
									break
						match_array.append(tile)
						break
				board.append(match_array)
				count -= random_match_size + 1
			elif match_or_straight == 1:
				print("attempting")
				var straight_array = []
				var tries = 0
				var success = false
				var rand_straight_len = randi_range(3, 12)
				var rand_color = randi_range(0,3)
				var tile_num = randi_range(1,13)
				var deck_num = randi_range(0,1)
				while success == false:
					if tries == max_tries:
						break
					while ({"tile_num": tile_num, "deck_num": deck_num}) in chosen_numbers_decks:
						tile_num = randi_range(1, 13)
						deck_num = randi_range(0,1)
					for tile in g:
						if tile.num == tile_num && tile.deck == deck_num && tile.color == rand_color:
							var conns = []
							conns.append(tile)
							for conn in g[tile]["connections"]:
								if conn["relation"] == Relations.STRAIGHT:
									if conn["node"].num > tile_num && {"tile_num": conn["node"].num, "deck_num": conn["node"].deck} not in chosen_numbers_decks:
										conns.append(conn["node"])
										expand_straight(conn["node"], g, conns, rand_straight_len, chosen_numbers_decks)
									elif conn["node"].num < tile_num && {"tile_num": conn["node"].num, "deck_num": conn["node"].deck} not in chosen_numbers_decks:
										conns.push_front(conn["node"])
										expand_straight(conn["node"], g, conns, rand_straight_len, chosen_numbers_decks)
							if conns.size() >= rand_straight_len:
								success = true
								straight_array = conns
								break
							else:
								break
					tries += 1
				if success == true:
					for node in straight_array:
						#TODO FIX THIS BECAUSE ITS TECHNICALLY LIMITING POOL TOO MUCH
						chosen_numbers_decks.append({"tile_num": node.num, "deck_num": node.deck})
					board.append(straight_array)
					count -= rand_straight_len
				else:
					count -= 3
		elif count == 3:
			count -= 3
		else:
			count -= 1
	return board

func expand_straight(node: Object, g: Dictionary, total_conns: Array, max: int,  chosen_numbers_decks: Array) -> void:
	if total_conns.size() > max:
		return
	for inner_node in g[node]["connections"]:
		if inner_node["relation"] == Relations.STRAIGHT && inner_node["node"] not in total_conns:
			if inner_node["node"].num < node.num && {"tile_num": inner_node["node"].num, "deck_num": inner_node["node"].deck} not in chosen_numbers_decks:
				total_conns.push_front(inner_node["node"])
				print("hello in recursion 1")
				expand_straight(inner_node["node"], g, total_conns, max, chosen_numbers_decks)
			if inner_node["node"].num > node.num && {"tile_num": inner_node["node"].num, "deck_num": inner_node["node"].deck} not in chosen_numbers_decks:
				total_conns.append(inner_node["node"])
				print("hello in recursion 2")
				expand_straight(inner_node["node"], g, total_conns, max, chosen_numbers_decks)
