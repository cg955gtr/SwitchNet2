--// Author: 8ch99
--// Date written: 25th March 2026
--// SwitchNet2

--!strict
--!native
--!optimize 2

return function()
	return {
		Size = 8,

		Read = function(buff: buffer, References: { any }, pointer: number): (Vector2, number)
			return Vector2.new(
				buffer.readf32(buff, pointer),
				buffer.readf32(buff, pointer + 4)
			), 8
		end,

		Write = function(buff: buffer, references: { any }, pointer: number, value: Vector2): number
			buffer.writef32(buff, pointer, value.X)
			buffer.writef32(buff, pointer + 4, value.Y)
			return 8
		end,
	}
end