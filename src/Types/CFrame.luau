--// Author: 8ch99
--// Date written: 25th March 2026
--// SwitchNet2

--!strict
--!native
--!optimize 2

return function()
	return {
		Size = 24,

		Read = function(buff: buffer, References: { any }, pointer: number): (CFrame, number)
			return CFrame.new(
				buffer.readf32(buff, pointer),
				buffer.readf32(buff, pointer + 4),
				buffer.readf32(buff, pointer + 8)
			) * CFrame.fromEulerAnglesXYZ(
				buffer.readf32(buff, pointer + 12),
				buffer.readf32(buff, pointer + 16),
				buffer.readf32(buff, pointer + 20)
			), 24
		end,

		Write = function(buff: buffer, references: { any }, pointer: number, value: CFrame): number
			local rX, rY, rZ = value:ToEulerAnglesXYZ()

			buffer.writef32(buff, pointer, value.X)
			buffer.writef32(buff, pointer + 4, value.Y)
			buffer.writef32(buff, pointer + 8, value.Z)
			buffer.writef32(buff, pointer + 12, rX)
			buffer.writef32(buff, pointer + 16, rY)
			buffer.writef32(buff, pointer + 20, rZ)

			return 24
		end,
	}
end