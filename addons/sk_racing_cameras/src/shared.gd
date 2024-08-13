extends Node

const SINGLETON_NAME = "cameraman"

static var mouse_sensitivity:float = 0.0025

const ACTION_SWITCH_CAM     = "switch_camera"
const ACTION_NEXT_CAM       = "next_camera"
const ACTION_PREV_CAM       = "prev_camera"
const ACTION_SWITCH_CAM_POS = "switch_camera_position"
const ACTION_NEXT_CAM_POS   = "next_camera_position"
const ACTION_PREV_CAM_POS   = "prev_camera_position"

const DEFAULT_SWITCH_CAM_KEY     = KEY_C
const DEFAULT_SWITCH_CAM_POS_KEY = KEY_V



static func check_mouse_capture(event:InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == 1:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	elif event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)



static func next_camera_key_pressed(event:InputEvent) -> bool:
	var inp1 := ACTION_SWITCH_CAM
	var inp2 := ACTION_NEXT_CAM
	return (InputMap.has_action(inp1) and event.is_action_pressed(inp1)) \
		or (InputMap.has_action(inp2) and event.is_action_pressed(inp2)) \
		or (event is InputEventKey
		and event.keycode == DEFAULT_SWITCH_CAM_KEY
		and event.is_pressed() and not event.is_echo())


static func prev_camera_key_pressed(event:InputEvent) -> bool:
	return InputMap.has_action(ACTION_PREV_CAM) \
		and event.is_action_pressed(ACTION_PREV_CAM)



static func next_cam_pos_key_pressed(event:InputEvent) -> bool:
	var inp1 := ACTION_SWITCH_CAM_POS
	var inp2 := ACTION_NEXT_CAM_POS
	return (InputMap.has_action(inp1) and event.is_action_pressed(inp1)) \
		or (InputMap.has_action(inp2) and event.is_action_pressed(inp2)) \
		or (event is InputEventKey
		and event.keycode == DEFAULT_SWITCH_CAM_POS_KEY
		and event.is_pressed() and not event.is_echo())


static func prev_cam_pos_key_pressed(event:InputEvent) -> bool:
	return InputMap.has_action(ACTION_PREV_CAM_POS) \
		and event.is_action_pressed(ACTION_PREV_CAM_POS)



