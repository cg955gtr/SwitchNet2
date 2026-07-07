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

const VERSION: string = "v0.3.1"
const OUTPUT_MESSAGE: boolean = true

const NAMESPACE_NAME_SIZE_LIMIT: number = 32
const PACKET_NAME_SIZE_LIMIT: number = 64

const NAMESPACE_STORAGE_NAME: string = "SwitchNet2_Namespaces"

--// Services

const LogService = game:GetService("LogService")
const RunService = game:GetService("RunService")
const HttpService = game:GetService("HttpService")
const ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Dependencies

const runContext: "Client" | "Server" = if RunService:IsClient() then "Client" else "Server"

const Typedefs = require("@self/Typedefs")
const TypeStores = require("@self/TypeStores")
const Namespaces = require("@self/Namespaces")
const ServerProcessor = require("@self/Processors/Server")
const ClientProcessor = require("@self/Processors/Client")

const ClientPacket = require("@self/PacketTypes/ClientPacket")
const ClientQuery = require("@self/PacketTypes/ClientQuery")
const ServerPacket = require("@self/PacketTypes/ServerPacket")
const ServerQuery = require("@self/PacketTypes/ServerQuery")

--const FilterContainer = require("@self/Utilities/FilterContainer")
--const RandomString = require("@self/Utilities/RandomString")

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
const typeNameLookups: { [StreamType<any>]: string } = {}
for name: string, streamType: StreamType<any> in (TypeStores :: any) :: { [string]: StreamType<any> } do
	if type(streamType) ~= "function" then
		typeNameLookups[streamType] = name
	end
end



function SwitchNet2.RegisterPacket<T>(parameters: { Mode: "Reliable" | "Unreliable", Type: T }): Packet<T>
	return if runContext == "Client" then
		ClientPacket(parameters.Mode, parameters.Type)
	else
		ServerPacket(parameters.Mode, parameters.Type)
end

function SwitchNet2.RegisterQuery<T1, T2>(parameters: { RequestType: T1, ResponseType: T2, Timeout: number? }): Query<T1, T2>
	return if runContext == "Client" then
		ClientQuery(parameters.RequestType, parameters.ResponseType, parameters.Timeout)
	else
		ServerQuery(parameters.RequestType, parameters.ResponseType, parameters.Timeout)
end

function SwitchNet2.RegisterNamespace<T>(name: string, packets: T, share: boolean?): T
	
	assert(#name <= NAMESPACE_NAME_SIZE_LIMIT, `Namespace name '{name}' is too large! Size limit is {NAMESPACE_NAME_SIZE_LIMIT}`)
	--assert(Namespaces[name] == nil, `Namespace '{name}' already exists!`)
	if Namespaces[name] then
		return (Namespaces[name] :: any) :: T
	end

	local typecasted: { [string]: Packet<any> } = packets :: any
	Namespaces[name] = typecasted

	for packetName: string in typecasted do
		assert(#packetName <= PACKET_NAME_SIZE_LIMIT, `Packet name '{packetName}' in namespace '{name}' is too large! Size limit is {PACKET_NAME_SIZE_LIMIT}`)
	end

	for packetName: string, packet: Packet<any> in typecasted do
		packet.Id = packetName
		packet.Namespace = name
	end

	if share and runContext == "Server" then
		SwitchNet2._shareNamespace(typecasted, name)
	end

	return packets

end



function SwitchNet2._convertStreamTypeToNameTree<T>(streamType: StreamType<T>): ConvertedTypeTree

	local name: string? = typeNameLookups[streamType :: StreamType<T>]
	if name then
		return { Name = name }
	end

	local typecasted = streamType :: StreamTypeWithArgs<T>
	local customName = typecasted.TypeName :: string
		
	local typeArgNames: { ConvertedTypeTree } = {}
	for i: number, v: StreamType<any> in typecasted.TypeArgs do
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
		local typeArgs: { StreamType<any> } = {}
		for index: number, data: { Name: string, Args: { ConvertedTypeTree }? } in typeData.Args do
			typeArgs[index] = SwitchNet2._convertNameTreeToStreamType(data)
		end
		return streamType(table.unpack(typeArgs))
	end

	return streamType

end



function SwitchNet2._shareNamespace(namespace: { [string]: Packet<any> | Query<any, any> }, name: string)

	if not SwitchNet2.NamespaceShareStore then return end
	if SwitchNet2.NamespaceShareStore:FindFirstChild(name) then return end

	local data: { any } = {}

	for _, v in namespace do
		local isQuery: boolean = (v :: any).Invoke ~= nil
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
	
	local value: StringValue = Instance.new("StringValue")
	value.Name = name
	value.Value = HttpService:JSONEncode(data)
	value.Parent = SwitchNet2.NamespaceShareStore

end

function SwitchNet2._registerRemoteNamespace(value: StringValue): { [string]: Packet<any> | Query<any, any> }?

	local name: string = value.Name
	if Namespaces[name] then return nil end --// Probably locally defined already somewhere

	local data = HttpService:JSONDecode(value.Value)
	
	local packets = {} :: { [string]: Packet<any> | Query<any, any> }

	for _, structure in data do
		local id: string = structure.Id
		local isQuery: boolean = structure.IsQuery

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
		local shareStore: Folder = Instance.new("Folder")
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

	for _, value: Instance in shareStore:GetChildren() do
		SwitchNet2._registerRemoteNamespace(value :: StringValue)
	end
end


--// Finalize

ServerProcessor.init(runContext)
ClientProcessor.init(runContext)



if OUTPUT_MESSAGE then
	
	local message = `SwitchNet2 {VERSION} - {runContext} initialized - @8ch99.`
	local logHistory = LogService:GetLogHistory() :: {
		{
			timestamp: number,
			message: string,
			messageType: Enum.MessageType,
		}
	}
	
	local hasDuplicateMessage: boolean = false
	for _, log in logHistory do
		if log.message == message then
			hasDuplicateMessage = true
			break
		end
	end

	if not hasDuplicateMessage then
		print(message)
	end

end



return table.freeze(SwitchNet2)