shader_type spatial; // Or canvas_item for 2D, but spatial for 3D buildings

uniform vec3 roof_colour : source_color;
uniform vec3 roof_frame : source_color;
uniform vec3 window_colour : source_color;
uniform vec3 wall_colour : source_color;
uniform float noise_scale = 0.1; // Controls the "zoom" of the noise
uniform float noise_strength = 0.1; // Controls how much the noise affects the color
uniform sampler2D noise_texture; // A NoiseTexture resource`

varying vec3 world_position;

void vertex() {
    // Calculate world position for the vertex and pass it to the fragment shader
    world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 worldNormal = (INV_VIEW_MATRIX * vec4(NORMAL.xyz, 0.0)).xyz;
    // Determine if it's a wall or a roof
    float dot_up = dot(worldNormal, vec3(0.0, 1.0, 0.0)); // Assuming Y is up

    if (abs(dot_up) > 0.5) { // Likely a roof or floor
    	vec2 noise_uv = world_position.xz * noise_scale;
	    float noise_value = texture(noise_texture, noise_uv).r;

	    noise_value = noise_value;
    	ALBEDO = roof_colour * noise_value * noise_strength;
    } else { 
        float floorH = 8.0;
        float winW = 10.0;
        float floor = mod(world_position.y, floorH);
        float column = mod(world_position.x, winW);
		
		// Window appears near center of each floor and column
		float is_floor_centered = step(1.0, abs(floor - floorH * 0.5));
		float is_column_centered = step(1.5, abs(column - winW * 0.5));

		// If both floor and column are centered, it's a window
		float window = 1.0 - (is_floor_centered + is_column_centered);

		// Clamp window to 0 or 1
		window = step(0.5, window);

		ALBEDO = mix(wall_colour, window_colour, window);
    }
}