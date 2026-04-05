--// Author: 8ch99
--// Date written: 25th March 2026
--// SwitchNet2

--!strict
--!native
--!optimize 2

return function()
	return {
		Size = 4,

		Read = function(buff: buffer, references: { any }, pointer: number): (number, number)
			return buffer.readu32(buff, pointer), 4
		end,

		Write = function(buff: buffer, references: { any }, pointer: number, value: number): number
			buffer.writeu32(buff, pointer, value)
			return 4
		end,
	}
end