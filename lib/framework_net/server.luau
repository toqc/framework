-- framework_net/server.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local rf = Instance.new("RemoteFunction")
rf.Name = "framework_rf"
rf.Parent = ReplicatedStorage

local re = Instance.new("RemoteEvent")
re.Name = "framework_re"
re.Parent = ReplicatedStorage

local ure = Instance.new("UnreliableRemoteEvent")
ure.Name = "framework_ure"
ure.Parent = ReplicatedStorage

local functionTasks = {}
local event_tasks = {}
local unreliable_events_tasks = {}

local Net = {}

function Net.FireAllExcept(exceptPlayer: Player, eventType: string, taskName: string, ...: any)
	for _, player in Players:GetPlayers() do
		if player ~= exceptPlayer then
			if type(eventType) ~= "string" then
				return warn(`{type(eventType)} Recieved Expeceted string`)
			end

			if eventType == "Reliable" then
				re:FireClient(player, taskName, ...)
			elseif eventType == "Unreliable" then
				ure:FireClient(player, taskName, ...)
			else
				return warn(`eventType Must be Reliable or Unreliable, Recieved: {eventType}`)
			end
		end
	end
end

function Net.FireAll(eventType: string, taskName: string, ...: any)
	if type(eventType) ~= "string" then
		return warn(`{type(eventType)} Recieved Expeceted string`)
	end

	if eventType == "Reliable" then
		re:FireAllClients(taskName, ...)
	elseif eventType == "Unreliable" then
		ure:FireAllClients(taskName, ...)
	else
		return warn(`eventType Must be Reliable or Unreliable, Recieved: {eventType}`)
	end

	return nil
end

function Net.Fire(player: Player, eventType: string, taskName: string, ...: any)
	if type(eventType) ~= "string" then
		return warn(`{type(eventType)} Recieved Expeceted string`)
	end

	if eventType == "Reliable" then
		re:FireClient(player, taskName, ...)
	elseif eventType == "Unreliable" then
		ure:FireClient(player, taskName, ...)
	else
		return warn(`eventType Must be Reliable or Unreliable, Recieved: {eventType}`)
	end
end

function Net.RegisterFunction(taskName: string, callback: (Player, ...any) -> any)
	functionTasks[taskName] = callback
end

function Net.RegisterEvent(taskName: string, callback: (Player, ...any) -> ())
	if event_tasks[taskName] then
		table.insert(event_tasks[taskName], callback)
	else
		event_tasks[taskName] = {}
		table.insert(event_tasks[taskName], callback)
	end
end

function Net.RegisterUnreliableEvent(taskName: string, callback: (Player, ...any) -> ())
	if unreliable_events_tasks[taskName] then
		table.insert(unreliable_events_tasks[taskName], callback)
	else
		unreliable_events_tasks[taskName] = {}
		table.insert(unreliable_events_tasks[taskName], callback)
	end
end

rf.OnServerInvoke = function(player, taskName, ...)
	local task = functionTasks[taskName]
	if task then
		return task(player, ...)
	else
		warn(("Unknown network function requested: %s"):format(taskName))
		return nil
	end
end

re.OnServerEvent:Connect(function(player, taskName, ...)
	local task = event_tasks[taskName]
	if task then
		for _, f in task do
			f(player, ...)
		end
	else
		warn(("Unknown network event received: %s"):format(taskName))
	end
end)

ure.OnServerEvent:Connect(function(player, taskName, ...)
	local task = unreliable_events_tasks[taskName]
	if task then
		for _, f in task do
			f(player, ...)
		end
	else
		warn(("Unknown network unreliable_event received: %s"):format(taskName))
	end
end)

function Net.RegisterService(service)
	for key, value in pairs(service) do
		if type(value) == "function" then
			local taskName = service.Name .. "." .. key
			Net.RegisterFunction(taskName, function(player, ...)
				return value(service, player, ...)
			end)
		end
	end
end

return Net
