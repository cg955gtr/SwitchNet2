--// Author: 8ch99
--// Date written: 25th March 2026
--// SwitchNet2

--!strict
--!native
--!optimize 2

return function(size: number)
	return {
		Size = size,

		Read = function(buff: buffer, references: { any }, pointer: number): (string, number)
			return buffer.readstring(buff, pointer, size), size
		end,

		Write = function(buff: buffer, references: { any }, pointer: number, value: string): number
			buffer.writestring(buff, pointer, value, math.min(#value, size))
			return size
		end,
	}
end