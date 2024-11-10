extends Camera2D

# Configurable properties for mobile pinch zoom and limits
@export var stop_on_limit: bool = false
@export var return_speed: float = 0.15
@export var fling_action: bool = true
@export var min_fling_velocity: float = 100.0
@export var deceleration: float = 2500.0
@export var min_zoom: float = 0.5
@export var max_zoom: float = 2.0
@export var zoom_sensitivity: int = 5
@export var zoom_increment: Vector2 = Vector2(0.02, 0.02)
@export var zoom_at_point: bool = true
@export var move_while_zooming: bool = true
@export var is_tile_dragging: bool = false

# Variables for touch tracking and camera movement
var last_pinch_distance: float = 0.0
var velocity_x: float = 0.0
var velocity_y: float = 0.0
var is_flying: bool = false
var duration: float = 0.0001
var events = {}
var vp_size = [500, 500]

func _ready():
	_update_viewport_size()

func _process(delta: float):
	if is_flying:
		_fling_camera(velocity_x, velocity_y, delta)

# Handle touch inputs for panning and pinch zooming
func _input(event: InputEvent):
	# Add handling to stop if a tile is currently being dragged
	
	if event is InputEventScreenTouch:
		if event.is_pressed():
			events[event.index] = event
			is_flying = false  # Stop fling when new touch starts
			if events.size() == 1:
				last_pinch_distance = 0
		else:
			events.erase(event.index)
			if events.is_empty():
				_start_fling(event.position, last_pinch_distance)

	elif event is InputEventScreenDrag:
		if events.size() == 1:
			_pan_camera(event.relative)
		elif events.size() > 1:
			_pinch_zoom_camera(event)

# Camera panning based on a single touch drag
func _pan_camera(delta: Vector2):
	position -= delta * zoom

# Pinch zooming with multi-touch
func _pinch_zoom_camera(event: InputEventScreenDrag):
	var touch_points = events.values()
	var p1 = touch_points[0].position
	var p2 = touch_points[1].position
	var pinch_distance = p1.distance_to(p2)
	
	if last_pinch_distance == 0:
		last_pinch_distance = pinch_distance
	if abs(pinch_distance - last_pinch_distance) > zoom_sensitivity:
		var new_zoom = zoom + zoom_increment * (pinch_distance > last_pinch_distance if 1 else -1)
		new_zoom = new_zoom.clamped(min_zoom, max_zoom)
		zoom = new_zoom
		last_pinch_distance = pinch_distance

# Trigger fling effect if swipe was fast enough
func _start_fling(end_position: Vector2, initial_distance: float):
	if fling_action and (initial_distance >= min_fling_velocity):
		is_flying = true
		duration = initial_distance / deceleration
		velocity_x = end_position.x / duration
		velocity_y = end_position.y / duration

# Decelerate fling over time
func _fling_camera(vx: float, vy: float, delta: float):
	duration -= delta
	if duration > 0.0:
		position += Vector2(vx, vy) * delta
	else:
		is_flying = false

# Update viewport size on resize
func _update_viewport_size():
	set_process_unhandled_input(true)
	vp_size = get_viewport().size
