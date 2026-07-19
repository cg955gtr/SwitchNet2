# SwitchNet2 Documentation

# Query

Queries are objects within a namespace used to define a specific communication route for response-based requests and its data structure, as well as storing methods for sending/receiving data for the specific query.


> Ensure that data you are sending is the correct format based on the type schema, otherwise the request will fail.

---
---

# Methods **(Client)**



## Invoke

```luau
packet.Invoke(data: T)
```

- Sends the given data to the server, and returns the data the client responded with (if any).

> Parameters

```luau
data : T
```


## ListenClient

```luau
packet.ListenClient(callback: (data: T1) -> T2): () -> ()
```

- Sets the callback that fires when the client receives a request for this query. This function also handles returning the response data.
- Returns a function that when called, disconnects the callback function from being fired again permanently.

> Parameters

```luau
callback : (data: T1) -> T2
```

> Returns

```luau
() -> ()
```


## AddPreProcessFilterClient

```luau
packet.AddPreProcessFilterClient(name: string, callback: () -> boolean, priority: number?)
```

- Adds a pre-process filter function that returns a boolean determining whether the incoming remote call should be dropped.
- If the function returns `false`, the remote call is dropped.
- These are called *before* any data decompression is done. These are useful for authorization of players, and other non-data filters.
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



## Invoke

```luau
packet.Invoke(data: T, player: Player)
```

- Sends the given data to the given client, and returns the data the client responded with (if any).

> Parameters

```luau
data : T
player : Player
```


## ListenServer

```luau
packet.ListenServer(callback: (data: T1, player: Player) -> T2): () -> ()
```

- Sets the callback that fires when the server receives a request for this query. This function also handles returning the response data.
- Returns a function that when called, disconnects the callback function from being fired again permanently.

> Parameters

```luau
callback : (data: T1, player: Player) -> T2
```

> Returns

```luau
() -> ()
```


## AddPreProcessFilterServer

```luau
packet.AddPreProcessFilterServer(name: string, callback: (Player) -> boolean, priority: number?)
```

- Adds a pre-process filter function that returns a boolean determining whether the incoming remote call should be dropped.
- If the function returns `false`, the remote call is dropped.
- These are called *before* any data decompression is done. These are useful for authorization of players, and other non-data filters.
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