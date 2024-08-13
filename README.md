# Racing Cameras Plugin

This plugin provides a handful of handy cameras for racing games. It's mostly intended for testing and prototyping, but could potentially serve as a basis for something more.

The cameras should be easy to use with minimal or no setup required. The plugin creates an autoload that manages the cameras. Most of it is done automatically. More information is available in the in-editor documentation.

## The available cameras are:
- **RacingChaseCamera** - the regular racing game camera that chases the vehicle and spins around to face the direction of movement
- **RacingCockpitCamera** - the car interior camera. Can be controlled with the mouse to look around freely
- **RacingOrbitCamera** - can be controlled with the mouse to orbit around the car, and zoom in and out
- **RacingCarCamera** - can cycle through several user-defined perspectives around the car (a fixed cockpit view can also be made using this camera)
- **RacingTrackCamera** - automatically cycles through user-defined positions around the race-track, to follow the player car
