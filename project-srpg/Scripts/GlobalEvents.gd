# GlobalEvents.gd
extends Node

# Define a custom signal. You can include parameters if needed 
# (e.g., signal move_requested(direction: Vector2))
signal player_move_requested
signal player_shoot_requested

# Signal emitted when the camera mode is switched
# 'is_fps' is true if switching to FP (shoot) mode, false if switching to TP mode
signal player_camera_switched(is_fps: bool)

signal bullet_count_updated(remaining_bullets: int)
