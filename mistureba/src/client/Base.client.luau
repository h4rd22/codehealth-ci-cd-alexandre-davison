--!strict
-- Ajustes que só valem para quem está jogando:
-- - o dono passa pela própria porta trancada (os outros batem nela);
-- - o botão "Roubar" não aparece nas suas próprias Misturebas;
-- - o botão "Trancar" só aparece na sua base;
-- - as Misturebas das bases ficam pulando de leve (só na tela, não pesa no servidor);
-- - na sua base sobem numerozinhos "+moedas" a cada segundo.
-- O servidor confere tudo de novo, isto é só para a tela ficar certa.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Util = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Util"))
local Config = require(ReplicatedStorage.Shared:WaitForChild("Config"))

local jogador = Players.LocalPlayer
local mapa = workspace:WaitForChild("Mapa")

-- modelo -> posição original e um atraso para cada uma pular num ritmo diferente
type Animada = {
	origem: CFrame,
	fase: number,
	olhos: { SpecialMesh },
	malha: SpecialMesh?, -- malha do corpo (para amassar no pulo)
	giro: number?,
	proximoPulo: number,
	puloInicio: number?,
	nasceu: number?, -- hora em que caiu na base (animação de chegada)
}
local animadas: { [Model]: Animada } = setmetatable({}, { __mode = "k" }) :: any
local primeiraVarredura = true
local QUEDA = 0.4 -- segundos caindo quando chega na base

-- Mistureba nova na base: cai do alto, amassa no chão e solta estrelinhas da cor da raridade
local function nascer(modelo: Model)
	local corpo = modelo.PrimaryPart
	local def = Config.PorId[modelo:GetAttribute("Criatura") :: string]
	if not corpo or not def or (corpo.Position - workspace.CurrentCamera.CFrame.Position).Magnitude > 140 then
		return
	end
	local info = Config.Raridades[def.raridade]
	local nivel = table.find(Config.OrdemRaridades, def.raridade) or 1

	-- cai do alto e amassa ao tocar o chão (o movimento é feito no laço de animação)
	local anim = animadas[modelo]
	if anim then
		anim.nasceu = os.clock()
		anim.proximoPulo = os.clock() + 1.5
	end

	local ponto = Instance.new("Attachment")
	ponto.Parent = corpo
	local estrelas = Instance.new("ParticleEmitter")
	estrelas.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	estrelas.Color = ColorSequence.new(info.cor, Color3.new(1, 1, 1))
	estrelas.LightEmission = 1
	estrelas.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.9), NumberSequenceKeypoint.new(1, 0) })
	estrelas.Lifetime = NumberRange.new(0.5, 1)
	estrelas.Speed = NumberRange.new(8, 14 + nivel * 2)
	estrelas.SpreadAngle = Vector2.new(180, 180)
	estrelas.Drag = 4
	estrelas.Rate = 0
	estrelas.Parent = ponto
	task.delay(QUEDA, function()
		estrelas:Emit(10 + nivel * 6)
	end)
	task.delay(QUEDA + 1.5, function()
		ponto:Destroy()
	end)

	-- das Épicas para cima: uma onda de luz no chão quando ela pousa
	if nivel >= 3 then
		task.wait(QUEDA)
		local onda = Instance.new("Part")
		onda.Shape = Enum.PartType.Cylinder
		onda.Anchored = true
		onda.CanCollide = false
		onda.CanQuery = false
		onda.CanTouch = false
		onda.CastShadow = false
		onda.Material = Enum.Material.Neon
		onda.Color = info.cor
		onda.Transparency = 0.2
		onda.Size = Vector3.new(0.15, 2, 2)
		onda.CFrame = CFrame.new(modelo:GetPivot().Position - Vector3.new(0, corpo.Size.Y / 2, 0))
			* CFrame.Angles(0, 0, math.pi / 2)
		onda.Parent = workspace
		local raio = 8 + nivel * 3
		TweenService:Create(onda, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = Vector3.new(0.15, raio, raio),
			Transparency = 1,
		}):Play()
		task.delay(0.8, function()
			onda:Destroy()
		end)
	end
end

local function ajustar()
	for _, obj in mapa:GetDescendants() do
		if obj:IsA("ProximityPrompt") then
			local dono = obj:GetAttribute("Dono")
			if obj.Name == "Roubar" then
				obj.Enabled = dono ~= jogador.UserId
			elseif obj.Name == "Cadeado" then
				obj.Enabled = dono == jogador.UserId
			end
		elseif obj:IsA("BasePart") and obj.Name == "Porta" then
			if obj:GetAttribute("Dono") == jogador.UserId then
				obj.CanCollide = false
				obj.LocalTransparencyModifier = 0.5
			end
		elseif obj:IsA("Model") and obj:GetAttribute("Criatura") and not animadas[obj] then
			local olhos = {}
			for _, p in obj:GetDescendants() do
				if
					p:IsA("SpecialMesh")
					and p.Parent
					and (p.Parent.Name == "Olho" or p.Parent.Name == "Pupila" or p.Parent.Name == "BrilhoOlho")
				then
					table.insert(olhos, p)
				end
			end
			local corpo = obj.PrimaryPart
			animadas[obj] = {
				origem = obj:GetPivot(),
				fase = math.random() * math.pi * 2,
				olhos = olhos,
				malha = corpo and corpo:FindFirstChildOfClass("SpecialMesh") or nil,
				proximoPulo = os.clock() + math.random() * 4,
			}
			if not primeiraVarredura then
				task.spawn(nascer, obj)
			end
		end
	end
	primeiraVarredura = false
end

-- piscadinha: de vez em quando cada Mistureba fecha os olhos rapidinho
task.spawn(function()
	while true do
		task.wait(0.25)
		for modelo, info in animadas do
			if modelo.Parent and math.random() < 0.035 then
				for _, malha in info.olhos do
					malha.Scale = Vector3.new(1, 0.12, 1)
				end
				task.delay(0.13, function()
					for _, malha in info.olhos do
						malha.Scale = Vector3.new(1, 1, 1)
					end
				end)
			end
		end
	end
end)

-- Animação das Misturebas (só as perto da câmera, para ficar leve no celular):
-- respiram de leve, viram para olhar você e de vez em quando dão um pulinho
-- com agachada antes e amassadinha ao pousar. Chegando na base, caem do alto.
local PERTO = 70
local function amassar(t: number): (number, number)
	-- devolve (altura, amasso) para o tempo t desde o começo do pulo
	if t < 0.12 then
		return 0, -0.12 * math.sin(t / 0.12 * math.pi / 2) -- agacha
	elseif t < 0.52 then
		local u = (t - 0.12) / 0.4
		return math.sin(u * math.pi), 0.1 * (1 - u) -- sobe esticada
	elseif t < 0.7 then
		local u = (t - 0.52) / 0.18
		return 0, -0.14 * math.sin(u * math.pi) -- amassa ao pousar
	end
	return 0, 0
end

RunService.RenderStepped:Connect(function(dt)
	local agora = os.clock()
	local camera = workspace.CurrentCamera
	local olho = camera and camera.CFrame.Position or Vector3.zero
	local personagem = jogador.Character
	local raizP = personagem and personagem:FindFirstChild("HumanoidRootPart") :: BasePart?
	local suave = math.min(1, dt * 6)
	for modelo, info in animadas do
		if not modelo.Parent or (info.origem.Position - olho).Magnitude > PERTO then
			continue
		end
		-- vira devagar para o jogador quando ele chega perto
		local alvo = math.sin(agora * 0.5 + info.fase) * 0.3
		local perto = false
		if raizP then
			local rel = info.origem:PointToObjectSpace(raizP.Position)
			local distancia = Vector3.new(rel.X, 0, rel.Z).Magnitude
			if distancia < 22 and distancia > 0.5 then
				perto = true
				alvo = math.atan2(-rel.X, -rel.Z)
			end
		end
		local giroAtual = info.giro or 0
		local diferenca = (alvo - giroAtual + math.pi) % (math.pi * 2) - math.pi
		info.giro = giroAtual + diferenca * suave

		local altura, amasso = 0, 0
		if info.nasceu then
			-- queda com aceleração e amassada forte no chão
			local t = agora - info.nasceu
			if t < QUEDA then
				local u = t / QUEDA
				altura = 6 * (1 - u * u)
				amasso = 0.12
			elseif t < QUEDA + 0.3 then
				amasso = -0.25 * math.sin((t - QUEDA) / 0.3 * math.pi)
			else
				info.nasceu = nil
			end
		else
			if not info.puloInicio and agora >= info.proximoPulo then
				info.puloInicio = agora
			end
			if info.puloInicio then
				local t = agora - info.puloInicio
				local h, a = amassar(t)
				altura = h * (if perto then 0.9 else 0.55)
				amasso = a
				if t >= 0.7 then
					info.puloInicio = nil
					info.proximoPulo = agora + (if perto then 0.6 + math.random() * 1.2 else 2 + math.random() * 4)
				end
			end
			-- respiração bem de leve
			amasso += math.sin(agora * 2.2 + info.fase) * 0.02
		end
		modelo:PivotTo(info.origem * CFrame.new(0, altura, 0) * CFrame.Angles(0, info.giro, 0))
		if info.malha then
			info.malha.Scale = Vector3.new(1 - amasso * 0.6, 1 + amasso, 1 - amasso * 0.6)
		end
	end
end)

-- "+123" subindo de uma Mistureba aleatória da sua base
local minhaBase: number? = nil
local rendaAtual = 0
local estadoRemoto = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Estado") :: RemoteEvent
estadoRemoto.OnClientEvent:Connect(function(estado: any)
	if type(estado) == "table" then
		minhaBase = estado.baseIndice
		rendaAtual = tonumber(estado.renda) or 0
	end
end)

local function numeroSubindo()
	if not minhaBase or rendaAtual <= 0 then
		return
	end
	local base = mapa:FindFirstChild("Base" .. minhaBase)
	if not base then
		return
	end
	local corpos = {}
	for _, obj in base:GetChildren() do
		if obj:IsA("Model") and obj:GetAttribute("Criatura") and obj.PrimaryPart then
			table.insert(corpos, obj.PrimaryPart)
		end
	end
	if #corpos == 0 then
		return
	end
	local alvo = corpos[math.random(1, #corpos)]
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromScale(6, 2)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 4, 0)
	gui.LightInfluence = 0
	gui.AlwaysOnTop = true
	gui.MaxDistance = 90
	local rotulo = Instance.new("TextLabel")
	rotulo.Size = UDim2.fromScale(1, 1)
	rotulo.BackgroundTransparency = 1
	rotulo.Font = Enum.Font.FredokaOne
	rotulo.TextScaled = true
	rotulo.TextColor3 = Color3.fromRGB(255, 230, 80)
	rotulo.TextStrokeTransparency = 0
	rotulo.Text = "+" .. Util.numero(math.floor(rendaAtual))
	rotulo.Parent = gui
	gui.Adornee = alvo
	gui.Parent = jogador:WaitForChild("PlayerGui")
	local info = TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(gui, info, { StudsOffsetWorldSpace = Vector3.new(0, 9, 0) }):Play()
	TweenService:Create(rotulo, info, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	task.delay(1.2, function()
		gui:Destroy()
	end)
end

task.spawn(function()
	while true do
		task.wait(1)
		numeroSubindo()
	end
end)

while true do
	ajustar()
	task.wait(0.4)
end
