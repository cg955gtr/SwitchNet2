# SwitchNet2 Documentation

# Packet

Packets are objects within a namespace used to define a specific communication route and its data structure, as well as storing methods for sending/receiving data for the specific packet.


> Ensure that data you are sending is the correct format based on the type schema, otherwise the request will fail.

---
---

# Methods **(Client)**



## Send

```luau
packet.Send(data: T)
```

- Sends the given data to the server.

> Parameters

```luau
data : T
```


## Wait

```luau
packet.Wait(timeout: number?): T?
```

- Yields the current thread until a request is received. If a request is received, sent data is returned.

> Parameters

```luau
timeout : number?
```

> Returns

```luau
T?
```


## ListenClient

```luau
packet.ListenClient(callback: (T) -> ()): () -> ()
```

- Adds a callback that fires when the client receives a request for this packet.
Returns a function that when called, disconnects the callback function from being fired again permanently.

> Parameters

```luau
callback : (T) -> ()
```

> Returns

```luau
() -> ()
```


## AddFilterClient

```luau
packet.AddFilterClient(name: string, callback: (T) -> boolean, priority: number?)
```

- Adds a filter function that returns a boolean determining whether the incoming remote call should be dropped. You can use this for things like verifying remote args.
- If the function returns `false`, the remote call is dropped.
- An optional priority can be provided too. (the lower the number, the higher priority)
- **NOTE**: The `callback` function should *never* yield.

> Parameters

```luau
name : string
callback : (T) -> boolean
priority: number?
```


## RemoveFilterClient

```luau
packet.RemoveFilterClient(name: string)
```

- Removes the filter function, if it exists.

> Parameters

```luau
name : string
```


## AddPreProcessFilterClient

```luau
packet.AddPreProcessFilterClient(name: string, callback: () -> boolean, priority: number?)
```

- Adds a pre-process filter function that returns a boolean determining whether the incoming remote call should be dropped.
- If the function returns `false`, the remote call is dropped.
- The difference between pre-process filters is that these are called *before* any data decompression is done. These are useful for authorization of players, and other non-data filters.
- An optional priority can be provided too. (the lower the number, the higher priority)
- **NOTE**: The `callback` function should *never* yield.

> Parameters

```luau
name : string
callback : () -> boolean
priority: number?
```


## RemovePreProcessFilterClient

```luau
packet.RemoveFilterClient(name: string)
```

- Removes the pre-process filter function, if it exists.

> Parameters

```luau
name : string
```

---
---


# Methods **(Server)**



## Send

```luau
packet.Send(data: T, player: Player)
```

- Sends the given data to the given client.

> Parameters

```luau
data : T
player : Player
```


## SendToAll

```luau
packet.SendToAll(data: T)
```

- Sends the given data to every active client.

> Parameters

```luau
data : T
```


## SendToPlayers

```luau
packet.SendToPlayers(data: T, players: { Player })
```

- Sends the given data to the given list of players only.

> Parameters

```luau
data : T
players : { Player }
```


## SendToAllExcept

```luau
packet.SendToAllExcept(data: T, exemptPlayer: Player)
```

- Sends the given data to every active client EXCEPTING `exemptPlayer`.

> Parameters

```luau
data : T
exemptPlayer : Player
```


## Wait

```luau
packet.Wait(timeout: number?): (T?, Player?)
```

- Yields the current thread until a request is received. If a request is received, sent data + sending player is returned.

> Parameters

```luau
timeout : number?
```

> Returns

```luau
T? 
Player?
```


## ListenServer

```luau
packet.ListenServer(callback: (T, Player) -> ()): () -> ()
```

- Adds a callback that fires when the server receives a request for this packet.
Returns a function that when called, disconnects the callback function from being fired again permanently.

> Parameters

```luau
callback : (T, Player) -> ()
```

> Returns

```luau
() -> ()
```



## AddFilterServer

```luau
packet.AddFilterServer(name: string, callback: (T, Player) -> boolean, priority: number?)
```

- Adds a filter function that returns a boolean determining whether the incoming remote call should be dropped. You can use this for things like verifying remote args.
- If the function returns `false`, the remote call is dropped.
- An optional priority can be provided too. (the lower the number, the higher priority)
- **NOTE**: The `callback` function should *never* yield.

> Parameters

```luau
name : string
callback : (T, Player) -> boolean
priority: number?
```


## RemoveFilterServer

```luau
packet.RemoveFilterServer(name: string)
```

- Removes the filter function, if it exists.

> Parameters

```luau
name : string
```


## AddPreProcessFilterServer

```luau
packet.AddPreProcessFilterServer(name: string, callback: (Player) -> boolean, priority: number?)
```

- Adds a pre-process filter function that returns a boolean determining whether the incoming remote call should be dropped.
- If the function returns `false`, the remote call is dropped.
- The difference between pre-process filters is that these are called *before* any data decompression is done. These are useful for authorization of players, and other non-data filters.
- An optional priority can be provided too. (the lower the number, the higher priority)
- **NOTE**: The `callback` function should *never* yield.

> Parameters

```luau
name : string
callback : (Player) -> boolean
priority: number?
```


## RemovePreProcessFilterServer

```luau
packet.RemoveFilterServer(name: string)
```

- Removes the pre-process filter function, if it exists.

> Parameters

```luau
name : string
```