--// Author: 8ch99
--// Date written: 25th March 2026
--// SwitchNet2

--!strict
--!native
--!optimize 2

--// Dependencies

const Typedefs = require("../Typedefs")
const Byte = require("../Byte")
const ServerProcessor = require("../Processors/Server")

--const FilterContainer = require("../Utilities/FilterContainer")


const compressStreamType = Byte.CompressStreamType

--// Typedefs

type StreamType<T> = Typedefs.StreamType<T>
type StreamTypeWithArgs<T> = Typedefs.StreamTypeWithArgs<T>

type Query<T1, T2> = Typedefs.Query<T1, T2>



const function registerQuery<T1, T2>(requestType: T1, responseType: T2, timeout: number?): Query<T1, T2>
	
	--// Packet name and namespace are assigned later when the namespace is registered
	local requestStreamType: StreamType<T1> = requestType :: any
	local responseStreamType: StreamType<T2> = responseType :: any
	
	local self = {
		Id = "",
		Namespace = "",

		RequestStreamType = requestStreamType,
		RequestByteSize = requestStreamType.Size,
		ResponseStreamType = responseStreamType,
		ResponseByteSize = responseStreamType.Size,
		Timeout = timeout,

		_isBound = false,
	} :: Query<T1, T2>



	function self.Invoke(data: T1, player: Player?): T2
		local buff: buffer, references: { any } = compressStreamType(self.RequestStreamType, data, self.RequestByteSize)
		return ServerProcessor.Invoke(self, player :: Player, buff, references, self.Timeout)
	end



	function self.ListenServer(callback: (data: T1, player: Player) -> T2): () -> ()

		self._isBound = true
		ServerProcessor.SetResponseHandler(self.Namespace, self.Id, callback)

		return function()
			if not self or not self._isBound then return end
			self._isBound = false
			ServerProcessor.RemoveResponseHandler(self.Namespace, self.Id)
		end
		
	end

	function self.ListenClient()
		error("This is a client only function!")
	end



	return self

end



return registerQuery