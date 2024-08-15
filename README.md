# Racing Cameras Plugin

This plugin provides a handful of handy cameras for racing games. It's mostly intended for testing and prototyping, but could potentially serve as a basis for something more.

The plugin includes a couple of example scenes, showing the cameras in action, with a single car and with multiple cars.

###### Note: this is a work in progress, and some things may change between versions.

Quick video demonstration:

[![[Godot 4] Racing Cameras Plugin](https://github.com/user-attachments/assets/5ee1d305-621e-47df-b54c-bc49cbd0f094)](http://www.youtube.com/watch?v=tU3scSdb8z4 "[Godot 4] Racing Cameras Plugin")


## The available cameras are:
- **RacingChaseCamera** - the regular racing game camera that chases the vehicle and rotates around it to face the direction of movement. Can be moved closer and away from the vehicle with the mouse wheel.
- **RacingOrbitCamera** - orbits around the vehicle independant of the vehicle's rotation (optionally). It's controlled with the mouse to orbit, and `mouse wheel` to zoom in and out.
- **RacingCockpitCamera** - the interior cockpit camera. Can be controlled with the mouse to look around freely.
- **RacingCarCamera** - allows cycling through several user-defined perspectives around the car.
- **RacingTrackCamera** - automatically follows the player car by changing between user-defined positions around the race-track.

###### Note: mouse controls only work when the mouse is captured. The plugin already includes this funtionality, just by `left-clicking` to capture the mouse and `Escape` to release the mouse.


# Usage

All the nodes are documented, so you can refer to the in-editor documentation if you need, but below is a quick rundown on how to use this plugin.

###### Note: Godot has an [unfortunate issue](https://github.com/godotengine/godot/issues/72406) with in-editor documentation going missing after restarting the editor. A (crappy) workaround is to edit each affected script (just add a random space to it) and save it, and its documentation should then be listed and it should persist (at least until you delete the `.godot` folder; then you'll need this workaround again).

This plugin will autoload a camera manager singleton that should automatically manage all the cameras that exist in the scene tree, so they should be easy to use with minimal or no setup required. The autoload should be accessible as `cameraman`.

The camera manager also allows to easily switch between the available cameras using the `C` key, by default, or user defined input actions if they exist (see [Input Actions](#input-actions) below). The same is true for cameras that support multiple positions or modes, using the `V` key by default.

The camera nodes will attempt to auto-detect your vehicle node when they enter the scene tree. For that end your vehicle node must satisfy two conditions:
- it must be the scene root or the immediate parent of the camera node
- it must either be one of the `PhysicsBody3D` subtypes, or it must define a `get_car_physicsbody -> PhysicsBody3D` method, which returns the respective physics node of the vehicle. (This is because not all vehicle scenes may have the actual vehicle body as the root node.)

If needed, the vehicle (its root node) can be assigned to a camera in the inspector, in the property `follow_car`, or through code using `set_car()`.

###### Note: unlike other cameras, the track-camera isn't placed within vehicle scenes, so it cannot auto-detect vehicle nodes. However, the camera manager singleton should be able to automatically ensure the track-camera follows the vehicle. This only requires a bit of user intervention when using multiple cars.

If the player can switch between multiple cars, then two things are required:
1. each vehicle should define an `is_active -> bool` method, so the camera manager can switch cameras while avoiding those that belong to inactive vehicles.
2. you must tell the singleton which vehicle is the current one, using `cameraman.set_car()`. This allows the camera manager to ensure that no camera is following the wrong vehicle (currently, this only pertains to the track-camera).

## Input Actions

By default the plugin uses the `C` and `V` keys to switch cameras and camera positions/modes, respectively, but you can define some input actions with whatever keys you want, and the plugin will use them instead.

- `switch_camera`
- `next_camera`
- `prev_camera`
- `switch_camera_position`
- `next_camera_position`
- `prev_camera_position`


## The Nodes



- ### RacingCameraManager
This is the camera manager singleton class, and should NOT be instantiated. This class exists only for documentation purporses. Always use the `cameraman` autoloaded singleton.

The only functionality you may need from it is the `set_car()` method.


- ### RacingCamera
This is the base class for all cameras and shouldn't be used directly, as it does nothing on its own.




- ### RacingCarCamera

With this camera you can specify several positions around your vehicle, that you can then switch between (hood view, rear view, side view -- a cockpit view can also be defined with this camera, but it will be fixed).

The positions are specified using child nodes of the `RacingCarCamera` node. Any `Node3D` type will do (except `RacingCamera` types), but it's preferable to use `Camera3D`, as they can be previewed in the editor, for accurate positioning.

You can then use the `V` key (or the input actions) to cycle through the positions.

###### Note: using `RacingCameras` as position markers is highly discouraged, as it's completely untested and weird things may happen.




- ### RacingChaseCamera

This camera will smoothly chase after the vehicle, and rotate around it to face the direction of movement.

You can use the `V` key (or the input actions) to switch between several rigidity modes, and you can use the `mouse wheel` to move the camera closer or away from the vehicle.

This camera also comes with some settings that are tweakable in the inspector.

For this camera to work properly, currently it needs to know about the input state of your vehicle, so it requires that the vehicle defines two methods: the `get_throttle_input` which returns the acceleration input, and `get_steering_direction` which returns the steering input.

For example:

```gdscript
# vehicle script

func get_throttle_input() -> float:
    return accel_input

func get_steering_direction() -> float:
     return steering_input

func _process(delta: float) -> void:
    accel_input    = Input.get_axis("brake", "accelerate")
    steering_input = Input.get_axis("turn_right", "turn_left")
```




- ### RacingOrbitCamera

With this camera you can orbit around the car to inspect it from any direction, using the mouse, and you can also use the `mouse wheel` to move the camera closer or away from the car.

This camera also comes with some settings that are tweakable in the inspector.




- ### RacingCockpitCamera

With this camera you can have a cockpit view, where you can use the mouse to look around.

Unlike other cameras, this camera needs to be positioned according to where the vehicle's cockpit is. You can preview it in the editor for accurate placement.




- ### RacingTrackCamera

With this camera you can specify any amount of positions all around the race-track, and it will automatically switch between those positions to follow the assigned vehicle.

You can optionally have manual control, in which case you can use the `V` key (or the input actions) to switch camera position.

Much like the `RacingCarCamera`, the positions are specified using child nodes of any `Node3D` type (except `RacingCamera` types), but it's preferable to use `Camera3D`, as they can be previewed in the editor.

###### Note: using `RacingCameras` as position markers is highly discouraged, as it's completely untested and weird things may happen.



