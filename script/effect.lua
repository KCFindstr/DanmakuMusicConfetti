--普通出现
function normalCreate()
end

--摧毁绘制
function drawDestroy(self)
	for i=self.r,self.r+315,45 do
		local rad=math.rad(i)
		local x,y=self.x+self.dist*math.cos(rad),self.y+self.dist*math.sin(rad)
		love.graphics.draw(self.img,x,y,rad,self.rate.x,self.rate.y,self.width/2,self.height/2)
	end
end

--普通摧毁
function normalDestroy(self)
	self.show=drawDestroy
	self.rate.x=0.5
	self.rate.y=0.5
	self.dist=0
	local escapeV=1
	table.insert(object,self)
	for i=30,1,-1 do
		self.color[4]=8*i
		self.dist=self.dist+escapeV
		coroutine.yield(1)
	end
	self.removed=true
	table.delete(object,self)
	return
end

--文字
function floatingText(self)
	for i=1,60 do
		self.y=self.y-1
		if i>30 then
			self.color[4]=self.color[4]-8
		end
		coroutine.yield(1)
	end
	table.delete(object,self)
end

--向玩家移动并获取奖励
function getBonus(self)
	if self.signal then return end
	self.signal=true
	TM:remove(self,self.type)
	TM:newTask(getToPlayer,self,self.type)
end

--回收资源
function getAllBonus()
	for i=#(bullet),1,-1 do
		local cur=bullet[i]
		if cur.type=="bonus" then
			getBonus(cur)
		end
	end
end