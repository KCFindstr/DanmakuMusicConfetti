--读取生成弹幕方式
function initPattern()
	pattern={}
	sbeat={}
	warnpat={}
	local items=love.filesystem.getDirectoryItems("script/SD")
	for i,file in ipairs(items) do
		if love.filesystem.isFile("script/SD/"..file) then
			file=strSplit(file,".")[1]
			if string.sub(file,1,1)=="a" then
				local tmp=require("script.SD."..file)
				tmp.id=i
				pattern[tmp.name]=tmp
			elseif string.sub(file,1,1)=="b" then
				local tmp=require("script.SD."..file)
				tmp.id=i
				sbeat[tmp.name]=tmp
			elseif string.sub(file,1,1)=="c" then
				local tmp=require("script.SD."..file)
				tmp.id=i
				warnpat[tmp.name]=tmp
			end
		end
	end
end

--判断版本
function checkScriptVersion(text)
	local back=transVersion(text)
	if (not back) or back<2 then
		love.window.showMessageBox("读取谱面失败","该谱面由版本"..text.."创建。\n为避免兼容性问题，将返回菜单界面。")
		addGradual(fnil,updateMenu,fnil,drawMenu,0,30,true,function(...)
			game.state={}
			love.filedropped=fileDrop
		end)
		return false
	end
	return true
end