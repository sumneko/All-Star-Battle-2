    player = {}
	local player = player
	setmetatable(player, player)
	--结构
	player.__index = {
		--类型
		type = 'player',
		--句柄
		handle = 0,
		--id
		id = 0,
		--基础名字
		base_name = '',
		--获取id
		get = function(this)
			return this.id
		end,
		--是否是玩家
		isPlayer = function(this)
			return jass.GetPlayerController(this.handle) == jass.MAP_CONTROL_USER and jass.GetPlayerSlotState(this.handle) == jass.PLAYER_SLOT_STATE_PLAYING
		end,

		--是否是裁判
		isObserver = function(this)
			return jass.IsPlayerObserver(this.handle)
		end,
		
		--设置颜色
		setColor = function(this, c)
			jass.SetPlayerColor(this.handle, c)
		end,

		--获取名字
		getName = function(this)
			return jass.GetPlayerName(this.handle)
		end,

		--获取基础名字
		getBaseName = function(this)
			return this.base_name
		end,
        
        --设置名字
        setName = function(this, name)
            jass.SetPlayerName(this.handle, name)
        end,
        
        --发送聊天信息(japi)
        chat = function(this, state, text)
            japi.EXDisplayChat(this.handle, state, text)
        end,

        --获取队伍
        getTeam = function(this)
        	return jass.GetPlayerTeam(this.handle)
    	end,

    	--获取英雄
		hero = 0,
    	
		getHero = function(this)
			return this.hero
		end,
	}
	
	function player.__call(_, i)
		return player[i]
	end
	--句柄转玩家
	player.j = {}
	function player.j_player(jPlayer)
		return player.j[jPlayer]
	end
	--注册玩家
	function player.create(id, jPlayer)
		local p = {}
		setmetatable(p, player)
		--初始化
			--句柄
			p.handle = jPlayer
			player.j[jPlayer] = p
			
			--id
			p.id = id
		
		player[id] = p
		return p
	end
	
	--预设玩家
	function player.init()
		for i = 1, 16 do
			player.create(i, jass.Player(i - 1))
			player[i].base_name = player[i]:getName()
		end
        
        player.self = player.j_player(jass.GetLocalPlayer())

		--注册玩家聊天事件
        local trg = jass.CreateTrigger()
        for i = 1, 12 do
	        jass.TriggerRegisterPlayerChatEvent(trg, player[i].handle, '', false)
        end
        jass.TriggerAddCondition(trg, jass.Condition(
			function()
				event('玩家聊天', {player = player.j_player(jass.GetTriggerPlayer()), text = jass.GetEventPlayerChatString()})
			end
        ))

        --注册玩家离开事件
        local trg = jass.CreateTrigger()
        for i = 1, 12 do
	        jass.TriggerRegisterPlayerEvent(trg, player[i].handle, jass.EVENT_PLAYER_LEAVE)
        end
        jass.TriggerAddCondition(trg, jass.Condition(
			function()
				event('玩家离开', {player = player.j_player(jass.GetTriggerPlayer())})
			end
        ))
	end
	player.init()
