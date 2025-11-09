# CrosshairController.gd
# Attach this script to your TextureRect node (the crosshair).

extends TextureRect

# Path to the shader file we created.
const INVERTED_SHADER_PATH = "res://Shaders/inverted_crosshair.gdshader"

func _ready():
	# 1. Load the shader resource (the .gdshader file).
	var shader_resource = load(INVERTED_SHADER_PATH)
	if not shader_resource:
		print("ERROR: Could not load shader resource at ", INVERTED_SHADER_PATH)
		return

	# 2. Create a new ShaderMaterial and assign the shader resource to it.
	var shader_material = ShaderMaterial.new() # Renamed variable to avoid shadowing
	shader_material.shader = shader_resource

	# 3. Apply the ShaderMaterial to this TextureRect node.
	# We assign the local 'shader_material' variable to the 'self.material' property.
	self.material = shader_material
	
	# IMPORTANT SETUP NOTE:
	# For the SCREEN_TEXTURE to work, the Material must have the "CanvasItem" 
	# property "Light Mode" set to "Unshaded" AND the "CanvasItem" property 
	# "Cull Mode" set to "Disabled" or "Clockwise".


	# Since this shader uses SCREEN_TEXTURE, ensure the canvas is set up correctly:
	# 1. The root UI container must have the viewport or Camera2D set up to capture the screen.
	# 2. The TextureRect should be the last drawn element to get the latest screen content.
	# 3. The surrounding scene viewport MUST have 'Filter' set to 'Nearest' or 'Linear' 
	#    under Project Settings -> General -> Rendering -> Quality -> Default Texture Filter.
