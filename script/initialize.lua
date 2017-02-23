--初始化
function love.load()
	--库
	require("DMClib")

	--消息
	message={}

	--随机数
	ran:setSeed(os.time())

	--本体
	game={
		width=love.graphics.getWidth(),
		height=love.graphics.getHeight(),
		debug=0,
		version="V0.3 Beta",
		name="Danmaku Music Confetti",
		canvas=love.graphics.newCanvas(),
		tmpCanvas=love.graphics.newCanvas(),
		bCanvas=love.graphics.newCanvas(),
		pCanvas=love.graphics.newCanvas(),
		preCanvas=love.graphics.newCanvas(),
		keyCanvas=love.graphics.newCanvas(),
		isFocus=true,
		replay=nil,
		interval={
			["player"]=1,
			["bullet"]=1,
			["enemy"]=1,
			["level"]=1,
			["bonus"]=1,
			["system"]=1
		},
		shader={
			inverse2=love.graphics.newShader("asset/effect/inverse.fs")
		},
		save={},
		active={},
		frame=0,
		audio={},
		state={},
		sound={},
		keyboard={
			{"0","1","2","3","4","5","6","7","8","9"},
			{"A","B","C","D","E","F","G","H","I","J"},
			{"K","L","M","N","O","P","Q","R","S","T"},
			{"U","V","W","X","Y","Z","+","-","*","/"},
			{"[","]","#","$",".","~"," ","<","×","√"},
			title="无",
			x=290,
			y=200,
			pos={x=1,y=1},
			res=nil,
			frame=0,
			size=50,
			text="为要保存的录像命名。"
		},
		difficulty={"EASY","NORMAL","HARD","LUNATIC"}
	}

	--读取存档
	fileLoad()

	game.push=function(update,draw,filedropped)
		local tmp={
			update=love.update,
			filedropped=love.filedropped,
			draw=love.draw
		}
		SD.first=0
		table.insert(game.state,tmp)
		love.update=update
		love.draw=draw
		love.filedropped=filedropped
	end
	game.pop=function()
		if #(game.state)>0 then
			local cur=game.state[#(game.state)]
			love.update=cur.update
			love.filedropped=cur.filedropped
			love.draw=cur.draw
			table.remove(game.state,#(game.state))
			return true
		end
		return false
	end
	game.preDraw=function(...)
		if #(game.state)>0 then
			game.state[#(game.state)].draw(...)
		else
			love.graphics.setCanvas(game.preCanvas)
			love.graphics.clear()
		end
	end

	game.graphics={
		width=600,
		height=600,
		dx=50,
		dy=50,
		color={50,0,50,0},
		font={},
		colorset={
			"blue",
			"red",
			"purple",
			"green",
			"yellow",
			"orange",
			"violet"
		}
	}

	game.title=game.name.." ~ "..game.version.." [By Shimatsukaze]"

	for i=1,20 do
		game.save[i]=love.graphics.newCanvas()
	end

	--界面与列表
	game.main={
		{
			y1=200,
			y2=245,
			text="开始",
			type="button",
			desc="进入选择音乐界面。",
			click=function(self)
				addGradual(fnil,updateMenu,love.draw,drawMenu,30,30,true,function(...)
					love.filedropped=fileDrop
				end)
			end
		},
		{
			y1=260,
			y2=305,
			text="录像回放",
			type="button",
			desc="回放之前的游戏记录。",
			click=function(self)
				game.replay=true
				addGradual(fnil,updateMenu,love.draw,drawMenu,30,30,true)
			end
		},
		{
			y1=320,
			y2=365,
			text="游戏设置",
			type="button",
			desc="修改游戏有关设置。",
			click=function(self)
				option=getSetting(false,option)
			end
		},
		{
			y1=380,
			y2=425,
			text="秘密档案",
			type="button",
			desc="查看游戏相关信息。",
			click=function(self)
				option=game.document
			end
		},
		{
			y1=440,
			y2=485,
			text="退出",
			type="button",
			desc="退出游戏并保存当前的音乐信息和游戏设置。",
			click=function(self)
				love.event.quit()
			end,
			confirm={
				desc="退出游戏并保存当前的音乐信息和游戏设置。",
				pos=1
			}
		},
		y1=200,
		y2=245,
		title=game.name,
		pos=1,
		hotkey={
			escape=function(self)
				if self.pos~=#(self) then
					self.pos=#(self)
				else
					applyConfirm()
				end
			end
		}
	}
	game.document={
		{
			y1=200,
			y2=245,
			text="返回上级菜单",
			type="button",
			click=function(self)
				option=game.main
			end
		},
		{
			y1=250,
			y2=295,
			text="操作说明",
			type="button",
			desc=[[通过导入自己的音乐生成弹幕！
按方向键进行移动，按住SHIFT来慢速移动，同时查看判定点和SP。
擦弹可以积累SP，当SP达到一定量，被弹时可以按X发动决死。
成功决死将消耗SP并短暂无敌，在之后一段时间高亮显示判定。
3秒没有操作自动回收资源。
游戏过程中按ESC可以暂停游戏。
请享受音乐与弹幕吧。]]
		},
		{
			y1=300,
			y2=345,
			text="开发者",
			type="button",
			desc=[[
程序/UI：Shimatsukaze
美工：Futurer]]
		},
		{
			y1=350,
			y2=395,
			text="关于版本",
			type="button",
			desc="名称："..game.name.."\n版本号："..game.version.."\n（第"..transVersion(game.version).."个版本）\n请查看about.txt以获取详细信息。"
		},
		{
			y1=400,
			y2=445,
			text="成就",
			type="button",
			click=function(self)
				option=achievementList(1)
			end
		},
		y1=200,
		y2=245,
		title="秘密档案",
		pos=1,
		hotkey={
			escape=function(self)
				if self.pos~=1 then
					self.pos=1
				else
					self[1].click(self[1])
				end
			end,
			dodge=function(self)
				local tmp=self[self.pos]
				if tmp.text=="开发者" then
					local keys=game.keyboard
					keys.onEnd=checkDevMode
					keys.title="？？？"
					keys.text="龙骧"
					game.push(updateInputText,drawInputText)
					checkAchievement("discoverDevMode")
				end
			end
		}
	}

	--读取文件
	initLoad()

	--光标
	cursor={
		pos=1,
		showpos=0,
		rectpos=100
	}

	--常量
	C={
		S2=math.sqrt(2),
		S2_2=math.sqrt(2)/2,
		PI=math.pi,
		inf=2147483647,
		eps=1e-3,
		wait=0.05
	}

	--按键
	keyDown={
		["up"]=0,
		["down"]=0,
		["left"]=0,
		["right"]=0,
		["fire"]=0,
		["dodge"]=0,
		["slow"]=0,
		["escape"]=0,
		["enter"]=0,
		["delete"]=0,
		["Y"]=0,
		["N"]=0
	}
	keyMap={
		["up"]="up",
		["down"]="down",
		["left"]="left",
		["right"]="right",
		["z"]="fire",
		["x"]="dodge",
		["lshift"]="slow",
		["rshift"]="slow",
		["escape"]="escape",
		["return"]="enter",
		["delete"]="delete",
		["backspace"]="delete",
		["y"]="Y",
		["n"]="N"
	}
	keyTime={first=0.3,rep=0.1}
	keyRepeat={}
	for k,v in pairs(keyDown) do
		keyTime[k]=v
		keyRepeat[k]=v
	end

	--录像
	keyRec={"up","down","left","right","slow","fire","dodge"}

	--单位
	enemy={}
	bullet={}
	object={}

	--随机数
	math.randomseed(os.time())

	--初始化弹幕
	initPattern()

	--初始化成就
	initAchievement()

	--开始
	player:init()
	player:load("reimu")

	checkAchievement("firstOpen")
	option=game.main
	addGradual(fnil,updateOption,fnil,drawOption,0,30,true)
	love.window.setTitle(game.title)
end