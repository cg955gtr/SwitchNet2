--// Author: 8ch99
--// Date written: 25th March 2026
--// SwitchNet2

--!strict
--!native
--!optimize 2

--// Dependencies

const Byte = require("./Byte")
const Typedefs = require("./Typedefs")

--// Typedefs

type StreamType<T> = Typedefs.StreamType<T>
type StreamTypeWithArgs<T> = Typedefs.StreamTypeWithArgs<T>

type Packet<T> = Typedefs.Packet<T>
type Query<T1, T2> = Typedefs.Query<T1, T2>

--// @module Types

const types = {
	null = require("./Types/null") :: nil,

	optional = require("./Types/optional") :: <T>(optType: T) -> T?,
	array = require("./Types/array") :: <T>(array: T) -> { T },
	map = require("./Types/map") :: <T1, T2>(keyType: T1, valueType: T2) -> { [T1]: T2 },
	struct = require("./Types/struct") :: <T>(struct: T) -> T,

	unknown = require("./Types/unknown")() :: unknown,

	boolean = require("./Types/boolean")() :: boolean,
	buffer = require("./Types/buffer")() :: buffer,

	string = require("./Types/string")() :: string,
	shortstring = require("./Types/shortstring")() :: string,
	fixedstring = require("./Types/fixedstring") :: (size: number) -> string,

	u8 = require("./Types/u8")() :: number,
	i8 = require("./Types/i8")() :: number,
	u16 = require("./Types/u16")() :: number,
	i16 = require("./Types/i16")() :: number,
	u32 = require("./Types/u32")() :: number,
	i32 = require("./Types/i32")() :: number,
	f32 = require("./Types/f32")() :: number,
	f64 = require("./Types/f64")() :: number,

	EnumItem = require("./Types/EnumItem")() :: EnumItem,

	CFrame = require("./Types/CFrame")() :: CFrame,
	shortCFrame = require("./Types/shortCFrame") :: CFrame,

	vector = require("./Types/vector")() :: vector,

	Vector2 = require("./Types/Vector2")() :: Vector2,
	Vector3 = require("./Types/Vector3")() :: Vector3,
	Vector2int16 = require("./Types/Vector2int16")() :: Vector2int16,
	Vector3int16 = require("./Types/Vector3int16")() :: Vector3int16,

	UDim = require("./Types/UDim")() :: UDim,
	UDim2 = require("./Types/UDim2")() :: UDim2,

	Color3 = require("./Types/Color3")() :: Color3,
	Color3u8 = require("./Types/Color3u8")() :: Color3,

	TweenInfo = require("./Types/TweenInfo")() :: TweenInfo,

	NumberRange = require("./Types/NumberRange")() :: NumberRange,

	Instance = require("./Types/Instance")() :: Instance,
}


do
	--// Setup `auto` type

	local autoValueTypeCache = {} :: { [any]: { Id: number, Type: StreamType<any> } }
	--// ^ Cache for auto types so we don't have to redetermine them for the GetGize and Write calls

	local autoTypes = {

		{
			Type = types.null :: any,
			Condition = function(value: any, typeName: string): boolean
				return typeName == "nil"
			end,
		},

		--// Int/float types

		{
			Type = types.u8 :: any,
			Condition = function(value: any, typeName: string): boolean
				return typeName == "number" and value == math.floor(value) and value >= 0 and value <= 255
			end,
		},

		{
			Type = types.i8 :: any,
			Condition = function(value: any, typeName: string): boolean
				return typeName == "number" and value == math.floor(value) and value >= -128 and value <= 127
			end,
		},

		{
			Type = types.u16 :: any,
			Condition = function(value: any, typeName: string): boolean
				return typeName == "number" and value == math.floor(value) and value >= 0 and value <= 65535
			end,
		},

		{
			Type = types.i16 :: any,
			Condition = function(value: any, typeName: string): boolean
				return typeName == "number" and value == math.floor(value) and value >= -32768 and value <= 32767
			end,
		},

		{
			Type = types.u32 :: any,
			Condition = function(value: any, typeName: string): boolean
				return typeName == "number" and value == math.floor(value) and value >= 0 and value <= 4294967295
			end,
		},

		{
			Type = types.i32 :: any,
			Condition = function(value: any, typeName: string): boolean
				return typeName == "number" and value == math.floor(value) and value >= -2147483648 and value <= 2147483647
			end,
		},

		--// i don't wanna automate the f32 type, skip straight to f64
		--// All luau numbers are 64bit floats internally, so itll work the best for almost everything

		{
			Type = types.f64 :: any,
			Condition = function(value: any, typeName: string): boolean
				return typeName == "number"
			end,
		},

		--// Other types

		{
			Type = types.boolean :: any,
			Condition = function(value: any, typeName: string): boolean
				return typeName == "boolean"
			end,
		},
		{
			Type = types.buffer :: any,
			Condition = function(value: any, typeName: string): boolean
				return typeName == "buffer"
			end,
		},
		{
			Type = types.shortstring :: any,
			Condition = function(value: any, typeName: string): boolean
				return typeName == "string" and #value <= 255
			end,
		},
		{
			Type = types.string :: any,
			Condition = function(value: any, typeName: string): boolean
				return typeName == "string"
			end,
		},
		{
			Type = types.Instance :: any,
			Condition = function(value: any, typeName: string): boolean
				return typeName == "Instance"
			end,
		},
		{
			Type = types.EnumItem :: any,
			Condition = function(value: any, typeName: string): boolean
				return typeName == "EnumItem"
			end,
		},
		{
			Type = types.CFrame :: any,
			Condition = function(value: any, typeName: string): boolean
				return typeName == "CFrame"
			end,
		},
		{
			Type = types.vector :: any,
			Condition = function(value: any, typeName: string): boolean
				return typeName == "vector"
			end,
		},
		{
			Type = types.Vector3 :: any,
			Condition = function(value: any, typeName: string): boolean
				return typeName == "Vector3"
			end,
		},
		{
			Type = types.Vector2 :: any,
			Condition = function(value: any, typeName: string): boolean
				return typeName == "Vector2"
			end,
		},
		{
			Type = types.Vector3int16 :: any,
			Condition = function(value: any, typeName: string): boolean
				return typeName == "Vector3int16"
			end,
		},
		{
			Type = types.Vector2int16 :: any,
			Condition = function(value: any, typeName: string): boolean
				return typeName == "Vector2int16"
			end,
		},
		{
			Type = types.UDim :: any,
			Condition = function(value: any, typeName: string): boolean
				return typeName == "UDim"
			end,
		},
		{
			Type = types.UDim2 :: any,
			Condition = function(value: any, typeName: string): boolean
				return typeName == "UDim2"
			end,
		},
		{
			Type = types.Color3 :: any,
			Condition = function(value: any, typeName: string): boolean
				return typeName == "Color3"
			end,
		},
		{
			Type = types.TweenInfo :: any,
			Condition = function(value: any, typeName: string): boolean
				return typeName == "TweenInfo"
			end,
		},
		{
			Type = types.NumberRange :: any,
			Condition = function(value: any, typeName: string): boolean
				return typeName == "NumberRange"
			end,
		},
	} :: { { Type: StreamType<any>, Condition: (value: any, typeName: string) -> boolean } }


	local function GetAutoType(value: any): (StreamType<any>, number)
		local typeName = typeof(value)
		for id, autoType in autoTypes do
			if autoType.Condition(value, typeName) then
				return autoType.Type :: any, id
			end
		end
		return types.unknown :: any, 0 --// failsafe, for unsupported types
	end


	types.auto = {
		TypeName = "auto",
			
		GetSize = function(value: any): number
			local streamType, id = GetAutoType(value)
			autoValueTypeCache[value] = { Id = id, Type = streamType }

			return 1 + Byte.GetSizeOfType(streamType, value)
		end,

		Read = function(buff: buffer, references: { any }, pointer: number): (any, number)
			local id = buffer.readu8(buff, pointer)
			if id == 0 then
				return (types.unknown :: StreamType<unknown>).Read(buff, references, pointer + 1)
			end

			local streamType = autoTypes[id].Type
			local value, offset = streamType.Read(buff, references, pointer + 1)

			return value, offset + 1
		end,

		Write = function(buff: buffer, references: { any }, pointer: number, value: any): number
			local typeData = autoValueTypeCache[value]
			autoValueTypeCache[value] = nil

			buffer.writeu8(buff, pointer, typeData.Id)
			return 1 + typeData.Type.Write(buff, references, pointer + 1, value)
		end,
	} :: any
	
end



return table.freeze(types)