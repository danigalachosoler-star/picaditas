-- src/server/Services/TestService.luau
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local TestService = Knit.CreateService({
	Name = "TestService",
	Client = {},
})

function TestService:KnitInit()
	print("TestService: KnitInit")
end

function TestService:KnitStart()
	print("TestService: KnitStart")
end

return TestService
