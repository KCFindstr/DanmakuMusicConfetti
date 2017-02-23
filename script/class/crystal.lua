--返回一个table，其中create为创建时运行的函数。
--create需要返回GP.polygon等合法的规则图形，表示判定区域（单位：像素），图像中心坐标为(0,0)
--详细参考http://hc.readthedocs.io/en/latest/index.html
--create函数可以为该类弹幕添加各种键值（不能冲突）
return {
	create=function()
		return GP:polygon(-16,-1,-1,-14,16,-1,-1,10)
	end
}