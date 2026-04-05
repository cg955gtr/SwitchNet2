--// Author: 8ch99
--// Date written: 25th March 2026
--// SwitchNet2

--!strict
--!native
--!optimize 2

return function()
	return {
		GetSize = function(value: buffer): number
			return 2 + buffer.len(value)
		end,

		Read = function(buff: buffer, references: { any }, pointer: number): (buffer, number)
			local size = buffer.readu16(buff, pointer)
			local newBuffer = buffer.create(size)
			if size == 0 then
				return newBuffer, 2
			end
			
			buffer.copy(newBuffer, 0, buff, pointer + 2, size)
			return newBuffer, 2 + size
		end,

		Write = function(buff: buffer, references: { any }, pointer: number, value: buffer): number
			local size = buffer.len(value)
			buffer.writeu16(buff, pointer, size)
			if size > 0 then
				buffer.copy(buff, pointer + 2, value, size)
			end
			return 2 + size
		end,
	}
end