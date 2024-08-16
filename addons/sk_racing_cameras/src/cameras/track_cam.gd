@tool
class_name RacingTrackCamera
extends RacingCamera


## A race-track camera, that automatically changes between the available
## positions to follow the car.
##[br][br]
## Must [color=ff5c5c]NOT[/color] be child of the car node, and its positions
## on the track should be marked by child nodes (use cameras, so you can preview them).
##
## The track-camera allows having multiple camera views (positions) all around a track, and
## it will automatically change between them to follow the target car, unless
## [member auto_switch] is [code]false[/code], in which case it can be
## controlled manually.
##
##[br][br]
## The positions must be marked by child nodes of this camera. The nodes can be
## of any [Node3D] type, but it's more convenient to use [Camera3D], as they
## can be previewed in the editor.
##
##[br][br]
## [color=white][b]Note:[/b][/color] this camera will not care if the child
## nodes are [RacingCamera] types, but their usage for this is discouraged, as
## there may be some potential for weird things to happen.
##
##[br][br]
## By default the track camera omits the position names, as they are usually not
## relevant, but the names can still be displayed by setting
## [member emit_position_names] to [code]true[/code]. The names of the child
## nodes are the names that will appear on screen when you change positions.
## The names will be capitalized if they're not already; e.g., [code]hairpin_camera[/code]
## will display as [code]Hairpin Camera[/code].
##
## [br][br]
## The [RacingCameraManager] should be able to assign the default car to this
## camera at startup, so it may not be be necessary to set it manually. If
## needed, it can be assigned to the [member RacingCamera.follow_car] in the
## inspector, or by using [method RacingCamera.set_car] through code.
##
## [br][br]
## When using multiple cars, the current car should be assigned to the
## [RacingCameraManager], which will make sure all cameras are properly notified.


## Emitted whenever this camera changes position. See [method switch_position].
signal position_changed(position_name: String)

const _CONF_WARNING_NO_CHILD_NODES = "The track-camera requires child nodes marking the camera positions around the race-track."

var _camera_positions:Array[CameraPosition]
var _curr_position:int

var _prev_closest_pos_idx := -1
var _closest_pos_idx:int = 0

var _should_change_position := false

# cooldown period to prevent cameras from swapping too fast when the player
# is right between them
var _pos_change_cooldown := 2.0
var _pos_change_timer := 0.0

var _target:Node3D


## If [code]true[/code], this camera will emit the position names when changing
## position. Normally you may want this turned off, as track-camera position
## names are usually irrelevant.
@export var emit_position_names := false

## Whether the camera should automatically switch between the available
## positions. Turn this off to have manual control.
@export var auto_switch:bool = true:
	get: return auto_switch
	set(enable):
		auto_switch = enable
		set_process(enable)




func _on_enter_tree() -> void:
	camera_name = "Track Camera"
	_type = "RacingTrackCamera"
	_cam = Camera3D.new() # don't add as child before freeing the child cameras in '_ready'
	# TODO: is this still an issue?


func _on_ready() -> void:
	_init_positions()
	add_child(_cam)
	if follow_car != null:
		set_car(follow_car)
		_internal_switch_position(0, false)


func _get_configuration_warnings() -> PackedStringArray:
	if follow_car and not _is_node_valid_car(follow_car):
		return [_CONF_WARNING_FOLLOW_CAR_INVALID]
	if get_child_count() == 0:
		return [_CONF_WARNING_NO_CHILD_NODES]
	return []


func _on_process(delta: float) -> void:
	if not _target: return
	if _pos_change_timer > 0:
		_pos_change_timer -= delta

	_calculate_closest_camera()

	if auto_switch and _should_change_position and _pos_change_timer <= 0:
		_change_camera(delta)

	# prevent looking at if direction is aligned with up vector
	if Vector3.UP != _cam.global_position.direction_to(_target.global_position):
		_cam.look_at(_target.global_position, Vector3.UP)


func _on_unhandled_input(event: InputEvent) -> void:
	if _shared.next_cam_pos_key_pressed(event):
		next_position()
	elif _shared.prev_cam_pos_key_pressed(event):
		previous_position()


func _on_set_car() -> void:
	_target = _car_body


func _on_set_active() -> void:
	_cam.current = _active
	set_process_unhandled_input(not auto_switch and _active)




#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
#		public
#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
## Switch to the next position available. See [method switch_position].
func next_position(emit:=true) -> void:
	if auto_switch: return
	switch_position(wrapi(_curr_position+1, 0, _camera_positions.size()), emit)


## Switch to the previous position available. See [method switch_position].
func previous_position(emit:=true) -> void:
	if auto_switch: return
	switch_position(wrapi(_curr_position-1, 0, _camera_positions.size()), emit)


## Switch camera position to the position [param index]. This
## function will do nothing if the new position is the same as the current position,
## unless the parameter [param force_change] is [code]true[/code].
##[br][br]
## If [param emit] is [code]true[/code], it will emit the [signal position_changed] signal.
##[br][br]
## [color=white]Note:[/color] unlike other cameras, in this case [param emit] is [code]false[/code] by default.
func switch_position(index:int, emit:=false, force_change:=false) -> void:
	if auto_switch: return
	if index == _curr_position and not force_change: return
	_internal_switch_position(index, emit)




#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
#		private
#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
func _internal_switch_position(idx:int, emit:=false) -> void:
	if _camera_positions.size() == 0: return
	_curr_position = idx
	_cam.global_position = _camera_positions[idx].pos

	if emit_position_names or emit:
		position_changed.emit(_camera_positions[idx].name)


func _init_positions() -> void:
	for c in get_children():
		var cp := CameraPosition.new(c.name.capitalize(), c.global_position)
		_camera_positions.append(cp)
		c.free()

	if _camera_positions.size() == 0:
		push_warning("no positions were specified for track camara")


func _change_camera(_delta:float) -> void:
	_pos_change_timer = _pos_change_cooldown
	_should_change_position = false
	_prev_closest_pos_idx = _closest_pos_idx
	_internal_switch_position(_closest_pos_idx, emit_position_names)


func _calculate_closest_camera() -> void:
	if not _target:return

	var closest:float = 99999999

	for i in _camera_positions.size():
		var dist:float = _camera_positions[i].pos.distance_to(_target.global_position)
		if dist < closest:
			closest = dist
			_closest_pos_idx = i

	_should_change_position = _prev_closest_pos_idx != _closest_pos_idx


