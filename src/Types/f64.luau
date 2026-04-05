--// Author: 8ch99
--// Date written: 25th March 2026
--// SwitchNet2

--!strict
--!native
--!optimize 2

return function()
	return {
		Size = 8,

		Read = function(buff: buffer, references: { any }, pointer: number): (number, number)
			return buffer.readf64(buff, pointer), 8
		end,

		Write = function(buff: buffer, references: { any }, pointer: number, value: number): number
			buffer.writef64(buff, pointer, value)
			return 8
		end,
	}
end