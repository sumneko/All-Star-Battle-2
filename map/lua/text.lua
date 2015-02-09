    text = {}
    
    local text = text
    text.skills = {} --技能表,以技能ID为索引
    
    --以1秒为周期进行循环检查
    timer.loop(1,
        function()
            local hero = game.self()
            if hero and jass.GetUnitTypeId(hero) ~= 0 then
                for i = 0, 99 do
                    local ab = japi.EXGetUnitAbilityByIndex(hero, i)
                    if not ab then break end --如果技能不存在就结束
                    text.setAbText(ab)
                end
            end
            for i = 1, #game.heroes do
                local hero = game.heroes[i]
                jass.UnitAddAbility(hero, ('Amgl'):toid())
                jass.UnitRemoveAbility(hero, ('Amgl'):toid())
            end
        end
    )
    
    --设置技能文本
    text.setAbText = function(ab)
        local id = japi.EXGetAbilityId(ab) --获取该技能的ID
        local texts = text.skills[id]
        local selfhero = game.self()
        if texts == nil then
            --如果该技能不在技能表中,则进行判定
            if text.newAbText(ab, id) then
				texts = text.skills[id]
			else
                return
            end
        elseif texts == false then
            --该技能无需动态文本,直接跳过
            return
        end
        --对文本进行动态修改
        local lv = jass.GetUnitAbilityLevel(selfhero, id)
        local nums = {}
        local t = texts[lv] --该等级的数据
        if not t then
	        return
        end
        for i = 1 , 10 do
            local func = t[i * 2 - 1]
            if not func then
                break
            end
            local num = t[i * 2]
            table.insert(nums, func(selfhero, true) * num)
        end
        local te = string.format(t.text, unpack(nums))
        japi.EXSetAbilityDataString(ab, lv, 218, te)
        japi.EXSetAbilityDataString(ab, 1, 217, texts.research)
    end
    
    --判定技能文本
    text.newAbText = function(ab, id)
        --获取该技能文本
        local texts = {}
        local flag = false
        for i = 1, 10 do
            local te = japi.EXGetAbilityDataString(ab, i, 218) --技能说明文本
			if te ~= nil and te ~= "" then
				local t = text.newText(te)
				if t then
					texts[i] = t
					flag = true
				end
				texts.maxlv = i
			else
				break
			end
        end
        if not flag then
            --该技能无需动态文本,进行标记
            text.skills[id] = false
            return false
        end
		texts.research = japi.EXGetAbilityDataString(ab, 1, 217) --技能学习文本
        text.skills[id] = texts
        return true --该技能需要动态文本
    end
    
    --判定文本
    text.newText = function(te)
        local start = 1
        local t = {}
        local flag
		te = string.gsub(te, "%%", "%%%%") --以免文本中本来包含的%符号被当做匹配符
        while start do
            start = string.find(te, "×", start)
            if start then
                local word = string.sub(te, start - 6, start - 1)
                local func
                if word == "力量" then
                    func = jass.GetHeroStr
                elseif word == "敏捷" then
                    func = jass.GetHeroAgi
                elseif word == "智力" then
                    func = jass.GetHeroInt
                end
				if func then
					local s, e = string.find(te, "[%d.]+", start + 2)
					if s then
						local num = string.sub(te, s, e)
                        if te:sub(s - 9, s - 9) == '+' then
                            te = string.sub(te, 1, s - 10) .. "(+%d)" .. string.sub(te, e + 1, -1)
                        else
                            te = string.sub(te, 1, s - 9) .. "%d" .. string.sub(te, e + 1, -1)
                        end
						table.insert(t, func)
						table.insert(t, num)
						flag = true
					end
				end
				start = start + 1
            end
        end
        if flag then
            t.text = te
            return t
        end
    end
