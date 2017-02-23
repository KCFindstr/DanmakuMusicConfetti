require("ShimakazeDet")

SD={
	count=0,
	rate=0,
	sound={},
	beat={},
	energy={},
	part=1024,
	bpm=0,
	begin=0,
	music=nil,
	process=0,
	pos=0,
	file=nil,
	routine=nil,
	first=0,
	ext=nil,
	state=nil
}

function SD:init()
	self.music=nil
	self.file=nil
	self.ext=nil
	self.count=nil
	self.rate=nil
	self.sound={}
	self.beat={}
	self.energy={}
	self.bpm=0
	self.begin=0
	self.process=0
	self.pos=0
	self.first=0
	self.routine=nil
end

function SD:loadData(file,part)
	local tmp=strSplit(file:getFilename(),".")
	tmp=string.lower(tmp[#(tmp)])
	if tmp~="mp3" and tmp~="wav" then
		return false
	end
	self.music=love.sound.newSoundData(file)
	self.file=file
	self.ext=tmp
	self.count=self.music:getSampleCount()
	self.rate=self.music:getSampleRate()
	self.sound={}
	self.beat={}
	self.energy={}
	self.part=part or self.part
	self.bpm=0
	self.begin=0
	self.process=0
	self.pos=0
	self.first=0
	self.routine=nil
	ShimakazeDet.init(-1)
	if self.music:getChannels()==1 then
		for i=0,self.count-1 do
			self.sound[i]=self.music:getSample(i)
		end
	else
		for i=0,self.count-1 do
			self.sound[i]=(self.music:getSample(i*2)+self.music:getSample(i*2+1))/2
		end
	end
	return true
end

function SD:analyze()
	self.pos=self.pos+1
	local L=self.pos
	local R=L*self.part-1
	L=(L-1)*self.part
	if L<0 or R>=self.count then
		return -1
	end
	ShimakazeDet.init(1)
	self.energy[self.pos]=0
	for i=L,R do
		self.energy[self.pos]=self.energy[self.pos]+math.abs(self.sound[i])
		ShimakazeDet.insert(self.sound[i])
	end
	ShimakazeDet.calculate(R/self.rate)
	self.process=R/self.count*0.8
	self.energy[self.pos]=self.energy[self.pos]/self.part
	return self.process*0.8
end

function SD:getFFT(mid)
	local L,R=mid-self.part/2,mid+self.part/2-1
	if L<0 or R>=self.count then
		return
	end
	ShimakazeDet.init(1)
	for i=L,R do
		ShimakazeDet.insert(self.sound[i])
	end
	return ShimakazeDet.FFT()
end

function SD:getSample(t)
	return self.sound[t]
end

function SD:finish()
	self.beat={ShimakazeDet.beats()}
	self.bpm,self.begin=ShimakazeDet.BPM()
end

function SD:getPart(t)
	return math.ceil(t*self.rate/self.part)
end

function SD:getEnergyP(p)
	local L,R=math.max(1,p-10),math.min(#(self.energy),p+10)
	local len=R-L+1
	local val=0
	for i=L,R do
		val=val+self.energy[i]
	end
	return val/len
end

function SD:getEnergy(t)
	local p=self:getPart(t)
	return SD:getEnergyP(p)
end

function sortByTime(obja,objb)
	return obja.t<objb.t
end

function getNotes(self)
	--过滤过密音符
	for i=#(self.beat),2,-1 do
		if self.beat[i]-self.beat[i-1]<self.bpm/5 then
			table.remove(self.beat,i)
		end
	end
	local save={}
	local l={}
	for i=1,#(self.energy) do
		table.insert(save,self.energy[i])
	end
	local cnt=#(save)
	local layer=10
	table.sort(save)
	for i=1,layer do
		l[i]=save[math.floor(cnt*i/layer)]
	end
	save={
		dir=tostring(mList.id),
		file=tostring(mList.id).."/main.dat",
		bpm=self.bpm
	}
	if not love.filesystem.isDirectory(save.dir) then
		love.filesystem.createDirectory(save.dir)
	end

	local pre=-1
	for i=1,#(self.beat) do
		local cur=self.beat[i]
		local cp=self:getPart(cur)
		local clevel=1
		local over=nil
		for j=1,layer do
			if self:getEnergy(cur)>l[j] then clevel=clevel+1 end
		end
--		if (i==#(self.beat) or self.beat[i+1]-self.beat[i]>self.bpm*4) and clevel>3 then
		if clevel>3 and cur>pre then
			for j=cp,#(self.energy) do
				local tlevel=1
				local E=self:getEnergyP(j)
				for k=1,layer do
					if E>l[k] then tlevel=tlevel+1 end
				end
				if tlevel<=3 then
					over=j*self.part/self.rate
					break
				end
			end
			if not over then
				over=#(self.energy)*self.part/self.rate
			end
--			if i<#(self.beat) and over>=self.beat[i+1] then
--				over=self.beat[i+1]-C.eps
--			end
			if over-cur<self.bpm then
				over=nil
			else
				pre=over
			end
		end
		table.insert(save,{
			f=cur,
			t=over,
			energy=clevel/layer
		})
	end

	local warning={}
	local mainData={ver=game.version}
	local valid=0
	for k,v in pairs(pattern) do
		pattern[k].valid=true
		valid=valid+1
	end
	while #(save)>0 and valid>0 do
		for k,v in pairs(pattern) do
			if v.valid and ran:int(1,valid)==1 then
				local removed,data=v.calc(save,warning)
				if removed then
					table.sort(removed)
					for j=#(removed),1,-1 do
						table.remove(save,removed[j])
					end
				else
					v.valid=false
					valid=valid-1
				end
				if data then
					local tmp={
						name=k,
						type="pattern",
						data=data
					}
					table.insert(mainData,tmp)
				end
				if #(save)==0 or valid==0 then break end
			end
		end
		coroutine.yield(#(save)/cnt/2+0.5)
	end
	if not SD.state then
		love.filesystem.write(save.dir.."/play."..self.ext,self.file:read())
	end
	cnt=#(save)
	while #(save)>0 do
		for k,v in pairs(sbeat) do
			local removed,data=v.calc(save,warning)
			if removed then
				table.remove(save,removed)
			end
			if data then
				local tmp={
					name=k,
					type="sbeat",
					data=data
				}
				table.insert(mainData,tmp)
			end
			if #(save)==0 then break end
		end
		coroutine.yield(#(save)/cnt/2)
	end

	table.sort(warning,sortByTime)
	local file=save.dir.."/warning.dat"
	love.filesystem.write(file,getContent("",warning))
	love.filesystem.write(save.file,getContent("",mainData))
end

--LOVE用
function musicAnalyze(dt)
	local beginT=love.timer.getTime()
	if SD.routine then
		while love.timer.getTime()-beginT<C.wait do
			local back, info=coroutine.resume(SD.routine,SD)
			if back==false or (not info) then
				if back==false then
					debug("Error: "..info)
				end
				SD.routine=nil
				fileSave()
				game.pop()
				cursor.pos=mList.cnt
				SD:init()
				love.update(dt)
				return
			else
				SD.process=1-info*0.2
			end
		end
	else
		while love.timer.getTime()-beginT<C.wait do
			local process=SD:analyze()
			if process==-1 then
				SD:finish()
				if #(SD.beat)>10 then
					local id=SD.state
					if not id then
						mList.cnt=mList.cnt+1
						mList.id=mList.id+1
						mList[mList.cnt]={
							id=mList.id,
							file=SD.file:getFilename(),
							highscore={0,0,0,0},
							duration=SD.music:getDuration(),
							bpm=SD.bpm,
							ext=SD.ext,
							cnt={0,0,0,0},
							replay={id=0}
						}
					else
						mList[id].duration=SD.music:getDuration()
						mList[id].highscore={0,0,0,0}
						mList[id].bpm=SD.bpm
						mList[id].cnt={0,0,0,0}
						mList[id].replay={id=0}
					end
					SD.routine=coroutine.create(getNotes)
					return
				else
					love.window.showMessageBox("生成出错","无法生成谱面；这首歌可能不适合弹幕游戏。")
					game.pop()
					return
				end
			end
		end
	end
	collectgarbage()
end

function drawMusic()
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
		love.graphics.draw(game.preCanvas)
		love.graphics.setShader()
		SD.words=getWaitingDialogue()
		checkAchievement("firstLoad")
	end

	local pre=love.graphics.getBlendMode()
	love.graphics.setBlendMode("alpha","premultiplied")
	love.graphics.setCanvas(game.canvas)
	love.graphics.clear()
	love.graphics.draw(game.pCanvas)
	love.graphics.setBlendMode(pre)
	
	local x,y=game.width/2,game.height/2
	local x1,y1,x2,y2
	for i=-90,SD.process*360-90 do
		local r=ran:float(game.height/50,game.height/20)
		local R=game.height*0.4
		x1=x+math.cos(i*C.PI/180)*(R-r)
		y1=y+math.sin(i*C.PI/180)*(R-r)
		x2=x+math.cos(i*C.PI/180)*(R+r)
		y2=y+math.sin(i*C.PI/180)*(R+r)
		love.graphics.setLineWidth(7)
		love.graphics.setColor(0,255,255,128)
		love.graphics.line(x1,y1,x2,y2)
		love.graphics.setLineWidth(3)
		love.graphics.setColor(255,255,255,255)
		love.graphics.line(x1,y1,x2,y2)
	end
	drawText(string.format("%6.2f",SD.process*100).."%",100,game.width/2-200,game.height/2-100)
	drawMidText(SD.words,30,game.height/2+20,"chn")
	love.graphics.setCanvas()
	love.graphics.setBlendMode("alpha", "premultiplied")
	game.shader.glow:send("radius",10)
	game.shader.glow:send("height",game.height)
	game.shader.glow:send("width",game.width)
	love.graphics.setShader(game.shader.glow)
	love.graphics.draw(game.canvas)
	love.graphics.setShader()
	love.graphics.setBlendMode(pre)
end