
	dump	= {}
	local dump	= dump
	setmetatable(dump, dump)
	
	--此luac文件的版本为5.3
	local result	= pcall(require, 'lua\\dumpc')
	
	if result and dump.save then
		dump.enable	= true
		print 'dump enbale'
	else
		dump.enable	= false
		print 'dump disable'
		print('result', result, 'dump.save', dump.save)
		
		function dump.save()
			return ''
		end

		function dump.load()
			return ''
		end
	end