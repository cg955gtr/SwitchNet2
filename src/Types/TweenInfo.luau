--// Author: 8ch99
--// Date written: 25th March 2026
--// SwitchNet2

--!strict
--!native
--!optimize 2

return function()
	return {
		Size = 13,

		Read = function(buff: buffer, references: { any }, pointer: number): (TweenInfo, number)
			local bitOffset: number = pointer * 8

			local time: number = buffer.readf32(buff, pointer)

			--// easing style, direction and reverse bool all stored in the same byte
			local styleValue: number = buffer.readbits(buff, bitOffset + 32, 4)
			local directionValue: number = buffer.readbits(buff, bitOffset + 36, 3)
			local reverses: boolean = buffer.readbits(buff, bitOffset + 39, 1) ~= 0

			local repeatCount: number = buffer.readi32(buff, pointer + 5)
			local delayTime: number = buffer.readf32(buff, pointer + 9)

			--// Get enums
			local easingStyle = Enum.EasingStyle:FromValue(styleValue) :: Enum.EasingStyle
			local easingDirection = Enum.EasingDirection:FromValue(directionValue) :: Enum.EasingDirection

			--// Create tween info
			return TweenInfo.new(time, easingStyle, easingDirection, repeatCount, reverses, delayTime), 13
		end,

		Write = function(buff: buffer, references: { any }, pointer: number, value: TweenInfo): number
			local bitOffset: number = pointer * 8

			buffer.writef32(buff, pointer, value.Time)

			--// easing style, direction and reverse bool all stored in the same byte
			buffer.writebits(buff, bitOffset + 32, 4, value.EasingStyle.Value)
			buffer.writebits(buff, bitOffset + 36, 3, value.EasingDirection.Value)
			buffer.writebits(buff, bitOffset + 39, 1, if value.Reverses then 1 else 0)

			buffer.writei32(buff, pointer + 5, value.RepeatCount)
			buffer.writef32(buff, pointer + 9, value.DelayTime)

			return 13
		end,
	}
end