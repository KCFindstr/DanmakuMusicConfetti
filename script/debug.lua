--调试输出
function debug(text)
	if game.debug>0 then
		print(text)
	end
end

--版本识别
function transVersion(text)
	if text=="V0.1 Beta" then
		return 1
	end
	if text=="V0.2 Beta" then
		return 2
	end
	if text=="V0.3 Beta" then
		return 3
	end
	return nil
end

--开发模式
function checkDevMode(input)
	if input~="DESTROYER" and input~="DD" then return end
	option=getSavedataOption(mList)
end

--获取文件列表
function getSavedataOption(cur,page,pre,prefix)
	page=page or 1
	pre=pre or game.document
	prefix=prefix or "savedata"
	local pn=10
	local begin=begin
	local back={
		{
			y1=150,
			y2=185,
			text="返回上级目录",
			type="button",
			desc="当前位置：\n"..prefix,
			click=function(self)
				option=pre
			end
		},
		y1=150,
		y2=185,
		title="浏览savadata",
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
			end
		}
	}
	local cnt=0
	local index=2
	local cury=230
	for k,v in pairs(cur) do
		if v then
			cnt=cnt+1
			local typ=type(v)
			local text=tostring(k)
			local desc=prefix.."/"..text.."\n"..
					"type : "..typ.."\n"
			local click
			local add=""
			if typ=="table" then
				click=function(self)
					option=getSavedataOption(v,1,back,prefix.."/"..text)
				end
				add=" >"
			else
				desc=desc.."value:\n"..tostring(v)
			end
			if cnt>(page-1)*pn and cnt<=page*pn then
				index=index+1
				back[index]={
					y1=cury,
					y2=cury+35,
					text=text..add,
					desc=desc,
					type="button",
					click=click,
					lang="eng"
				}
				cury=cury+35
			end
		end
	end
	if cnt==0 then
		cnt=1
		back[3]={
			y1=cury,
			y2=cury+35,
			text="(No Children)",
			desc="该table没有包含任何键值。",
			type="button",
			lang="eng"
		}
	end
	local pcnt=math.ceil(cnt/pn)
	local prev=page-1
	local next=page+1
	if prev<1 then prev=pcnt end
	if next>pcnt then next=1 end
	back[2]={
		y1=185,
		y2=220,
		text="页码",
		type="list",
		pos=2,
		list={prev.."/"..pcnt,page.."/"..pcnt,next.."/"..pcnt},
		desc="使用左右方向键进行翻页。",
		change=function(self)
			if self.pos==1 then
				option=getSavedataOption(cur,prev,pre,prefix)
				option.y1=self.y1
				option.y2=self.y2
				option.pos=2
			elseif self.pos==3 then
				option=getSavedataOption(cur,next,pre,prefix)
				option.y1=self.y1
				option.y2=self.y2
				option.pos=2
			end
		end
	}
	return back
end