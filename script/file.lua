--文件分析
function readData(string)
	local data=strSplit(string,"\n")
	local back={}
	local previous={}
	for i=1,#(data) do
		local content=strSplit(data[i],"?")
		local pos=strSplit(content[1],".")
		local cur=back
		if content[2]=="number" then
			content[3]=tonumber(content[3])
		end
		if content[2]=="boolean" then
			content[3]=content[3]=="true"
		end
		debug(content[1].."("..content[2]..")"..tostring(content[3]))
		for i=1,#(pos) do
			if pos[i]=="*" then
				pos[i]=previous[i]
			else
				previous[i]=pos[i]
			end
			if tonumber(pos[i]) then
				pos[i]=tonumber(pos[i])
			end
			if i==#(pos) then
				cur[pos[i]]=content[3]
			else
				if cur[pos[i]]==nil then
					cur[pos[i]]={}
				end
				cur=cur[pos[i]]
			end
		end
	end
	return back
end

--初始化mList
function initMemory()
	mList={
		id=0,
		cnt=0,
		ver=game.version,
		setting={
			bgm=1,
			se=1,
			cycle=true,
			autopause=false
		},
		achievement={cnt=0},
		counter={},
		difficulty=1
	}
end

--读取
function fileLoad()
	initMemory()
	if not love.filesystem.isFile("savedata") then
		fileSave()
	end
	local save=love.filesystem.read("savedata")
	save=love.math.decompress(save,"zlib")
	local back=readData(save)
	local sVer=transVersion(back.ver)
	if not sVer then
		love.window.showMessageBox("读取存档失败","你可能使用过版本号为"..back.ver.."的本软件。\n为避免出现兼容问题，本软件将退出。")
		love.event.quit()
	end
	if sVer<2 then
		local cur=love.window.showMessageBox("读取存档","你使用过过早版本的本软件。\n该版本存档在目前版本下已经无法使用。\n退出本软件，或初始化所有存档？你之前的记录将丢失。",{"不更改并退出","初始化存档",escapebutton=1})
		if cur==1 then
			love.event.quit()
		end
		if cur==2 then
			for i=1,back.id do
				fileRemove(tostring(i))
			end
			fileSave()
		end
	else
		addCopy(mList,back)
	end
end

--初始化
function initLoad()
	--Sound Effect
	local items=love.filesystem.getDirectoryItems("asset/se")
	for k,v in ipairs(items) do
		local content=strSplit(v,"/\\.")
		if content[#(content)]=="wav" then
			game.sound[content[#(content)-1]]=love.audio.newSource("asset/se/"..v,"static")
		end
	end

	--Visual Effect
	items=love.filesystem.getDirectoryItems("asset/effect")
	for k,v in ipairs(items) do
		local content=strSplit(v,"/\\.")
		if content[#(content)]=="fs" then
			game.shader[content[#(content)-1]]=love.graphics.newShader("asset/effect/"..v)
		end
	end

	--Bullet Class
	class={}
	items=love.filesystem.getDirectoryItems("script/class")
	for k,v in ipairs(items) do
		local content=strSplit(v,"/\\.")
		local name=content[#(content)-1]
		if content[#(content)]=="lua" then
			class[name]=require("script.class."..name)
			for _,color in ipairs(game.graphics.colorset) do
				local path="data/bullet/"..name.."_"..color..".png"
				if love.filesystem.isFile(path) then
					class[name][color]=love.graphics.newImage(path)
				end
				path="data/item/"..name.."_"..color..".png"
				if love.filesystem.isFile(path) then
					class[name][color]=love.graphics.newImage(path)
				end
			end
		end
	end
end

--递归
function getContent(prefix,obj,short)
	short=short or ""
	local content=""
	local first=true
	for k,v in pairs(obj) do
		if v~=nil then
			if first then
				first=false
			else
				prefix=short
			end
			if type(v)=="table" then
				content=content..getContent(prefix.."."..k,v,short..".*")
			else
				content=content..prefix.."."..k.."?"..type(v).."?"..tostring(v).."\n"
			end
		end
	end
	return content
end

--写入
function fileSave()
	local content=love.math.compress(getContent("",mList),"zlib")
	love.filesystem.write("savedata",content)
end

--删除
function fileRemove(dir)
	if not love.filesystem.exists(dir) then
		return
	end
	local file=love.filesystem.getDirectoryItems(dir)
	for i=1,#(file) do
		local v=file[i]
		if love.filesystem.isDirectory(dir.."/"..v) then
			fileRemove(dir.."/"..v)
		elseif love.filesystem.isFile(dir.."/"..v) then
			love.filesystem.remove(dir.."/"..v)
		end
	end
	love.filesystem.remove(dir)
end

--删除音乐
function delSong(pos)
	local cur=mList[pos]
	table.remove(mList,pos)
	mList.cnt=mList.cnt-1
	local file=tostring(cur.id)
	if love.filesystem.isDirectory(file) then
		fileRemove(file)
	end
	fileSave()
end

--读取
function beginGame(gData,pos)
	local id=gData.id
	local file=gData.file
	local checkList={"main.dat","warning.dat","play."..gData.ext}
	for i=1,#(checkList) do
		if not love.filesystem.isFile(id.."/"..checkList[i]) then
			return false
		end
	end
	enemy={}
	bullet={}
	object={}
	unit={}
	local warning={}

	for v in love.filesystem.lines(id.."/warning.dat") do
		local tmp=strSplit(v,",")
		if #(tmp)~=7 then return false end
		local t,x,y,r,g,b,type=tmp[1],tmp[2],tmp[3],tmp[4],tmp[5],tmp[6],tmp[7]
		if not warnpat[type] then
			love.window.showMessageBox("读取谱面失败","读取到了未知的信号类型：\n"..type)
			addGradual(fnil,updateMenu,fnil,drawMenu,0,30,true,function(...)
				game.state={}
				love.filedropped=fileDrop
			end)
			return false
		end
		table.insert(warning,{
			t=tonumber(t),
			x=tonumber(x),
			y=tonumber(y),
			color={tonumber(r),tonumber(g),tonumber(b),0},
			type=type
		})
	end
	local danmaku=readData(love.filesystem.read(id.."/main.dat"))
	if not checkScriptVersion(danmaku.ver) then
		return false
	end
	
	TM:init()
	player:initGame()
	player:new()
	game.active={}
	game.graphics.color[4]=0
	game.frame=0
	if game.audio.music then
		game.audio.music:stop()
	end
	game.audio=copyFrom(gData)
	game.audio.id=pos
	game.audio.music=love.audio.newSource(id.."/play."..gData.ext)
	game.audio.signal=warning
	game.audio.pos=0
	game.audio.previd=id
	for i=1,#(danmaku) do
		if danmaku[i].type=="pattern" then
			if not pattern[danmaku[i].name] then
				love.window.showMessageBox("读取谱面失败","读取到了未知的弹幕类型：\n"..danmaku[i].name)
				addGradual(fnil,updateMenu,fnil,drawMenu,0,30,true,function(...)
					game.state={}
					love.filedropped=fileDrop
				end)
				return false
			end
			TM:newTask(pattern[danmaku[i].name].run,danmaku[i].data,"level")
		else
			if not sbeat[danmaku[i].name] then
				love.window.showMessageBox("读取谱面失败","读取到了未知的弹幕类型：\n"..danmaku[i].name)
				addGradual(fnil,updateMenu,fnil,drawMenu,0,30,true,function(...)
					game.state={}
					love.filedropped=fileDrop
				end)
				return false
			end
			TM:newTask(sbeat[danmaku[i].name].run,danmaku[i].data,"level")
		end
	end

	TM:newTask(TM.func.bullet)
	TM:newTask(TM.func.player)
	TM:newTask(TM.func.enemy)
	TM:newTask(TM.func.bonus)
	TM:newTask(TM.func.level)
	TM:newTask(TM.func.system)

	TM:update("level")
	addGradual(fnil,updateGame,love.draw,prepareGame,30,0,false,function(...)
		while game.pop() do end
	end)
	love.filedropped=nil
	return true
end