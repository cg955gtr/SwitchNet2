--// Author: 8ch99
--// Date written: 25th March 2026
--// SwitchNet2

--!strict
--!native
--!optimize 2

return function()
	return {
		Size = 12,

		Read = function(buff: buffer, References: { any }, pointer: number): (vector, number)
			return vector.create(
				buffer.readf32(buff, pointer),
				buffer.readf32(buff, pointer + 4),
				buffer.readf32(buff, pointer + 8)
			), 12
		end,

		Write = function(buff: buffer, references: { any }, pointer: number, value: vector): number
			buffer.writef32(buff, pointer, value.x)
			buffer.writef32(buff, pointer + 4, value.y)
			buffer.writef32(buff, pointer + 8, value.z)
			return 12
		end,
	}
end