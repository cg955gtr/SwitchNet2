--// Author: 8ch99
--// Date written: 25th March 2026
--// SwitchNet2

--!strict
--!native
--!optimize 2

const Typedefs = require("../Typedefs")

return function<T>(valueType: Typedefs.StreamType<T>)

	const read: (buffer, { any }, number) -> (T, number) = valueType.Read
	const write: (buffer, { any }, number, T) -> number = valueType.Write

	const fixedSize: number? = valueType.Size
	const getSize: ((T) -> number)? = valueType.GetSize

	return {
		TypeName = "optional",
		TypeArgs = { valueType },
		
		GetSize = function(value: T?): number
			local size: number = 1
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
			local exists: boolean = buffer.readu8(buff, pointer) == 1
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