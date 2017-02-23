player={
	x=0,
	y=0,
	r=3, --判定大小
	rate={x=1,y=1},
	R=20, --擦弹判定
	v={x=0,y=0}, --速度
	a={x=0,y=0},
	state="appear",
	t={last=0,tot=0,lmove=0},
	count={
		score=0,
		graze=0,
		death=0,
		bomb=0
	}, --计数
	speed={
		fast=5,
		slow=2,
		sp=480,
		gain=5
	},
	img={group={}},
	draw=drawPlayer,
	sign=nil,
	shape=nil,
	domain=nil,
	immortal=300,
	type="player",
	active=true,
	sp=0,
	large=0
}

function beginPlayer(self)
	coroutine.yield(30)
	while self.y>game.graphics.height-30 do
		self.y=self.y-4
		coroutine.yield(1)
	end
	self.state="moving"
end

function player:initGame()
	player.count={
		score=0,
		graze=0,
		death=0,
		bomb=0
	}
	player.domain=GP:circle(self.x,self.y,self.R)
	player.shape=GP:circle(self.x,self.y,self.r)
	player.domain.touched=0
	player.shape.touched=0
	local diff=game.audio.record.difficulty
	if diff>3 then diff=1 end
	player.penalty=math.floor(math.sqrt(game.audio.duration)*100*diff)
end

function player:new()
	player.x=game.graphics.width/2
	player.y=game.graphics.height+100
	player.sp=0
	player.v={x=0,y=0}
	player.t={last=0,tot=0,lmove=0}
	player.a={x=0,y=0}
	player.immortal=300
	player.state="appear"
	player.sign=nil
	player.rate={x=1,y=1}
	player.active=true
	TM:newTask(beginPlayer,player,"player")
end

function player:load(name)
	player.img.move=love.graphics.newImage("data/player/"..name.."/"..name..".png")
	for i=0,2 do
		player.img.group[i]={}
		for j=0,7 do
			player.img.group[i][j]=love.graphics.newQuad(j*32,i*48,32,48,player.img.move:getWidth(),player.img.move:getHeight())
		end
	end
end

function playerDying(self)
	table.delete(game.active,game.shader.inverse)
	table.insert(game.active,game.shader.inverse)
	playSound(game.sound.death,true)
	game.shader.inverse:send("x",self.x+0.5+game.graphics.dx)
	game.shader.inverse:send("y",self.y+0.5+game.graphics.dy)
	game.shader.inverse:send("radius",0)
	local r2,d,val=0,50,math.sqrt(game.graphics.height^2+game.graphics.width^2)+200
	for i=d,val,d do
		coroutine.yield(1)
		game.shader.inverse:send("radius",i)
		if self.state~="dying" then
			if r2==0 then
				table.delete(game.active,game.shader.inverse2)
				table.insert(game.active,game.shader.inverse2)
				game.shader.inverse2:send("x",self.x+0.5+game.graphics.dx)
				game.shader.inverse2:send("y",self.y+0.5+game.graphics.dy)
			end
			r2=r2+d
			game.shader.inverse2:send("radius",r2)
		end
	end
	if player.state=="dying" then
		table.delete(game.active,game.shader.inverse)
		createBonus("power",player.sp,player.x,player.y)
		player.death:setPosition(player.x,player.y)
		player.death:emit(64)
		player:addCounter("death")
		player:addCounter("score",-player.penalty)
		checkAchievement("firstDeath")
		player:new()
	else
		while r2<val do
			r2=r2+d
			game.shader.inverse2:send("radius",r2)
			coroutine.yield(1)
		end
		table.delete(game.active,game.shader.inverse)
		table.delete(game.active,game.shader.inverse2)
	end
end

function exitTime(self)
	for i=59,0,-1 do
		coroutine.yield(1)
		if self.state=="time" then
			return
		end
		game.graphics.color[4]=i*2
		if i%15==0 then
--			game.interval["enemy"]=game.interval["enemy"]-1
--			game.interval["bullet"]=game.interval["bullet"]-1
		end
	end
end

function timeAttack(self)
	--决死成功
	player:addCounter("bomb")
	local t=self.speed.sp*self.sp/5000
	local dis=game.graphics.height*self.sp/5000
	for j=#(bullet),1,-1 do
		local cur=bullet[j]
		if cur.type=="bullet" and dist(self,cur)<=dis then
			createBonus("score",cur.drop,cur.x,cur.y,3,5,0,true)
			destroy(cur)
		end
	end
	getAllBonus()

	self.sp=0
	self.large=1
	for i=1,60 do
		coroutine.yield(1)
		if self.state~="time" then
			TM:newTask(exitTime,player,"player")
			return
		end
		game.graphics.color[4]=i*2
	end
	for i=61,t do
		coroutine.yield(1)
		if self.state~="time" then
			TM:newTask(exitTime,player,"player")
			return
		end
	end
	self.state="moving"
	TM:newTask(exitTime,player,"player")
end

function player:gainSP(delta)
	if game.audio.record.difficulty>3 then
		player:addCounter("score",math.max(0,delta))
	else
		player.sp=player.sp+delta
		player.sp=math.max(0,player.sp)
		player.sp=math.min(5000,player.sp)
	end
end

function player:addCounter(type,delta)
	delta=delta or 1
	self.count[type]=math.max(0,self.count[type]+delta)
end

function player:move()
	local dx,dy,dodge,rep
	if game.replay then
		rep=game.replay.state
		dodge=rep.first["dodge"]
	else
		rep=keyDown
		dodge=firstPress("dodge")
	end
	dx=rep["right"]-rep["left"]
	dy=rep["down"]-rep["up"]

	if self.immortal>0 then
		self.immortal=self.immortal-1
	end
	if self.large>0 then
		self.large=self.large-0.02
	end
	if (dx~=0 or dy~=0 or dodge) and self.state~="appear" then
		self.t.lmove=0
	else
		self.t.lmove=self.t.lmove+1
		if self.t.lmove>=180 then
			self.t.lmove=0
			self.large=1
			getAllBonus()
		end
	end
	if dodge and player.state~="dying" then
		player:gainSP(-100)
	end
	if player.domain.touched>0 then
		player:addCounter("graze",player.domain.touched)
		player:addCounter("score",(player.domain.touched^2)*4+player.domain.touched*10)
		local gain=player.speed.gain*player.domain.touched
		playSound(game.sound.graze,true)
		player:gainSP(gain)
	end
	if player.state=="dying" then
		if dodge and player.sp>=1000 and game.audio.record.difficulty<=3 then
			player.state="time"
			player.immortal=180
--			game.interval["bullet"]=5
--			game.interval["enemy"]=5
			TM:newTask(timeAttack,player,"player")
		end
		return
	end
	if player.shape.touched>0 and player.immortal==0 and player.state~="dying" then
		player.state="dying"
		TM:newTask(playerDying,player,"player")
	end
	if player.state=="appear" then
		return
	end
	if rep["slow"]>0 then
		dx=dx*self.speed.slow
		dy=dy*self.speed.slow
		if self.sign==nil then
			self.sign=255
		end
	else
		dx=dx*self.speed.fast
		dy=dy*self.speed.fast
		if self.sign then
			self.sign=nil
		end
	end
	if dx~=0 and dy~=0 then
		dx=dx*C.S2_2
		dy=dy*C.S2_2
	end
	updateSpeed(self)
	self.x=self.x+dx
	self.y=self.y+dy
	if self.x<0 then
		self.x=0
	end
	if self.x>game.graphics.width then
		self.x=game.graphics.width
	end
	if self.y<0 then
		self.y=0
	end
	if self.y>game.graphics.height then
		self.y=game.graphics.height
	end
	if dx>0 then
		dx=1
	elseif dx<0 then
		dx=-1
	end
	if dx==0 then
		if self.t.last~=0 then
			if self.t.last>0 then
				self.t.last=self.t.last-1
			else
				self.t.last=self.t.last+1
			end
		else
			self.t.tot=self.t.tot+1
		end
	else
		self.t.tot=0
		self.t.last=self.t.last+dx
		if self.t.last>7 then
			self.t.last=7
		end
		if self.t.last<-7 then
			self.t.last=-7
		end
	end
end

function player:draw(k,alpha)
	k=k or 1.5
	alpha=alpha or 1
	if self.immortal>0 then
		if self.immortal>=60 or (math.ceil(self.immortal/5)%2)==1 then
			love.graphics.setColor(255,255,255,150*alpha)
		else
			love.graphics.setColor(255,255,255,255*alpha)
		end
	else
		love.graphics.setColor(255,255,255,255*alpha)
	end
	local x,y=self.x,self.y
	if self.t.tot==0 then
		if self.t.last<0 then
			love.graphics.draw(self.img.move,self.img.group[1][-self.t.last],x,y,0,k,k,16,24)
		else
			love.graphics.draw(self.img.move,self.img.group[2][self.t.last],x,y,0,k,k,16,24)
		end
	else
		love.graphics.draw(self.img.move,self.img.group[0][self.t.tot%8],x,y,0,k,k,16,24)
	end
end

function player:effect()
	if self.large>0 then
		local k=(3.5-self.large*2)
		player:draw(k,self.large)
	end
	local r=self.r+1

	if self.sign then
		for i=-90,self.sp*360/5001-90,10 do
			local len=30
			local tmp=math.random(r*10,self.R*10)/30
			local x1=self.x+math.cos(i*C.PI/180)*(len+tmp)
			local y1=self.y+math.sin(i*C.PI/180)*(len+tmp)
			local x=self.x+math.cos(i*C.PI/180)*(len-tmp)
			local y=self.y+math.sin(i*C.PI/180)*(len-tmp)
			if i<=-18 then
				love.graphics.setColor(255,255,255,255)
			else
				love.graphics.setColor(0,255,255,255)
			end
			love.graphics.setLineWidth(2)
			love.graphics.line(x,y,x1,y1)
		end
		for i=5,1,-1 do
			love.graphics.setColor(255,0,0,64)
			love.graphics.circle("fill",self.x,self.y,r+i)
		end
		love.graphics.setColor(255,255,255,255)
		love.graphics.circle("fill",self.x,self.y,r)
	end
	if self.domain.touched>0 then
		self.graze:emit(4)
	end
	love.graphics.draw(self.graze)
	love.graphics.draw(self.death)
end

function player:init()
	local img=love.graphics.newImage("data/particle/graze.png")
	local ps = love.graphics.newParticleSystem( img, 32 )
	ps:setParticleLifetime( 0.2, 0.4 )
	ps:setDirection( -1.5708 )
	ps:setSpread( C.PI*2 )
	ps:setSpeed( 100, 300 )

	ps:setLinearAcceleration( 0, 0 )
	ps:setRadialAcceleration( 0, 0 )
	ps:setTangentialAcceleration( -14.2857, -14.2857 )

	ps:setSizes( 0.624107, 0.3125 )
	ps:setSizeVariation( 0 )
	ps:setSpin( -1.5708, 1.5708, 20 )
	ps:setColors( 255, 255, 255, 255, 255, 255, 255, 255 )

	player.graze=ps
	local img=love.graphics.newImage("data/particle/death.png")
	ps = love.graphics.newParticleSystem( img, 64 )

	ps:setParticleLifetime( 0.277778, 0.555556 )
	ps:setDirection( -1.5708 )
	ps:setSpread( 6.28319 )
	ps:setSpeed( -15.873, 634.921 )
	ps:setLinearAcceleration( 0, 0 )
	ps:setRadialAcceleration( 0, 0 )
	ps:setTangentialAcceleration( 0, -14.2857 )
	ps:setSizes( 1.50446, 0.350446)
	ps:setSizeVariation( 0 )
	ps:setSpin( -3.14159, 3.14159, 20 )
	ps:setColors( 255, 255, 255, 255, 255, 255, 255, 0 )
	player.death=ps
end