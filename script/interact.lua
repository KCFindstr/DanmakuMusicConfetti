function love.keypressed(key)
	local nowkey=keyMap[key]
	if nowkey==nil then
		return
	end
	keyDown[nowkey]=keyDown[nowkey]+1
	return
end

function love.keyreleased(key)
	local nowkey=keyMap[key]
	if nowkey==nil then
		return
	end
	keyDown[nowkey]=keyDown[nowkey]-1
	return
end

function updateKey(dt)
	for k,v in pairs(keyDown) do
		if v and v>0 then
			keyTime[k]=keyTime[k]+dt
			if keyTime[k]>keyTime.first then
				keyRepeat[k]=keyRepeat[k]+dt
				if keyRepeat[k]>keyTime.rep then
					keyRepeat[k]=0
				end
			end
		else
			keyTime[k]=0
			keyRepeat[k]=0
		end
	end
end

function firstPress(key)
	return keyDown[key]>0 and keyTime[key]==0
end

function repeatPress(key)
	return keyTime[key]>0.3 and keyRepeat[key]==0
end

--重设按键
function keyReset(key,time)
	if not keyRepeat[key] then return false end
	if keyRepeat[key]>=time then
		keyRepeat[key]=0
	end
	return true
end

--丢入文件
function fileDrop(file)
	local name=file:getFilename()
	for i=1,mList.cnt do
		if mList[i].file==name then
			love.window.showMessageBox("无法添加",name.."\n已存在于列表中。请先移除，才能再次添加并生成谱面。")
			return
		end
	end
	SD.state=nil
	musicLoad(file)
end

--载入音乐文件
function musicLoad(file)
	local name=file:getFilename()
	love.window.setTitle("Loading music file: "..name)
	if not SD:loadData(file) then
		love.window.setTitle(game.title)
		return
	end
	game.push(musicAnalyze,drawMusic)
	love.window.setTitle(game.title)
end

--重新加载音乐文件
function fileReload(num)
	local cur=mList[num]
	local name=cur.id.."/play."..cur.ext
	SD.state=num
	musicLoad(love.filesystem.newFileData(name))
end

--失去焦点
function love.focus(f)
	game.isFocus=f
end

--确认UI
function applyConfirm()
	if not option then return false end
	local target=option[option.pos]
	local width=option.width or 230
	option.confirm=copyFrom(target.confirm)
	if not option.confirm.x1 then
		if option.confirm.pos==1 then
			option.confirm.x1=game.width/2-width
		else
			option.confirm.x1=game.width/2
		end
	end
	return true
end