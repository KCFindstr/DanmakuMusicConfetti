vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
	vec4 cur=Texel(texture,texture_coords);
	if (screen_coords[1]<60||screen_coords[1]>660)
		return vec4(0);
	if (screen_coords[1]<160)
		cur*=(screen_coords[1]-60)/100;
	else if (screen_coords[1]>560)
		cur*=(660-screen_coords[1])/100;
	return cur*color;
}