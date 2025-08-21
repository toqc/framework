-- framework_net/client.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local rf: RemoteFunction = ReplicatedStorage:WaitForChild("framework_rf")
local re: RemoteEvent = ReplicatedStorage:WaitForChild("framework_re")
local ure: UnreliableRemoteEvent = ReplicatedStorage:WaitForChild("framework_ure")

local eventTasks = {}
local unreliable_events_Tasks = {}

local Net = {}

function Net.Fire(eventType: "Reliable" | "Unreliable", taskName, ...): nil
	if type(eventType) ~= "string" then
		return warn(`{type(eventType)} Recieved Expeceted string`)
	end

	if eventType == "Reliable" then
		re:FireServer(taskName, ...)
	elseif eventType == "Unreliable" then
		ure:FireServer(taskName, ...)
	else
		return warn(`eventType Must be Reliable or Unreliable, Recieved: {eventType}`)
	end

	return nil
end

function Net.Invoke(taskName: string, ...): any
	return rf:InvokeServer(taskName, ...)
end

function Net.FetchService(name: string)
	local proxy = {}

	setmetatable(proxy, {
		__index = function(_, key)
			return function(...)
				return rf:InvokeServer(name .. "." .. key, ...)
			end
		end,
	})

	return proxy
end

function Net.RegisterEvent(taskName: string, callback: (...any) -> ())
	if eventTasks[taskName] then
		table.insert(eventTasks[taskName], callback)
	else
		eventTasks[taskName] = {}
		table.insert(eventTasks[taskName], callback)
	end
end

function Net.RegisterUnreliableEvent(taskName: string, callback: (...any) -> ())
	if unreliable_events_Tasks[taskName] then
		table.insert(eventTasks[taskName], callback)
	else
		unreliable_events_Tasks[taskName] = {}
		table.insert(unreliable_events_Tasks[taskName], callback)
	end
end

re.OnClientEvent:Connect(function(taskName, ...)
	local task = eventTasks[taskName]
	if task then
		for _, f in task do
			f(...)
		end
	else
		warn(("Unknown network event received: %s"):format(taskName))
	end
end)

ure.OnClientEvent:Connect(function(taskName, ...)
	local task = unreliable_events_Tasks[taskName]
	if task then
		for _, f in task do
			f(...)
		end
	else
		warn(("Unknown network unreliable_event received: %s"):format(taskName))
	end
end)

return Net
