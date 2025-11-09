# UIScript.gd
extends Control 
@onready var shoot_button = %Shoot
@onready var move_button = %Move # Get the button using its Unique Name

func _ready():
	# Connect the button's built-in 'pressed' signal to a local function
	move_button.pressed.connect(_on_move_button_pressed)
	shoot_button.pressed.connect(_on_shoot_button_pressed)

func _on_move_button_pressed():
	# Access the globally available Autoload and emit the signal
	print("Move Button pressed, emitting signal...")
	GlobalEvents.player_move_requested.emit()

func _on_shoot_button_pressed():
	print("Shoot Button pressed, emitting signal...")
	GlobalEvents.player_shoot_requested.emit()
