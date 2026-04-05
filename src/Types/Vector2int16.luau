--// Author: 8ch99
--// Date written: 25th March 2026
--// SwitchNet2

--!strict
--!native
--!optimize 2

return function()
	return {
		Size = 4,

		Read = function(buff: buffer, References: { any }, pointer: number): (Vector2int16, number)
			return Vector2int16.new(
				buffer.readi16(buff, pointer),
				buffer.readi16(buff, pointer + 2)
			), 4
		end,

		Write = function(buff: buffer, references: { any }, pointer: number, value: Vector2int16): number
			buffer.writei16(buff, pointer, value.X)
			buffer.writei16(buff, pointer + 2, value.Y)
			return 4
		end,
	}
end