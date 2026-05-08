--// Author: 8ch99
--// Date written: 25th March 2026
--// SwitchNet2

--// Dependencies

const Typedefs = require("../Typedefs")
const Byte = require("../Byte")
const ClientProcessor = require("../Processors/Client")

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



	function self.Send(data: T)
		local buff: buffer, references: { any } = Byte.CompressStreamType(self.StreamType, data, self.ByteSize)
		ClientProcessor.Queue(self, buff, references)
	end

	function self.SendToAll()
		error("This is a server only function!")
	end

	function self.SendToPlayers()
		error("This is a server only function!")
	end

	function self.SendToAllExcept()
		error("This is a server only function!")
	end



	function self.SendUnreliable(data: T)
		local buff: buffer, references: { any } = Byte.CompressStreamType(self.StreamType, data, self.ByteSize)
		ClientProcessor.QueueUnreliable(self, buff, references)
	end

	function self.SendToAllUnreliable()
		error("This is a server only function!")
	end

	function self.SendToPlayersUnreliable()
		error("This is a server only function!")
	end

	function self.SendToAllExceptUnreliable()
		error("This is a server only function!")
	end



	function self.ListenServer()
		error("This is a server only function!")
	end

	function self.ListenClient(callback: (T) -> ()): () -> ()

		local bound: boolean = true
		local callbackId: string = self.Namespace .. self.Id .. RandomString(32)
		ClientProcessor.Bind(callbackId, function(namespaceId: string, packet: string, value: any)
			if namespaceId == self.Namespace and packet == self.Id then
				callback(value)
			end
		end)

		return function()
			if not bound then return end
			bound = false
			ClientProcessor.Unbind(callbackId)
		end

	end

	function self.Wait(timeout: number?): T?
		
		local thread: thread = coroutine.running()
		local timeoutThread: thread?

		local disconnect: () -> ()
		disconnect = self.ListenClient(function(value: T)
			disconnect()
			coroutine.resume(thread, value)
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