--// Author: 8ch99
--// Date written: 25th March 2026
--// SwitchNet2

--!strict
--!native
--!optimize 2

const NAMESPACE_NAME_SIZE_LIMIT: number = 32
const PACKET_NAME_SIZE_LIMIT: number = 64

--// Services

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const RunService = game:GetService("RunService")
const TestService = game:GetService("TestService")

--// Dependencies

const Byte = require("../Byte")
const Typedefs = require("../Typedefs")
const Namespaces = require("../Namespaces")



const function getPacketOrQueryAndVerifyPacket(packet: Typedefs.NetworkPacket): any

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

const ClientProcessor = {}


const sendStack: { NetworkPacket } = {}
const sendStackUnreliable: { NetworkPacket } = {}
const requestStack: { { Thread: thread, Timeout: number?, Packet: NetworkPacket } } = {}

const eventCallbacks = {} :: { [string]: (string, string, any) -> () }
const eventCallbacksUnreliable = {} :: { [string]: (string, string, any) -> () }
const responseHandlers = {} :: {
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

function ClientProcessor.Invoke<T1, T2>(query: Query<T1, T2>, buff: buffer, references: { any }, timeout: number?): T2
	local thread: thread = coroutine.running()
	table.insert(requestStack, {
		Thread = thread,
		Timeout = timeout,
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


	const compressStreamType: (StreamType<any>, any, number?) -> (buffer, { any }) = Byte.CompressStreamType
	const decompressStreamType: (StreamType<any>, buffer, { any }) -> any = Byte.DecompressStreamType


	ClientProcessor._replicationJob = RunService.PostSimulation:Connect(function(delta: number)

		if #requestStack > 0 then
			for _, request: { Thread: thread, Timeout: number?, Packet: NetworkPacket } in requestStack do

				local thread: thread = request.Thread

				local timeoutThread: thread?
				local requestThread: thread = task.spawn(function()
					local responsePacket: NetworkPacket? = remoteFunction:InvokeServer(request.Packet)
					
					if timeoutThread then
						task.cancel(timeoutThread)
						timeoutThread = nil
					end

					if not thread then return end --// probably was GCed

					if not responsePacket then
						coroutine.resume(thread, nil)
						return
					end

					local packet = getPacketOrQueryAndVerifyPacket(responsePacket)
					if not packet then
						coroutine.resume(thread, nil)
						return
					end

					local value: any = decompressStreamType(packet.ResponseStreamType, responsePacket.Data, responsePacket.References)
					coroutine.resume(thread, value)
				end)

				if request.Timeout ~= nil then
					timeoutThread = task.delay(request.Timeout, function()
						coroutine.resume(thread, nil)
						pcall(task.cancel, requestThread)
						timeoutThread = nil
					end)
				end

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



	const function ProcessIncomingRequest(incomingData: { NetworkPacket }, callbackList: { [string]: (string, string, any) -> () })

		if not next(callbackList) then return end
		
		--// Verify data first, before we deserialize anything
		if type(incomingData) ~= "table" then return end

		for _, networkPacket: NetworkPacket in incomingData do
			if not getPacketOrQueryAndVerifyPacket(networkPacket) then return end
		end

		for _, networkPacket: NetworkPacket in incomingData do
			local namespaceName: string = networkPacket.Namespace
			local packetName: string = networkPacket.Packet

			local namespace: { [string]: Packet<any> } = Namespaces[namespaceName]
			local packet: Packet<any> = namespace[packetName]

			local success1: boolean, value: any = pcall(decompressStreamType, (packet :: any).StreamType, networkPacket.Data, networkPacket.References)

			if not success1 or not value then return end --// 99% of the time it'd be a malformed packet (due to tampering)
			
			for name: string, callback: (string, string, any) -> () in callbackList do
				local success: boolean, result: any = pcall(task.spawn, callback, namespaceName, packetName, value)
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
		local packet = getPacketOrQueryAndVerifyPacket(networkPacket)
		if not packet then return nil end

		--// Ensure theres actually a response handler
		local handlerPool: { [string]: (any) -> any } = responseHandlers[networkPacket.Namespace]
		local responseHandler: ((any) -> any)? = if handlerPool then handlerPool[networkPacket.Packet] else nil
		if not responseHandler then return nil end

		--// Proceed!
		local success1: boolean, value: any = pcall(decompressStreamType, packet.RequestStreamType, networkPacket.Data, networkPacket.References)
		if not success1 or not value then return nil end

		local success: boolean, result: any = pcall(responseHandler, value)

		if not success then return nil end
		--// ^ Return nothing, safest choice

		local success2: boolean, buff: buffer, references: { any } = pcall(compressStreamType, packet.ResponseStreamType, result, packet.ResponseByteSize)
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