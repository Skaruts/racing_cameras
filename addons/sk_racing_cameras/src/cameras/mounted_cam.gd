@tool
class_name RacingMountedCamera
extends RacingCamera

## A camera that is mounted on the vehicle, which can cycle through multiple user-defined positions
## (hood view, side view, etc).
## [br][br]
## Must be child of the vehicle node, and its positions must be marked by child
## nodes (use cameras, so you can preview them).
##
## A camera that is mounted on the vehicle, which can cycle through multiple
## user-defined positions around (or in) the vehicle.
##
##[br][br]
## The positions must be marked by child nodes of this camera. The nodes can be
## of any [Node3D] type (except [RacingCamera]), but it's more convenient to
## use [Camera3D], as they can be previewed in the editor.
##
##[br][br]
## The names of the child nodes are the names that will appear on screen when
## you change positions. The names will be capitalized if they're not already;
## e.g., `hood_view` will appear as `Hood View`.
##
##[br][br]
## [color=white][b]Note:[/b][/color] using subclasses of [RacingCamera] as
## position markers is discouraged, as it's untested, and it may result in
## weird things happening.
##
##[br][br]
## [color=white][b]Note:[/b][/color] This camera must be a child of the car node.
## If the car node is the scene root or the immediate parent, then the camera
## will automatically detect it. Otherwise the car node must be set manually,
## either by setting [member RacingCamera.follow_car] in the inspector, or using
## [method RacingCamera.set_car] through code.



## Emitted whenever this camera changes position.
signal position_changed(position_name: String)

const _CONF_WARNING_NO_CHILD_NODES = "The mounted-camera requires child nodes marking the camera positions around the vehicle."


var _camera_positions:Array[CameraPosition]
var _curr_position:int



func _on_enter_tree() -> void:
	_type = "RacingMountedCamera"
	camera_name = "On-Car Camera"
	_init_car_from_owner()


func _on_ready() -> void:
	_init_positions()

	_cam = Camera3D.new()
	add_child(_cam)

	# if this node isn't at the correct position, fix it (do this AFTER initializing the camera positions)
	global_position = _car_body.global_position

	switch_position(_curr_position, false, true)


func _init_positions() -> void:
	for c:Node3D in get_children():
		if c == _cam: continue
		var cp := CameraPosition.new(c.name.capitalize(), _car_body.to_local(c.global_position), c.rotation)
		_camera_positions.append(cp)
		c.free()

	if _camera_positions.size() == 0:
		push_warning("no positions were specified for mounted camera")


func _get_configuration_warnings() -> PackedStringArray:
	var res := super()
	if not res and get_child_count() == 0:
		res = [_CONF_WARNING_NO_CHILD_NODES]
	return res


func _on_unhandled_input(event: InputEvent) -> void:
	if _car_base == null: return

	if _shared.next_cam_pos_key_pressed(event):
		next_position()
	elif _shared.prev_cam_pos_key_pressed(event):
		previous_position()


func _on_process(_delta: float) -> void:
	# if the parent isn't the car's physics body, then this camera will need to catch up to it
	if _car_base != _car_body:
		global_position = _car_body.global_position
		global_rotation = _car_body.global_rotation


func _on_set_active() -> void:
	_cam.current = _active
	set_process_unhandled_input(_active)


## Switch to the next position available.
func next_position(emit:=true) -> void:
	switch_position(wrapi(_curr_position+1, 0, _camera_positions.size()), emit)


## Switch to the previous position available.
func previous_position(emit:=true) -> void:
	switch_position(wrapi(_curr_position-1, 0, _camera_positions.size()), emit)


## Switch camera position to the position [param index]. This
## function will do nothing if the new position is the same as the current
## position, unless the parameter [param force_change] is [code]true[/code].
##[br][br]
## If [param emit] is [code]true[/code], it will emit the [signal position_changed] signal.
func switch_position(index:int, emit:=true, force_change:=false) -> void:
	if _camera_positions.size() == 0: return
	if index == _curr_position and not force_change: return
	_curr_position = index
	_cam.position = _camera_positions[_curr_position].pos
	_cam.rotation = _camera_positions[_curr_position].rot

	if emit:
		position_changed.emit(_camera_positions[_curr_position].name)





