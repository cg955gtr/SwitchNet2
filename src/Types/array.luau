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
		TypeName = "array",
		TypeArgs = { valueType },
		
		GetSize = function(value: { T }): number
			if fixedSize then
				return 2 + (fixedSize * #value)
			end
			local size: number = 2
			if getSize then
				for _, arrayValue in value do
					size += getSize(arrayValue)
				end
			end
			return size
		end,

		Read = function(buff: buffer, references: { any }, pointer: number): ({ T }, number)
			local size: number = buffer.readu16(buff, pointer)
			local value: { T } = table.create(size)
			if size == 0 then
				return value, 2
			end

			local basePointer: number = pointer
			pointer += 2

			for i: number = 1, size do
				local arrayValue: T, offset: number = read(buff, references, pointer)
				value[i] = arrayValue
				pointer += offset
			end

			return value, pointer - basePointer
		end,

		Write = function(buff: buffer, references: { any }, pointer: number, value: { T }): number
			buffer.writeu16(buff, pointer, #value)
			local basePointer: number = pointer
			pointer += 2

			for _, arrayValue: T in value do
				pointer += write(buff, references, pointer, arrayValue)
			end

			return pointer - basePointer
		end,
	}

end