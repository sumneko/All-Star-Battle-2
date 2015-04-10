    jass = require 'jass.common'
	japi = require 'jass.japi'
	slk = require 'jass.slk'
    hook = require 'jass.hook'
	storm = require 'jass.storm'
    
    print 'hello world'
    
	--汇报错误啦
	function debug.info(s, this)
		local t = {}
		for name, v in pairs(this) do
			table.insert(t, ('[%s] %s'):format(name, v))
		end
		print(('%s\n=======================\n%s\n=======================\n'):format(s, table.concat(t, '\n')))
	end
    
    unpack = unpack or table.unpack
    load = load or loadstring

    --全局环境
    setmetatable(_G,
		{
			__index	= function(_, name)
				error(('Warning:load global var is nil: "%s"'):format(name), 2)
			end,
			__newindex	= function(_, name, value)
				if type(value) ~= 'table' then
					print(('Warning:save global var is not table: "%s" = %s'):format(name, value))
				end
				rawset(_G, name, value)
			end,
		}
    )
    
	require 'lua\\util.lua'
	require 'lua\\dump.lua'
	require 'lua\\event.lua'
	require 'lua\\table.lua'
	require 'lua\\timer.lua'
	require 'lua\\player.lua'
	require 'lua\\cmd.lua'
	require 'lua\\game.lua'
	require 'lua\\text.lua'
	require 'lua\\check11.lua'
	require 'lua\\sync.lua'
	require 'lua\\11record.lua'

	require 'lua\\record.lua'
	require 'lua\\hot_fix.lua'

	require 'lua\\debug.lua'