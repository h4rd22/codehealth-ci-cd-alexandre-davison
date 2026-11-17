-- GameClient: tela do jogador, auto-farm (herói anda sozinho) e efeitos.
-- Versão de TESTE: fases 1-1, 1-2 e 1-3.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local evDano = remotes:WaitForChild("Dano")
local evFase = remotes:WaitForChild("Fase")
local evAuto = remotes:WaitForChild("AutoFarm")

local player = Players.LocalPlayer
local pasta = workspace:WaitForChild("Monstros")
local autoFarm = true

------------------------------------------------------------------------
-- Tela
------------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "Tela"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

-- Esconde o placar padrão do Roblox (o ouro já aparece na nossa tela)
pcall(function()
	game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
end)

local function canto(obj, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 10)
	c.Parent = obj
end

local function texto(pai, props)
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Font = Enum.Font.GothamBold
	t.TextColor3 = Color3.new(1, 1, 1)
	for k, v in pairs(props) do t[k] = v end
	t.Parent = pai
	return t
end

-- Painel da fase (topo)
local topo = Instance.new("Frame")
topo.AnchorPoint = Vector2.new(0.5, 0)
topo.Position = UDim2.new(0.5, 0, 0, 64)
topo.Size = UDim2.new(1, -32, 0, 64)
local limiteTopo = Instance.new("UISizeConstraint")
limiteTopo.MaxSize = Vector2.new(340, 64)
limiteTopo.Parent = topo
topo.BackgroundColor3 = Color3.fromRGB(20, 18, 30)
topo.BackgroundTransparency = 0.15
topo.Parent = gui
canto(topo, 12)
local borda = Instance.new("UIStroke")
borda.Color = Color3.fromRGB(150, 120, 255)
borda.Thickness = 2
borda.Parent = topo

local lblFase = texto(topo, {Position = UDim2.fromOffset(14, 8), Size = UDim2.new(1, -28, 0, 22),
	TextSize = 20, TextXAlignment = Enum.TextXAlignment.Left, Text = "Fase 1-1"})
local lblMonstro = texto(topo, {Position = UDim2.fromOffset(14, 8), Size = UDim2.new(1, -28, 0, 22),
	TextSize = 14, TextXAlignment = Enum.TextXAlignment.Right, Font = Enum.Font.Gotham,
	TextColor3 = Color3.fromRGB(200, 195, 230), Text = ""})

local fundoBarra = Instance.new("Frame")
fundoBarra.Position = UDim2.fromOffset(14, 36)
fundoBarra.Size = UDim2.new(1, -28, 0, 18)
fundoBarra.BackgroundColor3 = Color3.fromRGB(45, 40, 65)
fundoBarra.BorderSizePixel = 0
fundoBarra.Parent = topo
canto(fundoBarra, 9)
local barra = Instance.new("Frame")
barra.Size = UDim2.new(0, 0, 1, 0)
barra.BackgroundColor3 = Color3.fromRGB(150, 120, 255)
barra.BorderSizePixel = 0
barra.Parent = fundoBarra
canto(barra, 9)
local lblKills = texto(fundoBarra, {Size = UDim2.fromScale(1, 1), TextSize = 13, Text = "0 / 10", ZIndex = 2})

-- Ouro (logo abaixo do painel da fase)
local caixaOuro = Instance.new("Frame")
caixaOuro.AnchorPoint = Vector2.new(0.5, 0)
caixaOuro.Position = UDim2.new(0.5, 0, 0, 136)
caixaOuro.Size = UDim2.fromOffset(140, 40)
caixaOuro.BackgroundColor3 = Color3.fromRGB(20, 18, 30)
caixaOuro.BackgroundTransparency = 0.15
caixaOuro.Parent = gui
canto(caixaOuro, 12)
local moeda = Instance.new("Frame")
moeda.Position = UDim2.fromOffset(10, 10)
moeda.Size = UDim2.fromOffset(20, 20)
moeda.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
moeda.Parent = caixaOuro
canto(moeda, 10)
local lblOuro = texto(caixaOuro, {Position = UDim2.fromOffset(38, 0), Size = UDim2.new(1, -44, 1, 0),
	TextSize = 20, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(255, 215, 90), Text = "0"})

-- Botão de auto-farm (embaixo)
local botao = Instance.new("TextButton")
botao.AnchorPoint = Vector2.new(0.5, 1)
botao.Position = UDim2.new(0.5, 0, 1, -24)
botao.Size = UDim2.fromOffset(230, 52)
botao.Font = Enum.Font.GothamBlack
botao.TextSize = 18
botao.TextColor3 = Color3.new(1, 1, 1)
botao.AutoButtonColor = true
botao.Parent = gui
canto(botao, 14)

local function atualizarBotao()
	botao.Text = autoFarm and "AUTO-FARM: LIGADO" or "AUTO-FARM: DESLIGADO"
	botao.BackgroundColor3 = autoFarm and Color3.fromRGB(60, 185, 95) or Color3.fromRGB(95, 95, 105)
end
atualizarBotao()

-- Faixa de aviso (centro)
local faixa = texto(gui, {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.4),
	Size = UDim2.new(0.92, 0, 0, 90), TextScaled = true, TextWrapped = true, Font = Enum.Font.GothamBlack,
	TextColor3 = Color3.fromRGB(255, 225, 120), TextStrokeTransparency = 0, TextTransparency = 1,
	TextStrokeColor3 = Color3.fromRGB(80, 40, 140), Text = ""})
local limiteTexto = Instance.new("UITextSizeConstraint")
limiteTexto.MaxTextSize = 46
limiteTexto.Parent = faixa
local escalaFaixa = Instance.new("UIScale")
escalaFaixa.Parent = faixa

local function mostrarFaixa(msg)
	faixa.Text = msg
	faixa.TextTransparency = 1
	faixa.TextStrokeTransparency = 1
	escalaFaixa.Scale = 0.6
	TweenService:Create(escalaFaixa, TweenInfo.new(0.35, Enum.EasingStyle.Back), {Scale = 1}):Play()
	TweenService:Create(faixa, TweenInfo.new(0.35),
		{TextTransparency = 0, TextStrokeTransparency = 0}):Play()
	task.delay(2.2, function()
		if faixa.Text == msg then
			TweenService:Create(faixa, TweenInfo.new(0.5), {TextTransparency = 1, TextStrokeTransparency = 1}):Play()
		end
	end)
end

------------------------------------------------------------------------
-- Atualiza a tela com o que o servidor manda
------------------------------------------------------------------------
local function atualizarFase()
	local fase = player:GetAttribute("Fase") or "1-1"
	local kills = player:GetAttribute("Kills") or 0
	local meta = player:GetAttribute("Meta") or Config.MonstrosPorFase
	lblFase.Text = "Fase " .. fase
	lblMonstro.Text = player:GetAttribute("Monstro") or ""
	lblKills.Text = kills .. " / " .. meta
	TweenService:Create(barra, TweenInfo.new(0.2), {Size = UDim2.new(math.clamp(kills / meta, 0, 1), 0, 1, 0)}):Play()
end
local function atualizarOuro()
	lblOuro.Text = tostring(player:GetAttribute("Ouro") or 0)
end
for _, a in ipairs({"Fase", "Kills", "Meta", "Monstro"}) do
	player:GetAttributeChangedSignal(a):Connect(atualizarFase)
end
player:GetAttributeChangedSignal("Ouro"):Connect(function()
	atualizarOuro()
	moeda.Size = UDim2.fromOffset(26, 26)
	moeda.Position = UDim2.fromOffset(7, 7)
	TweenService:Create(moeda, TweenInfo.new(0.2), {Size = UDim2.fromOffset(20, 20), Position = UDim2.fromOffset(10, 10)}):Play()
end)
atualizarFase()
atualizarOuro()

botao.Activated:Connect(function()
	autoFarm = not autoFarm
	atualizarBotao()
	evAuto:FireServer(autoFarm)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not autoFarm and hum and root then
		hum:MoveTo(root.Position) -- para de andar
	end
end)

------------------------------------------------------------------------
-- Efeitos: números de dano, tremida de tela, explosão ao morrer
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
	bb.Size = UDim2.fromOffset(200, 60)
	bb.AlwaysOnTop = true
	bb.Adornee = ancora
	bb.Parent = ancora
	local t = texto(bb, {Size = UDim2.fromScale(1, 1), Text = msg, TextColor3 = cor, TextSize = tamanho,
		Font = Enum.Font.GothamBlack, TextStrokeTransparency = 0, TextStrokeColor3 = Color3.fromRGB(30, 20, 40)})

	TweenService:Create(ancora, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Position = ancora.Position + Vector3.new(0, 3, 0)}):Play()
	TweenService:Create(t, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0.35),
		{TextTransparency = 1, TextStrokeTransparency = 1}):Play()
	Debris:AddItem(ancora, 0.9)
end

local function tremer(forca, duracao)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	task.spawn(function()
		local fim = os.clock() + duracao
		while os.clock() < fim do
			hum.CameraOffset = Vector3.new((math.random() - 0.5) * forca, (math.random() - 0.5) * forca, 0)
			task.wait()
		end
		hum.CameraOffset = Vector3.zero
	end)
end

local function explosao(pos, cor)
	for _ = 1, 10 do
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
		TweenService:Create(p, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{Position = pos + dir * (4 + math.random() * 3), Size = Vector3.new(0.05, 0.05, 0.05), Transparency = 1}):Play()
		Debris:AddItem(p, 0.5)
	end
end

evDano.OnClientEvent:Connect(function(tipo, pos, valor, extra)
	if tipo == "dano" then
		if extra then
			textoFlutuante(pos, "CRÍTICO! " .. valor, Color3.fromRGB(255, 220, 60), 34)
			tremer(0.6, 0.15)
		else
			textoFlutuante(pos, tostring(valor), Color3.new(1, 1, 1), 24)
		end
	elseif tipo == "morte" then
		explosao(pos, extra)
		textoFlutuante(pos + Vector3.new(0, 1, 0), "+" .. valor .. " ouro", Color3.fromRGB(255, 205, 70), 22)
	end
end)

evFase.OnClientEvent:Connect(function(tipo, nome)
	if tipo == "nova" then
		mostrarFaixa("FASE " .. nome .. "!")
		tremer(0.8, 0.3)
	elseif tipo == "completo" then
		mostrarFaixa("TESTE COMPLETO! Você passou da " .. nome)
	end
end)

------------------------------------------------------------------------
-- Auto-farm: o herói anda sozinho até o monstro mais perto
------------------------------------------------------------------------
local alcance = Config.Heroi.Alcance

task.spawn(function()
	while true do
		task.wait(0.2)
		if autoFarm then
			local char = player.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			local root = char and char:FindFirstChild("HumanoidRootPart")
			if hum and root and hum.Health > 0 then
				local alvo, menor = nil, math.huge
				for _, m in ipairs(pasta:GetChildren()) do
					if m:GetAttribute("Dono") == player.UserId and (m:GetAttribute("Vida") or 0) > 0 and m.PrimaryPart then
						local d = (m.PrimaryPart.Position - root.Position).Magnitude
						if d < menor then alvo, menor = m, d end
					end
				end
				if alvo then
					local pos = alvo.PrimaryPart.Position
					local plano = Vector3.new(pos.X, root.Position.Y, pos.Z)
					if (plano - root.Position).Magnitude > alcance - 2.5 then
						hum:MoveTo(plano)
					else
						hum:MoveTo(root.Position)
						root.CFrame = CFrame.lookAt(root.Position, plano)
					end
				end
			end
		end
	end
end)
