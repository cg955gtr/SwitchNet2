--// Author: 8ch99
--// Date written: 25th March 2026
--// SwitchNet2

--!strict
--!native
--!optimize 2

return function()
	return {
		Size = 15,

		Read = function(buff: buffer, references: { any }, pointer: number): (TweenInfo, number)
			local time = buffer.readf32(buff, pointer)
			local styleValue = buffer.readu8(buff, pointer + 4)
			local directionValue = buffer.readu8(buff, pointer + 5)
			local repeatCount = buffer.readi32(buff, pointer + 6)
			local reverses = buffer.readu8(buff, pointer + 10) ~= 0
			local delayTime = buffer.readf32(buff, pointer + 11)

			--// Get enums
			local easingStyle = Enum.EasingStyle:FromValue(styleValue) :: Enum.EasingStyle
			local easingDirection = Enum.EasingDirection:FromValue(directionValue) :: Enum.EasingDirection

			--// Create tween info
			return TweenInfo.new(time, easingStyle, easingDirection, repeatCount, reverses, delayTime), 15
		end,

		Write = function(buff: buffer, references: { any }, pointer: number, value: TweenInfo): number
			buffer.writef32(buff, pointer, value.Time)
			buffer.writeu8(buff, pointer + 4, value.EasingStyle.Value)
			buffer.writeu8(buff, pointer + 5, value.EasingDirection.Value)
			buffer.writei32(buff, pointer + 6, value.RepeatCount)
			buffer.writeu8(buff, pointer + 10, if value.Reverses then 1 else 0)
			buffer.writef32(buff, pointer + 11, value.DelayTime)

			return 15
		end,
	}
end