--// Author: 8ch99
--// Date written: 25th March 2026
--// SwitchNet2

--!strict
--!native
--!optimize 2

type StructReader = (buff: buffer, references: { any }?, pointer: number) -> (any, number)
type StructWriter = (buff: buffer, references: { any }?, pointer: number, value: any) -> number

const Typedefs = require("../Typedefs")


return function(struct: { [string]: Typedefs.StreamType<any> })

	const order: { string } = {}
	for key, streamType in struct do
		table.insert(order, key)
	end

	const count: number = #order

	--// I want to absolutely mandate everything is in the same order, so both client and server
	--// are reading in the same order
	table.sort(order)

	--// Construct other memoized data
	const readers: { StructReader } = table.create(count)
	const writers: { StructWriter } = table.create(count)
	const sizes: { number } = table.create(count)
	const sizeMethods: { (any) -> number } = table.create(count)

	for index, key in order do
		local streamType: Typedefs.StreamType<any> = struct[key]
		readers[index] = streamType.Read
		writers[index] = streamType.Write

		if streamType.Size then
			sizes[index] = streamType.Size
		end
		if streamType.GetSize then
			sizeMethods[index] = streamType.GetSize
		end
	end


	local typeArray: { Typedefs.StreamType<any> } = {}
	for _, streamType in struct do
		table.insert(typeArray, streamType)
	end


	return {
		TypeName = "struct",
		TypeArgs = typeArray,

		GetSize = function(value: { [string]: any }): number
			local size: number = 0
			for _, typeSize: number in sizes do
				size += typeSize
			end

			for index: number, getSize: (any) -> number in sizeMethods do
				size += getSize(value[order[index]])
			end

			return size
		end,

		Read = function(buff: buffer, references: { any }, pointer: number): ({ [string]: any }, number)
			local basePointer: number = pointer
			local value: { [string]: any } = table.clone(struct)

			for index: number, read: StructReader in readers do
				local name: string = order[index]
				local structValue: any, offset: number = read(buff, references, pointer)
				value[name] = structValue
				pointer += offset
			end

			return value, pointer - basePointer
		end,

		Write = function(buff: buffer, references: { any }, pointer: number, value: { [string]: any }): number
			local basePointer = pointer

			for index: number, write: StructWriter in writers do
				pointer += write(buff, references, pointer, value[order[index]])
			end

			return pointer - basePointer
		end,
	}

end