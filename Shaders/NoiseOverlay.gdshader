shader_type spatial;

uniform float noise_scale = 0.1; // Controls the "zoom" of the noise
uniform float noise_strength = 0.1; // Controls how much the noise affects the color
uniform sampler2D noise_texture; // A NoiseTexture resource
uniform vec3 base_colour : source_color;

varying vec3 world_position;

void vertex() {
    // Calculate world position for the vertex and pass it to the fragment shader
    world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
    // Use world_position.xz for 2D noise in world space
    // If you want to use the Y coordinate, you can use world_position.xy or world_position.yz
    vec2 noise_uv = world_position.xz * noise_scale;

    // Sample the noise texture
    float noise_value = texture(noise_texture, noise_uv).r;

    // Normalize noise_value from [0, 1] to [-0.5, 0.5] for additive/subtractive effects
    noise_value = noise_value - 0.5;

    ALBEDO = base_colour + (noise_value * noise_strength);
}