extends Node3D

# This path targets your top-level UI container ('actions') that holds the Panel and Buttons.
@onready var button_container: Control = $GameHUD/actions 
@onready var ammo_container: Control = $Ammo
@onready var crosshair_container: Control = %crosshair

@onready var bullet_label: Label = ammo_container.get_node("PlayerInfoBox2/Label")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# 1. Start turn-based logic (preserving your existing code)
	TurnManager.start_turn()
	
	# 2. Connect the camera switch signal to our local function for UI control
	GlobalEvents.player_camera_switched.connect(_on_camera_switched)

	# 3. Connect the bullet count signal
	GlobalEvents.bullet_count_updated.connect(_on_bullet_count_updated)
	
	# 4. Ensure the UI is visible initially (assuming the game starts in TP mode)
	if is_instance_valid(button_container):
		button_container.visible = true
		ammo_container.visible = false
		crosshair_container.visible = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_camera_switched(is_fps: bool) -> void:
	# Check if the UI container node exists before trying to modify it
	if is_instance_valid(button_container):
		if is_fps:
			# Entering FPS/Shoot mode: Hide the entire 'actions' node
			button_container.visible = false
			ammo_container.visible = true
			crosshair_container.visible = true
			print("UI Hidden: Entered FPS Mode.")
		else:
			# Exiting FPS mode / Returning to TP mode: Show the entire 'actions' node
			button_container.visible = true
			ammo_container.visible = false
			crosshair_container.visible = false
			print("UI Visible: Returned to TP Mode.")
	else:
		# Error handling for debugging
		print("ERROR: 'actions' container not found or invalid. Check the node path in Main.gd!")

func _on_bullet_count_updated(remaining_bullets: int) -> void:
	if is_instance_valid(bullet_label):
		# Set the text to the number of remaining bullets
		bullet_label.text = str(remaining_bullets)
	else:
		print("WARNING: Bullet count label is missing or invalid. Check the node path in Main.gd or the Label's internal name!")
