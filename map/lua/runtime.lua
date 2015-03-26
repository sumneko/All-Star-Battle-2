
	runtime = require 'jass.runtime'

	--打开控制台
	--runtime.console = true
	--设置句柄等级为0(地图中所有的句柄均使用table封装)
	runtime.handle_level = 0
	--关闭等待功能
	runtime.sleep = false