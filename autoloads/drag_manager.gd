# -------------------------
# Custom manager for dragging and dropping tiles
# -------------------------
extends Node

signal drag_started
signal drag_ended

# Holds the tile while its being dragged
var holder := Marker2D.new()
var holder_target := Vector2.ZERO
var holder_delay := 25

var _active_touches := {}
var _current_node: Node = null
var _current_parent: Node = null

var disabled := false

func _ready() -> void:
	add_child(holder)

# Smooths motion
func _process(delta: float) -> void:
	if is_currently_dragging():
		var tween := get_tree().create_tween()
		tween.tween_property(holder, "position", holder_target, holder_delay * delta)

func _input(event):
	# Update drag position
	if event is InputEventScreenDrag and is_currently_dragging():
		holder_target = _get_pos_with_camera(event.position)

	# Send out signals for drag events
	# Only allows 1 finger dragging
	if event is InputEventScreenTouch:
		if event.pressed:
			_active_touches[event.index] = event.position
			if _active_touches.size() == 1 and !disabled:
				drag_started.emit(_get_pos_with_camera(event.position))
			else:
				_on_drag_cancel()
		else:
			if _active_touches.size() == 1 and event.index in _active_touches:
				_on_drag_end(_get_pos_with_camera(event.position))
			_active_touches.erase(event.index)

# Method for nodes that got picked up to call
# Only one should ever be picked up at a time
func set_current_node(node: Node) -> void:
	if _current_node != null:
		push_error("Current node set while already active")
	_current_node = node
	_current_parent = _current_node.get_parent()
	holder.position = _current_node.get_global_rect().get_center()
	holder_target = holder.position
	_current_node.reparent(holder)

# Ends a drag by trying to drop it
# Reverts to original position if nothing takes it
func _on_drag_end(pos: Vector2) -> void:
	if _current_node != null:
		drag_ended.emit(pos, _current_node, _current_parent)
		if _current_node.get_parent() == holder:
			_current_node.reparent(_current_parent)
		_reset_current()

# Cancels drag by sending node back to its original parent
func _on_drag_cancel() -> void:
	if _current_node != null:
		_current_node.reparent(_current_parent)
		_reset_current()

# Resets the data for the node being dragged
func _reset_current() -> void:
	_current_node = null
	_current_parent = null

# Convert touch position from screen space to global world space
# WILL THROW ERRORS IF THERE IS NO CAMERA2D
func _get_pos_with_camera(pos: Vector2) -> Vector2:
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return pos
	return get_viewport().get_camera_2d().get_canvas_transform().affine_inverse() * pos

# Is the manager currently handling a tile
func is_currently_dragging() -> bool:
	return _current_node != null

# Public function for canceling current drag
func cancel_drag() -> void:
	_on_drag_cancel()
