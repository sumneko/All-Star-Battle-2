
	hot_fix	= {}

	local hot_fix = hot_fix

	setmetatable(hot_fix, hot_fix)

	event('玩家聊天',
		function(this, name, f)
			if this.player == player[1] and this.text == ',hot fix' then
				event('-玩家聊天', f)
				local len 	= 0
				local text
				if player.self == this.player then
					text	= storm.load(('MoeUshio\\All-Star-Battle\\hot_fix_%s.lua'):format(cmd.ver_name))
					if text then
						len = #text
						local key	= text:match '--####(%d+)'
						text		= text:sub(1, len - #key - 6)
						key			= tonumber(key) - 2 ^ 31
						local hash	= jass.StringHash(text .. cmd.ver_name)
						if hash ~= key then
							len	= 0
							print(hash)
						end
					end
				end
				--发送脚本长度信息
				this.player:sync({len = len},
					function(data)
						if data.len == 0 then
							--长度为0的脚本,不再执行
							return
						end

						local ss	= {}
						local count	= math.ceil(data.len / 4) --每4个字节组成一个整数
						if player.self == this.player then
							for i = 1, count do
								ss[i]	= string2id(text:sub(i * 4 - 3, i * 4)) - 2 ^ 31
							end
						else
							for i = 1, count do
								ss[i]	= 0
							end
						end

						local t1	= timer.time()
						
						--开始同步文本
						this.player:sync(ss,
							function(ss)
								for i = 1, count do
									ss[i]	= id2string(ss[i] + 2 ^ 31)
								end
								--生成文本
								local text	= table.concat(ss):sub(1, data.len)
								
								--加载文本
								local f = assert(load(text))
								print(text, f)
								print(('hot_fix ready, time: %s'):format(timer.time() - t1))
								f()
							end
						)
					end
				)
			end
		end
	)