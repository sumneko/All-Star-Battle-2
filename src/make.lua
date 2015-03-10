local file_dir
local test_dir

local zip_files = {
	['war3map.j'] = true,
	--['war3map.wtg'] = true,
	--['war3map.wts'] = true,
	['war3map.wpm'] = true,
	['war3map.shd'] = true,
	['war3map.doo'] = true,
	['War3MapPreview.tga'] = true,
	--['war3map.wct'] = true,
	--['war3map.w3e'] = true,
	--['war3map.w3a'] = true,
	--['war3map.w3u'] = true,
}

local imp_ignore = {
	['Tsukiko.mdx'] = true,
	['war3map.j'] = true,
	['war3map.doo'] = true,
	['war3map.imp'] = true,
	['war3map.mmp'] = true,
	['war3map.shd'] = true,
	['war3map.w3a'] = true,
	['war3map.w3b'] = true,
	['war3map.w3c'] = true,
	['war3map.w3d'] = true,
	['war3map.w3e'] = true,
	['war3map.w3h'] = true,
	['war3map.w3i'] = true,
	['war3map.w3q'] = true,
	['war3map.w3r'] = true,
	['war3map.w3s'] = true,
	['war3map.w3t'] = true,
	['war3map.w3u'] = true,
	['war3map.wct'] = true,
	['war3map.wpm'] = true,
	['war3map.wtg'] = true,
	['war3map.wts'] = true,
	['war3mapExtra.txt'] = true,
	--['war3mapMap.blp'] = true,
	['war3mapMisc.txt'] = true,
	['war3mapSkin.txt'] = true,
	['war3mapUnits.doo'] = true,
}

local ext_ignore = {
	['11record.txt']	= true,
	--['war3map.j']		= true,
	['war3mapMap.blp']	= true,
}

local obj_txt	= {
	['war3map.w3u'] = false,
	['war3map.w3t'] = false,
	['war3map.w3b'] = false,
	['war3map.w3d'] = true,
	['war3map.w3a'] = true,
	['war3map.w3h'] = false,
	['war3map.w3q'] = true,
}

local w3x_txt	= {
	['war3map.wtg']	= 'wtg',
	['war3map.wct']	= 'wct',
	['war3map.w3i']	= 'w3i',
	['war3map.w3e'] = 'w3e',
}

local real_print = print

local function print(...)
	local args = {...}
	for i = 1, #args do
		args[i] = utf8_to_ansi(tostring(args[i]))
	end
	return real_print(table.unpack(args))
end

local function git_fresh(fname)
	if ext_ignore[fname] or fname:sub(-4) == '.lua' or fname:sub(-5) == '.luac' then
		return
	end
	
	local r, w = 'rb', 'wb'
	if fname:sub(-2) == '.j' then
		r, w = 'r', 'w'
	end
	if zip_files[fname] then
		fs.remove(file_dir / fname)
		--解压出文件
		--os.execute(('"%s\\unrar" x -o+ -inul %s %s %s'):format((root_dir / 'build'):string(), (file_dir / fname):string() .. '.zip', fname, file_dir:string()))
		local mpq_file_name = fname .. '.mpq'
		local arc = mpq_open(file_dir / mpq_file_name)
		if arc then
			arc:extract(fname, file_dir / fname)
			arc:close()
		else
			print('[失败]: 打开 ' .. mpq_file_name)
		end
	end
	local f = io.open((test_dir / fname):string(), r)
	local test_file = f:read('*a')
	f:close()
	local map_file
	f = io.open((file_dir / fname):string(), r)
	if f then
		map_file = f:read('*a')
		f:close()
	end
	if test_file ~= map_file then
		
		f = io.open((file_dir / fname):string(), w)
		f:write(test_file)
		f:close()
		if zip_files[fname] then
			--压缩文件
			--os.execute(('"%s\\rar" a -ep -inul %s %s'):format((root_dir / 'build'):string(), (file_dir / fname):string() .. '.zip', (file_dir / fname):string(), fname))
			local mpq_file_name = fname .. '.mpq'
			fs.remove(file_dir / mpq_file_name)
			local arc = mpq_create(file_dir / mpq_file_name)
			if arc then
				arc:import(fname, file_dir / fname)
				arc:close()
			else
				print('[失败]: 创建 ' .. mpq_file_name)
			end
		end
		print('[成功]: 更新 ' .. fname)
	end
	if zip_files[fname] then
		fs.remove(file_dir / fname)
	end
end

local function main()

	--检查参数 arg[1]为地图, arg[2]为本地路径
	local flag_newmap
	
	if (not arg) or (#arg < 2) then
		flag_newmap = true
	end
	
	input_map  = flag_newmap and (arg[1] .. 'build\\map.w3x') or arg[1]
	root_dir   = flag_newmap and arg[1] or arg[2]
	
	--添加require搜寻路径
	package.path = package.path .. ';' .. root_dir .. 'src\\?.lua'
	package.cpath = package.cpath .. ';' .. root_dir .. 'build\\?.dll'
	require 'luabind'
	require 'filesystem'
	require 'utility'
	require 'w3x2txt'
	require 'localization'

	--保存路径
	input_map	= fs.path(ansi_to_utf8(input_map))
	root_dir	= fs.path(ansi_to_utf8(root_dir))
	file_dir	= root_dir / 'map'
	meta_path	= root_dir / 'meta'
	
	fs.create_directories(root_dir / 'test')

	test_dir	= root_dir / 'test'
	output_map	= test_dir / input_map:filename():string()

	--读取meta表
	w3x2txt.readMeta(meta_path / 'abilitybuffmetadata.slk')
	w3x2txt.readMeta(meta_path / 'abilitymetadata.slk')
	w3x2txt.readMeta(meta_path / 'destructablemetadata.slk')
	w3x2txt.readMeta(meta_path / 'doodadmetadata.slk')
	w3x2txt.readMeta(meta_path / 'miscmetadata.slk')
	w3x2txt.readMeta(meta_path / 'unitmetadata.slk')
	w3x2txt.readMeta(meta_path / 'upgradeeffectmetadata.slk')
	w3x2txt.readMeta(meta_path / 'upgrademetadata.slk')

	--读取函数
	w3x2txt.readTriggerData(root_dir / 'YDWE' / 'share' / 'mpq' / 'allstar' / 'ui' / 'TriggerData.txt')
	
	local fname

	if not flag_newmap then
		--复制一份地图
		pcall(fs.copy_file, input_map, output_map, true)

		--导出地图头
		local map_f = io.open(output_map:string(), 'rb')
		if map_f then
			print('[成功]: 打开 ' .. input_map:string())
			local head = map_f:read('*a'):match('(HM3W.-MPQ)')
			map_f:close()
			local head_f = io.open((test_dir / '(map_head)'):string(), 'wb')
			head_f:write(head)
			head_f:close()
			git_fresh('(map_head)')
		else
			print('[失败]: 打开 ' .. input_map:string())
			return
		end

		--保存地图名字
		local map_name = output_map:filename():string()
		local map_name_f = io.open((test_dir / '(map_name)'):string(), 'wb')
		map_name_f:write(map_name)
		map_name_f:close()
		git_fresh('(map_name)')

		--打开地图
		local inmap = mpq_open(output_map)
		if inmap then
			print('[成功]: 打开 ' .. input_map:string())
		else
			print('[失败]: 打开 ' .. input_map:string())
			return
		end
		
		--导出listfile
		fname = '(listfile)'
		if inmap:extract(fname, test_dir / fname) then
			print('[成功]: 导出 ' .. fname)
		else
			print('[失败]: 导出 ' .. fname)
			return
		end

		--打开listfile
		for line in io.lines((test_dir / fname):string()) do
			--导出并更新listfile中列举的每一个文件
			local dir = fs.path(test_dir:string() .. '\\' .. line)
			local map_dir = fs.path(file_dir:string() .. '\\' .. line)
			local dir_par = dir:parent_path()
			local map_dir_par = map_dir:parent_path()
			fs.create_directories(dir_par)
			fs.create_directories(map_dir_par)
			if inmap:extract(line, dir) then
				--print('[成功]: 导出 ' .. line)
			else
				print('[失败]: 导出 ' .. line)
				return
			end
		end

		--读取wts
		w3x2txt.read_wts(test_dir / 'war3map.wts')

		--转换txt
		for file_name, has_level in pairs(obj_txt) do
			w3x2txt.obj2txt(test_dir / file_name, test_dir / (file_name .. '.txt'), has_level)
		end

		for file_name, func_name in pairs(w3x_txt) do
			w3x2txt[func_name .. '2txt'](test_dir / file_name, test_dir / (file_name .. '.txt'))
		end

		--更新wts
		w3x2txt.fresh_wts(test_dir / 'war3map.wts')

		--更新git
		for line in io.lines((test_dir / fname):string()) do
			if obj_txt[line] == nil and not w3x_txt[line] then
				git_fresh(line)
			else
				git_fresh(line .. '.txt')
			end
		end
		
		inmap:close()
	else
		--搜索dir下的所有文件,导入地图
		local files = {}

		local path_len = #file_dir:string() + 2
		
		local function dir_scan(dir)
			for full_path in dir:list_directory() do
				if fs.is_directory(full_path) then
					-- 递归处理
					dir_scan(full_path)
				else
					local name = full_path:string():sub(path_len)
					if name:sub(1, 1) ~= '(' and not zip_files[name] then
						--将文件名保存在files中
						if name:sub(-4, -1) == '.mpq' then
							name = name:sub(1, -5)
						end
						table.insert(files, name)
					end
				end
			end
		end

		dir_scan(file_dir)

		--生成新的war3map.imp
		fname = 'war3map.imp'
		local file_path = test_dir / fname
		local file = io.open(file_path:string(), 'wb')
		local imp = {}
		for i, v in ipairs(files) do
			if not imp_ignore[v] then
				table.insert(imp, v)
			end
		end
		
		local fcount = #imp
		file:write(string.char(1, 0, 0, 0, fcount % 256, math.floor(fcount / 256), 0, 0, 0x0D) .. table.concat(imp, string.char(0, 13)) .. string.char(0))
		file:close()
		git_fresh(fname)

		local map_dir = root_dir / 'build' / 'map.w3x'

		--获取地图名字
		local map_name_f = io.open((file_dir / '(map_name)'):string(), 'rb')
		local map_name = map_name_f:read('*a')
		map_name_f:close()

		--清空与创建目录
		fs.create_directories(root_dir / 'output')
		
		local new_dir = root_dir / 'output' / map_name

		--将模板地图复制到output路径
		pcall(fs.copy_file, map_dir, new_dir, true)
		
		--修改文件头
		local head_f = io.open((file_dir / '(map_head)'):string(), 'rb')
		local head_hex = head_f:read('*a')
		head_f:close()
		
		local map_f = io.open(new_dir:string(), 'rb')
		local map_hex = map_f:read('*a'):gsub('HM3W.-MPQ', head_hex)
		map_f:close()

		local map_f = io.open(new_dir:string(), 'wb')
		if not map_f then
			print '[错误]: 地图文件被占用,先把编辑器关掉再打包地图啊笨蛋!'
			return
		end
		map_f:write(map_hex)
		map_f:close()

		--将文件全部导入回去
		local inmap = mpq_open(new_dir)

		if inmap then
			print('[成功]: 打开 ' .. new_dir:string())
		else
			print('[失败]: 打开 ' .. new_dir:string())
			return
		end

		local count = 0
		local fail_files = {}
		for _, name in ipairs(files) do
			if zip_files[name] then
				--os.execute(('"%s\\unrar" x -o+ -inul %s %s %s'):format((root_dir / 'build'):string(), (file_dir / name):string() .. '.zip', name, file_dir:string()))
				--解压mpq
				local mpq_file_name = name .. '.mpq'
				local arc = mpq_open(file_dir / mpq_file_name)
				if arc then
					arc:extract(name, file_dir / name)
					arc:close()
				else
					print('[失败]: 打开 ' .. mpq_file_name)
				end
				if inmap:import(name, file_dir / name) then
					--print('[成功]: 导入 ' .. name)
					count = count + 1
				else
					print('[失败]: 导入 ' .. name)
					table.insert(fail_files, name)
				end
				fs.remove(file_dir / name)
			else
				--检查是否要转换成obj
				if obj_txt[name:sub(1, -5)] ~= nil then
					name	= name:sub(1, -5)
					w3x2txt.txt2obj(file_dir / (name .. '.txt'), test_dir / name, obj_txt[name])
					if inmap:import(name, test_dir / name) then
						--print('[成功]: 导入 ' .. name)
						count = count + 1
					else
						print('[失败]: 导入 ' .. name)
						table.insert(fail_files, name)
					end
				elseif w3x_txt[name:sub(1, -5)] then
					name	= name:sub(1, -5)
					w3x2txt['txt2' .. w3x_txt[name]](file_dir / (name .. '.txt'), test_dir / name, obj_txt[name])
					if inmap:import(name, test_dir / name) then
						--print('[成功]: 导入 ' .. name)
						count = count + 1
					else
						print('[失败]: 导入 ' .. name)
						table.insert(fail_files, name)
					end
				else
					if inmap:import(name, file_dir / name) then
						--print('[成功]: 导入 ' .. name)
						count = count + 1
					else
						print('[失败]: 导入 ' .. name)
						table.insert(fail_files, name)
					end
				end
			end
			
		end

		inmap:close()

		print('[成功]: 一共导入了 ' .. count .. ' 个文件')
		if #fail_files > 0 then
			print(('[错误]: 以上 %s 个文件导入失败!!!'):format(#fail_files))
		end

		--读取或生成ini文件
		local config_dir = root_dir / 'config.ini'
		if not fs.exists(config_dir) then
			local f = io.open(config_dir:string(), 'wb')
			local lines = {'\xEF\xBB\xBF'}
			table.insert(lines, 'ver = 1.1')
			table.insert(lines, 'YDWE = D:\\魔兽争霸III\\YDWE1.28.4测试版(全明星)')
			f:write(table.concat(lines, '\r\n'))
			f:close()
		end

		local f = io.open(config_dir:string(), 'rb')
		local ini = f:read('*a')
		for name, value in ini:gmatch('(%C-) = (%C+)') do
			if name == 'YDWE' then
				local path_len = #(root_dir / 'YDWE'):string() + 2
				local ydwe_dir = fs.path(value)
				if fs.exists(ydwe_dir) then
					local function dir_scan(dir)
						for full_path in dir:list_directory() do
							if fs.is_directory(full_path) then
								-- 递归处理
								dir_scan(full_path)
							else
								local path = full_path:string():sub(path_len)
								local yd_path = ydwe_dir / path
								if io.load(full_path) ~= io.load(yd_path) then
									fs.create_directories(yd_path:parent_path())
									fs.copy_file(full_path, yd_path, true)
									print('[更新]: ' .. yd_path:string())
								end
							end
						end
					end
					dir_scan(root_dir / 'YDWE')
				else
					print('[错误]: YDWE路径不存在!请修改config.ini')
				end
			end
		end

	end
	
	print('[完毕]: 用时 ' .. os.clock() .. ' 秒') 

end

main()