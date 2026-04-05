--// Author: 8ch99
--// Date written: 25th March 2026
--// SwitchNet2

--!strict
--!native
--!optimize 2

return function()
	return {
		Size = 6,

		Read = function(buff: buffer, References: { any }, pointer: number): (Vector3int16, number)
			return Vector3int16.new(
				buffer.readi16(buff, pointer),
				buffer.readi16(buff, pointer + 2),
				buffer.readi16(buff, pointer + 4)
			), 6
		end,

		Write = function(buff: buffer, references: { any }, pointer: number, value: Vector3int16): number
			buffer.writei16(buff, pointer, value.X)
			buffer.writei16(buff, pointer + 2, value.Y)
			buffer.writei16(buff, pointer + 4, value.Z)
			return 6
		end,
	}
end