# SwitchNet2

An efficient strictly-typed networking module for reducing bandwidth and overhead across remotes.
It has similar syntax to ByteNet, except with proper --!strict compatibility and more efficient compression/decompression.
> ^ Compression is especially much more efficient, most notably when dealing with complex type structures

# Installation

> SwitchNet2 can be installed via. Wally, or via the .rbxm in latest releases.

# Documentation

- **[Main](./docs/docs.md)**
- **[Packet](./docs/packet.md)**
- **[Query](./docs/query.md)**
- **[Types](./docs/types.md)**

```luau
const SwitchNet2 = require(path_to_switchnet_here)
```

# Overview & Basic Example Usage

Remote bridges are defined/registered by creating namespaces with packets.

All schema types are stored in the `SwitchNet2.Types` dictionary.

> Example namespace:
```luau
const packets = SwitchNet2.RegisterNamespace("ExampleNamespace123", {

	testPacket1 = SwitchNet2.RegisterPacket({
		Mode = "Reliable", --// can be "Reliable" or "Unreliable", unreliable communicates via UnreliableRemoteEvent
		Type = SwitchNet2.Types.string, --// The actual type schema used to define the packet structure.
	}),

	testPacket2 = SwitchNet2.RegisterPacket({
		Mode = "Unreliable",
		Type = SwitchNet2.Types.struct({
			id = SwitchNet2.Types.u32,
			message = SwitchNet2.Types.string,
			position = SwitchNet2.Types.Vector3,
			optionalData = SwitchNet2.Types.optional(SwitchNet2.Types.auto),
		}),
	}),


	testQuery1 = SwitchNet2.RegisterQuery({
		RequestType = SwitchNet2.Types.string, --// type schema for sending requests
		ResponseType = SwitchNet2.Types.boolean, --// type schema for receiving responses
	}),

	testQuery2 = SwitchNet2.RegisterQuery({
		RequestType = SwitchNet2.Types.string,
		ResponseType = SwitchNet2.Types.u8,
		Timeout = 30, --// optional timeout parameter (in seconds), request is dropped if no response by then
	}),

})
```

Additionally, Each packet/query's schema will also automatically infer the argument/parameter types when you use their methods.

```lua
packets.testPacket2.ListenClient(function(data)
	--[=[
		The 'data' parameter is automatically inferred as:

		data: {
			id: number,
			message: string,
			position: Vector3,
			optionalData: any?,
		}
	]=]
end)
```

> Examples of utilizing packets:
```luau
packets.testPacket1.ListenServer(function(data: string, player: Player)
	print(`Received {player.Name}'s message: {data}`)
	packets.testPacket1.Send(`Hello {player.Name}!`, player) --// relay back to player
end)

packets.testPacket1.SendToAll("Hello everyone!")
packets.testPacket1.SendToAllExcept("Hello (nearly) everyone!", other_player_here)

local isConnected: boolean = packets.testQuery1.Invoke("IS_CONNECTED", random_player_here)
warn(`{random_player_here.Name} is {if isConnected then "connected" else "NOT connected"}!`)
```