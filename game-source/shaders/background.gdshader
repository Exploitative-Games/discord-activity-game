shader_type canvas_item;

void vertex() {
	UV.x = UV.x / 5.0 + 0.2 * float(INSTANCE_ID % 5);
}
