--// Author: 8ch99
--// Date written: 25th March 2026
--// SwitchNet2

--// Dependencies

const Typedefs = require("../Typedefs")
const Byte = require("../Byte")
const ServerProcessor = require("../Processors/Server")

--const FilterContainer = require("../Utilities/FilterContainer")

--// Typedefs

type StreamType<T> = Typedefs.StreamType<T>
type StreamTypeWithArgs<T> = Typedefs.StreamTypeWithArgs<T>

type Query<T1, T2> = Typedefs.Query<T1, T2>



local function registerQuery<T1, T2>(requestType: T1, responseType: T2, timeout: number?): Query<T1, T2>
	
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
	} :: Query<T1, T2>



	function self.Invoke(data: T1, player: Player): T2
		local buff: buffer, references: { any } = Byte.CompressStreamType(self.RequestStreamType, data, self.RequestByteSize)
		return ServerProcessor.Invoke(self, player :: Player, buff, references, self.Timeout)
	end



	function self.ListenServer(callback: (data: T1, player: Player) -> T2): () -> ()

		local bound: boolean = true
		ServerProcessor.SetResponseHandler(self.Namespace, self.Id, callback)

		return function()
			if not bound then return end
			bound = false
			ServerProcessor.RemoveResponseHandler(self.Namespace, self.Id)
		end
		
	end

	function self.ListenClient()
		error("This is a client only function!")
	end



	return self

end



return registerQuery