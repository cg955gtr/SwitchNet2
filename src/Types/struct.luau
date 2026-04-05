--// Author: 8ch99
--// Date written: 25th March 2026
--// SwitchNet2

--!strict
--!native
--!optimize 2

type StructReader = (buff: buffer, references: { any }?, pointer: number) -> (any, number)
type StructWriter = (buff: buffer, references: { any }?, pointer: number, value: any) -> number

local Typedefs = require("../Typedefs")


return function(struct: { [string]: Typedefs.StreamType<any> })

	local order = {} :: { string }
	for key, streamType in struct do
		table.insert(order, key)
	end

	local count = #order

	--// I want to absolutely mandate everything is in the same order, so both client and server
	--// are reading in the same order
	table.sort(order)

	--// Construct other memoized data
	local readers = table.create(count) :: { StructReader }
	local writers = table.create(count) :: { StructWriter }
	local sizes = table.create(count) :: { number }
	local sizeMethods = table.create(count) :: { (any) -> number }

	for index, key in order do
		local streamType = struct[key]
		readers[index] = streamType.Read
		writers[index] = streamType.Write

		if streamType.Size then
			sizes[index] = streamType.Size
		end
		if streamType.GetSize then
			sizeMethods[index] = streamType.GetSize
		end
	end


	local typeArray = {} :: { Typedefs.StreamType<any> }
	for _, streamType in struct do
		table.insert(typeArray, streamType)
	end


	return {
		TypeName = "struct",
		TypeArgs = typeArray,

		GetSize = function(value: { [string]: any }): number
			local size = 0
			for _, typeSize in sizes do
				size += typeSize
			end

			for index, getSize in sizeMethods do
				size += getSize(value[order[index]])
			end

			return size
		end,

		Read = function(buff: buffer, references: { any }, pointer: number): ({ [string]: any }, number)
			local basePointer = pointer
			local value = table.clone(struct) :: { [string]: any }

			for index, read in readers do
				local name = order[index]
				local structValue, offset = read(buff, references, pointer)
				value[name] = structValue
				pointer += offset
			end

			return value, pointer - basePointer
		end,

		Write = function(buff: buffer, references: { any }, pointer: number, value: { [string]: any }): number
			local basePointer = pointer

			for index, write in writers do
				pointer += write(buff, references, pointer, value[order[index]])
			end

			return pointer - basePointer
		end,
	}

end