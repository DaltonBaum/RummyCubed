extends PanelContainer


signal tile_added
signal tile_removed

var index := -1
static var default_style := preload("res://resources/tiles/slot.tres")
static var invalid_style := preload("res://resources/tiles/invalid_slot.tres")

func _ready() -> void:
	DragManager.drag_ended.connect(_on_drag_end)
	child_entered_tree.connect(_on_child_enter)
	child_exiting_tree.connect(_on_child_exit)

func _on_drag_end(pos: Vector2, node: Node, parent: Node) -> void:
	if get_global_rect().has_point(pos):
		for child in get_children():
			child.reparent(parent)
		node.reparent(self)

func _on_child_enter(_n: Node) -> void:
	tile_added.emit(index)

func _on_child_exit(_n: Node) -> void:
	tile_removed.emit(index)

func get_info() -> TileInfo:
	if len(get_children()) == 0:
		return null
	return get_child(0).info

func set_invalid(is_invalid: bool) -> void:
	theme = invalid_style if is_invalid else default_style
