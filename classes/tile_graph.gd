class_name TileGraph

var g = {}
var relations = {}

# Add tile to TileGraph
func add_node(tile: TileInfo, relation := TileInfo.Relations.INVALID) -> void:
	g[tile] = {}
	set_node_relation(tile, relation)

# Add edge to TileGraph
func add_edge(tile1: TileInfo, tile2: TileInfo, relation := TileInfo.Relations.INVALID) -> void:
	g[tile1][tile2] = relation
	g[tile2][tile1] = relation

# Remove edge from TileGraph
func remove_edge(tile1: TileInfo, tile2: TileInfo) -> void:
	g[tile1].erase(tile2)
	g[tile2].erase(tile1)

# Returns true if the graph contains the edge from 'tile1' to 'tile2'
func has_edge(tile1: TileInfo, tile2: TileInfo) -> bool:
	return g[tile1].has(tile2)

# Gets the total number of edges in the graph
func get_edge_count() -> int:
	var count := 0
	for edges in g.values():
		count += len(edges)
	return count / 2

# Get the relation of a tile
func get_node_relation(tile: TileInfo) -> TileInfo.Relations:
	return relations[tile]

# Set the relation of a tile
func set_node_relation(tile: TileInfo, relation: TileInfo.Relations) -> void:
	relations[tile] = relation

# Get the relation between two tiles
func get_edge_relation(tile1: TileInfo, tile2: TileInfo) -> TileInfo.Relations:
	return g[tile1][tile2]

# Add tile to TileGraph
func get_nodes(relation: int = -1) -> Array:
	var nodes := g.keys()
	if TileInfo.Relations.find_key(relation) == null:
		return nodes 
	return nodes.filter(func(node): return relations[node] == relation)

# Get the neighbors of 'tiles'. Optionally filter neighbors by their relation
# 'tiles' is a TileInfo or Array
# neighbors will not include any tile in 'tiles'
func get_neighbors(tiles, relation: int = -1) -> Array:
	var use_relation = TileInfo.Relations.find_key(relation) != null
	if tiles is TileInfo:
		var neighbors: Array = g[tiles].keys()
		if use_relation:
			neighbors = neighbors.filter(func(node): return get_edge_relation(tiles, node) == relation)
		return neighbors
	
	if tiles is Array:
		var neighbors := []
		for tile in tiles:
			var tile_neighbors: Array = g[tile].keys()
			tile_neighbors = tile_neighbors.filter(func(node): return !node.same(tiles))
			if use_relation:
				tile_neighbors = tile_neighbors.filter(func(node): return get_edge_relation(tile, node) == relation)
			neighbors.append_array(tile_neighbors)
		return neighbors
	push_error("Unknown type", typeof(tiles))
	return []

# Get the connected components of each tile in 'tiles'
# Tiles that are connected will only have one array in the output
func get_connected_components(tiles := get_nodes()) -> Array[Array]:
	var visited := {}
	var components: Array[Array] = []
	for tile in tiles:
		if !visited.has(tile):
			var component: Array[TileInfo] = []
			_dfs(tile, component, visited)
			components.append(component)
	return components

# get_connected_components dfs implementation
func _dfs(tile: TileInfo, component: Array[TileInfo], visited: Dictionary) -> void:
		visited[tile] = null
		component.append(tile)
		for neighbor in get_neighbors(tile):
			if !visited.has(neighbor):
				_dfs(neighbor, component, visited)
