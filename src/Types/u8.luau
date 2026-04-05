--// Author: 8ch99
--// Date written: 25th March 2026
--// SwitchNet2

--!strict
--!native
--!optimize 2

return function()
	return {
		Size = 1,

		Read = function(buff: buffer, references: { any }, pointer: number): (number, number)
			return buffer.readu8(buff, pointer), 1
		end,

		Write = function(buff: buffer, references: { any }, pointer: number, value: number): number
			buffer.writeu8(buff, pointer, value)
			return 1
		end,
	}
end