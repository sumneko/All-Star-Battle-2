
	record = {}

	local record = record

	setmetatable(record, record)

	record.GC = jass.InitGameCache 'M'

	if not japi.InitGameCache then
		local names	= {
			'InitGameCache',
			'StoreInteger',
			'GetStoredInteger',
			'StoreString',
			'SaveGameCache'
		}
		
		for _, name in ipairs(names) do
			rawset(japi, name, jass[name])
		end

	end

	function record.i2s(i)
		return ('ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890/*-+=,.<>\\|[]{};:!@#$%^&()'):sub(i, i)
	end

	function record.init()
		for i = 1, 16 do
			record[i] = jass.GC[i - 1]
			player[i].record = record[i]
			player[i].record_data = {}
		end
	end

	timer.wait(1, record.init)

	function player.__index.getRecord(this, name)
		--print(('load record: %s = %s'):format(name, japi.GetStoredInteger(this.record, '', name)))
		return japi.GetStoredInteger(this.record, '', name) or 0
	end

	function player.__index.setRecord(this, name, value)
		--print(('save record: %s = %s'):format(name, value))
		return japi.StoreInteger(this.record, '', name, value)
	end

	function player.__index.saveRecord(this)
		return japi.SaveGameCache(this.record)
	end

	--保存名字
	function record.saveName(first, name, value)
		player.self:setRecord(first .. 0, value)
		
		--将名字拆成4个整数
		player.self:setRecord(first .. 1, __id(name:sub(1, 4)) - 2 ^ 31)
		player.self:setRecord(first .. 2, __id(name:sub(5, 8)) - 2 ^ 31)
		player.self:setRecord(first .. 3, __id(name:sub(9, 12)) - 2 ^ 31)
		player.self:setRecord(first .. 4, __id(name:sub(13, 16)) - 2 ^ 31)

	end

	--读取名字
	function record.loadName(first)
		local value = player.self:getRecord(first .. 0)
		
		--将4个整数组装成名字
		local name	= _id(player.self:getRecord(first .. 1) + 2 ^ 31) .. _id(player.self:getRecord(first .. 2) + 2 ^ 31) .. _id(player.self:getRecord(first .. 3) + 2 ^ 31) .. _id(player.self:getRecord(first .. 4) + 2 ^ 31)
		--print(name)
		return name:match '(%Z+)', value
	end

	--本地记录玩家
	--解析本地文件
	function record.read_players(text)
		for line in text:gmatch '(%C+)' do
			local name, value	= line:match '(.+)%=(%d+)'
			if name then
				table.insert(player.self.record_data, name)
				player.self.record_data[name] = tonumber(value)
			end
		end
	end
	
	function record.save_players()
		local text	= storm.load 'save\\Profile1\\Campaigns.mu'
		if text then
			record.read_players(text)
		end
		local data = player.self.record_data

		--取出胜利最多的一个名字
		local name, value	= record.loadName('mt')
		if value > 0 then
			if not data[name] then
				table.insert(data, name)
			end
			data[name] = math.max(data[name] or 0, value)
		end

		--保存当前名字
		local name = player.self:getBaseName()
		
		if not data[name] then
			table.insert(data, name)
		end
		data[name] = math.max(data[name] or 0, player.self:getRecord '胜利')
		
		--生成新的本地记录
		local texts = {}
		for _, name in ipairs(data) do
			table.insert(texts, ('%s=%d'):format(name, data[name]))
		end
		--保存到本地
		--print(table.concat(texts, '\n'))
		storm.save('save\\Profile1\\Campaigns.mu', table.concat(texts, '\n'))

		--找到胜利最多的一个名字
		local name	= table.pick(data,
			function(name1, name2)
				return data[name1] > data[name2]
			end
		)

		--保存该名字
		record.saveName('mt', name, data[name])
		--print(name, player.self:getBaseName())

		player.self:saveRecord()

		--将胜利信息发送给其他玩家
		jass.StoreInteger(record.GC, 'mt0', player.self:get(), data[name])
		jass.SyncStoredInteger(record.GC, 'mt0', player.self:get())
		
	end

	--计算节操
	function record.init_jc()
		local player_num 	= 0 --记录玩家数
		local my_team		= 0 --本方玩家数
		local enemy_team	= 0 --敌方玩家数
		local team			= player.self:getTeam()
		local lv1			= 0 --本方胜利总和
		local lv2			= 0 --敌方胜利总和
		
		record.jc = {}
		--读取节操
		for i = 1, 10 do
			record.jc[i] = table.new(0){
				['节操'] = player[i]:getRecord '节操',
				['收益'] = 1,
			}
			if player[i]:isPlayer() then
				if player[i]:getTeam() == team then
					my_team 	= my_team + 1
					lv1			= lv1 + math.max(player[i]:getRecord 'mt0', jass.GetStoredInteger(record.GC, 'mt0', i))
				else
					enemy_team 	= enemy_team + 1
					lv2			= lv2 + math.max(player[i]:getRecord 'mt0', jass.GetStoredInteger(record.GC, 'mt0', i))
				end
				player_num = player_num + 1
			end
		end
		local jc = record.jc[player.self:get()]

		if my_team ~= enemy_team then
			return
		end

		if player_num < 10 then
			jc['收益'] = jc['收益'] * player_num / 10
		end

		--判定是不是在开小号
		local is_main	= true
		local data	= player.self.record_data
		local name, value	= record.loadName('mt')
		if data[name] ~= data[player.self:getBaseName()] then
			is_main	= false
		end
		
		--对比双方战绩
		if lv1 < lv2 then
			local n = lv2 - lv1
			local x = 0
			if n <= 200 then
				x = x + n * 0.01
			else
				x = x + 200 * 0.01
				n = n - 200
				if n <= 500 then
					x = x + n * 0.005
				else
					x = x + 500 * 0.005
					n = n - 500
					if n <= 1000 then
						x = x + n * 0.002
					else
						x = x + 1000 * 0.002
						n = n - 1000
						x = x + n * 0.001
					end
				end
			end
			cmd.maid_chat(player.self, '主人,对方很强要加油哦')
			cmd.maid_chat(player.self, ('不管输赢本局您都可以获得额外%.1f%%节操收益哦~'):format(100 * x))
			jc['收益'] = jc['收益'] * (1 + x)
		else
			--检查是不是差距太大了
			if lv1 > 100 then
				local n = lv1 - lv2
				local x = 1
				if n > 5000 then
					x = 0.1
				elseif n > 2000 then
					x = 0.2
				elseif n > 1000 then
					x = 0.3
				elseif n > 800 then
					x = 0.4
				elseif n > 600 then
					x = 0.5
				elseif n > 500 then
					x = 0.6
				elseif n > 400 then
					x = 0.7
				elseif n > 300 then
					x = 0.8
				elseif n > 200 then
					x = 0.9
				end
				if x ~= 1 then
					cmd.maid_chat(player.self, '主人呀,对面差你们太多了吧')
					cmd.maid_chat(player.self, ('本局的节操收益只有%d%%了哟'):format(100 * x))
					jc['收益'] = jc['收益'] * x
				end
			end
			
			--检查是不是小号
			if not is_main then
				if player.self:getRecord '胜利' == 0 then
					cmd.maid_chat(player.self, '主人您居然开小号虐菜!从下局开始节操收益会降低25%')
					cmd.maid_chat(player.self, '主人您的大号是 [' .. name .. '] 没错吧~')
				else
					cmd.maid_chat(player.self, '主人您又在开小号虐菜了,您本局的节操收益降低25%')
					cmd.maid_chat(player.self, '主人您的大号是 [' .. name .. '] 没错吧~')
					jc['收益'] = jc['收益'] * 0.75
				end
			end
		end

		print('jc:' .. jc['收益'])
	end
	
	timer.wait(1,
		function()
			
			record.save_players()
			
		end
	)

	timer.wait(10,
		function()
			record.init_jc()
		end
	)

	function cmd.game_over(p, tid)
		local n = timer.time() --每分钟+1节操
		local jc = record.jc[player.self:get()]
		print 'game_over'
		tid = tonumber(tid)
		if tid == p:getTeam() then
			n = n + 30 --胜利+30节操
			n = math.floor(n * jc['收益'])
			cmd.maid_chat(player.self, ('恭喜获胜,您本局收获了 %d 点节操哦~'):format(n))
		else
			n = n + 20 --失败+20节操
			n = math.floor(n * jc['收益'])
			cmd.maid_chat(player.self, ('主人,您本局收获了 %d 点节操哦~'):format(n))
		end
		jc['节操'] = jc['节操'] + n
		player.self:setRecord('节操', jc['节操'])
	end