extern number radius;
extern number height;
extern number width;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
	vec4 c=vec4(0), cur=Texel(texture,texture_coords);
	number cnt=0;
	for (number i=0; i<radius; i+=1)
	{
		for (number j=0; i+j<radius; j+=1)
		{
			vec4 tmp=vec4(0);
			number rate=(radius*radius-i*j);
			cnt+=4.0*rate;
			tmp+=Texel(texture,texture_coords+vec2(i/width,j/height));
			tmp+=Texel(texture,texture_coords+vec2(-i/width,j/height));
			tmp+=Texel(texture,texture_coords+vec2(i/width,-j/height));
			tmp+=Texel(texture,texture_coords+vec2(-i/width,-j/height));
			c+=tmp*rate;
		}
	}
	c/=cnt;
	for (int i=0; i<4; i++)
		c[i]=max(c[i],cur[i]);
	return c*color;
}