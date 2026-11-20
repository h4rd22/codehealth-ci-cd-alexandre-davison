--!strict
-- Efeitos só de tela nas Misturebas (não pesa no servidor):
-- - Arco-íris: as cores do degradê ficam andando devagar.
-- Só atualiza as que estão perto da câmera e no máximo 12 vezes por segundo.

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local DISTANCIA = 80
local INTERVALO = 1 / 12

type Info = { corpo: BasePart?, partes: { { parte: BasePart, matiz: number } } }
local arcoiris: { [Instance]: Info } = {}

local function adicionar(modelo: Instance)
	if not modelo:IsA("Model") then
		return
	end
	local info: Info = { corpo = modelo.PrimaryPart, partes = {} }
	for _, p in modelo:GetDescendants() do
		local m = p:GetAttribute("Matiz")
		if p:IsA("BasePart") and type(m) == "number" then
			table.insert(info.partes, { parte = p, matiz = m })
		end
	end
	arcoiris[modelo] = info
end

CollectionService:GetInstanceAddedSignal("Arcoiris"):Connect(adicionar)
CollectionService:GetInstanceRemovedSignal("Arcoiris"):Connect(function(modelo)
	arcoiris[modelo] = nil
end)
for _, modelo in CollectionService:GetTagged("Arcoiris") do
	adicionar(modelo)
end

local acumulado = 0
RunService.Heartbeat:Connect(function(dt)
	acumulado += dt
	if acumulado < INTERVALO then
		return
	end
	acumulado = 0
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local deslocamento = (os.clock() * 0.15) % 1
	local olho = camera.CFrame.Position
	for _, info in arcoiris do
		local corpo = info.corpo
		if #info.partes == 0 and corpo and corpo.Parent then
			adicionar(corpo.Parent) -- peças ainda chegando (streaming)
			continue
		end
		if corpo and corpo.Parent and (corpo.Position - olho).Magnitude < DISTANCIA then
			for _, item in info.partes do
				item.parte.Color = Color3.fromHSV((item.matiz + deslocamento) % 1, 0.6, 1)
			end
		end
	end
end)

------------------------------------------------------------------------
-- Revelação das raras: quando você choca uma Lendária, Mítica ou Secreta,
-- a tela escurece, um brilho cresce, explode num flash e a Mistureba aparece
-- em 3D girando, com raios de luz e o nome da raridade.
------------------------------------------------------------------------
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Modelos = require(Shared:WaitForChild("Modelos"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local jogador = Players.LocalPlayer
local somLigado, modoLeve = true, false
local estadoRemoto = remotes:WaitForChild("Estado") :: RemoteEvent
estadoRemoto.OnClientEvent:Connect(function(estado: any)
	if type(estado) == "table" and type(estado.ajustes) == "table" then
		somLigado = estado.ajustes.som ~= false
		modoLeve = estado.ajustes.leve == true
	end
end)

local TITULOS = { lendario = "LENDÁRIA!", mitico = "MÍTICA!!", secreto = "SECRETA!!!" }

local function tocar(pai: Instance, tom: number, volume: number)
	if not somLigado then
		return
	end
	local som = Instance.new("Sound")
	som.SoundId = "rbxasset://sounds/electronicpingshort.wav"
	som.PlaybackSpeed = tom
	som.Volume = volume
	som.Parent = pai
	som:Play()
	som.Ended:Once(function()
		som:Destroy()
	end)
end

local function tween(obj: Instance, tempo: number, props: { [string]: any }, estilo: Enum.EasingStyle?)
	local t = TweenService:Create(
		obj,
		TweenInfo.new(tempo, estilo or Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		props
	)
	t:Play()
	return t
end

local revelando = 0
local function revelar(id: string)
	local def = Config.PorId[id]
	if not def then
		return
	end
	local nivel = table.find(Config.OrdemRaridades, def.raridade) or 1
	if nivel < 4 then
		return
	end
	revelando += 1
	local meu = revelando
	local info = Config.Raridades[def.raridade]
	local mut = def.mutacao and Config.MutacaoPorId[def.mutacao]
	local cor = info.cor
	local extra = nivel - 4 -- 0 lendária, 1 mítica, 2 secreta

	local gui = Instance.new("ScreenGui")
	gui.Name = "Revelacao"
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 100
	gui.ResetOnSpawn = false
	gui.Parent = jogador:WaitForChild("PlayerGui")

	local fundo = Instance.new("Frame")
	fundo.Size = UDim2.fromScale(1, 1)
	fundo.BackgroundColor3 = Color3.new(0, 0, 0)
	fundo.BackgroundTransparency = 1
	fundo.BorderSizePixel = 0
	fundo.Parent = gui
	tween(fundo, 0.25, { BackgroundTransparency = 0.3 - extra * 0.08 })

	-- 1) brilho crescendo no meio, com notas subindo
	local bola = Instance.new("Frame")
	bola.AnchorPoint = Vector2.new(0.5, 0.5)
	bola.Position = UDim2.fromScale(0.5, 0.48)
	bola.Size = UDim2.fromOffset(20, 20)
	bola.BackgroundColor3 = cor
	bola.BorderSizePixel = 0
	bola.Parent = gui
	local canto = Instance.new("UICorner")
	canto.CornerRadius = UDim.new(0.5, 0)
	canto.Parent = bola
	local contorno = Instance.new("UIStroke")
	contorno.Color = Color3.new(1, 1, 1)
	contorno.Thickness = 4
	contorno.Parent = bola
	local carga = 0.7 + extra * 0.25
	tween(bola, carga, { Size = UDim2.fromOffset(150 + extra * 40, 150 + extra * 40) }, Enum.EasingStyle.Quint)
	task.spawn(function()
		local notas = 5 + extra * 2
		for i = 1, notas do
			tocar(gui, 0.7 + i * 0.12, 0.4)
			task.wait(carga / notas)
		end
		tocar(gui, 2.2, 0.6)
		tocar(gui, 1.1, 0.6)
	end)
	task.wait(carga)
	if meu ~= revelando then
		gui:Destroy()
		return
	end

	-- 2) flash e explosão
	bola:Destroy()
	local flash = Instance.new("Frame")
	flash.Size = UDim2.fromScale(1, 1)
	flash.BackgroundColor3 = Color3.new(1, 1, 1)
	flash.BackgroundTransparency = 0
	flash.BorderSizePixel = 0
	flash.ZIndex = 10
	flash.Parent = gui
	tween(flash, 0.5, { BackgroundTransparency = 1 })

	-- raios girando
	local raios = Instance.new("Frame")
	raios.AnchorPoint = Vector2.new(0.5, 0.5)
	raios.Position = UDim2.fromScale(0.5, 0.48)
	raios.Size = UDim2.fromOffset(10, 10)
	raios.BackgroundTransparency = 1
	raios.Parent = gui
	if not modoLeve then
		local n = 8 + extra * 4
		for i = 1, n do
			local r = Instance.new("Frame")
			r.AnchorPoint = Vector2.new(0.5, 0.5)
			r.Position = UDim2.fromScale(0.5, 0.5)
			r.Size = UDim2.fromOffset(1600, 60)
			r.Rotation = i * 180 / n
			r.BackgroundColor3 = if i % 2 == 0 then Color3.new(1, 1, 1) else cor
			r.BackgroundTransparency = 0.55
			r.BorderSizePixel = 0
			local g = Instance.new("UIGradient")
			g.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.5, 0),
				NumberSequenceKeypoint.new(1, 1),
			})
			g.Parent = r
			r.Parent = raios
		end
	end

	-- a Mistureba em 3D
	local vp = Instance.new("ViewportFrame")
	vp.AnchorPoint = Vector2.new(0.5, 0.5)
	vp.Position = UDim2.fromScale(0.5, 0.46)
	vp.Size = UDim2.fromScale(0.6, 0.6)
	vp.BackgroundTransparency = 1
	vp.Ambient = Color3.fromRGB(200, 200, 210)
	vp.LightColor = Color3.new(1, 1, 1)
	vp.LightDirection = Vector3.new(-1, -1.5, -1)
	vp.Parent = gui
	local aspecto = Instance.new("UIAspectRatioConstraint")
	aspecto.AspectRatio = 1
	aspecto.Parent = vp
	local modelo = Modelos.modelo(id)
	for _, d in modelo:GetDescendants() do
		if d:IsA("BillboardGui") or d:IsA("ParticleEmitter") or d:IsA("Light") then
			d:Destroy()
		end
	end
	modelo:PivotTo(CFrame.new())
	modelo.Parent = vp
	local caixaCf, caixa = modelo:GetBoundingBox()
	local centro = caixaCf.Position
	local raio = caixa.Magnitude / 2
	local camera = Instance.new("Camera")
	camera.FieldOfView = 40
	camera.Parent = vp
	vp.CurrentCamera = camera
	local distancia = raio / math.tan(math.rad(20)) * 0.7

	-- título
	local titulo = Instance.new("TextLabel")
	titulo.AnchorPoint = Vector2.new(0.5, 0.5)
	titulo.Position = UDim2.fromScale(0.5, 0.13)
	titulo.Size = UDim2.fromScale(0.9, 0.12)
	titulo.BackgroundTransparency = 1
	titulo.Font = Enum.Font.FredokaOne
	titulo.TextScaled = true
	titulo.Text = TITULOS[def.raridade] or info.nome
	titulo.TextColor3 = cor
	titulo.Parent = gui
	local borda = Instance.new("UIStroke")
	borda.Thickness = 4
	borda.Color = Color3.new(1, 1, 1)
	borda.Parent = titulo
	local nome = titulo:Clone()
	nome.Position = UDim2.fromScale(0.5, 0.8)
	nome.Size = UDim2.fromScale(0.8, 0.07)
	nome.Text = def.nome
	nome.TextColor3 = Color3.new(1, 1, 1)
	local bordaNome = nome:FindFirstChildOfClass("UIStroke")
	if bordaNome then
		bordaNome.Color = Color3.new(0, 0, 0)
	end
	nome.Parent = gui
	if mut then
		local tagMut = nome:Clone()
		tagMut.Position = UDim2.fromScale(0.5, 0.87)
		tagMut.Size = UDim2.fromScale(0.6, 0.05)
		tagMut.Text = "MUTAÇÃO " .. string.upper(mut.nome) .. "!"
		tagMut.TextColor3 = mut.cor
		tagMut.Parent = gui
	end
	for _, rotulo in { titulo, nome } do
		local escala = Instance.new("UIScale")
		escala.Scale = 0.2
		escala.Parent = rotulo
		tween(escala, 0.5, { Scale = 1 }, Enum.EasingStyle.Back)
	end

	-- anima: câmera chega perto, Mistureba gira, raios giram, tela treme um pouco
	local duracao = 2.6 + extra * 0.5
	local inicio = os.clock()
	local conexao
	conexao = RunService.RenderStepped:Connect(function()
		local t = os.clock() - inicio
		local chegada = 1 - (1 - math.min(t / 0.6, 1)) ^ 3
		local d = distancia * (2.4 - 1.4 * chegada)
		local ang = t * 1.6 + math.pi
		camera.CFrame = CFrame.lookAt(
			centro + Vector3.new(math.sin(ang) * d, raio * 0.35, math.cos(ang) * d),
			centro
		)
		raios.Rotation = t * (25 + extra * 15)
		local tremor = math.max(0, 0.4 - t) * (6 + extra * 6)
		vp.Position = UDim2.new(0.5, math.random(-10, 10) * tremor / 10, 0.46, math.random(-10, 10) * tremor / 10)
	end)

	task.wait(duracao)
	conexao:Disconnect()
	if meu ~= revelando then
		gui:Destroy()
		return
	end
	-- some devagar e deixa o cartão normal de chocar aparecer
	for _, d in gui:GetDescendants() do
		if d:IsA("Frame") then
			tween(d, 0.35, { BackgroundTransparency = 1 })
		elseif d:IsA("TextLabel") then
			tween(d, 0.35, { TextTransparency = 1 })
		elseif d:IsA("UIStroke") then
			tween(d, 0.35, { Transparency = 1 })
		elseif d:IsA("ViewportFrame") then
			tween(d, 0.35, { ImageTransparency = 1 })
		end
	end
	task.wait(0.4)
	gui:Destroy()
end

local chocou = remotes:WaitForChild("Chocou") :: RemoteEvent
chocou.OnClientEvent:Connect(function(id: any)
	if type(id) == "string" then
		task.spawn(revelar, id)
	end
end)
