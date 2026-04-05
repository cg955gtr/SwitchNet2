--// Author: 8ch99
--// Date written: 25th March 2026
--// SwitchNet2

--!strict
--!native
--!optimize 2

return function()
	return {
		Size = 12,

		Read = function(buff: buffer, References: { any }, pointer: number): (Vector3, number)
			return Vector3.new(
				buffer.readf32(buff, pointer),
				buffer.readf32(buff, pointer + 4),
				buffer.readf32(buff, pointer + 8)
			), 12
		end,

		Write = function(buff: buffer, references: { any }, pointer: number, value: Vector3): number
			buffer.writef32(buff, pointer, value.X)
			buffer.writef32(buff, pointer + 4, value.Y)
			buffer.writef32(buff, pointer + 8, value.Z)
			return 12
		end,
	}
end