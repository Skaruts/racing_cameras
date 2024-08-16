#@tool
@icon("res://addons/sk_racing_cameras/icons/camera_man.svg")
class_name RacingCameraManager
extends Node


## Do not instantiate. This is the singleton (autoload) that [RacingCamera]
## nodes register themselves with, and it's automatically loaded by the
## [color=white]Racing Cameras[/color] plugin.
##
## This is the camera manager for the Racing Cameras. Once the plugin is
## activated, you can access this singleton by its intance name
## [code]cameraman[/code].
## [br][br]
##
## By default, if no input actions are defined, the keys [code]C[/code] and
## [code]V[/code] can be used to switch camera, and to switch the camera
## position/mode. However, both the camera manager and the cameras support
## several input actions that they will use instead of the default keys, if
## they are defined in [code]Project -> Project Settings -> Input Map[/code]:
## [codeblock]
##     switch_camera
##     next_camera
##     prev_camera
##     switch_camera_position
##     next_camera_position
##     prev_camera_position
## [/codeblock]
## [br]
## All [RacingCamera] nodes should automatically register/unregister themselves
## with the camera manager as they enter the scene tree.
## [br][br]
##
## The camera manager will attempt to use the car that is associated with the
## first camera that registers itself. If multiple cars exist for the player
## to switch between, then each car should define a method
## [code]is_active() -> bool[/code], that should only return true for the
## current car, and the current car should be assigned to the camera manager
## using [method set_car]. This will allow the camera manager to switch
## cameras, while avoiding those that belong to inactive cars.
## [br][br]
##
## When a new car is set, the camera manager will also automatically set it to any
## external cameras, such as the [RacingTrackCamera].



const _shared := preload("shared.gd")

var _cameras: Array[RacingCamera]
var _curr_idx: int = -1
var _cam_info_display: CanvasLayer
var _car: Node3D


func _enter_tree() -> void:
	const TextDisplay:PackedScene = preload("text_display.tscn")
	_cam_info_display = TextDisplay.instantiate() as CanvasLayer
	add_child(_cam_info_display)


func _ready() -> void:
	if _cameras.size():
		# if cameras exist at startup, allow them to be ready
		await get_tree().process_frame
		_init_default_cam()


func _unhandled_input(event: InputEvent) -> void:
	_shared.check_mouse_capture(event)

	if _shared.next_camera_key_pressed(event):
		_next_camera()
	elif _shared.prev_camera_key_pressed(event):
		_prev_camera()


func _init_default_car() -> void:
	for c in _cameras:
		if c._car_base != null:
			set_car(c._car_base)
			break


func _init_default_cam() -> void:
	if _curr_idx != -1: return

	if _car == null:
		_init_default_car()

	if _cameras.size() == 1:
		_switch_camera(0, true)
		return

	var track_cam_idx := -1
	for i in _cameras.size():
		var cam := _cameras[i]
		# try choosing a chase camera, if one exists
		if cam is RacingChaseCamera and cam._car_base == _car:
			_switch_camera(i, true)
			return
		elif cam is RacingTrackCamera:
			track_cam_idx = i

	_switch_camera(wrapi(track_cam_idx+1, 0, _cameras.size()))


# Switch to the next available camera.
func _next_camera(emit:=true) -> void:
	_switch_camera(wrapi(_curr_idx+1, 0, _cameras.size()), emit)


# Switch to the previous available camera.
func _prev_camera(emit:=true) -> void:
	_switch_camera(wrapi(_curr_idx-1, 0, _cameras.size()), emit)


# Switch to the camera at index [param index]. This function will do nothing
# if the new camera is the same as the current camera, unless the parameter
# [param force_change] is true.
func _switch_camera(index:int, emit:=true, force_change:=false) -> void:
	if _cameras.size() == 0 or (_curr_idx == index and not force_change): return
	var old_idx := _curr_idx


	var i := 0  # safety measure -- TODO: what happens if this fails, exactly?
	while i <= _cameras.size() \
	and _cameras[index]._car_base and (_cameras[index]._car_base != _car):
		i += 1
		index = wrapi(index+1, 0, _cameras.size())

	_curr_idx = index
	if _curr_idx == old_idx:
		return

	_cameras[old_idx].set_active(false)
	_cameras[index].set_active(true)

	if emit:
		_cam_info_display.show_camera_name(_cameras[index].camera_name)


## Remove a camera from the camera manager
## [br][br]
## [color=white]Note:[/color] Racing Cameras automatically remove themselves
## from the camera manager they exit the tree.
func remove_camera(cam:RacingCamera) -> void:
	if cam in _cameras:
		_cameras.erase(cam)
		if cam.has_signal("position_changed"):
			cam.position_changed.disconnect(_cam_info_display.show_position_name)
		elif cam.has_signal("mode_changed"):
			cam.mode_changed.disconnect(_cam_info_display.show_position_name)



## Add a camera to the camera manager
## [br][br]
## [color=white]Note:[/color] Racing Cameras automatically add themselves to
## the camera manager when they enter the tree.
func add_camera(cam:RacingCamera) -> void:
	if not cam in _cameras:
		_cameras.append(cam)
		cam.tree_exiting.connect(remove_camera.bind(cam))
		if cam.has_signal("position_changed"):
			cam.position_changed.connect(_cam_info_display.show_position_name)
		elif cam.has_signal("mode_changed"):
			cam.mode_changed.connect(_cam_info_display.show_position_name)



## Set the car that is currently in use.
func set_car(new_car:Node3D, force:=false) -> void:
	if new_car == _car and not force: return

	var old_car := _car
	_car = new_car

	for cam:RacingCamera in _cameras:
		if cam is RacingTrackCamera:
			cam.set_car(new_car)

	if old_car == null:
		_init_default_cam()
		return

	var curr_cam:RacingCamera = _cameras[_curr_idx]

	if curr_cam is RacingTrackCamera:
		return

	# find a camera in new car that is the same as the old car's
	for i in _cameras.size():
		var cam := _cameras[i]
		if cam._type != curr_cam._type: continue
		if cam._car_base == new_car:
			_switch_camera(i, false)
			if curr_cam is RacingChaseCamera:
				# try setting the same chase mode as the previous cam (and don't display name)
				_cameras[_curr_idx].switch_mode(curr_cam._curr_mode, false)
			return

	# if we're here, the new car doesn't have the same camera as the old car,
	# so switch to next camera and provide warning
	push_warning("current car is not equipped with current camera: '%s'" % curr_cam._type)
	_next_camera(false)
