    
    timer = {}
	local timer = timer
	--全局计时
	timer.gTimer = jass.CreateTimer()
	jass.TimerStart(timer.gTimer, 999999, false, nil)
	--获取当前时间
	-- -代参数时返回时间对应的文字
	function timer.time(a)
		if a then
			local t = jass.TimerGetElapsed(timer.gTimer)
			local h = math.floor(t / 3600)
			local m = math.floor((t - h * 3600) / 60)
			local s =t - h * 3600 - m * 60
			if h == 0 then
				if m == 0 then
					return string.format("%06.3f", s)
				else
					return string.format("%02d:%06.3f", m, s)
				end
			else
				return string.format("%02d:%02d:%06.3f", h, m, s)
			end
		else
			return jass.TimerGetElapsed(timer.gTimer)
		end
	end
	--存放空闲计时器
	timer.idles = {}
	--空闲计时器计数
	timer.idleCount = 100
	--先创建500个备用计时器出来
	for i = 1, 100 do
		timer.idles[i] = jass.CreateTimer()
	end
	--已经创建的计时器计数
	timer.count = 100
	--创建计时器
	function timer.create()
		local jTimer
		if timer.idleCount > 0 then
			--有空闲计时器
			jTimer = timer.idles[timer.idleCount]
			timer.idleCount = timer.idleCount - 1
		else
			--没有就新建计时器
			jTimer = jass.CreateTimer()
			timer.count = timer.count + 1
			--警告,使用的计时器超出了100个
			print(('CreateMoreTimers!! (%d)'):format(timer.time(true), timer.count))
		end
		return setmetatable({jTimer}, timer)
	end
	--计时器结构	
	timer.__index = {
		--结构类型
		type = 'timer',
		
		--[1]计时器handle
		[1] = nil,
		--[2]计时器周期
		[2] = 0,
		--[3]是否循环
		[3] = false,
		--[4]回调函数
		[4] = nil,
		--启动计时器
		-- -timer:start(周期, 是否循环, 回调函数)
		start = function(this, dur, loop, func)
			local jTimer = this[1]
			if jTimer then
				this[2], this[3], this[4] = dur, loop, func
				jass.TimerStart(jTimer, dur, loop, func)
			end
		end,
		--暂停计时器
		-- -timer:pause()
		pause = function(this)
			local jTimer = this[1]
			if jTimer then
				jass.PauseTimer(jTimer)
			end
		end,
		--摧毁计时器
		-- -timer:destroy()
		destroy = function(this)
			local jTimer = this[1]
			if jTimer then
				jass.PauseTimer(jTimer)
				--保护
				this[1] = nil
				--放回空闲计时器表中
				timer.idleCount = timer.idleCount + 1
				timer.idles[timer.idleCount] = jTimer
			end
		end,
	}
	--常用函数
	
	--延迟后执行函数(时间, 函数)
	-- -返回(计时器, 函数)
	-- --执行的函数将代入参数(计时器),如果函数返回true则不摧毁计时器
	function timer.wait(r, f)
		local t = timer.create()
		t:start(r, false,
			function()
				if not f(t) then
					t:destroy()
				end
			end
		)
		return t, f
	end
	--循环执行函数(时间, [是否立即运行一次], 函数)
	-- -返回(计时器, 函数)
	-- --执行的函数将代入参数(计时器),如果函数返回true则摧毁计时器
	function timer.loop(r, b, f)
		if not f then
			b, f = false, b
		end
		local t = timer.create()
		if b and f(t) then
			t:destroy()
		else
			t:start(r, true,
				function()
					if f(t) then
						t:destroy()
					end
				end
			)
		end
		return t, f
	end
	--按次数循环执行函数(时间, 次数, [是否立即运行一次], 函数)
	-- -返回(计时器, 函数)
	-- --执行的函数将代入参数(当前次数, 计时器),如果函数返回true则提前摧毁计时器
	function timer.rep(r, c, b, f)
		if not f then
			b, f = false, b
		end
		local i = 1
		local t = timer.create()
		local function run()
			if i > c or f(i, t) then
				t:destroy()
			else
				i = i + 1
			end
		end
		if b then
			run()
		end
		t:start(r, true, run)
		return t, f
	end
    
