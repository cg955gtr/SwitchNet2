--// Author: 8ch99
--// Date written: 25th March 2026
--// SwitchNet2

--!strict
--!native
--!optimize 2

return function()
	return {
		Size = 1,

		Read = function(buff: buffer, references: { any }, pointer: number): (boolean, number)
			return buffer.readu8(buff, pointer) ~= 0, 1
		end,

		Write = function(buff: buffer, references: { any }, pointer: number, value: boolean): number
			buffer.writeu8(buff, pointer, if value then 1 else 0)
			return 1
		end,
	}
end