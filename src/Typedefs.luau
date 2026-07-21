--// Author: 8ch99
--// Date written: 25th March 2026
--// SwitchNet2

--!strict

--// Dependencies

const FilterContainer = require("./Utilities/FilterContainer")

--// Typedefs

type FilterContainer<T...> = FilterContainer.FilterContainer<T...>



export type NetworkPacket = {
	Namespace: string,
	Packet: string,
	Data: buffer,
	References: { any },
}



export type StreamType<T> = {
	TypeName: string?,
	Read: (buff: buffer, references: { any }?, pointer: number) -> (T, number),
	Write: (buff: buffer, references: { any }?, pointer: number, value: T) -> number,
	Size: number?,
	GetSize: ((T) -> number)?,
}

export type StreamTypeWithArgs<T> = StreamType<T> & {
	TypeArgs: { StreamType<any> },
}

export type Packet<T> = {
	Id: string,
	Namespace: string,
	Mode: "Reliable" | "Unreliable",

	StreamType: StreamType<T>,
	ByteSize: number?,

	_isBound: boolean,
	_activeListeners: { string },

	_filters: FilterContainer<T, Player?>,
	_preProcessFilters: FilterContainer<Player?>,

	_destroy: () -> (),

	Send: (data: T, target: Player?) -> (),
	SendToAll: (data: T) -> (),
	SendToPlayers: (data: T, targets: { Player }) -> (),
	SendToAllExcept: (data: T, exemptPlayer: Player) -> (),

	Wait: () -> (T?, Player?),
	ListenServer: (callback: (data: T, player: Player) -> ()) -> (() -> ()),
	ListenClient: (callback: (data: T) -> ()) -> (() -> ()),
	DisconnectAll: () -> (),

	AddFilterClient: (name: string, callback: (data: T) -> boolean, priority: number?) -> (),
	RemoveFilterClient: (name: string) -> (),
	AddPreProcessFilterClient: (name: string, callback: () -> boolean, priority: number?) -> (),
	RemovePreProcessFilterClient: (name: string) -> (),

	AddFilterServer: (name: string, callback: (data: T, player: Player) -> boolean, priority: number?) -> (),
	RemoveFilterServer: (name: string) -> (),
	AddPreProcessFilterServer: (name: string, callback: (player: Player) -> boolean, priority: number?) -> (),
	RemovePreProcessFilterServer: (name: string) -> (),
}

export type Query<T1, T2> = {
	Id: string,
	Namespace: string,

	RequestStreamType: StreamType<T1>,
	RequestByteSize: number?,
	ResponseStreamType: StreamType<T2>,
	ResponseByteSize: number?,
	Timeout: number?,

	_isBound: boolean,

	_preProcessFilters: FilterContainer<Player?>,

	_destroy: () -> (),

	Invoke: (data: T1, target: Player?) -> T2,

	ListenServer: (callback: (data: T1, player: Player) -> T2) -> (() -> ()),
	ListenClient: (callback: (data: T1) -> T2) -> (() -> ()),

	AddPreProcessFilterClient: (name: string, callback: () -> boolean, priority: number?) -> (),
	RemovePreProcessFilterClient: (name: string) -> (),

	AddPreProcessFilterServer: (name: string, callback: (player: Player) -> boolean, priority: number?) -> (),
	RemovePreProcessFilterServer: (name: string) -> (),
}



return nil