	w3x2txt = {}

	local w3x2txt = w3x2txt

	local function main()
		--读取内部类型
		local meta_list	= {}

		meta_list.default	= {
			type	= 'string',
		}
		
		setmetatable(meta_list,
			{
				__index = function(_, id)
					return rawget(meta_list, 'default')
				end
			}
		)

		function w3x2txt.readMeta(file_name)
			local content	= io.load(file_name)
			if not content then
				print('文件无效:' .. file_name:string())
				return
			end

			for line in content:gmatch '[^\n\r]+' do
				local id	= line:match [[C;.*X1;.*K"(.-)"]]
				if id then
					meta_list.id	= id
					meta_list[id]	= {}
					goto continue
				end
				local x, value	= line:match [[C;X(%d+);K["]*(.-)["]*$]]
				if x then
					if meta_list.id == 'ID' then
						meta_list[x]	= value
					elseif meta_list[x] == 'type' then
						meta_list[meta_list.id].type	= value
					elseif meta_list[x] == 'data' then
						meta_list[meta_list.id].data	= value
					end
				end
				:: continue ::
			end
		end

		local index

		--string.pack/string.unpack的参数
		local data_type_format	= {}
		data_type_format[0]	= 'l'	--4字节有符号整数
		data_type_format[1] = 'f'	--4字节无符号浮点
		data_type_format[2] = 'f'	--4字节有符号浮点
		data_type_format[3] = 'z'	--以\0结尾的字符串

		setmetatable(data_type_format,
			{
				__index	= function(_, i)
					print(i, ('%x'):format(index - 2))
				end
			}
		)

		local value_type = {
			int			= 'int',
			bool		= 'int',
			unreal		= 'unreal',
			real		= 'real',
			deathType	= 'int',
			attackBits	= 'int',
			teamColor	= 'int',
			fullFlags	= 'int',
			channelType	= 'int',
			channelFlags= 'int',
			stackFlags	= 'int',
			silenceFlags= 'int',
			spellDetail	= 'int',
		}
		setmetatable(value_type,
			{
				__index	= function()
					return 'string'
				end,
			}
		)

		--将值根据内部类型转化为txt
		local function value2txt(value, id)
			local type	= meta_list[id].type
			if type == 'real' or type == 'unreal' then
				value = ('%.4f'):format(value)
			end
			return value
		end

		--将txt的值根据内部类型转化
		local function txt2value(value, id)
			local type	= value_type[meta_list[id].type]
			if type == 'int' then
				return value, 0
			elseif type == 'real' then
				return value, 1
			elseif type == 'unreal' then
				return value, 2
			end
			return value, 3
		end

		function w3x2txt.obj2txt(file_name_in, file_name_out, has_level)
			local content	= io.load(file_name_in)
			if not content then
				print('文件无效:' .. file_name_in:string())
				return
			end

			index = 1
			
			local len	= #content
			local lines	= {}

			local ver
			
			local chunks = {}
			local chunk, objs, obj, datas, data

			--解析方法
			local funcs	= {}

			--解析数据头
			function funcs.readHead()
				ver, index	= ('l'):unpack(content, index)

				funcs.next	= funcs.readChunk
			end

			--解析块
			function funcs.readChunk()
				chunk	= {}
				objs	= {}
				chunk.objs	= objs

				chunk.obj_count, index	= ('l'):unpack(content, index)

				table.insert(chunks, chunk)

				funcs.next	= funcs.readObj
			end

			--解析物体
			function funcs.readObj()
				obj	= {}
				datas	={}
				obj.datas	= datas
				obj.origin_id, obj.id, obj.data_count, index	= ('c4c4l'):unpack(content, index)
				if obj.id == '\0\0\0\0' then
					obj.id	= obj.origin_id
				end

				table.insert(objs, obj)

				if obj.data_count > 0 then
					funcs.next	= funcs.readData
				else
					--检查是否将这个chunk中的数据读完了
					if #objs == chunk.obj_count then
						funcs.next	= funcs.readChunk
						return
					end
					funcs.next	= funcs.readObj
				end
			end

			--解析数据
			function funcs.readData()
				data	= {}
				data.id, data.type, index	= ('c4l'):unpack(content, index)

				--是否包含等级信息
				if has_level then
					data.level, _, index	= ('ll'):unpack(content, index)
					if data.level == 0 then
						data.level	= nil
					end
				end
				
				data.value, index	= data_type_format[data.type]:unpack(content, index)
				data.value	= value2txt(data.value, data.id)
				if data.type == 3 then
					data.value	= data.value:gsub('\r\n', '@@n'):gsub('\t', '@@t')
				end
				index	= index + 4	--忽略掉后面4位的标识符

				table.insert(datas, data)

				--检查是否将这个obj中的数据读完了
				if #datas == obj.data_count then
					--检查是否将这个chunk中的数据读完了
					if #objs == chunk.obj_count then
						funcs.next	= funcs.readChunk
						return
					end
					funcs.next	= funcs.readObj
					return
				end
			end

			funcs.next	= funcs.readHead

			--开始解析
			repeat
				funcs.next()
			until index >= len or not funcs.next

			--转换文本
			--版本
			table.insert(lines, ('%s=%s'):format('VERSION', ver))
			for _, chunk in ipairs(chunks) do
				--chunk标记
				table.insert(lines, '[CHUNK]')
				for _, obj in ipairs(chunk.objs) do
					--obj的id
					if obj.id == obj.origin_id then
						table.insert(lines, ('[%s]'):format(obj.id))
					else
						table.insert(lines, ('[%s:%s]'):format(obj.id, obj.origin_id))
					end
					for _, data in ipairs(obj.datas) do
						--数据项
						local line = {}
						--数据id
						table.insert(line, data.id)
						--数据等级
						if data.level then
							table.insert(line, ('[%d]'):format(data.level))
						end
						table.insert(line, '=')
						--数据值
						table.insert(line, data.value)
						table.insert(lines, table.concat(line))
					end
				end
			end

			io.save(file_name_out, table.concat(lines, '\n'))

		end

		function w3x2txt.txt2obj(file_name_in, file_name_out, has_level)
			local content	= io.load(file_name_in)
			if not content then
				print('文件无效:' .. file_name_in:string())
				return
			end

			local pack = {}
			local chunks, chunk, objs, obj, datas, data
			local funcs
			funcs	= {
				--版本号
				function (line)
					pack.ver	= line:match 'VERSION%=(.+)'
					if pack.ver then
						chunks	= {}
						pack.chunks	= chunks
						table.remove(funcs, 1)
						return true
					end
				end,

				--块
				function (line)
					local obj_count	= line:match '^%s*%[%s*CHUNK%s*%]%s*$'
					if obj_count then
						chunk	= {}
						objs	= {}
						chunk.objs	= objs

						chunk.obj_count	= obj_count

						table.insert(chunks, chunk)
						return true
					end
				end,

				--当前obj的id
				function (line)
					local str	= line:match '^%s*%[%s*(.-)%s*%]%s*$'
					if not str then
						return
					end

					obj	= {}
					datas	= {}
					obj.datas	= datas

					obj.id, obj.origin_id	= str:match '^%s*(.-)%s*%:%s*(.-)%s*$'
					if not obj.id then
						obj.id, obj.origin_id	= str, str
					end

					table.insert(objs, obj)

					return true
				end,

				--当前obj的data
				function (line)
					local _, last, id	= line:find '^%s*(.-)%s*%='
					if not id then
						return
					end

					data = {}

					--检查是否包含等级信息
					if has_level then
						data.level	= id:match '%[(%d+)%]'
						id	= id:sub(1, 4)
					end

					data.id, data.value	= id, line:sub(last + 1):match '^%s*(.*)$'
					data.value, data.type	= txt2value(data.value, data.id)
					data.value	= data_type_format[data.type]:pack(data.value)

					if data.type == 3 then
						data.value	= data.value:gsub('@@n', '\r\n'):gsub('@@t', '\t')
					end

					table.insert(datas, data)

					return true
				end,
			}

			--解析文本
			for line in content:gmatch '[^\n\r]+' do
				for _, func in ipairs(funcs) do
					if func(line) then
						break
					end
				end
			end

			--生成2进制文件
			local hexs	= {}
			--版本
			table.insert(hexs, ('l'):pack(pack.ver))
			for _, chunk in ipairs(pack.chunks) do
				--obj数量
				table.insert(hexs, ('l'):pack(#chunk.objs))
				for _, obj in ipairs(chunk.objs) do
					--obj的id与数量
					if obj.origin_id == obj.id then
						obj.id	= '\0\0\0\0'
					end
					table.insert(hexs, ('c4c4l'):pack(obj.origin_id, obj.id, #obj.datas))
					for _, data in ipairs(obj.datas) do
						--data的id与类型
						if #data.id ~= 4 then
							print(data.id)
						end
						table.insert(hexs, ('c4l'):pack(data.id, data.type))
						--data的等级与分类
						if has_level then
							table.insert(hexs, ('ll'):pack(data.level or 0, meta_list[data.id].data or 0))
						end
						--data的内容
						table.insert(hexs, data.value)
						--添加一个结束标记
						table.insert(hexs, '\0\0\0\0')
					end
				end
			end

			io.save(file_name_out, table.concat(hexs))
		end

		local function_state	= {}

		function w3x2txt.readTriggerData(file_name_in)
			local content	= io.load(file_name_in)
			if not content then
				print('文件无效:' .. file_name_in)
				return
			end

			local funcs
			funcs	= {
				--检查关键字,判断函数域
				function (line)
					local trigger_type	= line:match '^%[(.+)%]$'
					if not trigger_type then
						return
					end

					if trigger_type	== 'TriggerEvents' then
						trigger_type	= 0
					elseif trigger_type	== 'TriggerConditions' then
						trigger_type	= 1
					elseif trigger_type	== 'TriggerActions' then
						trigger_type	= 2
					elseif trigger_type	== 'TriggerCalls' then
						trigger_type	= 3
					else
						funcs.trigger_type	= nil
						return
					end

					funcs.states	= {}
					funcs.trigger_type	= trigger_type
					function_state[trigger_type]	= funcs.states

				end,

				--检查函数
				function (line)
					if not funcs.trigger_type then
						return
					end

					local name, args	= line:match '^([^_].-)%=(.-)$'
					if not name then
						return
					end

					local state	= {}
					state.name	= name
					state.args	= {}

					for arg in args:gmatch '[^%,]+' do
						--排除部分参数
						if not tonumber(arg) and arg ~= 'nothing' then
							table.insert(state.args, arg)
						end
					end
					--类型为调用时,去掉第一个返回值
					if funcs.trigger_type == 3 then
						table.remove(state.args, 1)
					end

					table.insert(funcs.states, state)
					funcs.states[state.name]	= state
				end,
			}

			--解析文本
			for line in content:gmatch '[^\n\r]+' do
				for _, func in ipairs(funcs) do
					if func(line) then
						break
					end
				end
			end

		end

		function w3x2txt.wtg2txt(file_name_in, file_name_out)
			local content	= io.load(file_name_in)
			if not content then
				print('文件无效:' .. file_name_in)
				return
			end

			local index	= 1
			local len	= #content

			local chunk	= {}
			local funcs	= {}
			local categories, category, vars, var, triggers, trigger, ecas, eca, args, arg

			--文件头
			function funcs.readHead()
				chunk.file_id,			--文件ID
				chunk.file_ver,			--文件版本
				index	= ('c4l'):unpack(content, index)
			end

			--触发器类别(文件夹)
			function funcs.readCategories()
				--触发器类别数量
				chunk.category_count, index	= ('l'):unpack(content, index)

				--初始化
				categories	= {}
				chunk.categories	= categories

				for i = 1, chunk.category_count do
					funcs.readCategory()
				end
			end

			function funcs.readCategory()
				category	= {}
				category.id, category.name, category.comment, index	= ('lzl'):unpack(content, index)

				table.insert(categories, category)
			end

			--全局变量
			function funcs.readVars()
				--全局变量数量
				chunk.int_unknow_1, chunk.var_count, index	= ('ll'):unpack(content, index)
				
				--初始化
				vars	= {}
				chunk.vars	= vars

				for i = 1, chunk.var_count do
					funcs.readVar()
				end
			end

			function funcs.readVar()
				var	= {}
				var.name,		--变量名
				var.type,		--变量类型
				var.int_unknow_1,	--(永远是1,忽略)
				var.is_array,	--是否是数组(0不是, 1是)
				var.array_size,	--数组大小(非数组是1)
				var.is_default,	--是否是默认值(0是, 1不是)
				var.value,		--初始数值
				index = ('zzllllz'):unpack(content, index)

				table.insert(vars, var)
				vars[var.name]	= var
			end

			--触发器
			function funcs.readTriggers()
				--触发器数量
				chunk.trigger_count, index	= ('l'):unpack(content, index)

				--初始化
				triggers	= {}
				chunk.triggers	= triggers

				for i = 1, chunk.trigger_count do
					funcs.readTrigger()
				end
			end

			function funcs.readTrigger()
				trigger	= {}
				trigger.name,		--触发器名字
				trigger.des,		--触发器描述
				trigger.int_unknow_1,
				trigger.enable,		--是否允许(0禁用, 1允许)
				trigger.wct,		--是否是自定义代码(0不是, 1是)
				trigger.init,		--是否初始化(0是, 1不是)
				trigger.int_unknow_2,	--未知
				trigger.category,	--在哪个文件夹下
				index	= ('zzllllll'):unpack(content, index)

				table.insert(triggers, trigger)
				--print('trigger:' .. trigger.name)
				--读取子结构
				funcs.readEcas()

			end

			--子结构
			function funcs.readEcas()
				--子结构数量
				trigger.eca_count, index	= ('l'):unpack(content, index)

				--初始化
				ecas	= {}
				trigger.ecas	= ecas

				for i = 1, trigger.eca_count do
					funcs.readEca()
				end
			end

			function funcs.readEca(is_child, is_arg)
				eca	= {}
				local eca	= eca
				
				eca.type,	--类型(0事件, 1条件, 2动作, 3函数调用)
				index	= ('l'):unpack(content, index)

				--是否是复合结构
				if is_child then
					eca.child_id, index	= ('l'):unpack(content, index)
				end

				--是否是参数中的子函数
				if is_arg then
					is_arg.eca	= eca
				else
					table.insert(ecas, eca)
				end
				
				eca.name,	--名字
				eca.enable,	--是否允许(0不允许, 1允许)
				index	= ('zl'):unpack(content, index)

				--print('eca:' .. eca.name)
				--读取参数
				funcs.readArgs(eca)

				--if,loop等复合结构
				eca.child_eca_count, index	= ('l'):unpack(content, index)
				for i = 1, eca.child_eca_count do
					funcs.readEca(true)
				end
			end

			--参数
			function funcs.readArgs(eca)
				--初始化
				args	= {}
				local args	= args
				eca.args	= args

				--print(eca.type, eca.name)
				local state_args	= function_state[eca.type][eca.name].args
				local arg_count	= #state_args

				--print('args:' .. arg_count)

				for i = 1, arg_count do
					funcs.readArg(args)
				end

			end

			function funcs.readArg(args)
				arg	= {}

				arg.type, 			--类型(0预设, 1变量, 2函数, 3代码)
				arg.value,			--值
				arg.insert_call,	--是否需要插入调用
				index	= ('lzl'):unpack(content, index)
				--print('var:' .. arg.value)

				--是否是索引
				table.insert(args, arg)

				--插入调用
				if arg.insert_call == 1 then
					funcs.readEca(false, arg)
					arg.int_unknow_1, index	= ('l'):unpack(content, index) --永远是0
					--print(arg.int_unknow_1)
					return
				end

				arg.insert_index,	--是否需要插入数组索引
				index	= ('l'):unpack(content, index)

				--插入数组索引
				if arg.insert_index == 1 then
					funcs.readArg(args)
				end
			end

			--开始解析
			do
				funcs.readHead()
				funcs.readCategories()
				funcs.readVars()
				funcs.readTriggers()
			end

			--开始转化文本
			local lines	= {}
			
			do
				--版本
				table.insert(lines, ('VERSION=%d'):format(chunk.file_ver))
				table.insert(lines, ('未知1=%s'):format(chunk.int_unknow_1))

				--全局变量
				table.insert(lines, '【Global】')
				for i, var in ipairs(chunk.vars) do
					if var.is_array == 1 then
						if var.value ~= '' then
							table.insert(lines, ('%s %s[%d]=%s'):format(var.type, var.name, var.array_size, var.value))
						else
							table.insert(lines, ('%s %s[%d]'):format(var.type, var.name, var.array_size))
						end
					else
						if var.value ~= '' then
							table.insert(lines, ('%s %s=%s'):format(var.type, var.name, var.value))
						else
							table.insert(lines, ('%s %s'):format(var.type, var.name))
						end
					end
				end

				--触发器类别(文件夹)
				table.insert(lines, '【Category】')
				for _, category in ipairs(chunk.categories) do
					table.insert(lines, ('[%s](%d)%s'):format(
						category.name,
						category.id,
						category.comment == 1 and '*' or ''
					))
				end

				--ECA结构
				local tab	= 1
				local ecas, index, max
				
				local function push_eca(eca, is_arg)
					--print(index, eca, is_arg, max)
					table.insert(lines, ('%s%s[%d]%s%s%s'):format(
						('\t'):rep(tab),
						eca.child_id and ('(%d)'):format(eca.child_id) or '',
						eca.type,
						eca.name,
						(eca.enable == 0 and '*') or (is_arg and '#') or '',
						eca.child_eca_count == 0 and '' or ('[%d]'):format(eca.child_eca_count)
					))
					--参数
					tab = tab + 1
					for _, arg in ipairs(eca.args) do
						if arg.insert_call == 1 then
							push_eca(arg.eca, true)
						else
							table.insert(lines, ('%s[%d]%s%s'):format(
								('\t'):rep(tab),
								arg.type,
								arg.value:gsub('\r\n', '@@n'):gsub('\t', '@@t'),
								(arg.insert_index == 1 or arg.insert_call == 1) and '*' or ''
							))
						end
					end
					tab = tab - 1
					if eca.child_eca_count ~= 0 then
						--print(eca.name, eca.child_eca_count)
						tab	= tab + 1
						for i = 1, eca.child_eca_count do
							local eca	= ecas[index]
							index	= index + 1
							push_eca(eca)
						end
						tab	= tab - 1
					end
					
				end

				--触发器
				table.insert(lines, '【Trigger】')
				for _, trigger in ipairs(chunk.triggers) do
					table.insert(lines, ('<%s>'):format(trigger.name))
					table.insert(lines, ('描述=%s'):format(trigger.des:gsub('\r\n', '@@n'):gsub('\t', '@@t')))
					table.insert(lines, ('未知1=%s'):format(trigger.int_unknow_1))
					table.insert(lines, ('允许=%s'):format(trigger.enable))
					table.insert(lines, ('自定义代码=%s'):format(trigger.wct))
					table.insert(lines, ('初始化=%s'):format(trigger.init))
					table.insert(lines, ('未知2=%s'):format(trigger.int_unknow_2))
					table.insert(lines, ('类别=%s'):format(trigger.category))

					ecas	= trigger.ecas
					index	= 1
					max		= #ecas

					--ECA结构
					while index <= max do
						local eca	= ecas[index]
						index	= index + 1
						push_eca(eca)
					end
				end
				
			end

			io.save(file_name_out, table.concat(lines, '\n'))
		end

		function w3x2txt.txt2wtg(file_name_in, file_name_out)
			local content	= io.load(file_name_in)
			if not content then
				print('文件无效:' .. file_name_in)
				return
			end

			local index = 0
			local line
			local function read()
				local _
				_, index, line	= content:find('(%C+)', index + 1)
				if line and line:match '^%s*$' then
					return read()
				end
				return line
			end

			local chunk = {}
			
			--解析文本
			do
				--版本号
				repeat
					read()
					chunk.file_ver	= line:match 'VERSION%=(.+)'
				until chunk.file_ver

				--块
				local chunk_type, trigger
				while read() do
					--local line	= line
					local name	= line:match '^%s*【%s*(%S-)%s*】%s*$'
					if name then
						chunk_type	= name
						if name == 'Global' then
							chunk.vars	= {}
						elseif name == 'Category' then
							chunk.categories	= {}
						elseif name == 'Trigger' then
							chunk.triggers	= {}
						end
						goto continue
					end

					--全局变量
					if chunk_type	== 'Global' then
						
						local type, s	= line:match '^%s*(%S-)%s+(.+)$'
						if not type then
							goto continue
						end

						local var	= {}
						table.insert(chunk.vars, var)

						var.type	= type
						var.name, s	= s:match '^([%w_]+)(.*)$'
						if s then
							var.array_size	= s:match '%[%s*(%d+)%s*%]'
							var.value	= s:match '%=%s*(.-)%s*$'
						end

						--print(var.type, var.name, var.array_size, var.value)
						goto continue
					end

					--触发器类型(文件夹)
					if chunk_type	== 'Category' then
						
						local name, id, comment	= line:match '^%s*%[(.-)%]%(%s*(%d+)%s*%)%s*([%*]*)%s*$'
						if not name then
							goto continue
						end
						
						local category	 = {}
						table.insert(chunk.categories, category)

						category.name, category.id, category.comment	= name, id, comment == '*' and 1 or 0
						--print(name, id)

						goto continue
					end

					--触发器
					if chunk_type	== 'Trigger' then
						--读取ECA(最优先解读)
						local readEca, readArg

						function readEca(is_arg, is_child)
							local type, name, enable, s	= line:match '%[%s*(%d+)%s*%]([^%*%#%[]+)([%*%#]*)(.-)$'

							--print('line:' .. line)
							if type then
								--如果整个name都是空格,那么name就是这串空格;否则去2端空格
								if not name:match '^%s*$' then
									name	= name:match '^%s*(.-)%s*$'
								end
								
								local eca	= {}
								
								--是否包含复合结构
								eca.child_eca_count	= s:match '%[%s*(%d+)%s*%]'

								if is_arg then
									--是否是参数
									is_arg.eca	= eca
								elseif is_child then
									--是否是子项
									table.insert(is_child, eca)

									--子项ID
									eca.child_id	= line:match '%(%s*(%d+)%s*%)'
								else
									table.insert(trigger.ecas, eca)
								end

								eca.type, eca.name, eca.enable	= tonumber(type), name, enable

								--读取这个ECA下有多少参数
								--print(eca.type, eca.name)
								local state_args	= function_state
								[eca.type]
								[eca.name]
								.args
								local arg_count	= #state_args
								--print(arg_count)
								eca.args	= {}

								for i = 1, arg_count do
									readArg(eca.args)
								end

								--读取这个ECA下有多少子项
								if eca.child_eca_count then
									eca.child_ecas	= {}
									--print(eca.name, eca.child_eca_count)
									for i = 1, eca.child_eca_count do
										read()
										readEca(false, eca.child_ecas)
									end
								end

								return true
							end
						end

						function readArg(args)
							local line	= read()
							local type, value, has_child	= line:match '^%s*%[%s*([%-%d]+)%s*%](.-)([%*%#]*)$'
							if type then
								local arg	= {}
								table.insert(args, arg)

								arg.type, arg.value	= tonumber(type), value:gsub('@@n', '\r\n'):gsub('@@t', '\t')

								--有子数据
								if has_child == '*' then
									--数组索引
									arg.insert_index	= 1
									--print(has_child .. ':child_index:' .. arg.value)
									arg.args	= {}
									readArg(arg.args)
								elseif has_child == '#' then
									--函数调用
									arg.insert_call		= 1
									--print(has_child .. ':child_call:' .. arg.value)

									--只有在函数调用时,参数中才会保存函数的名字
									if arg.type ~= 3 then
										arg.value = ''
									end
									
									--函数调用的实际type为2
									arg.type	= 2
									readEca(arg)
								end
							end
						end

						if readEca() then
							goto continue
						end
						
						--尝试读取触发器名字
						local name	= line:match '^%s*%<(.-)%>%s*$'
						if name then
							trigger = {}
							table.insert(chunk.triggers, trigger)

							trigger.name	= name
							trigger.ecas	= {}
							
							goto continue
						end

						--读取触发器参数
						local name, s	= line:match '^(.-)%=(.-)$'
						if name then
							trigger[name]	= s:gsub('@@n', '\r\n'):gsub('@@t', '\t')

							goto continue
						end
					end

					--全局数据
					local name, s	= line:match '^(.-)%=(.-)$'
					if name then
						chunk[name]	= s
					end

					:: continue ::
				end
			end

			--转换2进制
			local pack	= {}
			
			do
				--文件头
				table.insert(pack, ('c4l'):pack('WTG!', chunk.file_ver))

				--触发器类别
					--文件夹计数
					table.insert(pack ,('l'):pack(#chunk.categories))
					
					--遍历文件夹
					for _, category in ipairs(chunk.categories) do
						table.insert(pack, ('lzl'):pack(category.id, category.name, category.comment))
					end

				--全局变量
					--计数
					table.insert(pack, ('ll'):pack(chunk['未知1'], #chunk.vars))

					--遍历全局变量
					for _, var in ipairs(chunk.vars) do
						table.insert(pack, ('zzllllz'):pack(
							var.name,					--名字
							var.type,					--类型
							1,							--永远是1
							var.array_size and 1 or 0,	--是否是数组
							var.array_size or 1,		--数组大小(非数组是1)
							var.value and 1 or 0,		--是否有自定义初始值
							var.value or ''				--自定义初始值
						))
					end

				--触发器
					--计数
					table.insert(pack, ('l'):pack(#chunk.triggers))

					--遍历触发器
					for _, trigger in ipairs(chunk.triggers) do
						
						--触发器参数
						table.insert(pack, ('zzllllll'):pack(
							trigger.name,
							trigger['描述'],
							trigger['未知1'],
							trigger['允许'],
							trigger['自定义代码'],
							trigger['初始化'],
							trigger['未知2'],
							trigger['类别']
						))

						--ECA
							--计数
							table.insert(pack, ('l'):pack(#trigger.ecas))

							--遍历ECA
							local push_eca, push_arg
							
							function push_eca(eca)
								--类型
								table.insert(pack, ('l'):pack(eca.type))

								--如果是复合结构,插入一个整数
								if eca.child_id then
									table.insert(pack, ('l'):pack(eca.child_id))
								end

								--名字,是否允许
								table.insert(pack, ('zl'):pack(eca.name, eca.enable == '*' and 0 or 1))

								--读取参数
								for _, arg in ipairs(eca.args) do
									push_arg(arg)
								end

								--复合结构
								table.insert(pack, ('l'):pack(eca.child_eca_count or 0))

								if eca.child_eca_count then
									for _, eca in ipairs(eca.child_ecas) do
										push_eca(eca)
									end
								end
							end

							function push_arg(arg)
								table.insert(pack, ('lzl'):pack(
									arg.type,				--类型
									arg.value,				--值
									arg.insert_call or 0	--是否插入函数调用
								))

								--是否要插入函数调用
								if arg.insert_call then
									push_eca(arg.eca)

									table.insert(pack, ('l'):pack(0)) --永远是0
									return
								end

								--是否要插入数组索引
								table.insert(pack, ('l'):pack(arg.insert_index or 0))

								if arg.insert_index then
									for _, arg in ipairs(arg.args) do
										push_arg(arg)
									end
								end
								
							end
							
							for _, eca in ipairs(trigger.ecas) do
								push_eca(eca)
							end
					end

				--打包
				io.save(file_name_out, table.concat(pack))
				
			end
		end
	end

	main()
	
	return w3x2txt