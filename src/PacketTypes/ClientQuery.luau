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


const compressStreamType = Byte.CompressStreamType

--// Typedefs

type FilterContainer<T...> = FilterContainer.FilterContainer<T...>

type StreamType<T> = Typedefs.StreamType<T>
type StreamTypeWithArgs<T> = Typedefs.StreamTypeWithArgs<T>

type Query<T1, T2> = Typedefs.Query<T1, T2>



const function registerQuery<T1, T2>(requestType: T1, responseType: T2, timeout: number?): Query<T1, T2>
	
	--// Packet name and namespace are assigned later when the namespace is registered
	local requestStreamType: StreamType<T1> = requestType :: any
	local responseStreamType: StreamType<T2> = responseType :: any

	local preProcessFilters: FilterContainer<nil> = FilterContainer.new()
	
	local self = {
		Id = "",
		Namespace = "",

		_preProcessFilters = preProcessFilters,

		RequestStreamType = requestStreamType,
		RequestByteSize = requestStreamType.Size,
		ResponseStreamType = responseStreamType,
		ResponseByteSize = responseStreamType.Size,
		Timeout = timeout,

		_isBound = false,
	} :: Query<T1, T2>



	function self.Invoke(data: T1): T2
		local buff: buffer, references: { any } = compressStreamType(self.RequestStreamType, data, self.RequestByteSize)
		return ClientProcessor.Invoke(self, buff, references, self.Timeout)
	end



	function self.ListenClient(callback: (data: T1) -> T2): () -> ()

		self._isBound = true
		ClientProcessor.SetResponseHandler(self.Namespace, self.Id, callback)

		return function()
			if not self or not self._isBound then return end
			self._isBound = false
			ClientProcessor.RemoveResponseHandler(self.Namespace, self.Id)
		end
		
	end

	function self.ListenServer()
		error("This is a server only function!")
	end



	function self.AddPreProcessFilterClient(name: string, callback: () -> boolean, priority: number?)
		preProcessFilters:AddFilter(name, callback, priority)
	end

	function self.RemovePreProcessFilterClient(name: string)
		preProcessFilters:RemoveFilter(name)
	end

	

	function self.AddPreProcessFilterServer(name: string, callback: (player: Player) -> boolean, priority: number?)
		error("This is a server only function!")
	end

	function self.RemovePreProcessFilterServer(name: string)
		error("This is a server only function!")
	end

	

	return self

end



return registerQuery