--// Author: 8ch99
--// Date written: 25th March 2026
--// SwitchNet2

--!strict
--!native
--!optimize 2

const HEADER = "SN2\16\26"
const HEADER_SIZE = #HEADER

const BUFFER_SIZE_LIMIT = 2 ^ 21
const MAX_REFERENCES = 2 ^ 16

--// Dependencies

const Typedefs = require("./Typedefs")

--// Typedefs

type StreamType<T> = Typedefs.StreamType<T>
type Packet<T> = Typedefs.Packet<T>
type Query<T1, T2> = Typedefs.Query<T1, T2>

--// @module Byte

local function GetSizeOfType<T>(streamType: StreamType<T>, associatedData: T): number
	local size = streamType.Size
	if size then
		return size
	end

	local getSize = streamType.GetSize
	if getSize then
		return getSize(associatedData)
	end

	return 0
end



const Byte = {}
Byte.GetSizeOfType = GetSizeOfType

function Byte.CompressStreamType<T>(streamType: StreamType<T>, data: T, byteSize: number?): (buffer, { any })
	local size = byteSize or GetSizeOfType(streamType, data)
	local buff = buffer.create(size + HEADER_SIZE)
	local references = table.create(32) :: { any }
	local pointer = HEADER_SIZE

	buffer.writestring(buff, 0, HEADER)
	pointer += streamType.Write(buff, references, HEADER_SIZE, data)

	return buff, references
end

function Byte.DecompressStreamType<T>(streamType: StreamType<T>, buff: buffer, references: { any }): T
	local size = buffer.len(buff)
	assert(size <= BUFFER_SIZE_LIMIT, "buffer too large!")
	assert(buffer.readstring(buff, 0, HEADER_SIZE) == HEADER, "invalid data sequence provided (unknown header)")
	assert(#references <= MAX_REFERENCES, "too many references!")

	local value = streamType.Read(buff, references, HEADER_SIZE)

	return value
end

return Byte