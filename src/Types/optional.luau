--// Author: 8ch99
--// Date written: 25th March 2026
--// SwitchNet2

--!strict
--!native
--!optimize 2

local Typedefs = require("../Typedefs")

return function<T>(valueType: Typedefs.StreamType<T>)
	local read = valueType.Read
	local write = valueType.Write
	
	local fixedSize = valueType.Size
	local getSize = valueType.GetSize

	return {
		TypeName = "optional",
		TypeArgs = { valueType },
		
		GetSize = function(value: T?): number
			local size = 1
			if not value then
				return size
			end
			
			if fixedSize then
				size += fixedSize
			elseif getSize then
				size += getSize(value)
			end

			return size
		end,

		Read = function(buff: buffer, references: { any }, pointer: number): (T?, number)
			local exists = buffer.readu8(buff, pointer) == 1
			if exists then
				local value, offset = read(buff, references, pointer + 1)
				return value, offset + 1
			end
			return nil, 1
		end,

		Write = function(buff: buffer, references: { any }, pointer: number, value: T?): number
			buffer.writeu8(buff, pointer, if value ~= nil then 1 else 0)
			if value then
				return 1 + write(buff, references, pointer + 1, value :: T)
			end
			return 1
		end,
	}
end