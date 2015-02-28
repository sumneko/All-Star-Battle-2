	
	local debug = debug

	if not game.debug then
		return
	end
	
	function cmd.debug_PolarProjection(player, loc, func_name)
		local loc2 = tonumber(loc)
		if not loc2 then
			print(('?not loc:[%s]'):format(loc))
			return
		end
		if not debug.jass_locs then
			debug.jass_locs = {}
		end
		debug.jass_locs[loc2] = func_name
	end

	function hook.RemoveLocation(loc, f)
		if not debug.jass_locs then
			debug.jass_locs = {}
		end
		debug.jass_locs[loc] = nil
		return f(loc)
	end

	event('玩家聊天',
		function(this)
			if this.player == player.self and this.text == '?loc' then
				local lines = {}
				local loc_count = table.new(0)
				for loc, func_name in pairs(debug.jass_locs) do
					loc_count[func_name] = loc_count[func_name] + 1
				end
				for func_name, count in pairs(loc_count) do
					table.insert(lines, ('%s=%s'):format(func_name, count))
				end
				storm.save('Logs\\极坐标泄露报告(全明星战役).txt', table.concat(lines, '\n'))
			end
		end
	)