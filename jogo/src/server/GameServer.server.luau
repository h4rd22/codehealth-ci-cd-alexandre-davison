-- GameServer: arena, monstros, combate automático, XP, ouro, loot,
-- inventário, equipamentos, forja e portal de fases.
-- Mundo 1 (fases 1-1 a 1-10, chefe na 1-10). Ainda não salva o progresso.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

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
local evEstado = remote("Estado") -- servidor -> tela: tudo do jogador
local evPedirEstado = remote("PedirEstado")
local evDano = remote("Dano") -- números de dano e morte de monstro
local evAviso = remote("Aviso") -- faixas: fase nova, nível novo, lendário
local evLoot = remote("Loot") -- item caiu / forja
local evAutoFarm = remote("AutoFarm")
local evRepetir = remote("Repetir") -- liga/desliga repetir a mesma fase
local evTreinar = remote("Treinar") -- sobe um atributo do treinamento
local evEquipar = remote("Equipar")
local evDesequipar = remote("Desequipar")
local evVender = remote("Vender")
local evForjar = remote("Forjar")
local evForjarAuto = remote("ForjarAuto")
local evAlquimia = remote("Alquimia")
local evConfigForja = remote("ConfigForja")
local evIrFase = remote("IrFase")
local evVida = remote("Vida") -- servidor -> tela: vida do herói

------------------------------------------------------------------------
-- Arena pequena com cenário por tema (ver Cenario.luau)
------------------------------------------------------------------------
local Cenario = require(script.Parent:WaitForChild("Cenario"))
local Modelos = require(script.Parent:WaitForChild("Modelos"))
local Chefe = require(script.Parent:WaitForChild("Chefe"))

local baseplate = workspace:FindFirstChild("Baseplate")
local spawn = workspace:FindFirstChildOfClass("SpawnLocation")
if spawn then
	spawn.Transparency = 1
	spawn.CanCollide = false
	for _, d in ipairs(spawn:GetChildren()) do
		if d:IsA("Decal") then
			d:Destroy()
		end
	end
end
local topoArena = Cenario.iniciar(baseplate)

local pasta = workspace:FindFirstChild("Monstros") or Instance.new("Folder")
pasta.Name = "Monstros"
pasta.Parent = workspace

------------------------------------------------------------------------
-- Estado dos jogadores
------------------------------------------------------------------------
local estado = {} -- estado[player] = {...}

-- Quantos inimigos derrotar para passar de fase (o chefe é 1 só)
local function metaDaFase(faseIdx)
	return Config.Fases[faseIdx].chefe and 1 or Config.MonstrosPorFase
end

local function raridadePorId(id)
	for i, r in ipairs(Config.Raridades) do
		if r.id == id then
			return r, i
		end
	end
end
local function slotPorId(id)
	for _, s in ipairs(Config.Slots) do
		if s.id == id then
			return s
		end
	end
end

local function calcularStats(st)
	local h = Config.Heroi
	local s = {
		dano = h.Dano + (st.nivel - 1) * h.DanoPorNivel,
		critico = h.ChanceCritico,
		ouro = 1,
		velocidade = h.Velocidade,
		vidaMax = h.Vida + (st.nivel - 1) * h.VidaPorNivel,
	}
	for slotId, itemId in pairs(st.equipado) do
		local item = st.itens[itemId]
		local slot = slotPorId(slotId)
		if item and slot then
			if slot.atributo == "dano" then
				s.dano += item.valor
			elseif slot.atributo == "critico" then
				s.critico += item.valor
			elseif slot.atributo == "ouro" then
				s.ouro += item.valor
			elseif slot.atributo == "velocidade" then
				s.velocidade += item.valor
			elseif slot.atributo == "vida" then
				s.vidaMax += item.valor
			elseif slot.atributo == "danoMult" then
				s.danoMult = (s.danoMult or 1) + item.valor
			end
		end
	end
	local treino = st.treino or {}
	for _, tr in ipairs(Config.Treino) do
		local n = treino[tr.id] or 0
		if tr.id == "forca" then
			s.dano += n * tr.valor
		elseif tr.id == "vitalidade" then
			s.vidaMax += n * tr.valor
		elseif tr.id == "precisao" then
			s.critico += n * tr.valor
		elseif tr.id == "ganancia" then
			s.ouro += n * tr.valor
		end
	end
	s.dano = math.floor(s.dano + 0.5)
	if s.danoMult then
		s.dano = math.floor(s.dano * s.danoMult + 0.5)
		s.danoMult = nil
	end
	return s
end

local function enviarEstado(player)
	local st = estado[player]
	if not st then
		return
	end
	local lista = {}
	for _, item in pairs(st.itens) do
		table.insert(lista, item)
	end
	table.sort(lista, function(a, b)
		return a.id > b.id
	end)
	evEstado:FireClient(player, {
		nivel = st.nivel,
		xp = st.xp,
		xpProx = Config.XPParaNivel(st.nivel),
		ouro = st.ouro,
		faseIdx = st.fase,
		faseMax = st.faseMax,
		kills = st.kills,
		meta = metaDaFase(st.fase),
		inventario = lista,
		equipado = st.equipado,
		stats = calcularStats(st),
		autoFarm = st.autoFarm,
		configForja = st.configForja,
		repetir = st.repetir,
		treino = st.treino,
	})
end

------------------------------------------------------------------------
-- Equipamento visível no personagem
------------------------------------------------------------------------
local function pecaDoCorpo(char, r15, r6)
	return char:FindFirstChild(r15) or char:FindFirstChild(r6)
end

local function grudar(pastaEq, base, tamanho, offset, cor, material, brilho)
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
	p.Parent = pastaEq
	return p
end

local function vestir(player)
	local st = estado[player]
	local char = player.Character
	if not st or not char then
		return
	end
	local velha = char:FindFirstChild("Equipamento")
	if velha then
		velha:Destroy()
	end
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
					grudar(
						pastaEq,
						mao,
						Vector3.new(0.35, 0.35, 1.2),
						CFrame.new(0, desce, -0.3),
						Color3.fromRGB(90, 60, 40),
						Enum.Material.Wood,
						false
					)
					grudar(
						pastaEq,
						mao,
						Vector3.new(1.4, 0.25, 0.3),
						CFrame.new(0, desce, -0.95),
						Color3.fromRGB(70, 70, 80),
						Enum.Material.Metal,
						false
					)
					grudar(
						pastaEq,
						mao,
						Vector3.new(0.3, 0.15, 3.4),
						CFrame.new(0, desce, -2.7),
						cor,
						ri >= 3 and Enum.Material.Neon or Enum.Material.Metal,
						brilho
					)
				end
			elseif slotId == "elmo" then
				local cabeca = char:FindFirstChild("Head")
				if cabeca then
					local s = cabeca.Size
					grudar(
						pastaEq,
						cabeca,
						Vector3.new(s.X * 1.15, s.Y * 0.55, s.Z * 1.15),
						CFrame.new(0, s.Y * 0.32, 0),
						cor,
						Enum.Material.Metal,
						brilho
					)
				end
			elseif slotId == "armadura" then
				local tronco = pecaDoCorpo(char, "UpperTorso", "Torso")
				if tronco then
					local s = tronco.Size
					grudar(
						pastaEq,
						tronco,
						Vector3.new(s.X * 1.1, s.Y * 0.9, s.Z * 1.25),
						CFrame.new(0, s.Y * 0.04, 0),
						cor,
						Enum.Material.Metal,
						brilho
					)
				end
			elseif slotId == "botas" then
				for _, nomes in ipairs({ { "LeftFoot", "Left Leg" }, { "RightFoot", "Right Leg" } }) do
					local pe = pecaDoCorpo(char, nomes[1], nomes[2])
					if pe then
						local s = pe.Size
						if pe.Name:find("Foot") then
							grudar(
								pastaEq,
								pe,
								s * Vector3.new(1.2, 1.4, 1.15),
								CFrame.new(0, s.Y * 0.15, 0),
								cor,
								Enum.Material.Metal,
								brilho
							)
						else
							grudar(
								pastaEq,
								pe,
								Vector3.new(s.X * 1.15, s.Y * 0.35, s.Z * 1.15),
								CFrame.new(0, -s.Y * 0.33, 0),
								cor,
								Enum.Material.Metal,
								brilho
							)
						end
					end
				end
			end
		end
	end

	-- Olho do Além-Ciclo: olhos roxos brilhando e uma aura na cabeça
	local olhoId = st.equipado.olho
	if olhoId and st.itens[olhoId] then
		local cabeca = char:FindFirstChild("Head")
		if cabeca then
			local roxo = Color3.fromRGB(190, 90, 255)
			for _, lado in ipairs({ -1, 1 }) do
				-- disco virado para a frente (o eixo do cilindro aponta para fora do rosto)
				local olho = grudar(
					pastaEq,
					cabeca,
					Vector3.new(0.05, 0.24, 0.24),
					CFrame.new(0.2 * lado, 0.12, -cabeca.Size.Z / 2 - 0.02) * CFrame.Angles(0, math.pi / 2, 0),
					roxo,
					Enum.Material.Neon,
					false
				)
				olho.Shape = Enum.PartType.Cylinder
			end
			local aura = Instance.new("ParticleEmitter")
			aura.Name = "AuraOlho"
			aura.Color = ColorSequence.new(roxo)
			aura.LightEmission = 1
			aura.Size = NumberSequence.new(0.35, 0)
			aura.Lifetime = NumberRange.new(0.5, 0.9)
			aura.Rate = 14
			aura.Speed = NumberRange.new(0.5, 1.5)
			aura.SpreadAngle = Vector2.new(180, 180)
			aura.Parent = cabeca
			local antigo = cabeca:FindFirstChild("AuraOlho")
			if antigo and antigo ~= aura then
				antigo:Destroy()
			end
		end
	else
		local cabeca = char:FindFirstChild("Head")
		local antigo = cabeca and cabeca:FindFirstChild("AuraOlho")
		if antigo then
			antigo:Destroy()
		end
	end

	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.WalkSpeed = calcularStats(st).velocidade
	end
end

------------------------------------------------------------------------
-- Itens
------------------------------------------------------------------------
local function sortearRaridade()
	local total = 0
	for _, r in ipairs(Config.Raridades) do
		total += r.peso
	end
	local x = math.random() * total
	for i, r in ipairs(Config.Raridades) do
		x -= r.peso
		if x <= 0 then
			return i
		end
	end
	return 1
end

-- Slots que podem cair aleatoriamente (o olho é especial e não entra)
local slotsComuns = {}
for _, s in ipairs(Config.Slots) do
	if not s.especial then
		table.insert(slotsComuns, s)
	end
end

-- Nível do item que cai: mistura nível do inimigo e do herói, com variação
local function nivelDoDrop(nivelInimigo, nivelHeroi)
	local c = Config.ItemNivel
	local base = nivelInimigo * c.PesoInimigo + nivelHeroi * c.PesoHeroi
	return math.max(1, math.floor(base + 0.5) + math.random(-c.Variacao, c.Variacao))
end

local function criarItem(st, raridadeIdx, nivel, slotId, nomeEspecial, valorFixo)
	local rar = Config.Raridades[raridadeIdx]
	local slot = slotId and slotPorId(slotId) or slotsComuns[math.random(#slotsComuns)]
	local cresc = 1 + Config.ItemNivel.CrescimentoPorNivel * (nivel - 1)
	local bruto = slot.valor * rar.mult * cresc * (0.85 + math.random() * 0.3)
	if slot.especial or valorFixo then
		bruto = valorFixo or slot.valor -- o olho tem valor fixo
	end
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
		nome = nomeEspecial
			or (Config.NomesItens[slot.id] and Config.NomesItens[slot.id][raridadeIdx])
			or (slot.base .. " " .. rar.material),
		valor = valor,
		nivel = nivel,
	}
	return item
end

local function contarItens(st)
	local n = 0
	for _ in pairs(st.itens) do
		n += 1
	end
	return n
end

local combinarAutomatico -- definida mais abaixo, na parte da forja

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
	if st.configForja.auto and not st.forjando and combinarAutomatico then
		task.defer(function()
			if estado[player] and combinarAutomatico(player, st) > 0 then
				enviarEstado(player)
			end
		end)
	end
	local _, riItem = raridadePorId(item.raridade)
	if riItem and riItem >= 5 then
		for _, outro in ipairs(Players:GetPlayers()) do
			evAviso:FireClient(outro, "lendario", player.DisplayName, item.nome)
		end
	end
end

------------------------------------------------------------------------
-- Monstros (o visual vem de Modelos.luau)
------------------------------------------------------------------------
local causarDano, enviarVida, vidaMaxDe -- definidas na parte "Vida do herói"

local function criarMonstro(player, indiceFase)
	local f = Config.Fases[indiceFase]
	local base
	if f.chefe then
		base = Vector3.new(0, topoArena, -11)
	else
		-- tenta um lugar longe dos outros inimigos, para não cercarem o herói todos juntos
		for _ = 1, 12 do
			local ang = math.random() * math.pi * 2
			local raio = 7 + math.random() * (Config.RaioMonstros - 7)
			base = Vector3.new(math.cos(ang) * raio, topoArena, math.sin(ang) * raio)
			local livre = true
			for _, outro in ipairs(pasta:GetChildren()) do
				if outro.PrimaryPart and (outro.PrimaryPart.Position - base).Magnitude < 11 then
					livre = false
					break
				end
			end
			if livre then
				break
			end
		end
	end
	-- olha para o centro da arena, onde o herói começa
	local cf = CFrame.lookAt(base, Vector3.new(0, topoArena, 0))
	local m, corpo, altura = Modelos.criar(f.modelo, cf)
	m.Name = f.monstro
	m:SetAttribute("Dono", player.UserId)
	local vida = Config.VidaInimigo(f.nivel, f.chefe)
	m:SetAttribute("Vida", vida)
	m:SetAttribute("VidaMax", vida)
	m:SetAttribute("Nivel", f.nivel)
	m:SetAttribute("Dano", Config.DanoInimigo(f.nivel))
	m:SetAttribute("Fase", indiceFase)
	m:SetAttribute("ProxAtaque", os.clock() + 1.2)
	if f.chefe then
		m:SetAttribute("Chefe", true)
		m:SetAttribute("Fim", workspace:GetServerTimeNow() + Config.ChefeTempo)
	end

	-- Plaquinha estilo anime: selo de nível, nome com contorno e barra de vida em degradê
	local bb = Instance.new("BillboardGui")
	bb.Name = "Barra"
	bb.Size = UDim2.fromOffset(f.chefe and 200 or 150, 40)
	bb.StudsOffsetWorldSpace = Vector3.new(0, (base.Y + altura) - corpo.Position.Y + 1.4, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 90
	bb.Adornee = corpo
	bb.Parent = m

	local corTema = f.chefe and Color3.fromRGB(190, 90, 255) or Color3.fromRGB(235, 70, 60)
	local selo = Instance.new("Frame")
	selo.Position = UDim2.fromOffset(0, 4)
	selo.Size = UDim2.fromOffset(28, 28)
	selo.BackgroundColor3 = Color3.fromRGB(40, 26, 20)
	selo.ZIndex = 3
	selo.Parent = bb
	Instance.new("UICorner", selo).CornerRadius = UDim.new(1, 0)
	local seloBorda = Instance.new("UIStroke")
	seloBorda.Color = Color3.fromRGB(230, 185, 100)
	seloBorda.Thickness = 2
	seloBorda.Parent = selo
	local nv = Instance.new("TextLabel")
	nv.Size = UDim2.fromScale(1, 1)
	nv.BackgroundTransparency = 1
	nv.Text = tostring(f.nivel)
	nv.TextColor3 = Color3.fromRGB(255, 225, 140)
	nv.Font = Enum.Font.FredokaOne
	nv.TextSize = 14
	nv.ZIndex = 4
	nv.Parent = selo

	local nome = Instance.new("TextLabel")
	nome.Position = UDim2.fromOffset(32, 2)
	nome.Size = UDim2.new(1, -32, 0, 16)
	nome.BackgroundTransparency = 1
	nome.Text = f.monstro
	nome.TextColor3 = f.chefe and Color3.fromRGB(235, 190, 255) or Color3.new(1, 1, 1)
	nome.TextXAlignment = Enum.TextXAlignment.Left
	nome.TextStrokeTransparency = 0
	nome.TextStrokeColor3 = Color3.fromRGB(20, 12, 10)
	nome.Font = Enum.Font.FredokaOne
	nome.TextSize = f.chefe and 16 or 13
	nome.TextTruncate = Enum.TextTruncate.AtEnd
	nome.Parent = bb

	local fundo = Instance.new("Frame")
	fundo.Name = "Fundo"
	fundo.Position = UDim2.fromOffset(26, 20)
	fundo.Size = UDim2.new(1, -28, 0, 11)
	fundo.BackgroundColor3 = Color3.fromRGB(24, 16, 14)
	fundo.BorderSizePixel = 0
	fundo.ZIndex = 2
	fundo.Parent = bb
	Instance.new("UICorner", fundo).CornerRadius = UDim.new(1, 0)
	local borda = Instance.new("UIStroke")
	borda.Color = Color3.fromRGB(20, 10, 8)
	borda.Thickness = 1.5
	borda.Parent = fundo

	local barra = Instance.new("Frame")
	barra.Name = "Vida"
	barra.Size = UDim2.fromScale(1, 1)
	barra.BackgroundColor3 = Color3.new(1, 1, 1)
	barra.BorderSizePixel = 0
	barra.ZIndex = 2
	barra.Parent = fundo
	Instance.new("UICorner", barra).CornerRadius = UDim.new(1, 0)
	local degrade = Instance.new("UIGradient")
	degrade.Rotation = 90
	degrade.Color = ColorSequence.new(corTema:Lerp(Color3.new(1, 1, 1), 0.35), corTema:Lerp(Color3.new(0, 0, 0), 0.25))
	degrade.Parent = barra

	m.Parent = pasta

	if m:GetAttribute("UsaArte") then
		-- Personagem 3D: aparece crescendo inteiro e começa a "respirar"
		Modelos.animar(m)
		if f.chefe then
			Chefe.iniciar(m, {
				player = player,
				chao = topoArena,
				dano = Config.DanoInimigo(f.nivel),
				vivo = function()
					local st = estado[player]
					return m.Parent ~= nil and (m:GetAttribute("Vida") or 0) > 0 and st ~= nil and not st.morto
				end,
				raizHeroi = function()
					local char = player.Character
					return char and char:FindFirstChild("HumanoidRootPart")
				end,
				acertar = function(pos, raio, dano)
					local char = player.Character
					local raiz = char and char:FindFirstChild("HumanoidRootPart")
					if raiz and ((raiz.Position - pos) * Vector3.new(1, 0, 1)).Magnitude <= raio then
						return causarDano(player, dano, raiz.Position)
					end
					return false
				end,
				empurrar = function(direcao, forca)
					evAviso:FireClient(player, "empurrao", direcao, forca)
				end,
				atacar = function()
					Modelos.atacar(m)
				end,
				aviso = function(texto)
					evAviso:FireClient(player, "habilidade", texto)
				end,
			})
		end
		local final = m:GetScale()
		local escala = Instance.new("NumberValue")
		escala.Value = final * 0.15
		escala.Changed:Connect(function(v)
			if m.Parent then
				m:ScaleTo(v)
			end
		end)
		local tw = TweenService:Create(escala, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Value = final })
		tw.Completed:Connect(function()
			escala:Destroy()
		end)
		tw:Play()
	else
		-- Modelo de peças: cada peça cresce no próprio lugar
		for _, p in ipairs(m:GetDescendants()) do
			if p:IsA("BasePart") then
				local tam = p.Size
				p.Size = tam * 0.1
				TweenService:Create(p, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Size = tam }):Play()
			end
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
	if not st then
		return
	end
	local f = Config.Fases[st.fase]
	local vivos = f.chefe and 1 or Config.MonstrosVivos
	for _ = 1, vivos - #monstrosDe(player) do
		criarMonstro(player, st.fase)
	end
end

------------------------------------------------------------------------
-- Fases e progresso
------------------------------------------------------------------------
local function aplicarFase(player)
	local st = estado[player]
	local f = Config.Fases[st.fase]
	Cenario.aplicar(f.tema, baseplate)
	limparMonstros(player)
	completarMonstros(player)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if root then
		root.CFrame = CFrame.new(0, topoArena + 3, 4)
	end
	if f.chefe then
		evAviso:FireClient(player, "chefe", f.monstro)
	end
	st.vida = vidaMaxDe(st)
	enviarVida(player)
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

-- Baú especial do chefe: abre, solta ouro e um item Épico ou Lendário
local function abrirBau(player, pos)
	local st = estado[player]
	local cf = CFrame.new(pos.X, topoArena, pos.Z) * CFrame.Angles(0, math.pi, 0)
	local bau, tampa = Modelos.bau(cf)
	bau.Parent = workspace
	task.delay(0.6, function()
		TweenService:Create(tampa, TweenInfo.new(0.4, Enum.EasingStyle.Back), {
			CFrame = tampa.CFrame * CFrame.new(0, 0.6, 1) * CFrame.Angles(math.rad(-70), 0, 0),
		}):Play()
		if not estado[player] then
			return
		end
		local drops = Config.DropsChefe
		st.ouro += drops.Ouro
		local f = Config.Fases[st.fase]
		local nivel = nivelDoDrop(f.nivel, st.nivel) + 2
		-- 1 equipamento garantido
		local x, escolhida = math.random(), drops.Equipamento[1][1]
		for _, par in ipairs(drops.Equipamento) do
			x -= par[2]
			if x <= 0 then
				escolhida = par[1]
				break
			end
		end
		local _, ri = raridadePorId(escolhida)
		guardarItem(player, criarItem(st, ri, nivel), pos + Vector3.new(0, 3, 0), "bau")
		-- especiais (Lâmina de Chakra Negro, Rinnegan...)
		for k, esp in ipairs(drops.Especiais) do
			if math.random() < esp.chance then
				local _, rie = raridadePorId(esp.raridade)
				local item = criarItem(st, rie, nivel, esp.slot, esp.nome, esp.valor)
				guardarItem(player, item, pos + Vector3.new(0, 3 + k * 2, 0), "bau")
				for _, outro in ipairs(Players:GetPlayers()) do
					evAviso:FireClient(outro, "lendario", player.DisplayName, esp.nome)
				end
			end
		end
		evAviso:FireClient(player, "bau", drops.Ouro)
		enviarEstado(player)
	end)
	task.delay(4, function()
		bau:Destroy()
	end)
end

local function monstroMorreu(player, m)
	local st = estado[player]
	if not st then
		return
	end
	local faseIdx = m:GetAttribute("Fase") or st.fase
	local f = Config.Fases[faseIdx]
	local pos = m.PrimaryPart and m.PrimaryPart.Position or Vector3.zero
	local cor = m.PrimaryPart and m.PrimaryPart:GetAttribute("CorOriginal") or Color3.new(1, 1, 1)
	m:SetAttribute("Vida", 0)

	local stats = calcularStats(st)
	local ouro = math.max(1, math.floor(f.ouro * stats.ouro + 0.5))
	st.ouro += ouro
	ganharXP(player, f.xp)
	evDano:FireClient(player, "morte", pos, ouro, cor, f.xp, f.chefe)

	local tempoSumir = f.chefe and 0.8 or 0.2
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") or p:IsA("Decal") then
			local alvo = { Transparency = 1 }
			if p:IsA("BasePart") and not m:GetAttribute("UsaArte") then
				alvo.Size = p.Size * 0.05
			end
			TweenService:Create(p, TweenInfo.new(tempoSumir), alvo):Play()
		end
	end
	task.delay(f.chefe and 0.85 or 0.25, function()
		m:Destroy()
	end)

	if f.chefe then
		abrirBau(player, pos)
	elseif math.random() < Config.ChanceDrop then
		guardarItem(player, criarItem(st, sortearRaridade(), nivelDoDrop(f.nivel, st.nivel)), pos)
	end

	st.kills += 1
	if st.kills >= metaDaFase(st.fase) then
		st.kills = 0
		if st.repetir then
			-- repete a mesma fase, mas já libera a próxima no portal
			st.faseMax = math.max(st.faseMax, math.min(st.fase + 1, #Config.Fases))
			evAviso:FireClient(player, "repetir", f.nome)
			task.delay(f.chefe and 3 or 0.6, completarMonstros, player)
		elseif st.fase < #Config.Fases then
			st.fase += 1
			st.faseMax = math.max(st.faseMax, st.fase)
			local nova = Config.Fases[st.fase]
			evAviso:FireClient(player, "fase", nova.nome, nova.monstro)
			task.delay(0.5, aplicarFase, player)
		else
			evAviso:FireClient(player, "completo", "Mundo " .. f.mundo)
			task.delay(4, completarMonstros, player)
		end
	else
		task.delay(0.6, completarMonstros, player)
	end
	enviarEstado(player)
end

------------------------------------------------------------------------
-- Combate: o herói bate sozinho no monstro mais perto dentro do alcance
------------------------------------------------------------------------
-- Pisca branco ao levar golpe (funciona em qualquer modelo, até com textura)
local function piscar(m)
	local h = m:FindFirstChild("Piscar")
	if not h then
		h = Instance.new("Highlight")
		h.Name = "Piscar"
		h.FillColor = Color3.new(1, 1, 1)
		h.FillTransparency = 0.25
		h.OutlineTransparency = 1
		h.DepthMode = Enum.HighlightDepthMode.Occluded
		h.Parent = m
	end
	h.Enabled = true
	task.delay(0.08, function()
		if h.Parent then
			h.Enabled = false
		end
	end)
end

local function golpe(player, root)
	local alvo, menor = nil, math.huge
	for _, m in ipairs(monstrosDe(player)) do
		if m.PrimaryPart then
			local d = ((m.PrimaryPart.Position - root.Position) * Vector3.new(1, 0, 1)).Magnitude
			local alcance = m:GetAttribute("Chefe") and Config.Heroi.AlcanceChefe or Config.Heroi.Alcance
			if d <= alcance and d < menor then
				alvo, menor = m, d
			end
		end
	end
	if not alvo then
		return
	end

	local st = estado[player]
	if st.morto then
		return
	end
	local stats = calcularStats(st)
	local h = Config.Heroi
	local dano = stats.dano * (1 + (math.random() * 2 - 1) * h.Variacao)
	local critico = math.random() < stats.critico
	if critico then
		dano *= h.MultCritico
	end
	dano = math.max(1, math.floor(dano + 0.5))

	local vida = math.max(0, alvo:GetAttribute("Vida") - dano)
	alvo:SetAttribute("Vida", vida)
	local barra = alvo:FindFirstChild("Barra")
	if barra then
		TweenService:Create(
			barra.Fundo.Vida,
			TweenInfo.new(0.12),
			{ Size = UDim2.fromScale(vida / alvo:GetAttribute("VidaMax"), 1) }
		):Play()
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
-- Vida do herói e ataques dos inimigos
------------------------------------------------------------------------
vidaMaxDe = function(st)
	return calcularStats(st).vidaMax
end

enviarVida = function(player)
	local st = estado[player]
	if st then
		evVida:FireClient(player, math.max(0, math.floor(st.vida + 0.5)), vidaMaxDe(st))
	end
end

-- O herói caiu: na fase normal recomeça a contagem; no chefe (ou se o tempo acabou) volta uma fase
local function derrota(player, motivo)
	local st = estado[player]
	if not st or st.morto then
		return
	end
	st.morto = true
	local voltar = Config.Fases[st.fase].chefe == true
	if RunService:IsStudio() then
		print(string.format("[Derrota] %s caiu na fase %d (motivo: %s)", player.Name, st.fase, tostring(motivo)))
	end
	evAviso:FireClient(player, "derrota", motivo, voltar)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.WalkSpeed = 0
	end
	task.delay(2.5, function()
		if not estado[player] then
			return
		end
		if voltar and st.fase > 1 then
			st.fase -= 1
		end
		st.kills = 0
		st.morto = false
		vestir(player) -- devolve a velocidade
		aplicarFase(player) -- também cura a vida toda
	end)
end

causarDano = function(player, dano, pos)
	local st = estado[player]
	if not st or st.morto then
		return false
	end
	dano = math.max(1, math.floor(dano + 0.5))
	st.vida -= dano
	st.ultimoDano = os.clock()
	evDano:FireClient(player, "heroi", pos, dano)
	enviarVida(player)
	if st.vida <= 0 then
		derrota(player, "vida")
	end
	return true
end

local function loopInimigos(player)
	while player.Parent and estado[player] do
		local st = estado[player]
		local char = player.Character
		local raizHeroi = char and char:FindFirstChild("HumanoidRootPart")
		local agora = os.clock()
		if raizHeroi and not st.morto then
			local alcance = Config.Inimigo.AtaqueAlcance
			for _, m in ipairs(monstrosDe(player)) do
				local raiz = m.PrimaryPart
				if raiz then
					local chefe = m:GetAttribute("Chefe") == true
					local d = ((raiz.Position - raizHeroi.Position) * Vector3.new(1, 0, 1)).Magnitude
					if d <= (chefe and alcance + 4 or alcance) and agora >= (m:GetAttribute("ProxAtaque") or 0) then
						m:SetAttribute(
							"ProxAtaque",
							agora + Config.Inimigo.AtaqueIntervalo * (0.85 + math.random() * 0.3)
						)
						Modelos.atacar(m)
						local dano = (m:GetAttribute("Dano") or 1) * (chefe and Config.Inimigo.DanoChefeGolpe or 1)
						causarDano(player, dano * (0.85 + math.random() * 0.3), raizHeroi.Position)
					end
					if chefe and workspace:GetServerTimeNow() > (m:GetAttribute("Fim") or math.huge) then
						derrota(player, "tempo")
					end
				end
			end
			-- regenera quando fica um tempo sem apanhar
			local vm = vidaMaxDe(st)
			if st.vida < vm and agora - (st.ultimoDano or 0) > 2 then
				st.vida = math.min(vm, st.vida + vm * Config.Heroi.Regeneracao * 0.25)
				enviarVida(player)
			end
		end
		task.wait(0.25)
	end
end

------------------------------------------------------------------------
-- Pedidos da tela
------------------------------------------------------------------------
evPedirEstado.OnServerEvent:Connect(enviarEstado)

evRepetir.OnServerEvent:Connect(function(player, ligado)
	local st = estado[player]
	if st then
		st.repetir = ligado == true
		enviarEstado(player)
	end
end)

-- Treinamento: sobe 1 nível do atributo pagando ouro (o servidor confere tudo)
local ultimoTreino = {}
evTreinar.OnServerEvent:Connect(function(player, id)
	local st = estado[player]
	if not st or type(id) ~= "string" then
		return
	end
	local agora = os.clock()
	if ultimoTreino[player] and agora - ultimoTreino[player] < 0.08 then
		return
	end
	ultimoTreino[player] = agora
	for _, tr in ipairs(Config.Treino) do
		if tr.id == id then
			local n = st.treino[id] or 0
			local custo = Config.CustoTreino(tr, n)
			if n < tr.max and st.ouro >= custo then
				st.ouro -= custo
				st.treino[id] = n + 1
				vestir(player) -- atualiza vida/velocidade
				enviarEstado(player)
				enviarVida(player)
			end
			return
		end
	end
end)

evAutoFarm.OnServerEvent:Connect(function(player, ligado)
	local st = estado[player]
	if st then
		st.autoFarm = ligado == true
	end
end)

evEquipar.OnServerEvent:Connect(function(player, itemId)
	local st = estado[player]
	local item = st and st.itens[itemId]
	if not item then
		return
	end
	st.equipado[item.slot] = item.id
	vestir(player)
	enviarEstado(player)
end)

evDesequipar.OnServerEvent:Connect(function(player, slotId)
	local st = estado[player]
	if not st or type(slotId) ~= "string" then
		return
	end
	st.equipado[slotId] = nil
	vestir(player)
	enviarEstado(player)
end)

evVender.OnServerEvent:Connect(function(player, itemId)
	local st = estado[player]
	local item = st and st.itens[itemId]
	if not item then
		return
	end
	for _, id in pairs(st.equipado) do
		if id == itemId then
			return
		end -- não vende o que está vestido
	end
	st.itens[itemId] = nil
	st.ouro += Config.ValorVenda[item.raridade] or 1
	enviarEstado(player)
end)

-- Forja: 3 itens da mesma raridade viram 1 da raridade de cima.
-- O servidor confere tudo (a tela do jogador pode ser hackeada).
local ultimaForja = {}

local function podeUsarForja(player)
	local agora = os.clock()
	if ultimaForja[player] and agora - ultimaForja[player] < 0.15 then
		return false
	end
	ultimaForja[player] = agora
	return true
end

local function forjarItens(player, st, itens)
	local rar, ri = raridadePorId(itens[1].raridade)
	local proxima = Config.Raridades[ri + 1]
	if not rar or rar.forjavel == false or not proxima then
		return nil
	end
	local custo = Config.Forja.Custo[rar.id] or 0
	if st.ouro < custo then
		return nil
	end
	local nivel = 1
	for _, it in ipairs(itens) do
		nivel = math.max(nivel, it.nivel or 1)
		st.itens[it.id] = nil
	end
	st.ouro -= custo
	local novo = criarItem(st, ri + 1, nivel, itens[1].slot) -- mesma categoria
	guardarItem(player, novo, nil, "forja")
	return novo
end

local function itensLivres(st)
	local vestidos = {}
	for _, id in pairs(st.equipado) do
		vestidos[id] = true
	end
	return vestidos
end

-- Forja manual: a tela manda os ids dos 3 itens colocados nos espaços
evForjar.OnServerEvent:Connect(function(player, ids)
	local st = estado[player]
	if not st or type(ids) ~= "table" or #ids ~= Config.Forja.Quantidade or not podeUsarForja(player) then
		return
	end
	local vestidos = itensLivres(st)
	local vistos, itens = {}, {}
	for _, id in ipairs(ids) do
		local item = type(id) == "number" and st.itens[id]
		if not item or vistos[id] or vestidos[id] then
			return
		end
		if #itens > 0 and (item.raridade ~= itens[1].raridade or item.slot ~= itens[1].slot) then
			return
		end
		vistos[id] = true
		table.insert(itens, item)
	end
	forjarItens(player, st, itens)
	enviarEstado(player)
end)

-- Forja automática: combina sozinha as raridades marcadas, das mais fracas para as mais fortes
-- Combina sozinho tudo o que der, da raridade mais fraca até a escolhida em "ate".
-- mesmoNivel = só junta itens do mesmo nível. Devolve quantas forjas fez.
combinarAutomatico = function(player, st, ateId, mesmoNivel)
	local cfg = st.configForja
	local _, ateIdx = raridadePorId(ateId or cfg.ate)
	if mesmoNivel == nil then
		mesmoNivel = cfg.mesmoNivel
	end
	if not ateIdx then
		return 0
	end
	st.forjando = true
	local feitas = 0
	for ri = 1, ateIdx do
		local rar = Config.Raridades[ri]
		while rar.forjavel ~= false and feitas < 50 do
			local vestidos = itensLivres(st)
			local grupos = {}
			for _, item in pairs(st.itens) do
				if item.raridade == rar.id and not vestidos[item.id] then
					local chave = item.slot .. "#" .. (mesmoNivel and (item.nivel or 1) or 0)
					grupos[chave] = grupos[chave] or {}
					table.insert(grupos[chave], item)
				end
			end
			local usar
			for _, g in pairs(grupos) do
				if #g >= Config.Forja.Quantidade then
					table.sort(g, function(a, b)
						return a.valor < b.valor
					end)
					usar = { table.unpack(g, 1, Config.Forja.Quantidade) }
					break
				end
			end
			if not usar or not forjarItens(player, st, usar) then
				break
			end
			feitas += 1
		end
	end
	st.forjando = false
	return feitas
end

-- Botão "combinar tudo agora" (usa as escolhas da tela)
evForjarAuto.OnServerEvent:Connect(function(player, ateId, mesmoNivel)
	local st = estado[player]
	if not st or type(ateId) ~= "string" or not raridadePorId(ateId) or not podeUsarForja(player) then
		return
	end
	local feitas = combinarAutomatico(player, st, ateId, mesmoNivel == true)
	evAviso:FireClient(player, "forjaAuto", feitas)
	enviarEstado(player)
end)

-- Configurações da forja (engrenagem): combinação automática ao farmar
evConfigForja.OnServerEvent:Connect(function(player, cfg)
	local st = estado[player]
	if not st or type(cfg) ~= "table" then
		return
	end
	if type(cfg.ate) == "string" and raridadePorId(cfg.ate) then
		st.configForja.ate = cfg.ate
	end
	st.configForja.auto = cfg.auto == true
	st.configForja.mesmoNivel = cfg.mesmoNivel == true
	if st.configForja.auto then
		combinarAutomatico(player, st)
	end
	enviarEstado(player)
end)

-- Alquimia: transforma de 1 a 9 itens em ouro
evAlquimia.OnServerEvent:Connect(function(player, ids)
	local st = estado[player]
	if not st or type(ids) ~= "table" or #ids < 1 or #ids > 9 or not podeUsarForja(player) then
		return
	end
	local vestidos = itensLivres(st)
	local vistos, total = {}, 0
	for _, id in ipairs(ids) do
		local item = type(id) == "number" and st.itens[id]
		if not item or vistos[id] or vestidos[id] then
			return
		end
		vistos[id] = true
		total += math.floor((Config.ValorVenda[item.raridade] or 1) * (1 + 0.05 * ((item.nivel or 1) - 1)) + 0.5)
	end
	for id in pairs(vistos) do
		st.itens[id] = nil
	end
	st.ouro += total
	evAviso:FireClient(player, "alquimia", total)
	enviarEstado(player)
end)

evIrFase.OnServerEvent:Connect(function(player, faseIdx)
	local st = estado[player]
	if not st or type(faseIdx) ~= "number" then
		return
	end
	if not Config.Fases[faseIdx] or faseIdx > st.faseMax or faseIdx == st.fase then
		return
	end
	st.fase = faseIdx
	st.kills = 0
	local f = Config.Fases[faseIdx]
	evAviso:FireClient(player, "fase", f.nome, f.monstro)
	aplicarFase(player)
end)

------------------------------------------------------------------------
-- Jogadores
------------------------------------------------------------------------
------------------------------------------------------------------------
-- Ferramenta de teste: só existe no Studio (nunca no jogo publicado)
------------------------------------------------------------------------
if RunService:IsStudio() then
	local debug = Instance.new("BindableFunction")
	debug.Name = "DebugTeste"
	debug.Parent = script
	debug.OnInvoke = function(acao, a, b)
		local player = Players:GetPlayers()[1]
		local st = player and estado[player]
		if not st then
			return "sem jogador"
		end
		if acao == "itens" then
			-- a = quantidade, b = índice da raridade (ou nil para sortear)
			for _ = 1, a or 10 do
				local f = Config.Fases[st.fase]
				local item = criarItem(st, b or sortearRaridade(), nivelDoDrop(f.nivel, st.nivel))
				st.itens[item.id] = item
			end
		elseif acao == "drop" then
			-- faz um item "cair" na frente do herói (para ver o efeito)
			local char = player.Character
			local raizHeroi = char and char:FindFirstChild("HumanoidRootPart")
			local pos = raizHeroi and (raizHeroi.Position + raizHeroi.CFrame.LookVector * 6) or Vector3.new(0, 5, 0)
			guardarItem(player, criarItem(st, b or sortearRaridade(), 10), pos)
		elseif acao == "vestirMelhor" then
			for _, s in ipairs(Config.Slots) do
				local melhor
				for _, it in pairs(st.itens) do
					if it.slot == s.id and (not melhor or it.valor > melhor.valor) then
						melhor = it
					end
				end
				if melhor then
					st.equipado[s.id] = melhor.id
				end
			end
			vestir(player)
		elseif acao == "ouro" then
			st.ouro += a or 1000
		elseif acao == "nivel" then
			st.nivel = a or 10
		elseif acao == "fase" then
			st.fase = a or 1
			st.kills = 0
			aplicarFase(player)
		end
		enviarEstado(player)
		local n = 0
		for _ in pairs(st.itens) do
			n += 1
		end
		return string.format("ok: nivel=%d ouro=%d itens=%d fase=%d", st.nivel, st.ouro, n, st.fase)
	end
end

Players.PlayerAdded:Connect(function(player)
	estado[player] = {
		nivel = 1,
		xp = 0,
		ouro = 0,
		fase = 1,
		-- No Studio todas as fases ficam liberadas para testar; no jogo publicado começa só a 1-1
		faseMax = RunService:IsStudio() and #Config.Fases or 1,
		kills = 0,
		itens = {},
		equipado = {},
		proximoId = 0,
		autoFarm = true,
		vida = Config.Heroi.Vida,
		repetir = false,
		treino = { forca = 0, vitalidade = 0, precisao = 0, ganancia = 0 },
		configForja = { auto = false, ate = "incomum", mesmoNivel = false },
	}
	player.CharacterAdded:Connect(function(char)
		char:WaitForChild("HumanoidRootPart")
		task.wait(0.2)
		vestir(player)
	end)
	if not player.Character then
		player.CharacterAdded:Wait()
	end
	task.wait(0.3)
	vestir(player)
	aplicarFase(player)
	task.spawn(loopCombate, player)
	task.spawn(loopInimigos, player)
end)

Players.PlayerRemoving:Connect(function(player)
	ultimaForja[player] = nil
	ultimoTreino[player] = nil
	limparMonstros(player)
	estado[player] = nil
end)
