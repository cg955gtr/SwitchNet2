--// Author: 8ch99
--// Date written: 25th March 2026
--// SwitchNet2

--!strict
--!native
--!optimize 2

--// Dependencies

const Typedefs = require("../Typedefs")
const Byte = require("../Byte")
const ClientProcessor = require("../Processors/Client")

const FilterContainer = require("../Utilities/FilterContainer")
const RandomString = require("../Utilities/RandomString")


const compressStreamType = Byte.CompressStreamType

--// Typedefs

type FilterContainer<T...> = FilterContainer.FilterContainer<T...>

type StreamType<T> = Typedefs.StreamType<T>
type StreamTypeWithArgs<T> = Typedefs.StreamTypeWithArgs<T>

type Packet<T> = Typedefs.Packet<T>



const function registerPacket<T>(mode: "Reliable" | "Unreliable", type: T): Packet<T>
	
	--// Packet name and namespace are assigned later when the namespace is registered
	local streamType: StreamType<T> = type :: any

	local filters: FilterContainer<T> = FilterContainer.new()
	local preProcessFilters: FilterContainer<nil> = FilterContainer.new()
	
	local self = {
		Id = "",
		Namespace = "",
		Mode = mode,

		StreamType = streamType,
		ByteSize = streamType.Size,

		_filters = filters,
		_preProcessFilters = preProcessFilters,

		_isBound = false,
		_activeListeners = {} :: { string },
	} :: Packet<T>



	--// setup queue methods
	--// so that we can easily just call the method and define it differently varying on mode
	local queue: (Packet<T>, buffer, { any }) -> ()
	local bind: (string, (string, string, any) -> ()) -> ()
	local unbind: (string) -> ()

	if mode == "Unreliable" then
		queue = ClientProcessor.QueueUnreliable
		bind = ClientProcessor.BindUnreliable
		unbind = ClientProcessor.UnbindUnreliable
	elseif mode == "Reliable" then
		queue = ClientProcessor.Queue
		bind = ClientProcessor.Bind
		unbind = ClientProcessor.Unbind
	end



	function self.Send(data: T)
		local buff: buffer, references: { any } = compressStreamType(self.StreamType, data, self.ByteSize)
		queue(self, buff, references)
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



	function self.ListenServer()
		error("This is a server only function!")
	end

	function self.ListenClient(callback: (T) -> ()): () -> ()

		local bound: boolean = true
		if not self._isBound then
			self._isBound = true
		end

		local callbackId: string = self.Namespace .. self.Id .. (RandomString(32) :: string)
		table.insert(self._activeListeners, callbackId)

		bind(callbackId, function(namespaceId: string, packet: string, value: any)
			if namespaceId == self.Namespace and packet == self.Id then
				callback(value)
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



	function self.AddFilterClient(name: string, callback: (data: T) -> boolean, priority: number?)
		filters:AddFilter(name, callback, priority)
	end

	function self.RemoveFilterClient(name: string)
		filters:RemoveFilter(name)
	end

	function self.AddPreProcessFilterClient(name: string, callback: () -> boolean, priority: number?)
		preProcessFilters:AddFilter(name, callback, priority)
	end

	function self.RemovePreProcessFilterClient(name: string)
		preProcessFilters:RemoveFilter(name)
	end



	function self.AddFilterServer(name: string, callback: (data: T, player: Player) -> boolean, priority: number?)
		error("This is a server only function!")
	end

	function self.RemoveFilterServer(name: string)
		error("This is a server only function!")
	end

	function self.AddPreProcessFilterServer(name: string, callback: (player: Player) -> boolean, priority: number?)
		error("This is a server only function!")
	end

	function self.RemovePreProcessFilterServer(name: string)
		error("This is a server only function!")
	end



	return self

end



return registerPacket