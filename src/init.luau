--// Author: 8ch99
--// Date written: 25th March 2026
--// SwitchNet2

--[=[
	MIT License

	Copyright (c) 2026 8ch99

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.
]=]

--!strict
--!native
--!optimize 2

const VERSION = "v0.2.0"
const OUTPUT_MESSAGE = true

const NAMESPACE_NAME_SIZE_LIMIT = 32
const PACKET_NAME_SIZE_LIMIT = 64

const NAMESPACE_STORAGE_NAME = "SwitchNet2_Namespaces"

--// Services

const Players = game:GetService("Players")
const LogService = game:GetService("LogService")
const RunService = game:GetService("RunService")
const HttpService = game:GetService("HttpService")
const TestService = game:GetService("TestService")
const ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Dependencies

const runContext: "Client" | "Server" = if RunService:IsClient() then "Client" else "Server"

const TypeStores = require("@self/TypeStores")
const Byte = require("@self/Byte")
const Typedefs = require("@self/Typedefs")
const Namespaces = require("@self/Namespaces")
const ServerProcessor = require("@self/Processors/Server")
const ClientProcessor = require("@self/Processors/Client")

--// Typedefs

type StreamType<T> = Typedefs.StreamType<T>
type StreamTypeWithArgs<T> = Typedefs.StreamTypeWithArgs<T>

type Packet<T> = Typedefs.Packet<T>
type Query<T1, T2> = Typedefs.Query<T1, T2>

type ConvertedTypeTree = { Name: string, Args: { ConvertedTypeTree }? }

--// @module SwitchNet

const SwitchNet2 = {
	Types = TypeStores,
	NamespaceShareStore = nil :: Folder?,
}


--// Setup type name lookup, for namespace sharing
const typeNameLookups = {} :: { [StreamType<any>]: string }
for name, streamType in (TypeStores :: any) :: { [string]: StreamType<any> } do
	if type(streamType) ~= "function" then
		typeNameLookups[streamType] = name :: string
	end
end



function SwitchNet2.RegisterPacket<T>(parameters: { Mode: "Reliable" | "Unreliable", Type: T }, ShareToAll: boolean?): Packet<T>
	--// Packet name and namespace are assigned later when the namespace is registered
	local streamType = (parameters.Type :: any) :: StreamType<T>
	local self = {
		Id = "",
		Namespace = "",
		Mode = parameters.Mode,

		StreamType = streamType,
		ByteSize = streamType.Size,
	} :: Packet<T>


	function self.SendToAll(data: T)
		assert(runContext == "Server", "This is a server only function!")
		local buff, references = Byte.CompressStreamType(self.StreamType, data, self.ByteSize)
		ServerProcessor.QueueToAll(self, buff, references)
	end

	function self.SendToPlayers(data: T, players: { Player })
		assert(runContext == "Server", "This is a server only function!")
		local buff, references = Byte.CompressStreamType(self.StreamType, data, self.ByteSize)
		for _, player in players do
			ServerProcessor.Queue(self, buff, references, player)
		end
	end

	function self.SendToAllExcept(data: T, exemptPlayer: Player)
		assert(runContext == "Server", "This is a server only function!")
		local buff, references = Byte.CompressStreamType(self.StreamType, data, self.ByteSize)
		for _, player in Players:GetPlayers() do
			if player ~= exemptPlayer then
				ServerProcessor.Queue(self, buff, references, player)
			end
		end
	end


	function self.SendToAllUnreliable(data: T)
		assert(runContext == "Server", "This is a server only function!")
		local buff, references = Byte.CompressStreamType(self.StreamType, data, self.ByteSize)
		ServerProcessor.QueueToAllUnreliable(self, buff, references)
	end

	function self.SendToPlayersUnreliable(data: T, players: { Player })
		assert(runContext == "Server", "This is a server only function!")
		local buff, references = Byte.CompressStreamType(self.StreamType, data, self.ByteSize)
		for _, player in players do
			ServerProcessor.QueueUnreliable(self, buff, references, player)
		end
	end

	function self.SendToAllExceptUnreliable(data: T, exemptPlayer: Player)
		assert(runContext == "Server", "This is a server only function!")
		local buff, references = Byte.CompressStreamType(self.StreamType, data, self.ByteSize)
		for _, player in Players:GetPlayers() do
			if player ~= exemptPlayer then
				ServerProcessor.QueueUnreliable(self, buff, references, player)
			end
		end
	end


	if runContext == "Client" then

		function self.Send(data: T)
			local buff, references = Byte.CompressStreamType(self.StreamType, data, self.ByteSize)
			ClientProcessor.Queue(self, buff, references)
		end

		function self.SendUnreliable(data: T)
			local buff, references = Byte.CompressStreamType(self.StreamType, data, self.ByteSize)
			ClientProcessor.QueueUnreliable(self, buff, references)
		end


		function self.ListenClient(callback: (T) -> ()): () -> ()
			local bound = true
			local callbackId = self.Namespace .. self.Id .. HttpService:GenerateGUID(false)
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
			local thread = coroutine.running()
			local timeoutThread

			local disconnect: () -> ()
			disconnect = self.ListenClient(function(value: T)
				disconnect()
				coroutine.resume(thread, value)
				if timeoutThread then
					task.cancel(timeoutThread)
					timeoutThread = nil :: never
				end
			end)

			if timeout then
				timeoutThread = task.delay(timeout, function()
					timeoutThread = nil :: never
					disconnect()
					coroutine.resume(thread, nil, nil)
				end)
			end

			return coroutine.yield()
		end

	else
		
		function self.Send(data: T, player: Player?)
			local buff, references = Byte.CompressStreamType(self.StreamType, data, self.ByteSize)
			ServerProcessor.Queue(self, buff, references, player :: Player)
		end

		function self.SendUnreliable(data: T, player: Player?)
			local buff, references = Byte.CompressStreamType(self.StreamType, data, self.ByteSize)
			ServerProcessor.QueueUnreliable(self, buff, references, player :: Player)
		end


		function self.ListenServer(callback: (T, Player) -> ()): () -> ()
			local bound = true
			local callbackId = self.Namespace .. self.Id .. HttpService:GenerateGUID(false)
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
			local thread = coroutine.running()
			local timeoutThread

			local disconnect: () -> ()
			disconnect = self.ListenServer(function(value: T, player: Player)
				disconnect()
				coroutine.resume(thread, value, player)
				if timeoutThread then
					task.cancel(timeoutThread)
					timeoutThread = nil :: never
				end
			end)

			if timeout then
				timeoutThread = task.delay(timeout, function()
					timeoutThread = nil :: never
					disconnect()
					coroutine.resume(thread, nil, nil)
				end)
			end

			return coroutine.yield()
		end

	end
	

	return self
end



function SwitchNet2.RegisterQuery<T1, T2>(parameters: { RequestType: T1, ResponseType: T2, Timeout: number? }): Query<T1, T2>
	--// Packet name and namespace are assigned later when the namespace is registered
	local requestStreamType = (parameters.RequestType :: any) :: StreamType<T1>
	local responseStreamType = (parameters.ResponseType :: any) :: StreamType<T2>

	local self = {
		Id = "",
		Namespace = "",

		RequestStreamType = requestStreamType,
		RequestByteSize = requestStreamType.Size,
		ResponseStreamType = responseStreamType,
		ResponseByteSize = responseStreamType.Size,
		Timeout = parameters.Timeout,
	} :: Query<T1, T2>


	function self.ListenServer(callback: (data: T1, player: Player) -> T2): () -> ()
		assert(runContext == "Server", "This is a server only function!")
		local bound = true
		ServerProcessor.SetResponseHandler(self.Namespace, self.Id, callback)

		return function()
			if not bound then return end
			bound = false
			ServerProcessor.RemoveResponseHandler(self.Namespace, self.Id)
		end
	end

	function self.ListenClient(callback: (data: T1) -> T2): () -> ()
		assert(runContext == "Client", "This is a client only function!")
		local bound = true
		ClientProcessor.SetResponseHandler(self.Namespace, self.Id, callback)

		return function()
			if not bound then return end
			bound = false
			ClientProcessor.RemoveResponseHandler(self.Namespace, self.Id)
		end
	end


	if runContext == "Client" then

		function self.Invoke(data: T1): T2
			local buff, references = Byte.CompressStreamType(self.RequestStreamType, data, self.RequestByteSize)
			return ClientProcessor.Invoke(self, buff, references, self.Timeout)
		end

	else
		
		function self.Invoke(data: T1, player: Player?): T2
			local buff, references = Byte.CompressStreamType(self.RequestStreamType, data, self.RequestByteSize)
			return ServerProcessor.Invoke(self, player :: Player, buff, references, self.Timeout)
		end

	end


	return self
end



function SwitchNet2.RegisterNamespace<T>(name: string, packets: T, share: boolean?): T
	assert(#name <= NAMESPACE_NAME_SIZE_LIMIT, `Namespace name '{name}' is too large! Size limit is {NAMESPACE_NAME_SIZE_LIMIT}`)
	--assert(Namespaces[name] == nil, `Namespace '{name}' already exists!`)
	if Namespaces[name] then
		return (Namespaces[name] :: any) :: T
	end

	local typecasted = (packets :: any) :: { [string]: Packet<any> }
	Namespaces[name] = typecasted

	for packetName in typecasted do
		assert(#packetName <= PACKET_NAME_SIZE_LIMIT, `Packet name '{packetName}' in namespace '{name}' is too large! Size limit is {PACKET_NAME_SIZE_LIMIT}`)
	end

	for packetName, packet in typecasted do
		packet.Id = packetName
		packet.Namespace = name
	end

	if share and runContext == "Server" then
		SwitchNet2._shareNamespace(typecasted, name)
	end

	return packets
end


--// Namespace sharing handlers


function SwitchNet2._convertStreamTypeToNameTree<T>(streamType: StreamType<T>): ConvertedTypeTree
	local name = typeNameLookups[streamType :: StreamType<T>]
	if name then
		return { Name = name }
	end

	local typecasted = streamType :: StreamTypeWithArgs<T>
	local customName = typecasted.TypeName :: string
		
	local typeArgNames = {} :: { ConvertedTypeTree }
	for i, v in typecasted.TypeArgs do
		typeArgNames[i] = SwitchNet2._convertStreamTypeToNameTree(v)
	end

	return {
		Name = customName,
		Args = typeArgNames,
	}
end

function SwitchNet2._convertNameTreeToStreamType<T>(typeData: ConvertedTypeTree): StreamType<T>
	local streamType = (TypeStores :: any)[typeData.Name]
	
	if typeData.Args then
		local typeArgs = {}
		for index, data in typeData.Args do
			typeArgs[index] = SwitchNet2._convertNameTreeToStreamType(data)
		end
		return streamType(table.unpack(typeArgs))
	end

	return streamType
end



function SwitchNet2._shareNamespace(namespace: { [string]: Packet<any> | Query<any, any> }, name: string)

	if not SwitchNet2.NamespaceShareStore then return end
	if SwitchNet2.NamespaceShareStore:FindFirstChild(name) then return end

	local data = {} :: { any }

	for _, v in namespace do
		local isQuery = (v :: any).Invoke ~= nil
		local structure = {
			IsQuery = isQuery,
			Id = v.Id,
		}

		if isQuery then
			local typecasted = v :: Query<any, any>
			structure.RequestType = SwitchNet2._convertStreamTypeToNameTree(typecasted.RequestStreamType)
			structure.ResponseType = SwitchNet2._convertStreamTypeToNameTree(typecasted.ResponseStreamType)
		else
			local typecasted = v :: Packet<any>
			structure.Mode = typecasted.Mode
			structure.Type = SwitchNet2._convertStreamTypeToNameTree(typecasted.StreamType)
		end

		table.insert(data, structure)
	end
	
	local value = Instance.new("StringValue")
	value.Name = name
	value.Value = HttpService:JSONEncode(data)
	value.Parent = SwitchNet2.NamespaceShareStore

end

function SwitchNet2._registerRemoteNamespace(value: StringValue): { [string]: Packet<any> | Query<any, any> }?

	local name = value.Name
	if Namespaces[name] then return nil end --// Probably locally defined already somewhere

	local data = HttpService:JSONDecode(value.Value)
	
	local packets = {} :: { [string]: Packet<any> | Query<any, any> }

	for _, structure in data do
		local id = structure.Id
		local isQuery = structure.IsQuery

		if isQuery then
			packets[id] = SwitchNet2.RegisterQuery({
				RequestType = SwitchNet2._convertNameTreeToStreamType(structure.RequestType),
				ResponseType = SwitchNet2._convertNameTreeToStreamType(structure.ResponseType),
			}) :: any
		else
			packets[id] = SwitchNet2.RegisterPacket({
				Mode = structure.Mode,
				Type = SwitchNet2._convertNameTreeToStreamType(structure.Type),
			}) :: any
		end
	end

	return SwitchNet2.RegisterNamespace(name, packets)

end



if runContext == "Server" then
	SwitchNet2.NamespaceShareStore = ReplicatedStorage:FindFirstChild(NAMESPACE_STORAGE_NAME) :: Folder
	if not SwitchNet2.NamespaceShareStore then
		local shareStore = Instance.new("Folder")
		shareStore.Name = NAMESPACE_STORAGE_NAME
		shareStore.Parent = ReplicatedStorage

		SwitchNet2.NamespaceShareStore = shareStore
	end
else
	SwitchNet2.NamespaceShareStore = ReplicatedStorage:WaitForChild(NAMESPACE_STORAGE_NAME) :: Folder
	
	local shareStore = SwitchNet2.NamespaceShareStore :: Folder
	shareStore.ChildAdded:Connect(function(value: Instance)
		SwitchNet2._registerRemoteNamespace(value :: StringValue)
	end)

	for _, value in shareStore:GetChildren() do
		SwitchNet2._registerRemoteNamespace(value :: StringValue)
	end
end


--// Finalize

ServerProcessor.init(runContext)
ClientProcessor.init(runContext)



if OUTPUT_MESSAGE then
	task.spawn(function()
		--// Print message
		--// Check if it exists already too, so if theres several dependencies, it won't add extras
		local message = `SwitchNet2 {runContext} - {VERSION} loaded successfully! Created by 8ch99.`
		local logHistory = LogService:GetLogHistory() :: {
			{
				timestamp: number,
				message: string,
				messageType: Enum.MessageType,
			}
		}
		
		for _, log in logHistory do
			if log.message == message then
				--// Message was sent already, cancel!
				return
			end
		end
		
		TestService:Message(message)
	end)
end



return table.freeze(SwitchNet2)