--// Author: 8ch99
--// Date written: 25th March 2026
--// SwitchNet2

--!strict
--!native
--!optimize 2

return function()
	return {
		Size = 8,

		Read = function(buff: buffer, References: { any }, pointer: number): (NumberRange, number)
			return NumberRange.new(
				buffer.readf32(buff, pointer),
				buffer.readf32(buff, pointer + 4)
			), 8
		end,

		Write = function(buff: buffer, references: { any }, pointer: number, value: NumberRange): number
			buffer.writef32(buff, pointer, value.Min)
			buffer.writef32(buff, pointer + 4, value.Max)
			return 8
		end,
	}
end