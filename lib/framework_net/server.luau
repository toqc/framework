-- framework_net/server.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local rf = Instance.new("RemoteFunction")
rf.Name = "framework_rf"
rf.Parent = ReplicatedStorage

local re = Instance.new("RemoteEvent")
re.Name = "framework_re"
re.Parent = ReplicatedStorage

local functionTasks = {}
local eventTasks = {}

local Net = {}

function Net.RegisterFunction(taskName: string, callback: (Player, ...any) -> any)
	functionTasks[taskName] = callback
end

function Net.RegisterEvent(eventName: string, callback: (Player, ...any) -> ())
	eventTasks[eventName] = callback
end

function Net.FireClient(player: Player, eventName: string, ...: any)
	re:FireClient(player, eventName, ...)
end

function Net.FireAllClients(eventName: string, ...: any)
	re:FireAllClients(eventName, ...)
end

function Net.FireOthers(except: Player, eventName: string, ...: any)
	for _, plr in game.Players:GetPlayers() do
		if plr ~= except then
			re:FireClient(plr, eventName, ...)
		end
	end
end

rf.OnServerInvoke = function(player, taskName, ...)
	local task = functionTasks[taskName]
	if task then
		return task(player, ...)
	else
		warn(("Unknown RF task requested: %s"):format(taskName))
		return nil
	end
end

re.OnServerEvent:Connect(function(player, eventName, ...)
	local handler = eventTasks[eventName]
	if handler then
		handler(player, ...)
	else
		warn(("Unknown RE event received: %s"):format(eventName))
	end
end)

return Net