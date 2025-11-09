# UIScript.gd
extends Control 

@onready var move_button = %Move # Get the button using its Unique Name

func _ready():
	# Connect the button's built-in 'pressed' signal to a local function
	move_button.pressed.connect(_on_move_button_pressed)

func _on_move_button_pressed():
	# Access the globally available Autoload and emit the signal
	print("UI Button pressed, emitting signal...")
	GlobalEvents.player_move_requested.emit()
