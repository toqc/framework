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

function Net.RegisterEvent(taskName: string, callback: (Player, ...any) -> ())
	eventTasks[taskName] = callback
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
		task(player, ...)
	else
		warn(("Unknown network event received: %s"):format(taskName))
	end
end)

function Net.RegisterService(service)
	for key, value in pairs(service) do
		if type(value) == "function" then
			local taskName = service.Name .. "." .. key
			print("Registering:", taskName)

			Net.RegisterFunction(taskName, function(player, ...)
				return value(service, player, ...)
			end)
		end
	end
end

return Net
