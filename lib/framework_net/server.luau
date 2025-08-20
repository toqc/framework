-- framework_net/server.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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
local eventTasks = {}
local unreliable_events_Tasks = {}

local Net = {}

function Net.RegisterFunction(taskName: string, callback: (Player, ...any) -> any)
	functionTasks[taskName] = callback
end

function Net.RegisterEvent(taskName: string, callback: (Player, ...any) -> ())
	if eventTasks[taskName] then
		table.insert(eventTasks[taskName], callback)
	else
		eventTasks[taskName] = {}
		table.insert(eventTasks[taskName], callback)
	end
end

function Net.RegisterUnreliableEvent(taskName: string, callback: (Player, ...any) -> ())
	if unreliable_events_Tasks[taskName] then
		table.insert(eventTasks[taskName], callback)
	else
		unreliable_events_Tasks[taskName] = {}
		table.insert(unreliable_events_Tasks[taskName], callback)
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
	local task = eventTasks[taskName]
	if task then
		for _, f in task do
			f(player, ...)
		end
	else
		warn(("Unknown network event received: %s"):format(taskName))
	end
end)

ure.OnServerEvent:Connect(function(player, taskName, ...)
	local task = unreliable_events_Tasks[taskName]
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
