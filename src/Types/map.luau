--// Author: 8ch99
--// Date written: 25th March 2026
--// SwitchNet2

--!strict
--!native
--!optimize 2

const Typedefs = require("../Typedefs")

return function<T1, T2>(keyType: Typedefs.StreamType<T1>, valueType: Typedefs.StreamType<T2>)

	const readKey: (buffer, { any }, number) -> (T1, number) = keyType.Read
	const writeKey: (buffer, { any }, number, T1) -> number = keyType.Write
	const readValue: (buffer, { any }, number) -> (T2, number) = valueType.Read
	const writeValue: (buffer, { any }, number, T2) -> number = valueType.Write
	
	const fixedKeySize: number? = keyType.Size
	const getKeySize: ((T1) -> number)? = keyType.GetSize
	const fixedValueSize: number? = valueType.Size
	const getValueSize: ((T2) -> number)? = valueType.GetSize

	return {
		TypeName = "map",
		TypeArgs = { keyType, valueType } :: { Typedefs.StreamType<any> },

		GetSize = function(value: { [T1]: T2 }): number

			local size: number = 2
			local count: number = 0
			
			if fixedKeySize or fixedValueSize then
				--// get count
				for _ in value do
					count += 1
				end
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

			local pointerOffset: number = 2
			local size: number = buffer.readu16(buff, pointer)
			if size == 0 then
				return {}, pointerOffset
			end

			local value: { [T1]: T2 } = {}

			for i: number = 1, size do
				local mapKey: T1, keyOffset: number = readKey(buff, references, pointer + pointerOffset)
				pointerOffset += keyOffset
				local mapValue: T2, valueOffset: number = readValue(buff, references, pointer + pointerOffset)
				pointerOffset += valueOffset

				value[mapKey] = mapValue
			end

			return value, pointerOffset

		end,

		Write = function(buff: buffer, references: { any }, pointer: number, value: { [T1]: T2 }): number
			
			local count: number = 0
			for _ in value do
				count += 1
			end
			buffer.writeu16(buff, pointer, count)

			local basePointer: number = pointer
			pointer += 2
			
			for mapKey: T1, mapValue: T2 in value do
				pointer += writeKey(buff, references, pointer, mapKey)
				pointer += writeValue(buff, references, pointer, mapValue)
			end

			return pointer - basePointer

		end,
	}

end