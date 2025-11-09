extends TextureButton

func _gui_input(event: InputEvent) -> void:
	# This function receives raw GUI events only when the cursor is over the button.
	if event is InputEventMouseMotion:
		print("Mouse Motion Detected over button!")
	if event is InputEventMouseButton:
		print("Mouse Button Click Detected over button!")
