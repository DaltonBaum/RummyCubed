extends PanelContainer

var info: TileInfo

func update_info(i: TileInfo):
	info = i
	%Label.text = str(info.num)
	%Label.add_theme_color_override("font_color", info.get_color())

func _ready() -> void:
	DragManager.drag_started.connect(_on_drag_start)

func _on_drag_start(pos: Vector2):
	if get_global_rect().has_point(pos):
		DragManager.set_current_node(self)
