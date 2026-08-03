-- src/server/Services/CurrencyService.luau
-- Dueño del monedero de cada jugador: la única pieza que decide cuánto vale
-- una picadita y la única que toca el campo Coins del perfil.
--
-- El saldo YA NO vive aquí: vive en el perfil guardado que custodia el
-- DataService. Este servicio lo lee y lo escribe, y ProfileStore se encarga
-- de que llegue al DataStore.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local EconomyConfig = require(ReplicatedStorage.Shared.EconomyConfig)

local REWARDS = {
	Perfect = EconomyConfig.PerfectReward,
	Good = EconomyConfig.GoodReward,
}

local CurrencyService = Knit.CreateService({
	Name = "CurrencyService",
	Client = {},
})

function CurrencyService:KnitInit()
	self._dataService = nil
end

function CurrencyService:KnitStart()
	self._dataService = Knit.GetService("DataService")
end

-- HUECO PARA EL FUTURO: el Game Pass x2 de monedas (ver Monetizacion.md).
-- Hoy devuelve 1 siempre, así que no cambia nada. Cuando toque implementarlo,
-- este es el único sitio que hay que tocar: consultar el Game Pass del jugador
-- y devolver 2. La fórmula de abajo ya lo multiplica.
function CurrencyService:GetMultiplier(_player: Player): number
	return 1
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

function CurrencyService:GetBalance(player: Player): number
	local profile = self._dataService:GetProfile(player)
	return if profile then profile.Data.Coins else 0
end

-- El cliente pide su saldo nada más entrar, cuando el perfil puede estar aún
-- cargando. Aquí sí podemos esperar: es una llamada única y el jugador
-- prefiere ver su saldo real medio segundo tarde que ver un 0 falso.
function CurrencyService.Client:GetBalance(player: Player): number
	local profile = self.Server._dataService:WaitForProfile(player)
	return if profile then profile.Data.Coins else 0
end

return CurrencyService
