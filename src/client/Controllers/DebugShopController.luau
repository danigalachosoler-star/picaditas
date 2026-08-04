-- src/client/Controllers/DebugShopController.luau
-- ⚠️ PANEL DE PRUEBAS, NO ES LA TIENDA. Solo existe en Studio.
--
-- Sirve para probar la lógica de comprar/equipar del paso 6b sin haber hecho
-- todavía la interfaz de verdad (paso 6c). A propósito es feo: que no se
-- confunda con la tienda real.
--
-- Llama exactamente a los mismos métodos de Knit que usará la tienda buena,
-- así que si funciona aquí, la UI del 6c solo tendrá que pintarlo bonito.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Catalog = require(ReplicatedStorage.Shared.Catalog)

local TOGGLE_KEY = Enum.KeyCode.F2
local DEBUG_COINS = 25000
local ROW_HEIGHT = 26

local DebugShopController = Knit.CreateController({
	Name = "DebugShopController",
})

function DebugShopController:KnitInit()
	self._rows = {}
	self._statusLabel = nil
	self._gui = nil
end

function DebugShopController:KnitStart()
	if not RunService:IsStudio() then
		return
	end

	self._inventoryService = Knit.GetService("InventoryService")
	self._currencyService = Knit.GetService("CurrencyService")

	self:_build()
	self:_refresh()

	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == TOGGLE_KEY then
			self._gui.Enabled = not self._gui.Enabled
		end
	end)
end

-- Relee el estado del servidor y repinta. Se llama tras cada acción para que
-- lo que se ve sea siempre lo que el servidor cree, no lo que suponemos.
function DebugShopController:_refresh()
	local snapshot = self._inventoryService:GetSnapshot():expect()

	for itemId, row in self._rows do
		local item = Catalog.GetItem(itemId)
		local owned = snapshot.inventory[item.category] and snapshot.inventory[item.category][itemId]
		local equipped = snapshot.equipped[item.category] == itemId

		local mark = if equipped then "[EQUIPADO]" elseif owned then "[comprado]" else ""
		row.label.Text = `{item.name} · {item.price} {mark}`
		row.label.TextColor3 = if equipped
			then Color3.fromRGB(120, 230, 140)
			elseif owned then Color3.fromRGB(220, 220, 220)
			else Color3.fromRGB(150, 150, 150)
	end
end

function DebugShopController:_run(action: string, itemId: string)
	local result = if action == "buy"
		then self._inventoryService:Purchase(itemId):expect()
		else self._inventoryService:Equip(itemId):expect()

	self._statusLabel.Text = result.message or result.reason or "?"
	self._statusLabel.TextColor3 = if result.ok then Color3.fromRGB(120, 230, 140) else Color3.fromRGB(240, 120, 120)

	self:_refresh()
end

function DebugShopController:_build()
	local gui = Instance.new("ScreenGui")
	gui.Name = "DebugShop"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 10
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	self._gui = gui

	local panel = Instance.new("Frame")
	panel.Size = UDim2.new(0, 320, 0, 90 + ROW_HEIGHT * #Catalog.Items)
	panel.Position = UDim2.new(1, -330, 0, 90)
	panel.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
	panel.BackgroundTransparency = 0.15
	panel.BorderSizePixel = 0
	panel.Parent = gui

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -8, 0, 20)
	title.Position = UDim2.fromOffset(4, 4)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.Code
	title.TextSize = 13
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = Color3.fromRGB(255, 190, 90)
	title.Text = `DEBUG tienda (F2 oculta) — solo Studio`
	title.Parent = panel

	local giveCoins = Instance.new("TextButton")
	giveCoins.Size = UDim2.new(1, -8, 0, 22)
	giveCoins.Position = UDim2.fromOffset(4, 26)
	giveCoins.BackgroundColor3 = Color3.fromRGB(60, 55, 30)
	giveCoins.BorderSizePixel = 0
	giveCoins.Font = Enum.Font.Code
	giveCoins.TextSize = 13
	giveCoins.TextColor3 = Color3.fromRGB(255, 214, 90)
	giveCoins.Text = `+{DEBUG_COINS} monedas`
	giveCoins.Parent = panel
	giveCoins.Activated:Connect(function()
		self._currencyService:DebugAddCoins(DEBUG_COINS):expect()
		self._statusLabel.Text = `+{DEBUG_COINS} monedas`
		self._statusLabel.TextColor3 = Color3.fromRGB(255, 214, 90)
	end)

	local y = 54
	for _, item in Catalog.Items do
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, -74, 0, ROW_HEIGHT - 4)
		label.Position = UDim2.fromOffset(4, y)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.Code
		label.TextSize = 12
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextTruncate = Enum.TextTruncate.AtEnd
		label.Text = item.name
		label.Parent = panel

		for index, spec in { { "C", "buy", 68 }, { "E", "equip", 34 } } do
			local button = Instance.new("TextButton")
			button.Size = UDim2.fromOffset(28, ROW_HEIGHT - 6)
			button.Position = UDim2.new(1, -spec[3], 0, y)
			button.BackgroundColor3 = if index == 1 then Color3.fromRGB(45, 60, 45) else Color3.fromRGB(40, 45, 65)
			button.BorderSizePixel = 0
			button.Font = Enum.Font.Code
			button.TextSize = 12
			button.TextColor3 = Color3.fromRGB(230, 230, 230)
			button.Text = spec[1]
			button.Parent = panel
			button.Activated:Connect(function()
				self:_run(spec[2], item.id)
			end)
		end

		self._rows[item.id] = { label = label }
		y += ROW_HEIGHT
	end

	local status = Instance.new("TextLabel")
	status.Size = UDim2.new(1, -8, 0, 28)
	status.Position = UDim2.fromOffset(4, y + 2)
	status.BackgroundTransparency = 1
	status.Font = Enum.Font.Code
	status.TextSize = 12
	status.TextWrapped = true
	status.TextXAlignment = Enum.TextXAlignment.Left
	status.TextYAlignment = Enum.TextYAlignment.Top
	status.TextColor3 = Color3.fromRGB(180, 180, 180)
	status.Text = "C = comprar · E = equipar"
	status.Parent = panel
	self._statusLabel = status
end

return DebugShopController
