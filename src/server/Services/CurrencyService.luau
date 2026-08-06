-- src/server/Services/CurrencyService.luau
-- Dueño del monedero de cada jugador: la única pieza que decide cuánto vale
-- una picadita y la única que toca el campo Coins del perfil.
--
-- El saldo YA NO vive aquí: vive en el perfil guardado que custodia el
-- DataService. Este servicio lo lee y lo escribe, y ProfileStore se encarga
-- de que llegue al DataStore.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Catalog = require(ReplicatedStorage.Shared.Catalog)
local EconomyConfig = require(ReplicatedStorage.Shared.EconomyConfig)

local REWARDS = {
	Perfect = EconomyConfig.PerfectReward,
	Good = EconomyConfig.GoodReward,
}

local CurrencyService = Knit.CreateService({
	Name = "CurrencyService",
	Client = {
		-- Avisa al cliente de un cambio de saldo que NO viene de una picadita
		-- (hoy: una compra). Las picaditas ya mandan el saldo dentro de su
		-- propio resultado, así que no se duplica un mensaje por golpe.
		BalanceChanged = Knit.CreateSignal(),
	},
})

function CurrencyService:KnitInit()
	self._dataService = nil
end

function CurrencyService:KnitStart()
	self._dataService = Knit.GetService("DataService")
end

-- Multiplicador total del jugador. Aquí se acumula todo lo que le haga ganar
-- más monedas, aparte del combo.
function CurrencyService:GetMultiplier(player: Player): number
	local multiplier = 1

	-- Bonus de lo que lleve equipado (hoy: mascotas). Se lee del perfil y se
	-- resuelve con el catálogo, sin pasar por el InventoryService: así los dos
	-- servicios no dependen el uno del otro cuando en el 6b el inventario
	-- necesite cobrar compras a través de este.
	local profile = self._dataService:GetProfile(player)
	if profile then
		multiplier += Catalog.GetCoinBonus(profile.Data.Equipped)
	end

	-- HUECO PARA EL FUTURO: el Game Pass x2 de monedas (ver Monetizacion.md).
	-- Cuando toque, aquí se consulta el Game Pass y se multiplica por 2.

	return multiplier
end

-- Cuánto vale una picadita. Función aparte para poder razonar sobre ella (y
-- para que el HUD pueda enseñar el valor sin duplicar la fórmula).
function CurrencyService:GetPicaditaReward(player: Player, judgement: string, combo: number): number
	local base = REWARDS[judgement]
	if not base then
		-- Un Miss o un veredicto desconocido no paga.
		return 0
	end

	local comboMultiplier = 1 + combo * EconomyConfig.ComboFactor
	local amount = base * comboMultiplier * self:GetMultiplier(player)

	return math.max(EconomyConfig.MinReward, math.floor(amount))
end

-- Paga la picadita y devuelve (lo ganado, saldo nuevo).
function CurrencyService:AwardPicadita(player: Player, judgement: string, combo: number): (number, number)
	local profile = self._dataService:GetProfile(player)
	if not profile then
		-- El perfil todavía no ha cargado (o ya se cerró). Preferimos no pagar
		-- a inventar monedas que luego no se guardarían. En la práctica casi no
		-- pasa: la carga termina durante los segundos de cortesía del inicio.
		warn(`[CurrencyService] Picadita sin perfil cargado para {player.Name}; no se paga.`)
		return 0, 0
	end

	local earned = self:GetPicaditaReward(player, judgement, combo)
	if earned <= 0 then
		return 0, profile.Data.Coins
	end

	-- Escribir en Profile.Data es TODO lo que hay que hacer para guardar:
	-- ProfileStore se encarga del resto (guardado periódico y al cerrar).
	profile.Data.Coins += earned
	return earned, profile.Data.Coins
end

-- Paga una skill épica clavada. Usa la misma curva de combo y el mismo
-- multiplicador del jugador que una picadita: solo cambia la base, que es
-- mucho más gorda.
function CurrencyService:AwardSkill(player: Player, combo: number): (number, number)
	local profile = self._dataService:GetProfile(player)
	if not profile then
		return 0, 0
	end

	local amount = EconomyConfig.SkillReward * (1 + combo * EconomyConfig.ComboFactor) * self:GetMultiplier(player)
	local earned = math.max(EconomyConfig.MinReward, math.floor(amount))

	profile.Data.Coins += earned
	return earned, profile.Data.Coins
end

function CurrencyService:GetBalance(player: Player): number
	local profile = self._dataService:GetProfile(player)
	return if profile then profile.Data.Coins else 0
end

-- Cobra `amount` monedas. Devuelve false y no toca nada si no llega el saldo.
--
-- Comprobar y restar van juntos EN LA MISMA FUNCIÓN a propósito: si el que
-- llama mirase el saldo por su cuenta y restara después, entre las dos cosas
-- podría colarse otra operación y dejar el saldo en negativo. Aquí no puede
-- pasar porque esta función no cede el hilo en ningún punto.
function CurrencyService:TrySpend(player: Player, amount: number): boolean
	if type(amount) ~= "number" or amount ~= amount or amount < 0 then
		warn(`[CurrencyService] TrySpend con un importe inválido: {tostring(amount)}`)
		return false
	end

	local profile = self._dataService:GetProfile(player)
	if not profile or profile.Data.Coins < amount then
		return false
	end

	profile.Data.Coins -= amount
	self.Client.BalanceChanged:Fire(player, profile.Data.Coins)
	return true
end

-- El cliente pide su saldo nada más entrar, cuando el perfil puede estar aún
-- cargando. Aquí sí podemos esperar: es una llamada única y el jugador
-- prefiere ver su saldo real medio segundo tarde que ver un 0 falso.
function CurrencyService.Client:GetBalance(player: Player): number
	local profile = self.Server._dataService:WaitForProfile(player)
	return if profile then profile.Data.Coins else 0
end

-- ⚠️ REGALA MONEDAS. Solo para probar la tienda sin farmear 75.000.
--
-- Fíjate en que el método se define DENTRO del if: fuera de Studio no llega a
-- existir, así que Knit no le crea remote y no hay nada que un cliente
-- modificado pueda llamar. Es más seguro que comprobar IsStudio por dentro.
if RunService:IsStudio() then
	function CurrencyService.Client:DebugAddCoins(player: Player, amount: number)
		local profile = self.Server._dataService:GetProfile(player)
		if not profile then
			return 0
		end

		local safeAmount = if type(amount) == "number" and amount == amount then math.floor(amount) else 0
		profile.Data.Coins = math.max(0, profile.Data.Coins + safeAmount)
		self.BalanceChanged:Fire(player, profile.Data.Coins)
		return profile.Data.Coins
	end
end

return CurrencyService
