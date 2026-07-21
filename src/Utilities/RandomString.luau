--// Author: 8ch99
--// Date written: 7th May 2026
--// Very fast random string generator

--!strict
--!native
--!optimize 2

const DEFAULT_SIZE_MIN: number = 5
const DEFAULT_SIZE_MAX: number = 24
const CHAR_RANGE_MIN: number = 36
const CHAR_RANGE_MAX: number = 122

const function randomString(length: number?): string
	
	local randomStringSize: number = length or math.random(DEFAULT_SIZE_MIN, DEFAULT_SIZE_MAX)
	local randomStringBuffer: buffer = buffer.create(randomStringSize)

	for i: number = 0, randomStringSize - 1 do
		local randomByte: number = math.random(CHAR_RANGE_MIN, CHAR_RANGE_MAX)
		buffer.writeu8(randomStringBuffer, i, randomByte)
	end

	return buffer.tostring(randomStringBuffer)

end

return randomString