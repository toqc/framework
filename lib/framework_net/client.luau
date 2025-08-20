-- framework_net/client.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local rf: RemoteFunction = ReplicatedStorage:WaitForChild("framework_rf")
local re: RemoteEvent = ReplicatedStorage:WaitForChild("framework_re")

local Net = {}

function Net.Fire(taskName, ...): nil
	re:FireServer(taskName, ...)
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

return Net
