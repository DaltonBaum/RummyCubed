class_name PuzzleGenerator

static var random_samples := 100
static var default_nums := 13
static var default_colors := TileInfo.Colors.values()
static var default_decks := 2

static func create_puzzle(size: int, _seed = null, nums := default_nums, decks := default_decks, colors := default_colors) -> Array[Array]:
	if _seed == null:
		randomize()
		_seed = randi()
	var seed_int: int = _seed if _seed is int else hash(_seed)
	print_debug("Puzzle seed is: ", _seed)
	seed(seed_int)
	var g := _create_graph(nums, decks, colors)
	var selected_tiles := _select_tiles(g, size)
	selected_tiles.shuffle()
	var puzzle := _traverse(selected_tiles)
	return puzzle.get_connected_components()

# Creates a TileGraph with every valid conenction
static func _create_graph(nums: int, decks: int, colors: Array) -> TileGraph:
	var g := TileGraph.new()
	for num in range(1, nums + 1):
		for color in colors:
			for deck in range(1, decks+1):
				g.add_node(TileInfo.new(num, color, deck))
	_connect_graph(g)
	return g

# Connects nodes in a TileGraph based on tile properties
static func _connect_graph(g: TileGraph) -> void:
	var nodes := g.get_nodes()
	for node_i1 in range(0, len(nodes)):
		for node_i2 in range(node_i1 + 1, len(nodes)):
			var node1: TileInfo = nodes[node_i1]
			var node2: TileInfo = nodes[node_i2]
			if node1.same(node2):
				continue
			if node1.color == node2.color and abs(node1.num - node2.num) == 1:
				g.add_edge(node1, node2, TileInfo.Relations.RUN)
			elif node1.num == node2.num:
				g.add_edge(node1, node2, TileInfo.Relations.SET)

# Selects 'n' tiles from the graph which form valid groups
static func _select_tiles(g: TileGraph, count: int) -> Array[TileInfo]:
	if count < 3:
		push_error("Bad selection tile count")
		return []
	var groups: Array[Array] = []
	groups.append(_create_new_group(g))
	count -= 3
	while count >= 3:
		groups.append(_create_adjacent_group(g))
		count -= 3
	while count > 0:
		_create_adjacent_tile(g, groups)
		count -=1
	var chosen_nodes: Array[TileInfo] = []
	for group in groups:
		chosen_nodes.append_array(group)
	return chosen_nodes

# Creates a group of 3 tiles from the TileGraph randomly
static func _create_new_group(g: TileGraph) -> Array[TileInfo]:
	var nodes = g.get_nodes(TileInfo.Relations.INVALID)
	for i in range(random_samples):
		var node1 = nodes[randi() % nodes.size()]
		var connected_nodes = g.get_neighbors(node1)
		if connected_nodes.size() == 0:
			continue
		var node2 = connected_nodes[randi() % connected_nodes.size()]
		var relation = g.get_edge_relation(node1, node2)
		connected_nodes = g.get_neighbors([node1, node2], relation)
		if connected_nodes.size() == 0:
			continue
		var node3 = connected_nodes[randi() % connected_nodes.size()]
		g.set_node_relation(node1, relation)
		g.set_node_relation(node2, relation)
		g.set_node_relation(node3, relation)
		return [node1, node2, node3]
	push_error("Failed to make new group")
	return []

# Creates a group of 3 unused tiles from the TileGraph randomly
# The group will have at least one connection to an already added tile
static func _create_adjacent_group(g: TileGraph) -> Array[TileInfo]:
	var used_nodes := g.get_nodes(TileInfo.Relations.SET)
	used_nodes.append_array(g.get_nodes(TileInfo.Relations.RUN))
	var possible_nodes := g.get_neighbors(used_nodes)
	if possible_nodes.size() == 0:
		push_error("Failed to make adjacent group")
		return []
	var in_use_filter = func(node): return node not in used_nodes
	for i in range(random_samples):
		var node1 = possible_nodes[randi() % possible_nodes.size()]
		var connected_nodes = g.get_neighbors(node1).filter(in_use_filter)
		if connected_nodes.size() == 0:
			continue
		var node2 = connected_nodes[randi() % connected_nodes.size()]
		var relation = g.get_edge_relation(node1, node2)
		connected_nodes = g.get_neighbors([node1, node2], relation).filter(in_use_filter)
		if connected_nodes.size() == 0:
			continue
		var node3 = connected_nodes[randi() % connected_nodes.size()]
		g.set_node_relation(node1, relation)
		g.set_node_relation(node2, relation)
		g.set_node_relation(node3, relation)
		return [node1, node2, node3]
	push_error("Failed to make adjacent group")
	return []

# Add a single, unused tile onto an existing group
static func _create_adjacent_tile(g: TileGraph, groups: Array[Array]) -> void:
	var used_nodes := g.get_nodes(TileInfo.Relations.SET)
	used_nodes.append_array(g.get_nodes(TileInfo.Relations.RUN))
	var in_use_filter = func(node): return node not in used_nodes
	for i in range(random_samples):
		var nodes = groups[randi() % groups.size()]
		var relation = g.get_node_relation(nodes[0])
		var connected_nodes = g.get_neighbors(nodes, relation).filter(in_use_filter)
		if connected_nodes.size() == 0:
			continue
		var node = connected_nodes[randi() % connected_nodes.size()]
		g.set_node_relation(node, relation)
		nodes.append(node)
		return
	push_error("Failed to add adjacent tile")
	return

# Create a puzzle graph by traversing across 'order' and adding the tiles to the puzzle
static func _traverse(order: Array[TileInfo]) -> TileGraph:
	var full_g := TileGraph.new()
	var puzzle_g := TileGraph.new()
	for tile in order:
		full_g.add_node(tile)
		puzzle_g.add_node(tile)
	_connect_graph(full_g)
	for tile in order:
		var modifications: Array[Modification]= _get_valid_changes(puzzle_g, full_g, tile)
		update_with_max(puzzle_g, modifications)
	return puzzle_g

# Gets all valid possible modifications to 'puzzle_g' with regards to 'node'
static func _get_valid_changes(puzzle_g: TileGraph, full_g: TileGraph, node: TileInfo) -> Array[Modification]:
	if puzzle_g.get_node_relation(node) != TileInfo.Relations.INVALID:
		return []
	var modifications: Array[Modification] = []
	
	# Tile stays in hand
	modifications.append(Modification.new([], TileInfo.Relations.INVALID))
	
	# Tile added onto existing group (will create multiple modifications for sets)
	var neighbors := full_g.get_neighbors(node)
	for neighbor in neighbors:
		var group := puzzle_g.get_connected_components([neighbor])[0]
		var relation := full_g.get_edge_relation(neighbor, node)
		if puzzle_g.get_node_relation(neighbor) == relation and !node.same(group):
			var connected_members: Array[TileInfo] = group.filter(func(n): return full_g.has_edge(node, n))
			var connections: Array = connected_members.map(func(n): return [node, n])
			modifications.append(Modification.new(connections, relation))
	
	# Tile creates new group (will create multiple modifications for groups where n degree > 1)
	for node2 in neighbors:
		if puzzle_g.get_node_relation(node2) != TileInfo.Relations.INVALID:
			continue
		var relation := full_g.get_edge_relation(node2, node)
		for node3 in full_g.get_neighbors([node, node2], relation):
			if puzzle_g.get_node_relation(node3) != TileInfo.Relations.INVALID:
				continue
			var connections: Array[Array] = [[node, node2],[node, node3],[node2, node3]]
			connections = connections.filter(func(conn): return full_g.has_edge(conn[0], conn[1]))
			modifications.append(Modification.new(connections, relation))
	
	return modifications

# Updates 'g' with the best modification determined by '_score_graph'
static func update_with_max(g: TileGraph, modifications: Array[Modification]) -> void:
	if modifications.size() == 0:
		return
	var best_index = 0
	var best_complexity = -INF
	for mod_i in modifications.size():
		var mod := modifications[mod_i]
		var relation_save := {}
		for conn_i in mod.connections.size():
			var node0: TileInfo = mod.connections[conn_i][0]
			var node1: TileInfo = mod.connections[conn_i][1]
			g.add_edge(node0, node1)
			relation_save.merge({node0: g.get_node_relation(node0), node1: g.get_node_relation(node1)})
			g.set_node_relation(node0, mod.relation)
			g.set_node_relation(node1, mod.relation)
		var complexity = _score_graph(g)
		if complexity > best_complexity:
			best_index = mod_i
			best_complexity = complexity
		for conn_i in mod.connections.size():
			var node0: TileInfo = mod.connections[conn_i][0]
			var node1: TileInfo = mod.connections[conn_i][1]
			g.remove_edge(node0, node1)
		for node in relation_save.keys():
			g.set_node_relation(node, relation_save[node])
	var best_mod = modifications[best_index]
	for conn in best_mod.connections:
		g.add_edge(conn[0], conn[1])
		g.set_node_relation(conn[0], best_mod.relation)
		g.set_node_relation(conn[1], best_mod.relation)

# Scores a graph based on desired and undesired criteria
static func _score_graph(g: TileGraph) -> float:
	var edge_count := g.get_edge_count()
	var group_sizes: Array = g.get_connected_components().map(len)
	
	# Reward for higher edge density and larger group sizes
	var edge_density_score := float(edge_count) ** 1.5
	var group_size_score := 0.0
	for group_size in group_sizes:
		group_size_score += float(group_size) ** 1.2

	# Count relation types and assign higher scores for a mix of types
	var set_count := g.get_nodes(TileInfo.Relations.SET).size()
	var run_count := g.get_nodes(TileInfo.Relations.RUN).size()
	var relation_variety_score := float(min(set_count, run_count)) * 1.5
	
	# Penalize disconnected components, as they simplify the solution space
	var disconnected_penalty: float = -len(group_sizes.filter(func(c): return c < 3))
	
	return (
		edge_density_score +
		group_size_score +
		relation_variety_score +
		disconnected_penalty
	)
