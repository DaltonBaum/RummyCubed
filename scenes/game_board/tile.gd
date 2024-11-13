extends PanelContainer

var info: TileInfo

# Init since this is created with instantiate()
func update_info(i: TileInfo):
	info = i
	%Label.text = "[center][b]%d[/b][/center]" % [info.num]
	%Label.add_theme_color_override("default_color", info.get_color())

func _ready() -> void:
	DragManager.drag_started.connect(_on_drag_start)

# Listener for when a drag is started
func _on_drag_start(pos: Vector2):
	if get_global_rect().has_point(pos):
		DragManager.set_current_node(self)
