--该文件将返回一个table
return {
	--pattern名称
	name="defaultLong",

	--calc函数为主要的计算函数，接受两个参数note与warning，都是table类型
	--note为计算出的音符，每个音符为一个table，含有f,t,energy三个属性
		--f为开始时间，t为结束时间（若为nil说明不是连续音符），energy为音符能量，规范化到了0~1之间
	--另外，note有其余的特殊键值：
		--bpm：实质是两拍的间隔时间，所以实际bpm为60/note.bpm
	--warning表示音符的提前提示（在游戏中为逐渐变小的提示圆圈），不需要读取，只需要修改
		--使用table.insert插入一个table，需要有x、y表示在游戏中的位置，t表示提示的时间，color表示提示圆圈颜色
		--若color为nil则采用默认颜色
	--calc函数应当返回一个table和data，table中的元素为使用过的音符编号。这些音符将被note中抹去。
	--data将在游戏中传送给run函数
	calc=function(note,warning)
		for i=1,#(note) do
			local cur=note[i]
			if cur.t then
				local x=ran:int(100,game.graphics.width-100)
				local y=ran:int(100,game.graphics.height-100)
	--game.graphics.width/height表示游戏界面的宽与高（不是窗口大小）
				local data={
					f=cur.f,
					t=cur.t,
					energy=cur.energy,
					x=x,
					y=y,
					bpm=note.bpm,
					beg=ran:int(1,15)
				}
				table.insert(warning,{
					x=x,
					y=y,
					t=cur.f,
					color=nil
				})
				return {i},data
			end
		end
	end,

	--run函数用于读取生成的data并运行
	--代码开始时调用coroutine.yield(-data.f)，表示该代码应当在data.f开始被调用。
	--coroutine.yield实质可以看作是暂停。我的任务管理器会根据你在yield中返回的信息决定下次调用你的时间。
	--如果返回负数表示时间计时器（秒），如果返回正数表示帧数计数器（帧），不要返回0
	--如果你的函数结束或返回值不正确，任务管理器会自动将其抹去
	--我提供的可以调用的函数（如createBullet，setV等）可以在script/object.lua中查看。
	run=function(data)
		coroutine.yield(-data.f)
		local delta=21-3*mList.difficulty
		local cur,add=data.f+data.bpm,data.bpm
		while cur<data.t do
			local beg=data.beg
			for i=1,360/delta do
				local tmp=createBullet("crystal","violet",data.x,data.y)
				setV(tmp,3,beg)
				beg=beg+delta
			end
			coroutine.yield(-cur)
			cur=cur+add
		end
	end
}