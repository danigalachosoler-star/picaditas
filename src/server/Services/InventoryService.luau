-- src/server/Services/InventoryService.luau
-- Lee el inventario del jugador: qué tiene desbloqueado y qué lleva equipado.
--
-- Sigue el reparto del paso 5: el DataService custodia el perfil sin saber qué
-- significa, y este servicio es el que entiende de inventario. Igual que el
-- CurrencyService es el único que entiende de monedas.
--
-- El cliente PIDE comprar o equipar; aquí se decide si se puede. Nunca se
-- confía en lo que mande (ver ClienteYServidor.md).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Catalog = require(ReplicatedStorage.Shared.Catalog)

export type Result = {
	ok: boolean,
	-- Código para el programa (la UI decide qué hacer con él).
	reason: string?,
	-- Texto para la persona. Se enseña tal cual.
	message: string?,
	itemId: string?,
	category: string?,
	balance: number?,
}

local function fail(reason: string, message: string): Result
	return { ok = false, reason = reason, message = message }
end

local InventoryService = Knit.CreateService({
	Name = "InventoryService",
	Client = {},
})

function InventoryService:KnitInit()
	self._dataService = nil
	self._currencyService = nil
end

function InventoryService:KnitStart()
	self._dataService = Knit.GetService("DataService")
	-- Esta es la dirección de dependencia que se dejó preparada en el 6a: el
	-- inventario cobra a través del monedero. El monedero NO llama aquí (lee
	-- el bonus con Catalog.GetCoinBonus), así que no hay ciclo.
	self._currencyService = Knit.GetService("CurrencyService")

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

----- Comprar y equipar -----

-- Resuelve el item y el perfil, o devuelve el motivo del fallo. Lo comparten
-- comprar y equipar porque las dos comprobaciones de entrada son idénticas.
function InventoryService:_resolve(player: Player, itemId: any): (Catalog.Item?, any, Result?)
	-- El id llega por la red: puede ser cualquier cosa, no solo un texto.
	if type(itemId) ~= "string" then
		return nil, nil, fail("UnknownItem", "Ese objeto no existe.")
	end

	local item = Catalog.GetItem(itemId)
	if not item then
		return nil, nil, fail("UnknownItem", "Ese objeto no existe.")
	end

	local profile = self._dataService:GetProfile(player)
	if not profile then
		return nil, nil, fail("ProfileNotReady", "Tus datos todavía se están cargando. Prueba otra vez.")
	end

	return item, profile, nil
end

-- La tabla de desbloqueados de una categoría, creándola si faltara. No debería
-- faltar (Reconcile la pone al cargar), pero así una categoría recién añadida
-- nunca provoca un error duro.
local function ownedTable(profile, categoryId: string)
	local owned = profile.Data.Inventory[categoryId]
	if not owned then
		owned = {}
		profile.Data.Inventory[categoryId] = owned
	end
	return owned
end

-- Compra un item: valida, cobra y lo desbloquea.
--
-- Todo esto ocurre sin ceder el hilo ni una vez (no hay esperas ni llamadas al
-- DataStore por el medio), así que dos peticiones seguidas no pueden
-- entrelazarse y colar una compra a mitad de otra.
function InventoryService:Purchase(player: Player, itemId: any): Result
	local item, profile, problem = self:_resolve(player, itemId)
	if problem then
		return problem
	end
	assert(item and profile)

	local owned = ownedTable(profile, item.category)
	if owned[item.id] == true then
		return fail("AlreadyOwned", `Ya tienes "{item.name}".`)
	end

	local balance = profile.Data.Coins
	if balance < item.price then
		return fail("NotEnoughCoins", `Te faltan {item.price - balance} monedas para "{item.name}".`)
	end

	-- El precio sale del CATÁLOGO, nunca de lo que mande el cliente.
	if not self._currencyService:TrySpend(player, item.price) then
		return fail("NotEnoughCoins", "No se ha podido cobrar la compra.")
	end

	owned[item.id] = true

	-- No se equipa solo: comprar y equipar son dos acciones distintas.
	return {
		ok = true,
		itemId = item.id,
		category = item.category,
		balance = profile.Data.Coins,
		message = `Has comprado "{item.name}".`,
	}
end

-- Equipa un item ya desbloqueado, sustituyendo lo que hubiera en su categoría.
function InventoryService:Equip(player: Player, itemId: any): Result
	local item, profile, problem = self:_resolve(player, itemId)
	if problem then
		return problem
	end
	assert(item and profile)

	if ownedTable(profile, item.category)[item.id] ~= true then
		return fail("NotOwned", `Todavía no tienes "{item.name}".`)
	end

	-- Equipar lo que ya llevas puesto no es un error, simplemente no cambia nada.
	profile.Data.Equipped[item.category] = item.id

	return {
		ok = true,
		itemId = item.id,
		category = item.category,
		message = `Te has equipado "{item.name}".`,
	}
end

function InventoryService.Client:Purchase(player: Player, itemId: any): Result
	return self.Server:Purchase(player, itemId)
end

function InventoryService.Client:Equip(player: Player, itemId: any): Result
	return self.Server:Equip(player, itemId)
end

-- Foto completa para el cliente: lo que tiene y lo que lleva puesto.
-- Solo lectura; la UI de la tienda del paso 6c partirá de esto.
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
