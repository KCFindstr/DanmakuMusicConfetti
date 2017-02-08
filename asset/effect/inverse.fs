extern number radius;
extern number x;
extern number y;

number sqr(number val){
	return val*val;
}

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
	vec4 c=Texel(texture,texture_coords);
	number cx=screen_coords.x, cy=screen_coords.y;
	if (sqr(radius)>=sqr(x-cx)+sqr(y-cy)){
		return vec4(1-c.r,1-c.g,1-c.b,c.a);
	} else {
		return c;
	}
}