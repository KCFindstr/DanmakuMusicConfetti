TM={
	func={},
	bullet={},
	enemy={},
	player={},
	bonus={},
	level={},
	system={},
	draw={},
	state="game"
}

function TM:init()
	for k,v in pairs(self) do
		if k~="func" and type(v)=="table" then
			self[k]={}
		end
	end
	for k,v in pairs(game.interval) do
		game.interval[k]=1
	end
	self.state="game"
end

function TM:remove(obj,typ)
	if not self[typ] then
		return
	end
	for i=#(self[typ]),1,-1 do
		if self[typ][i].obj==obj then
			self[typ][i].task=nil
		end
	end
end


function TM:newTask(task,obj,typ)
	if task==nil then
		return
	end
	typ=typ or "main"
	if not self[typ] then
		self[typ]={}
	end
	local tmp={
		obj=obj,
		task=coroutine.create(task),
		next=0
	}
	table.insert(self[typ],tmp)
end

function TM.func.bullet()
	while true do
		updateBullet()
		TM:update("bullet")
		coroutine.yield(game.interval["bullet"])
	end
end

function TM.func.player()
	while true do
		player:move()
		TM:update("player")
		coroutine.yield(game.interval["player"])
	end
end

function TM.func.enemy()
	while true do
		TM:update("enemy")
		coroutine.yield(game.interval["enemy"])
	end
end

function TM.func.bonus()
	while true do
		TM:update("bonus")
		coroutine.yield(game.interval["bonus"])
	end
end

function TM.func.level()
	while true do
		TM:update("level")
		coroutine.yield(game.interval["level"])
	end
end

function TM.func.system()
	local frameMonitor=false
	local last=0
	while true do
		local curFPS=math.ceil(love.timer.getFPS()-C.eps)
		if curFPS<50 then
			last=last+1
		else
			last=0
		end
		if last>180 and not frameMonitor then
			frameMonitor=true
			addMessage("系统 System",
				"警告：你当前的FPS为"..curFPS.."\n（推荐为60FPS）\n请检查屏幕刷新率是否为60Hz，\n或者关掉占用大量资源的程序。",
				{0,128,255},nil,nil,nil,nil,170
			)
		end
		TM:update("system")
		coroutine.yield(game.interval["system"])
	end
end

function TM:update(typ)
	if not typ then
		debug("Warning: no type read but required.")
		return
	end
	if self.state=="pause" and typ~="system" then
		return
	end
	local queue=self[typ]
	if not queue then
		return
	end
	for i=#(queue),1,-1 do
		local tmp=queue[i]
		if tmp.next==0 or
		(game.audio.music and game.audio.music:isPlaying() and tmp.next<0 and -tmp.next<=game.audio.music:tell()) then
			if tmp.task==nil or (tmp.obj and tmp.obj.removed) then
				table.remove(queue,i)
			else
				local back, next=coroutine.resume(tmp.task,tmp.obj)
				if back==false or next==nil then
					if back==false then
						debug("Coroutine Error: "..next)
					end
					table.remove(queue,i)
				else
					tmp.next=next
				end
			end
		end
		if tmp.next>0 then
			tmp.next=tmp.next-1
		end
	end
end