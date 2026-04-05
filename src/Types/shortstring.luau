--// Author: 8ch99
--// Date written: 25th March 2026
--// SwitchNet2

--!strict
--!native
--!optimize 2

return function()
	return {
		GetSize = function(value: string): number
			return 1 + #value
		end,

		Read = function(buff: buffer, references: { any }, pointer: number): (string, number)
			local size = buffer.readu8(buff, pointer)
			if size == 0 then
				return "", 1
			end
			return buffer.readstring(buff, pointer + 1, size), 1 + size
		end,

		Write = function(buff: buffer, references: { any }, pointer: number, value: string): number
			local size = #value
			buffer.writeu8(buff, pointer, size)
			if size > 0 then
				buffer.writestring(buff, pointer + 1, value)
			end
			return 1 + size
		end,
	}
end