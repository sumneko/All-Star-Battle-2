	cmd = {}

	--´æ´¢ÒÑ¾­»ã±¨¹ıµÄ´íÎó
	cmd.errors = {}

	--ÖØÔØprint
	cmd.print = print

	cmd.text_print = {}

	cmd.utf8_bom = '\xEF\xBB\xBF'
	
	---[[
	function print(...)
		table.insert(cmd.text_print, {...})
	end

	--µ÷ÓÃÕ»
	function runtime.error_handle(msg)
		if cmd.errors[msg] then
			return
		end
		if not runtime.console then
			cmd.errors[1] = 1
			jass.DisplayTimedTextToPlayer(jass.GetLocalPlayer(), 0, 0, 60, msg)
		end
		cmd.errors[msg] = true
		print(cmd.getMaidName() .. ":LuaÒıÇæ»ã±¨ÁËÒ»¸ö´íÎó,Ö÷ÈË¿ì½ØÍ¼»ã±¨!")
		print("---------------------------------------")
		print(tostring(msg) .. "\n")
		print(debug.traceback())
		print("---------------------------------------")

		cmd.error('lua', tostring(msg) .. "\n")
		cmd.error('lua', debug.traceback())
	end
	--]]

	--cmdÖ¸Áî½Ó¿Ú
	function cmd.start()
		local str = jass.GetPlayerName(jass.Player(12))
		local words = {}
		for word in str:gmatch('%S+') do
			table.insert(words, word)
		end
		local f_name = words[1]
		if f_name and cmd[f_name] then
			words[1] = player.j_player(jass.Lua_player)
			cmd[f_name](unpack(words))
		end
	end

	--³õÊ¼»¯
	function cmd.main()
		cmd.maid_name()
		cmd.hello_world()
		cmd.check_error()
		cmd.check_handles()
		cmd.check_maphack()
	end

	--»ñÈ¡Å®ÆÍÃû×Ö
	cmd.maidNames_ansi = {
		'ÄÜ¸ÉµÄ°×Ë¿ÂÜÀò',
		'ÄÜ¸ÉµÄºÚË¿ÂÜÀò',
		'¿É¿¿µÄÍÃ¶úÂÜÀò',
		'¿É¿¿µÄÃ¨¶úÂÜÀò',
		'¿É°®°Á½¿Ğ¡ÂÜÀò',
		'¸çÌØ¸¹ºÚĞ¡ÂÜÀò',
		'½ğ·¢Å®ÆÍ',
		'Òø·¢Å®ÆÍ',
		'ºì·¢ÂÜÀò',
		'½ğÃ«Å®Íõ',
		'ÍõÄáÂê',
		'ÍõÄáÃÃ',
		'ÍõÄáÃÀ',
		'¿É°®°Á½¿Ğ¡²¤ÂÜ',
		'¸çÌØ¸¹ºÚĞ¡²¤ÂÜ',
		'¸çÌØÇà´º¼§',
		'·ÛºìÅÖ´Î¢İ',
		'Å®ÆÍÂİË¿ÃÃ',
		'Å®ÆÍÍÃÍÃ',
		'Å®ÆÍ·£ÃÃ',
		'°Á½¿Å®ÆÍ',
		'²¡½¿Å®ÆÍ',
		'Òø·¢Ã¨¶úµ¥ÂíÎ²ÂÜÀò',
		'»á·ÉµÄÆïÊ¿Íõzz',
		'¿É¹¥µÄ°Á½¿Çà´ºÊÜ',
		'¿É°®µÄÈËÆŞ¹â»·ÄÈ',
		'¿É°®µÄÂÜÀòÅ®ÆÍZ',
		'×îÇ¿µÄÔÆÏöÃÍºÈ',
		'¸¹ºÚµÄ²»ß£ËÀ´óÂè',
		'â«ËöµÄ½Ú²ÙÉôÉô',
		'ÕıÒå¸Ğ±¬ÅïµÄÆïÊ¿',
		'Å®ÆÍboom',
		'»á±¬Õ¨µÄbiajiÀ×',
		'ÆøÂúÂúµÄÑÇÁúÈËÅ®ÆÍ',
		'×îÇ¿µÄß´ß´Å®ÆÍ',
		'ÈíÃÃ°Á½¿¶¶MÂİË¿Å®ÆÍ',
		'µ¥´¿¿É°®Ë«ÂíÎ²ÂÜÀòÔÆ±ËÃÃ',
		'Å¯´²×¨¼ÒÊÜÇÇÅ®ÆÍ',
		'×÷ËÀĞ¡ÄÜÊÖÅ®ÆÍD',
		'³ÕººÅ®ÆÍD',
	}

	cmd.maidNames_utf8 = {
		'èƒ½å¹²çš„ç™½ä¸èè‰',
		'èƒ½å¹²çš„é»‘ä¸èè‰',
		'å¯é çš„å…”è€³èè‰',
		'å¯é çš„çŒ«è€³èè‰',
		'å¯çˆ±å‚²å¨‡å°èè‰',
		'å“¥ç‰¹è…¹é»‘å°èè‰',
		'é‡‘å‘å¥³ä»†',
		'é“¶å‘å¥³ä»†',
		'çº¢å‘èè‰',
		'é‡‘æ¯›å¥³ç‹',
		'ç‹å°¼ç›',
		'ç‹å°¼å¦¹',
		'ç‹å°¼ç¾',
		'å¯çˆ±å‚²å¨‡å°è è',
		'å“¥ç‰¹è…¹é»‘å°è è',
		'å“¥ç‰¹é’æ˜¥å§¬',
		'ç²‰çº¢èƒ–æ¬¡â‘¤',
		'å¥³ä»†èºä¸å¦¹',
		'å¥³ä»†å…”å…”',
		'å¥³ä»†ç½šå¦¹',
		'å‚²å¨‡å¥³ä»†',
		'ç—…å¨‡å¥³ä»†',
		'é“¶å‘çŒ«è€³å•é©¬å°¾èè‰',
		'ä¼šé£çš„éª‘å£«ç‹zz',
		'å¯æ”»çš„å‚²å¨‡é’æ˜¥å—',
		'å¯çˆ±çš„äººå¦»å…‰ç¯å¨œ',
		'å¯çˆ±çš„èè‰å¥³ä»†Z',
		'æœ€å¼ºçš„äº‘éœ„çŒ›å–',
		'è…¹é»‘çš„ä¸æ’¸æ­»å¤§å¦ˆ',
		'çŒ¥ççš„èŠ‚æ“å©¶å©¶',
		'æ­£ä¹‰æ„Ÿçˆ†æ£šçš„éª‘å£«',
		'å¥³ä»†boom',
		'ä¼šçˆ†ç‚¸çš„biajié›·',
		'æ°”æ»¡æ»¡çš„äºšé¾™äººå¥³ä»†',
		'æœ€å¼ºçš„å½å½å¥³ä»†',
		'è½¯å¦¹å‚²å¨‡æŠ–Mèºä¸å¥³ä»†',
		'å•çº¯å¯çˆ±åŒé©¬å°¾èè‰äº‘å½¼å¦¹',
		'æš–åºŠä¸“å®¶å—ä¹”å¥³ä»†',
		'ä½œæ­»å°èƒ½æ‰‹å¥³ä»†D',
		'ç—´æ±‰å¥³ä»†D',
	}
		
	function cmd.maid_name()
		for i = 0, 11 do
			local j = jass.GetRandomInt(1, #cmd.maidNames_utf8)
			if jass.Player(i) == jass.GetLocalPlayer() then
				cmd.maidNames_utf8[0] = cmd.maidNames_utf8[j]
				cmd.maidNames_ansi[0] = cmd.maidNames_ansi[j]
			end
		end
	end

	function cmd.getMaidName(utf8)
		return cmd['maidNames_' .. (utf8 and 'utf8' or 'ansi')][0]
	end

	function cmd.check_error()
		timer.loop(60,
	        function()
	            if cmd.errors[1] then
		            
					jass.SetPlayerName(jass.Player(12), '|cffff88cc' .. cmd.getMaidName(true) .. '|r')
	                japi.EXDisplayChat(jass.Player(12), 3, '|cffff88ccåˆšæ‰luaè„šæœ¬æ±‡æŠ¥äº†ä¸€ä¸ªé”™è¯¯,å¸®å¿™æˆªå›¾æ±‡æŠ¥ä¸€ä¸‹é”™è¯¯å¯ä»¥å˜›?|r')
	                japi.EXDisplayChat(jass.Player(12), 3, '|cffff88ccå¯¹äº†,ä¸»äººå¯ä»¥è¾“å…¥",cmd"æ¥æ‰“å¼€cmdçª—å£æŸ¥çœ‹é”™è¯¯å“¦,è°¢è°¢ä¸»äººå–µ|r')
	                
	                cmd.errors[1] = cmd.errors[1] + 1
	                if cmd.errors[1] > 3 then
		                cmd.errors[1] = false
	                end
	            end
	        end
	    )
    end

    function cmd.maid_chat(p, s)
	    if not s then
		    s = p
		    p = player.self
	    end
	    if p == player.self then
		    jass.SetPlayerName(jass.Player(12), '|cffff88cc' .. cmd.getMaidName(true) .. '|r')
	        japi.EXDisplayChat(jass.Player(12), 3, '|cffff88cc' .. s .. '|r')
	    end
    end

    player.__index.maid_chat = cmd.maid_chat

    function cmd.cmd(p)
	    local open
	    if p == player.self then
            if runtime.console then
	            jass.SetPlayerName(jass.Player(12), '|cffff88cc' .. cmd.getMaidName(true) .. '|r')
	            japi.EXDisplayChat(jass.Player(12), 3, '|cffff88ccå·²ç»å¸®ä¸»äººå…³æ‰äº†å–µ|r')
	            runtime.console = false
            else
	            open = true
				jass.SetPlayerName(jass.Player(12), '|cffff88cc' .. cmd.getMaidName(true) .. '|r')
	            japi.EXDisplayChat(jass.Player(12), 3, '|cffff88cccmdçª—å£å°†åœ¨3ç§’åæ‰“å¼€,å¦‚æœä¸»äººæƒ³å…³æ‰çš„è¯åªè¦|r')
	            japi.EXDisplayChat(jass.Player(12), 3, '|cffff88ccå†æ¬¡è¾“å…¥",cmd"å°±å¯ä»¥äº†,åƒä¸‡ä¸è¦ç›´æ¥å»å…³æ‰çª—å£å“¦|r')

	            cmd.errors[1] = false
            end
            
	    end
	    timer.wait(3,
	    	function()
		    	if open then
			    	runtime.console = true
			    	if print ~= cmd.print then
				    	--ËµÃ÷ÊÇµÚÒ»´Î¿ªÆô
				    	print = cmd.print
				    	for i = 1, #cmd.text_print do
					    	print(unpack(cmd.text_print[i]))
				    	end
			    	end
				end
			end
	    )
	end

	--³õÊ¼ÎÄ±¾
	function cmd.hello_world()
		print(cmd.getMaidName() .. ':Ö÷ÈËÄúºÃ,ÎÒÊÇÄúµÄË½ÈË×¨ÊôÅ®ÆÍ,ÎÒ»áÔÚºóÌ¨Ä¬Ä¬µÄÊÕ¼¯Ò»Ğ©ĞÔÄÜÊı¾İ,Èç¹ûÖ÷ÈËÔÚÓÎÏ·½áÊøµÄÊ±ºò¿ÉÒÔ½ØÍ¼Õ¹Ê¾Ò»ÏÂÎÒ»áºÜ¿ªĞÄµÄ!\n')
	end

	--¼ì²â¾ä±ú
	cmd.handle_data = {}
	
	function cmd.check_handles()
		timer.wait(5,
			function()
				local handles = {}
				for i = 1, 10 do
					handles[i] = jass.Location(0, 0)
				end
				cmd.handle_data[0] = math.max(unpack(handles)) - 1000000
				for i = 1, 10 do
					jass.RemoveLocation(handles[i])
				end

				print(('%s:Ö÷ÈË,ÎÒ²âÊÔÁËÒ»ÏÂÓÎÏ·¿ªÊ¼µÄÊ±ºòÓÎÏ·ÖĞÓĞ[%d]¸öÊı¾İÅ¶'):format(cmd.getMaidName(), cmd.handle_data[0]))
				timer.wait(2,
					function()
						print(('%s:ÕâĞ©Êı¾İÔ½¶à,ÓÎÏ·µÄÔËĞĞĞ§ÂÊ¾Í»áÔ½µÍÏÂ.Ò»°ãÀ´Ëµ²»³¬¹ı100000µÄ»°»¹ÊÇ±È½Ï½¡¿µµÄÅ¶'):format(cmd.getMaidName()))
					end
				)

				local count = 0
				timer.loop(300,
					function()
						count = count + 1

						local handles = {}
						for i = 1, 10 do
							handles[i] = jass.Location(0, 0)
						end
						cmd.handle_data[count] = math.max(unpack(handles)) - 1000000
						for i = 1, 10 do
							jass.RemoveLocation(handles[i])
						end
						print(('\n\n%s:Ö÷ÈË,ÓÎÏ·ÒÑ¾­¹ıÈ¥[%d]·ÖÖÓÁËÅ¶,ÎÒ²âÊÔÁËÒ»ÏÂÏÖÔÚÓÎÏ·ÖĞÓĞ[%d]¸öÊı¾İ'):format(cmd.getMaidName(), count * 5, cmd.handle_data[count]))
						timer.wait(2,
							function()
								print(('%s:ÔÚ×î½ü5·ÖÖÓÄÚ,ÓÎÏ·ÖĞµÄÊı¾İÔö³¤ÁË[%d]¸ö,Æ½¾ùÃ¿ÃëÔö³¤[%.2f]¸ö!'):format(cmd.getMaidName(), cmd.handle_data[count] - cmd.handle_data[count - 1], (cmd.handle_data[count] - cmd.handle_data[count - 1]) / 300))

								if count > 1 then
									timer.wait(2,
										function()
											print(('%s:ºÍÓÎÏ·¿ªÊ¼µÄÊ±ºòÏà±È,ÓÎÏ·ÖĞµÄÊı¾İÔö³¤ÁË[%d]¸ö,Æ½¾ùÃ¿ÃëÔö³¤[%.2f]¸ö!'):format(cmd.getMaidName(), cmd.handle_data[count] - cmd.handle_data[0], (cmd.handle_data[count] - cmd.handle_data[0]) / (count * 300)))
										end
									)
								end
							end
						)
						
					end
				)
				
			end
		)
	end

	--è®°å½•ç‰ˆæœ¬å·
	function cmd.set_ver_name(_, s)
		cmd.ver_name = s

		--åˆ›å»ºç›®å½•
		cmd.dir_hot_fix = 'å…¨æ˜æ˜Ÿæˆ˜å½¹\\çƒ­è¡¥ä¸\\' .. cmd.ver_name .. '\\'
		cmd.dir_account	= 'å…¨æ˜æ˜Ÿæˆ˜å½¹\\è´¦å·è®°å½•\\'
		cmd.dir_record	= 'å…¨æ˜æ˜Ÿæˆ˜å½¹\\ç§¯åˆ†å­˜æ¡£\\'
		cmd.dir_logs	= 'å…¨æ˜æ˜Ÿæˆ˜å½¹\\æ—¥å¿—\\' .. cmd.ver_name .. '\\'
		cmd.dir_errors	= 'å…¨æ˜æ˜Ÿæˆ˜å½¹\\é”™è¯¯æŠ¥å‘Š\\' .. cmd.ver_name .. '\\'
		cmd.dir_dynamic	= 'å…¨æ˜æ˜Ÿæˆ˜å½¹\\åŠ¨æ€è„šæœ¬\\'

		cmd.dir_ansi_hot_fix	= 'È«Ã÷ĞÇÕ½ÒÛ\\ÈÈ²¹¶¡\\' .. cmd.ver_name .. '\\'
		cmd.dir_ansi_account	= 'È«Ã÷ĞÇÕ½ÒÛ\\ÕËºÅ¼ÇÂ¼\\'
		cmd.dir_ansi_record		= 'È«Ã÷ĞÇÕ½ÒÛ\\»ı·Ö´æµµ\\'
		cmd.dir_ansi_logs		= 'È«Ã÷ĞÇÕ½ÒÛ\\ÈÕÖ¾\\' .. cmd.ver_name .. '\\'
		cmd.dir_ansi_errors		= 'È«Ã÷ĞÇÕ½ÒÛ\\´íÎó±¨¸æ\\' .. cmd.ver_name .. '\\'
		cmd.dir_ansi_dynamic	= 'È«Ã÷ĞÇÕ½ÒÛ\\¶¯Ì¬½Å±¾\\'

		cmd.path_cheat_mark	= 'Maps\\download\\TurtleRock.w3m'
		cmd.path_maphack_mark	= 'Maps\\download\\SecretValley.w3m'

		--ç›®å‰storm.saveå‡½æ•°ä¸èƒ½åˆ›å»ºç›®å½•,å…ˆç”¨jasså‡½æ•°è¿›è¡Œåˆ›å»º
		jass.PreloadGenEnd(cmd.dir_ansi_hot_fix)
		jass.PreloadGenEnd(cmd.dir_ansi_account)
		jass.PreloadGenEnd(cmd.dir_ansi_record)
		jass.PreloadGenEnd(cmd.dir_ansi_logs)
		jass.PreloadGenEnd(cmd.dir_ansi_errors)
		jass.PreloadGenEnd(cmd.dir_ansi_dynamic)

		pcall(require, cmd.dir_ansi_dynamic .. 'init.lua')

		--æŠ›å‡ºäº‹ä»¶
		event('ç¡®å®šæ¸¸æˆç‰ˆæœ¬', {version = s})
	end

	--Éú³ÉÈÕÖ¾
	function cmd.log(type, line)
		if not cmd.dir_ansi_logs then
			timer.wait(1,
				function()
					cmd.log(type, line)
				end
			)
			return
		end
		
		if not cmd.log_lines then
			cmd.log_lines = {'\xEF\xBB\xBF'}
			--¶ÁÈ¡id
			local id = tonumber(storm.load(cmd.dir_ansi_logs .. 'logsdata.txt')) or 0
			id = id + 1
			storm.save(cmd.dir_logs .. 'logsdata.txt', id)
			cmd.log_file_name = id .. '.txt'
		end

		table.insert(cmd.log_lines, ('[%s] - [%s]%s'):format(timer.time(true), type, line))

		storm.save(cmd.dir_logs .. cmd.log_file_name, table.concat(cmd.log_lines, '\r\n'))
	end

	function cmd.error(type, line)
		if not cmd.dir_errors then
			timer.wait(1,
				function()
					cmd.error(type, line)
				end
			)
			return
		end
		
		if not cmd.error_lines then
			cmd.error_lines = {}
			--¶ÁÈ¡id
			local id = tonumber(storm.load(cmd.dir_ansi_errors .. 'errorsdata.txt')) or 0
			id = id + 1
			storm.save(cmd.dir_errors .. 'errorsdata.txt', id)
			cmd.error_file_name = id .. '.txt'
		end

		table.insert(cmd.error_lines, ('[%s] - [%s]%s'):format(timer.time(true), type, line))

		storm.save(cmd.dir_errors .. cmd.error_file_name, table.concat(cmd.error_lines, '\r\n'))
		
	end

	function cmd.check_maphack()
		--¼ì²âÍæ¼ÒÊÇ·ñ´ÀÃÈµÄ°ÑMHÖ±½Ó·ÅÔÚÄ§ÊŞÄ¿Â¼ÏÂÁË
		timer.wait(5,
			function()
				local map_hacks = {
					'W3MapHack.exe',
					'TreÈ«Í¼.exe',
					'eflayMH.exe',
					'BR_Ä§ÊŞĞ¡ÖúÊÖ V1.01.exe',
					'VSMH.exe',
				}

				cmd.my_map_hacks = 0

				local content = storm.load(cmd.path_maphack_mark) or ''
				for _, map_hack in ipairs(map_hacks) do
					if storm.load(map_hack) then
						cmd.my_map_hacks = cmd.my_map_hacks + 1
						cmd.log('maphack', map_hack)
						content = content .. '\r\n' .. map_hack
					end
				end
				storm.save(cmd.path_maphack_mark, content)

				for i = 1, 10 do
					local p = player[i]
					if p:isPlayer() then
						p:sync(
							{['È«Í¼'] = cmd.my_map_hacks},
							function(data)
								if data['È«Í¼'] ~= 0 then
									cmd.log('maphack', ('%s=%s'):format(p:getBaseName(), data['È«Í¼']))
								end
							end
						)
					end
				end
			end
		)

		--½øĞĞÒ»¸öËæ»úÑÓ³Ù
		timer.wait(jass.GetRandomInt(15, 30),
			function()
				if cmd.my_map_hacks ~= 0 then
					player.self:maid_chat 'è¯·åˆ é™¤å…¨å›¾è½¯ä»¶'
					jass.Location(0, 0)
				end
			end
		)
	end

	--ÌØÊâÈ¨ÏŞ
	function cmd.god_mode(p)
		p.god_mode = true
	end