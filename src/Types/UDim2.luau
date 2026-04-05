--// Author: 8ch99
--// Date written: 25th March 2026
--// SwitchNet2

--!strict
--!native
--!optimize 2

return function()
	return {
		Size = 12,

		Read = function(buff: buffer, References: { any }, pointer: number): (UDim2, number)
			return UDim2.new(
				buffer.readf32(buff, pointer),
				buffer.readi32(buff, pointer + 4),
				buffer.readf32(buff, pointer + 8),
				buffer.readi32(buff, pointer + 12)
			), 12
		end,

		Write = function(buff: buffer, references: { any }, pointer: number, value: UDim2): number
			local x, y = value.X, value.Y
			buffer.writef32(buff, pointer, x.Scale)
			buffer.writei32(buff, pointer + 4, x.Offset)
			buffer.writef32(buff, pointer + 8, y.Scale)
			buffer.writei32(buff, pointer + 12, y.Offset)
			return 12
		end,
	}
end