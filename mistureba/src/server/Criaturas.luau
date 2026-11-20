--!strict
-- Monta os modelos 3D das Misturebas e dos ovos com peças simples.
-- Quando houver arte própria (modelos feitos no Studio), troque só este arquivo.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Util = require(ReplicatedStorage.Shared.Util)

local Criaturas = {}

local FORMAS = {
	bloco = Enum.PartType.Block,
	cilindro = Enum.PartType.Cylinder,
}

-- Bola de verdade no Roblox é sempre redonda; com malha de esfera ela vira oval.
local function oval(part: BasePart)
	local malha = Instance.new("SpecialMesh")
	malha.MeshType = Enum.MeshType.Sphere
	malha.Parent = part
end

local function peca(def: Config.Peca, escala: number): BasePart
	local p: BasePart
	if def.forma == "cunha" then
		p = Instance.new("WedgePart")
	else
		local part = Instance.new("Part")
		part.Shape = FORMAS[def.forma] or Enum.PartType.Block
		if def.forma == "bola" then
			oval(part)
		end
		p = part
	end
	p.Size = def.tamanho * escala
	p.Color = def.cor
	p.Material = if def.material then (Enum.Material :: any)[def.material] else Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = true
	p.Massless = true
	return p
end

local function soldar(a: BasePart, b: BasePart)
	local solda = Instance.new("WeldConstraint")
	solda.Part0 = a
	solda.Part1 = b
	solda.Parent = b
end

local function placa(alvo: BasePart, linhas: { { texto: string, cor: Color3, tamanho: number } }, altura: number)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Placa"
	gui.Size = UDim2.fromScale(8, 1.1 * #linhas) -- em studs: diminui com a distância
	gui.StudsOffsetWorldSpace = Vector3.new(0, altura, 0)
	gui.AlwaysOnTop = false
	gui.MaxDistance = 90
	gui.LightInfluence = 0
	local lista = Instance.new("UIListLayout")
	lista.Parent = gui
	for i, linha in linhas do
		local rotulo = Instance.new("TextLabel")
		rotulo.LayoutOrder = i
		rotulo.BackgroundTransparency = 1
		rotulo.Font = Enum.Font.FredokaOne
		rotulo.TextScaled = true
		rotulo.Text = linha.texto
		rotulo.TextColor3 = linha.cor
		rotulo.TextStrokeTransparency = 0.2
		rotulo.Size = UDim2.fromScale(1, linha.tamanho / 26 / #linhas)
		rotulo.Parent = gui
	end
	gui.Parent = alvo
end

-- Pecinha redonda (oval) presa no corpo. pos/tam já em studs (sem escala).
local function oval3(
	pai: Instance,
	corpo: BasePart,
	cor: Color3,
	tam: Vector3,
	pos: Vector3,
	material: Enum.Material?,
	rot: CFrame?
): BasePart
	local p = Instance.new("Part")
	oval(p)
	p.Size = tam
	p.Color = cor
	p.Material = material or Enum.Material.SmoothPlastic
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = true
	p.Massless = true
	p.CastShadow = false
	p.CFrame = corpo.CFrame * CFrame.new(pos) * (rot or CFrame.identity)
	p.Parent = pai
	soldar(corpo, p)
	return p
end

-- Rosto fofo: olhões com brilho, bochechas e boquinha (fica de fora da cor da mutação)
local function rosto(modelo: Model, corpo: BasePart, e: number, iris: Color3?)
	local z = -corpo.Size.Z / 2
	for _, lado in { -1, 1 } do
		local branco = oval3(
			modelo,
			corpo,
			Color3.new(1, 1, 1),
			Vector3.new(0.85, 1.05, 0.45) * e,
			Vector3.new(0.62 * lado * e, 0.42 * e, z + 0.22 * e)
		)
		branco.Name = "Olho"
		local pupila = oval3(
			modelo,
			corpo,
			if iris then iris:Lerp(Color3.new(0, 0, 0), 0.45) else Color3.fromRGB(30, 22, 50),
			Vector3.new(0.52, 0.68, 0.3) * e,
			Vector3.new(0.6 * lado * e, 0.36 * e, z + 0.02 * e)
		)
		pupila.Name = "Pupila"
		local brilho = oval3(
			modelo,
			corpo,
			Color3.new(1, 1, 1),
			Vector3.new(0.2, 0.22, 0.12) * e,
			Vector3.new((0.52 * lado + 0.08) * e, 0.56 * e, z - 0.17 * e),
			Enum.Material.Neon
		)
		brilho.Name = "BrilhoOlho"
		local bochecha = oval3(
			modelo,
			corpo,
			Color3.fromRGB(255, 130, 170),
			Vector3.new(0.55, 0.3, 0.2) * e,
			Vector3.new(1.08 * lado * e, -0.05 * e, z + 0.38 * e)
		)
		bochecha.Name = "Rosto"
		bochecha.Transparency = 0.15
	end
	local boca = oval3(
		modelo,
		corpo,
		Color3.fromRGB(70, 20, 40),
		Vector3.new(0.55, 0.32, 0.2) * e,
		Vector3.new(0, -0.18 * e, z - 0.05 * e)
	)
	boca.Name = "Rosto"
	local lingua = oval3(
		modelo,
		corpo,
		Color3.fromRGB(255, 110, 130),
		Vector3.new(0.32, 0.14, 0.12) * e,
		Vector3.new(0, -0.26 * e, z - 0.11 * e)
	)
	lingua.Name = "Rosto"
end

-- Enfeites que mostram a raridade de longe:
-- Épico ganha asinhas, Lendário coroa, Mítico auréola e asas que brilham, Secreto tudo isso.
local function enfeites(modelo: Model, corpo: BasePart, e: number, nivel: number, cor: Color3)
	-- ponto mais alto da Mistureba (a fantasia costuma ficar em cima da cabeça)
	local topo = 1.3 * e
	for _, p in modelo:GetDescendants() do
		if p:IsA("BasePart") and p.Name ~= "Rabo" then
			local y = corpo.CFrame:PointToObjectSpace(p.Position).Y + math.max(p.Size.X, p.Size.Y, p.Size.Z) / 2
			topo = math.max(topo, y)
		end
	end
	local temCoroa = nivel == 4 or nivel == 6
	if nivel >= 3 then
		local grande = nivel >= 5
		for _, lado in { -1, 1 } do
			local asa = oval3(
				modelo,
				corpo,
				if grande then cor:Lerp(Color3.new(1, 1, 1), 0.35) else Color3.fromRGB(250, 250, 255),
				Vector3.new(0.25, if grande then 2 else 1.4, if grande then 1.5 else 1.05) * e,
				Vector3.new(1.05 * lado, 0.45, 1.2) * e,
				if grande then Enum.Material.Neon else Enum.Material.SmoothPlastic,
				CFrame.Angles(math.rad(-20), math.rad(35 * lado), math.rad(-30 * lado))
			)
			asa.Name = "Enfeite"
			asa.Transparency = if grande then 0.3 else 0.05
		end
	end
	if temCoroa then
		-- coroa dourada torta, em cima de tudo
		local ouro = Color3.fromRGB(255, 200, 40)
		local base = Instance.new("Part")
		base.Name = "Enfeite"
		base.Shape = Enum.PartType.Cylinder
		base.Size = Vector3.new(0.35, 1.2, 1.2) * e
		base.Color = ouro
		base.Material = Enum.Material.Foil
		base.CanCollide = false
		base.CanTouch = false
		base.Massless = true
		local inclina = CFrame.Angles(math.rad(-8), 0, math.rad(12))
		local lugar = CFrame.new(0, topo + 0.05 * e, 0.1 * e)
		base.CFrame = corpo.CFrame * lugar * inclina * CFrame.Angles(0, 0, math.pi / 2)
		base.Parent = modelo
		soldar(corpo, base)
		for i = 0, 4 do
			local a = i / 5 * math.pi * 2
			local ponta = oval3(
				modelo,
				corpo,
				ouro,
				Vector3.new(0.2, 0.32, 0.2) * e,
				Vector3.zero,
				Enum.Material.Neon,
				lugar * inclina * CFrame.new(math.cos(a) * 0.5 * e, 0.3 * e, math.sin(a) * 0.5 * e)
			)
			ponta.Name = "Enfeite"
		end
	end
	if nivel >= 5 then
		-- auréola de bolinhas brilhando acima de tudo
		local alturaAureola = topo + (if temCoroa then 1.1 else 0.45) * e
		for i = 0, 11 do
			local a = i / 12 * math.pi * 2
			oval3(
				modelo,
				corpo,
				Color3.fromRGB(255, 245, 170),
				Vector3.new(0.3, 0.3, 0.3) * e,
				Vector3.new(math.cos(a) * 0.95 * e, alturaAureola, (math.sin(a) * 0.95 + 0.2) * e),
				Enum.Material.Neon
			).Name =
				"Enfeite"
		end
	end
end

-- Cria o modelo de uma Mistureba: um bichinho gordinho e redondo da cor dela,
-- com barriga, pezinhos e bracinhos, usando as peças da fantasia (Config) por cima.
-- O corpo é a PrimaryPart e fica ancorado.
function Criaturas.modelo(id: string): Model
	local def = Config.PorId[id]
	assert(def, "Mistureba desconhecida: " .. tostring(id))
	local raridade = Config.Raridades[def.raridade]
	local mut = def.mutacao and Config.MutacaoPorId[def.mutacao]
	-- Mini e Gigante só mudam o tamanho
	-- (com limite para a Gigante não invadir a vaga do lado)
	local escala = math.min(raridade.tamanho * (if mut and mut.tamanho then mut.tamanho else 1), 2.5)
	local e = escala

	local modelo = Instance.new("Model")
	modelo.Name = def.nome
	modelo:SetAttribute("Criatura", id)

	local cor = def.corpo.cor
	local corpo = Instance.new("Part")
	oval(corpo)
	corpo.Name = "Corpo"
	corpo.Size = Vector3.new(3.2, 2.9, 3) * e
	corpo.Color = cor
	corpo.Material = Enum.Material.SmoothPlastic
	corpo.Reflectance = 0.04
	corpo.CanCollide = false
	corpo.CanTouch = false
	corpo.CanQuery = true
	corpo.Anchored = true
	corpo.CFrame = CFrame.new()
	corpo.Parent = modelo
	modelo.PrimaryPart = corpo

	local clara = cor:Lerp(Color3.new(1, 1, 1), 0.55)
	-- segunda cor: a da primeira peça da fantasia que for bem diferente do corpo (dá contraste)
	local segunda = cor:Lerp(Color3.new(0, 0, 0), 0.3)
	for _, extra in def.extras do
		local d = math.abs(extra.cor.R - cor.R) + math.abs(extra.cor.G - cor.G) + math.abs(extra.cor.B - cor.B)
		if d > 0.45 then
			segunda = extra.cor
			break
		end
	end
	oval3(modelo, corpo, clara, Vector3.new(2.1, 1.7, 0.7) * e, Vector3.new(0, -0.45, -1.2) * e).Name = "Barriga"
	oval3(modelo, corpo, segunda, Vector3.new(0.8, 0.8, 0.8) * e, Vector3.new(0, -0.7, 1.45) * e).Name = "Rabo"
	local nivel = table.find(Config.OrdemRaridades, def.raridade) or 1
	for _, lado in { -1, 1 } do
		oval3(modelo, corpo, segunda, Vector3.new(1.1, 0.6, 1.4) * e, Vector3.new(0.8 * lado, -1.45, -0.25) * e).Name =
			"Pe"
		if nivel >= 2 then
			-- orelhinhas a partir de Raro
			oval3(
				modelo,
				corpo,
				cor,
				Vector3.new(0.65, 1, 0.45) * e,
				Vector3.new(0.95 * lado, 1.2, 0.1) * e,
				nil,
				CFrame.Angles(0, 0, math.rad(-28 * lado))
			).Name =
				"Orelha"
			oval3(
				modelo,
				corpo,
				segunda,
				Vector3.new(0.38, 0.6, 0.3) * e,
				Vector3.new(0.97 * lado, 1.2, -0.06) * e,
				nil,
				CFrame.Angles(0, 0, math.rad(-28 * lado))
			).Name =
				"Orelha"
		end
		oval3(
			modelo,
			corpo,
			cor,
			Vector3.new(0.6, 1.1, 0.6) * e,
			Vector3.new(1.55 * lado, -0.25, -0.3) * e,
			nil,
			CFrame.Angles(0, 0, math.rad(25 * lado))
		).Name =
			"Braco"
	end

	-- fantasia: as peças que dão a cara de cada Mistureba, um pouco menores e em cima do corpo
	local peca0 = peca(def.corpo, escala * 0.7)
	peca0.Name = "Fantasia"
	peca0.CFrame = corpo.CFrame * CFrame.new(0, 1.15 * e, 0.35 * e)
	peca0.Parent = modelo
	soldar(corpo, peca0)
	for i, extra in def.extras do
		local p = peca(extra, escala * 0.8)
		p.Name = "Extra" .. i
		local pos = (extra.posicao or Vector3.zero) * escala * 0.8
		p.CFrame = corpo.CFrame * CFrame.new(pos + Vector3.new(0, 1.15 * e, 0.35 * e))
		p.Parent = modelo
		soldar(corpo, p)
	end

	-- aro brilhante da cor da raridade embaixo dos pés
	local aro = Instance.new("Part")
	aro.Name = "Aro"
	aro.Shape = Enum.PartType.Cylinder
	aro.Size = Vector3.new(0.12, 4.2 * e, 4.2 * e)
	aro.Color = raridade.cor
	aro.Material = Enum.Material.Neon
	aro.Transparency = 0.35
	aro.CanCollide = false
	aro.CanTouch = false
	aro.CanQuery = false
	aro.Massless = true
	aro.CastShadow = false
	aro.CFrame = corpo.CFrame * CFrame.new(0, -1.72 * e, 0) * CFrame.Angles(0, 0, math.rad(90))
	aro.Parent = modelo
	soldar(corpo, aro)

	-- mutação: muda a cor/material de todas as peças do corpo (antes dos olhos)
	if mut and mut.tamanho then
		-- brilho leve para destacar o tamanho diferente
		local aura = Instance.new("ParticleEmitter")
		aura.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		aura.Color = ColorSequence.new(mut.cor, Color3.new(1, 1, 1))
		aura.Rate = 5
		aura.Lifetime = NumberRange.new(0.8, 1.4)
		aura.Speed = NumberRange.new(1, 2)
		aura.SpreadAngle = Vector2.new(180, 180)
		aura.Size = NumberSequence.new(0.4 * e, 0)
		aura.LightEmission = 1
		aura.Parent = corpo
	elseif mut then
		local arco = {
			Color3.fromRGB(255, 70, 70),
			Color3.fromRGB(255, 170, 50),
			Color3.fromRGB(255, 240, 60),
			Color3.fromRGB(80, 230, 90),
			Color3.fromRGB(60, 170, 255),
			Color3.fromRGB(170, 90, 255),
		}
		local i = 0
		for _, parte in modelo:GetDescendants() do
			if parte:IsA("BasePart") and parte.Name ~= "Aro" then
				i += 1
				parte.Material = (Enum.Material :: any)[mut.material]
				if mut.id == "arcoiris" then
					parte.Color = arco[(i - 1) % #arco + 1]
				else
					parte.Color = parte.Color:Lerp(mut.cor, 0.7)
				end
				if mut.id == "diamante" then
					parte.Reflectance = 0.35
					parte.Transparency = 0.1
				end
			end
		end
		local aura = Instance.new("ParticleEmitter")
		aura.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		aura.Color = ColorSequence.new(mut.cor, Color3.new(1, 1, 1))
		aura.Rate = 10
		aura.Lifetime = NumberRange.new(0.8, 1.4)
		aura.Speed = NumberRange.new(1.5, 3)
		aura.SpreadAngle = Vector2.new(180, 180)
		aura.Size = NumberSequence.new(0.5, 0)
		aura.LightEmission = 1
		aura.Parent = corpo
		-- mutações de clima ganham enfeite próprio
		if mut.id == "acucarada" then
			-- granulado colorido espalhado pelo corpo
			local granulado = {
				Color3.fromRGB(255, 90, 90),
				Color3.fromRGB(255, 230, 80),
				Color3.fromRGB(90, 220, 255),
				Color3.fromRGB(140, 255, 120),
				Color3.new(1, 1, 1),
			}
			for k = 1, 22 do
				local g = Instance.new("Part")
				g.Name = "Granulado"
				g.Shape = Enum.PartType.Cylinder
				g.Size = Vector3.new(0.6, 0.2, 0.2) * e
				g.Color = granulado[(k - 1) % #granulado + 1]
				g.Material = Enum.Material.SmoothPlastic
				g.CanCollide = false
				g.Massless = true
				local dir = Vector3.new(
					math.cos(k * 2.4) * math.sin(0.4 + k * 0.17),
					math.cos(0.4 + k * 0.17),
					math.sin(k * 2.4) * math.sin(0.4 + k * 0.17)
				).Unit
				local ponto = dir * Vector3.new(corpo.Size.X / 2, corpo.Size.Y / 2, corpo.Size.Z / 2) * 0.97
				g.CFrame = corpo.CFrame * CFrame.lookAt(ponto, ponto * 2) * CFrame.Angles(0, 0, k)
				g.Parent = modelo
				soldar(corpo, g)
			end
		elseif mut.id == "estelar" then
			-- estrelinhas brilhando em volta
			for k = 1, 3 do
				local estrela = Instance.new("Part")
				estrela.Name = "Estrela"
				estrela.Shape = Enum.PartType.Ball
				estrela.Size = Vector3.one * 0.55 * e
				estrela.Color = Color3.fromRGB(255, 250, 200)
				estrela.Material = Enum.Material.Neon
				estrela.CanCollide = false
				estrela.Massless = true
				local ang = k * math.pi * 2 / 3
				estrela.CFrame = corpo.CFrame
					* CFrame.new(math.cos(ang) * 2.3 * e, 0.6 * e + k * 0.25 * e, math.sin(ang) * 2.3 * e)
				estrela.Parent = modelo
				soldar(corpo, estrela)
			end
			local poeira = Instance.new("ParticleEmitter")
			poeira.Texture = "rbxasset://textures/particles/sparkles_main.dds"
			poeira.Color = ColorSequence.new(Color3.fromRGB(180, 160, 255), Color3.fromRGB(255, 250, 200))
			poeira.Rate = 6
			poeira.Lifetime = NumberRange.new(1.5, 2.5)
			poeira.Speed = NumberRange.new(0.3, 0.8)
			poeira.Size = NumberSequence.new(0.8, 0)
			poeira.LightEmission = 1
			poeira.Parent = corpo
		end
	end

	rosto(modelo, corpo, e, if nivel >= 3 then raridade.cor else nil)
	enfeites(modelo, corpo, e, nivel, raridade.cor)

	if def.raridade ~= "comum" then
		local brilho = Instance.new("PointLight")
		brilho.Color = raridade.cor
		brilho.Range = 6 + escala * 4
		brilho.Brightness = 1.5
		brilho.Parent = corpo
	end
	if def.raridade == "mitico" or def.raridade == "secreto" or def.raridade == "lendario" then
		local brilhinhos = Instance.new("ParticleEmitter")
		brilhinhos.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		brilhinhos.Color = ColorSequence.new(raridade.cor)
		brilhinhos.Rate = 6
		brilhinhos.Lifetime = NumberRange.new(1, 1.6)
		brilhinhos.Speed = NumberRange.new(1, 2)
		brilhinhos.Size = NumberSequence.new(0.4)
		brilhinhos.Parent = corpo
	end

	-- a placa fica acima da peça mais alta (fantasia, coroa ou auréola)
	local topoModelo = 0
	for _, p in modelo:GetDescendants() do
		if p:IsA("BasePart") then
			topoModelo = math.max(topoModelo, corpo.CFrame:PointToObjectSpace(p.Position).Y + p.Size.Y / 2)
		end
	end
	local alturaPlaca = math.max(corpo.Size.Y / 2 + 3.2 * escala, topoModelo + 2)
	placa(corpo, {
		{ texto = def.nome, cor = Color3.new(1, 1, 1), tamanho = 26 },
		{
			texto = if mut then raridade.nome .. " · " .. mut.nome .. " x" .. mut.multiplicador else raridade.nome,
			cor = if mut then mut.cor else raridade.cor,
			tamanho = 22,
		},
		{ texto = "+" .. Util.numero(def.renda) .. "/s", cor = Color3.fromRGB(120, 255, 120), tamanho = 22 },
	}, alturaPlaca)

	return modelo
end

-- Move o ovo junto com os enfeites. Fora do workspace a solda ainda não
-- arrasta as peças, então movemos cada uma mantendo a posição relativa.
function Criaturas.moverOvo(ovo: BasePart, cf: CFrame)
	local delta = cf * ovo.CFrame:Inverse()
	for _, p in ovo:GetDescendants() do
		if p:IsA("BasePart") then
			p.CFrame = delta * p.CFrame
		end
	end
	ovo.CFrame = cf
end

-- Cria um ovo da raridade dada. Ovos lendários para cima são dourados.
function Criaturas.ovo(raridade: string): BasePart
	local info = Config.Raridades[raridade]
	local ovo = Instance.new("Part")
	ovo.Name = "Ovo"
	oval(ovo)
	ovo.Size = Vector3.new(2.2, 2.8, 2.2) * (0.85 + info.tamanho * 0.25)
	-- o ovo comum é cinza; fica bem mais bonito como ovo de páscoa creme
	local corFaixa = info.cor:Lerp(Color3.new(0, 0, 0), 0.3)
	local corBolinha = info.cor:Lerp(Color3.new(1, 1, 1), 0.75)
	if raridade == "comum" then
		ovo.Color = Color3.fromRGB(255, 240, 215)
		corFaixa = Color3.fromRGB(120, 205, 120)
		corBolinha = Color3.fromRGB(255, 170, 90)
	else
		ovo.Color = info.cor:Lerp(Color3.new(1, 1, 1), 0.12)
	end
	ovo.Material = Enum.Material.SmoothPlastic
	ovo.Reflectance = 0.08
	ovo.CanCollide = true
	ovo:SetAttribute("Raridade", raridade)

	-- enfeites de ovo de páscoa: faixa no meio, bolinhas e um brilho no topo
	local nivelOvo = table.find(Config.OrdemRaridades, raridade) or 1
	local s = ovo.Size
	local faixa = Instance.new("Part")
	faixa.Shape = Enum.PartType.Cylinder
	faixa.Size = Vector3.new(0.35 * s.Y / 2.8, s.X + 0.06, s.Z + 0.06)
	faixa.Color = corFaixa
	faixa.Material = if nivelOvo >= 4 then Enum.Material.Neon else Enum.Material.SmoothPlastic
	faixa.CanCollide = false
	faixa.CanTouch = false
	faixa.Massless = true
	faixa.CastShadow = false
	faixa.CFrame = ovo.CFrame * CFrame.new(0, -s.Y * 0.04, 0) * CFrame.Angles(0, 0, math.pi / 2)
	faixa.Parent = ovo
	soldar(ovo, faixa)

	local a, b, c = s.X / 2, s.Y / 2, s.Z / 2
	for i = 0, 5 do
		local ang = i * math.pi / 3 + 0.4
		local alt = if i % 2 == 0 then 0.45 else -0.4
		local d = Vector3.new(math.cos(ang), alt, math.sin(ang)).Unit
		local t = 1 / math.sqrt((d.X / a) ^ 2 + (d.Y / b) ^ 2 + (d.Z / c) ^ 2)
		local ponto = d * t
		local normal = Vector3.new(ponto.X / (a * a), ponto.Y / (b * b), ponto.Z / (c * c)).Unit
		local tam = s.X * 0.22
		oval3(
			ovo,
			ovo,
			corBolinha,
			Vector3.new(tam, tam, 0.12),
			Vector3.zero,
			Enum.Material.SmoothPlastic,
			CFrame.lookAt(ponto - normal * 0.03, ponto + normal)
		)
	end
	-- brilho de "plástico novo" no alto, do lado da frente
	local dBrilho = Vector3.new(-0.35, 0.75, -0.55).Unit
	local tB = 1 / math.sqrt((dBrilho.X / a) ^ 2 + (dBrilho.Y / b) ^ 2 + (dBrilho.Z / c) ^ 2)
	local pB = dBrilho * tB
	local nB = Vector3.new(pB.X / (a * a), pB.Y / (b * b), pB.Z / (c * c)).Unit
	local brilho = oval3(
		ovo,
		ovo,
		Color3.new(1, 1, 1),
		Vector3.new(s.X * 0.16, s.X * 0.26, 0.08),
		Vector3.zero,
		Enum.Material.Neon,
		CFrame.lookAt(pB - nB * 0.02, pB + nB)
	)
	brilho.Transparency = 0.25
	brilho.Name = "Brilho"

	local luz = Instance.new("PointLight")
	luz.Color = info.cor
	luz.Range = 8
	luz.Brightness = 2
	luz.Parent = ovo

	-- quanto mais raro, mais o ovo chama atenção: brilhos a partir de épico,
	-- coluna de luz subindo a partir de lendário
	local nivel = table.find(Config.OrdemRaridades, raridade) or 1
	if nivel >= 3 then
		local brilhos = Instance.new("ParticleEmitter")
		brilhos.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		brilhos.Color = ColorSequence.new(info.cor, Color3.new(1, 1, 1))
		brilhos.Size = NumberSequence.new(0.6, 0)
		brilhos.Lifetime = NumberRange.new(0.6, 1.2)
		brilhos.Rate = 6 + nivel * 4
		brilhos.Speed = NumberRange.new(2, 4)
		brilhos.SpreadAngle = Vector2.new(180, 180)
		brilhos.LightEmission = 1
		brilhos.Parent = ovo
		luz.Range = 14
	end
	if nivel >= 4 then
		local coluna = Instance.new("ParticleEmitter")
		coluna.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		coluna.Color = ColorSequence.new(info.cor)
		coluna.Size = NumberSequence.new(2.5, 0.5)
		coluna.Transparency = NumberSequence.new(0.2, 1)
		coluna.Lifetime = NumberRange.new(2, 2.5)
		coluna.Rate = 25
		coluna.Speed = NumberRange.new(14, 18)
		coluna.EmissionDirection = Enum.NormalId.Top
		coluna.SpreadAngle = Vector2.new(3, 3)
		coluna.LightEmission = 1
		coluna.LockedToPart = false
		coluna.Parent = ovo
		luz.Range = 20
		luz.Brightness = 4
	end

	placa(ovo, { { texto = "Ovo " .. info.nome, cor = info.cor, tamanho = 24 } }, 2.6)
	return ovo
end

return Criaturas
