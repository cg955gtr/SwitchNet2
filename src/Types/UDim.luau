--// Author: 8ch99
--// Date written: 25th March 2026
--// SwitchNet2

--!strict
--!native
--!optimize 2

return function()
	return {
		Size = 8,

		Read = function(buff: buffer, References: { any }, pointer: number): (UDim, number)
			return UDim.new(
				buffer.readf32(buff, pointer),
				buffer.readi32(buff, pointer + 4)
			), 8
		end,

		Write = function(buff: buffer, references: { any }, pointer: number, value: UDim): number
			buffer.writef32(buff, pointer, value.Scale)
			buffer.writei32(buff, pointer + 4, value.Offset)
			return 8
		end,
	}
end