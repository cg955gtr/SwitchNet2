--// Author: 8ch99
--// Date written: 25th March 2026
--// SwitchNet2

--!strict

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

	Send: (data: T, target: Player?) -> (),
	SendToAll: (data: T) -> (),
	SendToPlayers: (data: T, targets: { Player }) -> (),
	SendToAllExcept: (data: T, exemptPlayer: Player) -> (),

	SendUnreliable: (data: T, target: Player?) -> (),
	SendToAllUnreliable: (data: T) -> (),
	SendToPlayersUnreliable: (data: T, targets: { Player }) -> (),
	SendToAllExceptUnreliable: (data: T, exemptPlayer: Player) -> (),

	Wait: () -> (T?, Player?),
	ListenServer: (callback: (data: T, player: Player) -> ()) -> (() -> ()),
	ListenClient: (callback: (data: T) -> ()) -> (() -> ()),
}

export type Query<T1, T2> = {
	Id: string,
	Namespace: string,

	RequestStreamType: StreamType<T1>,
	RequestByteSize: number?,
	ResponseStreamType: StreamType<T2>,
	ResponseByteSize: number?,
	Timeout: number?,

	Invoke: (data: T1, target: Player?) -> T2,

	ListenServer: (callback: (data: T1, player: Player) -> T2) -> (() -> ()),
	ListenClient: (callback: (data: T1) -> T2) -> (() -> ()),
}


export type NetworkPacket = {
	Namespace: string,
	Packet: string,
	Data: buffer,
	References: { any },
}


return nil