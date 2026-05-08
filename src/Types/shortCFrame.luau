--// Author: 8ch99
--// Date written: 3rd May 2026
--// SwitchNet2

--// credit to stravant/tnavarts for the rotation matrix compression method (rotation > azimuth,roll,elevation, compressed to 64 bits)
--// This is not lossless like the main CFrame method, but will use 4 less bytes

--!strict
--!native
--!optimize 2

const POW_FLAT_2_21: number = 2 ^ 21 - 1
const POW_FLAT_2_20: number = 2 ^ 20 - 1


local function readSignedBits(buff: buffer, bitOffset: number, bitCount: number): number
	return buffer.readbits(buff, bitOffset, bitCount) - (2 ^ (bitCount - 1))
end

local function writeSignedBits(buff: buffer, bitOffset: number, bitCount: number, value: number)
	buffer.writebits(buff, bitOffset, bitCount, value + (2 ^ (bitCount - 1)))
end



local function cframeRotationToAzimuthRollElevation(cframe: CFrame): (number, number, number)
	local lookVector: Vector3 = cframe.LookVector
	local lookVectorX: number, lookVectorY: number, lookVectorZ: number = lookVector.X, lookVector.Y, lookVector.Z

	local azimuth: number = math.atan2(-lookVectorX, -lookVectorZ)
	local elevation: number = math.atan2(lookVectorY, (lookVectorX ^ 2 + lookVectorZ ^ 2) ^ 0.5)

	local withoutRoll: CFrame = CFrame.new(cframe.Position) * CFrame.fromEulerAnglesXYZ(elevation, azimuth, 0)
	local _, _, roll: number = (withoutRoll:Inverse() * cframe):ToEulerAnglesXYZ()

	return
		math.round((azimuth / math.pi) * POW_FLAT_2_21),
		math.round((roll / math.pi) * POW_FLAT_2_20),
		math.round((elevation / (math.pi / 2)) * POW_FLAT_2_20)
end

local function azimuthRollElevationToCFrameRotation(azimuth: number, roll: number, elevation: number): CFrame
	azimuth, roll, elevation =
		(azimuth / POW_FLAT_2_21) * math.pi,
		(roll / POW_FLAT_2_20) * math.pi,
		(elevation / POW_FLAT_2_20) * (math.pi / 2)

	--return CFrame.fromEulerAnglesXYZ(0, azimuth, 0)
	--	* CFrame.fromEulerAnglesXYZ(elevation, 0, 0)
	--	* CFrame.fromEulerAnglesXYZ(0, 0, roll)
	return CFrame.fromEulerAnglesXYZ(0, azimuth, 0)
		* CFrame.fromEulerAnglesXYZ(elevation, 0, roll)
end


return {
	Size = 20,

	Read = function(buff: buffer, References: { any }, pointer: number): (CFrame, number)
		local x: number, y: number, z: number =
			buffer.readf32(buff, pointer),
			buffer.readf32(buff, pointer + 4),
			buffer.readf32(buff, pointer + 8)

		local bitOffset: number = (pointer + 12) * 8
		local azimuth: number, roll: number, elevation: number =
			readSignedBits(buff, bitOffset, 22),
			readSignedBits(buff, bitOffset + 22, 21),
			readSignedBits(buff, bitOffset + 43, 21)

		return CFrame.new(x, y, z) * azimuthRollElevationToCFrameRotation(azimuth, roll, elevation), 20
	end,

	Write = function(buff: buffer, references: { any }, pointer: number, value: CFrame): number
		buffer.writef32(buff, pointer, value.X)
		buffer.writef32(buff, pointer + 4, value.Y)
		buffer.writef32(buff, pointer + 8, value.Z)

		local bitOffset: number = (pointer + 12) * 8
		local azimuth: number, roll: number, elevation: number = cframeRotationToAzimuthRollElevation(value)

		writeSignedBits(buff, bitOffset, 22, azimuth)
		writeSignedBits(buff, bitOffset + 22, 21, roll)
		writeSignedBits(buff, bitOffset + 43, 21, elevation)

		return 20
	end,
}