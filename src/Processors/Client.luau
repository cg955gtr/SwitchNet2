--// Author: 8ch99
--// Date written: 25th March 2026
--// SwitchNet2

--!strict
--!native
--!optimize 2

const NAMESPACE_NAME_SIZE_LIMIT = 32
const PACKET_NAME_SIZE_LIMIT = 64

--// Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TestService = game:GetService("TestService")

--// Dependencies

local Byte = require("../Byte")
local Typedefs = require("../Typedefs")
local Namespaces = require("../Namespaces")

local function GetPacketOrQueryAndVerifyPacket(packet: Typedefs.NetworkPacket): any
	if type(packet) ~= "table" then return end
	if type(packet.Data) ~= "buffer" then return end
	if type(packet.References) ~= "table" then return end

	if type(packet.Namespace) ~= "string" or #packet.Namespace > NAMESPACE_NAME_SIZE_LIMIT then return end
	local namespace = Namespaces[packet.Namespace]
	if not namespace then return end

	if type(packet.Packet) ~= "string" or #packet.Packet > PACKET_NAME_SIZE_LIMIT then return end

	local realPacket = namespace[packet.Packet]
	if not realPacket then return end

	return realPacket
end

--// Typedefs

type StreamType<T> = Typedefs.StreamType<T>
type Packet<T> = Typedefs.Packet<T>
type Query<T1, T2> = Typedefs.Query<T1, T2>
type NetworkPacket = Typedefs.NetworkPacket

--// @module ClientProcessor

local ClientProcessor = {}


local sendStack = {} :: { NetworkPacket }
local sendStackUnreliable = {} :: { NetworkPacket }
local requestStack = {} :: { { Thread: thread, Packet: NetworkPacket } }

local eventCallbacks = {} :: { [string]: (string, string, any) -> () }
local eventCallbacksUnreliable = {} :: { [string]: (string, string, any) -> () }
local responseHandlers = {} :: {
	[string]: {
		[string]: (any) -> any,
	}
}



function ClientProcessor.Bind(id: string, callback: (string, string, any) -> ())
	eventCallbacks[id] = callback
end

function ClientProcessor.Unbind(id: string)
	eventCallbacks[id] = nil
end

function ClientProcessor.BindUnreliable(id: string, callback: (string, string, any) -> ())
	eventCallbacksUnreliable[id] = callback
end

function ClientProcessor.UnbindUnreliable(id: string)
	eventCallbacksUnreliable[id] = nil
end

function ClientProcessor.SetResponseHandler(namespace: string, packet: string, callback: (any) -> any)
	local namespaceStore = responseHandlers[namespace]
	if not namespaceStore then
		namespaceStore = {}
		responseHandlers[namespace] = namespaceStore
	end

	namespaceStore[packet] = callback
end

function ClientProcessor.RemoveResponseHandler(namespace: string, packet: string)
	local namespaceStore = responseHandlers[namespace]
	if not namespaceStore then return end
	if not namespaceStore[packet] then return end
	
	namespaceStore[packet] = nil
end



function ClientProcessor.Queue<T>(packet: Packet<T>, buff: buffer, references: { any })
	table.insert(sendStack, {
		Namespace = packet.Namespace,
		Packet = packet.Id,
		Data = buff,
		References = references,
	})
end

function ClientProcessor.QueueUnreliable<T>(packet: Packet<T>, buff: buffer, references: { any })
	table.insert(sendStackUnreliable, {
		Namespace = packet.Namespace,
		Packet = packet.Id,
		Data = buff,
		References = references,
	})
end

function ClientProcessor.Invoke<T1, T2>(query: Query<T1, T2>, buff: buffer, references: { any }): T2
	local thread = coroutine.running()
	table.insert(requestStack, {
		Thread = thread,
		Packet = {
			Namespace = query.Namespace,
			Packet = query.Id,
			Data = buff,
			References = references,
		}
	})

	return coroutine.yield()
end




function ClientProcessor.init(runContext: "Server" | "Client")
	
	if runContext ~= "Client" then return end

	--// Get remote events
	local remoteEvent = ReplicatedStorage:WaitForChild("SwitchNet2_Reliable") :: RemoteEvent
	local unreliableRemoteEvent = ReplicatedStorage:WaitForChild("SwitchNet2_Unreliable") :: UnreliableRemoteEvent
	local remoteFunction = ReplicatedStorage:WaitForChild("SwitchNet2_Function") :: RemoteFunction


	ClientProcessor._replicationJob = RunService.PostSimulation:Connect(function(delta: number)

		if #requestStack > 0 then
			for _, request in requestStack do
				local thread = request.Thread
				task.spawn(function()
					local responsePacket: NetworkPacket? = remoteFunction:InvokeServer(request.Packet)
					if not responsePacket then
						coroutine.resume(thread, nil)
						return
					end

					local packet = GetPacketOrQueryAndVerifyPacket(responsePacket)
					if not packet then
						coroutine.resume(thread, nil)
						return
					end

					local value = Byte.DecompressStreamType(packet.ResponseStreamType, responsePacket.Data, responsePacket.References)
					coroutine.resume(thread, value)
				end)
			end

			table.clear(requestStack)
		end

		if #sendStack > 0 then
			remoteEvent:FireServer(sendStack)
			table.clear(sendStack)
		end

		if #sendStackUnreliable > 0 then
			unreliableRemoteEvent:FireServer(sendStackUnreliable)
			table.clear(sendStackUnreliable)
		end

	end)



	local function ProcessIncomingRequest(incomingData: { NetworkPacket }, callbackList: { [string]: (string, string, any) -> () })
		if not next(callbackList) then return end
		
		--// Verify data first, before we deserialize anything
		if type(incomingData) ~= "table" then return end

		for _, networkPacket in incomingData do
			if not GetPacketOrQueryAndVerifyPacket(networkPacket) then return end
		end

		for _, networkPacket in incomingData do
			local namespaceName = networkPacket.Namespace
			local packetName = networkPacket.Packet

			local namespace = Namespaces[namespaceName]
			local packet = namespace[packetName]

			local success1, value = pcall(Byte.DecompressStreamType, packet.StreamType, networkPacket.Data, networkPacket.References)

			if not success1 or not value then return end --// 99% of the time it'd be a malformed packet (due to tampering)
			
			for name, callback in callbackList do
				local success, result = pcall(task.spawn, callback, namespaceName, packetName, value)
				if not success then
					TestService:Error(`SwitchNet2.ClientProcessor: Callback '{name}' Error:\n{result}`)
				end
			end
		end
		
	end


	ClientProcessor._onServerEvent = remoteEvent.OnClientEvent:Connect(function(incomingData: { NetworkPacket })
		ProcessIncomingRequest(incomingData, eventCallbacks)
	end)

	ClientProcessor._onServerEventUnreliable = unreliableRemoteEvent.OnClientEvent:Connect(function(incomingData: { NetworkPacket })
		ProcessIncomingRequest(incomingData, eventCallbacksUnreliable)
	end)



	remoteFunction.OnClientInvoke = function(networkPacket: NetworkPacket): NetworkPacket?
		if not next(responseHandlers) then return nil end

		--// Verify data first, before we deserialize anything
		local packet = GetPacketOrQueryAndVerifyPacket(networkPacket)
		if not packet then return nil end

		--// Ensure theres actually a response handler
		local handlerPool = responseHandlers[networkPacket.Namespace]
		local responseHandler = if handlerPool then handlerPool[networkPacket.Packet] else nil
		if not responseHandler then return nil end

		--// Proceed!
		local success1, value = pcall(Byte.DecompressStreamType, packet.RequestStreamType, networkPacket.Data, networkPacket.References)
		if not success1 or not value then return nil end

		local success, result = pcall(responseHandler, value)

		if not success then return nil end
		--// ^ Return nothing, safest choice

		local success2, buff, references = pcall(Byte.CompressStreamType, packet.ResponseStreamType, result, packet.ResponseByteSize)
		if not success2 or not buff or not references then return nil end

		--// Relay!
		return {
			Namespace = networkPacket.Namespace,
			Packet = networkPacket.Packet,
			Data = buff,
			References = references,
		}
	end

end



return ClientProcessor