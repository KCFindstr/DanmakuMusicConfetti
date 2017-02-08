function getToPlayer(self)
	while true do
		local d=dist(self,player)
		local v=math.max(6,d*0.1)
		setV(self,v,0,player)
		self.r=0
		if player.shape:contains(self.x,self.y) then
			destroy(self)
			local text
			if self.sp then
				text="SP+"..self.sp/1000
				player:gainSP(self.sp)
			else
				text="+"..self.score
				player:gainScore(self.score)
			end
			local tmp={
				x=self.x-30,
				y=self.y-20,
				color={255,255,0,240},
				text=text,
				show=function(self)
					drawText(self.text,20,self.x,self.y,"eng")
				end
			}
			TM:newTask(floatingText,tmp,self.type)
			table.insert(object,tmp)
			return
		end
		coroutine.yield(1)
	end
end

local function tracePlayer(self)
	while true do
		if self.removed then return end
		if self:collidesWith(player.domain) then
			getBonus(self)
		end
		coroutine.yield(1)
	end
end

return {
	create=function(rad,V,sp)
		local back,score
		if sp<=0 then
			score=-sp
		end
		if (sp<100 and not score) or (score and score<1000) then
			back=GP.circle(0,0,30)
		else
			back=GP.circle(0,0,50)
		end
		back.onCreate=function(self)
			local cur=rad
			local delta=20
			TM:newTask(tracePlayer,self,self.type)
			for v=V,1,-1 do
				setV(self,v,rad)
				for i=1,3 do
					self.r=cur
					cur=cur+delta
					coroutine.yield(1)
				end
			end
			setV(self,2,90)
			self.r=0
		end
		back.type="bonus"
		if score then
			back.score=score
		else
			back.sp=sp
		end
		return back
	end
}