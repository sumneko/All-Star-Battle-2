    game = {}
    
    local game = game

    game.debug = jass.s__sys_Debug
    
    game.heroes = {}
    game.trg_hero_spell	= jass.CreateTrigger()
    game.trg_hero_skill	= jass.CreateTrigger()
    
    function game.initHero(u)
        table.insert(game.heroes, u)
        
        if jass.GetOwningPlayer(u) == jass.GetLocalPlayer() then
            game.selfHero = u
        end

        local p = player.j_player(jass.GetOwningPlayer(u))
        p.hero	= u

        event('注册英雄', {hero = u, player = p})
        jass.TriggerRegisterUnitEvent(game.trg_hero_spell, u, jass.EVENT_UNIT_SPELL_EFFECT)
        jass.TriggerRegisterUnitEvent(game.trg_hero_skill, u, jass.EVENT_UNIT_HERO_SKILL)
    end

    jass.TriggerAddCondition(game.trg_hero_spell, jass.Condition(
    	function()
	    	event('英雄发动技能', {from = jass.GetTriggerUnit(), to = jass.GetSpellTargetUnit(), skill = jass.GetSpellAbilityId()})
    	end
    ))

    jass.TriggerAddCondition(game.trg_hero_skill, jass.Condition(
    	function()
	    	event('英雄学习技能', {from = jass.GetTriggerUnit(), skill = jass.GetLearnedSkill()})
    	end
    ))

   	game.trg_unit_spell = jass.CreateTrigger()
	for i = 1, 12 do
		jass.TriggerRegisterPlayerUnitEvent(game.trg_unit_spell, player[i].handle, jass.EVENT_PLAYER_UNIT_SPELL_EFFECT, nil)
	end
	jass.TriggerAddCondition(game.trg_unit_spell, jass.Condition(
    	function()
	    	event('单位发动技能', {from = jass.GetTriggerUnit(), to = jass.GetSpellTargetUnit(), skill = jass.GetSpellAbilityId(), player = player.j_player(jass.GetTriggerPlayer())})
    	end
    ))

    game.trg_unit_death	= jass.CreateTrigger()
    for i = 1, 12 do
		jass.TriggerRegisterPlayerUnitEvent(game.trg_unit_death, player[i].handle, jass.EVENT_PLAYER_UNIT_DEATH, nil)
	end
	jass.TriggerAddCondition(game.trg_unit_death, jass.Condition(
    	function()
	    	event('单位死亡', {from = jass.GetKillingUnit(), to = jass.GetSpellTargetUnit(), player = player.j_player(jass.GetTriggerPlayer())})
    	end
    ))
    
    function game.self()
        return game.selfHero
    end
    
    function hook.UnitWakeUp(u, f)
        game.initHero(u)
    end
    
    function hook.SetUnitRescueRange(u, r, f)
        if jass.GetUnitTypeId(u) == 0 then
            if r + 0 == 23333 then
		        cmd.start()
	        end
            return
        end
        if r < 0 then
            game[math.floor(0 - r)](u)
        else
            return f(u, r)
        end
    end
    
    --一方通行-重力移动冷却2秒
    game[1] = function(u)
        local ab = japi.EXGetUnitAbility(u, |A0II|)
        local lv = jass.GetUnitAbilityLevel(u, |A0II|)
        japi.EXSetAbilityDataReal(ab, lv, 105, 2)
        japi.EXSetAbilityState(ab, 1, 2)
        japi.EXSetAbilityDataReal(ab, lv, 105, 0)
    end
    
    --一方通行-重力移动冷却1秒
    game[2] = function(u)
        local ab = japi.EXGetUnitAbility(u, |A0II|)
        local lv = jass.GetUnitAbilityLevel(u, |A0II|)
        japi.EXSetAbilityDataReal(ab, lv, 105, 1)
        japi.EXSetAbilityState(ab, 1, 1)
        japi.EXSetAbilityDataReal(ab, lv, 105, 0)
    end
    
    --三笠阿克曼-技能耗蓝增加50%(废弃)
    game.table_3 = {}
    game.table_4 = {
        [|A0PX|] = true,
        [|A0PZ|] = true,
        [|A0Q0|] = true,
        [|A0Q1|] = true,
    }
    
    game[3] = function(u)
        local data = {}
        local t = timer.loop(0.1, true,
            function()
                for i = 0, 99 do
                    local ab = japi.EXGetUnitAbilityByIndex(u, i)
                    if ab == 0 then
                        return
                    end
                    local id = japi.EXGetAbilityId(ab)
                    local lv = jass.GetUnitAbilityLevel(u, id)
                    local mp = japi.EXGetAbilityDataInteger(ab, lv, 104)
                    if mp > 0 and game.table_4[id] then
                        if data[id] then
                            mp = mp - (data[id][lv] or 0)
                        end
                        data[id] = {}
                        data[id][lv] = math.floor(mp * 0.5)
                        mp = mp + data[id][lv]
                        japi.EXSetAbilityDataInteger(ab, lv, 104, mp)
                    end
                end
            end
        )
        game.table_3[u] = {t, data}
    end
    
    game[4] = function(u)
        if not game.table_3[u] then
            return
        end
        local t = game.table_3[u][1]
        local data = game.table_3[u][2]
        t:destroy()
        for i = 0, 99 do
            local ab = japi.EXGetUnitAbilityByIndex(u, i)
            if ab == 0 then
                return
            end
            local id = japi.EXGetAbilityId(ab)
            local lv = jass.GetUnitAbilityLevel(u, id)
            local mp = japi.EXGetAbilityDataInteger(ab, lv, 104)
            if mp > 0 and game.table_4[id] then
                if data[id] then
                    mp = mp - (data[id][lv] or 0)
                end
                japi.EXSetAbilityDataInteger(ab, lv, 104, mp)
            end
        end
    end
    
    --连杀后死亡
    game[5] = function(u)
        local name = jass.GetPlayerName(jass.Player(12))
        local p = jass.GetOwningPlayer(u)
    
        jass.SetPlayerName(jass.Player(12), '阎魔爱')
        if p == jass.GetLocalPlayer() then
            japi.EXDisplayChat(jass.Player(12), 3, '|cff505050充满罪恶的灵魂、想死一遍看看吗？|r')
        end
        
        jass.SetPlayerName(jass.Player(12), name)
    end
    
    --克劳德暴击触发
    game.table_6 = setmetatable({}, {__index = function() return 0 end})
    game.table_7 = setmetatable({}, {__index = function() return 0 end})
    
    game[6] = function(u)
        game.table_6[u] = game.table_6[u] + 1
    end
    
    game[7] = function(u)
        game.table_7[u] = game.table_7[u] + 1
        if game.table_7[u] % 10 == 0 then
            jass.SetPlayerName(jass.Player(12), '|cffff88cc' .. cmd.getMaidName(true) .. '|r')
            if jass.GetOwningPlayer(u) == jass.GetLocalPlayer() then
                japi.EXDisplayChat(jass.Player(12), 3, ('|cffff88cc主人,从您学习了[一刀两断]后一共攻击了%d次,其中暴击了%d次|r'):format(game.table_6[u], game.table_7[u]))
                local s = game.table_7[u] / game.table_6[u] * 100
                local w
                if s > 33 then
                    w = '赶紧去买彩票吧!'
                elseif s > 25 then
                    w = 'RP真不错啊!'
                elseif s < 15 then
                    w = '建议洗把脸再回来玩?'
                else
                    w = '加油加油~'
                end
                japi.EXDisplayChat(jass.Player(12), 3, ('|cffff88cc综合暴击率为%.2f%%,%s|r'):format(s, w))
            end
        end
    end
    
	--技能japi
	function cmd.japi_ability(p, sync, u, sid, func_name, ...)
		if sync == 'true' or player.self == p then
			local args	= {...}
			for i = 1, #args do
				args[i]	= tonumber(args[i]) or args[i]
			end

			local ability	= japi.EXGetUnitAbility(tonumber(u), string2id(sid))
			japi[func_name](ability, table.unpack(args))
		end
	end