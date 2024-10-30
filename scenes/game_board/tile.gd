extends Panel

var info: TileInfo
var tile_scene := preload("res://scenes/game_board/tile.tscn")
var is_dragged = false

func _ready():
	pass

func update_info(i: TileInfo):
	info = i
	%Label.text = str(info.num)
	%Label.add_theme_color_override("font_color", info.get_color())

func _get_drag_data(at_position: Vector2) -> Variant:
	set_drag_preview(make_drag_preview())
	hide()
	is_dragged = true
	return self

func make_drag_preview() -> Control:
	var tile := tile_scene.instantiate()
	tile.update_info(info)
	tile.modulate.a = 0.9
	tile.size = Vector2(36, 60)
	tile.position = -0.5 * tile.size
	
	var c := Control.new()
	c.add_child(tile)
	return c

func _notification(what:int) -> void:
	if what == NOTIFICATION_DRAG_END and is_dragged:
		is_dragged = false
		show()
