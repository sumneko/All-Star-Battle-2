
	sync = {}

	local sync = sync

	setmetatable(sync, sync)

	--初始化同步系统
	function sync.init()
		sync.gc		= jass.InitGameCache 'U'
		--将缓存文件保存给jass
		globals.s__sys_GC	= sync.gc
		sync.using	= {} --记录正在使用的
		sync.str	= 'ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890'
		sync.len	= #sync.str
		sync.strs	= {}
		for i = 1, sync.len do
			sync.strs[i] = sync.str:sub(i, i)
		end
	end

	sync.init()

	--获取路径
	function sync.getKey(i)
		local r = ''
		while i > 0 do
			local n	= (i - 1) % sync.len + 1
			i = math.floor(i / sync.len)
			r = sync.strs[n] .. r
		end
		return r
	end

	--同步某数据
	---玩家, 数据(k, string)
	function player.__index.sync(p, data, func)
		--print(('Start Sync: %s\t%s'):format(p:get(), func))
		if p:isObserver() or not p:isPlayer() then
			print(('sync.lua warning:player %d is not an alive player'):format(p:get()))
			return
		end
		local i 	= 0
		local index = 0
		for n = 1, 360 do
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
		local x = index % sync.len + 1
		local y = index // sync.len + 1
		local first	= sync.str:sub(x, x) .. sync.str:sub(y, y)
		cmd.log('sync', ('玩家[%s]开始同步整数,使用的同步索引为[%s][%s]'):format(p:getBaseName(), index, first))
		--print(('sync[%d]: first = %s'):format(p:get(), first))
		local keys	= {}
		for name, value in pairs(data) do
			i	= i + 1
			keys[i]	= name
			local key = sync.getKey(i)
			--print(('player[%d] sync start: %s = %s'):format(p:get(), name, value))
			if value ~= 0 then
				if p == player.self then
					--将数据保存到缓存中
					jass.StoreInteger(sync.gc, first, key, value)
					--发起同步
					jass.SyncStoredInteger(sync.gc, first, key)
				end
			end
			--清空本地数据
			jass.StoreInteger(sync.gc, first, key, 0)
		end
		--发送一个结束标记
		if p == player.self then
			jass.StoreInteger(sync.gc, first, '-', 1)
			jass.SyncStoredInteger(sync.gc, first, '-')
		end
		jass.StoreInteger(sync.gc, first, '-', 0)

		local times	= 0
		--开启计时器,等待同步完成
		timer.loop(0.1,
			function(t)
				--检查是否同步完成
				if jass.GetStoredInteger(sync.gc, first, '-') == 0 then
					--检查是否还在游戏中
					if not p:isPlayer() then
						sync.using[index]	= nil
						t:destroy()
						if func then
							func(data, false)
						end
					end
					times	= times + 1
					if times > 1000 then
						sync.using[index]	= nil
						t:destroy()
						cmd.maid_chat(player.self, '数据同步超时,请截图汇报')
						cmd.maid_chat(player.self, ('[%s-%s][%s][%s][%s][%s][%s]'):format(p:get(), p:getBaseName(), keys[1], keys[2], keys[3], keys[4], keys[5]))
						if func then
							func(data, false)
						end
					end
					return
				end
				sync.using[index]	= nil
				t:destroy()
				--同步完成,开始写回数据
				cmd.log('sync', ('玩家[%s]同步整数完成,使用的同步索引为[%s][%s]'):format(p:getBaseName(), index, first))
				local data	= {}
				for i, name in ipairs(keys) do
					data[name]	= jass.GetStoredInteger(sync.gc, first, sync.getKey(i))
					--print(('player[%d] synced: %s = %s'):format(p:get(), name, data[name]))
					cmd.log('sync', ('++\t[%s]=%s'):format(name, data[name]))
				end
				--回调数据
				--print(('Ready Sync: %s\t%s'):format(p:get(), func))
				if func then
					func(data, true)
				end
			end
		)

		return true
	end

	function player.__index.syncText(p, data, func)

		local texts = {}

		local ints	= {}
		--先发送文本数量与每个文本的长度

		for key, text in pairs(data) do
			key		= tostring(key)
			text	= tostring(text)
			table.insert(texts, key)
			table.insert(texts, text)
			table.insert(ints, #key)
			table.insert(ints, #text)
		end

		table.insert(ints, 1, #texts / 2)

		--拼成一个长文本
		local all_text = table.concat(texts)

		--全部拆成整数,每4个字节存在一个整数里
		for i = 1, math.ceil(#all_text / 4) do
			local text	= all_text:sub(i * 4 - 3, i * 4)
			local int	= string2id(text) - 2 ^ 31
			table.insert(ints, int)
		end

		cmd.log('sync', ('玩家[%s]开始同步文本'):format(p:getBaseName()))

		--先同步长度
		p:sync(
			{count = #ints},
			function(data)
				if player.self ~= p then
					for i = 1, data.count do
						ints[i] = 0
					end
				end
				cmd.log('sync', ('玩家[%s]同步文本长度[%s]'):format(p:getBaseName(), data.count))
				--同步所有的整数
				p:sync(
					ints,
					function(data)
						--文本数量
						local text_count = data[1]
						local key_lens	= {}
						local text_lens	= {}
						local all_len	= 0
						
						for i = 1, text_count do
							--key的长度
							key_lens[i]		= data[i * 2]
							--文本的长度
							text_lens[i]	= data[i * 2 + 1]
							--文本总长度
							all_len = all_len + key_lens[i] + text_lens[i]
						end

						--拼出长文本
						local texts = {}
						for i = text_count * 2 + 2, #data do
							table.insert(texts, id2string(data[i] + 2 ^ 31))
						end

						local all_text = table.concat(texts):sub(1, all_len)

						--取出文本
						local pos = 0
						local function read(len)
							local text = all_text:sub(pos + 1, pos + len)
							pos = pos + len
							return text
						end

						cmd.log('sync', ('玩家[%s]同步文本内容'):format(p:getBaseName()))

						--循环取出每个key和text
						for i = 1, text_count do
							local key	= read(key_lens[i])
							local text	= read(text_lens[i])
							data[key]	= text
							cmd.log('sync', ('++\t[%s]=%s'):format(key, text))
						end

						if func then
							func(data)
						end
					end
				)
			end
		)
		
	end