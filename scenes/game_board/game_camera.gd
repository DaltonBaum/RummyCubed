#extends Camera2D
#
## Configurable properties for mobile pinch zoom and limits
#@export var stop_on_limit: bool = false
#@export var return_speed: float = 0.15
#@export var fling_action: bool = true
#@export var min_fling_velocity: float = 100.0
#@export var deceleration: float = 2500.0
#@export var min_zoom: float = 0.5
#@export var max_zoom: float = 2.0
#@export var zoom_sensitivity: int = 5
#@export var zoom_increment: Vector2 = Vector2(0.02, 0.02)
#@export var zoom_at_point: bool = true
#@export var move_while_zooming: bool = true
#
## Variables for touch tracking and camera movement
#var last_pinch_distance: float = 0.0
#var velocity_x: float = 0.0
#var velocity_y: float = 0.0
#var is_flying: bool = false
#var duration: float = 0.0001
#var events = {}
#var vp_size = [500, 500]
#var debug_touch_point: Vector2 = Vector2()
#var debug_touch_active: bool = false
#var zooming: bool = false
#var disabled := false
#
#func _ready():
	#_update_viewport_size()
#
#func _process(delta: float):
	#if is_flying:
		#_fling_camera(velocity_x, velocity_y, delta)
	#var x = zoom.x*vp_size.x/2
	#var y = zoom.y*vp_size.y/2
	#position.x = clamp(position.x, limit_left+x, limit_right-x)
	#position.y = clamp(position.y, limit_top+y, limit_bottom-y)
#
## Handle touch inputs for panning and pinch zooming
#func _input(event: InputEvent):
	## Toggle debug touch on key press (e.g., "D" key)
	#if event is InputEventKey and event.is_pressed() and event.keycode == KEY_D:
		#debug_touch_active = !debug_touch_active
		#if debug_touch_active:
			##print("Debug touch has started!")
			#debug_touch_point = get_viewport().size / 2  # Place in the center initially
		#else:
			#last_pinch_distance = 0  # Reset pinch distance when disabling debug touch
		#return
		#
	## Handle drag for the debug touch
	#if debug_touch_active and event is InputEventMouseMotion:
		#debug_touch_point += event.relative
	#
	## Add handling to stop if a tile is currently being dragged
	#if DragManager.is_currently_dragging() == true:
		#return
	#
	#if event is InputEventScreenTouch:
		#if event.is_pressed():
			#events[event.index] = event
			#is_flying = false  # Stop fling when new touch starts
			#if events.size() == 1:
				#last_pinch_distance = 0
		#else:
			#events.erase(event.index)
			#if events.is_empty():
				#if zooming:
					#zooming = false
				#else:
					#_start_fling(event.position, last_pinch_distance)
#
	#elif event is InputEventScreenDrag:
		#if events.size() > 1 or (events.size() == 1 and debug_touch_active):
			#_pinch_zoom_camera(event)
		#elif events.size() == 1:
			#_pan_camera(event.relative)
#
## Camera panning based on a single touch drag
#func _pan_camera(delta: Vector2):
	#if disabled:
		#return
	#position -= delta * zoom
#
## Pinch zooming with multi-touch
#func _pinch_zoom_camera(event: InputEventScreenDrag):
	#if disabled:
		#return
	#zooming = true
	#var touch_points = events.values()
	#var p1 = touch_points[0].position
	#var p2 = 0
	#if debug_touch_active:
		#p2 = debug_touch_point
	#else:
		#if events.size() < 2:
			#return
		#p2 = touch_points[1].position
	#
	#var pinch_distance = p1.distance_to(p2)
	#
	#if last_pinch_distance == 0:
		#last_pinch_distance = pinch_distance
	#if abs(pinch_distance - last_pinch_distance) > zoom_sensitivity:
		##var new_zoom = zoom + zoom_increment * (1 if pinch_distance > last_pinch_distance else -1)
		#var new_zoom = Vector2(clamp(zoom.x + zoom_increment.x * (1 if pinch_distance > last_pinch_distance else -1), min_zoom, max_zoom),clamp(zoom.y + zoom_increment.y * (1 if pinch_distance > last_pinch_distance else -1), min_zoom, max_zoom))
		#zoom = new_zoom
		#last_pinch_distance = pinch_distance
#
## Trigger fling effect if swipe was fast enough
#func _start_fling(end_position: Vector2, initial_distance: float):
	#if disabled:
		#return
	#if fling_action and (initial_distance >= min_fling_velocity) and zooming == false:
		#is_flying = true
		#duration = initial_distance / deceleration
		#velocity_x = end_position.x / duration
		#velocity_y = end_position.y / duration
#
## Decelerate fling over time
#func _fling_camera(vx: float, vy: float, delta: float):
	#if disabled:
		#return
	#duration -= delta
	#if duration > 0.0:
		#position += Vector2(vx, vy) * delta
	#else:
		#is_flying = false
#
## Update viewport size on resize
#func _update_viewport_size():
	#set_process_unhandled_input(true)
	#vp_size = get_viewport().size


# Style Number 2 


extends Camera2D


enum TrackpadPanBehavior { ZOOM, PAN }


@export var stop_on_limit: bool = true
@export var return_speed: float = 0.15
@export var fling_action: bool = true
@export var min_fling_velocity: float = 100.0
@export var deceleration: float = 2500.0
@export var min_zoom: float = 0.5
@export var max_zoom: float = 2
@export var zoom_sensitivity: int = 5
@export var zoom_increment: Vector2 = Vector2(0.02, 0.02)
@export var zoom_at_point: bool = true
@export var move_while_zooming: bool = false
@export var handle_mouse_events: bool = true
@export var mouse_zoom_increment: Vector2 = Vector2(0.1, 0.1)
@export var trackpad_pan_behavior = TrackpadPanBehavior.PAN
@export var trackpad_pan_speed: float = 10

var last_pinch_distance: float = 0
var events = {}

# Viewport size
var vp_size := Vector2.ZERO
var limit_target := position
var base_limits := Rect2(limit_left, limit_top, limit_right, limit_bottom)
var valid_limit := Rect2(0, 0, 0, 0)

# Initial velocity of the fling
var velocity_x: float = 0.0
var velocity_y: float = 0.0

# The Start and end positive of the fling
var start_position := Vector2.ZERO
var end_position := Vector2.ZERO

# Fling related variables
var fling_time: float = 0.0001
var ignore_fling : bool = false
var is_flying: bool = false
var is_moving: bool = false

var duration: float = 0.0001
var dx: float = 0.0
var dy: float = 0.0
var zoomed_to_min = false
var zoomed_to_max = false

# Connects the viewport signal
func _ready() -> void:
	_on_viewport_size_changed()
	calculate_valid_limits()
	get_viewport().connect("size_changed", Callable(self, "_on_viewport_size_changed"))
	set_stop_on_limit(stop_on_limit)

func _process(_delta) -> void:
	# Return camera to valid limits
	if not stop_on_limit and events.size() == 0:
		position = lerp(position, limit_target, return_speed)

	# If the camera is moving, update the duration
	if is_moving:
		duration += _delta

	# If the camera is flying, set the next camera's position considering the velocity
	if is_flying:
		fling(velocity_x, velocity_y, _delta)
	
	# Constrain camera position
	var x = vp_size.x / 2 / zoom.x
	var y = vp_size.y / 2 / zoom.y
	position.x = clamp(position.x, limit_left+x, limit_right-x)
	position.y = clamp(position.y, limit_top+y, limit_bottom-y)

func _input(event: InputEvent) -> void:
	# Add handling to stop if a tile is currently being dragged
	if DragManager.is_currently_dragging() == true:
		return

	if event is InputEventScreenTouch:
		var i = event.index

		if event.is_pressed():
			events[i] = event
			# If there is more than one finger at the screen, ignores the fling action
			if events.size() > 1:
				ignore_fling = true

			# Sets the camera as moving if the fling action is activated
			is_moving = fling_action
			if events.size() == 1:
				# Stores the event start position to calculate the velocity later
				start_position = event.position
				end_position = start_position
				last_pinch_distance = 0

			# In case the camera was flying, stops it
			finish_flying()

		# If it's not pressed
		else:
			if duration > 0 and is_moving and not ignore_fling:
				is_moving = false

				# If the fling action is activated and it's not to ignore the fling action
				if fling_action and not ignore_fling:
					if was_flinged(start_position, end_position, fling_time):
						is_flying = true

			# Erases this event from the dictionary
			events.erase(i)

			# The fling action will be ignored until the last finger leave the screen
			if events.size() == 0:
				ignore_fling = false
				is_moving = false

	if event is InputEventScreenDrag:
		if duration > 0.02 and is_moving and not ignore_fling:
			fling_time = duration
			duration = 0.0001
			start_position = end_position
			end_position = event.position
			

		var last_pos: Vector2 = events[event.index].position
		if last_pos.distance_to(event.position) > zoom_sensitivity:
			events[event.index] = event

		if events.size() == 1:
			update_position(position - event.relative * zoom)

		if events.size() > 1:
			# Stores the touches position
			var keys = events.keys()
			var p1: Vector2 = events[keys[0]].position
			var p2: Vector2 = events[keys[1]].position

			# Calculates the distance between them
			var pinch_distance: float = p1.distance_to(p2)
			if last_pinch_distance == 0:
				last_pinch_distance = pinch_distance


			if abs(pinch_distance - last_pinch_distance) > zoom_sensitivity:
				var new_zoom: Vector2
				if (pinch_distance < last_pinch_distance):
					new_zoom = zoom + zoom_increment * zoom
				else:
					new_zoom = zoom - zoom_increment * zoom

				if zoom_at_point:
					zoom_at(new_zoom, (p1 + p2) / 2)
				else:
					# Otherwise, just updates de camera's zoom
					zoom_at(new_zoom, position)

				last_pinch_distance = pinch_distance


# Updates the reference vp_size properly when the viewport change size
func _on_viewport_size_changed() -> void:
	var viewport := get_viewport()
	vp_size = viewport.get_visible_rect().size



func was_flinged(start_p: Vector2, end_p: Vector2, dt: float) -> bool:
	var vi: float = start_p.distance_to(end_p) / dt
	duration = vi / deceleration

	if vi >= min_fling_velocity:
		velocity_x = (start_p.x - end_p.x) / dt
		velocity_y = (start_p.y - end_p.y) / dt
		dx = velocity_x / duration
		dy = velocity_y / duration
		return true

	else:
		return false


func fling(vx: float, vy: float, dt: float) -> void:
	duration -= dt
	if duration > 0.0:
		if position.x > valid_limit.size.x or position.x < valid_limit.position.x:
			dx = velocity_x / 0.2
		if position.y > valid_limit.size.y or position.y < valid_limit.position.y:
			dy = velocity_y / 0.2

		# Calculates the next camera's position for both axis
		var npx = position.x + vx * dt
		var npy = position.y + vy * dt

		# Moves the camera to the next position
		update_position(Vector2(npx, npy))

		# Calculates the next velocity for both axis considering the deceleration
		velocity_x = vx - dx * dt
		velocity_y = vy - dy * dt

	else:
		finish_flying()

func finish_flying() -> void:
	is_flying = false
	duration = 0.0
	velocity_x = 0.0
	velocity_y = 0.0

func apply_zoom(new_zoom: Vector2) -> void:
	zoomed_to_min = false
	zoomed_to_max = false

	if new_zoom.x <= min_zoom:
		zoomed_to_min = true
		zoom = Vector2(min_zoom, min_zoom)
		return

	if new_zoom.x >= max_zoom:
		zoomed_to_max = true
		zoom = Vector2(max_zoom, max_zoom)
		return

	new_zoom.x = clamp(new_zoom.x, min_zoom, max_zoom)
	zoom = Vector2.ONE * new_zoom.x

	calculate_valid_limits()


func zoom_at(new_zoom: Vector2, point: Vector2) -> void:
	# In case the camera was flying, stops it
	finish_flying()

	var zoom_diff: Vector2
	zoom_diff = new_zoom - zoom

	if anchor_mode == ANCHOR_MODE_DRAG_CENTER:
		point -= vp_size/2

	apply_zoom(new_zoom)

	if !zoomed_to_min and !zoomed_to_max:
		update_position(position - (point * zoom_diff))


# Returns if the camera's position is out of the valid limit
func is_camera_out_of_limit() -> bool:
	return (position.x < valid_limit.position.x
				or position.x > valid_limit.size.x
				or position.y < valid_limit.position.y
				or position.y > valid_limit.size.y)


func calculate_valid_limits() -> void:
	var offset: Vector2
	valid_limit.position = base_limits.position
	valid_limit.size = base_limits.size

	if anchor_mode == ANCHOR_MODE_DRAG_CENTER:
		offset = vp_size / 2
		valid_limit.position += offset * zoom

	elif anchor_mode == ANCHOR_MODE_FIXED_TOP_LEFT:
		offset = vp_size

	valid_limit.size -= offset * zoom


# Sets the camera's position making sure it stays between the limits
func update_position(new_position: Vector2) -> void:
	if stop_on_limit:
		position.x = clamp(new_position.x, valid_limit.position.x, valid_limit.size.x)
		position.y = clamp(new_position.y, valid_limit.position.y, valid_limit.size.y)

	else:
		position.x = new_position.x
		position.y = new_position.y
		limit_target.x = clamp(new_position.x, valid_limit.position.x, valid_limit.size.x)
		limit_target.y = clamp(new_position.y, valid_limit.position.y, valid_limit.size.y)

func set_stop_on_limit(stop: bool) -> void:
	stop_on_limit = stop
	if stop_on_limit:
		limit_left = base_limits.position.x as int
		limit_top = base_limits.position.y as int
		limit_right = base_limits.size.x as int
		limit_bottom = base_limits.size.y as int
	else:
		limit_left = -10000000
		limit_top = -10000000
		limit_right = 10000000
		limit_bottom = 10000000
