
	sync = {}

	local sync = sync

	setmetatable(sync, sync)

	--初始化同步系统
	function sync.init()
		sync.gc		= jass.InitGameCache 'U'
		sync.using	= {} --记录正在使用的
		sync.str	= 'abcdefghijklmnopqrstuvwxyz0123456789'
	end

	sync.init()

	--同步某数据
	---玩家, 数据(k, string)
	function player.__index.sync(p, data, func)
		if p:isObserver() or not p:isPlayer() then
			print(('sync.lua warning:player %d is not an alive player'):format(p:get()))
			return
		end
		local i 	= 0
		local index = 0
		for n = 1, 36 do
			if not sync.using[n] then
				sync.using[n]	= data
				index	= n
				break
			end
		end
		if index == 0 then
			error('sync.lua error:Could not find idle index', 2)
			return
		end
		sync.first	= sync.str:sub(index, index)
		local keys	= {}
		for name, value in pairs(data) do
			i	= i + 1
			keys[i]	= name
			if p == player.self then
				--将数据保存到缓存中
				jass.StoreInteger(sync.gc, sync.first, sync.str:sub(i, i), value)
				--发起同步
				jass.SyncStoredInteger(sync.gc, sync.first, sync.str:sub(i, i))
			end
			--清空本地数据
			jass.StoreInteger(sync.gc, sync.first, sync.str:sub(i, i), 0)
		end
		--发送一个结束标记
		if p == player.self then
			jass.StoreInteger(sync.gc, sync.first, '-', 1)
			jass.SyncStoredInteger(sync.gc, sync.first, '-')
		end
		jass.StoreInteger(sync.gc, sync.first, '-', 0)
		--开启计时器,等待同步完成
		timer.loop(0.1,
			function(t)
				--检查是否同步完成
				if jass.GetStoredInteger(sync.gc, sync.first, '-') == 0 then
					--检查是否还在游戏中
					if not p:isPlayer() then
						sync.using[index]	= nil
						t:destroy()
					end
					return
				end
				sync.using[index]	= nil
				t:destroy()
				--同步完成,开始写回数据
				for i, name in ipairs(keys) do
					data[name]	= jass.GetStoredInteger(sync.gc, sync.first, sync.str:sub(i, i))
					print(('player[%d] synced: %s = %s'):format(p:get(), name, data[name]))
				end
				--回调数据
				if func then
					func(data)
				end
			end
		)
	end