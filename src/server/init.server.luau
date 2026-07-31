-- src/server/init.server.luau
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

Knit.AddServices(script.Services)
Knit.Start():andThen(function()
	print("Knit arrancado en el SERVIDOR")
end):catch(warn)