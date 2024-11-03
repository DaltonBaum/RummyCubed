extends GridContainer

@export var grid_width := 15
@export var grid_height := 15
var tile_scene := preload("res://scenes/game_board/tile.tscn")
var tile_slot_scene := preload("res://scenes/game_board/tile_slot.tscn")

func _ready() -> void:
	columns = grid_width
	for i in grid_width * grid_height:
		add_child(tile_slot_scene.instantiate())
	
	var a: Array[Array] = []
	for c in TileInfo.Colors.values():
		var b: Array[TileInfo] = []
		for i in range(1, 14):
			b.append(TileInfo.new(i, c))
		a.append(b)
		a.append(b)
	add_tile_groups(a)

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
