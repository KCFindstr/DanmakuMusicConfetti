function levelBegin()
	while true do
		local add=ran:int(1,15)
		for i=add,360,15 do
			local tmp=createBullet("crystal","violet",
				game.graphics.width/2,
				game.graphics.height/2
			)
			setV(tmp,3,i)
		end
		coroutine.yield(30)
	end
end