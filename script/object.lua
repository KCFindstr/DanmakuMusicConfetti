--没有特殊说明时，传入参数的默认单位为像素和【角度制】

--设置速度，参数为 目标 速度大小 角度 速度目标（若填player则是自机狙，可以留空）
function setV(self,len,rad,aim)
	if aim then
		rad=rad+degree(self,aim)
	end
	self.v.x=len*math.cos(math.rad(rad))
	self.v.y=len*math.sin(math.rad(rad))
	self.r=rad
end

--设置加速度，同上
function setA(self,len,rad,aim)
	if aim then
		rad=rad+degree(self,aim)
	end
	self.a.x=len*math.cos(math.rad(rad))
	self.a.y=len*math.sin(math.rad(rad))
end

--摧毁目标
function destroy(cur)
	GP:remove(cur)
	cur.active=false
	table.delete(bullet,cur)
	if cur.onDestroy then
		TM:newTask(cur.onDestroy,cur,cur.type)
		cur.onDestroy=nil
	end
end

--创建子弹，参数为 类型 颜色 x坐标 y坐标 速度 角度 加速度 加速度角度
--除type和color外都可以留空，该函数将返回创建的子弹
function createBullet(type,color,x,y,v,rad,a,arad,drop,...)
	if not class[type] then
		return nil
	end
	x=x or 0
	color=color or "red"
	y=y or 0
	v=v or 0
	rad=rad or 0
	a=a or 0
	arad=arad or 0
	local tmp=class[type].create(...)
	local tmpx,tmpy=tmp:center()
	tmp.x=x
	tmp.y=y
	tmp.r=rad
	tmp.t=0
	tmp.rate={x=1,y=1}
	tmp.color={255,255,255,0}
	tmp.v={x=v*math.cos(math.rad(rad)),y=v*math.sin(math.rad(rad))}
	tmp.a={x=a*math.cos(math.rad(arad)),y=a*math.sin(math.rad(arad))}
	tmp.active=false
	tmp.img=class[type][color]
	tmp.width=class[type][color]:getWidth()
	tmp.height=class[type][color]:getHeight()
	tmp.onCreate=tmp.onCreate or normalCreate
	tmp.onDestroy=tmp.onDestroy or normalDestroy
	tmp.d={x=tmpx,y=tmpy}
	tmp.type=tmp.type or "bullet"
	tmp.drop=tmp.drop or 100
	table.insert(bullet,tmp)
	if tmp.onCreate then
		TM:newTask(tmp.onCreate,tmp,tmp.type)
	end
	return tmp
end

--创建奖励
--power或score 数量 x坐标 y坐标 初始速度min 初始速度max 扩散范围 是否只用一个表示
function createBonus(type,number,x,y,vmin,vmax,spread,compress)
	if type~="power" and type~="score" then
		return nil
	end
	vmin=vmin or 8
	vmax=vmax or 10
	spread=spread or 45
	local big,small,cbig,csmall
	if type=="power" then
		big=400
		small=20
		cbig="red"
		csmall="blue"
	elseif type=="score" then
		big=math.max(2000,number/20)
		small=math.max(100,number/400)
		cbig="yellow"
		csmall="green"
	end
	if compress then
		local rad=ran:int(-90-spread,-90+spread)
		local v=ran:float(vmin,vmax)
		local amount=number
		if type=="score" then amount=-amount end
		if (type=="score" and number<1000) or (type=="power" and number<100) then
			createBullet("power",csmall,x,y,nil,nil,nil,nil,nil,rad,v,amount)
		else
			createBullet("power",cbig,x,y,nil,nil,nil,nil,nil,rad,v,amount)
		end
		return
	end
	if number>=big then
		local cnt=math.floor(number/big)
		for i=1,cnt do
			local rad=ran:int(-90-spread,-90+spread)
			local v=ran:float(vmin,vmax)
			local amount=big
			if type=="score" then amount=-amount end
			createBullet("power",cbig,x,y,nil,nil,nil,nil,nil,rad,v,amount)
		end
		number=number%big
	end
	number=math.ceil(number/small)
	for i=1,number do
		local rad=ran:int(-90-spread,-90+spread)
		local v=ran:float(vmin,vmax)
		local amount=small
		if type=="score" then amount=-amount end
		createBullet("power",csmall,x,y,nil,nil,nil,nil,nil,rad,v,amount)
	end
end