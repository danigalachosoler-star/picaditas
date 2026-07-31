-- src/client/Controllers/TestController.luau
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local TestController = Knit.CreateController({
	Name = "TestController",
})

function TestController:KnitInit()
	print("TestController: KnitInit")
end

function TestController:KnitStart()
	print("TestController: KnitStart")
end

return TestController