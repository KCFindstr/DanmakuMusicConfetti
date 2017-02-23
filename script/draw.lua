--背景
function drawBackground()
	love.graphics.translate(game.graphics.dx,game.graphics.dy)
	love.graphics.setCanvas(game.tmpCanvas)
	love.graphics.setColor(255,255,255,255)

	local curt=game.audio.pos
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

--游戏
function drawGame(canvas)
	local pre=love.graphics.getBlendMode()
	local curt=game.audio.pos
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
		for i=3,#(game.save),3 do
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
	
	--绘制UI
	love.graphics.setColor(255,255,255)
	love.graphics.draw(game.image.bg)
	local barL=game.graphics.width+game.graphics.dx*2
	love.graphics.draw(game.image["diff"..game.audio.record.difficulty],(game.width-barL)/2+barL,
		game.graphics.dy,0,1,1,100,25)
	love.graphics.setFont(game.graphics.font.eng)
	love.graphics.printf(player.count.score,840,225,800,"right",0,0.25)
	love.graphics.printf(player.count.graze,840,265,800,"right",0,0.25)
	love.graphics.printf(string.format("%.3f / 5.000",player.sp/1000),840,305,800,"right",0,0.25)
	if game.audio.record.difficulty<=3 then
		cur=string.format("%d (+%d)",player.count.death,player.count.bomb)
	else
		cur=tostring(player.count.death)
	end
	love.graphics.printf(cur,840,345,800,"right",0,0.25)

	love.graphics.setFont(game.graphics.font.chn)
	local tmp=getMusicName(game.audio.id).."\n"
	if T.over>0 or T.prepare<1 then
		tmp=tmp.."--:--"
	else
		tmp=tmp..getTimeFormat(game.audio.music:tell())
	end
	tmp=tmp.." / "..getTimeFormat(game.audio.duration)
	love.graphics.printf(tmp,700,80,1440,"center",0,0.25)
	love.graphics.setColor(255,0,0)

	love.graphics.setFont(game.graphics.font.digit)
	love.graphics.print(tostring(love.timer.getFPS()),700,20,0,0.5)

	love.graphics.setLineWidth(1)
	if T.over==0 then
		love.graphics.setColor(0,255,255)
		love.graphics.rectangle("fill",game.graphics.dx,game.height-20,game.graphics.width*T.prepare,5)
		love.graphics.setColor(255,255,255)
		love.graphics.rectangle("fill",game.graphics.dx,game.height-20,game.graphics.width*T.duration,5)
	else
		love.graphics.setColor(255,255,255)
		love.graphics.rectangle("fill",game.graphics.dx+game.graphics.width*T.over,game.height-20,game.graphics.width*(1-T.over),5)
	end

	if game.debug>0 then
		love.graphics.setColor(255,255,255)
		drawText("Bullet: "..#(bullet).." Object: "..#(object),20,10,10)
		local content="task:\n"
		for k,v in pairs(TM) do
			if type(v)=="table" and k~="func" then
				content=content..k..": "..#(v).."\n"
			end
		end
		content=content.."Score: "..player.count.score
		drawText(content,20,10,30)
	end
end

--菜单
function drawMenu(canvas)
	local pre=love.graphics.getBlendMode()
	local cur, tmp
	tmp={"Easy","Normal","Hard","Lunatic"}
	love.graphics.setCanvas(game.canvas)
	love.graphics.clear()
	love.graphics.setColor(255,255,255)
	if game.replay then
		cur="Select Music [Replay]"
	else
		cur="Select Music ["..tmp[mList.difficulty].."]"
	end
	drawText(cur,50,50,30,"chn")
	cur="上/下:移动光标 Enter/Z:确认 ESC:返回上级界面"
	if not game.replay then
		cur=cur.."\n拖入音乐文件以增加音乐。"
	end
	drawText(cur,26,50,630,"chn")

	love.graphics.setCanvas(game.bCanvas)
	love.graphics.clear()
	if mList.cnt==0 then
		drawText("还没有音乐文件！",26,50,130,"chn")
	elseif mList.cnt<5 then
		for i=1,mList.cnt do
			cur=mList[i]
			tmp=getMusicName(i)
			drawText(tmp,26,50,100*i,"chn")
			drawText(string.format("Time:%2d:%02d",math.floor(cur.duration/60),math.floor(cur.duration)%60),40,50,100*i+30)
			if game.replay then
				tmp="Replay: "..#(cur.replay)
			else
				tmp=string.format("Highscore:%010d",cur.highscore[mList.difficulty])
			end
			drawText(tmp,40,400,100*i+30)
		end
	else
		local pos=math.floor(cursor.showpos/100)
		for i=pos,pos+6 do
			local curpos=i*100-cursor.showpos
			local num=(i-1+mList.cnt)%mList.cnt+1
			cur=mList[num]
			tmp=getMusicName(num)
			drawText(tmp,26,50,curpos,"chn")
			drawText(string.format("Time:%2d:%02d",math.floor(cur.duration/60),math.floor(cur.duration)%60),40,50,curpos+30)
			if game.replay then
				tmp="Replay: "..#(cur.replay)
			else
				tmp=string.format("Highscore:%010d",cur.highscore[mList.difficulty])
			end
			drawText(tmp,40,400,curpos+30)
		end
	end
	if mList.cnt>0 then
		love.graphics.setLineWidth(3)
		love.graphics.setColor(0,255,255)
		love.graphics.rectangle("line",30,toRange(cursor.rectpos-10-cursor.showpos,mList.cnt*100),game.width-60,100)
	end

	love.graphics.setColor(255,255,255)
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
		love.graphics.setCanvas(game.preCanvas)
		love.graphics.clear()
		renderTo(game.canvas,game.preCanvas)
	else
		renderTo(game.canvas)
	end
	love.graphics.setShader()
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
	x=x-len*size*1.1/4
	drawText(content,size,x,y,typ)
end

--画提示
function drawSignal(self)
	local wait=game.audio.bpm*4
	local curt=game.audio.pos
	for i=#(self),1,-1 do
		local cur=self[i]
		if not cur.color then
			cur.color={255,0,0}
		end
		if not cur.type then
			cur.type="default"
		end
		if cur.t-wait<curt and cur.t>curt then
			local r=(cur.t-curt)/wait
			warnpat[cur.type].run(cur,r)
		end
		if cur.t<curt then
			table.remove(self,i)
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

	if canvas then
		canvas=game.preCanvas
	end

	love.graphics.setCanvas(game.canvas,game.tmpCanvas)
	love.graphics.clear()

	if option.draw then
		love.graphics.setCanvas(game.canvas)
		option.draw(option)
	end
	
	love.graphics.setColor(128,128,128)
	renderTo(game.pCanvas,canvas)

	local width=option.width or 230
	local fontsize=option.fontsize or 30
	local barL=game.width/2-width
	local endY=option[#(option)].y2+fontsize/2
	local confirm=option.confirm

	love.graphics.setCanvas(game.tmpCanvas)
	love.graphics.setColor(255,255,255)
	drawMidText(option.title,50,50,"chn")
	love.graphics.setColor(0,255,255)
	love.graphics.setLineWidth(3)
	if confirm then
		love.graphics.rectangle("line",confirm.x1,endY+90,width,45)
		drawText(confirm.desc,20,barL,endY,"chn")
	else
		love.graphics.rectangle("line",barL-20,option.y1,(width+20)*2,option.y2-option.y1)
	end
	love.graphics.setColor(255,255,255)
	if confirm then
		if confirm.x1<=barL+20 then
			love.graphics.setCanvas(game.tmpCanvas)
		else
			love.graphics.setCanvas(game.canvas)
		end
		drawText("是",30,game.width/2-width/2-15,endY+90,"chn")
		if confirm.x1>=game.width/2-20 then
			love.graphics.setCanvas(game.tmpCanvas)
		else
			love.graphics.setCanvas(game.canvas)
		end
		drawText("否",30,game.width/2+width/2-15,endY+90,"chn")
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
			local lang=cur.lang or "chn"
			drawMidText(cur.text,fontsize,cur.y1,lang)
		elseif cur.type=="slider" then
			local lang=cur.lang or "chn"
			drawMidText(cur.text,fontsize,cur.y1,lang)
			love.graphics.setLineWidth(5)
			local barR=cur.value*(width-30)*2+barL
			local tmp=fontsize*1.7+cur.y1
			love.graphics.line(barL-1,tmp,barR,tmp)
			drawText(cur.vtext,fontsize,barL+(width-30)*2+10,cur.y1+fontsize)
		elseif cur.type=="list" then
			drawText(cur.text,fontsize,barL,cur.y1,"chn")
			local quarter=math.floor(fontsize/4)
			if #(cur.list)>1 then
				local triangle={game.width/2,cur.y1+quarter*3,game.width/2+quarter*3,cur.y1+quarter,game.width/2+quarter*3,cur.y1+quarter*5}
				love.graphics.polygon("fill",triangle)
				triangle[1]=triangle[1]+width+quarter*3-30
				triangle[3]=triangle[3]+width-quarter*3-30
				triangle[5]=triangle[5]+width-quarter*3-30
				love.graphics.polygon("fill",triangle)
			end
			local text=cur.list[cur.pos]
			local len=strlen(text)
			local lang=cur.lang or "chn"
			drawText(text,fontsize,game.width/2+width/2-len*(quarter+1),cur.y1,lang)
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
function drawReport(self)
	local width=self.width or 230
	local val1=math.max(C.eps,self.score)
	local val2=math.max(C.eps,self.highscore)
	if self.death==0 then val1=math.max(C.eps,self.score*1.2) end
	local bar=math.min(1,self.bar)
	local rate=val1/val2
	local len1,len2
	local triangle={-5,-20,5,-20,0,-5}
	if val1>=val2*1.5 then
		len1=width*1.8
		len2=len1/rate
	else
		len2=width*1.2
		len1=len2*rate
	end
	len1=len1*bar
	if self.death==0 then len1=len1*5/6 end

	len1=math.max(len1,1)
	len2=math.max(len2,1)
	val1=math.floor(self.score*bar)
	val2=math.floor(val2)

	love.graphics.setFont(game.graphics.font.digit)
	love.graphics.setColor(255,255,255)
	local leftbar=game.width/2-width
	love.graphics.printf("HIGHSCORE\n"..val2,leftbar+len2-100,240,800,"center",0,0.25)
	local cur=copyFrom(triangle)
	for i=1,#(cur),2 do
		cur[i]=cur[i]+leftbar+len2
		cur[i+1]=cur[i+1]+320
	end
	love.graphics.polygon("fill",cur)
	love.graphics.rectangle("fill",leftbar,320,len2,5)

	love.graphics.setColor(0,255,255)
	cur="SCORE"
	if self.death==0 then
		if self.bar>2 then cur=cur.." " end
		if self.bar>3 then cur=cur.."x" end
		if self.bar>4 then cur=cur.."1" end
		if self.bar>5 then cur=cur.."." end
		if self.bar>6 then cur=cur.."2" end
	elseif self.score>self.highscore and self.bar>100 then
		love.graphics.setColor(255,0,0,self.bar-100)
		love.graphics.print("NEW HIGHSCORE!",leftbar+len1+5,205,0,0.25)
		love.graphics.setColor(0,255,255)
	end
	cur=cur.."\n"..val1
	love.graphics.printf(cur,leftbar+len1-100,140,800,"center",0,0.25)
	cur=copyFrom(triangle)
	for i=1,#(cur),2 do
		cur[i]=cur[i]+leftbar+len1
		cur[i+1]=cur[i+1]+220
	end
	love.graphics.polygon("fill",cur)
	love.graphics.rectangle("fill",leftbar,220,len1,5)
end

--渐变
function drawGradual(canvas)
	local data=game.graphics.data
	local preD=data.preD
	local preT=data.preT
	local nextD=data.nextD
	local nextIgnore=data.nextIgnore
	local nextT=data.nextT
	local alpha
	if data.frame<=preT then
		alpha=255-(preT-data.frame)/preT*255
		preD(canvas)
	else
		alpha=255-(data.frame-preT)/nextT*255
		nextD(canvas)
	end
	if canvas then
		love.graphics.setCanvas(game.preCanvas)
	else
		love.graphics.setCanvas()
	end
	love.graphics.setColor(0,0,0,alpha)
	love.graphics.rectangle("fill",0,0,game.width,game.height)
end

--输入文字
function drawInputText(canvas)
	local keys=game.keyboard
	local size=keys.size
	local text=keys.text

	if SD.first==0 then
		SD.first=1
		game.preDraw(true)
		game.shader.blur:send("radius",7)
		game.shader.blur:send("height",game.height)
		game.shader.blur:send("width",game.width)
		love.graphics.setCanvas(game.keyCanvas)
		love.graphics.clear()
		love.graphics.setShader(game.shader.blur)
		love.graphics.setColor(255,255,255,255)
		renderTo(game.preCanvas,game.keyCanvas)
		love.graphics.setShader()

		keys.res=""
		keys.x=game.width/2-size*5
		keys.y=200
		keys.frame=0
		keys.pos={x=1,y=1}
	end

	if canvas then
		canvas=game.preCanvas
	end
	local px,py=game.width/2-size*5,200
	
	love.graphics.setCanvas(game.canvas,game.tmpCanvas)
	love.graphics.clear()
	love.graphics.setColor(128,128,128)
	renderTo(game.keyCanvas,canvas)

	love.graphics.setCanvas(game.tmpCanvas)
	love.graphics.setColor(255,255,255)
	drawMidText(keys.title,50,50,"chn")
	drawText(text,20,px,py+size*(#(keys)+1),"chn")
	if keys.frame%30<15 then
		drawMidText(keys.res.."_",50,130)
	else
		drawMidText(keys.res.." ",50,130)
	end
	love.graphics.setColor(0,255,255)
	love.graphics.setLineWidth(3)
	love.graphics.rectangle("line",keys.x,keys.y,size+5,size+5)

	love.graphics.setColor(255,255,255)
	for i=1,#(keys) do
		for j=1,#(keys[i]) do
			if i==#(keys) and j>=#(keys[i])-2 then
				love.graphics.setColor(0,255,255)
			end
			local x=px+(j-1)*size
			local y=py+(i-1)*size
			if x>=keys.x and x<=keys.x+5 and y>=keys.y and y<=keys.y+5 then
				love.graphics.setCanvas(game.tmpCanvas)
			else
				love.graphics.setCanvas(game.canvas)
			end
			drawText(keys[i][j],size,x+15,y-3)
		end
	end

	--分别绘制不同shader
	love.graphics.setColor(255,255,255)
	love.graphics.setShader(game.shader.glow)
	game.shader.glow:send("radius",10)
	game.shader.glow:send("height",game.height)
	game.shader.glow:send("width",game.width)
	renderTo(game.tmpCanvas,canvas)
	love.graphics.setShader()
	renderTo(game.canvas,canvas)
end