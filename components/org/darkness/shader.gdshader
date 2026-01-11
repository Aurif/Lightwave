shader_type canvas_item;

uniform sampler2D mask_tex;  // The SubViewport texture

void fragment() {
// Repeat the main texture
    vec4 color = texture(TEXTURE, UV);

    // Sample mask texture (SubViewportTexture)
    //vec2 mask_uv = UV; // assuming the mask covers the full rect
    float mask_red = texture(mask_tex, SCREEN_UV).r;

    // Multiply alpha by the red channel of the mask
    color.a *= mask_red;

    COLOR = color;
}