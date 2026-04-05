--// Author: 8ch99
--// Date written: 25th March 2026
--// SwitchNet2

--!strict
--!native
--!optimize 2

return function()
	return {
		Size = 2,

		Read = function(buff: buffer, references: { any }, pointer: number): (number, number)
			return buffer.readi16(buff, pointer), 2
		end,

		Write = function(buff: buffer, references: { any }, pointer: number, value: number): number
			buffer.writei16(buff, pointer, value)
			return 2
		end,
	}
end