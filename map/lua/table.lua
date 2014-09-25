	
	--如果不是数字,则移除指定值
	local oldremove = table.remove
	
	function table.remove(t, p)
		if p and type(p) ~= 'number' then
			for i = 1, #t do
				local v = t[i]
				if v == p then
					oldremove(t, i)
					return
				end
			end
		else
			oldremove(t, p)
		end
	end

	--将数组转化为哈希表
	function table.key(t, v)
		if v == nil then
			v = true
		end
		local nt = {}
		for i = 1, #t do
			nt[t[i]] = v
		end
		return nt
	end

	--挑选出数组中的某个值
	
		---table.pick(表, 规则, 项目)
		function table.pick(t, f1, f2)
			local count = #t
			if count == 0 then
				return
			elseif count == 1 then
				return t[1], 1
			end

			local y = f2 and f2(t[1]) or t[1]
			local r = 1
			for i = 2, count do
				local x = f2 and f2(t[i]) or t[i]
				if f1(x, y) then
					y = x
					r = i
				end
			end

			return t[r], r
		end

	--批量删除表中指定的索引
	function table.removes(a, b)
		local n = #a - #b + 1
		for j = 1, #b do
			local x, y = b[j], b[j + 1] or #a
			for i = x - j + 1, y - j + 1 do
				a[i] = a[i + j]
			end
		end
		for i = n, #a do
			a[i] = nil
		end
	end

	
	--建立带有默认值的表
	function table.new(n)
		local mt = {}
		function mt.__index()
			return n
		end
		function mt.__call(t, nt)
			mt.__call = nil
			return setmetatable(nt, mt)
		end
		return setmetatable({}, mt)
	end

	--创建反向表(不要吐槽我英文)
	function table.back(t)
		local tt = {}
		for name, value in pairs(t)	do
			if not tt[name] and not tt[value] then
				tt[name]	= true
				tt[value]	= true
				t[value]	= name
			end
		end
		return t
	end

	--meta表
	table.meta = {
		math = {
			__index = function()
				return 0
			end,
			__add	= function(t1, t2)
				local t = setmetatable({}, table.meta.math)
				for name in pairs(t1) do
					t[name] = t1[name] + t2[name]
				end
				return t
			end,
			__sub	= function(t1, t2)
				local t = setmetatable({}, table.meta.math)
				for name in pairs(t1) do
					t[name] = t1[name] - t2[name]
				end
				return t
			end,
		},
	}