// This shader inverts the colors of whatever is under the crosshair texture.
shader_type canvas_item;

// FIX: SCREEN_TEXTURE must now be explicitly defined as a uniform with the hint_screen_texture flag.
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture;

void fragment() {
	// 1. Get the color of the screen underneath the crosshair texture.
	// We use SCREEN_UV as the coordinate to sample the screen texture.
	vec3 screen_color = texture(SCREEN_TEXTURE, SCREEN_UV).rgb;
	
	// 2. Invert the color (1.0 - color)
	vec3 inverted_color = 1.0 - screen_color;
	
	// 3. Set the final RGB color to the inverted screen color.
	COLOR.rgb = inverted_color;
	
	// 4. Use the alpha channel (transparency) from the crosshair's TextureRect texture (TEXTURE).
	// This ensures the inverted color is only visible where the crosshair image is drawn.
	COLOR.a = texture(TEXTURE, UV).a;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
