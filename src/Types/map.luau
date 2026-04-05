--// Author: 8ch99
--// Date written: 25th March 2026
--// SwitchNet2

--!strict
--!native
--!optimize 2

local Typedefs = require("../Typedefs")

return function<T1, T2>(keyType: Typedefs.StreamType<T1>, valueType: Typedefs.StreamType<T2>)
	local readKey = keyType.Read
	local writeKey = keyType.Write
	local readValue = valueType.Read
	local writeValue = valueType.Write
	
	local fixedKeySize = keyType.Size
	local getKeySize = keyType.GetSize
	local fixedValueSize = valueType.Size
	local getValueSize = valueType.GetSize

	return {
		TypeName = "map",
		TypeArgs = { keyType, valueType } :: { Typedefs.StreamType<any> },

		GetSize = function(value: { [T1]: T2 }): number
			local size = 2
			local count = 0
			for _ in value do
				count += 1
			end

			if fixedKeySize then
				size += fixedKeySize * count
			elseif getKeySize then
				for mapKey in value do
					size += getKeySize(mapKey)
				end
			end

			if fixedValueSize then
				size += fixedValueSize * count
			elseif getValueSize then
				for _, mapValue in value do
					size += getValueSize(mapValue)
				end
			end

			return size
		end,

		Read = function(buff: buffer, references: { any }, pointer: number): ({ [T1]: T2 }, number)
			local pointerOffset = 2
			local size = buffer.readu16(buff, pointer)
			if size == 0 then
				return {}, pointerOffset
			end

			local value = {} :: { [T1]: T2 }

			for i = 1, size do
				local mapKey, keyOffset = readKey(buff, references, pointer + pointerOffset)
				pointerOffset += keyOffset
				local mapValue, valueOffset = readValue(buff, references, pointer + pointerOffset)
				pointerOffset += valueOffset

				value[mapKey] = mapValue
			end

			return value, pointerOffset
		end,

		Write = function(buff: buffer, references: { any }, pointer: number, value: { [T1]: T2 }): number
			local count = 0
			for _ in value do
				count += 1
			end
			buffer.writeu16(buff, pointer, count)

			local basePointer = pointer
			pointer += 2
			
			for mapKey, mapValue in value do
				pointer += writeKey(buff, references, pointer, mapKey)
				pointer += writeValue(buff, references, pointer, mapValue)
			end

			return pointer - basePointer
		end,
	}
end