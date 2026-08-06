-- src/client/Controllers/CharacterAnimationController.luau
-- Mueve al personaje cuando el servidor confirma una picadita o una skill.
--
-- Es puramente estético, por eso vive en el cliente. Reacciona a lo que ya
-- manda el ComboService; no toca la lógica de juego ni añade tráfico de red.
--
-- Detalle de Roblox: al reproducir una animación sobre el Animator de TU
-- propio personaje, Roblox la replica sola al servidor y a los demás
-- jugadores. No hay que mandarla a mano (útil para la fase 3, ver
-- VisionYFases.md).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Knit = require(ReplicatedStorage.Packages.Knit)
local AnimationConfig = require(ReplicatedStorage.Shared.AnimationConfig)
local SkillTrajectories = require(ReplicatedStorage.Shared.SkillTrajectories)
local SpeedConfig = require(ReplicatedStorage.Shared.SpeedConfig)

local CharacterAnimationController = Knit.CreateController({
	Name = "CharacterAnimationController",
})

function CharacterAnimationController:KnitInit()
	self._tracks = {}
	self._animator = nil
	self._random = Random.new()

	-- Segundos (en tiempo de animación) desde que arranca cada pista hasta que
	-- salta su marker de contacto. NO se escribe a mano: se aprende solo la
	-- primera vez que se reproduce, midiendo TimePosition cuando salta.
	self._contactOffset = {}

	-- Token para poder cancelar una animación ya programada. Sin esto, una
	-- picadita programada seguiría saliendo aunque el jugador haya fallado.
	self._scheduleToken = 0

	-- ¿Hay un toque ya programado para el próximo bote? Si lo hay, al llegar la
	-- confirmación del servidor no hay que tocar otra vez: ya salió a tiempo.
	self._scheduled = false
end

function CharacterAnimationController:KnitStart()
	local ComboService = Knit.GetService("ComboService")
	local player = Players.LocalPlayer

	-- Las animaciones se cargan sobre el Animator del personaje, así que hay
	-- que rehacerlas cada vez que el jugador reaparece (al morir, al resetear).
	if player.Character then
		task.spawn(function()
			self:_setupCharacter(player.Character)
		end)
	end
	player.CharacterAdded:Connect(function(character)
		self:_setupCharacter(character)
	end)

	ComboService.PicaditaResult:Connect(function(payload)
		if payload.result == "Perfect" or payload.result == "Good" then
			self:_onTouchConfirmed(payload)
		else
			-- Falló: la racha se corta y lo que hubiera programado sobra.
			self:_cancelScheduled()
		end
	end)

	ComboService.SkillStarted:Connect(function()
		self:_cancelScheduled()
	end)

	ComboService.SkillResult:Connect(function(payload)
		if payload.ok then
			self:_playCelebration(payload)
			-- Tras la celebración la racha sigue: reenganchamos con el toque
			-- del próximo bote, que el servidor acaba de re-anclar.
			self:_scheduleNextTouch(payload)
		end
	end)
end

----- Carga -----

function CharacterAnimationController:_setupCharacter(character: Model)
	local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
	if not humanoid then
		return
	end

	-- El Animator es el objeto moderno para reproducir animaciones.
	-- Humanoid:LoadAnimation() está obsoleto desde hace años.
	local animator = humanoid:WaitForChild("Animator", 10) :: Animator?
	if not animator then
		warn("[CharacterAnimation] El personaje no tiene Animator; no habrá animaciones.")
		return
	end

	self._animator = animator
	self._tracks = {}

	self:_load("normal", AnimationConfig.Touches.normal.id)
	self:_load("knee", AnimationConfig.Touches.knee.id)
	self:_load("celebration", AnimationConfig.SkillCelebration.id)
end

function CharacterAnimationController:_load(key: string, assetId: number)
	local animation = Instance.new("Animation")
	animation.Name = key
	animation.AnimationId = `rbxassetid://{assetId}`

	local ok, track = pcall(function()
		return self._animator:LoadAnimation(animation)
	end)

	if not ok or not track then
		warn(
			`[CharacterAnimation] No se pudo cargar "{key}" (id {assetId}). `
				.. "Recuerda que Roblox solo permite animaciones que pertenezcan a la cuenta "
				.. "o al grupo dueño del juego. Ver AnimationConfig.luau."
		)
		return
	end

	track.Priority = Enum.AnimationPriority.Action

	-- El marker se conecta UNA VEZ, al cargar la pista, no en cada Play():
	-- el AnimationTrack se reutiliza, así que conectarlo por reproducción
	-- acumularía conexiones sin parar.
	track:GetMarkerReachedSignal(AnimationConfig.ContactMarker):Connect(function()
		-- Aprendemos dónde cae el contacto dentro de la animación. TimePosition
		-- va en tiempo de animación, así que NO depende de la velocidad a la
		-- que se esté reproduciendo: se mide una vez y vale para siempre.
		if self._contactOffset[key] == nil then
			self._contactOffset[key] = track.TimePosition
			if RunService:IsStudio() then
				-- Para la celebración, este número es el que hay que copiar en
				-- `contactTime` dentro de SkillTrajectories.luau, para que el
				-- balón esté arriba justo cuando el pie lo golpea.
				print(`[CharacterAnimation] marker "{key}" medido en {string.format("%.3f", track.TimePosition)}s`)
			end
		end
		self:_onContact(key)
	end)

	self._tracks[key] = track
end

----- Reproducción -----

-- Misma aceleración que el balón: si el ciclo se ha acortado a la mitad, la
-- animación va al doble. Sale de dividir la duración base entre la actual, que
-- el servidor manda en cada resultado.
local function rateFor(rhythm): number
	local duration = rhythm and rhythm.duration
	return if duration and duration > 0 then SpeedConfig.BaseCycleDuration / duration else 1
end

function CharacterAnimationController:_pickTouch(): string
	-- El toque normal predomina; el de rodilla sale de vez en cuando.
	return if self._random:NextNumber() < AnimationConfig.KneeChance then "knee" else "normal"
end

function CharacterAnimationController:_onTouchConfirmed(payload)
	-- El servidor ya confirmó ESTE toque. Si no habíamos programado nada
	-- (primer acierto de la racha), lo reproducimos ahora aunque llegue un
	-- pelín tarde: hace falta para aprender dónde cae el marker.
	if not self._scheduled then
		self:_playTouch(self:_pickTouch(), rateFor(payload.rhythm))
	end
	self._scheduled = false

	self:_scheduleNextTouch(payload)
end

-- ============================================================
-- SINCRONIZACIÓN CONTACTO ↔ PUNTO BAJO DEL BALÓN
-- ============================================================
-- El toque tiene que verse cuando el balón está ABAJO, no después. Y el
-- contacto no ocurre al empezar la animación, sino unos fotogramas más tarde
-- (donde está el marker). Así que la animación hay que ARRANCARLA ANTES del
-- bote, exactamente ese adelanto.
--
-- Como el aviso del servidor llega DESPUÉS del bote (ida y vuelta de red),
-- reaccionar a él siempre llegaría tarde. Lo que se hace es programar el
-- toque del bote SIGUIENTE, que el reloj compartido nos deja calcular al
-- milisegundo. Mientras la racha esté viva, cada toque queda clavado.
--
-- Efecto secundario honesto: si el jugador rompe la racha, la animación ya
-- programada llega a salir (el personaje da un toque al aire). Es el precio
-- de que el 99% de los toques cuadren.
function CharacterAnimationController:_scheduleNextTouch(payload)
	local rhythm = payload.rhythm
	if not rhythm then
		return
	end

	local key = self:_pickTouch()
	local offset = self._contactOffset[key]
	if not offset then
		-- Todavía no sabemos dónde cae el marker de esa animación. Se sabrá en
		-- cuanto se reproduzca una vez; hasta entonces se toca al recibir.
		return
	end

	local rate = rateFor(rhythm)

	-- El servidor re-ancla el ciclo en el bote que acabas de dar, así que el
	-- siguiente cae justo una duración después.
	local nextBeat = rhythm.startTime + rhythm.duration

	-- El adelanto se divide por la velocidad: a doble velocidad el contacto
	-- llega en la mitad de tiempo, así que hay que arrancar menos antes.
	local startAt = nextBeat - offset / rate
	local delay = startAt - Workspace:GetServerTimeNow()

	self._scheduleToken += 1
	local token = self._scheduleToken
	self._scheduled = true

	local function fire()
		if self._scheduleToken == token then
			self:_playTouch(key, rate)
		end
	end

	if delay <= 0 then
		-- Ya vamos tarde (ping alto o ciclo muy corto): salir ya es lo mejor.
		fire()
	else
		task.delay(delay, fire)
	end
end

function CharacterAnimationController:_cancelScheduled()
	self._scheduleToken += 1
	self._scheduled = false
end

function CharacterAnimationController:_playTouch(key: string, rate: number)
	local track = self._tracks[key]
	if not track then
		return
	end

	-- Cortamos el otro toque por si quedara sonando de un acierto anterior.
	local other = self._tracks[if key == "normal" then "knee" else "normal"]
	if other and other.IsPlaying then
		other:Stop(AnimationConfig.FadeTime)
	end

	track:Stop(0)
	track:Play(AnimationConfig.FadeTime)
	track:AdjustSpeed(rate)
end

function CharacterAnimationController:_playCelebration(payload)
	local track = self._tracks.celebration
	if not track then
		return
	end

	-- Los toques se cortan: la celebración manda.
	for key, other in self._tracks do
		if key ~= "celebration" and other.IsPlaying then
			other:Stop(AnimationConfig.FadeTime)
		end
	end

	track:Stop(0)
	track:Play(AnimationConfig.FadeTime)
	-- A velocidad normal a propósito: la vuelta al mundo tiene que verse entera.
	track:AdjustSpeed(1)

	-- La coreografía del balón arrancó en el instante en que el SERVIDOR
	-- resolvió la skill, pero este aviso ha tardado el viaje de red en llegar.
	-- Si empezáramos la animación desde el fotograma 0 iría por detrás del
	-- balón y el golpe no cuadraría.
	--
	-- Como el momento de arranque ya pasó, adelantamos la pista hasta donde
	-- debería ir. Se pierden unos milisegundos del inicio (nada perceptible) y
	-- a cambio el contacto cae justo donde el balón está arriba esperándolo.
	local startTime = self:_trajectoryStart(payload)
	if startTime then
		local elapsed = Workspace:GetServerTimeNow() - startTime
		if elapsed > 0 and track.Length > 0 then
			track.TimePosition = math.min(elapsed, track.Length)
		end
	end
end

-- El servidor ancla el ritmo al FINAL de la coreografía, así que restándole su
-- duración sale el instante en que empezó. Mismo cálculo que hace el
-- BallController: los dos quedan clavados al mismo reloj.
function CharacterAnimationController:_trajectoryStart(payload): number?
	local duration = SkillTrajectories.GetDuration(payload.trajectory)
	if duration <= 0 or not payload.rhythm then
		return nil
	end
	return payload.rhythm.startTime - duration
end

-- ============================================================
-- PUNTO DE CONEXIÓN DEL CONTACTO PIE-BALÓN
-- ============================================================
-- Se dispara en el fotograma EXACTO en que el pie toca el balón, lo diga el
-- marker de la animación. Aquí van luego el sonido del golpe (con el pitch que
-- sube con el combo, ya decidido), las partículas y el impulso del balón.
--
-- Que sea el marker y no un `task.wait(0.15)` es lo que hace que siga cuadrando
-- cuando la animación se acelera con el combo: a doble velocidad el marker
-- llega a la mitad de tiempo solo, mientras que una espera fija se quedaría
-- clavada y el sonido sonaría tarde.
function CharacterAnimationController:_onContact(_key: string) end

return CharacterAnimationController
