--// Author: 8ch99
--// Date written: 25th March 2026
--// SwitchNet2

--!strict
--!native
--!optimize 2

const NAMESPACE_NAME_SIZE_LIMIT: number = 32
const PACKET_NAME_SIZE_LIMIT: number = 64

--// Services

const Players = game:GetService("Players")
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const RunService = game:GetService("RunService")
const TestService = game:GetService("TestService")

--// Dependencies

const Byte = require("../Byte")
const Typedefs = require("../Typedefs")
const Namespaces = require("../Namespaces")



const function getChildAndCreateIfNil(parent: Instance, name: string, className: string): Instance
	local child: Instance? = parent:FindFirstChild(name)
	if child then
		return child
	end

	local newInstance: Instance = Instance.new(className)
	newInstance.Name = name
	newInstance.Parent = parent

	return newInstance
end

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

--// @module ServerProcessor

const ServerProcessor = {}


const sendStack: { [Player]: { NetworkPacket } } = {}
const sendStackUnreliable: { [Player]: { NetworkPacket } } = {}
const globalSendStack: { NetworkPacket } = {}
const globalSendStackUnreliable: { NetworkPacket } = {}
const requestStack: { [Player]: { { Thread: thread, Timeout: number?, Packet: NetworkPacket } } } = {}

const processingRequests: { [thread]: { Player: Player, RequestThread: thread, TimeoutThread: thread? } } = {}

const eventCallbacks = {} :: { [string]: (Player, string, string, any) -> () }
const eventCallbacksUnreliable = {} :: { [string]: (Player, string, string, any) -> () }
const responseHandlers = {} :: {
	[string]: {
		[string]: (any, Player) -> any,
	}
}


--[[
function ServerProcessor._getCallbacks(): { [string]: (Player, string, string, any) -> () }
	return eventCallbacks
end

function ServerProcessor._getUnrCallbacks(): { [string]: (Player, string, string, any) -> () }
	return eventCallbacksUnreliable
end
]]


function ServerProcessor.Bind(id: string, callback: (Player, string, string, any) -> ())
	eventCallbacks[id] = callback
end

function ServerProcessor.Unbind(id: string)
	eventCallbacks[id] = nil
end

function ServerProcessor.BindUnreliable(id: string, callback: (Player, string, string, any) -> ())
	eventCallbacksUnreliable[id] = callback
end

function ServerProcessor.UnbindUnreliable(id: string)
	eventCallbacksUnreliable[id] = nil
end



function ServerProcessor.SetResponseHandler(namespace: string, packet: string, callback: (any, Player) -> any)
	local namespaceStore = responseHandlers[namespace]
	if not namespaceStore then
		namespaceStore = {}
		responseHandlers[namespace] = namespaceStore
	end

	namespaceStore[packet] = callback
end

function ServerProcessor.RemoveResponseHandler(namespace: string, packet: string)
	local namespaceStore = responseHandlers[namespace]
	if not namespaceStore then return end
	if not namespaceStore[packet] then return end

	namespaceStore[packet] = nil
end



function ServerProcessor.Queue<T>(packet: Packet<T>, buff: buffer, references: { any }, player: Player)
	local stack: { NetworkPacket } = sendStack[player]
	if not stack then
		stack = {}
		sendStack[player] = stack
	end

	table.insert(stack, {
		Namespace = packet.Namespace,
		Packet = packet.Id,
		Data = buff,
		References = references,
	})
end

function ServerProcessor.QueueToAll<T>(packet: Packet<T>, buff: buffer, references: { any })
	table.insert(globalSendStack, {
		Namespace = packet.Namespace,
		Packet = packet.Id,
		Data = buff,
		References = references,
	})
end

function ServerProcessor.QueueUnreliable<T>(packet: Packet<T>, buff: buffer, references: { any }, player: Player)
	local stack: { NetworkPacket } = sendStackUnreliable[player]
	if not stack then
		stack = {}
		sendStackUnreliable[player] = stack
	end

	table.insert(stack, {
		Namespace = packet.Namespace,
		Packet = packet.Id,
		Data = buff,
		References = references,
	})
end

function ServerProcessor.QueueToAllUnreliable<T>(packet: Packet<T>, buff: buffer, references: { any })
	table.insert(globalSendStackUnreliable, {
		Namespace = packet.Namespace,
		Packet = packet.Id,
		Data = buff,
		References = references,
	})
end

function ServerProcessor.Invoke<T1, T2>(query: Query<T1, T2>, player: Player, buff: buffer, references: { any }, timeout: number?): T2
	local thread: thread = coroutine.running()
	local stack: { { Thread: thread, Timeout: number?, Packet: NetworkPacket } } = requestStack[player]
	if not stack then
		stack = {}
		requestStack[player] = stack
	end
	
	table.insert(stack, {
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



function ServerProcessor.init(runContext: "Server" | "Client")
	
	if runContext ~= "Server" then return end

	--// Get remote events
	local remoteEvent = getChildAndCreateIfNil(ReplicatedStorage, "SwitchNet2_Reliable", "RemoteEvent") :: RemoteEvent
	local unreliableRemoteEvent = getChildAndCreateIfNil(ReplicatedStorage, "SwitchNet2_Unreliable", "UnreliableRemoteEvent") :: UnreliableRemoteEvent
	local remoteFunction = getChildAndCreateIfNil(ReplicatedStorage, "SwitchNet2_Function", "RemoteFunction") :: RemoteFunction


	const compressStreamType: (StreamType<any>, any, number?) -> (buffer, { any }) = Byte.CompressStreamType
	const decompressStreamType: (StreamType<any>, buffer, { any }) -> any = Byte.DecompressStreamType


	ServerProcessor._playerRemoving = Players.PlayerRemoving:Connect(function(player: Player)

		if sendStack[player] then
			sendStack[player] = nil
		end

		if sendStackUnreliable[player] then
			sendStackUnreliable[player] = nil
		end

		if requestStack[player] then
			requestStack[player] = nil
		end

		for mainThread: thread, data in processingRequests do
			if data.Player == player then
				coroutine.resume(mainThread, nil)

				pcall(task.cancel, data.RequestThread)
				if data.TimeoutThread then
					pcall(task.cancel, data.TimeoutThread)
				end
			end
		end

	end)


	ServerProcessor._replicationJob = RunService.PostSimulation:Connect(function()

		--// Per-player stacks
		for player: Player, requests: { { Thread: thread, Timeout: number?, Packet: NetworkPacket } } in requestStack do
			for _, request: { Thread: thread, Timeout: number?, Packet: NetworkPacket } in requests do

				local thread: thread = request.Thread
				
				local timeoutThread: thread?
				local requestThread: thread = task.spawn(function()
					local responsePacket: NetworkPacket? = remoteFunction:InvokeClient(player, request.Packet)

					if timeoutThread then
						task.cancel(timeoutThread)
						timeoutThread = nil
					end

					if not thread then return end --// probably was GCed
					
					processingRequests[thread] = nil
					
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

				processingRequests[thread] = {
					Player = player,
					RequestThread = requestThread,
					TimeoutThread = timeoutThread
				}

			end
		end

		table.clear(requestStack)



		for player: Player, packets: { NetworkPacket } in sendStack do
			if #packets > 0 then
				remoteEvent:FireClient(player, packets)
			end
		end

		for player: Player, packets: { NetworkPacket } in sendStackUnreliable do
			if #packets > 0 then
				unreliableRemoteEvent:FireClient(player, packets)
			end
		end

		table.clear(sendStack)
		table.clear(sendStackUnreliable)

		--// Global stacks (FireAllClients)
		if #globalSendStack > 0 then
			remoteEvent:FireAllClients(globalSendStack)
			table.clear(globalSendStack)
		end

		if #globalSendStackUnreliable > 0 then
			unreliableRemoteEvent:FireAllClients(globalSendStackUnreliable)
			table.clear(globalSendStackUnreliable)
		end

	end)



	const function processIncomingCall(player: Player, incomingData: { NetworkPacket }, callbackList: { [string]: (Player, string, string, any) -> () })
		
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

			if not packet._isBound then
				--// There is nothing to process this data
				continue
			end


			--// pre-process filters
			if not packet._preProcessFilters:Check(player) then continue end

			local success1: boolean, value: any = pcall(decompressStreamType, (packet :: any).StreamType, networkPacket.Data, networkPacket.References)
			if not success1 or not value then return end --// 99% of the time it'd be a malformed packet (due to tampering)

			--// post-process filters
			if not packet._filters:Check(value, player) then continue end

			
			for name, callback: (Player, string, string, any) -> () in callbackList do
				local success: boolean, result: any = pcall(task.spawn, callback, player, namespaceName, packetName, value)
				if not success then
					TestService:Error(`SwitchNet2.ServerProcessor: Callback '{name}' Error:\n{result}`)
				end
			end
		end
		
	end


	ServerProcessor._onServerEvent = remoteEvent.OnServerEvent:Connect(function(player: Player, incomingData: { NetworkPacket })
		processIncomingCall(player, incomingData, eventCallbacks)
	end)

	ServerProcessor._onServerEventUnreliable = unreliableRemoteEvent.OnServerEvent:Connect(function(player: Player, incomingData: { NetworkPacket })
		processIncomingCall(player, incomingData, eventCallbacksUnreliable)
	end)



	remoteFunction.OnServerInvoke = function(player: Player, networkPacket: NetworkPacket): NetworkPacket?

		if not next(responseHandlers) then return nil end

		--// Verify data first, before we deserialize anything
		local packet = getPacketOrQueryAndVerifyPacket(networkPacket)
		if not packet then return nil end

		--// Ensure theres actually a response handler
		local handlerPool: { [string]: (any, Player) -> any } = responseHandlers[networkPacket.Namespace]
		local responseHandler: ((any, Player) -> any)? = if handlerPool then handlerPool[networkPacket.Packet] else nil
		
		if not responseHandler then
			--// There is nothing to process this data
			return nil
		end

		--// pre-process filters
		if not packet._preProcessFilters:Check(player) then return nil end
		
		--// Proceed!
		local success1: boolean, value: any = pcall(decompressStreamType, packet.RequestStreamType, networkPacket.Data, networkPacket.References)
		if not success1 or not value then return nil end

		local success: boolean, result: any = pcall(responseHandler, value, player)
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



return ServerProcessor