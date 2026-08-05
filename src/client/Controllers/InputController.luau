-- src/client/Controllers/InputController.luau
-- Captura el intento de picadita. Su ÚNICA responsabilidad es avisar al
-- servidor de que se pulsó y en qué instante. No decide si fue acierto: eso
-- lo hace el ComboService (ver ClienteYServidor.md).

local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Knit = require(ReplicatedStorage.Packages.Knit)

local ACTION_NAME = "Picadita"

local InputController = Knit.CreateController({
	Name = "InputController",
})

function InputController:KnitInit()
	self._comboService = nil
end

function InputController:KnitStart()
	self._comboService = Knit.GetService("ComboService")

	-- ContextActionService en vez de UserInputService por una razón concreta:
	-- el tercer argumento (`true`) hace que Roblox cree SOLO en móvil un botón
	-- táctil en pantalla para esta misma acción. Soporte móvil gratis.
	ContextActionService:BindAction(ACTION_NAME, function(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			self:_attemptPicadita()
		end
		-- Sink = nos quedamos la tecla. Si no, espacio también haría saltar al
		-- personaje en cada toque. Cambia a Pass si prefieres poder saltar.
		return Enum.ContextActionResult.Sink
	end, true, Enum.KeyCode.Space)

	ContextActionService:SetTitle(ACTION_NAME, "PICA")
end

function InputController:_attemptPicadita()
	-- Mandamos el instante EXACTO de la pulsación, no "ahora": entre que esto
	-- sale y llega al servidor pasan unos milisegundos, y sin la marca de
	-- tiempo el jugador con ping alto siempre llegaría tarde.
	-- El servidor no se fía de este número a ciegas: lo acota (ver ComboService).
	self._comboService.SendInput:Fire(Workspace:GetServerTimeNow())
end

return InputController
