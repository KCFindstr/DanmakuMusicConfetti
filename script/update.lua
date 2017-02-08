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
	local collisions=GP.collisions(player.shape)
	player.shape.touched=0
	for other,v in pairs(collisions) do
		if other.active and other.type=="bullet" then
			player.shape.touched=player.shape.touched+1
		end
	end
	collisions=GP.collisions(player.domain)
	player.domain.touched=0
	for other,v in pairs(collisions) do
		if other.active and other.type=="bullet" then
			player.domain.touched=player.domain.touched+1
		end
	end
end

--画出判定
function showShape()
	for i=#(bullet),1,-1 do
		local cur=bullet[i]
		if cur.type=="bullet" then
			cur:draw("fill")
		end
	end
	if game.debug>=5 then
		player.shape:draw("line")
		player.domain:draw("line")
	end
end

--进入暂停
function updatePause()
	if SD.state~="play" then
		return
	end
	if firstPress("escape") or ((not game.isFocus) and mList.setting.autopause) then
		if game.audio.music:isPlaying() then
			game.audio.music:pause()
		end
		game.push(updateOption,drawOption)
		option=game.pause
		option.pos=1
		local cur=option[1]
		option.y1=cur.y1
		option.y2=cur.y2
	end
end

--游戏中
function updateGame(dt)
	game.frame=game.frame+1
	TM:update("main")

	player.graze:setPosition(player.x,player.y)
	player.graze:update(dt)
	player.death:update(dt)
	updateShape()
	updatePause()

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
			musicOption(cursor.pos)
		end
	end
	cursor.showpos=toRange(cursor.showpos,whole)
	cursor.rectpos=toRange(cursor.rectpos,whole)

	if firstPress("escape") then
		addGradual(fnil,updateOption,love.draw,drawOption,30,30,true,function(...)
			love.filedropped=nil
			option=game.main
		end)
		SD.first=0
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
			dest=game.width/2-230
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
