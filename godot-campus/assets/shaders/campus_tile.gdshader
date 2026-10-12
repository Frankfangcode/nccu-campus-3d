shader_type spatial;
render_mode diffuse_burley;
uniform vec4 tint : source_color = vec4(0.7, 0.65, 0.6, 1.0);
uniform float tile_size = 0.1;
varying vec3 world_position;
varying vec3 world_normal;
void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}
void fragment() {
	vec3 n = abs(world_normal);
	vec2 plane = n.y > 0.7 ? world_position.xz : (n.x > n.z ? world_position.zy : world_position.xy);
	vec2 uv = plane / tile_size;
	vec2 edge = min(fract(uv), 1.0 - fract(uv));
	vec2 aa = max(fwidth(uv), vec2(0.001));
	vec2 joint = smoothstep(vec2(0.025), vec2(0.025) + aa, edge);
	float cell = fract(sin(dot(floor(uv), vec2(127.1,311.7))) * 43758.5453);
	float grime = 0.025 * sin(plane.x*0.67) * sin(plane.y*0.41);
	float tiles = mix(0.72, 0.96 + cell*0.08, joint.x*joint.y);
	ALBEDO = tint.rgb * (tiles - grime);
	ROUGHNESS = 0.87;
}
