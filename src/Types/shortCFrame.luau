--// Author: 8ch99
--// Date written: 3rd May 2026
--// SwitchNet2

--!strict
--!native
--!optimize 2

const POW_FLAT_2_21: number = 2 ^ 21 - 1
const POW_FLAT_2_20: number = 2 ^ 20 - 1


const function readSignedBits(buff: buffer, bitOffset: number, bitCount: number): number
	return buffer.readbits(buff, bitOffset, bitCount) - (2 ^ (bitCount - 1))
end

const function writeSignedBits(buff: buffer, bitOffset: number, bitCount: number, value: number)
	buffer.writebits(buff, bitOffset, bitCount, value + (2 ^ (bitCount - 1)))
end



return {
	Size = 20,

	Read = function(buff: buffer, References: { any }, pointer: number): (CFrame, number)
		local x: number, y: number, z: number =
			buffer.readf32(buff, pointer),
			buffer.readf32(buff, pointer + 4),
			buffer.readf32(buff, pointer + 8)

		local bitOffset: number = (pointer + 12) * 8
		local rX: number, rY: number, rZ: number =
			readSignedBits(buff, bitOffset, 22),
			readSignedBits(buff, bitOffset + 22, 21),
			readSignedBits(buff, bitOffset + 43, 21)
		local rotation: CFrame = CFrame.fromEulerAnglesXYZ(
			(rX / POW_FLAT_2_21) * math.pi,
			(rY / POW_FLAT_2_20) * math.pi,
			(rZ / POW_FLAT_2_20) * (math.pi / 2)
		)

		return CFrame.new(x, y, z) * rotation, 20
	end,

	Write = function(buff: buffer, references: { any }, pointer: number, value: CFrame): number
		buffer.writef32(buff, pointer, value.X)
		buffer.writef32(buff, pointer + 4, value.Y)
		buffer.writef32(buff, pointer + 8, value.Z)

		local bitOffset: number = (pointer + 12) * 8
		local rX: number, rY: number, rZ: number = value:ToEulerAnglesXYZ()

		writeSignedBits(buff, bitOffset, 22, math.round((rX / math.pi) * POW_FLAT_2_21))
		writeSignedBits(buff, bitOffset + 22, 21, math.round((rY / math.pi) * POW_FLAT_2_20))
		writeSignedBits(buff, bitOffset + 43, 21, math.round((rZ / (math.pi / 2)) * POW_FLAT_2_20))

		return 20
	end,
}