--// Author: 8ch99
--// Date written: 25th March 2026
--// SwitchNet2

--!strict
--!native
--!optimize 2

local enumNames: { string } = {}
for _, list in Enum:GetEnums() do
	table.insert(enumNames, tostring(list))
end
table.sort(enumNames) --// mandate same order between contexts


const enumLookup: { Enum } = {}
const reverseEnumLookup: { [Enum]: number } = {}

for index, name in enumNames do
	local enum = Enum[name]
	enumLookup[index] = enum
	reverseEnumLookup[enum] = index
end

table.clear(enumNames)
enumNames = nil :: never



return function()
	return {
		Size = 6,

		Read = function(buff: buffer, references: { any }, pointer: number): (EnumItem, number)
			local value: number = buffer.readu32(buff, pointer)
			local listValue: number = buffer.readu16(buff, pointer + 4)

			return (enumLookup[listValue] :: any):FromValue(value), 6
		end,

		Write = function(buff: buffer, references: { any }, pointer: number, value: EnumItem): number
			buffer.writeu32(buff, pointer, value.Value)
			buffer.writeu16(buff, pointer + 4, reverseEnumLookup[value.EnumType])
			
			return 6
		end,
	}
end