--调试输出
function debug(text)
	if game.debug>0 then
		print(text)
	end
end

--版本识别
function transVersion(text)
	if text=="V0.1 Beta" then
		return 1
	end
	if text=="V0.2 Beta" then
		return 2
	end
	return nil
end