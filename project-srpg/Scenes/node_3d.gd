extends Node3D

# This path targets your top-level UI container ('actions') that holds the Panel and Buttons.
@onready var button_container: Control = $GameHUD/actions 

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# 1. Start turn-based logic (preserving your existing code)
	TurnManager.start_turn()
	
	# 2. Connect the camera switch signal to our local function for UI control
	GlobalEvents.player_camera_switched.connect(_on_camera_switched)

	# 3. Ensure the UI is visible initially (assuming the game starts in TP mode)
	if is_instance_valid(button_container):
		button_container.visible = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_camera_switched(is_fps: bool) -> void:
	# Check if the UI container node exists before trying to modify it
	if is_instance_valid(button_container):
		if is_fps:
			# Entering FPS/Shoot mode: Hide the entire 'actions' node
			button_container.visible = false
			print("UI Hidden: Entered FPS Mode.")
		else:
			# Exiting FPS mode / Returning to TP mode: Show the entire 'actions' node
			button_container.visible = true
			print("UI Visible: Returned to TP Mode.")
	else:
		# Error handling for debugging
		print("ERROR: 'actions' container not found or invalid. Check the node path in Main.gd!")
