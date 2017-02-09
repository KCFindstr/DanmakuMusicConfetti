--无用函数
function fnil(...)
	return
end

--计算距离
function dist(obj1,obj2)
	return math.sqrt((obj1.x-obj2.x)^2+(obj1.y-obj2.y)^2)
end

--计算角度（对于obj1）
function degree(obj1,obj2)
	return math.deg(math.atan2(obj2.y-obj1.y,obj2.x-obj1.x))
end

--极坐标相加
function addPolar(p1,p2,opt)
	local x1=p1.len*math.cos(math.rad(p1.r))
	local y1=p1.len*math.sin(math.rad(p1.r))
	local x2=p2.len*math.cos(math.rad(p2.r))
	local y2=p2.len*math.sin(math.rad(p2.r))
	local x,y=nil,nil
	if opt then
		x=x1-x2
		y=y1-y2
	else
		x=x1+x2
		y=y1+y2
	end
	local back={
		len=math.sqrt(x*x+y*y),
		r=math.deg(math.atan2(y,x))
	}
	return back
end

--旋转角度
function vecRotate(obj,rad)
	local x,y=obj.x,obj.y
	rad=math.rad(rad)
	return x*math.cos(rad)-y*math.sin(rad),
		x*math.sin(rad)+y*math.cos(rad)
end

--删除数组
function table.delete(tab,obj)
	for i=#(tab),1,-1 do
		if tab[i]==obj then
			table.remove(tab,i)
		end
	end
end

--查找
function strFind(text,c,pos)
	for i=pos,#(text) do
		for j=1,#(c) do
			if string.sub(text,i,i)==string.sub(c,j,j) then
				return i
			end
		end
	end
	return #(text)+1
end

--分割
function strSplit(text,c)
	if text==nil then
		return nil
	end
	local tmp={}
	local i=0
	local nexti=1
	while nexti<=#(text) do
		nexti=strFind(text,c,i+1)
		local tmp2=string.sub(text,i+1,nexti-1)
		if #(tmp2) and #(tmp2)>0 then
			table.insert(tmp,tmp2)
		end
		i=nexti
	end
	return tmp
end

--字符串长度
function strlen(str)
	local len=#(str)
	local i=1
	local back=0
	while (i<=len)
	do
		local curByte=string.byte(str, i)
		local byteCount=1
		if curByte>0 and curByte<=127 then
			byteCount=1
		elseif curByte>=192 and curByte<223 then
			byteCount=2
		elseif curByte>=224 and curByte<239 then
			byteCount=3
		elseif curByte>=240 and curByte<=247 then
			byteCount=4
		end
		i=i+byteCount
		if (byteCount==1) then
			back=back+1
		else
			back=back+2
		end
	end
	return back
end

--字符串切割
function strcut(str,cnt)
	local len=#(str)
	local i=1
	local back=0
	local res=""
	while i<=len do
		local curByte=string.byte(str, i)
		local byteCount=1
		if curByte>0 and curByte<=127 then
			byteCount=1
		elseif curByte>=192 and curByte<223 then
			byteCount=2
		elseif curByte>=224 and curByte<239 then
			byteCount=3
		elseif curByte>=240 and curByte<=247 then
			byteCount=4
		end
		res=res..string.sub(str,i,i+byteCount-1)
		i=i+byteCount
		if (byteCount==1) then
			back=back+1
		else
			back=back+2
		end
		if back>cnt then
			return res.."..."
		end
	end
	return res
end

--固定范围
function toRange(val,R)
	if R==0 then return 0 end
	return val%R
end

--是否在范围内
function inRange(val,L,R,whole)
	val=toRange(val-L,whole)
	R=R-L
	return val<=R
end

--Canvas绘制
function renderTo(c1,c2)
	local pre=love.graphics.getBlendMode()
	love.graphics.setBlendMode("alpha","premultiplied")
	if c2 then
		love.graphics.setCanvas(c2)
	else
		love.graphics.setCanvas()
	end
	love.graphics.draw(c1)
	love.graphics.setBlendMode(pre)
end

--复制table
function copyFrom(table)
	if type(table)~="table" then
		return table
	end
	local back={}
	for k,v in pairs(table) do
		if type(v)=="table" then
			back[k]=copyFrom(v)
		else
			back[k]=v
		end
	end
	return back
end

--添加table
function addCopy(t1,t2)
	for k,v in pairs(t2) do
		if not t1[k] then
			t1[k]=copyFrom(v)
		else
			if type(v)==table then
				addCopy(t1[k],v)
			else
				t1[k]=v
			end
		end
	end
end

--播放声音
function playSound(source,atplayer)
	if atplayer then
		if source:getChannels()>1 then
			debug("PlaySound: Number of channels is invalid.")
		else
			local x=(player.x/game.graphics.width-0.5)*2
			local y=(player.y/game.graphics.height-0.5)*2
			source:setPosition(x,y,0)
		end
	elseif source:getChannels()==1 then
		source:setPosition(0,0,0)
	end
	source:setVolume(mList.setting.se)
	source:clone():play()
end

--随机数
ran={
	A=1103515245,
	B=12345,
	max=2^32,
	seed=1
}

function ran:setSeed(seed)
	self.seed=seed%ran.max
end

function ran:int(l,r)
	return math.floor(l+self:_01()*(r-l+1))
end

function ran:float(l,r)
	return l+self:_01()*(r-l)
end

function ran:_01()
	self.seed=(self.seed*self.A+self.B)%self.max
	return self.seed/self.max
end

function ran:shuffle(table)
	local N=#(table)
	for i=N,1,-1 do
		local j=ran:int(1,i)
		table[i],table[j]=table[j],table[i]
	end
end

--获取音乐位置
function getMusicPosition()
	local curt
	if game.audio.music:isStopped() and game.audio.music:tell()==0 then
		if game.audio.pos==0 then
			curt=game.frame/60-5
		else
			curt=game.audio.duration+(game.frame-game.audio.pos)/60
		end
	else
		curt=game.audio.music:tell()
		game.audio.pos=game.frame
	end
	return curt
end

--获取音乐名字
function getMusicName(id,limit)
	if id<1 or id>mList.cnt then
		return
	end
	limit=limit or 50
	local tmp
	local cur=mList[id]
	tmp=strSplit(cur.file,"/\\")
	tmp=id..". "..strcut(tmp[#(tmp)],limit)
	return tmp
end

--渐变效果
function addGradual(preU,nextU,preD,nextD,preT,nextT,nextIgnore,onEnd)
	local tmp={}
	game.graphics.data=tmp
	tmp.preU=preU
	tmp.nextU=nextU
	tmp.preD=preD
	tmp.nextD=nextD
	tmp.preT=preT
	tmp.nextT=nextT
	tmp.nextIgnore=nextIgnore
	tmp.onEnd=onEnd
	if preT==0 then
		if not nextIgnore then
			love.update=preU
		end
		if onEnd then
			onEnd(tmp)
		end
	end
	love.draw=drawGradual
end

--新建消息
function addMessage(title,content,color,p1,p2,p3,width,height)
	color=color or {0,255,255,200}
	width=width or 320
	height=height or 100
	p1=p1 or 1
	p2=p2 or 5
	p3=p3 or 1
	local tmp={
		title=title,
		text=content,
		color=color,
		p1=p1,
		p2=p2,
		p3=p3,
		width=width,
		height=height,
		t=-1
	}
	table.insert(message,tmp)
end