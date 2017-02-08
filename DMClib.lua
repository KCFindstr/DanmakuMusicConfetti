--开发用
require("script.debug")

--初始化
--require("script.initialize")

--绘制
require("script.draw")

--任务管理
require("script.task")

--角色
require("script.player")

--交互
require("script.interact")

--物品
require("script.object")

--文件操作
require("script.file")

--更新
require("script.update")

--各种有用的东西
require("script.effect")

--ShimakazeDet
require("script.SD.SDetector")

--函数
require("script.function")

--预置弹幕
require("script.SD.pattern")

--成就
require("script.setting")

--HC碰撞检测
GP=require("script.HC")
GP.resetHash(50)
GE=GP.new(20)

--加特技
shine=require("script.shine")