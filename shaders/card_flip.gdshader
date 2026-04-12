shader_type canvas_item;
// Pseudo-3D card flip shader.
// Squeezes the card horizontally with a slight perspective skew
// to simulate a 3D rotation around the vertical axis.

uniform float flip_progress : hint_range(0.0, 1.0) = 0.0;
uniform float perspective_amount : hint_range(0.0, 0.5) = 0.15;
uniform bool add_shadow = true;

void vertex() {
	// Convert progress to angle (0 to PI)
	float angle = flip_progress * PI;
	float cos_val = cos(angle);

	// Horizontal squeeze based on cosine
	VERTEX.x *= abs(cos_val);

	// Perspective: slight vertical stretch at edges
	float perspective = 1.0 + perspective_amount * (1.0 - abs(cos_val));
	VERTEX.y *= perspective;
}

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);

	// Darken slightly during mid-flip for depth
	float angle = flip_progress * PI;
	float shadow = 1.0 - 0.3 * (1.0 - abs(cos(angle)));
	if (add_shadow) {
		tex_color.rgb *= shadow;
	}

	COLOR = tex_color;
}
