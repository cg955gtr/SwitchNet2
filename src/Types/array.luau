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
		TypeName = "array",
		TypeArgs = { valueType },
		
		GetSize = function(value: { T }): number
			if fixedSize then
				return 2 + (fixedSize * #value)
			end
			local size = 2
			for _, arrayValue in value do
				size += (getSize :: (T) -> number)(arrayValue)
			end
			return size
		end,

		Read = function(buff: buffer, references: { any }, pointer: number): ({ T }, number)
			local size = buffer.readu16(buff, pointer)
			local value = table.create(size) :: { T }
			if size == 0 then
				return value, 2
			end

			local basePointer = pointer
			pointer += 2

			for i = 1, size do
				local arrayValue, offset = read(buff, references, pointer)
				value[i] = arrayValue
				pointer += offset
			end

			return value, pointer - basePointer
		end,

		Write = function(buff: buffer, references: { any }, pointer: number, value: { T }): number
			buffer.writeu16(buff, pointer, #value)
			local basePointer = pointer
			pointer += 2

			for _, arrayValue in value do
				pointer += write(buff, references, pointer, arrayValue)
			end

			return pointer - basePointer
		end,
	}
end