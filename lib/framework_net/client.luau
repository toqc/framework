-- framework_net/client.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local rf: RemoteFunction = ReplicatedStorage:WaitForChild("framework_rf")
local re: RemoteEvent = ReplicatedStorage:WaitForChild("framework_re")
local ure: UnreliableRemoteEvent = ReplicatedStorage:WaitForChild("framework_ure")

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

return Net
