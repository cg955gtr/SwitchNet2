# SwitchNet2 Documentation

> **NOTE:** Properties/variables/methods prefixed with `_` are intended for internal use only.

# Properties

## Types

```luau
SwitchNet2.Types
```

- Stores all the schema types for defining packets/queries. More info can be found in the `docs/types.md` file.

# Methods


## RegisterNamespace

```luau
SwitchNet2.RegisterNamespace(name: string, packets: T): T
```

- Defines a new namespace with the given name and given packets/queries. If the namespace exists already, it will just return the existing namespace.
- Packet/query names are defined by the key names in the given `packets` table.
> **NOTE**: The namespace name has a size limit of `32` chars, and each packet/query name has a size limit of `64` chars.

> Parameters

```luau
name : string
packets : T
```

> Returns

```luau
T - The new namespace
```


## RegisterPacket

```luau
SwitchNet2.RegisterPacket(parameters: { Mode: "Reliable" | "Unreliable", Type: T }): Packet<T>
```

- Creates a new packet with the given mode and type structure.
- The packet is registered once its applied to a namespace via. `SwitchNet2.RegisterNamespace`.

> Parameters

```luau
parameters : { Mode: "Reliable" | "Unreliable", Type: T }
```

> Returns

```luau
Packet<T> - The packet object
```


## RegisterQuery

```luau
SwitchNet2.RegisterQuery(parameters: { RequestType: T1, ResponseType: T2, Timeout: number? }): Query<T1, T2>
```

- Creates a new query with the given request and response type structures.
- The query is registered once its applied to a namespace via. `SwitchNet2.RegisterNamespace`.

> Parameters

```luau
parameters : { RequestType: T1, ResponseType: T2, Timeout: number? }
```

> Returns

```luau
Query<T1, T2> - The query object
```



## AddPacketToNamespace

```luau
SwitchNet2.AddPacketToNamespace(namespace: string, packetName: string, parameters: { Mode: "Reliable" | "Unreliable", Type: T }): Packet<T>
```

- Creates a new packet in the given namespace with the given name and parameters.
- This is intended for adding packets at runtime.

> Parameters

```luau
namespace : string
packetName : string
parameters : { RequestType: T1, ResponseType: T2, Timeout: number? }
```

> Returns

```luau
Packet<T> - The packet object
```

## RemovePacketFromNamespace

```luau
SwitchNet2.RemovePacketFromNamespace<T>(namespace: string, packetName: string)
```

- Removes a packet from the given namespace.
- This is intended for removing packets at runtime.

> Parameters

```luau
namespace : string
packetName : string
```



## AddQueryToNamespace

```luau
SwitchNet2.AddQueryToNamespace(namespace: string, queryName: string, parameters: { RequestType: T1, ResponseType: T2, Timeout: number? }): Query<T1, T2>
```

- Creates a new query in the given namespace with the given name and parameters.
- This is intended for adding queries at runtime.

> Parameters

```luau
namespace : string
queryName : string
parameters : { RequestType: T1, ResponseType: T2, Timeout: number? }
```

> Returns

```luau
Query<T1, T2> - The query object
```

## RemoveQueryFromNamespace

```luau
SwitchNet2.RemoveQueryFromNamespace<T>(namespace: string, queryName: string)
```

- Removes a query from the given namespace.
- This is intended for removing queries at runtime.

> Parameters

```luau
namespace : string
queryName : string
```