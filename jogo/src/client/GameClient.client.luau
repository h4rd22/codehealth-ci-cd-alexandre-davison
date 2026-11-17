-- GameClient: auto-farm (o herói anda sozinho) e efeitos:
-- números de dano, tremida de tela, explosão, drop de itens com brilho
-- da raridade, avisos de fase/nível e anúncio de lendário.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local ItemArte = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ItemArte"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local evDano = remotes:WaitForChild("Dano")
local evAviso = remotes:WaitForChild("Aviso")
local evLoot = remotes:WaitForChild("Loot")

local player = Players.LocalPlayer
local pasta = workspace:WaitForChild("Monstros")

local function raridade(id)
	for i, r in ipairs(Config.Raridades) do
		if r.id == id then
			return r, i
		end
	end
	return Config.Raridades[1], 1
end

------------------------------------------------------------------------
-- Tela de efeitos (avisos e notificações)
------------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "Efeitos"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 3
gui.Parent = player:WaitForChild("PlayerGui")

local faixa = Instance.new("TextLabel")
faixa.AnchorPoint = Vector2.new(0.5, 0.5)
faixa.Position = UDim2.fromScale(0.5, 0.36)
faixa.Size = UDim2.new(0.9, 0, 0, 80)
faixa.BackgroundTransparency = 1
faixa.Font = Enum.Font.GothamBlack
faixa.TextScaled = true
faixa.TextWrapped = true
faixa.TextColor3 = Color3.fromRGB(255, 225, 120)
faixa.TextStrokeColor3 = Color3.fromRGB(70, 35, 130)
faixa.TextTransparency = 1
faixa.TextStrokeTransparency = 1
faixa.Text = ""
faixa.Parent = gui
local lim = Instance.new("UITextSizeConstraint")
lim.MaxTextSize = 48
lim.Parent = faixa
local escala = Instance.new("UIScale")
escala.Parent = faixa

local function mostrarFaixa(msg, cor, tempo)
	faixa.Text = msg
	faixa.TextColor3 = cor or Color3.fromRGB(255, 225, 120)
	escala.Scale = 0.6
	TweenService:Create(escala, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	TweenService:Create(faixa, TweenInfo.new(0.3), { TextTransparency = 0, TextStrokeTransparency = 0 }):Play()
	task.delay(tempo or 2.2, function()
		if faixa.Text == msg then
			TweenService:Create(faixa, TweenInfo.new(0.5), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		end
	end)
end

-- Notificações de itens (lado direito)
local pilha = Instance.new("Frame")
pilha.AnchorPoint = Vector2.new(1, 0)
pilha.Position = UDim2.new(1, -14, 0, 176)
pilha.Size = UDim2.fromOffset(280, 300)
pilha.BackgroundTransparency = 1
pilha.Parent = gui
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 6)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = pilha
local ordem = 0

local function notificar(texto, cor)
	ordem -= 1
	-- cartão de madeira escura com faixa na cor (raridade) e brilho, entra deslizando
	local f = Instance.new("Frame")
	f.LayoutOrder = ordem
	f.Size = UDim2.fromOffset(280, 32)
	f.BackgroundTransparency = 1
	f.Parent = pilha
	local card = Instance.new("Frame")
	card.Size = UDim2.fromScale(1, 1)
	card.Position = UDim2.fromOffset(300, 0)
	card.BackgroundColor3 = Color3.fromRGB(34, 26, 22)
	card.BorderSizePixel = 0
	card.Parent = f
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = card
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(cor:Lerp(Color3.fromRGB(34, 26, 22), 0.55), Color3.fromRGB(34, 26, 22))
	g.Transparency = NumberSequence.new(0.05, 0.12)
	g.Parent = card
	local s = Instance.new("UIStroke")
	s.Color = cor:Lerp(Color3.new(1, 1, 1), 0.15)
	s.Thickness = 1.5
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = card
	local tira = Instance.new("Frame")
	tira.Size = UDim2.new(0, 5, 1, -8)
	tira.Position = UDim2.fromOffset(4, 4)
	tira.BackgroundColor3 = cor
	tira.BorderSizePixel = 0
	tira.Parent = card
	local tc = Instance.new("UICorner")
	tc.CornerRadius = UDim.new(0, 3)
	tc.Parent = tira
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Position = UDim2.fromOffset(14, 0)
	t.Size = UDim2.new(1, -20, 1, 0)
	t.Font = Enum.Font.FredokaOne
	t.TextScaled = true
	t.TextColor3 = cor:Lerp(Color3.new(1, 1, 1), 0.25)
	t.TextStrokeTransparency = 0.3
	t.TextStrokeColor3 = Color3.fromRGB(16, 10, 8)
	t.TextTruncate = Enum.TextTruncate.AtEnd
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.Text = texto
	t.Parent = card
	local limite = Instance.new("UITextSizeConstraint")
	limite.MaxTextSize = 14
	limite.MinTextSize = 10
	limite.Parent = t
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 7)
	pad.PaddingBottom = UDim.new(0, 7)
	pad.Parent = t
	TweenService:Create(card, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Position = UDim2.fromOffset(0, 0) }):Play()
	local fila = {}
	for _, x in ipairs(pilha:GetChildren()) do
		if x:IsA("Frame") then
			table.insert(fila, x)
		end
	end
	if #fila > 6 then
		table.sort(fila, function(x, y)
			return x.LayoutOrder > y.LayoutOrder
		end)
		fila[1]:Destroy()
	end
	task.delay(3.5, function()
		if f.Parent then
			local sai = TweenInfo.new(0.4)
			TweenService:Create(card, sai, { BackgroundTransparency = 1, Position = UDim2.fromOffset(60, 0) }):Play()
			TweenService:Create(t, sai, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
			TweenService:Create(tira, sai, { BackgroundTransparency = 1 }):Play()
			TweenService:Create(s, sai, { Transparency = 1 }):Play()
			Debris:AddItem(f, 0.45)
		end
	end)
end

------------------------------------------------------------------------
-- Efeitos no mundo
------------------------------------------------------------------------
local function textoFlutuante(pos, msg, cor, tamanho)
	local ancora = Instance.new("Part")
	ancora.Anchored = true
	ancora.CanCollide = false
	ancora.CanQuery = false
	ancora.Transparency = 1
	ancora.Size = Vector3.new(0.2, 0.2, 0.2)
	ancora.Position = pos + Vector3.new(math.random(-15, 15) / 10, 3, math.random(-15, 15) / 10)
	ancora.Parent = workspace
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(220, 60)
	bb.AlwaysOnTop = true
	bb.Adornee = ancora
	bb.Parent = ancora
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Text = msg
	t.TextColor3 = Color3.new(1, 1, 1)
	t.TextSize = tamanho
	t.Font = Enum.Font.FredokaOne
	t.Parent = bb
	-- contorno grosso + degradê da cor (estilo anime)
	local contorno = Instance.new("UIStroke")
	contorno.Color = Color3.fromRGB(25, 12, 10)
	contorno.Thickness = tamanho >= 28 and 3 or 2.2
	contorno.Parent = t
	local degrade = Instance.new("UIGradient")
	degrade.Rotation = 90
	degrade.Color = ColorSequence.new(cor:Lerp(Color3.new(1, 1, 1), 0.55), cor)
	degrade.Parent = t
	-- "pop": nasce grande e encolhe rapidinho
	local escalaPop = Instance.new("UIScale")
	escalaPop.Scale = tamanho >= 28 and 1.9 or 1.5
	escalaPop.Parent = t
	TweenService:Create(escalaPop, TweenInfo.new(0.22, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	TweenService:Create(contorno, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0.35), {
		Transparency = 1,
	}):Play()
	TweenService:Create(
		ancora,
		TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Position = ancora.Position + Vector3.new(0, 3, 0) }
	):Play()
	TweenService:Create(
		t,
		TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0.35),
		{ TextTransparency = 1, TextStrokeTransparency = 1 }
	):Play()
	Debris:AddItem(ancora, 0.9)
end

-- O item que caiu aparece em 3D, pula do inimigo com o brilho da raridade e sobe
local function itemPulando(pos, item, cor, ri)
	local ancora = Instance.new("Part")
	ancora.Anchored = true
	ancora.CanCollide = false
	ancora.CanQuery = false
	ancora.Transparency = 1
	ancora.Size = Vector3.new(0.2, 0.2, 0.2)
	ancora.Position = pos + Vector3.new(0, 1, 0)
	ancora.Parent = workspace
	local tamanho = ri >= 5 and 110 or 80
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(tamanho, tamanho + 22)
	bb.AlwaysOnTop = true
	bb.Adornee = ancora
	bb.Parent = ancora
	local brilho = Instance.new("Frame")
	brilho.AnchorPoint = Vector2.new(0.5, 0.5)
	brilho.Position = UDim2.new(0.5, 0, 0, tamanho / 2)
	brilho.Size = UDim2.fromOffset(tamanho, tamanho)
	brilho.BackgroundColor3 = cor
	brilho.BackgroundTransparency = 0.35
	brilho.Parent = bb
	Instance.new("UICorner", brilho).CornerRadius = UDim.new(1, 0)
	local g = Instance.new("UIGradient")
	g.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(0.5, 0.55),
		NumberSequenceKeypoint.new(1, 1),
	})
	g.Rotation = 90
	g.Parent = brilho
	local vp = Instance.new("ViewportFrame")
	vp.BackgroundTransparency = 1
	vp.Size = UDim2.fromOffset(tamanho, tamanho)
	vp.Parent = bb
	ItemArte.mostrar(vp, item.slot, ri, cor, item.conjunto, item.classe)
	local nome = Instance.new("TextLabel")
	nome.Position = UDim2.fromOffset(-40, tamanho)
	nome.Size = UDim2.new(1, 80, 0, 20)
	nome.BackgroundTransparency = 1
	nome.Text = item.nome
	nome.TextColor3 = cor
	nome.Font = Enum.Font.FredokaOne
	nome.TextSize = ri >= 5 and 18 or 14
	nome.TextStrokeTransparency = 0
	nome.TextStrokeColor3 = Color3.fromRGB(20, 10, 8)
	nome.Parent = bb
	local escalaPop = Instance.new("UIScale")
	escalaPop.Scale = 0.2
	escalaPop.Parent = bb
	TweenService:Create(escalaPop, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	TweenService:Create(ancora, TweenInfo.new(0.5, Enum.EasingStyle.Back), { Position = pos + Vector3.new(0, 5, 0) })
		:Play()
	-- gira o brilho devagar
	local giro = TweenService:Create(g, TweenInfo.new(1.6, Enum.EasingStyle.Linear), { Rotation = 450 })
	giro:Play()
	task.delay(1.4 + (ri >= 5 and 1 or 0), function()
		if bb.Parent then
			TweenService:Create(escalaPop, TweenInfo.new(0.3), { Scale = 0 }):Play()
			TweenService:Create(ancora, TweenInfo.new(0.3), { Position = ancora.Position + Vector3.new(0, 3, 0) })
				:Play()
		end
	end)
	Debris:AddItem(ancora, 2.2 + (ri >= 5 and 1 or 0))
end

local function tremer(forca, duracao)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum then
		return
	end
	task.spawn(function()
		local fim = os.clock() + duracao
		while os.clock() < fim do
			hum.CameraOffset = Vector3.new((math.random() - 0.5) * forca, (math.random() - 0.5) * forca, 0)
			task.wait()
		end
		hum.CameraOffset = Vector3.zero
	end)
end

local function explosao(pos, cor, qtd)
	for _ = 1, qtd or 10 do
		local p = Instance.new("Part")
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.Material = Enum.Material.Neon
		p.Color = cor
		p.Size = Vector3.new(0.6, 0.6, 0.6)
		p.Position = pos
		p.Parent = workspace
		local dir = Vector3.new(math.random() - 0.5, math.random() * 0.8 + 0.2, math.random() - 0.5).Unit
		TweenService:Create(
			p,
			TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Position = pos + dir * (4 + math.random() * 3), Size = Vector3.new(0.05, 0.05, 0.05), Transparency = 1 }
		):Play()
		Debris:AddItem(p, 0.5)
	end
end

-- Coluna de luz da cor da raridade no lugar onde o item caiu
local function feixe(pos, cor, forte)
	local altura = forte and 40 or 14
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.Material = Enum.Material.Neon
	p.Color = cor
	p.Transparency = 0.25
	p.Shape = Enum.PartType.Cylinder
	p.Size = Vector3.new(altura, forte and 2 or 1, forte and 2 or 1)
	p.CFrame = CFrame.new(pos.X, pos.Y - 1 + altura / 2, pos.Z) * CFrame.Angles(0, 0, math.rad(90))
	p.Parent = workspace
	TweenService
		:Create(p, TweenInfo.new(forte and 2.2 or 1.2), { Transparency = 1, Size = Vector3.new(altura, 0.1, 0.1) })
		:Play()
	Debris:AddItem(p, forte and 2.3 or 1.3)
end

-- Corte de espada estilo anime: risco de luz que atravessa o inimigo
local function corte(pos, critico)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local origem = root and root.Position or pos + Vector3.new(0, 0, 4)
	local dir = (pos - origem) * Vector3.new(1, 0, 1)
	if dir.Magnitude < 0.1 then
		dir = Vector3.new(0, 0, -1)
	end
	local base = CFrame.lookAt(pos, pos + dir.Unit)
	for i = 1, critico and 2 or 1 do
		local giro = math.rad(math.random(-60, 60) + (i == 2 and 90 or 0))
		local p = Instance.new("Part")
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Material = Enum.Material.Neon
		p.Color = critico and Color3.fromRGB(255, 220, 90) or Color3.fromRGB(190, 235, 255)
		p.Size = Vector3.new(7, 0.25, 0.12)
		p.CFrame = base * CFrame.Angles(0, 0, giro) * CFrame.new(-1.5, 0, 0)
		p.Transparency = 0.1
		p.Parent = workspace
		TweenService:Create(p, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			CFrame = p.CFrame * CFrame.new(3, 0, 0),
			Size = Vector3.new(9, 0.04, 0.04),
			Transparency = 1,
		}):Play()
		Debris:AddItem(p, 0.2)
	end
	for _ = 1, critico and 6 or 3 do
		local s = Instance.new("Part")
		s.Anchored = true
		s.CanCollide = false
		s.CanQuery = false
		s.Material = Enum.Material.Neon
		s.Color = critico and Color3.fromRGB(255, 200, 60) or Color3.new(1, 1, 1)
		s.Size = Vector3.new(0.15, 0.15, 0.9)
		local d = Vector3.new(math.random() - 0.5, math.random() - 0.2, math.random() - 0.5).Unit
		s.CFrame = CFrame.lookAt(pos, pos + d)
		s.Parent = workspace
		TweenService:Create(s, TweenInfo.new(0.25), { CFrame = s.CFrame * CFrame.new(0, 0, -3), Transparency = 1 })
			:Play()
		Debris:AddItem(s, 0.3)
	end
end

-- Peça de efeito (neon, sem colisão)
local function pecaFx(tamanho, cor, forma)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.Neon
	p.Color = cor
	p.Size = tamanho
	if forma then
		p.Shape = forma
	end
	return p
end

-- Rastro de luz atrás de um projétil
local function rastro(parte, cor, largura, vida)
	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, largura / 2, 0)
	a0.Parent = parte
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, -largura / 2, 0)
	a1.Parent = parte
	local t = Instance.new("Trail")
	t.Attachment0 = a0
	t.Attachment1 = a1
	t.Color = ColorSequence.new(cor:Lerp(Color3.new(1, 1, 1), 0.5), cor)
	t.Transparency = NumberSequence.new(0.1, 1)
	t.LightEmission = 1
	t.Lifetime = vida
	t.FaceCamera = true
	t.Parent = parte
end

-- Faíscas pequenas no ponto atingido (caçador e mago não usam o corte de espada)
local function faiscas(pos, cor, qtd)
	for _ = 1, qtd do
		local s = pecaFx(Vector3.new(0.12, 0.12, 0.8), cor)
		local d = Vector3.new(math.random() - 0.5, math.random() - 0.1, math.random() - 0.5).Unit
		s.CFrame = CFrame.lookAt(pos, pos + d)
		s.Parent = workspace
		TweenService:Create(s, TweenInfo.new(0.22), { CFrame = s.CFrame * CFrame.new(0, 0, -2.5), Transparency = 1 })
			:Play()
		Debris:AddItem(s, 0.25)
	end
end

-- Explosão de magia em área (raio do mago = 7 studs): anel no chão + esfera + faíscas
local function explosaoMagia(pos, cor, raio, critico)
	local chao = pos - Vector3.new(0, 2.2, 0)
	local anel = pecaFx(Vector3.new(0.2, 1, 1), cor, Enum.PartType.Cylinder)
	anel.CFrame = CFrame.new(chao) * CFrame.Angles(0, 0, math.rad(90))
	anel.Transparency = 0.2
	anel.Parent = workspace
	TweenService:Create(anel, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.1, raio * 2, raio * 2),
		Transparency = 1,
	}):Play()
	Debris:AddItem(anel, 0.4)
	local bola = pecaFx(Vector3.new(1, 1, 1), cor, Enum.PartType.Ball)
	bola.Material = Enum.Material.ForceField
	bola.Position = pos
	bola.Transparency = 0
	-- clarão branco no centro
	local clarao = pecaFx(Vector3.new(1.5, 1.5, 1.5), Color3.new(1, 1, 1), Enum.PartType.Ball)
	clarao.Position = pos
	clarao.Parent = workspace
	TweenService:Create(clarao, TweenInfo.new(0.18), { Size = Vector3.new(4, 4, 4), Transparency = 1 }):Play()
	Debris:AddItem(clarao, 0.2)
	-- segundo anel (cor forte) um pouco atrás do primeiro
	local anel2 = pecaFx(Vector3.new(0.3, 1, 1), cor:Lerp(Color3.new(0, 0, 0), 0.15), Enum.PartType.Cylinder)
	anel2.CFrame = CFrame.new(chao + Vector3.new(0, 0.05, 0)) * CFrame.Angles(0, 0, math.rad(90))
	anel2.Parent = workspace
	TweenService:Create(anel2, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.1, raio * 1.6, raio * 1.6),
		Transparency = 1,
	}):Play()
	Debris:AddItem(anel2, 0.55)
	bola.Parent = workspace
	local tam = critico and raio * 1.4 or raio
	TweenService:Create(bola, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(tam, tam, tam),
		Transparency = 1,
	}):Play()
	Debris:AddItem(bola, 0.35)
	local luz = Instance.new("PointLight")
	luz.Color = cor
	luz.Range = raio * 2
	luz.Brightness = 4
	luz.Parent = bola
	explosao(pos, cor, critico and 16 or 9)
end

local COR_MAGIA = Color3.fromRGB(170, 100, 255)
local COR_FLECHA = Color3.fromRGB(140, 255, 150)
local DOURADO = Color3.fromRGB(255, 215, 80)

-- Flecha (caçador) ou bola de magia (mago) voando do herói até o alvo
local function projetil(origem, destino, classeId, critico)
	if typeof(origem) ~= "Vector3" or typeof(destino) ~= "Vector3" then
		return
	end
	local inicio = origem + Vector3.new(0, 0.6, 0)
	local dist = (destino - inicio).Magnitude
	if dist < 0.5 then
		return
	end
	if classeId == "mago" then
		local cor = critico and DOURADO or COR_MAGIA
		local bola = pecaFx(Vector3.new(1.1, 1.1, 1.1), cor, Enum.PartType.Ball)
		bola.Position = inicio
		bola.Parent = workspace
		local nucleo = pecaFx(Vector3.new(0.6, 0.6, 0.6), Color3.new(1, 1, 1), Enum.PartType.Ball)
		nucleo.Position = inicio
		nucleo.Parent = bola
		local luz = Instance.new("PointLight")
		luz.Color = cor
		luz.Range = 10
		luz.Brightness = 3
		luz.Parent = bola
		rastro(bola, cor, 0.9, 0.25)
		local tempo = math.clamp(dist / 70, 0.12, 0.3)
		local t0 = os.clock()
		local con
		con = RunService.Heartbeat:Connect(function()
			local a = math.min((os.clock() - t0) / tempo, 1)
			-- sobe um pouco no meio do caminho (arco de magia)
			local p = inicio:Lerp(destino, a) + Vector3.new(0, math.sin(a * math.pi) * dist * 0.12, 0)
			bola.Position = p
			nucleo.Position = p
			if a >= 1 then
				con:Disconnect()
				bola:Destroy()
				explosaoMagia(destino, cor, 7, critico)
			end
		end)
		Debris:AddItem(bola, 1)
	else
		local cor = critico and DOURADO or COR_FLECHA
		local flecha = Instance.new("Model")
		local haste = pecaFx(Vector3.new(0.12, 0.12, 2.2), Color3.fromRGB(150, 110, 70))
		haste.Material = Enum.Material.Wood
		haste.Parent = flecha
		local ponta = pecaFx(Vector3.new(0.3, 0.3, 0.5), cor)
		ponta.Parent = flecha
		rastro(haste, cor, 0.35, 0.18)
		flecha.Parent = workspace
		local tempo = math.clamp(dist / 110, 0.06, 0.2)
		local t0 = os.clock()
		local con
		con = RunService.Heartbeat:Connect(function()
			local a = math.min((os.clock() - t0) / tempo, 1)
			local p = inicio:Lerp(destino, a)
			local cf = CFrame.lookAt(p, destino + (destino - inicio).Unit)
			haste.CFrame = cf
			ponta.CFrame = cf * CFrame.new(0, 0, -1.2)
			if a >= 1 then
				con:Disconnect()
				flecha:Destroy()
				faiscas(destino, cor, critico and 8 or 4)
			end
		end)
		Debris:AddItem(flecha, 1)
	end
end

-- Tela vermelha quando o herói apanha
local flash = Instance.new("Frame")
flash.Size = UDim2.fromScale(1, 1)
flash.BackgroundColor3 = Color3.fromRGB(255, 30, 40)
flash.BackgroundTransparency = 1
flash.BorderSizePixel = 0
flash.ZIndex = 0
flash.Parent = gui
local function piscarTela(forca)
	flash.BackgroundTransparency = 1 - forca
	TweenService:Create(flash, TweenInfo.new(0.35), { BackgroundTransparency = 1 }):Play()
end

local morto = false

evDano.OnClientEvent:Connect(function(tipo, pos, valor, extra, xp, chefe)
	if tipo == "heroi" then
		textoFlutuante(pos + Vector3.new(0, 1, 0), "-" .. valor, Color3.fromRGB(255, 70, 70), valor >= 50 and 30 or 22)
		piscarTela(valor >= 50 and 0.35 or 0.15)
		if valor >= 50 then
			tremer(0.8, 0.25)
		end
		return
	end
	if tipo == "projetil" then
		projetil(pos, valor, extra, xp)
		return
	end
	if tipo == "dano" then
		local minhaClasse = player:GetAttribute("Classe")
		if minhaClasse == "cacador" or minhaClasse == "mago" then
			faiscas(pos, extra and DOURADO or Color3.new(1, 1, 1), extra and 5 or 2)
		else
			corte(pos, extra)
		end
		if extra then
			textoFlutuante(pos, "CRÍTICO! " .. valor, Color3.fromRGB(255, 220, 60), 34)
			tremer(0.6, 0.15)
		else
			textoFlutuante(pos, tostring(valor), Color3.new(1, 1, 1), 24)
		end
	elseif tipo == "morte" then
		explosao(pos, extra, chefe and 40 or 10)
		if chefe then
			tremer(1.6, 0.8)
			mostrarFaixa("PEN DERROTADO!", Color3.fromRGB(220, 170, 255), 3)
		end
		textoFlutuante(pos + Vector3.new(0, 1, 0), "+" .. valor .. " ouro", Color3.fromRGB(255, 205, 70), 22)
		if xp then
			textoFlutuante(pos + Vector3.new(0, 2.5, 0), "+" .. xp .. " XP", Color3.fromRGB(80, 220, 170), 18)
		end
	end
end)

evLoot.OnClientEvent:Connect(function(tipo, pos, item, ouro)
	local r, ri = raridade(item.raridade)
	local corTexto = r.corBorda or r.cor -- itens pretos (Secreto) usam a borda clara
	if tipo == "vendido" then
		notificar("💰 Vendido: " .. item.nome .. " (+" .. ouro .. ")", Color3.fromRGB(200, 185, 150))
		return
	end
	if tipo == "cheio" then
		notificar("Mochila cheia: " .. item.nome .. " virou " .. ouro .. " ouro", Color3.fromRGB(255, 205, 70))
		return
	end
	if pos then
		feixe(pos, r.cor, ri >= 4)
		itemPulando(pos, item, corTexto, ri)
	end
	if tipo == "forja" then
		notificar("🔨 Forjou: " .. item.nome .. " (" .. r.nome .. ")", corTexto)
		mostrarFaixa("FORJADO: " .. string.upper(r.nome) .. "!", corTexto, 1.6)
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if root then
			explosao(root.Position, r.cor, 16)
		end
	else
		notificar(item.nome .. " (" .. r.nome .. ")", corTexto)
	end
	if ri >= 5 then
		tremer(1.2, 0.5)
	elseif ri >= 4 then
		tremer(0.6, 0.25)
	end
end)

evAviso.OnClientEvent:Connect(function(tipo, a, b)
	if tipo == "fase" then
		mostrarFaixa("FASE " .. a .. "!")
		tremer(0.8, 0.3)
	elseif tipo == "nivel" then
		mostrarFaixa("NÍVEL " .. a .. "!", Color3.fromRGB(80, 230, 180))
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if root then
			explosao(root.Position, Color3.fromRGB(80, 230, 180), 18)
		end
	elseif tipo == "completo" then
		mostrarFaixa(string.upper(a) .. " COMPLETO!", Color3.fromRGB(255, 225, 120), 3)
	elseif tipo == "lendario" then
		mostrarFaixa(a .. " achou um item LENDÁRIO: " .. b .. "!", Color3.fromRGB(255, 160, 40), 3.5)
	elseif tipo == "avatar" then
		local r = raridade(b)
		local cor = r.corBorda or r.cor
		mostrarFaixa("🎭 AVATAR OBTIDO! " .. a .. " (" .. r.nome .. ")", cor, 3.5)
		notificar("🎭 Novo avatar: " .. a .. " — veja no menu Avatar", cor)
		tremer(1.4, 0.6)
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if root then
			explosao(root.Position, cor, 40)
		end
	elseif tipo == "classeErrada" then
		notificar("✖ " .. a .. " é só para " .. b .. " (use na síntese)", Color3.fromRGB(255, 110, 110))
	elseif tipo == "avatarRepetido" then
		notificar("🎭 Avatar repetido (" .. a .. ") virou +" .. b .. " ouro", Color3.fromRGB(255, 205, 70))
	elseif tipo == "bauEstagio" then
		notificar(
			"📦 Baú de tesouro de estágio " .. b .. " obtido! +" .. a .. " ouro",
			Color3.fromRGB(255, 210, 90)
		)
		mostrarFaixa("📦 BAÚ DE ESTÁGIO! +" .. a .. " OURO", Color3.fromRGB(255, 210, 90), 1.6)
	elseif tipo == "equipouRaro" then
		local r = raridade(b)
		local cor = r.corBorda or r.cor
		mostrarFaixa(string.upper(r.nome) .. " EQUIPADO!\n" .. a, cor, 2.4)
		tremer(1, 0.4)
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if root then
			-- coluna de luz + anel no chão
			local pilar = Instance.new("Part")
			pilar.Anchored = true
			pilar.CanCollide = false
			pilar.CanQuery = false
			pilar.Material = Enum.Material.Neon
			pilar.Color = cor
			pilar.Shape = Enum.PartType.Cylinder
			pilar.Size = Vector3.new(60, 6, 6)
			pilar.CFrame = CFrame.new(root.Position + Vector3.new(0, 27, 0)) * CFrame.Angles(0, 0, math.rad(90))
			pilar.Transparency = 0.2
			pilar.Parent = workspace
			TweenService:Create(pilar, TweenInfo.new(1.2), { Size = Vector3.new(60, 0.3, 0.3), Transparency = 1 })
				:Play()
			Debris:AddItem(pilar, 1.3)
			local anel = Instance.new("Part")
			anel.Anchored = true
			anel.CanCollide = false
			anel.CanQuery = false
			anel.Material = Enum.Material.Neon
			anel.Color = cor
			anel.Shape = Enum.PartType.Cylinder
			anel.Size = Vector3.new(0.2, 2, 2)
			anel.CFrame = CFrame.new(root.Position - Vector3.new(0, 2.8, 0)) * CFrame.Angles(0, 0, math.rad(90))
			anel.Transparency = 0.1
			anel.Parent = workspace
			TweenService:Create(anel, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = Vector3.new(0.2, 26, 26),
				Transparency = 1,
			}):Play()
			Debris:AddItem(anel, 0.9)
			explosao(root.Position, cor, 30)
		end
	elseif tipo == "repetir" then
		notificar("🔁 Fase " .. a .. " de novo (repetindo)", Color3.fromRGB(150, 230, 160))
	elseif tipo == "habilidade" then
		mostrarFaixa(string.upper(a), Color3.fromRGB(200, 120, 255), 1.4)
	elseif tipo == "empurrao" then
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if root and typeof(a) == "Vector3" then
			root.AssemblyLinearVelocity = a * (b or 80) + Vector3.new(0, 35, 0)
			tremer(1.4, 0.4)
		end
	elseif tipo == "derrota" then
		morto = true
		local msg = a == "tempo" and "O TEMPO ACABOU!" or "VOCÊ FOI DERROTADO!"
		local sub = b and "Voltando uma fase..." or "Recomeçando a fase..."
		mostrarFaixa(msg .. "\n" .. sub, Color3.fromRGB(255, 80, 80), 2.4)
		piscarTela(0.5)
		task.delay(2.6, function()
			morto = false
		end)
	elseif tipo == "chefe" then
		mostrarFaixa("CHEFE: " .. string.upper(a) .. "!", Color3.fromRGB(210, 120, 255), 3)
		tremer(1.2, 0.6)
	elseif tipo == "forjaAuto" then
		if a > 0 then
			notificar("⚒ Forja automática: " .. a .. " combinação(ões)", Color3.fromRGB(255, 170, 80))
		else
			notificar("⚒ Nada para combinar agora", Color3.fromRGB(180, 175, 200))
		end
	elseif tipo == "alquimia" then
		notificar("🪙 Alquimia: +" .. a .. " ouro", Color3.fromRGB(255, 205, 70))
		mostrarFaixa("+" .. a .. " OURO!", Color3.fromRGB(255, 210, 80), 1.2)
	elseif tipo == "bau" then
		notificar("Baú do chefe: +" .. a .. " ouro", Color3.fromRGB(255, 205, 70))
	end
end)

------------------------------------------------------------------------
-- Auto-farm: o herói anda sozinho até o monstro mais perto
------------------------------------------------------------------------
local alcance = Config.Heroi.Alcance
local estavaLigado = true

task.spawn(function()
	while true do
		task.wait(0.2)
		local ligado = player:GetAttribute("AutoFarm") ~= false and not morto
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if hum and root and hum.Health > 0 then
			if ligado then
				local alvo, menor = nil, math.huge
				for _, m in ipairs(pasta:GetChildren()) do
					if
						m:GetAttribute("Dono") == player.UserId
						and (m:GetAttribute("Vida") or 0) > 0
						and m.PrimaryPart
					then
						local d = (m.PrimaryPart.Position - root.Position).Magnitude
						if d < menor then
							alvo, menor = m, d
						end
					end
				end
				if alvo then
					local pos = alvo.PrimaryPart.Position
					local plano = Vector3.new(pos.X, root.Position.Y, pos.Z)
					local alcClasse = player:GetAttribute("Alcance") or alcance -- muda com a classe
					local alc = alvo:GetAttribute("Chefe") and math.max(alcClasse, Config.Heroi.AlcanceChefe)
						or alcClasse
					if (plano - root.Position).Magnitude > alc - 2.5 then
						hum:MoveTo(plano)
					else
						hum:MoveTo(root.Position)
						root.CFrame = CFrame.lookAt(root.Position, plano)
					end
				end
			elseif estavaLigado then
				hum:MoveTo(root.Position) -- acabou de desligar: para de andar
			end
		end
		estavaLigado = ligado
	end
end)
