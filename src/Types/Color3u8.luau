--// Author: 8ch99
--// Date written: 25th March 2026
--// SwitchNet2

--!strict
--!native
--!optimize 2

return function()
	return {
		Size = 3,

		Read = function(buff: buffer, References: { any }, pointer: number): (Color3, number)
			return Color3.fromRGB(
				buffer.readu8(buff, pointer),
				buffer.readu8(buff, pointer + 1),
				buffer.readu8(buff, pointer + 2)
			), 3
		end,

		Write = function(buff: buffer, references: { any }, pointer: number, value: Color3): number
			buffer.writeu8(buff, pointer, math.floor(value.R * 255))
			buffer.writeu8(buff, pointer + 1, math.floor(value.G * 255))
			buffer.writeu8(buff, pointer + 2, math.floor(value.B * 255))
			return 3
		end,
	}
end