--录像保存
function recordGame(dt)
	if game.replay then return end
	local rep=game.audio.record
	local state=rep.state
	local back={dt=dt,press="",t=game.audio.pos}
	for k,v in ipairs(keyRec) do
		if keyDown[v]>0 then
			if not state[v] then
				back.press=back.press..k
				state[v]=true
			end
		else
			if state[v] then
				back.press=back.press..k
				state[v]=false
			end
		end
	end
	table.insert(rep,back)
end

--初始化录像
function initRecord()
	local curt=os.date("*t")
	game.audio.record={
		time=string.format("%04d/%02d/%02d %02d:%02d:%02d",curt.year,curt.month,curt.day,curt.hour,curt.min,curt.sec),
		state={},
		version=game.version,
		difficulty=mList.difficulty,
		seed=ran:getSeed()
	}
end

--保存录像
function saveReplay(input)
	if input==nil then return end
	local rec=game.audio.record
	if not mList[game.audio.id].replay then mList[game.audio.id].replay={id=0} end
	local rep=mList[game.audio.id].replay
	rep.id=rep.id+1
	local id=rep.id
	local add={
		time=rec.time,
		version=rec.version,
		difficulty=rec.difficulty,
		seed=rec.seed,
		name=input,
		avefps=getFPS(game.frame,game.audio.duration),
		count=player.count,
		id=id,
		frame=game.frame
	}
	table.insert(rep,add)

	local file=game.audio.previd.."/"..id..".rep"
	local content=""
	for i=1,#(rec) do
		local cur=rec[i]
		content=content..cur.dt.." "..cur.t.." "..cur.press.."\n"
	end

	content=love.math.compress(content,"zlib")
	love.filesystem.write(file,content)
	fileSave()

	--改变option
	for i=1,#(option) do
		local cur=option[i]
		if cur.text=="保存录像" then
			cur.text="已保存录像"
			cur.desc="已经保存了：\n"..getMusicName(game.audio.id).."\n在"..game.audio.record.time.."的游戏记录。"
			cur.click=fnil
		end
	end
end

--更新replay，需要同步时间与对应帧数
function updateReplay(dt)
	local curt,pos
	local rep=game.replay
	local state=rep.state
	state.t=state.t+dt
	rep.frame=rep.frame+1
	if game.audio.music:isPlaying() then
		rep.playframe=rep.playframe+1
	end
	repeat
		pos=game.frame+1
		local cur=rep[pos]
		if not cur then
			cur={dt=dt,press=0,t=game.audio.duration+6}
			for k,v in ipairs(keyRec) do
				if state[v]>0 then
					cur.press=cur.press*10+k
				end
			end
		end
		local tmp=cur.press
		local cnt
		state.first={}
		while tmp>0 do
			cnt=tmp%10
			local tmp2=keyRec[cnt]
			if state[tmp2]>0 then
				state[tmp2]=0
			else
				state[tmp2]=1
				state.first[tmp2]=true
			end
			tmp=(tmp-cnt)/10
		end
		state.curT=state.curT+cur.dt
		state.musicT=cur.t
		if pos<#(rep) then
			state.nextT=state.nextT+rep[pos+1].dt
		end
		if state.t<state.curT-C.eps then
			love.timer.sleep(state.curT-C.eps-state.t)
		end
		
		updateGame(cur.dt)
	until pos>=#(rep) or state.t<state.nextT
end

--回放选项
function replayOption(id,page)
	page=page or 1
	local rep=mList[id].replay
	local cnt=#(rep)
	local pn=8
	local pcnt=math.max(1,math.ceil(cnt/pn))
	page=math.min(page,pcnt)
	local next=page+1
	local prev=page-1
	if next>pcnt then next=1 end
	if prev<1 then prev=pcnt end

	local back={
		{
			y1=150,
			y2=185,
			text="返回上级菜单",
			type="button",
			click=function(self)
				game.pop()
			end
		},
		{
			y1=185,
			y2=220,
			text="页码",
			type="list",
			list={prev.."/"..pcnt,page.."/"..pcnt,next.."/"..pcnt},
			pos=2,
			desc="使用左右方向键进行翻页。",
			change=function(self)
				if self.pos==1 then
					option=replayOption(id,prev)
					option.y1=self.y1
					option.y2=self.y2
					option.pos=2
				elseif self.pos==3 then
					option=replayOption(id,next)
					option.y1=self.y1
					option.y2=self.y2
					option.pos=2
				end
			end
		},
		y1=150,
		y2=185,
		title="录像列表",
		pos=1,
		fontsize=24,
		width=300,
		hotkey={
			escape=function(self)
				if self.pos~=1 then
					self.pos=1
				else
					self[1].click(self[1])
				end
			end,
			delete=function(self)
				if self.pos<=2 then return end
				local tmp=self[self.pos]
				local add={
					desc="确定删除这个录像文件？",
					pos=2,
					x1=game.width/2
				}
				option.confirm=add
			end
		}
	}
	local curpos=230
	if cnt==0 then
		back[2].text="（没有匹配的录像文件）"
		back[2].type="button"
		back[2].list=nil
		back[2].desc=nil
		back[2].change=nil
	end
	for i=(page-1)*pn+1,math.min(cnt,page*pn) do
		local cur=rep[i]
		local dif="["..game.difficulty[rep[i].difficulty].."]"
		local text=string.format("%-9s %010d - %s",dif,cur.count.score,cur.name)
		local len=strlen(text)
		for i=len+1,47 do
			text=text.." "
		end
		local desc=cur.name.."\n在"..cur.time.."的记录"..
		"\n难度/得分："..dif..string.format(" %010d",cur.count.score)..
		"\n被弹/决死/擦弹："..cur.count.death.."/"..cur.count.bomb.."/"..cur.count.graze..
		"\n平均FPS："..string.format("%.4f",cur.avefps).."，由"..cur.version.."创建"..
		"\n回车回放录像，Delete/Backspace删除录像。"
		local tmp={
			y1=curpos,
			y2=curpos+35,
			type="button",
			text=text,
			lang="eng",
			desc=desc,
			click=function(self)
				if option.confirm then
					delReplay(id,i)
					option=replayOption(id,page)
				else
					beginReplay(id,i)
				end
			end
		}
		curpos=curpos+35
		table.insert(back,tmp)
	end
	return back
end

--读取录像并回放
function beginReplay(id,repid)
	local add={
		id=id,
		repid=repid,
		state={t=0,curT=0},
		frame=0,
		playframe=0
	}
	local rep=mList[id].replay[repid]
	local file=mList[id].id.."/"..mList[id].replay[repid].id..".rep"
	if not love.filesystem.isFile(file) then
		return false
	end

	local content=love.filesystem.read(file)
	content=love.math.decompress(content,"zlib")
	content=strSplit(content,"\n")
	for i,v in ipairs(content) do
		local line=strSplit(v," ")
		local tmp={dt=tonumber(line[1]),t=tonumber(line[2])}
		if line[3] then
			tmp.press=tonumber(line[3])
		else
			tmp.press=0
		end
		table.insert(add,tmp)
	end
	add.state.nextT=add[1].dt
	for k,v in ipairs(keyRec) do
		add.state[v]=0
	end
	game.replay=add
	ran:setSeed(rep.seed)

	local pre=mList.difficulty
	mList.difficulty=rep.difficulty
	beginGame(mList[id],id)
	mList.difficulty=pre
	game.graphics.data.nextU=updateReplay
end

--退出replay
function endReplay()
	addGradual(love.update,updateOption,love.draw,drawOption,60,30,true,function(...)
		game.state={}
		SD.first=0
		option=endReplayOption(game.replay.id,game.replay.repid)
		game.replay=true
		ran:setSeed(os.time())
		fileSave()
	end)
	checkAchievement("firstReplay")
end

--回放结束选项
function endReplayOption(id,repid)
	local rep=game.replay
	local data=mList[id].replay[repid]
	local rate=rep.frame/data.frame
	local fps=math.min(60,(rep.playframe+1)/game.audio.duration)
	local diff=game.audio.record.difficulty
	local back={
		{
			y1=400,
			y2=445,
			text="返回菜单",
			type="button",
			desc="返回录像选择界面。",
			click=function(self)
				while game.pop() do end
				addGradual(fnil,updateMenu,love.draw,drawMenu,30,30,true)
			end
		},
		{
			y1=450,
			y2=495,
			text="回放率："..string.format("%.3f%%",rate*100),
			type="button",
			desc=rep.frame.."帧 / "..data.frame.."帧\n"..
				string.format("%.4f FPS / %.4f FPS\n",fps,data.avefps)..
				"回放率说明了该录像在回放中的掉帧程度。\n"..
				"* 回放帧率可能比原录像高，但回放算法将尽可能减小\n  该误差。"
		},
		y1=400,
		y2=445,
		title="录像结束",
		pos=1,
		draw=drawReport,
		update=updateReport,
		bar=0,
		highscore=mList[id].highscore[diff],
		score=player.count.score,
		death=player.count.death,
		hotkey={
			escape=function(self)
				if self.pos~=1 then
					self.pos=1
				else
					self[1].click(self[1])
				end
			end
		}
	}
	return back
end

--暂停菜单
function getReplayOption()
	local back={
		{
			y1=200,
			y2=245,
			text="继续播放",
			type="button",
			desc="从暂停状态返回并继续回放录像。",
			click=function(self)
				game.pop()
				if game.audio.music:isPaused() then
					game.audio.music:setVolume(mList.setting.bgm)
					game.audio.music:resume()
				end
			end
		},
		{
			y1=260,
			y2=305,
			text="游戏设置",
			type="button",
			desc="修改游戏有关设置。",
			click=function(self)
				option=getSetting(true,option)
			end
		},
		{
			y1=320,
			y2=365,
			text="返回菜单",
			type="button",
			desc="停止回放并返回菜单界面。",
			confirm={
				desc="返回菜单界面？。",
				pos=2
			},
			click=function(self)
				addGradual(fnil,updateMenu,love.draw,drawMenu,30,30,true,function(...)
					game.state={}
				end)
			end
		},
		y1=200,
		y2=245,
		title="回放暂停",
		pos=1
	}
	return back
end