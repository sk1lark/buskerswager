shader_type canvas_item;

// Character lighting shader to add depth and atmosphere
uniform float ambient_strength : hint_range(0.0, 1.0) = 0.3;
uniform float light_strength : hint_range(0.0, 2.0) = 1.0;
uniform vec3 light_color : source_color = vec3(1.0, 0.9, 0.7);
uniform vec2 light_position = vec2(0.5, 0.2);
uniform float rim_strength : hint_range(0.0, 2.0) = 0.5;
uniform vec3 rim_color : source_color = vec3(0.8, 0.9, 1.0);

// Performance glow effects
uniform float glow_strength : hint_range(0.0, 2.0) = 0.0;
uniform vec3 glow_color : source_color = vec3(1.0, 0.9, 0.6);
uniform float glow_speed : hint_range(0.0, 10.0) = 2.0;

varying vec2 world_position;

void vertex() {
    world_position = VERTEX;
}

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);

    // Calculate lighting
    vec2 norm_uv = UV - vec2(0.5, 0.5);
    vec2 light_dir = normalize(light_position - UV);

    // Basic directional lighting
    float light_intensity = dot(normalize(vec2(0.5, -0.5)), light_dir) * 0.5 + 0.5;
    light_intensity = mix(ambient_strength, light_strength, light_intensity);

    // Rim lighting effect
    float rim_factor = 1.0 - abs(dot(normalize(norm_uv), vec2(0.0, 1.0)));
    rim_factor = pow(rim_factor, 3.0) * rim_strength;

    // Performance glow effect
    float glow_pulse = sin(TIME * glow_speed) * 0.5 + 0.5;
    vec3 glow = glow_color * glow_strength * glow_pulse;

    // Combine lighting effects
    vec3 final_color = tex_color.rgb * light_color * light_intensity;
    final_color += rim_color * rim_factor;
    final_color += glow;

    COLOR = vec4(final_color, tex_color.a);
}