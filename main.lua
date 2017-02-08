require("script.initialize")

function love.quit()
	if game.audio.music and game.audio.music:isPlaying() then
		game.audio.music:stop()
	end
	fileSave()
end

function love.drawMessage(dt)
	if #(message)>0 then
		local cur=message[1]
		if cur.t==-1 then
			cur.t=0
			return
		end
		cur.t=cur.t+dt
		if cur.t>cur.p1+cur.p2+cur.p3 then
			table.remove(message,1)
			return
		end
		local x=game.width-cur.width-20
		local y=game.height-cur.height-20
		if cur.t<cur.p1 then
			y=game.height-(cur.height+20)*cur.t/cur.p1
		elseif cur.t>cur.p1+cur.p2 then
			y=game.height-(cur.height+20)*(cur.p1+cur.p2+cur.p3-cur.t)/cur.p3
		end
		love.graphics.setColor(cur.color)
		love.graphics.rectangle("fill",x,y,cur.width,cur.height)
		love.graphics.setColor(0,0,0,128)
		drawText(cur.title,24,x+13,y+13,"chn")
		drawText(cur.text,20,x+12,y+52,"chn")
		love.graphics.setColor(255,255,255,255)
		drawText(cur.title,24,x+10,y+10,"chn")
		drawText(cur.text,20,x+10,y+50,"chn")
	end
end

function love.run()
	if love.math then
		love.math.setRandomSeed(os.time())
	end
	if love.load then love.load(arg) end
 
	-- We don't want the first frame's dt to include time taken by love.load.
	if love.timer then love.timer.step() end

	local dt = 0

	-- Main loop time.
	while true do
		-- Process events.
		if love.event then
			love.event.pump()
			for name, a,b,c,d,e,f in love.event.poll() do
				if name == "quit" then
					if not love.quit or not love.quit() then
						return a
					end
				end
				love.handlers[name](a,b,c,d,e,f)
			end
		end

		-- Update dt, as we'll be passing it to update
		if love.timer then
			love.timer.step()
			dt = love.timer.getDelta()
		end

		-- Call update and draw
		if love.update then love.update(dt) end -- will pass 0 if love.timer is disabled

		if love.graphics and love.graphics.isActive() then
			love.graphics.clear(love.graphics.getBackgroundColor())
			love.graphics.origin()
			if love.draw then love.draw() end
			if love.drawMessage then love.drawMessage(dt) end
			love.graphics.present()
		end
 
		if love.timer then love.timer.sleep(0.001) end
	end
end