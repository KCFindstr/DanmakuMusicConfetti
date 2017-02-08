return {
	name="default",
	run=function(data,t)
		data.color[4]=(1-t)*128
		love.graphics.setColor(data.color)
		t=t*50
		love.graphics.circle("fill",data.x,data.y,t)
	end
}