-- src/client/Controllers/ShopController.luau
-- La tienda. Pinta el catálogo y llama a los métodos del InventoryService.
--
-- No decide NADA: no sabe si puedes permitirte algo ni si ya lo tienes. Pinta
-- lo que el servidor le dice y le reenvía lo que pulsas. Si el servidor
-- rechaza la compra, se enseña su mensaje tal cual.
--
-- Las pestañas salen de Catalog.Categories: añadir una categoría nueva al
-- catálogo hace aparecer su pestaña sola, sin tocar este archivo.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Catalog = require(ReplicatedStorage.Shared.Catalog)

local DEBUG_COINS = 25000

local COLORS = {
	panel = Color3.fromRGB(28, 30, 38),
	header = Color3.fromRGB(38, 41, 52),
	row = Color3.fromRGB(38, 41, 52),
	placeholder = Color3.fromRGB(58, 62, 76),
	text = Color3.fromRGB(235, 235, 240),
	dim = Color3.fromRGB(150, 154, 165),
	gold = Color3.fromRGB(255, 214, 90),
	buy = Color3.fromRGB(56, 150, 82),
	equip = Color3.fromRGB(58, 100, 180),
	equipped = Color3.fromRGB(70, 76, 90),
	cant = Color3.fromRGB(70, 60, 60),
	ok = Color3.fromRGB(120, 230, 140),
	error = Color3.fromRGB(240, 120, 120),
}

-- 75000 → "75.000". Se lee mucho mejor de un vistazo.
local function formatNumber(n: number): string
	local text = tostring(math.floor(n))
	local out = text:reverse():gsub("(%d%d%d)", "%1."):reverse()
	return (out:gsub("^%.", ""))
end

local function corner(parent: Instance, radius: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
	return c
end

local ShopController = Knit.CreateController({
	Name = "ShopController",
})

function ShopController:KnitInit()
	self._rows = {}
	self._pages = {}
	self._tabs = {}
	self._activeCategory = nil
	self._snapshot = { inventory = {}, equipped = {} }
	self._balance = 0
end

function ShopController:KnitStart()
	self._inventoryService = Knit.GetService("InventoryService")
	self._currencyService = Knit.GetService("CurrencyService")

	self:_build()

	self._balance = self._currencyService:GetBalance():expect()
	self._currencyService.BalanceChanged:Connect(function(balance)
		-- El saldo cambia lo que puedes permitirte, así que hay que repintar
		-- los botones. No hace falta volver a preguntar el inventario.
		self._balance = balance
		self:_render()
	end)

	self:_reload()
end

----- Estado -----

-- Pregunta al servidor qué tiene y qué lleva puesto, y repinta.
function ShopController:_reload()
	self._snapshot = self._inventoryService:GetSnapshot():expect()
	self:_render()
end

function ShopController:_stateOf(item)
	local owned = self._snapshot.inventory[item.category]
	local isOwned = owned ~= nil and owned[item.id] == true
	if self._snapshot.equipped[item.category] == item.id then
		return "equipped"
	elseif isOwned then
		return "owned"
	elseif self._balance >= item.price then
		return "buyable"
	end
	return "tooExpensive"
end

function ShopController:_render()
	for itemId, row in self._rows do
		local item = Catalog.GetItem(itemId)
		local state = self:_stateOf(item)

		if state == "equipped" then
			row.button.Text = "EQUIPADO"
			row.button.BackgroundColor3 = COLORS.equipped
			row.button.TextColor3 = COLORS.ok
			row.button.AutoButtonColor = false
			row.button.Active = false
		elseif state == "owned" then
			row.button.Text = "Equipar"
			row.button.BackgroundColor3 = COLORS.equip
			row.button.TextColor3 = COLORS.text
			row.button.AutoButtonColor = true
			row.button.Active = true
		else
			row.button.Text = "Comprar"
			-- Si no llega el dinero se deja pulsable a propósito: así el
			-- servidor responde con cuánto falta en vez de no pasar nada.
			row.button.BackgroundColor3 = if state == "buyable" then COLORS.buy else COLORS.cant
			row.button.TextColor3 = if state == "buyable" then COLORS.text else COLORS.dim
			row.button.AutoButtonColor = true
			row.button.Active = true
		end

		row.price.TextColor3 = if state == "tooExpensive" then COLORS.dim else COLORS.gold
	end
end

function ShopController:_act(item)
	local state = self:_stateOf(item)
	if state == "equipped" then
		return
	end

	local promise = if state == "owned"
		then self._inventoryService:Equip(item.id)
		else self._inventoryService:Purchase(item.id)

	local result = promise:expect()

	self._status.Text = result.message or result.reason or ""
	self._status.TextColor3 = if result.ok then COLORS.ok else COLORS.error

	-- Siempre se recarga desde el servidor, también al fallar: lo que se ve
	-- tiene que ser lo que el servidor cree, nunca lo que suponemos aquí.
	self:_reload()
end

function ShopController:_showCategory(categoryId: string)
	self._activeCategory = categoryId
	for id, page in self._pages do
		page.Visible = id == categoryId
	end
	for id, tab in self._tabs do
		tab.BackgroundColor3 = if id == categoryId then COLORS.equip else COLORS.header
		tab.TextColor3 = if id == categoryId then COLORS.text else COLORS.dim
	end
end

function ShopController:_toggle()
	self._panel.Visible = not self._panel.Visible
	if self._panel.Visible then
		self._status.Text = ""
		self:_reload()
	end
end

----- Construcción -----

function ShopController:_build()
	local gui = Instance.new("ScreenGui")
	gui.Name = "Shop"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 5
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

	self:_buildOpenButton(gui)
	self:_buildPanel(gui)

	for _, category in Catalog.Categories do
		self:_buildPage(category)
	end

	self:_showCategory(Catalog.Categories[1].id)
end

function ShopController:_buildOpenButton(gui: ScreenGui)
	local button = Instance.new("TextButton")
	button.Name = "OpenShop"
	button.Size = UDim2.fromOffset(56, 56)
	-- Pegado al borde izquierdo y centrado en vertical. El AnchorPoint en 0.5
	-- hace que sea el CENTRO del botón el que se alinea con la mitad de la
	-- pantalla; sin él quedaría medio botón por debajo.
	button.AnchorPoint = Vector2.new(0, 0.5)
	button.Position = UDim2.new(0, 16, 0.5, 0)
	button.BackgroundColor3 = COLORS.header
	button.Font = Enum.Font.GothamBold
	button.TextSize = 26
	button.Text = "🛒"
	button.TextColor3 = COLORS.text
	button.Parent = gui
	corner(button, 12)

	button.Activated:Connect(function()
		self:_toggle()
	end)
end

function ShopController:_buildPanel(gui: ScreenGui)
	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.new(0.9, 0, 0.82, 0)
	panel.BackgroundColor3 = COLORS.panel
	panel.BorderSizePixel = 0
	panel.Visible = false
	panel.Parent = gui
	corner(panel, 14)
	self._panel = panel

	-- Escala con la pantalla pero sin desmadrarse en un monitor grande.
	local constraint = Instance.new("UISizeConstraint")
	constraint.MaxSize = Vector2.new(600, 520)
	constraint.Parent = panel

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -60, 0, 44)
	title.Position = UDim2.fromOffset(16, 4)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBlack
	title.TextSize = 22
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = COLORS.text
	title.Text = "TIENDA"
	title.Parent = panel

	local close = Instance.new("TextButton")
	close.Size = UDim2.fromOffset(36, 36)
	close.Position = UDim2.new(1, -46, 0, 8)
	close.BackgroundColor3 = COLORS.header
	close.Font = Enum.Font.GothamBold
	close.TextSize = 18
	close.TextColor3 = COLORS.text
	close.Text = "X"
	close.Parent = panel
	corner(close, 8)
	close.Activated:Connect(function()
		self:_toggle()
	end)

	-- Pestañas, una por categoría del catálogo.
	local tabBar = Instance.new("Frame")
	tabBar.Size = UDim2.new(1, -32, 0, 34)
	tabBar.Position = UDim2.fromOffset(16, 50)
	tabBar.BackgroundTransparency = 1
	tabBar.Parent = panel

	local tabLayout = Instance.new("UIListLayout")
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.Padding = UDim.new(0, 6)
	tabLayout.Parent = tabBar

	for _, category in Catalog.Categories do
		local tab = Instance.new("TextButton")
		tab.Size = UDim2.new(1 / #Catalog.Categories, -6, 1, 0)
		tab.BackgroundColor3 = COLORS.header
		tab.Font = Enum.Font.GothamBold
		tab.TextSize = 14
		tab.TextColor3 = COLORS.dim
		tab.Text = category.name
		tab.Parent = tabBar
		corner(tab, 8)

		tab.Activated:Connect(function()
			self:_showCategory(category.id)
		end)
		self._tabs[category.id] = tab
	end

	local status = Instance.new("TextLabel")
	status.Size = UDim2.new(1, -32, 0, 30)
	status.Position = UDim2.new(0, 16, 1, -36)
	status.BackgroundTransparency = 1
	status.Font = Enum.Font.GothamMedium
	status.TextSize = 14
	status.TextWrapped = true
	status.TextXAlignment = Enum.TextXAlignment.Left
	status.TextColor3 = COLORS.dim
	status.Text = ""
	status.Parent = panel
	self._status = status

	if RunService:IsStudio() then
		self:_buildDebugButton(panel)
	end
end

function ShopController:_buildPage(category)
	local page = Instance.new("ScrollingFrame")
	page.Name = category.id
	page.Size = UDim2.new(1, -32, 1, -134)
	page.Position = UDim2.fromOffset(16, 92)
	page.BackgroundTransparency = 1
	page.BorderSizePixel = 0
	page.ScrollBarThickness = 5
	page.CanvasSize = UDim2.new()
	page.AutomaticCanvasSize = Enum.AutomaticSize.Y
	page.Visible = false
	page.Parent = self._panel
	self._pages[category.id] = page

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = page

	for index, item in Catalog.GetItems(category.id) do
		self:_buildRow(page, item, index)
	end
end

function ShopController:_buildRow(page: ScrollingFrame, item, index: number)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -6, 0, 68)
	row.BackgroundColor3 = COLORS.row
	row.BorderSizePixel = 0
	row.LayoutOrder = index
	row.Parent = page
	corner(row, 10)

	-- Hueco para el arte. Es un ImageLabel de verdad ya colocado: cuando
	-- tengáis las imágenes basta con ponerle el Image, sin tocar el layout.
	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.fromOffset(52, 52)
	icon.Position = UDim2.fromOffset(8, 8)
	icon.BackgroundColor3 = COLORS.placeholder
	icon.BorderSizePixel = 0
	icon.Image = ""
	icon.Parent = row
	corner(icon, 8)

	local name = Instance.new("TextLabel")
	name.Size = UDim2.new(1, -210, 0, 22)
	name.Position = UDim2.fromOffset(70, 12)
	name.BackgroundTransparency = 1
	name.Font = Enum.Font.GothamBold
	name.TextSize = 16
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.TextTruncate = Enum.TextTruncate.AtEnd
	name.TextColor3 = COLORS.text
	name.Text = item.name
	name.Parent = row

	-- Precio y, si el item da bonus, cuánto. Se saca de item.coinBonus en vez
	-- de mirar la categoría: si mañana una skin da monedas, sale sola.
	local detail = item.coinBonus and `{formatNumber(item.price)}  ·  +{math.round(item.coinBonus * 100)}% monedas`
		or formatNumber(item.price)

	local price = Instance.new("TextLabel")
	price.Size = UDim2.new(1, -210, 0, 20)
	price.Position = UDim2.fromOffset(70, 34)
	price.BackgroundTransparency = 1
	price.Font = Enum.Font.GothamMedium
	price.TextSize = 14
	price.TextXAlignment = Enum.TextXAlignment.Left
	price.TextTruncate = Enum.TextTruncate.AtEnd
	price.TextColor3 = COLORS.gold
	price.Text = detail
	price.Parent = row

	local button = Instance.new("TextButton")
	button.Size = UDim2.fromOffset(112, 34)
	button.Position = UDim2.new(1, -124, 0.5, -17)
	button.Font = Enum.Font.GothamBold
	button.TextSize = 14
	button.BackgroundColor3 = COLORS.buy
	button.TextColor3 = COLORS.text
	button.Text = "..."
	button.Parent = row
	corner(button, 8)

	button.Activated:Connect(function()
		self:_act(item)
	end)

	self._rows[item.id] = { button = button, price = price }
end

-- Solo Studio: monedas para poder probar la tienda sin farmear.
function ShopController:_buildDebugButton(panel: Frame)
	local button = Instance.new("TextButton")
	button.Size = UDim2.fromOffset(130, 26)
	button.Position = UDim2.new(1, -146, 1, -34)
	button.BackgroundColor3 = Color3.fromRGB(60, 55, 30)
	button.Font = Enum.Font.Code
	button.TextSize = 12
	button.TextColor3 = COLORS.gold
	button.Text = `debug +{formatNumber(DEBUG_COINS)}`
	button.Parent = panel
	corner(button, 6)

	-- El botón se come la esquina derecha: encogemos el texto de estado para
	-- que los mensajes largos no se metan por debajo.
	self._status.Size = UDim2.new(1, -178, 0, 30)

	button.Activated:Connect(function()
		self._currencyService:DebugAddCoins(DEBUG_COINS):expect()
	end)
end

return ShopController
