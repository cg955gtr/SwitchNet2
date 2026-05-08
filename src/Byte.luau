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

local function getSizeOfType<T>(streamType: StreamType<T>, associatedData: T): number
	local size: number? = streamType.Size
	if size then
		return size
	end

	local getSize: ((T) -> number)? = streamType.GetSize
	if getSize then
		return getSize(associatedData)
	end

	return 0
end



const Byte = {
	GetSizeOfType = getSizeOfType
}

function Byte.CompressStreamType<T>(streamType: StreamType<T>, data: T, byteSize: number?): (buffer, { any })
	local size: number = byteSize or getSizeOfType(streamType, data)
	local buff: buffer = buffer.create(size + HEADER_SIZE)
	local references: { any } = table.create(32) :: { any }

	buffer.writestring(buff, 0, HEADER)
	streamType.Write(buff, references, HEADER_SIZE, data)

	return buff, references
end

function Byte.DecompressStreamType<T>(streamType: StreamType<T>, buff: buffer, references: { any }): T
	local size: number = buffer.len(buff)
	assert(size <= BUFFER_SIZE_LIMIT, "buffer too large!")
	assert(buffer.readstring(buff, 0, HEADER_SIZE) == HEADER, "invalid data sequence provided (unknown header)")
	assert(#references <= MAX_REFERENCES, "too many references!")

	local value = streamType.Read(buff, references, HEADER_SIZE)

	return value
end

return Byte