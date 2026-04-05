--// Author: 8ch99
--// Date written: 25th March 2026
--// SwitchNet2

--!strict
--!native
--!optimize 2

return function()
	return {
		Size = 0,

		Read = function(buff: buffer, references: { any }, pointer: number): (nil, number)
			return nil, 0
		end,

		Write = function(buff: buffer, references: { any }, pointer: number, value: nil): number
			return 0
		end,
	}
end