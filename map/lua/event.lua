	event = {}

	setmetatable(event, event)

	function event.dummy_func()
	end

	--发起事件
	---发起事件(事件1, 事件2, 事件3..., 数据)
	function event.start(...)
		local arg = {...}
		local count = #arg
		local data = arg[count]
		for i = 1, count - 1 do
			
			--当前事件的名字
			local name = arg[i]
			local t = event[name]
			if t then
				if #t.removes ~= 0 and t.lock == 0 then
					table.removes(t, t.removes)
					t.removes = {}
				end
				t.lock = t.lock + 1
				for i = 1, #t do
					--找到函数
					local f = t[i]
					local r = f(data, name, f)
					--如果事件有返回值,则直接退出
					if r then
						return r
					end
				end
				t.lock = t.lock - 1
			end
		end
	end

	--注册事件
	---event.get(事件1, 事件2, 事件3..., 函数)
	function event.init(...)
		local arg = {...}
		local count = #arg
		local f = arg[count]
		for i = 1, count - 1 do
			
			--当前事件的名字
			local name = arg[i]

			--检查是否是删除事件
			if name:sub(1, 1) == '-' then
				name = name:sub(2)

				local t = event[name]
				if t then
					for i = 1, #t do
						if f == t[i] then
							t[i] = event.dummy_func
							table.insert(t.removes, i)
							break
						end
					end
				end
			else

				local t = event[name]
				if not t then
					--如果事件表不存在就新建
					t = {}
					t.lock = 0
					t.removes = {}
					event[name] = t
				end
				table.insert(t, f)
			end
		end
		return f
	end

	---event(事件1, 事件2, 事件3..., [函数, 数据])
	function event.__call(_, ...)
		local arg = {...}
		if type(arg[#arg]) == 'table' then
			return event.start(...)
		else
			return event.init(...)
		end
	end