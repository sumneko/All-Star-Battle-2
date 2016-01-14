--加载jass.message后会屏蔽11平台的改键
local message = require 'jass.message'
print('加载jass.message库', message)
if not message then
	return
end

local order = require 'lua\\smart_cast\\order.lua'

--显示本地消息(开销较高,正式版要注释掉)
message.order_enable_debug()

--单位是否存活
local function is_alive(u)
	return u and jass.GetUnitTypeId(u) ~= 0 and not jass.IsUnitType(u, 1)
end

--获取自己的英雄
local function get_hero()
	return game.selfHero
end

--选择自己的英雄
local function select_hero()
	local hero = get_hero()
	if hero and is_alive(hero) then
		jass.ClearSelection()
		jass.SelectUnit(hero, true)
		return hero
	end
end

--锁定选择自己的英雄
local function lock_hero(is_lock)
	if is_lock then
		local hero = select_hero()
		if hero then
			print('锁定英雄', hero)
			jass.SetCameraTargetController(hero, 0, 0, false)
			return true
		end
	else
		print('解锁视角')
		jass.SetCameraPosition(jass.GetCameraTargetPositionX(), jass.GetCameraTargetPositionY())
		return true
	end
	return false
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

		--空格
		if code == 32 then
			lock_hero(true)
			return false
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

		--空格
		if code == 32 then
			lock_hero(false)
			return false
		end
		
		--tab
		if code == 515 then
			show_board(false)
			return false
		end
	end

	return true
end
