extends SpringArm3D 

@export var sensitivity = 0.003
@export var min_pitch = -89.0
@export var max_pitch = 89.0

@onready var player_body: Node3D = get_parent()

func _ready() -> void:
	set_process_unhandled_input(false)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		# Rotate the PlayerBody left/right
		player_body.rotate_y(-event.relative.x * sensitivity)
		
		# Rotate self (the CameraSpringArm) up/down
		rotate_x(-event.relative.y * sensitivity)
		
		# Clamp the up/down rotation
		rotation.x = clampf(rotation.x, deg_to_rad(min_pitch), deg_to_rad(max_pitch))
