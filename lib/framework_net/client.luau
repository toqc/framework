-- framework_net/client.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local rf: RemoteFunction = ReplicatedStorage:WaitForChild("framework_rf")
local re: RemoteEvent = ReplicatedStorage:WaitForChild("framework_re")

local Net = {}

function Net.Fire(taskName,...): nil
    re:FireServer(taskName,...)
    return nil
end

function Net.Invoke(taskName: string, ...): any
	return rf:InvokeServer(taskName, ...)
end

return Net