extends PanelContainer


func _ready() -> void:
	DragManager.drag_ended.connect(_on_drag_end)

func _on_drag_end(pos: Vector2, node: Node, parent: Node) -> void:
	if get_global_rect().has_point(pos):
		for child in get_children():
			child.reparent(parent)
		node.reparent(self)
