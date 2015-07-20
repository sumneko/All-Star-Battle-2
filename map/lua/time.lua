
	time = {}

	function time.readTime()
		time.my_time = os.time()
		time.my_date = os.date('%Y-%m-%d-%H.%M.%S', time.my_time)

	end

	function time.syncTime()
		time.times = {}
		
		local count = 0

		--交换时间数据
		for i = 1, 10 do
			local p = player[i]
			
			local function f(data, suc)
				if suc then
					table.insert(time.times, data[1])
					print(('同步时间[%d]=%d'):format(i, data[1]))
				end
				count = count - 1
				if count == 0 then
					time.syncReady()
				end
			end
			
			if p:sync({time.my_time}, f) then
				count = count + 1
			end
		end
	end

	function time.syncReady()
		print(('时间全部同步完成'))
		print(table.concat(time.times, '\n'))

		while true do
			--先求方差
			local dx = math.dx(table.unpack(time.times))
			if not dx then
				break
			end
			--找出方差最大值
			local mn, mi = math.maxn(table.unpack(dx))
			if mn > 1e2 then
				table.remove(time.times, mi)
			else
				time.now_time = math.ave(table.unpack(time.times))
				time.now_date = os.date('%Y年%m月%d日%H:%M:%S', time.now_time)
				break
			end
		end

		print(('now_time = %d'):format(time.now_time))
		print(('now_date = %s'):format(time.now_date))

		cmd.maid_chat(('当前时间为 %s ,对不对呢?'):format(time.now_date))
		
	end

	function time.main()
		time.readTime()
	end

	return time.main()