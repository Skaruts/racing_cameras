@tool
class_name RacingChaseCamera
extends RacingCamera

## A camera that chases the car and spins around to face the direction of movement.
##[br][br]
## Must be child of the car node.
##
## A camera that chases the car and spins around to face the direction of
## movement, smoothly or rigidly, depending on the selected [enum ChaseMode].
##[br][br]
## The mouse wheel can also be used to change the camera's distance
## from the car.
##[br][br]
## [color=white][b]Note:[/b][/color] the mouse controls will only work if the
## mouse is captured. The mouse can be captured by left-clicking, or uncaptured
## by pressing [code]escape[/code].
##[br][br]
## [color=white][b]Note:[/b][/color] This camera must be a child of the car node.
## If the car node is the scene root or the immediate parent, then the camera
## will automatically detect it. Otherwise the car node must be set manually,
## either by setting [member RacingCamera.follow_car] in the inspector, or using
## [method RacingCamera.set_car] through code.
##[br][br]
## In order for this camera to work properly, it needs to know state of the
## steering input (it will still work without this, but with some minor
## inconsistencies). This means that the car node should define the method
## [code]get_steering_input[/code].
## [codeblock]
## func get_steering_input() -> float:
##     return steer_input
##
## func _process(delta: float) -> void:
##    steer_input = Input.get_axis("turn_right", "turn_left")
## [/codeblock]
## The return value should be a [param float] between [code]-1[/code]
## and [code]1[/code], and the steering direction may have be corrected/negated
## to point in the right direction, depending on the implementation.
##[br][br]
## The intended result is that the camera always rotates around the opposite
## side that the wheels are turning to, such that it will more quickly provide
## visibility in that direction (see the plugin examples). E.g., if the car is
## turning left, the camera will rotate by the right side, and vice-versa.


## Emitted whenever this camera changes mode.
signal mode_changed(mode_name: String)


enum ChaseMode {
	SMOOTH,         ## The camera will very slowly adjust to face the direction of movement.
	SOFT,           ## The camera will softly adjust to face the direction of movement.
	RIGID,          ## The camera will always face the exact direction of movement.
	FIXED,          ## The camera is fixed and will not spin around to face the direction of movement.
}
var _curr_mode:ChaseMode

@export var chase_mode         : ChaseMode = ChaseMode.SOFT  ## The chase mode that this camera should use.
@export var default_distance   : float = 5.0    ## The default camera distance from the car.
#@export var camera_height:float = 2
@export var origin_offset      : float = 1      ## The vertical offset from the car's origin that the camera will look at.
@export var cam_speed          : float = 0.2    ## How fast the camera moves toward or away from the car, when turning the mouse wheel.
@export var min_height         : float = 1      ## The minimum camera height.
@export var max_height         : float = 4      ## The maximum camera height.
@export var min_distance       : float = 2.5    ## The minimum distance to the car.
@export var max_distance       : float = 10     ## The maximum distance to the car.
@export var invert_mouse_wheel : bool = false   ## Invert mouse wheel movement.


var _lerp_look_weight:float = 0.05
var _lerp_pos_weight:float  = 0.1
var _lerp_rot_weight:float  = 0.035

const _LOOK_WEIGHTS := {
	ChaseMode.SMOOTH : 0.01,
	ChaseMode.SOFT   : 0.05,
	ChaseMode.RIGID  : 0.5,
	ChaseMode.FIXED  : 0.9,
}

const _ROT_WEIGHTS := {
	ChaseMode.SMOOTH : 0.015,
	ChaseMode.SOFT   : 0.03,
	ChaseMode.RIGID  : 0.05,
	ChaseMode.FIXED  : 0.1,
}

var _target_rot   : float
var _curr_heading : int
var _new_heading  : int
var _piv_diff     : float

var _pivot:Node3D
var _dest_cam_pos: Vector3


func _on_enter_tree() -> void:
	camera_name = "Chase Camera"
	_type = "RacingChaseCamera"

	top_level = true

	_pivot = Node3D.new()
	_cam = Camera3D.new()
	add_child(_pivot)
	_pivot.add_child(_cam)

	_init_car_from_owner()



func _on_ready() -> void:
	max_height = max(max_height, min_height) # just in case the max is smaller than the min
	max_distance = max(max_distance, min_distance)

	_dest_cam_pos = Vector3(0, min_height, default_distance)
	_cam.position = _dest_cam_pos

	switch_mode(chase_mode, false, true)

	if not _car_base.has_method("get_steering_input"):
		push_warning("vehicle script has no method 'get_steering_input' (this will cause some minor inconsistencies in the camera's behavior).")


func _on_process(delta: float) -> void:
	if _cam.position != _dest_cam_pos:
		_cam.position.z = lerp(_cam.position.z, _dest_cam_pos.z, 0.1)

		# correct height while zooming, to prevent pitching
		# down to the car when too close
		var zoom_range := max_distance-min_distance
		var height_range := max_height-min_height
		var curr_z_perc := (_cam.position.z-min_distance) / zoom_range

		var y := curr_z_perc * height_range + min_height
		#var y := _dest_cam_pos.y
		_cam.position.y = lerp(_cam.position.y, y , 0.1)

	_do_rotating_camera(delta)


func _on_unhandled_input(event: InputEvent) -> void:
	if _shared.next_cam_pos_key_pressed(event):
		next_mode()
	elif _shared.prev_cam_pos_key_pressed(event):
		previous_mode()

	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return

	_check_mouse_wheel(event)


func _check_mouse_wheel(event:InputEvent) -> void:
	if event is InputEventMouseButton:
		var step := cam_speed
		if Input.is_key_pressed(KEY_SHIFT): step *= 2
		if Input.is_key_pressed(KEY_CTRL):  step /= 2

		if not invert_mouse_wheel:
			if   event.button_index == MOUSE_BUTTON_WHEEL_UP:   _dest_cam_pos.z -= step
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN: _dest_cam_pos.z += step
		else:
			if   event.button_index == MOUSE_BUTTON_WHEEL_UP:   _dest_cam_pos.z += step
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN: _dest_cam_pos.z -= step

		_dest_cam_pos.z = clamp(_dest_cam_pos.z, min_distance, max_distance)


func _on_set_active() -> void:
	_cam.current = _active
	set_process_unhandled_input(_active)


## Switch to the next mode available.
func next_mode(emit:=true) -> void:
	switch_mode(wrapi(_curr_mode+1, 0, ChaseMode.size()), emit)


## Switch to the previous mode available.
func previous_mode(emit:=true) -> void:
	switch_mode(wrapi(_curr_mode-1, 0, ChaseMode.size()), emit)


## Switch camera mode to the mode [param index]. This
## function will do nothing if the new mode is the same as the current mode,
## unless the parameter [param force_change] is [code]true[/code].
##[br][br]
## If [param emit] is [code]true[/code], it will emit the [signal mode_changed] signal.
func switch_mode(index:ChaseMode, emit:=true, force_change:=false) -> void:
	if index == _curr_mode and not force_change: return

	_curr_mode = index
	_lerp_look_weight = _LOOK_WEIGHTS[index]
	_lerp_rot_weight = _ROT_WEIGHTS[index]

	if emit:
		mode_changed.emit(ChaseMode.keys()[index])



func _do_rotating_camera(_delta: float) -> void:
	if not _car_body: return

	# adjust root
	global_position = global_position.lerp(_car_body.global_position, _lerp_pos_weight)
	global_rotation.y = lerp_angle(global_rotation.y, _car_body.global_rotation.y, _lerp_look_weight)

	# adjust _pivot
	var car_rot:float = _car_body.global_rotation_degrees.y

	if _curr_mode != ChaseMode.FIXED:
		_piv_diff = wrapf(_pivot.global_rotation_degrees.y - car_rot, -180, 180)
		_new_heading = sign(_car_body.linear_velocity.normalized().dot(-_car_body.global_basis.z))

		# this means the _pivot will need to change direction of rotation
		if _new_heading != 0 and _new_heading != _curr_heading:
			# prevent turning the camera when the car is going back and forth near zero movement
			if _car_body.linear_velocity.length() > 0.25:
				_target_rot = _calc_target_rotation()
				_curr_heading = _new_heading
	else:
		_target_rot = 0

	_pivot.rotation_degrees.y = lerp(_pivot.rotation_degrees.y, _target_rot, _lerp_rot_weight)

	# adjust camera
	var offset := Vector3(0, origin_offset, 0)
	var look_target := _car_body.global_position + offset

	# prevent looking at if direction is aligned with up vector
	if Vector3.UP != _cam.global_position.direction_to(look_target):
		_cam.look_at(look_target, Vector3.UP)


func _calc_target_rotation() -> float:
	var rot := _target_rot

	var steering_dir:float
	if _car_base.has_method("get_steering_input"):
		steering_dir = _car_base.get_steering_input()
	else:
		var dotp: float = _car_body.linear_velocity.normalized().dot(_car_body.global_basis.x)
		steering_dir = sign(dotp) if abs(dotp) > 0.001 else 0
		steering_dir *= _new_heading # correct for this being inverted when reversing

		#var car_rot:float = -(last_rot - _car_body.global_rotation.y)  * _curr_heading
		#var steering_dir: int = 0 if abs(car_rot) < 0.01 else sign(car_rot)
		#logs.print(car_rot, steering_dir)

	if _new_heading < 0:  # reverse
		if   steering_dir > 0: rot =  180
		elif steering_dir < 0: rot = -180
		elif _piv_diff > 0:    rot =  180
		elif _piv_diff < 0:    rot = -180
	else:                 # forward
		rot = 0
		if steering_dir > 0:
			if _pivot.rotation_degrees.y < 0:
				_pivot.rotation_degrees.y = 360 + _pivot.rotation_degrees.y
		elif steering_dir < 0:
			if _pivot.rotation_degrees.y > 0:
				_pivot.rotation_degrees.y = -360 + _pivot.rotation_degrees.y
		elif _piv_diff > 0:
			if _pivot.rotation_degrees.y < 0:
				_pivot.rotation_degrees.y = 360 + _pivot.rotation_degrees.y
		elif _piv_diff <= 0:
			if _pivot.rotation_degrees.y >= 0:
				_pivot.rotation_degrees.y = -360 + _pivot.rotation_degrees.y

	return rot

