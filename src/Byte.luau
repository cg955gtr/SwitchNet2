--// Author: 8ch99
--// Date written: 25th March 2026
--// SwitchNet2

--!strict
--!native
--!optimize 2

--// Constants

const HEADER: string = "SN2\16\26"
const HEADER_SIZE: number = #HEADER

const REFERENCES_PRE_ALLOC_SIZE: number = 32

--// Dependencies

const Constants = require("./Constants")
const Typedefs = require("./Typedefs")

--// Typedefs

type StreamType<T> = Typedefs.StreamType<T>
type Packet<T> = Typedefs.Packet<T>
type Query<T1, T2> = Typedefs.Query<T1, T2>

--// @module Byte

const function getSizeOfType<T>(streamType: StreamType<T>, associatedData: T): number
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

const function compressStreamType<T>(streamType: StreamType<T>, data: T, byteSize: number?): (buffer, { any })
	local size: number = byteSize or getSizeOfType(streamType, data)
	assert(size <= Constants.BUFFER_SIZE_LIMIT, "buffer too large!")

	local buff: buffer = buffer.create(size + HEADER_SIZE)
	local references: { any } = table.create(REFERENCES_PRE_ALLOC_SIZE) --:: { any }

	buffer.writestring(buff, 0, HEADER)
	streamType.Write(buff, references, HEADER_SIZE, data)

	return buff, references
end

const function decompressStreamType<T>(streamType: StreamType<T>, buff: buffer, references: { any }): T
	local size: number = buffer.len(buff)
	assert(size <= Constants.BUFFER_SIZE_LIMIT, "buffer too large!")
	assert(buffer.readstring(buff, 0, HEADER_SIZE) == HEADER, "invalid data sequence provided (unknown header)")
	assert(#references <= Constants.MAX_REFERENCES, "too many references!")

	return (streamType.Read(buff, references, HEADER_SIZE))
end


return {
	GetSizeOfType = getSizeOfType,
	CompressStreamType = compressStreamType,
	DecompressStreamType = decompressStreamType,
}