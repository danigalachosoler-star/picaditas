-- src/server/Services/InventoryService.luau
-- Lee el inventario del jugador: qué tiene desbloqueado y qué lleva equipado.
--
-- Sigue el reparto del paso 5: el DataService custodia el perfil sin saber qué
-- significa, y este servicio es el que entiende de inventario. Igual que el
-- CurrencyService es el único que entiende de monedas.
--
-- ⚠️ PASO 6a: SOLO LECTURA. Comprar y equipar llegan en el 6b.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Catalog = require(ReplicatedStorage.Shared.Catalog)

local InventoryService = Knit.CreateService({
	Name = "InventoryService",
	Client = {},
})

function InventoryService:KnitInit()
	self._dataService = nil
end

function InventoryService:KnitStart()
	self._dataService = Knit.GetService("DataService")

	if #Catalog.DebugUnlocked > 0 and RunService:IsStudio() then
		for _, player in Players:GetPlayers() do
			task.spawn(function()
				self:_applyDebugUnlocks(player)
			end)
		end

		Players.PlayerAdded:Connect(function(player)
			self:_applyDebugUnlocks(player)
		end)
	end
end

----- Consultas -----

-- Todo lo desbloqueado: { [categoría] = { [idDelItem] = true } }.
-- Devuelve la tabla VIVA del perfil, no una copia: no la modifiques desde
-- fuera. Para eso estarán los métodos de compra del paso 6b.
function InventoryService:GetInventory(player: Player): { [string]: { [string]: boolean } }?
	local profile = self._dataService:GetProfile(player)
	return if profile then profile.Data.Inventory else nil
end

function InventoryService:IsUnlocked(player: Player, itemId: string): boolean
	local item = Catalog.GetItem(itemId)
	if not item then
		return false
	end

	local profile = self._dataService:GetProfile(player)
	if not profile then
		return false
	end

	local owned = profile.Data.Inventory[item.category]
	return owned ~= nil and owned[itemId] == true
end

-- Id de lo equipado en una categoría, o nil si no lleva nada.
function InventoryService:GetEquippedId(player: Player, categoryId: string): string?
	local profile = self._dataService:GetProfile(player)
	if not profile then
		return nil
	end

	local itemId = profile.Data.Equipped[categoryId]
	return if itemId ~= nil and itemId ~= "" then itemId else nil
end

-- Lo equipado, ya resuelto contra el catálogo. Devuelve nil si no lleva nada
-- o si el id guardado ya no existe (por ejemplo, item retirado del catálogo).
function InventoryService:GetEquippedItem(player: Player, categoryId: string): Catalog.Item?
	return Catalog.GetItem(self:GetEquippedId(player, categoryId))
end

-- Los items de una categoría que el jugador ya tiene, en orden de catálogo.
function InventoryService:GetUnlockedItems(player: Player, categoryId: string): { Catalog.Item }
	local profile = self._dataService:GetProfile(player)
	if not profile then
		return {}
	end

	local owned = profile.Data.Inventory[categoryId]
	if not owned then
		return {}
	end

	local result = {}
	for _, item in Catalog.GetItems(categoryId) do
		if owned[item.id] == true then
			table.insert(result, item)
		end
	end
	return result
end

-- Foto completa para el cliente: lo que tiene y lo que lleva puesto.
-- Solo lectura; la UI de la tienda del paso 6b partirá de esto.
function InventoryService.Client:GetSnapshot(player: Player)
	local profile = self.Server._dataService:WaitForProfile(player)
	if not profile then
		return { inventory = {}, equipped = {} }
	end

	-- Copia superficial por categoría: lo que sale por la red no debe ser la
	-- tabla viva del perfil.
	local inventory = {}
	for categoryId, owned in profile.Data.Inventory do
		inventory[categoryId] = table.clone(owned)
	end

	return {
		inventory = inventory,
		equipped = table.clone(profile.Data.Equipped),
	}
end

----- Atajo de pruebas -----

-- Desbloquea y equipa los items de Catalog.DebugUnlocked. Solo en Studio.
-- Escribe en el perfil, así que lo desbloqueado PERSISTE: puedes activarlo una
-- vez, volver a vaciar la lista, y comprobar que el item sigue ahí al entrar.
function InventoryService:_applyDebugUnlocks(player: Player)
	local profile = self._dataService:WaitForProfile(player)
	if not profile then
		return
	end

	for _, itemId in Catalog.DebugUnlocked do
		local item = Catalog.GetItem(itemId)
		if not item then
			warn(`[InventoryService] DebugUnlocked: el id "{itemId}" no está en el catálogo.`)
			continue
		end

		profile.Data.Inventory[item.category][item.id] = true

		-- Si no lleva nada de esa categoría, le equipamos esto.
		if profile.Data.Equipped[item.category] == "" then
			profile.Data.Equipped[item.category] = item.id
		end

		print(`[InventoryService] (Studio) Desbloqueado "{item.name}" para {player.Name}.`)
	end
end

return InventoryService
