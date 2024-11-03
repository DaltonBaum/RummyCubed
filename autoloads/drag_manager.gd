extends Node

signal drag_started
signal drag_ended

var holder := Marker2D.new()

var _active_touches := {}
var _current_node: Node = null
var _current_parent: Node = null

func _ready() -> void:
	add_child(holder)

func _input(event):
	if event is InputEventScreenDrag:
		print(_get_pos_with_camera(event.position))
		holder.position = event.position

	if event is InputEventScreenTouch:
		if event.pressed:
			_active_touches[event.index] = event.position
			if _active_touches.size() == 1:
				drag_started.emit(event.position)
			else:
				_on_drag_cancel()
		else:
			if _active_touches.size() == 1 and event.index in _active_touches:
				_on_drag_end(event.position)
			_active_touches.erase(event.index)

func set_current_node(node: Node) -> void:
	if _current_node != null:
		push_error("Current node set while already active")
	_current_node = node
	_current_parent = _current_node.get_parent()
	print(_get_pos_with_camera(_current_node.get_global_rect().get_center()))
	holder.position = _get_pos_with_camera(_current_node.get_global_rect().get_center())
	_current_node.reparent(holder)

func _on_drag_end(pos: Vector2) -> void:
	if _current_node != null:
		drag_ended.emit(pos, _current_node, _current_parent)
		if _current_node.get_parent() == holder:
			_current_node.reparent(_current_parent)
		_reset_current()

func _on_drag_cancel() -> void:
	_current_node.reparent(_current_parent)
	_reset_current()

func _reset_current() -> void:
	_current_node = null
	_current_parent = null

func _get_pos_with_camera(pos: Vector2) -> Vector2:
	var new_pos := pos
	#new_pos += Vector2(get_window().size) / 2
	new_pos -= get_viewport().get_camera_2d().get_screen_center_position()
	return new_pos
