-- src/server/Services/DataService.luau
-- Dueño del perfil guardado de cada jugador. Abre la sesión al entrar, la
-- cierra al salir, y ProfileStore se encarga del guardado periódico.
--
-- Este Service NO sabe qué significan los datos: solo los custodia. Quien
-- entiende de monedas es el CurrencyService; quien entienda de personajes
-- será otro. Todos piden aquí su perfil con GetProfile(player).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local DataTemplate = require(ReplicatedStorage.Shared.DataTemplate)
local ProfileStore = require(ServerScriptService.ServerPackages.ProfileStore)

-- Nombre del almacén en el DataStore. ⚠️ Cambiarlo equivale a borrar el
-- progreso de todo el mundo (apuntaría a otro sitio). No tocar a la ligera.
local STORE_NAME = "PlayerData_v1"

local WAIT_TIMEOUT = 15

local DataService = Knit.CreateService({
	Name = "DataService",
	Client = {},
})

function DataService:KnitInit()
	self._profileStore = ProfileStore.New(STORE_NAME, DataTemplate)
	self._profiles = {}
end

function DataService:KnitStart()
	-- Aviso de en qué modo estamos. En Studio sin acceso a la API activado,
	-- ProfileStore usa solo/a un almacén falso en memoria: todo funciona igual
	-- pero los datos se van al parar. Ver README/EstadoActual para probarlo.
	task.spawn(function()
		while ProfileStore.DataStoreState == "NotReady" do
			task.wait(0.2)
		end
		if ProfileStore.DataStoreState == "Access" then
			print("[DataService] DataStore REAL: los datos se guardan de verdad.")
		else
			warn(
				("[DataService] Sin DataStore (%s). Se usa un almacén FALSO en memoria: "):format(
					ProfileStore.DataStoreState
				) .. "el progreso se pierde al parar la sesión."
			)
		end
	end)

	for _, player in Players:GetPlayers() do
		task.spawn(function()
			self:_loadProfile(player)
		end)
	end

	Players.PlayerAdded:Connect(function(player)
		self:_loadProfile(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		local profile = self._profiles[player]
		self._profiles[player] = nil
		if profile then
			-- Cierra la sesión y fuerza un último guardado. Sin esto, otro
			-- servidor no podría abrir el perfil hasta que caduque el cerrojo.
			profile:EndSession()
		end
	end)
end

function DataService:_loadProfile(player: Player)
	-- La clave del DataStore. El UserId no cambia nunca (el nombre sí), así
	-- que es lo único válido para identificar a un jugador.
	local profile = self._profileStore:StartSessionAsync(`{player.UserId}`, {
		-- Si el jugador se va mientras seguimos intentando abrir su perfil,
		-- dejamos de insistir en vez de pelear con el DataStore para nada.
		Cancel = function()
			return player.Parent ~= Players
		end,
	})

	if profile == nil then
		-- No hemos podido abrir la sesión (normalmente porque otro servidor la
		-- tiene cogida). Dejarle jugar sería peor: perdería lo que ganase.
		player:Kick("No hemos podido cargar tus datos. Vuelve a entrar en un momento.")
		return
	end

	-- Asocia el perfil con su dueño (requisito de GDPR para peticiones de
	-- borrado de datos) y rellena los campos que se hayan añadido a la
	-- plantilla desde la última vez que este jugador entró.
	profile:AddUserId(player.UserId)
	profile:Reconcile()

	profile.OnSessionEnd:Connect(function()
		self._profiles[player] = nil
		if player.Parent == Players then
			-- La sesión se ha cerrado sin que nosotros la cerráramos: otro
			-- servidor se la ha llevado. Seguir jugando escribiría en un
			-- perfil que ya no controlamos.
			player:Kick("Tu sesión de datos se ha cerrado. Vuelve a entrar.")
		end
	end)

	if player.Parent ~= Players then
		-- Se fue mientras cargaba: soltamos el cerrojo y no guardamos nada.
		profile:EndSession()
		return
	end

	self._profiles[player] = profile
end

-- Perfil ya cargado, o nil si todavía no está listo. Para código que no puede
-- esperar (por ejemplo el pago de una picadita, que va en caliente).
function DataService:GetProfile(player: Player)
	return self._profiles[player]
end

-- Espera a que el perfil esté listo. Para código que sí puede esperar, como
-- responder al cliente cuál es su saldo al entrar.
function DataService:WaitForProfile(player: Player, timeout: number?)
	local deadline = os.clock() + (timeout or WAIT_TIMEOUT)

	while self._profiles[player] == nil do
		if player.Parent ~= Players or os.clock() > deadline then
			return nil
		end
		task.wait(0.1)
	end

	return self._profiles[player]
end

return DataService
