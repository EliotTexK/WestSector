shader_type canvas_item;

void fragment() {
	vec4 tex_color = texture(TEXTURE,UV);
    float avg = (tex_color.r + tex_color.g + tex_color.b) / 3.0;
	COLOR.r = avg;
	COLOR.g = avg;
	COLOR.b = avg;
	COLOR *= vec4(avg,avg,avg,tex_color.a); // don't ask me why THIS is how you properly change alpha
}