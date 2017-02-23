achievement={
	firstOpen={
		index=1,
		title="初体验",
		text="第一次打开游戏！",
		hidden=false
	},
	changeBGMVolumn={
		index=2,
		title="标量操作Ⅰ",
		text="第一次修改BGM音量！",
		hidden=false
	},
	changeSEVolumn={
		index=3,
		title="标量操作Ⅱ",
		text="第一次修改游戏音效音量！",
		hidden=false
	},
	changeCursorCycle={
		index=4,
		title="光标操纵者",
		text="第一次修改光标轮回！",
		hidden=false
	},
	changeFocusPause={
		index=5,
		title="时空裂缝",
		text="第一次修改失焦暂停！",
		hidden=false
	},
	firstLoad={
		index=6,
		title="少女祈祷中",
		text="第一次载入音乐文件！",
		hidden=false
	},
	firstGame1={
		index=7,
		title="FIRST LIVE",
		text="完成第一次EASY难度游戏！",
		hidden=false
	},
	firstGame2={
		index=8,
		title="FIRST LIVE Ⅱ",
		text="完成第一次NORMAL难度游戏！",
		hidden=false
	},
	firstGame3={
		index=9,
		title="FIRST LIVE SUNSHINE",
		text="完成第一次HARD难度游戏！",
		hidden=false
	},
	firstGame4={
		index=10,
		title="FIRST LIVE SUNSHINE Ⅱ",
		text="完成第一次LUNATIC难度游戏！",
		hidden=false
	},
	firstDeath={
		index=11,
		title="死亡轮回",
		text="第一次被弹。",
		hidden=false
	},
	firstPerfect={
		index=12,
		title="GET SPELLCARD BONUS",
		text="第一次无伤完成游戏。",
		hidden=false
	},
	firstReplay={
		index=13,
		title="Blu-ray Disk",
		text="第一次完整回放录像。",
		hidden=false
	},
	discoverDevMode={
		index=14,
		title="Hello World",
		text="发现开发者入口\n——等等，你是怎么找到的？",
		hidden=true
	}
}
achievementCount={}

--初始化成就
function initAchievement()
	for k,v in pairs(achievement) do
		if v then achievementCount[v.index]=k end
	end
end

--激活成就
function checkAchievement(name)
	if achievement[name]==nil or mList.achievement[name] then
		return false
	end
	mList.achievement[name]=true
	mList.achievement.cnt=mList.achievement.cnt+1
	local checkCount=#(strSplit(achievement[name].text,"\n"))
	local height=100+checkCount*24
	addMessage("成就 Achievement",achievement[name].title.."：\n"..achievement[name].text,{255,100,0},nil,nil,nil,nil,height)
	return true
end

--成就列表
function achievementList(page)
	local cnt=#(achievementCount)
	local pn=5
	local pcnt=math.ceil(cnt/pn)
	if page>pcnt or page<1 then
		return nil
	end
	local prev=page-1
	local next=page+1
	if next>pcnt then next=1 end
	if prev<1 then prev=pcnt end
	
	local back={
		{
			y1=180,
			y2=225,
			text="返回上级菜单",
			type="button",
			click=function(self)
				option=game.document
			end
		},
		{
			y1=230,
			y2=275,
			text="页码",
			type="list",
			list={prev.."/"..pcnt,page.."/"..pcnt,next.."/"..pcnt},
			pos=2,
			desc="使用左右方向键进行翻页。",
			change=function(self)
				if self.pos==1 then
					option=achievementList(prev)
					option.y1=self.y1
					option.y2=self.y2
					option.pos=2
				elseif self.pos==3 then
					option=achievementList(next)
					option.y1=self.y1
					option.y2=self.y2
					option.pos=2
				end
			end
		},
		y1=180,
		y2=225,
		title="成就",
		pos=1,
		width=300,
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
	local from,to=1+(page-1)*pn,math.min(cnt,page*pn)
	local cury=300
	for i=from,to do
		local cur=achievementCount[i]
		local info
		if achievement[cur].hidden and not mList.achievement[cur] then
			info={
				title="？？？",
				text="这是一个隐藏成就。\n不知道去哪里探索才能达成它呢……"
			}
		else
			info=achievement[cur]
		end
		local state="　　　　　未达成"
		if mList.achievement[cur] then
			state="　　　　　已达成"
		end
		local tmp={
			y1=cury,
			y2=cury+45,
			text=info.title,
			desc=info.text,
			type="list",
			list={state},
			pos=1
		}
		table.insert(back,tmp)
		cury=cury+50
	end
	return back
end

--计数
function addSongCounter(id)
	local tmp=mList.difficulty
	mList[id].cnt[tmp]=mList[id].cnt[tmp]+1
end

function addNormalCounter(name)
	if not mList.counter[name] then
		return
	end
	mList.counter[name]=mList.counter[name]+1
	return mList.counter[name]
end

--开始确认
function musicOption(id)
	local cur=mList[id]
	local info="名称："..getMusicName(id).."\n最高得分："..cur.highscore[1]
	for i=2,#(cur.highscore) do
		info=info.."/"..cur.highscore[i]
	end
	info=info.."\n共完成了"..cur.cnt[1]
	for i=2,#(cur.cnt) do
		info=info.."/"..cur.cnt[i]
	end
	info=info.."次"..[[

时长：]]..string.format("%2d:%02d",math.floor(cur.duration/60),math.floor(cur.duration)%60)..[[

估计BPM：]]..string.format("%.2f",60/cur.bpm).."\n分配ID："..cur.id
	local back={
		{
			y1=200,
			y2=245,
			text="返回",
			type="button",
			desc="返回到音乐选择界面。",
			click=function(self)
				game.pop()
			end
		},
		{
			y1=250,
			y2=295,
			text="开始游戏",
			type="list",
			list=game.difficulty,
			pos=mList.difficulty,
			lang="eng",
			desc="用左右选择难度，ENTER开始。",
			click=function(self)
				local dest=mList[id]
				if not love.filesystem.isDirectory(tostring(dest.id)) then
					love.window.showMessageBox("读取失败","没有找到创建的谱面。你可以移除该音乐然后重新创建。\n文件：\n"..dest.file)
				elseif not beginGame(dest,id) then
					love.window.showMessageBox("读取失败","读取谱面时发生了错误。你可以移除该音乐然后重新创建。\n文件：\n"..dest.file)
				end
			end,
			change=function(self)
				mList.difficulty=self.pos
			end
		},
		{
			y1=300,
			y2=345,
			text="音乐信息",
			type="button",
			desc=info
		},
		{
			y1=350,
			y2=395,
			text="重新载入",
			type="button",
			desc="删除记录并重新生成谱面。\n生成的谱面将与之前不同。",
			confirm={
				desc="重新生成谱面？你之前的游戏记录将丢失。",
				pos=2
			},
			click=function(self)
				fileReload(id)
			end
		},
		{
			y1=400,
			y2=445,
			text="删除",
			type="button",
			confirm={
				desc="删除这首音乐及其谱面？这将不可恢复。",
				pos=2
			},
			click=function(self)
				delSong(id)
				whole=mList.cnt*100
				if mList.cnt==4 then
					cursor.showpos=0
				end
				game.pop()
			end
		},
		y1=200,
		y2=245,
		title="抉择",
		pos=1,
		hotkey={
			escape=function(self)
				self[1].click(self[1])
			end
		}
	}
	game.push(updateOption,drawOption)
	option=back
	return
end

--获取等待语句
function getWaitingDialogue()
	local tmp={
		"第六驱逐队远征中",
		"演唱会准备中",
		"少女祈祷中",
		"重装小兔瞌睡中",
		"正在驱散调皮的小精灵",
		"正在召唤从者",
		"正在与QB签订契约",
		"学级裁判准备中"
	}
	return tmp[ran:int(1,#(tmp))]
end

--获取游戏设置
function getSetting(playing,previous)
	local isCycle,isAutoPause
	local dList=game.difficulty
	local dPos=mList.difficulty
	if game.audio.record and game.audio.record.difficulty then
		dPos=game.audio.record.difficulty
	end
	if mList.setting.cycle then
		isCycle=1
	else
		isCycle=2
	end
	if mList.setting.autopause then
		isAutoPause=1
	else
		isAutoPause=2
	end
	if playing then
		dList={dList[dPos]}
		dPos=1
	end
	local back={
		{
			y1=200,
			y2=245,
			text="返回上级菜单",
			type="button",
			click=function(self)
				option=option.previous
			end
		},
		{
			y1=250,
			y2=320,
			text="背景音乐",
			type="slider",
			desc="修改背景音乐音量。100为原音量。",
			value=mList.setting.bgm,
			vtext=math.ceil(mList.setting.bgm*100),
			move=function(self,val)
				self.value=self.value+val/100
				self.value=math.max(0,self.value)
				self.value=math.min(1,self.value)
				self.vtext=math.ceil(self.value*100)
				if mList.setting.bgm~=self.value then
					checkAchievement("changeBGMVolumn")
				end
				mList.setting.bgm=self.value
			end
		},
		{
			y1=330,
			y2=400,
			tCount=0,
			text="游戏音效",
			type="slider",
			desc="修改游戏音效音量。100为原音量。",
			value=mList.setting.se,
			hover=function(self,dt)
				if self.tCount<=0 then
					playSound(game.sound.death)
					self.tCount=2
				end
				self.tCount=self.tCount-dt
			end,
			vtext=math.ceil(mList.setting.se*100),
			move=function(self,val)
				self.value=self.value+val/100
				self.value=math.max(0,self.value)
				self.value=math.min(1,self.value)
				self.vtext=math.ceil(self.value*100)
				if mList.setting.se~=self.value then
					checkAchievement("changeSEVolumn")
				end
				mList.setting.se=self.value
			end
		},
		{
			y1=410,
			y2=455,
			text="光标轮回",
			type="list",
			desc="控制非游戏界面移动光标时能否穿透屏幕。",
			list={"开","关"},
			pos=isCycle,
			change=function(self)
				if self.pos==1 then
					mList.setting.cycle=true
				else
					mList.setting.cycle=false
				end
				checkAchievement("changeCursorCycle")
			end
		},
		{
			y1=460,
			y2=505,
			text="失焦暂停",
			type="list",
			desc="窗口失去焦点时自动暂停游戏。",
			list={"开","关"},
			pos=isAutoPause,
			change=function(self)
				if self.pos==1 then
					mList.setting.autopause=true
				else
					mList.setting.autopause=false
				end
				checkAchievement("changeFocusPause")
			end
		},
		{
			y1=510,
			y2=555,
			text="游戏难度",
			type="list",
			list=dList,
			pos=dPos,
			lang="eng",
			desc="用左右选择难度。",
			change=function(self)
				if #(self.list)>1 then
					mList.difficulty=self.pos
				end
			end
		},
		y1=200,
		y2=245,
		title="游戏设置",
		pos=1,
		hotkey={
			escape=function(self)
				if self.pos~=1 then
					self.pos=1
				else
					option=option.previous
				end
			end
		},
		previous=previous
	}
	return back
end

--音乐结束选项
function endGameOption(id)
	local next=id+1
	if next>mList.cnt then
		next=1
	end
	local diff=game.audio.record.difficulty
	local back={
		{
			y1=350,
			y2=395,
			text="返回菜单",
			type="button",
			desc="返回音乐选择界面。",
			click=function(self)
				while game.pop() do end
				addGradual(fnil,updateMenu,love.draw,drawMenu,30,30,true,function(...)
					love.filedropped=fileDrop
				end)
			end
		},
		{
			y1=400,
			y2=445,
			text="游戏难度",
			type="list",
			list=game.difficulty,
			pos=mList.difficulty,
			lang="eng",
			desc="用左右选择难度。",
			change=function(self)
				mList.difficulty=self.pos
			end
		},
		{
			y1=450,
			y2=495,
			text="重新开始",
			type="button",
			desc="重新开始：\n"..getMusicName(id),
			click=function(self)
				beginGame(mList[id],id)
			end
		},
		{
			y1=500,
			y2=545,
			text="下一首",
			type="button",
			desc="下一首：\n"..getMusicName(next),
			click=function(self)
				beginGame(mList[next],next)
			end
		},
		{
			y1=550,
			y2=595,
			text="保存录像",
			type="button",
			desc="保存这次游戏的录像。",
			click=function(self)
				local keys=game.keyboard
				keys.onEnd=saveReplay
				keys.title="保存录像"
				keys.text="为要保存的录像命名：\n"..getMusicName(id).."\n在"..game.audio.record.time.."的游戏记录。"
				game.push(updateInputText,drawInputText)
			end
		},
		y1=350,
		y2=395,
		title="演唱会成功",
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
	if player.count.death==0 then
		back.title="完全胜利！S"
		player.count.score=math.floor(player.count.score*1.2)
	end
	
	if player.count.score>mList[id].highscore[diff] then
		mList[id].highscore[diff]=player.count.score
	end
	return back
end

--暂停菜单
function getPauseOption()
	local back={
		{
			y1=200,
			y2=245,
			text="返回游戏",
			type="button",
			desc="从暂停状态返回游戏。",
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
			text="重新开始",
			type="button",
			desc="重新开始这首音乐。（不会改变谱面）",
			confirm={
				desc="重新开始这首音乐？你之前的游戏进度将丢失。",
				pos=2
			},
			click=function(self)
				local tmp=game.audio.id
				beginGame(mList[game.audio.id],game.audio.previd)
			end
		},
		{
			y1=320,
			y2=365,
			text="游戏设置",
			type="button",
			desc="修改游戏有关设置。",
			click=function(self)
				option=getSetting(true,option)
			end
		},
		{
			y1=380,
			y2=425,
			text="返回菜单",
			type="button",
			desc="停止游戏并返回菜单界面。",
			confirm={
				desc="返回菜单界面？你之前的游戏进度将丢失。",
				pos=2
			},
			click=function(self)
				addGradual(fnil,updateMenu,love.draw,drawMenu,30,30,true,function(...)
					game.state={}
					love.filedropped=fileDrop
				end)
			end
		},
		y1=200,
		y2=245,
		title="游戏暂停",
		pos=1
	}
	return back
end
