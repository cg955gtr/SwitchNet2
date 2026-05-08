--// Author: 8ch99
--// Date written: 25th March 2026
--// SwitchNet2

--// Services

const Players = game:GetService("Players")

--// Dependencies

const Typedefs = require("../Typedefs")
const Byte = require("../Byte")
const ServerProcessor = require("../Processors/Server")

--const FilterContainer = require("../Utilities/FilterContainer")
const RandomString = require("../Utilities/RandomString")

--// Typedefs

type StreamType<T> = Typedefs.StreamType<T>
type StreamTypeWithArgs<T> = Typedefs.StreamTypeWithArgs<T>

type Packet<T> = Typedefs.Packet<T>



local function registerPacket<T>(mode: "Reliable" | "Unreliable", type: T): Packet<T>
	
	--// Packet name and namespace are assigned later when the namespace is registered
	local streamType: StreamType<T> = type :: any
	
	local self = {
		Id = "",
		Namespace = "",
		Mode = mode,

		StreamType = streamType,
		ByteSize = streamType.Size,

		_filters = {},
	} :: Packet<T>



	function self.Send(data: T, player: Player)
		local buff: buffer, references: { any } = Byte.CompressStreamType(self.StreamType, data, self.ByteSize)
		ServerProcessor.Queue(self, buff, references, player)
	end

	function self.SendToAll(data: T)
		local buff: buffer, references: { any } = Byte.CompressStreamType(self.StreamType, data, self.ByteSize)
		ServerProcessor.QueueToAll(self, buff, references)
	end

	function self.SendToPlayers(data: T, players: { Player })
		local buff: buffer, references: { any } = Byte.CompressStreamType(self.StreamType, data, self.ByteSize)
		for _, player: Player in players do
			ServerProcessor.Queue(self, buff, references, player)
		end
	end

	function self.SendToAllExcept(data: T, exemptPlayer: Player)
		local buff: buffer, references: { any } = Byte.CompressStreamType(self.StreamType, data, self.ByteSize)
		for _, player: Player in Players:GetPlayers() do
			if player ~= exemptPlayer then
				ServerProcessor.Queue(self, buff, references, player)
			end
		end
	end



	function self.SendUnreliable(data: T, player: Player)
		local buff: buffer, references: { any } = Byte.CompressStreamType(self.StreamType, data, self.ByteSize)
		ServerProcessor.QueueUnreliable(self, buff, references, player)
	end

	function self.SendToAllUnreliable(data: T)
		local buff, references = Byte.CompressStreamType(self.StreamType, data, self.ByteSize)
		ServerProcessor.QueueToAllUnreliable(self, buff, references)
	end

	function self.SendToPlayersUnreliable(data: T, players: { Player })
		local buff, references = Byte.CompressStreamType(self.StreamType, data, self.ByteSize)
		for _, player in players do
			ServerProcessor.QueueUnreliable(self, buff, references, player)
		end
	end

	function self.SendToAllExceptUnreliable(data: T, exemptPlayer: Player)
		local buff, references = Byte.CompressStreamType(self.StreamType, data, self.ByteSize)
		for _, player in Players:GetPlayers() do
			if player ~= exemptPlayer then
				ServerProcessor.QueueUnreliable(self, buff, references, player)
			end
		end
	end



	function self.ListenClient()
		error("This is a client only function!")
	end

	function self.ListenServer(callback: (T, Player) -> ()): () -> ()

		local bound: boolean = true
		local callbackId: string = self.Namespace .. self.Id .. RandomString(32)
		ServerProcessor.Bind(callbackId, function(player: Player, namespaceId: string, packet: string, value: any)
			if namespaceId == self.Namespace and packet == self.Id then
				callback(value, player)
			end
		end)

		return function()
			if not bound then return end
			bound = false
			ServerProcessor.Unbind(callbackId)
		end

	end

	function self.Wait(timeout: number?): (T?, Player?)
		
		local thread: thread = coroutine.running()
		local timeoutThread: thread?

		local disconnect: () -> ()
		disconnect = self.ListenServer(function(value: T, player: Player)
			disconnect()
			coroutine.resume(thread, value, player)
			if timeoutThread then
				task.cancel(timeoutThread)
				timeoutThread = nil
			end
		end)

		if timeout then
			timeoutThread = task.delay(timeout, function()
				timeoutThread = nil
				disconnect()
				coroutine.resume(thread, nil, nil)
			end)
		end

		return coroutine.yield()

	end



	return self

end



return registerPacket