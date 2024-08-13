@tool
extends EditorPlugin


const _shared := preload("res://addons/sk_racing_cameras/src/shared.gd")


func _enter_tree() -> void:
	add_autoload_singleton(_shared.SINGLETON_NAME, "res://addons/sk_racing_cameras/src/cameraman.gd")

func _exit_tree() -> void:
	remove_autoload_singleton(_shared.SINGLETON_NAME)

