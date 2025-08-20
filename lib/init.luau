local RunService = game:GetService("RunService")

if RunService:IsServer() then
	return require(script.Server)
else
	local Server = script:FindFirstChild("Server")
	if Server and RunService:IsRunning() then
		Server:Destroy()
	end

	return require(script.Client)
end