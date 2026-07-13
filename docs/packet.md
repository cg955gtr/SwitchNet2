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