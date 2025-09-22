shader_type canvas_item;

uniform float scanline_strength : hint_range(0.0, 1.0) = 0.15;
uniform float curvature : hint_range(0.0, 0.2) = 0.05;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.6;
uniform float noise_strength : hint_range(0.0, 0.1) = 0.01;
uniform float brightness : hint_range(0.5, 1.5) = 1.05;
uniform float contrast : hint_range(0.5, 2.0) = 1.1;
uniform float rgb_shift : hint_range(0.0, 0.01) = 0.002;

vec2 curve_uv(vec2 uv) {
    uv = uv * 2.0 - 1.0;

    // More pronounced barrel distortion
    vec2 offset = abs(uv.yx) / vec2(curvature * 3.0, curvature * 2.0);
    uv = uv + uv * offset * offset;

    // Additional subtle pincushion effect
    float r2 = dot(uv, uv);
    uv *= 1.0 + curvature * 0.5 * r2;

    uv = uv * 0.5 + 0.5;
    return uv;
}

float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
    vec2 curved_uv = curve_uv(UV);

    // Check if we're outside the curved screen bounds with soft edges
    if (curved_uv.x < -0.05 || curved_uv.x > 1.05 || curved_uv.y < -0.05 || curved_uv.y > 1.05) {
        COLOR = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }

    // RGB chromatic aberration shift
    vec4 color;
    color.r = texture(TEXTURE, curved_uv + vec2(rgb_shift, 0.0)).r;
    color.g = texture(TEXTURE, curved_uv).g;
    color.b = texture(TEXTURE, curved_uv - vec2(rgb_shift, 0.0)).b;
    color.a = texture(TEXTURE, curved_uv).a;

    // Scanlines - higher frequency, more subtle
    float scanline = sin(curved_uv.y * 600.0) * 0.5 + 0.5;
    scanline = mix(1.0, scanline, scanline_strength);

    // Enhanced vignette with soft falloff
    vec2 center = curved_uv - 0.5;
    float vignette = 1.0 - smoothstep(0.0, 0.7, length(center) * vignette_strength);

    // Subtle noise that varies over time
    float noise = (random(curved_uv + fract(TIME * 0.1)) - 0.5) * noise_strength;

    // Apply effects
    color.rgb *= scanline;
    color.rgb *= vignette;
    color.rgb += noise;

    // Brightness and contrast
    color.rgb = ((color.rgb - 0.5) * contrast + 0.5) * brightness;

    // Subtle bloom effect on bright areas
    float brightness_factor = dot(color.rgb, vec3(0.299, 0.587, 0.114));
    if (brightness_factor > 0.8) {
        color.rgb += vec3(0.1) * (brightness_factor - 0.8);
    }

    COLOR = color;
}