shader_type spatial;
render_mode cull_front;

uniform float multi = 1.05;
uniform vec3 offset = vec3(0, 0, 0);

void vertex() {
	VERTEX = (VERTEX + offset) * multi;
}

void fragment() {
	ALBEDO = vec3(0, 0, 0);
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
