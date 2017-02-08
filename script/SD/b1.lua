--s开头的文件与p开头的文件唯一区别在于：s*.lua只能返回一个值，即它只能使用一个音符
return {
	name="targetPlayer",
	calc=function(note,warning)
		local cur=note[1]
		local x=ran:int(100,game.graphics.width-100)
		local y=ran:int(100,game.graphics.height-100)
		local data={
			f=cur.f,
			x=x,
			y=y
		}
		table.insert(warning,{
			x=x,
			y=y,
			t=cur.f,
			color=nil
		})
		return 1,data
	end,

	run=function(data)
		coroutine.yield(-data.f)
		local tmp=createBullet("crystal","violet",data.x,data.y)
		setV(tmp,5,0,player)
	end
}