extends CharacterBody3D

# ----- Grid / Movement -----
@export var grid_size = 4.0
@export var move_duration = 0.2
@export var move_range = 3 # 3x3 grid (1 tile away)

# ----- Camera / Tilt -----
@export var sensitivity = 100
@export var camera_tilt = 1.0
@export var peek_offset = 3.0

# ----- Line Settings -----
@export var line_color = Color(0.0, 1.0, 0.5, 1.0) # Bright green, fully opaque
@export var line_width = 0.3 # Width of the line cylinder
@export var line_height_offset = 0.5 # Height above ground
@export var arc_height = 2.0 # Height of the arc curve
@export var path_segments = 20 # Number of segments in the curved path

# ----- Range Display Settings -----
@export var show_range_indicator = true
@export var range_color = Color(0.2, 0.6, 1.0, 0.3) # Blue semi-transparent
@export var range_outline_color = Color(0.3, 0.7, 1.0, 0.6) # Brighter blue for outline
@export var range_outline_width = 0.1
@export var show_range_only_on_hover = true # Only show range when hovering to move

# Nodes
@onready var ray_cast: RayCast3D = $RayCast3D
@onready var fp_cam: Camera3D = $Firstperson/FP_CAM
@onready var parent: Node3D = $Firstperson
@onready var mesh: Node3D = $MeshInstance3D
@onready var tp_cam: Camera3D = $"../CameraSpringArm/TP_CAM"

# Line visualization
var line_mesh_instance: MeshInstance3D
var range_indicator: MeshInstance3D
var current_target_pos: Vector3 = Vector3.ZERO
var is_valid_target: bool = false
var is_hovering_for_move: bool = false

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
	
	# Create line mesh instance
	line_mesh_instance = MeshInstance3D.new()
	add_child(line_mesh_instance)
	line_mesh_instance.visible = false
	
	# Create range indicator
	range_indicator = MeshInstance3D.new()
	add_child(range_indicator)
	range_indicator.visible = false
	
	# Delay range creation to ensure physics is ready
	await get_tree().process_frame
	if show_range_indicator:
		create_range_indicator()

func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	move_and_slide()
	handle_tilt(delta)
	
	# Update line visualization in TP mode
	if get_viewport().get_camera_3d() == tp_cam:
		update_movement_line()
		# Show range only if hovering for movement or if show_range_only_on_hover is false
		if show_range_indicator and range_indicator:
			if show_range_only_on_hover:
				range_indicator.visible = is_hovering_for_move
			else:
				range_indicator.visible = true
	else:
		if range_indicator:
			range_indicator.visible = false

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

# ------------------ Movement Line ------------------

func create_range_indicator() -> void:
	# Create a grid-based square range indicator
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	var vertices = PackedVector3Array()
	var indices = PackedInt32Array()
	var normals = PackedVector3Array()
	
	# Setup raycast for checking tile existence
	var space_state = get_world_3d().direct_space_state
	
	# Create a square grid of tiles within range
	for x in range(-move_range, move_range + 1):
		for z in range(-move_range, move_range + 1):
			var tile_x = x * grid_size
			var tile_z = z * grid_size
			
			# Calculate the target grid position
			var tile_world_x = global_position.x + tile_x
			var tile_world_z = global_position.z + tile_z
			var tile_pos = Vector3(tile_world_x, global_position.y, tile_world_z)
			
			# Only create tile indicator if it's walkable (has ground and no obstacle)
			if is_tile_walkable(tile_pos, space_state):
				# Get the actual ground height for proper placement
				var ground_ray_params = PhysicsRayQueryParameters3D.new()
				ground_ray_params.from = tile_pos + Vector3(0, 5, 0)
				ground_ray_params.to = tile_pos + Vector3(0, -5, 0)
				ground_ray_params.exclude = [self]
				var ground_result = space_state.intersect_ray(ground_ray_params)
				
				if ground_result:
					# Create a slightly raised square for each tile
					var half_tile = grid_size * 0.48 # Slightly smaller to show gaps
					var height = ground_result.position.y + 0.05 # Place just above the detected ground
					
					var base_index = vertices.size()
					
					# Bottom vertices (in global space)
					vertices.append(Vector3(tile_world_x - half_tile, height, tile_world_z - half_tile))
					vertices.append(Vector3(tile_world_x + half_tile, height, tile_world_z - half_tile))
					vertices.append(Vector3(tile_world_x + half_tile, height, tile_world_z + half_tile))
					vertices.append(Vector3(tile_world_x - half_tile, height, tile_world_z + half_tile))
					
					# Normals pointing up
					for i in range(4):
						normals.append(Vector3.UP)
					
					# Create two triangles for the tile
					indices.append(base_index + 0)
					indices.append(base_index + 1)
					indices.append(base_index + 2)
					
					indices.append(base_index + 0)
					indices.append(base_index + 2)
					indices.append(base_index + 3)
	
	# Only create mesh if we have vertices
	if vertices.size() > 0:
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_INDEX] = indices
		arrays[Mesh.ARRAY_NORMAL] = normals
		
		var array_mesh = ArrayMesh.new()
		array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		
		# Create semi-transparent material
		var material = StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_color = range_color
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
		material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
		material.no_depth_test = true
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		
		array_mesh.surface_set_material(0, material)
		range_indicator.mesh = array_mesh
		range_indicator.global_position = Vector3.ZERO # Use global coordinates
		range_indicator.global_rotation = Vector3.ZERO

func update_movement_line() -> void:
	var mouse_pos = get_viewport().get_mouse_position()
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

		# Check if within move range
		if abs(target_grid_x - player_grid_x) <= move_range and abs(target_grid_z - player_grid_z) <= move_range:
			var target_global = Vector3(target_grid_x * grid_size, global_position.y, target_grid_z * grid_size)
			
			# Verify the target position is valid (has ground and no obstacle)
			if is_tile_walkable(target_global, space_state):
				# Valid tile - show range and line
				is_hovering_for_move = true
				current_target_pos = target_global
				is_valid_target = true
				draw_line_to_target()
			else:
				# Invalid tile (obstacle or no ground)
				is_hovering_for_move = false
				is_valid_target = false
				line_mesh_instance.visible = false
		else:
			is_hovering_for_move = false
			is_valid_target = false
			line_mesh_instance.visible = false
	else:
		is_hovering_for_move = false
		is_valid_target = false
		line_mesh_instance.visible = false

# Check if a tile position is walkable (has ground and no obstacle)
func is_tile_walkable(target_pos: Vector3, space_state: PhysicsDirectSpaceState3D) -> bool:
	# Check for ground beneath the tile
	var ground_ray_params = PhysicsRayQueryParameters3D.new()
	ground_ray_params.from = target_pos + Vector3(0, 5, 0)
	ground_ray_params.to = target_pos + Vector3(0, -5, 0)
	ground_ray_params.exclude = [self]
	
	var ground_result = space_state.intersect_ray(ground_ray_params)
	if not ground_result:
		return false # No ground
	
	# Check for obstacles at the tile position
	var obstacle_ray_params = PhysicsRayQueryParameters3D.new()
	obstacle_ray_params.from = target_pos + Vector3(0, 0.1, 0) # Start slightly above ground
	obstacle_ray_params.to = target_pos + Vector3(0, 2.0, 0) # Check up to player height
	obstacle_ray_params.exclude = [self]
	
	var obstacle_result = space_state.intersect_ray(obstacle_ray_params)
	if obstacle_result:
		return false # Obstacle blocking
	
	return true # Tile is walkable

func draw_line_to_target() -> void:
	if not is_valid_target:
		return
	
	var start_pos = global_position + Vector3(0, line_height_offset, 0)
	var end_pos = current_target_pos + Vector3(0, line_height_offset, 0)
	
	# Calculate arc midpoint (raised in the air)
	var horizontal_distance = Vector3(start_pos.x, 0, start_pos.z).distance_to(Vector3(end_pos.x, 0, end_pos.z))
	var arc_mid = (start_pos + end_pos) / 2.0
	arc_mid.y += arc_height * (horizontal_distance / grid_size) * 0.5 # Scale arc with distance
	
	# Generate curved path points using quadratic Bezier curve
	var path_points = []
	for i in range(path_segments + 1):
		var t = float(i) / float(path_segments)
		var point = quadratic_bezier(start_pos, arc_mid, end_pos, t)
		path_points.append(point)
	
	# Create tube mesh along the path
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	var vertices = PackedVector3Array()
	var indices = PackedInt32Array()
	var normals = PackedVector3Array()
	
	var radial_segments = 8
	
	# Generate vertices along the path (in global space)
	for i in range(path_points.size()):
		var point = path_points[i]
		var tangent: Vector3
		
		# Calculate tangent direction
		if i == 0:
			tangent = (path_points[i + 1] - point).normalized()
		elif i == path_points.size() - 1:
			tangent = (point - path_points[i - 1]).normalized()
		else:
			tangent = (path_points[i + 1] - path_points[i - 1]).normalized()
		
		# Create a perpendicular basis
		var arbitrary = Vector3.UP if abs(tangent.dot(Vector3.UP)) < 0.9 else Vector3.RIGHT
		var bitangent = tangent.cross(arbitrary).normalized()
		var normal_base = bitangent.cross(tangent).normalized()
		
		# Create ring of vertices
		for j in range(radial_segments):
			var angle = (float(j) / float(radial_segments)) * TAU
			var offset = (normal_base * cos(angle) + bitangent * sin(angle)) * line_width
			vertices.append(point + offset) # Keep in global space
			normals.append(offset.normalized())
	
	# Generate indices for triangles
	for i in range(path_points.size() - 1):
		for j in range(radial_segments):
			var current_ring = i * radial_segments
			var next_ring = (i + 1) * radial_segments
			var next_j = (j + 1) % radial_segments
			
			# Two triangles per quad
			indices.append(current_ring + j)
			indices.append(next_ring + j)
			indices.append(current_ring + next_j)
			
			indices.append(current_ring + next_j)
			indices.append(next_ring + j)
			indices.append(next_ring + next_j)
	
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	arrays[Mesh.ARRAY_NORMAL] = normals
	
	# Create the mesh
	var array_mesh = ArrayMesh.new()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	
	# Create material
	var material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = line_color
	material.no_depth_test = true
	material.disable_receive_shadows = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	array_mesh.surface_set_material(0, material)
	
	line_mesh_instance.mesh = array_mesh
	# Position at world origin since vertices are in global space
	line_mesh_instance.global_position = Vector3.ZERO
	line_mesh_instance.global_rotation = Vector3.ZERO
	line_mesh_instance.visible = true

# Quadratic Bezier curve function
func quadratic_bezier(p0: Vector3, p1: Vector3, p2: Vector3, t: float) -> Vector3:
	var q0 = p0.lerp(p1, t)
	var q1 = p1.lerp(p2, t)
	return q0.lerp(q1, t)

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
			
			# Only move if tile is walkable (has ground and no obstacle)
			if is_tile_walkable(target_global, space_state):
				start_grid_move(target_global)

func start_grid_move(target_position: Vector3) -> void:
	if is_moving:
		return

	is_moving = true
	line_mesh_instance.visible = false # Hide line during movement

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
		line_mesh_instance.visible = false # Hide line in FP mode
		range_indicator.visible = false # Hide range in FP mode
