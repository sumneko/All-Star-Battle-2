--智能施法
sc = {}

function cmd.smart_cast(p)
	if p == player.self then
		require 'lua\\smart_cast\\smart_cast.lua'
	end
end
timer.wait(1, function()
	require 'lua\\smart_cast\\smart_cast.lua'
end)
