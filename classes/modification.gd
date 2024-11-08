class_name Modification


@export var connections: Array
@export var relation: TileInfo.Relations

# Called when the node enters the scene tree for the first time.
func _init(_conns: Array, _relation: TileInfo.Relations):
	connections = _conns
	relation = _relation
