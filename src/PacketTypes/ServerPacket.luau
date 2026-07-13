--// Author: 8ch99
--// Date written: 25th March 2026
--// SwitchNet2

--!strict
--!native
--!optimize 2

--// Services

const Players = game:GetService("Players")

--// Dependencies

const Typedefs = require("../Typedefs")
const Byte = require("../Byte")
const ServerProcessor = require("../Processors/Server")

--const FilterContainer = require("../Utilities/FilterContainer")
const RandomString = require("../Utilities/RandomString")


const compressStreamType = Byte.CompressStreamType

--// Typedefs

type StreamType<T> = Typedefs.StreamType<T>
type StreamTypeWithArgs<T> = Typedefs.StreamTypeWithArgs<T>

type Packet<T> = Typedefs.Packet<T>



const function registerPacket<T>(mode: "Reliable" | "Unreliable", type: T): Packet<T>
	
	--// Packet name and namespace are assigned later when the namespace is registered
	local streamType: StreamType<T> = type :: any
	
	local self = {
		Id = "",
		Namespace = "",
		Mode = mode,

		StreamType = streamType,
		ByteSize = streamType.Size,

		_filters = {},
		
		_isBound = false,
		_activeListeners = {} :: { string },
	} :: Packet<T>



	--// setup queue methods
	--// so that we can easily just call the method and define it differently varying on mode
	local queue: (Packet<T>, buffer, { any }, Player) -> ()
	local queueToAll: (Packet<T>, buffer, { any }) -> ()
	local bind: (string, (Player, string, string, any) -> ()) -> ()
	local unbind: (string) -> ()

	if mode == "Unreliable" then
		queue = ServerProcessor.QueueUnreliable
		queueToAll = ServerProcessor.QueueToAllUnreliable
		bind = ServerProcessor.BindUnreliable
		unbind = ServerProcessor.UnbindUnreliable
	elseif mode == "Reliable" then
		queue = ServerProcessor.Queue
		queueToAll = ServerProcessor.QueueToAll
		bind = ServerProcessor.Bind
		unbind = ServerProcessor.Unbind
	end




	function self.Send(data: T, player: Player?)
		local buff: buffer, references: { any } = compressStreamType(self.StreamType, data, self.ByteSize)
		queue(self, buff, references, player :: Player)
	end

	function self.SendToAll(data: T)
		local buff: buffer, references: { any } = compressStreamType(self.StreamType, data, self.ByteSize)
		queueToAll(self, buff, references)
	end

	function self.SendToPlayers(data: T, players: { Player })
		local buff: buffer, references: { any } = compressStreamType(self.StreamType, data, self.ByteSize)
		for _, player: Player in players do
			queue(self, buff, references, player)
		end
	end

	function self.SendToAllExcept(data: T, exemptPlayer: Player)
		local buff: buffer, references: { any } = compressStreamType(self.StreamType, data, self.ByteSize)
		for _, player: Player in Players:GetPlayers() do
			if player ~= exemptPlayer then
				queue(self, buff, references, player)
			end
		end
	end



	function self.ListenClient()
		error("This is a client only function!")
	end

	function self.ListenServer(callback: (T, Player) -> ()): () -> ()

		local bound: boolean = true
		if not self._isBound then
			self._isBound = true
		end
		
		local callbackId: string = self.Namespace .. self.Id .. (RandomString(32) :: string)
		table.insert(self._activeListeners, callbackId)
		
		bind(callbackId, function(player: Player, namespaceId: string, packet: string, value: any)
			if namespaceId == self.Namespace and packet == self.Id then
				callback(value, player)
			end
		end)

		return function()

			if not self or not bound then return end
			bound = false
			unbind(callbackId)

			table.remove(self._activeListeners, table.find(self._activeListeners, callbackId))
			if #self._activeListeners == 0 then
				self._isBound = false
			end

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