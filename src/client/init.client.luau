-- src/client/init.client.luau
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

Knit.AddControllers(script.Controllers)
Knit.Start():andThen(function()
	print("Knit arrancado en el CLIENTE")
end):catch(warn)