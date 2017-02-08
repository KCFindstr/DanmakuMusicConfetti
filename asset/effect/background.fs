extern number cx;
extern number cy;

number dist(number x1, number y1, number x2, number y2)
{
	return pow((x1-x2)*(x1-x2)+(y1-y2)*(y1-y2),0.25);
}

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
	vec4 c=Texel(texture,texture_coords);
	number rate=dist(cx,cy,texture_coords[0],texture_coords[1]);
	return c*rate*color;
}