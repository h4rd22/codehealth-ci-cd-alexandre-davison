-- GameServer: monstros, combate automático, ouro e troca de fase.
-- Versão de TESTE: fases 1-1, 1-2 e 1-3.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))

-- Canais de comunicação com a tela do jogador
local remotes = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = ReplicatedStorage

local function remote(nome)
	local r = remotes:FindFirstChild(nome) or Instance.new("RemoteEvent")
	r.Name = nome
	r.Parent = remotes
	return r
end
local evDano = remote("Dano")       -- números de dano, morte de monstro
local evFase = remote("Fase")       -- aviso de fase nova
local evAuto = remote("AutoFarm")   -- botão liga/desliga

local pasta = workspace:FindFirstChild("Monstros") or Instance.new("Folder")
pasta.Name = "Monstros"
pasta.Parent = workspace

local baseplate = workspace:FindFirstChild("Baseplate")
local alturaChao = baseplate and (baseplate.Position.Y + baseplate.Size.Y / 2) or 0

local estado = {} -- estado[player] = {fase, kills}

------------------------------------------------------------------------
-- Monstros
------------------------------------------------------------------------
local function parte(modelo, props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CastShadow = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do
		p[k] = v
	end
	p.Parent = modelo
	return p
end

local function criarMonstro(player, indiceFase)
	local f = Config.Fases[indiceFase]
	local s = f.tamanho
	local ang = math.random() * math.pi * 2
	local raio = 14 + math.random() * (Config.RaioArena - 14)
	local base = Vector3.new(math.cos(ang) * raio, alturaChao, math.sin(ang) * raio)

	local m = Instance.new("Model")
	m.Name = f.monstro

	local corpo
	if f.forma == "bola" then
		corpo = parte(m, {Name = "Corpo", Shape = Enum.PartType.Ball, Size = Vector3.new(s, s, s),
			Color = f.cor, Material = Enum.Material.SmoothPlastic, Transparency = 0.1,
			CFrame = CFrame.new(base + Vector3.new(0, s / 2, 0))})
	elseif f.forma == "cogumelo" then
		corpo = parte(m, {Name = "Corpo", Size = Vector3.new(s * 0.5, s * 0.6, s * 0.5),
			Color = Color3.fromRGB(235, 225, 200), Material = Enum.Material.SmoothPlastic,
			CFrame = CFrame.new(base + Vector3.new(0, s * 0.3, 0))})
		local chapeu = parte(m, {Name = "Chapeu", Shape = Enum.PartType.Ball, Size = Vector3.new(s * 1.2, s * 0.7, s * 1.2),
			Color = f.cor, Material = Enum.Material.SmoothPlastic,
			CFrame = CFrame.new(base + Vector3.new(0, s * 0.75, 0))})
		chapeu:SetAttribute("CorOriginal", f.cor)
	else
		corpo = parte(m, {Name = "Corpo", Size = Vector3.new(s * 1.3, s * 0.8, s * 0.8),
			Color = f.cor, Material = Enum.Material.Slate,
			CFrame = CFrame.new(base + Vector3.new(0, s * 0.4, 0))})
		parte(m, {Name = "Cabeca", Size = Vector3.new(s * 0.6, s * 0.6, s * 0.6),
			Color = f.cor, Material = Enum.Material.Slate,
			CFrame = CFrame.new(base + Vector3.new(s * 0.75, s * 0.75, 0))})
	end
	corpo:SetAttribute("CorOriginal", corpo.Color)

	-- Olhos
	local olhoY = corpo.Position.Y + s * 0.15
	for _, lado in ipairs({-1, 1}) do
		parte(m, {Name = "Olho", Shape = Enum.PartType.Ball, Size = Vector3.new(s * 0.18, s * 0.18, s * 0.18),
			Color = Color3.fromRGB(20, 20, 25), Material = Enum.Material.Neon,
			CFrame = CFrame.new(corpo.Position.X + lado * s * 0.2, olhoY, corpo.Position.Z + s * 0.42)})
	end

	m.PrimaryPart = corpo
	m:SetAttribute("Dono", player.UserId)
	m:SetAttribute("Vida", f.vida)
	m:SetAttribute("VidaMax", f.vida)
	m:SetAttribute("Ouro", f.ouro)

	-- Barra de vida e nome
	local bb = Instance.new("BillboardGui")
	bb.Name = "Barra"
	bb.Size = UDim2.fromOffset(110, 30)
	bb.StudsOffsetWorldSpace = Vector3.new(0, s * 1.1 + 1, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 120
	bb.Adornee = corpo
	bb.Parent = m

	local nome = Instance.new("TextLabel")
	nome.Size = UDim2.new(1, 0, 0, 14)
	nome.BackgroundTransparency = 1
	nome.Text = f.monstro
	nome.TextColor3 = Color3.new(1, 1, 1)
	nome.TextStrokeTransparency = 0.4
	nome.Font = Enum.Font.GothamBold
	nome.TextSize = 12
	nome.Parent = bb

	local fundo = Instance.new("Frame")
	fundo.Name = "Fundo"
	fundo.Position = UDim2.new(0, 0, 0, 17)
	fundo.Size = UDim2.new(1, 0, 0, 8)
	fundo.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
	fundo.BorderSizePixel = 0
	fundo.Parent = bb
	Instance.new("UICorner", fundo).CornerRadius = UDim.new(1, 0)

	local barra = Instance.new("Frame")
	barra.Name = "Vida"
	barra.Size = UDim2.new(1, 0, 1, 0)
	barra.BackgroundColor3 = Color3.fromRGB(235, 70, 70)
	barra.BorderSizePixel = 0
	barra.Parent = fundo
	Instance.new("UICorner", barra).CornerRadius = UDim.new(1, 0)

	m.Parent = pasta

	-- Aparece crescendo
	for _, p in ipairs(m:GetChildren()) do
		if p:IsA("BasePart") then
			local tam = p.Size
			p.Size = tam * 0.1
			TweenService:Create(p, TweenInfo.new(0.35, Enum.EasingStyle.Back), {Size = tam}):Play()
		end
	end
	return m
end

local function monstrosDe(player)
	local lista = {}
	for _, m in ipairs(pasta:GetChildren()) do
		if m:GetAttribute("Dono") == player.UserId and (m:GetAttribute("Vida") or 0) > 0 then
			table.insert(lista, m)
		end
	end
	return lista
end

local function limparMonstros(player)
	for _, m in ipairs(pasta:GetChildren()) do
		if m:GetAttribute("Dono") == player.UserId then
			m:Destroy()
		end
	end
end

local function completarMonstros(player)
	local st = estado[player]
	if not st then return end
	local faltam = Config.MonstrosVivos - #monstrosDe(player)
	for _ = 1, faltam do
		criarMonstro(player, st.fase)
	end
end

------------------------------------------------------------------------
-- Fases
------------------------------------------------------------------------
local function aplicarFase(player)
	local st = estado[player]
	local f = Config.Fases[st.fase]
	player:SetAttribute("Fase", f.nome)
	player:SetAttribute("Monstro", f.monstro)
	player:SetAttribute("Kills", st.kills)
	player:SetAttribute("Meta", Config.MonstrosPorFase)
	local ls = player:FindFirstChild("leaderstats")
	if ls then ls.Fase.Value = f.nome end
	if baseplate then
		TweenService:Create(baseplate, TweenInfo.new(1), {Color = f.chao}):Play()
	end
	limparMonstros(player)
	completarMonstros(player)
end

local function monstroMorreu(player, m)
	local st = estado[player]
	if not st then return end
	local ouro = m:GetAttribute("Ouro") or 0
	local pos = m.PrimaryPart and m.PrimaryPart.Position or Vector3.zero
	local cor = m.PrimaryPart and m.PrimaryPart:GetAttribute("CorOriginal") or Color3.new(1, 1, 1)
	m:SetAttribute("Vida", 0)

	evDano:FireClient(player, "morte", pos, ouro, cor)

	-- Some encolhendo
	for _, p in ipairs(m:GetChildren()) do
		if p:IsA("BasePart") then
			TweenService:Create(p, TweenInfo.new(0.2), {Size = p.Size * 0.05, Transparency = 1}):Play()
		end
	end
	task.delay(0.25, function() m:Destroy() end)

	local ls = player:FindFirstChild("leaderstats")
	if ls then ls.Ouro.Value += ouro end
	player:SetAttribute("Ouro", ls and ls.Ouro.Value or 0)

	st.kills += 1
	player:SetAttribute("Kills", st.kills)

	if st.kills >= Config.MonstrosPorFase then
		if st.fase < #Config.Fases then
			st.fase += 1
			st.kills = 0
			task.wait(0.4)
			aplicarFase(player)
			local f = Config.Fases[st.fase]
			evFase:FireClient(player, "nova", f.nome, f.monstro)
		else
			-- Passou da última fase do teste: avisa e continua farmando a 1-3
			st.kills = 0
			player:SetAttribute("Kills", 0)
			evFase:FireClient(player, "completo", Config.Fases[st.fase].nome)
			task.delay(0.3, completarMonstros, player)
		end
	else
		task.delay(0.6, completarMonstros, player)
	end
end

------------------------------------------------------------------------
-- Combate: o herói bate sozinho em qualquer monstro dentro do alcance
------------------------------------------------------------------------
local function piscar(m)
	for _, p in ipairs(m:GetChildren()) do
		if p:IsA("BasePart") and p:GetAttribute("CorOriginal") then
			p.Color = Color3.new(1, 1, 1)
			task.delay(0.08, function()
				if p.Parent then p.Color = p:GetAttribute("CorOriginal") end
			end)
		end
	end
end

local function golpe(player, root)
	local alvo, menor = nil, Config.Heroi.Alcance
	for _, m in ipairs(monstrosDe(player)) do
		if m.PrimaryPart then
			local d = (m.PrimaryPart.Position - root.Position) * Vector3.new(1, 0, 1)
			if d.Magnitude <= menor then
				alvo, menor = m, d.Magnitude
			end
		end
	end
	if not alvo then return end

	local h = Config.Heroi
	local dano = h.Dano * (1 + (math.random() * 2 - 1) * h.Variacao)
	local critico = math.random() < h.ChanceCritico
	if critico then dano *= h.MultCritico end
	dano = math.max(1, math.floor(dano + 0.5))

	local vida = math.max(0, alvo:GetAttribute("Vida") - dano)
	alvo:SetAttribute("Vida", vida)
	local barra = alvo:FindFirstChild("Barra")
	if barra then
		local v = barra.Fundo.Vida
		TweenService:Create(v, TweenInfo.new(0.12), {Size = UDim2.new(vida / alvo:GetAttribute("VidaMax"), 0, 1, 0)}):Play()
	end
	piscar(alvo)
	evDano:FireClient(player, "dano", alvo.PrimaryPart.Position, dano, critico)

	if vida <= 0 then
		monstroMorreu(player, alvo)
	end
end

local function loopCombate(player)
	while player.Parent and estado[player] do
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if hum and root and hum.Health > 0 then
			golpe(player, root)
		end
		task.wait(Config.Heroi.Intervalo)
	end
end

------------------------------------------------------------------------
-- Jogadores
------------------------------------------------------------------------
Players.PlayerAdded:Connect(function(player)
	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	local ouro = Instance.new("IntValue")
	ouro.Name = "Ouro"
	ouro.Parent = ls
	local fase = Instance.new("StringValue")
	fase.Name = "Fase"
	fase.Parent = ls
	ls.Parent = player

	estado[player] = {fase = 1, kills = 0}
	player:SetAttribute("Ouro", 0)
	player:SetAttribute("AutoFarm", true)

	if not player.Character then player.CharacterAdded:Wait() end
	aplicarFase(player)
	task.spawn(loopCombate, player)
end)

Players.PlayerRemoving:Connect(function(player)
	limparMonstros(player)
	estado[player] = nil
end)

evAuto.OnServerEvent:Connect(function(player, ligado)
	player:SetAttribute("AutoFarm", ligado == true)
end)
