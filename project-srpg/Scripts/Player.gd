extends CharacterBody3D

# ----- Grid / Movement -----
@export var grid_size = 4.0
@export var move_duration = 0.2
@export var move_range = 1 # 3x3 grid (1 tile away)

# ----- Camera / Tilt -----
@export var sensitivity = 100
@export var camera_tilt = 1.0
@export var peek_offset = 3.0

# Nodes
@onready var ray_cast: RayCast3D = $RayCast3D
@onready var fp_cam: Camera3D = $Firstperson/FP_CAM
@onready var parent: Node3D = $Firstperson
@onready var mesh: Node3D = $MeshInstance3D
@onready var tp_cam: Camera3D = $"../CameraSpringArm/TP_CAM"

# State
var is_moving = false
var tilted_left = false
var tilted_right = false
var original_x = 0.0

func _ready() -> void:
	# Snap to grid
	global_position.x = snapped(global_position.x, grid_size)
	global_position.z = snapped(global_position.z, grid_size)
	original_x = parent.position.x

func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	move_and_slide()
	handle_tilt(delta)

func _input(event):
	# Mouse look (FP_CAM only rotates locally)
	if event is InputEventMouseMotion:
		parent.rotation.y -= event.relative.x / sensitivity
		fp_cam.rotation.x -= event.relative.y / sensitivity
		fp_cam.rotation.x = clamp(fp_cam.rotation.x, deg_to_rad(-45), deg_to_rad(90))

	# Point-and-click movement
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if get_viewport().get_camera_3d() == tp_cam:
			move_to_clicked_tile(event.position)

	# Camera switch
	if Input.is_action_pressed("jump"):
		switch_camera()

# ------------------ Movement ------------------

func move_to_clicked_tile(mouse_pos: Vector2) -> void:
	var from = tp_cam.project_ray_origin(mouse_pos)
	var to = from + tp_cam.project_ray_normal(mouse_pos) * 1000
	var space_state = get_world_3d().direct_space_state

	var ray_params = PhysicsRayQueryParameters3D.new()
	ray_params.from = from
	ray_params.to = to
	ray_params.exclude = [self]

	var result = space_state.intersect_ray(ray_params)
	if result:
		var click_pos = result.position
		var target_grid_x = round(click_pos.x / grid_size)
		var target_grid_z = round(click_pos.z / grid_size)
		var player_grid_x = round(global_position.x / grid_size)
		var player_grid_z = round(global_position.z / grid_size)

		# Restrict to 3x3 grid
		if abs(target_grid_x - player_grid_x) <= move_range and abs(target_grid_z - player_grid_z) <= move_range:
			var target_global = Vector3(target_grid_x * grid_size, global_position.y, target_grid_z * grid_size)
			start_grid_move(target_global)

func start_grid_move(target_position: Vector3) -> void:
	if is_moving:
		return

	is_moving = true

	# Check collisions
	ray_cast.position = Vector3(0, 0.5, 0)
	ray_cast.target_position = target_position - global_position
	ray_cast.force_raycast_update()

	if not ray_cast.is_colliding():
		var tween = create_tween()
		tween.tween_property(self, "global_position", target_position, move_duration).set_trans(Tween.TRANS_SINE)
		await tween.finished

	global_position = target_position
	is_moving = false

# ------------------ Tilt / Peek ------------------

func handle_tilt(delta: float) -> void:
	# Tilt Left
	if Input.is_action_just_pressed("tiltLeft") and not tilted_left:
		var tween = create_tween()
		tween.tween_property(fp_cam, "rotation:z", deg_to_rad(camera_tilt), 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(parent, "position:x", original_x - peek_offset, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(mesh, "rotation:z", deg_to_rad(15), 0.2)
		tilted_left = true
		tilted_right = false

	# Tilt Right
	if Input.is_action_just_pressed("tiltRight") and not tilted_right:
		var tween = create_tween()
		tween.tween_property(fp_cam, "rotation:z", deg_to_rad(-camera_tilt), 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(parent, "position:x", original_x + peek_offset, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(mesh, "rotation:z", deg_to_rad(-15), 0.2)
		tilted_right = true
		tilted_left = false

	# Reset Left
	if Input.is_action_just_released("tiltLeft") and tilted_left:
		var tween = create_tween()
		tween.tween_property(fp_cam, "rotation:z", 0.0, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(parent, "position:x", original_x, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(mesh, "rotation:z", 0.0, 0.2)
		tilted_left = false

	# Reset Right
	if Input.is_action_just_released("tiltRight") and tilted_right:
		var tween = create_tween()
		tween.tween_property(fp_cam, "rotation:z", 0.0, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(parent, "position:x", original_x, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(mesh, "rotation:z", 0.0, 0.2)
		tilted_right = false

# ------------------ Camera Switch ------------------

func switch_camera() -> void:
	if get_viewport().get_camera_3d() == fp_cam:
		tp_cam.make_current()
	else:
		fp_cam.make_current()
