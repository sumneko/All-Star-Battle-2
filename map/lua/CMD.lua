	cmd = {}

	--´æ´¢ÒÑ¾­»ã±¨¹ıµÄ´íÎó
	cmd.errors = {}

	--ÖØÔØprint
	cmd.print = print

	cmd.text_print = {}
	
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
	    if p == player.self then
		    jass.SetPlayerName(jass.Player(12), '|cffff88cc' .. cmd.getMaidName(true) .. '|r')
	        japi.EXDisplayChat(jass.Player(12), 3, '|cffff88cc' .. s .. '|r')
	    end
    end

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

	--¼ÇÂ¼°æ±¾ºÅ
	function cmd.set_ver_name(_, s)
		cmd.ver_name = s
	end