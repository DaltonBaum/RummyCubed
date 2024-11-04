class_name TileInfo

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
	Colors.GREEN: Color(0, 0.5, 0)
}

enum Relations {
	INVALID,
	SET,
	RUN
}

@export_range(1, 13) var num: int
@export var color: Colors
@export var deck: int

func _init(n: int, c: Colors, d: int):
	num = n
	color = c
	deck = d

func get_color():
	return _color_dict[color]

func same(other) -> bool:
	return self.num == other.num and self.color == other.color
