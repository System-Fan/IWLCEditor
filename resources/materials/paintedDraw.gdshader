shader_type canvas_item;
render_mode blend_add;
instance uniform vec2 scale = vec2(1,1);
uniform vec3 colorTop:source_color;
uniform vec3 colorBottom:source_color;

vec3 lerpColor(vec3 color1, vec3 color2, float t) {
	return color1 * (1.0-t) + color2 * t;
}

void fragment() {
	COLOR.rgb = lerpColor(colorTop, colorBottom, UV.y/scale.y);
}
