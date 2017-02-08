function love.conf(t)
	t.title="重装小兔瞌睡中……"
	t.author="Shimatsukaze"
	t.identity="DMConfetti"

	t.window.width=1080
	t.window.height=720
	t.window.vsync=true

	t.modules.joystick=false
	t.modules.touch=false
	t.modules.mouse=false
	t.modules.physics=false

	t.console=true --for debug
end