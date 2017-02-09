--背景
function drawBackground()
	love.graphics.translate(game.graphics.dx,game.graphics.dy)
	love.graphics.setCanvas(game.tmpCanvas)
	love.graphics.setColor(255,255,255,255)

	local curt=getMusicPosition()
	local pos=1-toRange(curt,game.audio.bpm)/game.audio.bpm
	local R=game.graphics.height
	local function drawDistCircle(dist)
		if dist<0.2 then return end
		local r=R/dist
		love.graphics.setLineWidth(r/R*16)
		love.graphics.circle("line",game.graphics.width/2,game.graphics.height/2,r)
	end
	for i=0,16 do
		drawDistCircle((pos+i)*3)
	end
	
	love.graphics.origin()
	love.graphics.setShader(game.shader.background)
	local cx=(game.graphics.dx+game.graphics.width/2)/game.canvas:getWidth()
	local cy=(game.graphics.dy+game.graphics.height/2)/game.canvas:getHeight()
	game.shader.background:send("cx",cx)
	game.shader.background:send("cy",cy)
	renderTo(game.tmpCanvas,game.canvas)
	love.graphics.setShader()
	love.graphics.setCanvas(game.tmpCanvas)
	love.graphics.clear()
end

--画物体
function drawObject(list)
	for i=#(list),1,-1 do
		local cur=list[i]
		local x,y=cur.x,cur.y
		love.graphics.setColor(cur.color)
		if cur.show then
			cur.show(cur)
		else
			love.graphics.draw(cur.img,x,y,math.rad(cur.r),cur.rate.x,cur.rate.y,cur.width/2,cur.height/2)
		end
	end
end

--游戏
function drawGame(canvas)
	local pre=love.graphics.getBlendMode()
	local curt=getMusicPosition()
	local T={
		prepare=(5+curt)/5,
		duration=curt/game.audio.duration,
		over=(curt-game.audio.duration)/5
	}
	for k,v in pairs(T) do
		T[k]=math.max(0,math.min(1,v))
	end

	love.graphics.setColor(255,255,255,255)
	love.graphics.setCanvas(game.bCanvas,game.canvas,game.tmpCanvas)
	love.graphics.clear()

	drawBackground()

	love.graphics.setCanvas(game.canvas)
	love.graphics.setColor(game.graphics.color)
	love.graphics.rectangle("fill",0,0,game.width,game.height)

	love.graphics.setColor(255,255,255,255)
	love.graphics.translate(game.graphics.dx,game.graphics.dy)
	player:draw()
	drawObject(object)

	love.graphics.setCanvas(game.bCanvas)
	drawObject(bullet)
	drawSignal(game.audio.signal)
	love.graphics.origin()
	if player.state=="time" then
		love.graphics.setCanvas(game.canvas)
		for i=2,#(game.save),2 do
			love.graphics.setColor(255,255,255,200*i/(#(game.save)+1))
			love.graphics.draw(game.save[i])
		end
	end
	local cur=game.save[1]
	for i=1,#(game.save)-1 do
		game.save[i]=game.save[i+1]
	end
	game.save[#(game.save)]=cur
	love.graphics.setCanvas(cur)
	love.graphics.clear()
	love.graphics.draw(game.bCanvas)

	love.graphics.setBlendMode("alpha","premultiplied")
	cur=255-game.graphics.color[4]
	love.graphics.setColor(cur,cur,cur)
	love.graphics.setCanvas(game.canvas)
	love.graphics.draw(game.bCanvas)
	love.graphics.setBlendMode(pre)
	
	love.graphics.translate(game.graphics.dx,game.graphics.dy)

	if game.debug>=5 or player.state=="time" then
		love.graphics.setColor(255,255,255,game.graphics.color[4]*2)
		showShape()
	end
	love.graphics.setColor(255,255,255)
	player:effect()

	love.graphics.origin()
	love.graphics.setBlendMode("alpha","premultiplied")
	love.graphics.setLineWidth(1)

	if T.over==0 then
		love.graphics.setColor(0,255,255)
		love.graphics.rectangle("fill",game.graphics.dx,game.height-30,game.graphics.width*T.prepare,5)
		love.graphics.setColor(255,255,255)
		love.graphics.rectangle("fill",game.graphics.dx,game.height-30,game.graphics.width*T.duration,5)
	else
		love.graphics.setColor(255,255,255)
		love.graphics.rectangle("fill",game.graphics.dx+game.graphics.width*T.over,game.height-30,game.graphics.width*(1-T.over),5)
	end

	for i=1,#(game.active) do
		local shader=game.active[i]
		love.graphics.setShader(shader)
		if i%2==1 then
			love.graphics.setCanvas(game.tmpCanvas)
			love.graphics.draw(game.canvas,0,0)
		else
			love.graphics.setCanvas(game.canvas)
			love.graphics.draw(game.tmpCanvas,0,0)
		end
	end

	if canvas then
		love.graphics.setCanvas(game.preCanvas)
	else
		love.graphics.setCanvas()
	end
	love.graphics.clear()
	love.graphics.setShader()
	if #(game.active)%2==1 then
		love.graphics.draw(game.tmpCanvas,0,0)
	else
		love.graphics.draw(game.canvas,0,0)
	end

	love.graphics.setBlendMode(pre)
	if game.debug>0 then
		love.graphics.setColor(255,255,255,255)
		drawText(love.timer.getFPS().."FPS Bullet: "..#(bullet).." Object: "..#(object),20,10,10)
		local content="task:\n"
		for k,v in pairs(TM) do
			if type(v)=="table" and k~="func" then
				content=content..k..": "..#(v).."\n"
			end
		end
		content=content.."Score: "..player.count.score
		drawText(content,20,10,30)
	end

	if T.over==1 and love.draw~=endGame then
		game.push(love.update,endGame)
	end
end

--菜单
function drawMenu(canvas)
	local pre=love.graphics.getBlendMode()
	love.graphics.setCanvas(game.canvas)
	love.graphics.clear()
	love.graphics.setColor(255,255,255,255)
	drawText("Select Music",50,50,30,"chn")
	drawText("上/下:移动光标 Enter/Z:确认 ESC:返回上级界面\n拖入音乐文件以增加音乐。",26,50,630,"chn")

	love.graphics.setCanvas(game.bCanvas)
	love.graphics.clear()
	local cur, tmp
	if mList.cnt==0 then
		drawText("还没有音乐哦！请拖入音乐文件来识别并生成谱面。",26,50,130,"chn")
	elseif mList.cnt<5 then
		for i=1,mList.cnt do
			cur=mList[i]
			tmp=getMusicName(i)
			drawText(tmp,26,50,100*i,"chn")
			drawText(string.format("Time:%2d:%02d",math.floor(cur.duration/60),math.floor(cur.duration)%60),40,50,100*i+30)
			drawText(string.format("Highscore:%010d",cur.highscore[mList.difficulty]),40,400,100*i+30)
		end
	else
		local pos=math.floor(cursor.showpos/100)
		for i=pos,pos+6 do
			local curpos=i*100-cursor.showpos
			local num=(i-1+mList.cnt)%mList.cnt+1
			cur=mList[num]
			tmp=strSplit(cur.file,"/\\")
			tmp=num..". "..strcut(tmp[#(tmp)],50)
			drawText(tmp,26,50,curpos,"chn")
			drawText(string.format("Time:%2d:%02d",math.floor(cur.duration/60),math.floor(cur.duration)%60),40,50,curpos+30)
			drawText(string.format("Highscore:%010d",cur.highscore[mList.difficulty]),40,400,curpos+30)
		end
	end
	if mList.cnt>0 then
		love.graphics.setLineWidth(3)
		love.graphics.setColor(0,255,255,255)
		love.graphics.rectangle("line",30,toRange(cursor.rectpos-10-cursor.showpos,mList.cnt*100),game.width-60,100)
	end

	love.graphics.setColor(255,255,255,255)
	love.graphics.setCanvas(game.canvas)
	love.graphics.setBlendMode("alpha","premultiplied")
	love.graphics.setShader(game.shader.menu)
	love.graphics.draw(game.bCanvas,0,60)
	love.graphics.setShader()
	love.graphics.setBlendMode(pre)

	game.shader.glow:send("radius",10)
	game.shader.glow:send("height",game.height)
	game.shader.glow:send("width",game.width)
	love.graphics.setShader(game.shader.glow)
	if canvas then
		renderTo(game.canvas,game.preCanvas)
	else
		renderTo(game.canvas)
	end
end

--显示文字
function drawText(content,size,x,y,typ,r)
	typ=typ or "eng"
	r=r or 0
	love.graphics.setFont(game.graphics.font[typ])
	love.graphics.print(content,x,y,r,size/100,size/100)
end

--居中显示文字
function drawMidText(content,size,y,typ)
	local x=game.width/2
	local len=strlen(content)
	x=x-len*size/4
	drawText(content,size,x,y,typ)
end

--准备游戏
function prepareGame(canvas)
	drawGame(true)
	SD.state="play"
	love.graphics.setCanvas(game.tmpCanvas)
	love.graphics.clear()
	renderTo(game.preCanvas,game.tmpCanvas)
	if game.frame<300 then
		if game.frame<60 then
			local tmp=game.frame*255/60
			love.graphics.setColor(tmp,tmp,tmp)
		else
			love.graphics.setColor(255,255,255)
		end
		if canvas then
			renderTo(game.tmpCanvas,game.preCanvas)
		else
			renderTo(game.tmpCanvas)
		end
	else
		game.audio.music:setVolume(mList.setting.bgm)
		game.audio.music:play()
		love.draw=drawGame
		love.draw()
	end
end

--结束
function endGame(canvas)
	SD.state="end"
	game.preDraw(true)
	local curt=getMusicPosition()
	love.graphics.setCanvas(game.tmpCanvas)
	love.graphics.clear()
	renderTo(game.preCanvas,game.tmpCanvas)
	if curt-game.audio.duration-5<1 then
		local tmp=255-(curt-game.audio.duration-5)*255
		love.graphics.setColor(tmp,tmp,tmp)
		if canvas then
			renderTo(game.tmpCanvas,game.preCanvas)
		else
			renderTo(game.tmpCanvas)
		end
	else
		addGradual(love.update,updateOption,love.draw,drawOption,0,30,true,function(...)
			while game.pop() do end
			SD.first=0
		end)
		option=game.report
		game.report[1].id=game.audio.id
		checkAchievement("firstGame")
		addSongCounter(game.audio.id)
	end
end

--画提示
function drawSignal(self)
	local wait=game.audio.bpm*4
	local curt=getMusicPosition()
	for i=1,#(self) do
		local cur=self[i]
		if cur.t-wait<curt and cur.t>curt then
			local r=(cur.t-curt)/wait
			warnpat[cur.type].run(cur,r)
		end
	end
end

--选项
function drawOption(canvas)
	if SD.first==0 then
		SD.first=1
		game.preDraw(true)
		game.shader.blur:send("radius",7)
		game.shader.blur:send("height",game.height)
		game.shader.blur:send("width",game.width)
		love.graphics.setCanvas(game.pCanvas)
		love.graphics.clear()
		love.graphics.setShader(game.shader.blur)
		love.graphics.setColor(255,255,255,255)
		renderTo(game.preCanvas,game.pCanvas)
		love.graphics.setShader()
	end

	if option.draw then
		option.draw(option)
	end
	if canvas then
		canvas=game.preCanvas
	end
	
	love.graphics.setColor(128,128,128)
	renderTo(game.pCanvas,canvas)
	love.graphics.setCanvas(game.canvas,game.tmpCanvas)
	love.graphics.clear()

	local barL=game.width/2-230
	local barR
	local endY=option[#(option)].y2+30
	local confirm=option.confirm

	love.graphics.setCanvas(game.tmpCanvas)
	love.graphics.setColor(255,255,255)
	drawMidText(option.title,50,50,"chn")
	love.graphics.setColor(0,255,255)
	love.graphics.setLineWidth(3)
	if confirm then
		love.graphics.rectangle("line",confirm.x1,endY+90,230,45)
		drawText(confirm.desc,20,barL,endY,"chn")
	else
		love.graphics.rectangle("line",barL-20,option.y1,(game.width/2-barL+20)*2,option.y2-option.y1)
	end
	love.graphics.setColor(255,255,255)
	if confirm then
		if confirm.x1<=barL+20 then
			love.graphics.setCanvas(game.tmpCanvas)
		else
			love.graphics.setCanvas(game.canvas)
		end
		drawText("是",30,game.width/2-130,endY+90,"chn")
		if confirm.x1>=game.width/2-20 then
			love.graphics.setCanvas(game.tmpCanvas)
		else
			love.graphics.setCanvas(game.canvas)
		end
		drawText("否",30,game.width/2+100,endY+90,"chn")
	end

	for i=1,#(option) do
		local cur=option[i]
		if cur.y1>=option.y1-20 and cur.y2<=option.y2+20 and not confirm then
			love.graphics.setCanvas(game.tmpCanvas)
			if cur.desc then
				drawText(cur.desc,20,barL,endY,"chn")
			end
		else
			love.graphics.setCanvas(game.canvas)
		end
		if cur.type=="button" then
			drawMidText(cur.text,30,cur.y1,"chn")
		elseif cur.type=="slider" then
			drawMidText(cur.text,30,cur.y1,"chn")
			love.graphics.setLineWidth(5)
			barR=cur.value*400+barL
			love.graphics.line(barL-1,cur.y1+50,barR,cur.y1+50)
			drawText(cur.vtext,30,barL+410,cur.y1+30)
		elseif cur.type=="list" then
			drawText(cur.text,30,barL,cur.y1,"chn")
			if #(cur.list)>1 then
				local triangle={game.width/2,cur.y1+22,game.width/2+20,cur.y1+9,game.width/2+20,cur.y1+35}
				love.graphics.polygon("fill",triangle)
				triangle[1]=triangle[1]+220
				triangle[3]=triangle[3]+180
				triangle[5]=triangle[5]+180
				love.graphics.polygon("fill",triangle)
			end
			local text=cur.list[cur.pos]
			local len=strlen(text)
			local lang=cur.lang or "chn"
			drawText(text,30,game.width/2+110-len*8,cur.y1,lang)
		end
	end

	love.graphics.setShader(game.shader.glow)
	game.shader.glow:send("radius",10)
	game.shader.glow:send("height",game.height)
	game.shader.glow:send("width",game.width)
	renderTo(game.tmpCanvas,canvas)
	love.graphics.setShader()
	renderTo(game.canvas,canvas)
end

--绘制得分界面
function drawReport(canvas)
	
end

--渐变
function drawGradual(canvas)
	local data=game.graphics.data
	local preD=data.preD
	local preU=data.preU
	local preT=data.preT
	local nextD=data.nextD
	local nextU=data.nextU
	local nextIgnore=data.nextIgnore
	local nextT=data.nextT
	local alpha
	if not data.frame then
		data.frame=0
		love.update=preU
	end
	data.frame=data.frame+1
	if data.frame<=preT then
		alpha=255-(preT-data.frame)/preT*255
		preD()
	else
		alpha=255-(data.frame-preT)/nextT*255
		nextD()
	end
	love.graphics.setColor(0,0,0,alpha)
	love.graphics.rectangle("fill",0,0,game.width,game.height)

	if data.frame==preT then
		if not nextIgnore then
			love.update=nextU
		end
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