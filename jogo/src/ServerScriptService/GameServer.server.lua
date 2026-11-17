-- GameServer: arena, monstros, combate automático, XP, ouro, loot,
-- inventário, equipamentos, forja e portal de fases.
-- Versão de TESTE: mundo 1, fases 1-1 a 1-3. (Ainda não salva o progresso.)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))

------------------------------------------------------------------------
-- Comunicação com a tela do jogador
------------------------------------------------------------------------
local remotes = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = ReplicatedStorage
local function remote(nome)
	local r = remotes:FindFirstChild(nome) or Instance.new("RemoteEvent")
	r.Name = nome
	r.Parent = remotes
	return r
end
local evEstado = remote("Estado")         -- servidor -> tela: tudo do jogador
local evPedirEstado = remote("PedirEstado")
local evDano = remote("Dano")             -- números de dano e morte de monstro
local evAviso = remote("Aviso")           -- faixas: fase nova, nível novo, lendário
local evLoot = remote("Loot")             -- item caiu / forja
local evAutoFarm = remote("AutoFarm")
local evEquipar = remote("Equipar")
local evDesequipar = remote("Desequipar")
local evVender = remote("Vender")
local evForjar = remote("Forjar")
local evIrFase = remote("IrFase")

------------------------------------------------------------------------
-- Arena pequena
------------------------------------------------------------------------
local baseplate = workspace:FindFirstChild("Baseplate")
if baseplate then
	baseplate.Size = Vector3.new(140, baseplate.Size.Y, 140)
	baseplate.Color = Color3.fromRGB(28, 26, 38)
	baseplate.Material = Enum.Material.Slate
end
local alturaChao = baseplate and (baseplate.Position.Y + baseplate.Size.Y / 2) or 0

local spawn = workspace:FindFirstChildOfClass("SpawnLocation")
if spawn then
	spawn.Transparency = 1
	spawn.CanCollide = false
	for _, d in ipairs(spawn:GetChildren()) do
		if d:IsA("Decal") then d:Destroy() end
	end
end

local arena = workspace:FindFirstChild("Arena")
if arena then arena:Destroy() end
arena = Instance.new("Model")
arena.Name = "Arena"
arena.Parent = workspace

local chao = Instance.new("Part")
chao.Name = "Chao"
chao.Shape = Enum.PartType.Cylinder
chao.Anchored = true
chao.Size = Vector3.new(1, Config.RaioArena * 2, Config.RaioArena * 2)
chao.CFrame = CFrame.new(0, alturaChao + 0.5, 0) * CFrame.Angles(0, 0, math.rad(90))
chao.Material = Enum.Material.Grass
chao.TopSurface = Enum.SurfaceType.Smooth
chao.Parent = arena

local borda = {}
local nPedras = 26
for i = 1, nPedras do
	local a = (i / nPedras) * math.pi * 2
	local r = Config.RaioArena + 1
	local h = 1.2 + (i % 3) * 0.7
	local pedra = Instance.new("Part")
	pedra.Anchored = true
	pedra.Size = Vector3.new(2.2 + (i % 2), h, 2.4)
	pedra.CFrame = CFrame.new(math.cos(a) * r, alturaChao + 0.6 + h / 2, math.sin(a) * r)
		* CFrame.Angles(math.rad((i * 37) % 20 - 10), a + (i % 2) * 0.6, math.rad((i * 53) % 24 - 12))
	pedra.Material = Enum.Material.Rock
	pedra.Parent = arena
	table.insert(borda, pedra)
end

local function pintarArena(f)
	TweenService:Create(chao, TweenInfo.new(1), {Color = f.chao}):Play()
	for _, p in ipairs(borda) do
		TweenService:Create(p, TweenInfo.new(1), {Color = f.chao:Lerp(Color3.new(0, 0, 0), 0.45)}):Play()
	end
end

local topoArena = alturaChao + 1

local pasta = workspace:FindFirstChild("Monstros") or Instance.new("Folder")
pasta.Name = "Monstros"
pasta.Parent = workspace

------------------------------------------------------------------------
-- Estado dos jogadores
------------------------------------------------------------------------
local estado = {} -- estado[player] = {...}

local function raridadePorId(id)
	for i, r in ipairs(Config.Raridades) do
		if r.id == id then return r, i end
	end
end
local function slotPorId(id)
	for _, s in ipairs(Config.Slots) do
		if s.id == id then return s end
	end
end

local function calcularStats(st)
	local h = Config.Heroi
	local s = {
		dano = h.Dano + (st.nivel - 1) * h.DanoPorNivel,
		critico = h.ChanceCritico,
		ouro = 1,
		velocidade = h.Velocidade,
	}
	for slotId, itemId in pairs(st.equipado) do
		local item = st.itens[itemId]
		local slot = slotPorId(slotId)
		if item and slot then
			if slot.atributo == "dano" then s.dano += item.valor
			elseif slot.atributo == "critico" then s.critico += item.valor
			elseif slot.atributo == "ouro" then s.ouro += item.valor
			elseif slot.atributo == "velocidade" then s.velocidade += item.valor
			end
		end
	end
	return s
end

local function enviarEstado(player)
	local st = estado[player]
	if not st then return end
	local lista = {}
	for _, item in pairs(st.itens) do
		table.insert(lista, item)
	end
	table.sort(lista, function(a, b) return a.id > b.id end)
	evEstado:FireClient(player, {
		nivel = st.nivel,
		xp = st.xp,
		xpProx = Config.XPParaNivel(st.nivel),
		ouro = st.ouro,
		faseIdx = st.fase,
		faseMax = st.faseMax,
		kills = st.kills,
		meta = Config.MonstrosPorFase,
		inventario = lista,
		equipado = st.equipado,
		stats = calcularStats(st),
		autoFarm = st.autoFarm,
	})
end

------------------------------------------------------------------------
-- Equipamento visível no personagem
------------------------------------------------------------------------
local function pecaDoCorpo(char, r15, r6)
	return char:FindFirstChild(r15) or char:FindFirstChild(r6)
end

local function grudar(char, pasta, base, tamanho, offset, cor, material, brilho)
	local p = Instance.new("Part")
	p.Size = tamanho
	p.Color = cor
	p.Material = material
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.CFrame = base.CFrame * offset
	local w = Instance.new("WeldConstraint")
	w.Part0 = base
	w.Part1 = p
	w.Parent = p
	if brilho then
		local luz = Instance.new("PointLight")
		luz.Color = cor
		luz.Range = 6
		luz.Brightness = 1.5
		luz.Parent = p
		local fx = Instance.new("ParticleEmitter")
		fx.Color = ColorSequence.new(cor)
		fx.LightEmission = 1
		fx.Size = NumberSequence.new(0.25, 0)
		fx.Lifetime = NumberRange.new(0.4, 0.8)
		fx.Rate = 8
		fx.Speed = NumberRange.new(0.5, 1.5)
		fx.Parent = p
	end
	p.Parent = pasta
	return p
end

local function vestir(player)
	local st = estado[player]
	local char = player.Character
	if not st or not char then return end
	local velha = char:FindFirstChild("Equipamento")
	if velha then velha:Destroy() end
	local pastaEq = Instance.new("Folder")
	pastaEq.Name = "Equipamento"
	pastaEq.Parent = char

	for slotId, itemId in pairs(st.equipado) do
		local item = st.itens[itemId]
		if item then
			local rar, ri = raridadePorId(item.raridade)
			local cor = rar.cor
			local brilho = ri >= 4
			if slotId == "arma" then
				local mao = pecaDoCorpo(char, "RightHand", "Right Arm")
				if mao then
					local desce = mao.Name == "Right Arm" and -1 or -0.2
					grudar(char, pastaEq, mao, Vector3.new(0.35, 0.35, 1.2), CFrame.new(0, desce, -0.3), Color3.fromRGB(90, 60, 40), Enum.Material.Wood, false)
					grudar(char, pastaEq, mao, Vector3.new(1.4, 0.25, 0.3), CFrame.new(0, desce, -0.95), Color3.fromRGB(70, 70, 80), Enum.Material.Metal, false)
					grudar(char, pastaEq, mao, Vector3.new(0.3, 0.15, 3.4), CFrame.new(0, desce, -2.7), cor, ri >= 3 and Enum.Material.Neon or Enum.Material.Metal, brilho)
				end
			elseif slotId == "elmo" then
				local cabeca = char:FindFirstChild("Head")
				if cabeca then
					local s = cabeca.Size
					grudar(char, pastaEq, cabeca, Vector3.new(s.X * 1.15, s.Y * 0.55, s.Z * 1.15), CFrame.new(0, s.Y * 0.32, 0), cor, Enum.Material.Metal, brilho)
				end
			elseif slotId == "armadura" then
				local tronco = pecaDoCorpo(char, "UpperTorso", "Torso")
				if tronco then
					local s = tronco.Size
					grudar(char, pastaEq, tronco, Vector3.new(s.X * 1.1, s.Y * 0.9, s.Z * 1.25), CFrame.new(0, s.Y * 0.04, 0), cor, Enum.Material.Metal, brilho)
				end
			elseif slotId == "botas" then
				for _, nomes in ipairs({{"LeftFoot", "Left Leg"}, {"RightFoot", "Right Leg"}}) do
					local pe = pecaDoCorpo(char, nomes[1], nomes[2])
					if pe then
						local s = pe.Size
						if pe.Name:find("Foot") then
							grudar(char, pastaEq, pe, s * Vector3.new(1.2, 1.4, 1.15), CFrame.new(0, s.Y * 0.15, 0), cor, Enum.Material.Metal, brilho)
						else
							grudar(char, pastaEq, pe, Vector3.new(s.X * 1.15, s.Y * 0.35, s.Z * 1.15), CFrame.new(0, -s.Y * 0.33, 0), cor, Enum.Material.Metal, brilho)
						end
					end
				end
			end
		end
	end

	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then hum.WalkSpeed = calcularStats(st).velocidade end
end

------------------------------------------------------------------------
-- Itens
------------------------------------------------------------------------
local function sortearRaridade()
	local total = 0
	for _, r in ipairs(Config.Raridades) do total += r.peso end
	local x = math.random() * total
	for i, r in ipairs(Config.Raridades) do
		x -= r.peso
		if x <= 0 then return i end
	end
	return 1
end

local function criarItem(st, raridadeIdx, faseIdx, slotId)
	local rar = Config.Raridades[raridadeIdx]
	local slot = slotId and slotPorId(slotId) or Config.Slots[math.random(#Config.Slots)]
	local bruto = slot.valor * rar.mult * (1 + 0.35 * (faseIdx - 1)) * (0.85 + math.random() * 0.3)
	local valor
	if slot.atributo == "dano" or slot.atributo == "velocidade" then
		valor = math.max(1, math.floor(bruto + 0.5))
	else
		valor = math.floor(bruto * 1000 + 0.5) / 1000
	end
	st.proximoId += 1
	local item = {
		id = st.proximoId,
		slot = slot.id,
		raridade = rar.id,
		nome = slot.base .. " " .. rar.material,
		valor = valor,
		fase = faseIdx,
	}
	return item
end

local function contarItens(st)
	local n = 0
	for _ in pairs(st.itens) do n += 1 end
	return n
end

local function guardarItem(player, item, pos, origem)
	local st = estado[player]
	if contarItens(st) >= Config.LimiteInventario then
		local ouro = Config.ValorVenda[item.raridade] or 1
		st.ouro += ouro
		evLoot:FireClient(player, "cheio", pos, item, ouro)
		return
	end
	st.itens[item.id] = item
	evLoot:FireClient(player, origem or "drop", pos, item)
	if item.raridade == "lendario" then
		for _, outro in ipairs(Players:GetPlayers()) do
			evAviso:FireClient(outro, "lendario", player.DisplayName, item.nome)
		end
	end
end

------------------------------------------------------------------------
-- Monstros
------------------------------------------------------------------------
local function parte(modelo, props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do p[k] = v end
	p.Parent = modelo
	return p
end

local function criarMonstro(player, indiceFase)
	local f = Config.Fases[indiceFase]
	local s = f.tamanho
	local ang = math.random() * math.pi * 2
	local raio = 7 + math.random() * (Config.RaioMonstros - 7)
	local base = Vector3.new(math.cos(ang) * raio, topoArena, math.sin(ang) * raio)

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
	m:SetAttribute("Fase", indiceFase)

	local bb = Instance.new("BillboardGui")
	bb.Name = "Barra"
	bb.Size = UDim2.fromOffset(110, 30)
	bb.StudsOffsetWorldSpace = Vector3.new(0, s * 1.1 + 1, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 90
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
		if m:GetAttribute("Dono") == player.UserId then m:Destroy() end
	end
end

local function completarMonstros(player)
	local st = estado[player]
	if not st then return end
	for _ = 1, Config.MonstrosVivos - #monstrosDe(player) do
		criarMonstro(player, st.fase)
	end
end

------------------------------------------------------------------------
-- Fases e progresso
------------------------------------------------------------------------
local function aplicarFase(player)
	local st = estado[player]
	local f = Config.Fases[st.fase]
	pintarArena(f)
	limparMonstros(player)
	completarMonstros(player)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if root then root.CFrame = CFrame.new(0, topoArena + 3, 0) end
	enviarEstado(player)
end

local function ganharXP(player, quanto)
	local st = estado[player]
	st.xp += quanto
	while st.xp >= Config.XPParaNivel(st.nivel) do
		st.xp -= Config.XPParaNivel(st.nivel)
		st.nivel += 1
		evAviso:FireClient(player, "nivel", st.nivel)
	end
end

local function monstroMorreu(player, m)
	local st = estado[player]
	if not st then return end
	local faseIdx = m:GetAttribute("Fase") or st.fase
	local f = Config.Fases[faseIdx]
	local pos = m.PrimaryPart and m.PrimaryPart.Position or Vector3.zero
	local cor = m.PrimaryPart and m.PrimaryPart:GetAttribute("CorOriginal") or Color3.new(1, 1, 1)
	m:SetAttribute("Vida", 0)

	local stats = calcularStats(st)
	local ouro = math.max(1, math.floor(f.ouro * stats.ouro + 0.5))
	st.ouro += ouro
	ganharXP(player, f.xp)
	evDano:FireClient(player, "morte", pos, ouro, cor, f.xp)

	for _, p in ipairs(m:GetChildren()) do
		if p:IsA("BasePart") then
			TweenService:Create(p, TweenInfo.new(0.2), {Size = p.Size * 0.05, Transparency = 1}):Play()
		end
	end
	task.delay(0.25, function() m:Destroy() end)

	if math.random() < Config.ChanceDrop then
		guardarItem(player, criarItem(st, sortearRaridade(), faseIdx), pos)
	end

	st.kills += 1
	if st.kills >= Config.MonstrosPorFase then
		st.kills = 0
		if st.fase < #Config.Fases then
			st.fase += 1
			st.faseMax = math.max(st.faseMax, st.fase)
			local nova = Config.Fases[st.fase]
			evAviso:FireClient(player, "fase", nova.nome, nova.monstro)
			task.delay(0.5, aplicarFase, player)
		else
			evAviso:FireClient(player, "completo", f.nome)
			task.delay(0.3, completarMonstros, player)
		end
	else
		task.delay(0.6, completarMonstros, player)
	end
	enviarEstado(player)
end

------------------------------------------------------------------------
-- Combate: o herói bate sozinho no monstro mais perto dentro do alcance
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
			local d = ((m.PrimaryPart.Position - root.Position) * Vector3.new(1, 0, 1)).Magnitude
			if d <= menor then alvo, menor = m, d end
		end
	end
	if not alvo then return end

	local st = estado[player]
	local stats = calcularStats(st)
	local h = Config.Heroi
	local dano = stats.dano * (1 + (math.random() * 2 - 1) * h.Variacao)
	local critico = math.random() < stats.critico
	if critico then dano *= h.MultCritico end
	dano = math.max(1, math.floor(dano + 0.5))

	local vida = math.max(0, alvo:GetAttribute("Vida") - dano)
	alvo:SetAttribute("Vida", vida)
	local barra = alvo:FindFirstChild("Barra")
	if barra then
		TweenService:Create(barra.Fundo.Vida, TweenInfo.new(0.12),
			{Size = UDim2.new(vida / alvo:GetAttribute("VidaMax"), 0, 1, 0)}):Play()
	end
	piscar(alvo)
	evDano:FireClient(player, "dano", alvo.PrimaryPart.Position, dano, critico)
	if vida <= 0 then monstroMorreu(player, alvo) end
end

local function loopCombate(player)
	while player.Parent and estado[player] do
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if hum and root and hum.Health > 0 then golpe(player, root) end
		task.wait(Config.Heroi.Intervalo)
	end
end

------------------------------------------------------------------------
-- Pedidos da tela
------------------------------------------------------------------------
evPedirEstado.OnServerEvent:Connect(enviarEstado)

evAutoFarm.OnServerEvent:Connect(function(player, ligado)
	local st = estado[player]
	if st then st.autoFarm = ligado == true end
end)

evEquipar.OnServerEvent:Connect(function(player, itemId)
	local st = estado[player]
	local item = st and st.itens[itemId]
	if not item then return end
	st.equipado[item.slot] = item.id
	vestir(player)
	enviarEstado(player)
end)

evDesequipar.OnServerEvent:Connect(function(player, slotId)
	local st = estado[player]
	if not st or type(slotId) ~= "string" then return end
	st.equipado[slotId] = nil
	vestir(player)
	enviarEstado(player)
end)

evVender.OnServerEvent:Connect(function(player, itemId)
	local st = estado[player]
	local item = st and st.itens[itemId]
	if not item then return end
	for _, id in pairs(st.equipado) do
		if id == itemId then return end -- não vende o que está vestido
	end
	st.itens[itemId] = nil
	st.ouro += Config.ValorVenda[item.raridade] or 1
	enviarEstado(player)
end)

evForjar.OnServerEvent:Connect(function(player, raridadeId)
	local st = estado[player]
	if not st then return end
	local _, ri = raridadePorId(raridadeId)
	if not ri or ri >= #Config.Raridades then return end
	local custo = Config.Forja.Custo[raridadeId] or 0
	if st.ouro < custo then return end

	local vestidos = {}
	for _, id in pairs(st.equipado) do vestidos[id] = true end
	local usar = {}
	for _, item in pairs(st.itens) do
		if item.raridade == raridadeId and not vestidos[item.id] then table.insert(usar, item) end
	end
	if #usar < Config.Forja.Quantidade then return end
	table.sort(usar, function(a, b) return a.valor < b.valor end) -- usa os mais fracos primeiro

	local faseMaior = 1
	for i = 1, Config.Forja.Quantidade do
		faseMaior = math.max(faseMaior, usar[i].fase or 1)
		st.itens[usar[i].id] = nil
	end
	st.ouro -= custo
	local novo = criarItem(st, ri + 1, faseMaior)
	guardarItem(player, novo, nil, "forja")
	enviarEstado(player)
end)

evIrFase.OnServerEvent:Connect(function(player, faseIdx)
	local st = estado[player]
	if not st or type(faseIdx) ~= "number" then return end
	if not Config.Fases[faseIdx] or faseIdx > st.faseMax or faseIdx == st.fase then return end
	st.fase = faseIdx
	st.kills = 0
	local f = Config.Fases[faseIdx]
	evAviso:FireClient(player, "fase", f.nome, f.monstro)
	aplicarFase(player)
end)

------------------------------------------------------------------------
-- Jogadores
------------------------------------------------------------------------
Players.PlayerAdded:Connect(function(player)
	estado[player] = {
		nivel = 1, xp = 0, ouro = 0,
		fase = 1, faseMax = 1, kills = 0,
		itens = {}, equipado = {}, proximoId = 0,
		autoFarm = true,
	}
	player.CharacterAdded:Connect(function(char)
		char:WaitForChild("HumanoidRootPart")
		task.wait(0.2)
		vestir(player)
	end)
	if not player.Character then player.CharacterAdded:Wait() end
	task.wait(0.3)
	vestir(player)
	aplicarFase(player)
	task.spawn(loopCombate, player)
end)

Players.PlayerRemoving:Connect(function(player)
	limparMonstros(player)
	estado[player] = nil
end)
