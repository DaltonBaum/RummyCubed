class_name Modification


@export var connection: Array
@export var relation: TileInfo.Relations

# Called when the node enters the scene tree for the first time.
func _init(_conn: Array, _relation: TileInfo.Relations):
	connection = _conn
	relation = _relation
