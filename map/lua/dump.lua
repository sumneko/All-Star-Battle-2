
	dump	= {}
	local dump	= dump
	setmetatable(dump, dump)

	--此luac文件的版本为5.2
	local result	= pcall(require, 'lua\\dump.luac')
	
	--目前11平台的lua引擎版本为5.2,如果acb成功回归11平台,将lua引擎版本更新为5.3或更高版本后,该luac文件将会加载失败
	--希望他能加载失败吧~
	----写于2014年12月27日
	if result then
		dump.enable	= true
	else
		dump.enable	= false
		
		function dump.save()
			return ''
		end

		function dump.load()
			return ''
		end
	end