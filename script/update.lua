--速度更新
function updateSpeed(self)
	local rad=self.v.r
	self.x=self.x+self.v.x
	self.y=self.y+self.v.y
	if self.a then
		self.v.x=self.v.x+self.a.x
		self.v.y=self.v.y+self.a.y
	end
end

--更新
function updateBullet()
	local out=160
	for i=#(bullet),1,-1 do
		local cur=bullet[i]
		updateSpeed(cur)
		if cur.t<12 then
			local tmp=cur.t/12
			cur.rate.x=1.5-tmp/2
			cur.rate.y=1.5-tmp/2
			cur.color[4]=tmp*255
		elseif cur.t==12 then
			cur.color[4]=255
			cur.active=true
		end
		cur.t=cur.t+1
		if cur.x<-out or cur.y<-out or cur.x>game.graphics.width+out or cur.y>game.graphics.height+out then
			destroy(cur)
		end
	end
end

--更新判定
function updateShape()
	for i=#(bullet),1,-1 do
		local cur=bullet[i]
		local x,y=vecRotate(cur.d,cur.r)
		cur:moveTo(cur.x+x,cur.y+y)
		cur:setRotation(math.rad(cur.r))
	end
	player.shape:moveTo(player.x,player.y)
	player.domain:moveTo(player.x,player.y)
	player.shape.touched=0
	player.domain.touched=0
	if player.immortal==0 then
		local collisions=GP:collisions(player.shape)
		for other,v in pairs(collisions) do
			if other.active and other.type=="bullet" then
				player.shape.touched=player.shape.touched+1
			end
		end
		collisions=GP:collisions(player.domain)
		for other,v in pairs(collisions) do
			if other.active and other.type=="bullet" then
				player.domain.touched=player.domain.touched+1
			end
		end
	end
end

--进入暂停
function updatePause()
	if firstPress("escape") or ((not game.isFocus) and mList.setting.autopause) then
		if game.audio.music:isPlaying() then
			game.audio.music:pause()
		end
		game.push(updateOption,drawOption)
		if game.replay then
			option=getReplayOption()
		else
			option=getPauseOption()
		end
		option.pos=1
		local cur=option[1]
		option.y1=cur.y1
		option.y2=cur.y2
	end
end

--更新计时器
function updateTimer()
	game.frame=game.frame+1
	if game.frame==300 then
		game.audio.music:setVolume(mList.setting.bgm)
		game.audio.music:play()
	end
	if game.replay then
		game.audio.pos=game.replay.state.musicT
	else
		if game.audio.music:isStopped() and game.audio.music:tell()==0 then
			if game.audio.pos<=0 then
				game.audio.pos=game.frame/60-5
			else
				game.audio.pos=game.audio.duration+(game.frame-game.audio.endframe)/60
			end
		else
			game.audio.endframe=game.frame
			game.audio.pos=game.audio.music:tell()
		end
	end
end

--游戏中
function updateGame(dt)
	updateTimer()

	TM:update("main")

	player.graze:setPosition(player.x,player.y)
	player.graze:update(dt)
	player.death:update(dt)
	updateShape()
	updatePause()

	recordGame(dt)

	if math.abs(game.audio.pos-game.audio.duration-5)<=C.eps then
		if game.replay then 
			endReplay()
		else
			endGame()
		end
	end

	updateKey(dt)
	collectgarbage()
end

--菜单
function updateMenu(dt)
	if firstPress("up") or repeatPress("up") then
		cursor.pos=cursor.pos-1
	end
	if firstPress("down") or repeatPress("down") then
		cursor.pos=cursor.pos+1
	end
	if cursor.pos==0 then cursor.pos=mList.cnt end
	if cursor.pos==mList.cnt+1 then cursor.pos=1 end
	local whole=mList.cnt*100
	local dest=toRange(cursor.pos*100,whole)
	local cur=cursor.rectpos
	local delta=0
	if keyDown["up"]>0 then
		delta=1
	elseif keyDown["down"]>0 then
		delta=-1
	end
	if mList.cnt>0 then
		if math.abs(dest-cur)>C.eps or not inRange(cursor.rectpos,cursor.showpos+100,cursor.showpos+400,whole) then
			local choice,dist
			if (dest>cur and dest-cur+delta>cur-dest+whole) or (dest<cur and cur-dest-delta<dest-cur+whole) then
				choice="up"
				if dest>cur then
					dist=cur-dest+whole
				else
					dist=cur-dest
				end
			else
				choice="down"
				if dest>cur then
					dist=dest-cur
				else
					dist=dest-cur+whole
				end
			end
			local move=math.min(dist,math.ceil(math.sqrt(dist)*3))
			if choice=="up" then
				cursor.rectpos=cursor.rectpos-move
			else
				cursor.rectpos=cursor.rectpos+move
			end
			if mList.cnt>=5 and (not inRange(cursor.rectpos,cursor.showpos+100,cursor.showpos+400,whole)) then
				if choice=="up" then
					cursor.showpos=cursor.rectpos-100
				else
					cursor.showpos=cursor.rectpos-400
				end
			end
		elseif firstPress("fire") or firstPress("enter") then
			if game.replay then
				option=replayOption(cursor.pos)
				game.push(updateOption,drawOption)
			else
				musicOption(cursor.pos)
			end
		end
	end
	cursor.showpos=toRange(cursor.showpos,whole)
	cursor.rectpos=toRange(cursor.rectpos,whole)

	if firstPress("escape") and love.update==updateMenu then
		addGradual(fnil,updateOption,love.draw,drawOption,30,30,true,function(...)
			love.filedropped=nil
			game.replay=nil
			option=game.main
			SD.first=0
		end)
	end
	updateKey(dt)
	collectgarbage()
end

--选项
function updateOption(dt)
	if option.update then
		option.update(option,dt)
	end
	if option.confirm then
		local cur=option.confirm
		local width=option.width or 230
		if mList.setting.cycle then
			if firstPress("right") or firstPress("left") then
				cur.pos=3-cur.pos
			end
		else
			if firstPress("right") then
				cur.pos=2
			end
			if firstPress("left") then
				cur.pos=1
			end
		end
		local dest
		if cur.pos==1 then
			dest=game.width/2-width
		else
			dest=game.width/2
		end
		local dist=math.abs(dest-cur.x1)
		local walk=math.min(math.ceil(math.sqrt(dist)*3),dist)
		if walk>0 then
			if dest>cur.x1 then
				cur.x1=cur.x1+walk
			else
				cur.x1=cur.x1-walk
			end
		elseif firstPress("fire") or firstPress("enter") then
			if cur.pos==1 then
				option[option.pos].click(option[option.pos])
			end
			option.confirm=nil
		elseif firstPress("escape") then
			option.confirm=nil
		end

		updateKey(dt)
		collectgarbage()
		return
	end
	if firstPress("up") or repeatPress("up") then
		option.pos=option.pos-1
	end
	if firstPress("down") or repeatPress("down") then
		option.pos=option.pos+1
	end
	keyReset("left",0.05)
	keyReset("right",0.05)
	if mList.setting.cycle then
		if option.pos==#(option)+1 then
			option.pos=1
		end
		if option.pos==0 then
			option.pos=#(option)
		end
	else
		option.pos=math.max(option.pos,1)
		option.pos=math.min(option.pos,#(option))
	end
	local target=option[option.pos]
	local y1,y2=target.y1,target.y2
	if option.y1~=y1 or option.y2~=y2 then
		local dist1=math.abs(y1-option.y1)
		local dist2=math.abs(y2-option.y2)
		local walk1=math.min(math.ceil(math.sqrt(dist1)*3),dist1)
		local walk2=math.min(math.ceil(math.sqrt(dist2)*3),dist2)
		if y1>option.y1 then
			option.y1=option.y1+walk1
		else
			option.y1=option.y1-walk1
		end
		if y2>option.y2 then
			option.y2=option.y2+walk2
		else
			option.y2=option.y2-walk2
		end
	else
		if target.hover then
			target.hover(target,dt)
		end
		if target.click then
			if firstPress("enter") or firstPress("fire") then
				if target.confirm then
					applyConfirm()
				else
					target.click(target)
				end
			end
		end
		if target.move then
			if firstPress("left") or repeatPress("left") then
				target.move(target,-1)
			end
			if firstPress("right") or repeatPress("right") then
				target.move(target,1)
			end
		end
		if target.change then
			local changed=false
			if firstPress("left") or repeatPress("left") then
				target.pos=target.pos-1
				changed=true
			end
			if firstPress("right") or repeatPress("right") then
				target.pos=target.pos+1
				changed=true
			end
			if target.pos==#(target.list)+1 then
				target.pos=1
			end
			if target.pos==0 then
				target.pos=#(target.list)
			end
			if changed then
				target.change(target)
			end
		end
	end
	if option.hotkey then
		for k,v in pairs(option.hotkey) do
			if firstPress(k) then
				v(option)
			end
		end
	end

	updateKey(dt)
	collectgarbage()
end

function updateInputText(dt)
	local keys=game.keyboard
	if keys.res==nil then return end
	keys.frame=keys.frame+1
	local dx,dy,size=0,0,keys.size
	if firstPress("up") or repeatPress("up") then dy=dy-1 end
	if firstPress("down") or repeatPress("down") then dy=dy+1 end
	if firstPress("left") or repeatPress("left") then dx=dx-1 end
	if firstPress("right") or repeatPress("right") then dx=dx+1 end
	keys.pos.x=keys.pos.x+dx
	keys.pos.y=keys.pos.y+dy
	if mList.setting.cycle then
		if keys.pos.x==0 then keys.pos.x=#(keys[1]) end
		if keys.pos.x>#(keys[1]) then keys.pos.x=1 end
		if keys.pos.y==0 then keys.pos.y=#(keys) end
		if keys.pos.y>#(keys) then keys.pos.y=1 end
	else
		keys.pos.x=math.max(math.min(keys.pos.x,#(keys[1])),1)
		keys.pos.y=math.max(math.min(keys.pos.y,#(keys)),1)
	end

	local px,py=game.width/2-size*5,200
	local x=px+(keys.pos.x-1)*size
	local y=py+(keys.pos.y-1)*size

	if keys.x~=x or keys.y~=y then
		local tmp=math.abs(keys.x-x)
		local walkx=math.min(tmp,math.sqrt(tmp)*3)
		if keys.x<x then
			keys.x=keys.x+walkx
		else
			keys.x=keys.x-walkx
		end
		local tmp=math.abs(keys.y-y)
		local walky=math.min(tmp,math.sqrt(tmp)*3)
		if keys.y<y then
			keys.y=keys.y+walky
		else
			keys.y=keys.y-walky
		end
	elseif firstPress("enter") or firstPress("fire") or repeatPress("enter") or repeatPress("fire") then
		x,y=keys.pos.x,keys.pos.y
		if keys[y][x]=="<" then
			if string.len(keys.res)>0 then
				keys.res=string.sub(keys.res,1,-2)
			end
		elseif keys[y][x]=="×" then
			keys.onEnd(nil)
			game.pop()
		elseif keys[y][x]=="√" then
			keys.onEnd(keys.res)
			game.pop()
		elseif string.len(keys.res)<24 then
			keys.res=keys.res..keys[y][x]
		end
	elseif firstPress("escape") then
		keys.onEnd(nil)
		game.pop()
	end

	updateKey(dt)
	collectgarbage()
end

--渐变更新
function updateGradual(dt)
	local data=game.graphics.data
	local preU=data.preU
	local preT=data.preT
	local nextU=data.nextU
	local nextD=data.nextD
	local nextIgnore=data.nextIgnore
	local nextT=data.nextT
	data.frame=data.frame+1
	if data.frame<=preT then
		preU(dt)
	elseif not nextIgnore then
		nextU(dt)
	end

	if data.frame==preT then
		if data.onEnd then
			data.onEnd(data)
		end
	end
	if data.frame==preT+nextT then
		love.draw=nextD
		love.update=nextU
		game.graphics.data=nil
	end
end

--结束
function endGame()
	addGradual(love.update,updateOption,love.draw,drawOption,60,30,true,function(...)
		game.state={}
		SD.first=0
		checkAchievement("firstGame"..game.audio.record.difficulty)
		addSongCounter(game.audio.id)
		if player.count.death==0 then
			checkAchievement("firstPerfect")
		end
		option=endGameOption(game.audio.id)
		fileSave()
	end)
end

--更新报告界面
function updateReport(self,dt)
	if self.bar<1 then
		local delta=math.max(0.001,0.05*(1-self.bar))
		self.bar=math.min(self.bar+delta,1)
		playSound(game.sound.scorecounter)
	elseif self.bar<10 then
		if self.death==0 then
			self.bar=self.bar+0.1
		else
			self.bar=100
		end
	elseif self.bar<100 then
		self.bar=5/6
		self.score=math.floor(self.score*1.2)
		self.death=false
	else
		self.bar=math.min(self.bar+5,355)
	end
end