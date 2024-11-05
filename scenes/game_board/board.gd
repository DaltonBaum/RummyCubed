extends GridContainer

@export var grid_width := 15
@export var grid_height := 15
var tile_scene := preload("res://scenes/game_board/tile.tscn")
var tile_slot_scene := preload("res://scenes/game_board/tile_slot.tscn")

var invalid_tiles := {}
var board_valid := false
var random_samples := 100

func _ready() -> void:
	columns = grid_width
	for i in grid_width * grid_height:
		var tile_slot := tile_slot_scene.instantiate()
		tile_slot.index = i
		tile_slot.tile_added.connect(_tile_added)
		tile_slot.tile_removed.connect(_tile_removed)
		add_child(tile_slot)
	
	var g = create_graph(13, 2, TileInfo.Colors.values())
	var selected_tiles = select_tiles(g, 10)
	clear_graph(g, selected_tiles)

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
	var seen := [info1, old_info]
	for i in range(lower_index + 2, upper_index, 1):
		var new_info: TileInfo = children[i].get_info()
		if _get_relation(old_info, new_info) != relation or new_info.same(seen):
			return true
		seen.append(new_info)
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
				g[tile] = { "relation": TileInfo.Relations.INVALID, "connections": {} }
	connect_graph(g)
	return g

# Connects nodes in the graph based on tile properties
func connect_graph(g: Dictionary) -> void:
	for node in g.keys():
		for node2 in g.keys():
			if node.same(node2):
				continue
			if node.color == node2.color and abs(node.num - node2.num) == 1:
				g[node]["connections"][node2] = {"relation": TileInfo.Relations.RUN}
			elif node.num == node2.num:
				g[node]["connections"][node2] = {"relation": TileInfo.Relations.SET}

func select_tiles(g: Dictionary, count: int) -> Array:
	if count < 3:
		print("Bad Tile count")
		return []
	var groups = []
	groups.append(create_new_group(g))
	count -=3
	while count >= 3:
		groups.append(create_adjacent_group(g))
		count -=3
	while count > 0:
		create_adjacent_tile(g, groups)
		count -=1
	var chosen_nodes = []
	for node in g:
		if g[node]["relation"] != TileInfo.Relations.INVALID:
			chosen_nodes.append(node)
	return chosen_nodes
	
func create_new_group(g: Dictionary) -> Array:
	var nodes = []
	for node in g:
		nodes.append(node)
	for i in range(random_samples):
		var node1 = nodes[randi() % nodes.size()]
		var connected_nodes = []
		for conn in g[node1]["connections"].keys():
			if conn in nodes:
				connected_nodes.append(conn)
		if connected_nodes.size() == 0:
			continue
		var node2 = connected_nodes[randi() % connected_nodes.size()]
		var relation = g[node1]["connections"][node2]["relation"]
		connected_nodes = []
		for conn in g[node1]["connections"].keys():
			if conn in nodes and not node1.same(conn) and g[node1]["connections"][conn]["relation"] == relation:
				connected_nodes.append(conn)
		for conn in g[node2]["connections"].keys():
			if conn in nodes and not node2.same(conn) and  g[node2]["connections"][conn]["relation"] == relation:
				connected_nodes.append(conn)
		if connected_nodes.size() == 0:
			continue
		var node3 = connected_nodes[randi() % connected_nodes.size()]
		g[node1]["relation"] = relation
		g[node2]["relation"] = relation
		g[node3]["relation"] = relation
		return [node1, node2, node3]
	print("failed to make new group")
	return []
	
func create_adjacent_group(g: Dictionary) -> Array:
	var used_nodes = []
	var possible_nodes = []
	for node in g:
		if g[node]["relation"] != TileInfo.Relations.INVALID:
			used_nodes.append(node)
	for node in used_nodes:
		for conn in g[node]["connections"].keys():
			if conn not in used_nodes:
				possible_nodes.append(conn)
	if possible_nodes.size() == 0:
		print("failed to make adjacent group")
		return []
	for i in range(random_samples):
		var node1 = possible_nodes[randi() % possible_nodes.size()]
		var connected_nodes = []
		for conn in g[node1]["connections"].keys():
			if conn not in used_nodes:
				connected_nodes.append(conn)
		if connected_nodes.size() == 0:
			continue
		var node2 = connected_nodes[randi() % connected_nodes.size()]
		var relation = g[node1]["connections"][node2]["relation"]
		connected_nodes = []
		for conn in g[node1]["connections"].keys():
			if conn not in used_nodes and not node1.same(conn) and g[node1]["connections"][conn]["relation"] == relation:
				connected_nodes.append(conn)
		for conn in g[node2]["connections"].keys():
			if conn not in used_nodes and not node2.same(conn) and  g[node2]["connections"][conn]["relation"] == relation:
				connected_nodes.append(conn)
		if connected_nodes.size() == 0:
			continue
		var node3 = connected_nodes[randi() % connected_nodes.size()]
		g[node1]["relation"] = relation
		g[node2]["relation"] = relation
		g[node3]["relation"] = relation
		return [node1, node2, node3]
	print("failed to make adjacent group")
	return []

func create_adjacent_tile(g: Dictionary, groups: Array) -> void:
	var used_nodes = []
	for node in g:
		if g[node]["relation"] != TileInfo.Relations.INVALID:
			used_nodes.append(node)
	for i in range(random_samples):
		var nodes = groups[randi() % groups.size()]
		var relation = g[nodes[0]]["relation"]
		var conns = []
		for conn in g[nodes[0]]["connections"].keys():
			if conn not in used_nodes and not nodes[0].same(conn) and g[nodes[0]]["connections"][conn]["relation"] == relation:
				conns.append(conn)
		for conn in g[nodes[1]]["connections"].keys():
			if conn not in used_nodes and not nodes[1].same(conn) and g[nodes[1]]["connections"][conn]["relation"] == relation:
				conns.append(conn)
		for conn in g[nodes[2]]["connections"].keys():
			if conn not in used_nodes and not nodes[2].same(conn) and g[nodes[2]]["connections"][conn]["relation"] == relation:
				conns.append(conn)
		if conns.size() == 0:
			print("no adjacent tiles")
			continue
		var node = conns[randi() % conns.size()]
		g[node]["relation"] = relation
		nodes.append(node)
		return
	print("failed to add adjacent tile")
	return 
	
func clear_graph(og: Dictionary, selected_tiles: Array) -> void:
	for node in og.keys():
		for conn in og[node]["connections"].keys():
			if conn not in selected_tiles:
				og[node]["connections"].erase(conn)
		if node not in selected_tiles:
			og.erase(node)
		else:
			og[node]["relation"] = TileInfo.Relations.INVALID
	for start in og:
		var groups = {}
		for r in range(3):
			groups[r] = {}
		var counts = {}
		for r in range(3):
			counts[r] = 0
		for conn in og[start]["connections"].keys():
			if not groups[og[start]["connections"][conn]["relation"]].has(conn):
				counts[og[start]["connections"][conn]["relation"]] += 1
			groups[og[start]["connections"][conn]["relation"]][conn] = true
		for relation in range(3):
			if counts[relation] < 2:
				for end in groups[relation].keys():
					og.erase(end)
					og[start]["connections"].erase(end)
