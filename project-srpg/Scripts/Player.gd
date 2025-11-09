extends CharacterBody3D

# to change grid movement
@export var grid_size = 4.0
@export var move_duration = 0.2 # How long it takes to move one grid cell
@export var sensitivity = 100
# checking wall collisions
@onready var ray_cast: RayCast3D = $RayCast3D

# state var to prevent new movement while already moving
var is_moving = false

func _ready() -> void:
	# snap to grid
	global_position.x = snapped(global_position.x, grid_size)
	global_position.z = snapped(global_position.z, grid_size)

func _physics_process(delta: float) -> void:
	# gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# grid movement
	if not is_moving:
		# prevents sliding after movement is done
		velocity.x = 0
		velocity.z = 0
		
		# define movement
		var move_vector = Vector3.ZERO
		if Input.is_action_pressed("back"):
			move_vector.z = 1
		elif Input.is_action_pressed("forward"):
			move_vector.z = -1
		elif Input.is_action_pressed("right"):
			move_vector.x = 1
		elif Input.is_action_pressed("left"):
			move_vector.x = -1
			
		# camera-relative direction
		if not move_vector.is_zero_approx():
			move_vector = move_vector.rotated(Vector3.UP, rotation.y)
			# makes the input relative to the character's rotation
			var grid_direction = ($Firstperson.transform.basis * move_vector).normalized().round()
			
			if not grid_direction.is_zero_approx():
				# Start the movement
				start_grid_move(grid_direction)

	move_and_slide()

# grid movement
func start_grid_move(grid_direction: Vector3) -> void:
	is_moving = true
	
	# RayCast to check for walls
	# check from a bit inside the player to avoid hitting the floor
	var ray_origin = Vector3(0, 0.5, 0) 
	ray_cast.position = ray_origin
	ray_cast.target_position = grid_direction * grid_size
	ray_cast.force_raycast_update()

	# move if the raycast doesnt hit a wall
	if not ray_cast.is_colliding():
		var target_position = global_position + grid_direction * grid_size
		
		# tween to animate the global_position
		var tween = create_tween()
		tween.set_parallel(false) # animations one after another
		
		# 'global_position' property from current to target
		tween.tween_property(self, "global_position", target_position, move_duration).set_trans(Tween.TRANS_SINE)
		
		# tween to finish before we can move again
		await tween.finished
		
		# snap position
		global_position = target_position
		is_moving = false
	else:
		# hit a wall, we can move again immediately
		is_moving = false

func _input(event):
	if event is InputEventMouseMotion:
			rotation.y -= event.relative.x / sensitivity
		
			$Firstperson.rotation.x -= event.relative.y / sensitivity
			$Firstperson.rotation.x = clamp($Firstperson.rotation.x, deg_to_rad(-45),deg_to_rad(90))
func switch_camera()->void:
	if get_viewport().getcamera() == $CameraSpringArm.TP_CAM:
		$Firstperson.FP_CAM.current = true
	else:
		$CameraSpringArm.TP_CAM.current = true
func acutal_switch(event):
	if Input.is_action_pressed("space"):
		switch_camera()
