--加载jass.message后会屏蔽11平台的改键
local message = require 'jass.message'
print('加载jass.message库', message)
if not message then
	return
end

--显示多面板
local board
local function show_board(is_show)
	if not board then
		board = jass.udg_duomianban[0]
		if not board then
			return
		end
		print('多面板:', board)
	end
	print('多面板状态', is_show)
	jass.MultiboardMinimize(board, not is_show)
end

local keyboard = message.keyboard

--本地消息
function message.hook(msg)
	--键盘按下消息
	if msg.type	== 'key_down' then
		local code = msg.code
		local state	= msg.state

		--如果是组合键,则跳过
		if state ~=	0 then
			return true
		end
		
		--tab
		if code	== 515 then
			show_board(true)
			return false
		end
	end

	--键盘放开消息
	if msg.type	== 'key_up' then
		local code = msg.code
		
		--如果是组合键,则跳过
		local state = msg.state
		if state ~= 0 then
			return true
		end
		
		--tab
		if code == 515 then
			show_board(false)
			return false
		end
	end

	return true
end
