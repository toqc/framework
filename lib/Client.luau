local Types = require(script.Parent.Types)

local util = script.Parent.framework_util
local Promise = require(util.Promise)

local framework_net = require(script.Parent.framework_net.client)

local Client = {}

local controllers: { Types.Controller } = {}
local services: { Types.Service } = {}
local utilities: { Types.Utility } | nil = {}
local data: { Types.Data } | nil = {}

local minPriority = 1
local maxPriority = 9
for i = 1, maxPriority do
	controllers[i] = {}
end

local started: boolean = false
local startedComplete = false
local onStartedComplete = Instance.new("BindableEvent")

local function fetchService(serviceName)
	local result = framework_net.Invoke("FetchService", serviceName)
	if result then
		local proxy = {}
		setmetatable(proxy, {
			__index = function(_, key)
				if result[key] == true then
					return function(...)
						return framework_net.Invoke(result.Name .. "." .. key, ...)
					end
				end
			end,
		})

		services[result.Name] = proxy
		return proxy
	else
		warn(("Service Not Found For: %s"):format(serviceName))
		return nil
	end
end

function Client.Network()
	return framework_net
end

function Client.AddUtility(name: string, utility: {}): Types.Utility
	do
		assert(not started, "Can't Add Utility After Running Client.Start")
		assert(type(utility) == "table", "Utility Must be a Table")
	end
	utilities[name] = utility
end

function Client.CreateShared(Folder: Folder)
	local newFolder = Folder:Clone()
	newFolder.Parent = script

	if newFolder:FindFirstChild("Utility") then
		for _, module in newFolder.Utility:GetChildren() do
			if not module:IsA("ModuleScript") then continue end
			utilities[module.Name] = require(module)
		end
	end
	if newFolder:FindFirstChild("Data") then
		for _, module in newFolder.Data:GetChildren() do
			if not module:IsA("ModuleScript") then continue end
			data[module.Name] = require(module)
		end
	end
end

function Client.CreateController(controller: {})
	do
		assert(not started, "Can't Create Controllers After Running Client.Start")
		assert(type(controller) == "table", "Controller Must be a Table")
		assert(type(controller.Name) == "string", `Controller.Name must be a string; got {type(controller.Name)}`)
		assert(not Client.GetController(controller.Name), `Controller {controller.Name} already exists`)
		assert(
			controller.Priority and type(controller.Priority) == "number",
			`{controller.Name} Must Have Priority that exists or is a Number.`
		)
	end

	controllers[math.clamp(controller.Priority, minPriority, maxPriority)][controller.Name] =
		controller :: Types.Controller

	return controller
end

function Client.GetGameService(service: string)
	return game:GetService(service)
end

function Client.GetData(DataType: string)
	assert(type(DataType) == "string", `Expected [STRING] for Client.GetData got [{string.upper(type(DataType))}]`)
	if data == nil then
		return warn("Data Folder Wasn't Included in Shared Folder on Client Start.")
	elseif not data[DataType] then
		return warn(`{DataType} not Found in Data Dir.`)
	else
		return data[DataType]
	end
end

function Client.GetUtility(Utility: string)
	assert(type(Utility) == "string", `Expected [STRING] for Client.GetUtility got [{string.upper(type(Utility))}]`)
	if utilities == nil then
		return warn("Utility Folder Wasn't Included in Shared Folder on Client Start.")
	elseif not utilities[Utility] then
		return warn(`{Utility} not Found in Data Dir.`)
	else
		return utilities[Utility]
	end
end

function Client.GetService(service: string)
	if services[service] then
		return services[service]
	else
		return fetchService(service)
	end
end

function Client.GetController(name: string)
	return controllers[name]
end

function Client.Start()
	if started then
		warn("Client Framework Already Started.")
		return
	end

	started = true

	for _, prioBucket in controllers do
		if type(prioBucket) == "table" then
			table.freeze(prioBucket)
		end
	end

	return Promise.new(function(resolve)
		local initPromises = {}

		for priority = minPriority, maxPriority do
			local bucket = controllers[priority]
			if bucket then
				for _, c in bucket do
					if type(c.Init) == "function" then
						table.insert(
							initPromises,
							Promise.new(function(r)
								debug.setmemorycategory(c.Name)
								c:Init()
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
			local bucket = controllers[priority]
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

		local flatControllers = {}
		for _, bucket in controllers do
			for name, m in bucket do
				flatControllers[name] = m
			end
		end
		controllers = flatControllers
		table.freeze(controllers)

		startedComplete = true
		onStartedComplete:Fire()
		task.defer(function()
			onStartedComplete:Destroy()
		end)
	end)
end

function Client.OnStart()
	if startedComplete then
		return Promise.resolve()
	else
		return Promise.fromEvent(onStartedComplete.Event)
	end
end

function Client.IsStarting()
	return started and not startedComplete
end

function Client.HasStarted()
	return startedComplete
end

return Client
