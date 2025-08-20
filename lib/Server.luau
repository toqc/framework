local Types = require(script.Parent.Types)

local util = script.Parent.util
local Promise = require(util.Promise)

local framework_net = require(script.Parent.framework_net.server)

local Server = {}

local managers: { Types.Manager } = {}
local services: { Types.Service } = {}

local minPriority = 1
local maxPriority = 9
for i = 1, maxPriority do
	managers[i] = {}
end

local started = false
local startedComplete = false
local onStartedComplete = Instance.new("BindableEvent")

function Server.CreateManager(manager: {})
	do
		assert(not started, "Can't Create Managers After Running Server.Start")
		assert(type(manager) == "table", "Manager Must be a Table")
		assert(type(manager.Name) == "string", `Manager.Name must be a string; got {type(manager.Name)}`)
		assert(not Server.GetManager(manager.Name), `Manager: {manager.Name} already exists`)
		assert(
			manager.Priority and type(manager.Priority) == "number",
			`{manager.Name} Must Have Priority that exists or is a Number.`
		)
	end
	managers[math.clamp(manager.Priority, minPriority, maxPriority)][manager.Name] = manager :: Types.Manager
	return manager
end

function Server.CreateService(service: {})
	do
		assert(not started, "Can't Create Services After Running Server.Start")
		assert(type(service) == "table", "Service Must be a Table")
		assert(type(service.Name) == "string", `Manager.Name must be a string; got {type(service.Name)}`)
		assert(not service[service.Name], `Service: {service.Name} already exists`)
		assert(type(service.Shared) == "boolean", `Service.Shared must be a boolean; got {type(service.Name)}`)
	end
	services[service.Name] = service

	if service.Shared then
		framework_net.RegisterService(service)
	end

	return service
end

function Server.GetGameService(service: string)
	return game:GetService(service)
end

function Server.GetService(service: string)
	if services[service] then
		return services[service]
	else
		return warn(("Service Not Found for: %s"):format(service))
	end
end

function Server.GetManager(name: string)
	return managers[name]
end

function Server.Network()
	return framework_net
end

function Server.Start()
	if started then
		warn("Server Framework Already Started.")
		return
	end

	started = true

	for _, prioBucket in managers do
		if type(prioBucket) == "table" then
			table.freeze(prioBucket)
		end
	end

	return Promise.new(function(resolve)
		local initPromises = {}

		for priority = minPriority, maxPriority do
			local bucket = managers[priority]
			if bucket then
				for _, m in bucket do
					if type(m.Init) == "function" then
						table.insert(
							initPromises,
							Promise.new(function(r)
								debug.setmemorycategory(m.Name)
								m:Init()
								r()
							end)
						)
					end
				end
			end
		end

		resolve(Promise.all(initPromises))
	end):andThen(function()
		for priority = minPriority, maxPriority do
			local bucket = managers[priority]
			if bucket then
				for _, m in bucket do
					if type(m.Start) == "function" then
						task.spawn(function()
							debug.setmemorycategory(m.Name)
							m:Start()
						end)
					end
				end
			end
		end

		local flatManagers = {}
		for _, bucket in managers do
			for name, m in bucket do
				flatManagers[name] = m
			end
		end
		managers = flatManagers
		table.freeze(managers)

		startedComplete = true
		onStartedComplete:Fire()
		task.defer(function()
			onStartedComplete:Destroy()
		end)
	end)
end

function Server.OnStart()
	if startedComplete then
		return Promise.resolve()
	else
		return Promise.fromEvent(onStartedComplete.Event)
	end
end

function Server.IsStarting()
	return started and not startedComplete
end

function Server.HasStarted()
	return startedComplete
end

framework_net.RegisterFunction("FetchService", function(_: Player, serviceName: string)
	local service = Server.GetService(serviceName)
	if not service then
		warn(`Service: {serviceName} Not Found.`)
		return nil
	end

	if service.Shared then
		local result = {
			Name = service.Name,
		}

		for key, value in pairs(service) do
			if type(value) == "function" then
				result[key] = true
			end
		end

		return result
	else
		warn(`Access Denied to: {serviceName}`)
		return nil
	end
end)

return Server
