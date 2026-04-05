--// Author: 8ch99
--// Date written: 25th March 2026
--// SwitchNet2

--!strict
--!native
--!optimize 2

return function()
	return {
		GetSize = function(value: string): number
			return 2 + #value
		end,

		Read = function(buff: buffer, references: { any }, pointer: number): (string, number)
			local size = buffer.readu16(buff, pointer)
			if size == 0 then
				return "", 2
			end
			return buffer.readstring(buff, pointer + 2, size), 2 + size
		end,

		Write = function(buff: buffer, references: { any }, pointer: number, value: string): number
			local size = #value
			buffer.writeu16(buff, pointer, size)
			if size > 0 then
				buffer.writestring(buff, pointer + 2, value)
			end
			return 2 + size
		end,
	}
end