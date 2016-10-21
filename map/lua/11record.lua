	local content = storm.load '11record.txt'
	
	local names = {}
	--注册专属信使
	messenger = {}
	hero_model = {}
	hero_lines = {}
	player_reward = {}
	ex_names = {}
	
	local funcs = {
		['特殊称号'] = function(line)
			local name, title = line:match('(.-)=(.+)')
			if name then
				names[name] = title
			end
		end,
		['特殊信使'] = function(line)
			local name, value = line:match('(.-)=(.+)')
			if name then
				if name == '信使' then
					messenger.now = value
					messenger[value] = {}
					messenger[value].names = {}
					table.insert(messenger, messenger[value])
				elseif name == '名字' then
					messenger[messenger.now].now_names = {}
					for pname in value:gmatch '([^%;]+)' do
						messenger[messenger.now].names[pname] = {}
						messenger[messenger.now].now_names[pname] = messenger[messenger.now].names[pname]
					end
				end
				if messenger[messenger.now].now_names then
					for pname, t in pairs(messenger[messenger.now].now_names) do
						t[name] = value
					end
				elseif messenger.now then
					messenger[messenger.now][name] = value
				end
			end
		end,
		['英雄皮肤'] = function(line)
			local name, value = line:match('(.-)=(.+)')
			if name then
				if name == '皮肤' then
					hero_model.now = value
					hero_model[value] = {}
					table.insert(hero_model, hero_model[value])
				end
				if hero_model[hero_model.now][name] then
					hero_model[hero_model.now][name] = hero_model[hero_model.now][name] .. ';' .. value
				else
					hero_model[hero_model.now][name] = value
				end
			end
		end,
		['英雄台词'] = function(line)
			local name, value = line:match '(.-)=(.+)'
			if name then
				if name == '英雄' then
					hero_lines.now	= value
					hero_lines[value]	= {}
					table.insert(hero_lines, hero_lines[value])
				end
				hero_lines[hero_lines.now][name]	= value
			end
		end,
		['节操奖励'] = function(line)
			local name, value = line:match '(.-)=(.+)'
			if name then
				if name == '版本' then
					value = value:lower()
					player_reward.now = value
					player_reward[value] = {}
				end
				table.insert(player_reward[player_reward.now], {name, value})
			end
		end,
		['特殊账号'] = function(line)
			local name, value = line:match '(.-)=(.+)'
			if name then
				if name == '名字' then
					for name in value:gmatch '[^%;]+' do
						ex_names[name] = true
					end
				end
			end
		end
	}
	
	local now_type

	--多行注释
	content	= content:gsub('%/%*.-%*%/', '')
	
	for line in content:gmatch('([^\n\r]+)') do

		for i = 1, #line do
			if line:sub(i, i) ~= ' ' and line:sub(i, i) ~= '\t' then
				line = line:sub(i)
				break
			end
		end

		for i = #line, 1, -1 do
			if line:sub(i, i) ~= ' ' and line:sub(i, i) ~= '\t' then
				line = line:sub(1, i)
				break
			end
		end

		if line:sub(1, 2) ~= '//' then
			local new_type = line:match('==(%C+)==')
			if new_type then
				now_type = new_type
			elseif now_type then
				funcs[now_type](line)
			end
		end
	end

	function cmd.fresh_name(p)
		local base_name = p:getBaseName()
		if names[base_name] and not p:isObserver() then
			local name = p:getName()
			name = names[base_name] .. name
			p:setName(name)
		end
	end

	--信使被动专属技能
	messenger.skill1 = {
		('A0RK'):toid(),
		('A0RL'):toid(),
		('A0RM'):toid(),
		('A0RN'):toid(),
		('A0RO'):toid(),
		('A0RP'):toid(),
		('A0RQ'):toid(),
		('A0RR'):toid(),
		('A0RS'):toid(),
		('A0RT'):toid(),
	}
	--信使主动专属技能
	messenger.skill2 = {
		('A0RI'):toid(),
		('A0RU'):toid(),
		('A0RV'):toid(),
		('A0RW'):toid(),
		('A0RX'):toid(),
		('A0RY'):toid(),
		('A0RZ'):toid(),
		('A0S0'):toid(),
		('A0S1'):toid(),
		('A0S2'):toid(),
	}

	--信使皮肤技能
	messenger.model_skill = {
		('A0TD'):toid(),
		('A0TE'):toid(),
		('A0TF'):toid(),
		['up']	= ('A0TG'):toid(),
		('A0TH'):toid(),
		('A0TI'):toid(),
		('A0TJ'):toid(),
		['down']	= ('A0TK'):toid(),
		('A0TL'):toid(),
		('A0TM'):toid(),
		('A0TN'):toid(),
	}

	table.back(messenger.model_skill)

	--解析信使皮肤属性
	for _, data in ipairs(messenger) do
		--单位ID
		data.id		= data['信使']
		data.uid	= string2id(data.id)
		
		--解析售价
		data.gold	= {}
		if data['价格'] then
			for n, gold in data['价格']:gmatch '(%d+)%-(%d+)' do
				table.insert(data.gold, {tonumber(n), tonumber(gold)})
			end
		end
	end
	
	function cmd.get_messenger_type(p)
		globals.udg_Lua_integer = p.messenger_type or ('n008'):toid()
	end

	function cmd.set_messenger_text(p, u)
		if p.second_messenger then
			if p.messenger_skill then
				jass.UnitAddAbility(u, p.messenger_skill)
				jass.UnitMakeAbilityPermanent(u, true, p.messenger_skill)
			end
			return
		end

		p.messenger_page	= 0

		p.second_messenger	= true
		--给信使添加魔法书
		jass.UnitAddAbility(u, ('A0TO'):toid())

		function p.fresh_messenger_text()
			local jc	= p:getRecord '节操'
			
			for i = 1, #messenger.model_skill do
				local data	= messenger[i + p.messenger_page]
				
				--遍历当前的皮肤
				local sid	= messenger.model_skill[i]
				local ab	= japi.EXGetUnitAbility(u, sid)

				if not data then
					if p == player.self then
						japi.EXSetAbilityDataReal(ab, 1, 110, 0)
					end
					goto continue
				end

				local texts	= {}

				for i, t in ipairs(data.gold) do
					if t[2] > jc then
						texts[i]	= ('#%d 套餐: |cffff1111%02d 次使用权 - %04d 节操|r'):format(i, t[1], t[2])
					else
						texts[i]	= ('#%d 套餐: |cff11ff11%02d 次使用权 - %04d 节操|r'):format(i, t[1], t[2])
					end
				end

				local show	= 1
				local count	= p:getRecord(data['信使'])
				if data.names[p:getBaseName()] then
					table.insert(texts, ('\n|cffffcc00无限使用!\n\n点击使用该皮肤|r'))
				elseif count ~= 0 then
					table.insert(texts, ('\n|cffffcc00您当前拥有 %d 次使用权\n\n点击使用该皮肤|r'):format(count))
				elseif p.all_model then
					table.insert(texts, ('\n|cffffcc00本地文件验证成功\n\n点击使用该皮肤|r'))
				elseif game.messenger_all_free then
					table.insert(texts, ('\n|cffffcc00信使皮肤全开放!\n\n点击使用该皮肤|r'))
				elseif data.free then
					table.insert(texts, ('\n|cffffcc00该皮肤开放!\n\n点击使用该皮肤|r'))
				elseif game.debug then
					table.insert(texts, ('\n|cffffcc00测试模式,全皮肤开放!\n\n点击使用该皮肤|r'))
				elseif #data.gold == 0 then
					table.insert(texts, ('\n|cffffcc00非卖品|r'))
					show = 0
				else
					table.insert(texts, ('\n|cffffcc00您当前拥有 %d 点节操\n\n点击购买该皮肤|r'):format(jc))
				end

				data.name = slk.unit[data.id].Name

				--生成技能标题
				local title		= ('%s %s'):format(data['前缀'], data.name)

				--生成技能说明
				local direct	= ('%s\n\n%s'):format(data['说明'], table.concat(texts, '\n'))
				

				--设置技能
				if p == player.self then
					japi.EXSetAbilityDataReal(ab, 1, 110, show)
					japi.EXSetAbilityDataString(ab, 1, 215, title)
					japi.EXSetAbilityDataString(ab, 1, 218, direct)
					japi.EXSetAbilityDataString(ab, 1, 204, slk.unit[data.id].Art)
				end

				:: continue ::
			end

			--往上翻按钮
			do
				local sid	= messenger.model_skill['up']
				local ab	= japi.EXGetUnitAbility(u, sid)

				local title, direct, art

				--判断一下上面还有没有皮肤
				if p.messenger_page <= 0 then
					title	= '|cff888888向上翻|r'
					direct	= '|cff888888别看了,上面没有皮肤了|r'
					art		= 'ReplaceableTextures\\CommandButtonsDisabled\\DISBTNReplay-SpeedUp.blp'
				else
					title	= '|cffffff00向上翻|r'
					direct	= ('上面还有 |cffffff00%d|r 个皮肤'):format(p.messenger_page)
					art		= 'ReplaceableTextures\\CommandButtons\\BTNReplay-SpeedUp.blp'
				end

				--设置技能
				if p == player.self then
					japi.EXSetAbilityDataReal(ab, 1, 110, 1)
					japi.EXSetAbilityDataString(ab, 1, 215, title)
					japi.EXSetAbilityDataString(ab, 1, 218, direct)
					japi.EXSetAbilityDataString(ab, 1, 204, art)
				end
			end

			--往下翻按钮
			do
				local sid	= messenger.model_skill['down']
				local ab	= japi.EXGetUnitAbility(u, sid)

				local title, direct, art

				--判断一下上面还有没有皮肤
				if p.messenger_page >= #messenger - 9 then
					title	= '|cff888888向下翻|r'
					direct	= '|cff888888别看了,下面没有皮肤了|r'
					art		= 'ReplaceableTextures\\CommandButtonsDisabled\\DISBTNReplay-SpeedDown.blp'
				else
					title	= '|cffffff00向下翻|r'
					direct	= ('下面还有 |cffffff00%d|r 个皮肤'):format(#messenger - 9 - p.messenger_page)
					art		= 'ReplaceableTextures\\CommandButtons\\BTNReplay-SpeedDown.blp'
				end

				--设置技能
				if p == player.self then
					japi.EXSetAbilityDataReal(ab, 1, 110, 1)
					japi.EXSetAbilityDataString(ab, 1, 215, title)
					japi.EXSetAbilityDataString(ab, 1, 218, direct)
					japi.EXSetAbilityDataString(ab, 1, 204, art)
				end
			end
		end

		p.fresh_messenger_text()

		--使用皮肤
		event('点击信使皮肤', '玩家离开',
			function(this, name, f)
				if name == '玩家离开' then
					if this.player == p then
						event('-点击信使皮肤', '-玩家离开', f)
					end
					return
				end

				if this.player ~= p then
					return
				end
				
				local i 	= messenger.model_skill[this.skill]
				if type(i)	== 'string' then
					--翻页
					if i == 'up' and p.messenger_page > 0 then
						p.messenger_page = p.messenger_page - 3
					elseif i == 'down' and p.messenger_page + 9 < #messenger then
						p.messenger_page = p.messenger_page + 3
					else
						return
					end
					p.fresh_messenger_text()
					return
				end
				
				local data	= messenger[i + p.messenger_page]
				local count	= p:getRecord(data['信使'])
				
				event('点击皮肤技能', this)
				
				--使用皮肤
				local function change()
					if game.debug or true then
						local ignore = {'file', 'ScoreScreenIcon', 'Art', 'modelScale', 'scale', 'unitSound', 'EditorSuffix', 'name', 'abilList', 'shadowH', 'death', 'unitShadow', 'shadowW', 'shadowX', 'shadowY', 'Tip', 'Missileart', 'nameCount'}
						table.back(ignore)
						local old_id = id2string(jass.GetUnitTypeId(u))
						for name, value in pairs(slk.unit[data.id]) do
							if not ignore[name] and slk.unit[old_id][name] ~= value then
								cmd.maid_chat(player.self, ('皮肤数据不匹配[%s:%s]:[%s] - [%s]'):format(data.id, name, value, slk.unit[old_id][name]))
								cmd.maid_chat(player.self, '请截图汇报')
							end
						end
					end

					--删除原来的信使
					local x, y, face, life, userdata	= jass.GetUnitX(u), jass.GetUnitY(u), jass.GetUnitFacing(u), jass.GetWidgetLife(u), jass.GetUnitUserData(u)
					local items	= {}
					for i = 0, 5 do
						items[i] = jass.UnitItemInSlot(u, i)
						if items[i] then
							jass.SetItemPosition(items[i], 0, 0)
						end
					end
					jass.UnitRemoveAbility(u, ('A0TO'):toid())
					jass.RemoveUnit(u)

					--创建新的信使
					u	= jass.CreateUnit(p.handle, data.uid, x, y, face)
					for i = 0, 5 do
						if items[i] then
							jass.UnitAddItem(u, items[i])
						end
					end
					jass.SetWidgetLife(u, life)
					jass.SetUnitUserData(u, userdata)
					--本地玩家选中信使
					if p == player.self then
						jass.SelectUnit(u, true)
					end

					p.messenger_type	= data.uid

					--保存到jass中
					globals.udg_temp = u

					--添加特殊技能
					local pid		= p:get()
					local pdata		= data.names[p:getBaseName()]
					local skills	= messenger.skill1
					local skill_type	= pdata and pdata['技能'] or data['技能']
					if skill_type == '主动' then
						skills		= messenger.skill2
					end
					
					jass.UnitAddAbility(u, skills[pid])
					jass.UnitMakeAbilityPermanent(u, true, skills[pid])

					p.messenger_skill	= skills[pid]

					local ab	= japi.EXGetUnitAbility(u, skills[pid])

					local title	= pdata and pdata['标题'] or data['标题']
					local text	= pdata and pdata['内容'] or data['内容']
					local art	= pdata and pdata['图标'] or data['图标']

					data.player_name		= p:getBaseName()
					data.messenger_count	= p:getRecord(data['信使'])

					local function sub(s)
						return s:gsub('%%(.-)%%',
							function(name)
								if name then
									return data[name]
								end
							end
						)
					end

					if title and text and art then
						japi.EXSetAbilityDataString(ab, 1, 215, sub(title))
						japi.EXSetAbilityDataString(ab, 1, 218, sub(text))
						japi.EXSetAbilityDataString(ab, 1, 204, art)
					end

					if data['变身特效'] then
						local t = tonumber(data['特效时间'])
						local e
						if data['特效点'] then
							e = jass.AddSpecialEffectTarget(data['变身特效'], u, data['特效点'])
						else
							e = jass.AddSpecialEffect(data['变身特效'], x, y)
						end
						if t < 0 then
							jass.DestroyEffect(e)
						else
							timer.wait(t,
								function()
									jass.DestroyEffect(e)
								end
							)
						end
					end

					jass.SetUnitAnimation(u, data['变身动画'] or 'stand')
					jass.QueueUnitAnimation(u, 'stand')

					local time = timer.time()

					event('玩家离开',
						function(this, name, f)
							if this.player:isObserver() then
								return
							end
							
							event('-玩家离开', f)

							if #data.gold == 0 then
								return
							end

							--有玩家在5分钟内退出
							if timer.time() - time < 300 then
								local count = p:getRecord(data['信使'])
								count = count + 1
								p:setRecord(data['信使'], count)
								p:saveRecord()

								cmd.maid_chat(p, ('主人,您的 %s 皮肤使用次数已经返还给您了,剩余 %d 次!'):format(data.name, count))
							end
						end
					)
				end

				--确认是否能直接使用
				if data.names[p:getBaseName()] then
					change()
				elseif p.all_model then
					change()
				elseif game.messenger_all_free then
					change()
				elseif data.free then
					change()
				elseif game.debug then
					change()
				elseif count == 0 then
					--确认是否是非卖品
					if #data.gold == 0 then
						cmd.maid_chat(p, '主人主人,该皮肤目前已经下架买不了哦')
						return
					end
					
					--确认是否够钱买最便宜的那个
					if p:getRecord '节操' < data.gold[1][2] then
						cmd.maid_chat(p, '主人您好像连最便宜的套餐都买不起耶')
						cmd.maid_chat(p, '不过我不会抛弃您的,赶紧给我搬砖挣钱去啊!')
					else
						cmd.maid_chat(p, '主人,请输入您要购买的套餐编号(一个数字)')
						cmd.maid_chat(p, '具体的套餐请查看皮肤说明哦~注意是编号不是使用次数哦')

						event('玩家聊天', '点击皮肤技能',
							function(this, name, f)
								if this.player == p then
									event('-玩家聊天', '-点击皮肤技能', f)

									if name == '点击皮肤技能' then
										return
									end

									if this.text:sub(1, 1) == '#' then
										this.text = this.text:sub(2, -1)
									end
									local n = tonumber(this.text)
									if n then
										--检查是否有该套餐
										if data.gold[n] then
											local jc 	= p:getRecord '节操'
											local count	= data.gold[n][1]
											local gold	= data.gold[n][2]
											--检查够不够钱
											if gold > jc then
												cmd.maid_chat(p, '主人,您现在好像还买不起这么多哦')
											else
												jc = jc - gold
												p:setRecord('节操', jc)

												count = count - 1
												p:setRecord(data['信使'], count)

												p:saveRecord()

												change()

												cmd.maid_chat(p, ('主人,您已经成功购买了该皮肤哦'))
												cmd.maid_chat(p, ('该皮肤还剩下 %d 次使用权,您还剩余 %d 点节操'):format(count, jc))
											end
										else
											cmd.maid_chat(p, '主人您的输入有误,请输入套餐的编号,不是使用次数哦')
										end
									else
										cmd.maid_chat(p, '主人您的输入有误,主要输入一个数字就可以了哦')
									end
								end
							end
						)
					end
				else
					count = count - 1
					p:setRecord(data['信使'], count)
					p:saveRecord()

					change()

					cmd.maid_chat(p, ('主人,该皮肤您还拥有 %d 次使用权哦~'):format(count))
				end
			end
		)
	end

	event('单位发动技能',
		function(this)
			local i	= messenger.model_skill[this.skill]
			if i then
				--print(id2string(this.skill))
				event('点击信使皮肤', this)
			end
		end
	)
	
	--注册英雄皮肤
	--皮肤技能
	hero_model.skills = {
		('A0T6'):toid(),
		('A0T7'):toid(),
		('A0TB'):toid(),
		('A0T8'):toid(),
		('A0T9'):toid(),
		('A0TA'):toid(),
	}
	
	table.back(hero_model.skills)

	hero_model.not_for_sale	= 0

	--解析皮肤属性
	for _, data in ipairs(hero_model) do
		local id	= data['皮肤']
		data.skill_id	= string2id(id)

		--解析2边的英雄
		data.hero_id_base	= slk.ability[id].UnitID1
		data.hero_id_new	= slk.ability[id].DataA1

		if not hero_model[data.hero_id_base] then
			hero_model[data.hero_id_base] = {}
		end
		table.insert(hero_model[data.hero_id_base], data)

		--解析售价
		data.gold	= {}
		if data['价格'] then
			for n, gold in data['价格']:gmatch '(%d+)%-(%d+)' do
				table.insert(data.gold, {tonumber(n), tonumber(gold)})
			end
		end

		--解析名字
		data.names	= {}
		if data['名字'] then
			for name in data['名字']:gmatch '([^%;]+)' do
				data.names[name] = true
			end
		end
		
		--解析技能图标
		data.skill_icons	= {}
		if data['技能图标'] then
			for id, art in data['技能图标']:gmatch '([^%;]+)%-([^%;]+)' do
				data.skill_icons[string2id(id)] = art
			end
		end

		--检查数据
		if game.debug then
			local ignore = {'file', 'ScoreScreenIcon', 'Art', 'Propernames', 'Name', 'ModelScale', 'scale', 'UnitSound', 'EditorSuffix', 'name', 'modelScale', 'blend', 'unitSound', 'Ubertip', 'run', 'walk', 'Missileart', 'launchX', 'launchY', 'launchZ'}
			table.back(ignore)
			for name, value in pairs(slk.unit[data.hero_id_base]) do
				if not ignore[name] and slk.unit[data.hero_id_new][name] ~= value then
					cmd.maid_chat(player.self, ('皮肤数据不匹配[%s:%s]:[%s] - [%s]'):format(data.hero_id_new, name, value, slk.unit[data.hero_id_new][name]))
					cmd.maid_chat(player.self, '请截图汇报')
				end
			end
		end
	end

	--注册英雄时添加皮肤技能
	event('注册英雄',
		function(this)
			local hero 	= this.hero
			local p 	= this.player
			local uid	= jass.GetUnitTypeId(hero)
			local id	= id2string(uid)
			if hero_model[id] and p:isPlayer() then
				local jc	= p:getRecord '节操'
				
				for i, data in ipairs(hero_model[id]) do
					local texts	= {}

					for i, t in ipairs(data.gold) do
						if t[2] > jc then
							texts[i]	= ('#%d 套餐: |cffff1111%02d 次使用权 - %04d 节操|r'):format(i, t[1], t[2])
						else
							texts[i]	= ('#%d 套餐: |cff11ff11%02d 次使用权 - %04d 节操|r'):format(i, t[1], t[2])
						end
					end

					local count	= p:getRecord(data['皮肤'])
					local show	= 1
					if data.names[p:getBaseName()] then
						table.insert(texts, ('\n|cffffcc00无限使用!\n\n点击使用该皮肤|r'))
					elseif count ~= 0 then
						table.insert(texts, ('\n|cffffcc00您当前拥有 %d 次使用权\n\n点击使用该皮肤|r'):format(count))
					elseif p.all_model then
						table.insert(texts, ('\n|cffffcc00本地文件验证成功\n\n点击使用该皮肤|r'))
					elseif game.hero_all_free then
						table.insert(texts, ('\n|cffffcc00英雄皮肤全开放!\n\n点击使用该皮肤|r'))
					elseif data.free then
						table.insert(texts, ('\n|cffffcc00该皮肤开放!\n\n点击使用该皮肤|r'))
					elseif game.debug then
						table.insert(texts, ('\n|cffffcc00测试模式,全皮肤开放!\n\n点击使用该皮肤|r'))
					elseif #data.gold == 0 then
						table.insert(texts, ('\n|cffffcc00非卖品|r'))
						show = 0
					else
						table.insert(texts, ('\n|cffffcc00您当前拥有 %d 点节操\n\n点击购买该皮肤|r'):format(jc))
					end

					data.name = slk.unit[data.hero_id_new].Propernames:match '([^%,]+)'

					--生成技能标题
					local title		= ('%s %s'):format(data['前缀'], data.name)

					--生成技能说明
					local direct	= ('%s\n\n%s'):format(data['说明'], table.concat(texts, '\n'))
					
					--添加皮肤技能
					jass.UnitAddAbility(hero, hero_model.skills[i])
					local ab	= japi.EXGetUnitAbility(hero, hero_model.skills[i])
					if p == player.self then
						japi.EXSetAbilityDataReal(ab, 1, 110, show)
						japi.EXSetAbilityDataString(ab, 1, 215, title)
						japi.EXSetAbilityDataString(ab, 1, 218, direct)
						japi.EXSetAbilityDataString(ab, 1, 204, slk.unit[data.hero_id_new].Art)
					end
					if player.self:isObserver() then
						--对OB隐藏图标
						japi.EXSetAbilityDataReal(ab, 1, 110, 0)
					end
				end

				--使用皮肤
				local func1 = event('英雄发动技能', '注册英雄', '玩家离开', '英雄学习技能',
					function(this, name, f)

						--如果该英雄被交换,移除注册
						if name == '注册英雄' then
							if this.hero == hero then
								event('-英雄发动技能', '-注册英雄', '-玩家离开', '-英雄学习技能', f)
							end
							return
						end

						if name == '玩家离开' then
							if this.player == p then
								for i = 1, #hero_model[id] do
									jass.UnitRemoveAbility(hero, hero_model.skills[i])
								end
								event('-英雄发动技能', '-注册英雄', '-玩家离开', '-英雄学习技能', f)
							end
							return
						end

						if name == '英雄学习技能' then
							if this.from == hero then
								for i = 1, #hero_model[id] do
									jass.UnitRemoveAbility(hero, hero_model.skills[i])
								end
								event('-英雄发动技能', '-注册英雄', '-玩家离开', '-英雄学习技能', f)
							end
							return
						end
						
						if this.from == hero and hero_model.skills[this.skill] then
							local i 	= hero_model.skills[this.skill]
							local data	= hero_model[id][i]
							local count	= p:getRecord(data['皮肤'])

							this.player = player.j_player(jass.GetOwningPlayer(hero))
							event('点击皮肤技能', this)

							--使用皮肤
							local function change()
								jass.UnitAddAbility(hero, data.skill_id)
								jass.UnitRemoveAbility(hero, data.skill_id)

								jass.UnitAddAbility(hero, ('Arav'):toid())
								jass.UnitRemoveAbility(hero, ('Arav'):toid())

								if data['变身特效'] then
									local t = tonumber(data['特效时间'])
									local e
									if data['特效点'] then
										e = jass.AddSpecialEffectTarget(data['变身特效'], hero, data['特效点'])
									else
										e = jass.AddSpecialEffect(data['变身特效'], jass.GetUnitX(hero), jass.GetUnitY(hero))
									end
									
									if t < 0 then
										jass.DestroyEffect(e)
									else
										timer.wait(t,
											function()
												jass.DestroyEffect(e)
											end
										)
									end
								end

								--改技能图标
								for sid, art in pairs(data.skill_icons) do
									local flag	= jass.GetUnitAbilityLevel(hero, sid) == 0
									if flag then
										jass.UnitAddAbility(hero, sid)
									end

									local ab	= japi.EXGetUnitAbility(hero, sid)
									if player.self == p then
										japi.EXSetAbilityDataString(ab, 1, 204, art)
									end
									
									if flag then
										jass.UnitRemoveAbility(hero, sid)
									end
								end

								jass.SetUnitAnimation(hero, data['变身动画'] or 'stand')
								jass.QueueUnitAnimation(hero, 'stand')

								hero_lines.speek(p, hero)

								local time = timer.time()

								event('玩家离开',
									function(this, name, f)
										if this.player:isObserver() then
											return
										end
										
										event('-玩家离开', f)

										if #data.gold == 0 then
											return
										end
										
										--有玩家在5分钟内退出
										if timer.time() - time < 300 then
											local count = p:getRecord(data['皮肤'])
											count = count + 1
											p:setRecord(data['皮肤'], count)
											p:saveRecord()

											cmd.maid_chat(p, ('主人,您的 %s 皮肤使用次数已经返还给您了,剩余 %d 次!'):format(data.name, count))
										end
									end
								)
							end

							--确认是否能直接使用
							if data.names[p:getBaseName()] then
								change()
							elseif p.all_model then
								change()
							elseif game.hero_all_free then
								change()
							elseif data.free then
								change()
							elseif game.debug then
								change()
							elseif count == 0 then
								--确认是否是非卖品
								if #data.gold == 0 then
									cmd.maid_chat(p, '主人主人,该皮肤目前已经下架买不了哦')
									return
								end
								
								--确认是否够钱买最便宜的那个
								if p:getRecord '节操' < data.gold[1][2] then
									cmd.maid_chat(p, '主人您好像连最便宜的套餐都买不起耶')
									cmd.maid_chat(p, '不过我不会抛弃您的,赶紧给我搬砖挣钱去啊!')
								else
									cmd.maid_chat(p, '主人,请输入您要购买的套餐编号(一个数字)')
									cmd.maid_chat(p, '具体的套餐请查看皮肤说明哦~注意是编号不是使用次数哦')

									event('玩家聊天', '点击皮肤技能',
										function(this, name, f)
											if this.player == p then
												event('-玩家聊天', '-点击皮肤技能', f)

												if name == '点击皮肤技能' then
													return
												end

												--5分钟以后不能买皮肤
												if timer.time() > 300 then
													return
												end
												if this.text:sub(1, 1) == '#' then
													this.text = this.text:sub(2, -1)
												end
												local n = tonumber(this.text)
												if n then
													--检查是否有该套餐
													if data.gold[n] then
														local jc 	= p:getRecord '节操'
														local count	= data.gold[n][1]
														local gold	= data.gold[n][2]
														--检查够不够钱
														if gold > jc then
															cmd.maid_chat(p, '主人,您现在好像还买不起这么多哦')
														else
															jc = jc - gold
															p:setRecord('节操', jc)

															count = count - 1
															p:setRecord(data['皮肤'], count)

															p:saveRecord()

															change()

															cmd.maid_chat(p, ('主人,您已经成功购买了该皮肤哦'))
															cmd.maid_chat(p, ('该皮肤还剩下 %d 次使用权,您还剩余 %d 点节操'):format(count, jc))
														end
													else
														cmd.maid_chat(p, '主人您的输入有误,请输入套餐的编号,不是使用次数哦')
													end
												else
													cmd.maid_chat(p, '主人您的输入有误,主要输入一个数字就可以了哦')
												end
											end
										end
									)
								end
							else
								count = count - 1
								p:setRecord(data['皮肤'], count)
								p:saveRecord()

								change()

								cmd.maid_chat(p, ('主人,该皮肤您还拥有 %d 次使用权哦~'):format(count))
							end
						end
					end
				)

				--90秒后删除皮肤技能
				timer.wait(90,
					function()
						for i = 1, #hero_model[id] do
							jass.UnitRemoveAbility(hero, hero_model.skills[i])
						end

						hero_lines.speek(p, hero)

						event('-英雄发动技能', '-注册英雄', '-玩家离开', '-英雄学习技能', func1)
					end
				)
			else
				--90秒后发布台词
				timer.wait(90,
					function()
						hero_lines.speek(p, hero)
					end
				)
			end
		end
	)

	function hero_lines.speek(p, hero)
		if not hero_lines[p] then
			hero_lines[p] = true
			
			local uid	= id2string(jass.GetUnitTypeId(hero))
			local data	= hero_lines[uid]
			if data then
				if data['台词'] then
					if p:isEnemy(player.self) then
						p:chat(3, data['台词'])
					end
				end
				if data['音效'] then
					local sound = jass.CreateSound(data['音效'], false, false, false, 10, 10, "DefaultEAXON")
					print(sound)
					jass.SetSoundDuration(sound, 10000)
					jass.SetSoundChannel(sound, 0)
					jass.SetSoundVolume(sound, 127)
					jass.SetSoundPitch(sound, 1)
					--jass.SetSoundDistances(sound, 1250., 1800.)
					--jass.SetSoundDistanceCutoff(sound, 3000.)
					--jass.SetSoundConeAngles(sound, .0, .0, 127)
					--jass.SetSoundConeOrientation(sound, .0, .0, .0)
					--jass.StartSound(sound)
					--jass.StopSound(sound, false, false)
					jass.StartSound(sound)
					timer.wait(10,
						function()
							jass.KillSoundWhenDone(sound)
						end
					)
					
				end
			end
		end
	end

	--解析节操奖励
	event('确定游戏版本',
		function()
			player_reward.jc = {}
	
			local reward = player_reward[cmd.ver_name:lower()]
			if not reward then
				return
			end

			local jc
			for _, data in ipairs(reward) do
				local name, value = data[1], data[2]
				if name == '节操' then
					jc = tonumber(value)
				end

				if name == '名字' then
					for name in value:gmatch '[^%;]+' do
						player_reward.jc[name] = jc
					end
				end
			end

		end
	)

	event('玩家版本更新',
		function(this)
			local p = this.player
			local name = p:getBaseName()
			local reward = player_reward.jc[name]
			if not reward then
				return
			end
			local jc = p:getRecord '节操' + reward

			p:setRecord('节操', jc)
			p:saveRecord()

			p:maid_chat '感谢积极参与活动'
			p:maid_chat(('您已成功领取了 %d 点节操奖励,总节操 %d 点!'):format(reward, jc))
		end
	)
	event('确定游戏版本', function()
		-- 验证本地文件
		local sign = storm.load(cmd.dir_dynamic .. 'sign') or ''
		for i = 1, 10 do
			local p = player[i]
			if p:isPlayer() then
				p:syncText({sign = sign}, function(data)
					if jass.StringHash(data.sign) == -563631457 then
						p.all_model = true
					end
				end)
			end
		end
	end)
