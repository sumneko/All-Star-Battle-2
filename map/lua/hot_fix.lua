
	hot_fix	= {}

	local hot_fix = hot_fix

	setmetatable(hot_fix, hot_fix)

	-- 新的热补丁流程如下
	-- 每个玩家查询自己的热补丁版本号并同步
	-- 找到版本号最大的那个玩家,将整个热补丁文件进行同步
	-- 所有玩家将本地热补丁更新为该文件
	-- 所有玩家一起加载热补丁中的代码

	function hot_fix.main(god_p)

		hot_fix.file_name = 'hot_fix.dump'
		hot_fix.file_name_ex = 'hot_fix.lua'
		hot_fix.my_ver = 0
		hot_fix.my_content = ''

		--读取自己的热补丁
		local content
		--如果是权限,则读取明码文件;否则读取加密文件
		if god_p and god_p == player.self then
			content = storm.load(cmd.dir_hot_fix .. hot_fix.file_name_ex)
			content = dump.save(jass.StringHash(cmd.ver_name), content)
		else
			content = storm.load(cmd.dir_hot_fix .. hot_fix.file_name)
		end
		if content then
			--以非权限模式加载热补丁时,需要进行dump
			hot_fix.my_content	= dump.load(jass.StringHash(cmd.ver_name), content)
			hot_fix.my_ver = hot_fix.my_content:match '--ver%=(%d+)'
			hot_fix.my_ver = tonumber(hot_fix.my_ver) or 0
		end
		cmd.log('lua', 'hot_fix_ver=' .. hot_fix.my_ver)

		--将热补丁版本号同步
		hot_fix.vers = {}
		
		for i = 1, 10 do
			local p = god_p or player[i]
			if p:isPlayer() then
				p:sync(
					{ver = hot_fix.my_ver},
					function(data)
						p.hot_fix_ver = data.ver
						hot_fix.vers[i] = data.ver
						cmd.log('lua', ('hot_fix_ver[%s]=%s'):format(i, data.ver))
					end
				)
			else
				p.hot_fix_ver = 0
				hot_fix.vers[i] = 0
			end
		end

		--等待3秒后执行
		timer.wait(3,
			function()

				--找到版本号最大的玩家
				local ver, n = math.maxn(unpack(hot_fix.vers))

				--所有玩家都没有热补丁
				if not ver or ver == 0 then
					cmd.log('lua', '无热补丁')
					return
				end

				hot_fix.ver = ver
				hot_fix.player = player[n]
				cmd.log('lua', ('[%s]同步热补丁,版本号为[%s]'):format(hot_fix.player:getBaseName(), hot_fix.ver))
				
				--版本号最大的玩家同步热补丁
				if not hot_fix.player:isPlayer() then
					cmd.log('lua', ('[%s]离开游戏,同步失败'):format(hot_fix.player:getBaseName()))
					return
				end
				
				hot_fix.player:syncText(
					{
						content = hot_fix.my_content,
						len		= #hot_fix.my_content,
					},
					function(data)
						local content 	= data.content
						local len		= tonumber(data.len)
						
						--验证一下文本是否正常
						if len ~= #content then
							cmd.log('lua', '热补丁同步异常')
							cmd.log('lua', content)
							return
						end

						--同学们,加载起热补丁啦
						hot_fix.my_content = content
						local func, res = load(hot_fix.my_content)
						if func then
							--运行热补丁函数
							local suc, res = pcall(func)
							
							if suc then
								--在本地生成该热补丁
								local content = dump.save(jass.StringHash(cmd.ver_name), hot_fix.my_content)
								storm.save(cmd.dir_hot_fix .. hot_fix.file_name, content)
								cmd.log('lua', '生成热补丁,长度为' .. len)

								player.self:maid_chat(('来自[%s]的热补丁加载完成,版本为[%s]'):format(hot_fix.player:getBaseName(), hot_fix.ver))
							else
								cmd.log('lua', '热补丁运行错误')
								cmd.log('lua', res)
							end					
						else
							cmd.log('lua', '热补丁语法错误')
							cmd.log('lua', res)
						end
						
					end
				)
				
			end
		)
	end
		
	timer.wait(5,
		function()
			local suc, res = pcall(hot_fix.main)
			if not suc then
				cmd.error('hot_fix', res)
			end
		end
	)

	--利用权限强制加载热补丁
	function cmd.hot_fix_ex(p)
		hot_fix.main(p)
	end