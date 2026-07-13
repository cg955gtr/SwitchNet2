# SwitchNet2 Documentation

This contains a list of all the available packet types in SwitchNet2.
All schema types are stored in the `SwitchNet2.Types` dictionary.

> Miscellaneous Types
- `null` - Type that always represents a `nil` value.
- `unknown` - Type that can be used for values that are not to be compressed due to unknown value nature.
- `auto` - Type that will try to automatically determine and compress the given value. Unsupported values are not compressed but are still sent over remote
- `optional(t: T)` - Creates a type with the given type that can be nil.
	- Example:
		```luau
		SwitchNet2.Types.optional(SwitchNet2.Types.auto)
		```
- `array(t: T)` - Creates a type that defines an array using the given type as the value type.
	- Example:
		```luau
		SwitchNet2.Types.array(SwitchNet2.Types.vector)
		```
- `map(key: T1, value: T2)` - Creates a type that defines a map using the given types as key/value types.
	- Example:
		```luau
		SwitchNet2.Types.map(SwitchNet2.Types.f64, SwitchNet2.Types.vector)
		```
- `struct(struct: { [string]: StreamType<any> })` - Creates a type that defines a schema-like structure using the given dictionary (string keys, type values).
	- Example:
		```luau
		SwitchNet2.Types.struct({
			foo = SwitchNet2.Types.f64,
			bar = SwitchNet2.Types.optional(SwitchNet2.Types.string),
		})
		```
> `string` Types
- `string` - Luau string. Size limit is 65535 bytes
- `shortstring` - Luau string. Size limit is 255 bytes
- `fixedstring(size: number)` - Fixed size Luau string.
> `number` Types
- `f32` - Single precision (32-bit) float
- `f64` - Double precision (64-bit) float
	- ^ This is what regular Luau numbers use. If you wish to just transport regular numbers, use this
- `u8` - Unsigned 8-bit integer.
- `u16` - Unsigned 16-bit integer.
- `u32` - Unsigned 32-bit integer.
- `i8` - Signed 8-bit integer.
- `i16` - Signed 16-bit integer.
- `i32` - Signed 32-bit integer.
> Other Lua/Luau Types
- `boolean` - A boolean value.
- `buffer` - A Luau buffer value. Size limit is 65535 bytes.
- `vector` - A Luau vector value.
> Roblox Luau Types
- `CFrame` - A CFrame value.
- `shortCFrame` - A CFrame value with a more compressed rotation (uses 4 less bytes, but results in some precision loss).
- `Color3` - A Color3 value.
- `Color3u8` - A Color3 value, with each of its values compressed as a `u8` (uses 3 bytes instead of 12 bytes). 
- `EnumItem` - An EnumItem value of any sort.
- `Instance` - A Roblox Instance of any sort.
- `NumberRange` - A NumberRange value.
- `TweenInfo` - A TweenInfo value.
- `UDim` - A UDim value.
- `UDim2` - A UDim2 value.
- `Vector2` - A Vector2 value.
- `Vector3` - A Vector3 value.
- `Vector2int16` - A Vector2int16 value.
- `Vector3int16` - A Vector3int16 value.
