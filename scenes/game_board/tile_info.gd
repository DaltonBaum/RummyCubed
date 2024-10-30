class_name TileInfo
extends Resource

enum Colors {
	RED,
	BLUE,
	BLACK,
	GREEN
}

const _color_dict = {
	Colors.RED: Color(0.8, 0, 0),
	Colors.BLUE: Color(0, 0, 0.8),
	Colors.BLACK: Color(0, 0, 0),
	Colors.GREEN: Color(0, 0.8, 0)
}

@export_range(1, 13) var num: int
@export var color: Colors

func _init(n: int, c: Colors):
	num = n
	color = c

func get_color():
	return _color_dict[color]
