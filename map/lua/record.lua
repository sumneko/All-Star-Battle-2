
	record = {}

	local record = record

	setmetatable(record, record)

	time.syncTime()

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

	function cmd.initRecord()
		for i = 1, 16 do
			record[i] = jass.GC[i - 1]
			player[i].record = record[i]
			player[i].record_data = {}
			record[record[i]]	= player[i]
		end

		event('注册积分', {})
	end

	--本地积分
	record.my_record	= {}

	function cmd.getRecord(p, name)
		jass.udg_Lua_integer	= p:getRecord(name)
	end

	function player.__index.getRecord(this, name)
		--print(('player[%d] load record: %s = %s from %d'):format(this:get(), name, japi.GetStoredInteger(this.record, '', name), this.record))
		local value	= japi.GetStoredInteger(this.record, '', name) or 0
		if this	== player.self then
			if not record.my_record[name] then
				table.insert(record.my_record, name)
			end
			record.my_record[name]	= value
		end
		return value
	end

	function cmd.setRecord(p, name, value)
		p:setRecord(name, tonumber(value))

		if p == player.self then
			cmd.log('积分', ('%s --> %s'):format(name, tonumber(value)))
		end
	end

	function player.__index.setRecord(this, name, value)
		--print(('player[%d] save record: %s = %s'):format(this:get(), name, value))
		if this	== player.self then
			if not record.my_record[name] then
				table.insert(record.my_record, name)
			end
			record.my_record[name]	= value
		end
		return japi.StoreInteger(this.record, '', name, value)
	end

	function cmd.saveRecord(p)
		p:saveRecord()
	end

	record.local_save_name = ('[%s]的本地积分存档(全明星战役).txt'):format(player.self:getBaseName())
	record.local_save_name_old = ('[0x%08X]的本地积分存档(全明星战役).txt'):format(jass.StringHash(player.self:getBaseName()) + 2 ^ 31)

	function player.__index.saveRecord(this)
		if not record.enable_local_save then
			return false
		end
		if dump.enable and this == player.self and this:isPlayer() then
			local lines	= {}
			table.insert(lines, ('[%s]'):format(player.self:getBaseName()))
			for _, name in ipairs(record.my_record) do
				if record.my_record[name] ~= 0 then
					table.insert(lines, ('%s=%d'):format(name, record.my_record[name]))
				end
			end
			local content	= table.concat(lines, '\r\n')
			storm.save(
				cmd.dir_record .. record.local_save_name,
				('%s%s\r\n\r\n以下内容请勿编辑,否则会导致本地存档损坏\r\n\r\n#start#%s#end#'):format(string.char(0xEF, 0xBB, 0xBF), content, dump.save(this:getBaseName(), content))
			)

			cmd.log('积分', '保存本地积分')
		end

		cmd.log('积分', '保存在线积分')
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
		text = text:gsub('\xEF\xBB\xBF', '')
		for line in text:gmatch '(%C+)' do
			local name, value	= line:match '(.+)%=(%d+)'
			if name then
				table.insert(player.self.record_data, name)
				player.self.record_data[name] = tonumber(value)
			end
		end
	end
	
	function record.save_players()
		--读取本地积分
		local text	= storm.load(cmd.dir_record .. record.local_save_name)
			or storm.load(cmd.dir_record .. record.local_save_name_old) 
		local local_record	= table.new(0)
		if text and player.self:isPlayer() then
			--读取加密部分
			local content	= text:match '#start#(.+)#end#'
			if content then
				local result, content	= pcall(dump.load, player.self:getBaseName(), content)
				if result then
					for name, value in content:gmatch '(%C-)%=(%C+)' do
						table.insert(local_record, name)
						local_record[name]	= tonumber(value)
					end
					
					--对比2边的局数
					if local_record['局数'] > player.self:getRecord '局数' then
						--恢复积分
						for _, name in ipairs(local_record) do
							player.self:setRecord(name, local_record[name])
							print(('[恢复积分]:%s --> %s'):format(name, local_record[name]))
						end
						
						cmd.maid_chat '检测到您的在线积分异常,已从本地积分恢复'
						cmd.maid_chat '请注意备份魔兽目录下的本地积分存档文件'
						cmd.maid_chat '录像或单人模式请忽略该信息'
					end
				else
					cmd.maid_chat '积分文件解析出错'
					cmd.maid_chat '如果你改了文件,请删除文件'
					cmd.maid_chat '否则请截图并联系最萌小汐'
					player.self:display(content)
				end
			end
		end

		--读取本地大号信息
		local text	= storm.load(cmd.dir_account .. 'account.txt')
		if text then
			pcall(record.read_players, text)
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
		data[name] = math.max(data[name] or 0, player.self:getRecord '胜利' + math.floor(player.self:getRecord '时间' / 30))
		
		--生成新的本地记录
		local texts = {'\xEF\xBB\xBF'}
		for _, name in ipairs(data) do
			table.insert(texts, ('%s=%d'):format(name, data[name]))
		end
		--保存到本地
		record.account_info = table.concat(texts, '\n')
		--print(table.concat(texts, '\n'))
		--storm.save('ushio1.log', table.concat(texts, '\n'))

		--找到胜利最多的一个名字
		local name	= table.pick(data,
			function(name1, name2)
				return data[name1] > data[name2]
			end
		)

		--保存该名字
		record.saveName('mt', name, data[name])
		--print(name, player.self:getBaseName())

		--读取本地作弊标记
		local cheat_mark = tonumber(storm.load(cmd.path_cheat_mark)) or 0
		record.cheat_mark = math.max(cheat_mark, player.self:getRecord 'cht')
		player.self:setRecord('cht', record.cheat_mark)

		event('录像检测完毕',
			function()
				if game.is_replay ~= 'true' then
					record.enable_local_save = true
					storm.save(cmd.dir_account .. 'account.txt', record.account_info)
					storm.save(cmd.path_cheat_mark, record.cheat_mark)
				end
				player.self:saveRecord()
			end
		)

		--将胜利信息发送给其他玩家
		local sync_names	= '局数 胜利 时间 节操 mt0 mt1 mt2 mt3 mt4 V2 db flag cht'
		local t	= {}
		for name in sync_names:gmatch '(%S+)' do
			t[name]	= player.self:getRecord(name)
		end

		--t['id'] = player.self:get()
		
		--保存信使皮肤数据
		for _, data in ipairs(messenger) do
			local name	= data['信使']
			t[name] 	= player.self:getRecord(name)
		end
		
		--保存英雄皮肤数据
		for _, data in ipairs(hero_model) do
			local name	= data['皮肤']
			t[name]		= player.self:getRecord(name)
		end

		--record.enable_local_save	= true

		player.self:saveRecord()
		
		--同步数据
		for i = 1, 10 do
			local p = player[i]
			if p:isPlayer() then
				p:sync(
					t,
					function(data)
						local random	= jass.GetRandomInt(0, 99999999)
						--只有在录像模式中才会重载积分哦
						local function in_replay()
							for name, value in pairs(data) do
								p:setRecord(name, value)
							end

							event('积分同步完成', {player = p})
						end

						--游戏模式则对积分进行校验
						local function in_game()
							--如果是别人的积分,直接进行重载
							if player.self ~= p then
								in_replay()
								return
							end

							--自己的积分则仔细验证,不重载
							local texts	= {}
							for name, value in pairs(data) do
								local true_value	= t[name]
								if true_value ~= value then
									table.insert(texts, ('[%s]\t%d : %d'):format(name, true_value, value))
								end
							end
							--print('#texts = ' .. #texts)
							if #texts ~= 0 then
								local text	= table.concat(texts, '\n')
								cmd.maid_chat(player.self, text)
								cmd.maid_chat(player.self, '积分同步异常,请截图汇报')
								local file_name	= ('ASB_SyncError_%02d_%02d_%08s.txt'):format(player.self:get(), p:get(), random)
								print(file_name)
								storm.save(cmd.dir_errors .. file_name, text)
							end

							event('积分同步完成', {player = p})
						end

						if game.is_replay == 'unknow' then
							event('录像检测完毕',
								function(data, name, f)
									event('-录像检测完毕', f)
									if game.is_replay == 'true' then
										in_replay()
									else
										in_game()
									end
								end
							)
						else
							if game.is_replay == 'true' then
								in_replay()
							else
								in_game()
							end
						end
					end
				)
			end
		end
		
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
				['节操'] = 0,
				['收益'] = 1,
			}
			if player[i]:isPlayer() then
				if player[i]:getTeam() == team then
					my_team 	= my_team + 1
					lv1			= lv1 + player[i]:getRecord 'mt0'
				else
					enemy_team 	= enemy_team + 1
					lv2			= lv2 + player[i]:getRecord 'mt0'
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
		--print('main', name, value)
		if data[name] ~= data[player.self:getBaseName()] and value ~= 0 then
			is_main	= false
		end
		
		--对比双方战绩
		if lv1 < lv2 then
			local n = lv2 - lv1
			local x = 0
			if n <= 200 then
				x = x + n * 0.005
			else
				x = x + 200 * 0.005
				n = n - 200
				if n <= 500 then
					x = x + n * 0.002
				else
					x = x + 500 * 0.0002
					n = n - 500
					if n <= 1000 then
						x = x + n * 0.001
					else
						x = x + 1000 * 0.001
						--n = n - 1000
						--x = x + n * 0.001
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
					x = 0.75
				elseif n > 2000 then
					x = 0.80
				elseif n > 1000 then
					x = 0.85
				elseif n > 500 then
					x = 0.90
				elseif n > 200 then
					x = 0.95
				end
				if x ~= 1 then
					cmd.maid_chat(player.self, '主人呀,对面差你们太多了吧')
					cmd.maid_chat(player.self, ('本局的节操收益只有%d%%了哟'):format(100 * x))
					jc['收益'] = jc['收益'] * x
				end
			end
			
			--检查是不是小号
			if not is_main then
				if player.self:getRecord '局数' == 0 then
					cmd.maid_chat(player.self, '主人您居然开小号虐菜!')
					cmd.maid_chat(player.self, '主人您的大号是 [' .. name .. '] 没错吧~')
				else
					cmd.maid_chat(player.self, '主人您又在开小号虐菜了')
					cmd.maid_chat(player.self, '主人您的大号是 [' .. name .. '] 没错吧~')
					--jc['收益'] = jc['收益'] * 0.75
				end
			end
		end

		print('jc:' .. jc['收益'])
	end
	
	event('注册积分', record.save_players)

	timer.wait(30,
		function()
			record.init_jc()
		end
	)

	function cmd.new_version(p)
		--print(p:get())
		p.new_version	= p:isPlayer()
		event('玩家版本更新', {player = p})
	end

	function cmd.game_over(p, tid)
		local n 	= timer.time() / 60 --每分钟+1节操
		local jc 	= record.jc[p:get()]
		tid = tonumber(tid)
		print ('game_over', tid, p:getTeam(), tostring(tid == p:getTeam()))
		if tid == p:getTeam() then
			n = n + 50 --胜利+50节操
			n = math.floor(n * jc['收益'])
			--print(n)
			cmd.maid_chat(p, ('恭喜获胜,您本局收获了 %d 点节操哦~'):format(n))
		else
			n = n + 25 --失败+25节操
			n = math.floor(n * jc['收益'])
			--print(n)
			cmd.maid_chat(p, ('主人,您本局收获了 %d 点节操哦~'):format(n))
		end

		--检查节操奖励
		local buff	= p:getRecord 'db'
		local dn	= 0
		if buff > 0 then
			if buff > n then
				dn		= n
				buff	= buff - n
				cmd.maid_chat(p, ('主人,您额外获得了 %d 点节操奖励,剩余奖励 %d 点~'):format(dn, buff))
			else
				dn		= buff
				buff	= -1
				cmd.maid_chat(p, ('主人,您额外获得了 %d 点节操奖励,已经将奖励领完了哦'):format(dn))
			end
			p:setRecord('db', buff)
		end

		--检查特殊奖惩
		local x, y
		if tid == 0 then
			x, y = jass.udg_FS, jass.udg_FSDL
		else
			x, y = jass.udg_FSDL, jass.udg_FS
		end
		if x and y and y > 10 and x / y > 2 then
			--判定为碾压
			if jc['收益'] > 1 and player.self:getTeam() == tid then
				--local debuff	= math.ceil((jc['收益'] - 1) * 2 * n)
				--local n 		= n - debuff
				--cmd.maid_chat(p, ('主人,您受到了 %d 点节操的特殊惩罚,实际获得的节操为 %d 点'):format(debuff, n))
			elseif jc['收益'] < 1 and player.self:getTeam() ~= tid then
				local buff	= math.ceil((1 - jc['收益']) * 5 * n)
				local n		= n + buff
				cmd.maid_chat(p, ('主人,您获得了 %d 点节操的特殊奖励,实际获得的节操为 %d 点'):format(buff, n))
			end
		end
		
		jc['节操'] = jc['节操'] + n + p:getRecord '节操'
		p:setRecord('节操', jc['节操'])
	end

	--检测其他玩家的大号
	record.check_main_cost = 1000

	function player.__index.loadName(p, first)
		local value = p:getRecord(first .. 0)
		
		--将4个整数组装成名字
		local name	= _id(p:getRecord(first .. 1) + 2 ^ 31) .. _id(p:getRecord(first .. 2) + 2 ^ 31) .. _id(p:getRecord(first .. 3) + 2 ^ 31) .. _id(p:getRecord(first .. 4) + 2 ^ 31)
		--print(name)
		return name:match '(%Z+)', value
	end
	
	function cmd.check_main(p, u)
		if p ~= player.self then
			return
		end

		local op, id
		u	= tonumber(u)
		op	= jass.GetOwningPlayer(u)
		op	= player.j_player(op)
		id	= op:get()
		
		if not p.has_checked then
			p.has_checked = {}
		end
		
		if id < 1 or id > 10 then
			cmd.maid_chat(p, '主人,这家伙又不是玩家,怎么查得出大号呀')
			return
		end

		if id == p:get() then
			cmd.maid_chat(p, '主人,您没事查您自己干啥...')
			return
		end

		if p.has_checked[id] then
			local name, count = table.unpack(p.has_checked[id])
			if count == 0 or name == op:getBaseName() then
				cmd.maid_chat(p, ('主人, [%s] 并没有检测到大号哦'):format(op:getBaseName()))
			else
				cmd.maid_chat(p, ('主人, [%s] 的大号是 [%s] 哦,玩了 [%s] 局游戏'):format(op:getBaseName(), name, count))
			end
			return
		end

		if p:getRecord '节操' < record.check_main_cost then
			cmd.maid_chat(p, ('主人,您的节操不够哦,使用该功能需要 %s 节操,而您只有 %s 点!'):format(record.check_main_cost, p:getRecord '节操'))
			return
		end

		--开始检测
		local name, count = op:loadName 'mt'
		p.has_checked[id] = {name, count}
		
		if count == 0 or name == op:getBaseName() then
			p:setRecord('节操', p:getRecord '节操' - record.check_main_cost * 0.2)
			p:saveRecord()
			
			cmd.maid_chat(p, ('主人, [%s] 并没有检测到大号哦'):format(op:getBaseName()))
			cmd.maid_chat(p, ('扣了您 %d 点节操,剩余 %d 点!'):format(record.check_main_cost * 0.2, p:getRecord '节操'))
			return
		end

		p:setRecord('节操', p:getRecord '节操' - record.check_main_cost)
		p:saveRecord()

		cmd.maid_chat(p, ('主人, [%s] 的大号是 [%s] 哦,玩了 [%s] 局游戏'):format(op:getBaseName(), name, count))
		cmd.maid_chat(p, ('扣了您 %d 点节操,剩余 %d 点!'):format(record.check_main_cost, p:getRecord '节操'))
	end

	--作弊标记
	function cmd.cheat_mark(p, u)
		u = tonumber(u)
		local dest = player.j_player(jass.GetOwningPlayer(u))
		if not p.cheat_marks then
			p.cheat_marks = {}
		end
		
		if p.cheat_marks[dest:get()] then
			p:maid_chat '主人,您已经标记过该玩家了!'
			return
		end

		if p:getRecord '节操' < 1000 then
			p:maid_chat '主人,您的节操不够!'
			return
		end

		p:setRecord('节操', p:getRecord('节操') - 1000)
		p:saveRecord()

		p.cheat_marks[dest:get()] = true
		dest:setRecord('cht', dest:getRecord('cht') + 1)
		dest:saveRecord()
		
		if game.is_replay == 'false' then
			storm.save(cmd.path_cheat_mark, player.self:getRecord 'cht')
		end

		--if game.is_replay == 'true' then
			player.self:maid_chat(('[%s]的作弊标记为[%s](仅供参考)'):format(dest:getBaseName(), dest:getRecord 'cht'))
		--end
		
		p:maid_chat(('主人,您已成功标记[%s],剩余[%s]点节操'):format(dest:getBaseName(), p:getRecord '节操'))
	end