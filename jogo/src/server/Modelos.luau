-- Modelos: monta o visual dos inimigos com peças (estilo chibi de anime).
-- Todos os designs são originais: só a "vibe" de anime ninja é inspirada.

local Modelos = {}

local MADEIRA = Color3.fromRGB(70, 50, 35)
local METAL = Color3.fromRGB(150, 155, 165)
local PRETO = Color3.fromRGB(20, 18, 24)

-- Estilos dos inimigos humanos
local ESTILOS = {
	aprendiz = {
		pele = Color3.fromRGB(255, 220, 190),
		roupa = Color3.fromRGB(80, 150, 90),
		roupa2 = Color3.fromRGB(45, 60, 50),
		cabelo = Color3.fromRGB(70, 45, 30),
		acento = Color3.fromRGB(240, 200, 80),
		olhos = PRETO,
		mascara = false,
		arma = "kunai",
		escala = 0.9,
	},
	bambu = {
		pele = Color3.fromRGB(245, 205, 170),
		roupa = Color3.fromRGB(110, 170, 70),
		roupa2 = Color3.fromRGB(60, 90, 40),
		cabelo = Color3.fromRGB(30, 90, 60),
		acento = Color3.fromRGB(200, 240, 120),
		olhos = PRETO,
		mascara = true,
		arma = "bastao",
		escala = 1,
	},
	sombrinha = {
		pele = Color3.fromRGB(230, 195, 165),
		roupa = Color3.fromRGB(45, 45, 70),
		roupa2 = Color3.fromRGB(25, 25, 40),
		cabelo = Color3.fromRGB(40, 40, 60),
		acento = Color3.fromRGB(120, 200, 255),
		olhos = Color3.fromRGB(120, 200, 255),
		olhosNeon = true,
		mascara = true,
		arma = "espada",
		escala = 1,
	},
	acolito = {
		pele = Color3.fromRGB(215, 225, 205),
		roupa = Color3.fromRGB(90, 60, 130),
		roupa2 = Color3.fromRGB(45, 30, 70),
		cabelo = Color3.fromRGB(20, 20, 25),
		acento = Color3.fromRGB(150, 255, 120),
		olhos = Color3.fromRGB(230, 220, 60),
		olhosNeon = true,
		capuz = Color3.fromRGB(70, 45, 110),
		arma = "kunai",
		escala = 1,
	},
	discipulo = {
		pele = Color3.fromRGB(225, 235, 220),
		roupa = Color3.fromRGB(230, 225, 235),
		roupa2 = Color3.fromRGB(110, 70, 150),
		cabelo = Color3.fromRGB(25, 25, 30),
		cabeloLongo = true,
		acento = Color3.fromRGB(140, 90, 200),
		olhos = Color3.fromRGB(240, 220, 50),
		olhosNeon = true,
		faixa = Color3.fromRGB(140, 90, 200),
		arma = "espada",
		escala = 1.1,
	},
	recruta = {
		pele = Color3.fromRGB(240, 205, 175),
		roupa = Color3.fromRGB(35, 30, 40),
		roupa2 = Color3.fromRGB(20, 18, 25),
		cabelo = Color3.fromRGB(150, 40, 50),
		acento = Color3.fromRGB(230, 60, 70),
		olhos = PRETO,
		manto = Color3.fromRGB(30, 26, 36),
		emblema = Color3.fromRGB(230, 70, 70),
		arma = "kunai",
		escala = 1,
	},
	assassino = {
		pele = Color3.fromRGB(225, 190, 160),
		roupa = Color3.fromRGB(30, 26, 36),
		roupa2 = Color3.fromRGB(15, 14, 20),
		cabelo = Color3.fromRGB(220, 220, 230),
		acento = Color3.fromRGB(255, 90, 60),
		olhos = Color3.fromRGB(255, 80, 60),
		olhosNeon = true,
		mascara = true,
		manto = Color3.fromRGB(28, 24, 34),
		emblema = Color3.fromRGB(255, 90, 60),
		arma = "espada",
		escala = 1.05,
	},
	guardiao = {
		pele = Color3.fromRGB(200, 170, 145),
		roupa = Color3.fromRGB(30, 26, 36),
		roupa2 = Color3.fromRGB(15, 14, 20),
		cabelo = Color3.fromRGB(60, 120, 150),
		acento = Color3.fromRGB(255, 170, 60),
		olhos = Color3.fromRGB(255, 170, 60),
		olhosNeon = true,
		manto = Color3.fromRGB(26, 22, 32),
		emblema = Color3.fromRGB(255, 170, 60),
		arma = "bastao",
		escala = 1.25,
	},
	lordeDor = {
		pele = Color3.fromRGB(235, 225, 230),
		roupa = Color3.fromRGB(20, 16, 28),
		roupa2 = Color3.fromRGB(12, 10, 18),
		cabelo = Color3.fromRGB(225, 225, 245),
		acento = Color3.fromRGB(190, 90, 255),
		olhos = Color3.fromRGB(200, 120, 255),
		olhosEspiral = true,
		manto = Color3.fromRGB(18, 14, 26),
		emblema = Color3.fromRGB(200, 110, 255),
		arma = "espada",
		esferas = true,
		aura = Color3.fromRGB(170, 80, 255),
		escala = 1.9,
	},
}

------------------------------------------------------------------------
-- Peças
------------------------------------------------------------------------
local function peca(modelo, nome, tamanho, cf, cor, material, forma, piscar)
	local p = Instance.new("Part")
	p.Name = nome
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Size = tamanho
	p.CFrame = cf
	p.Color = cor
	p.Material = material or Enum.Material.SmoothPlastic
	if forma then
		p.Shape = forma
	end
	if piscar ~= false and p.Material ~= Enum.Material.Neon then
		p:SetAttribute("CorOriginal", cor)
	end
	p.Parent = modelo
	return p
end

local function cunha(modelo, tamanho, cf, cor)
	local w = Instance.new("WedgePart")
	w.Name = "Cabelo"
	w.Anchored = true
	w.CanCollide = false
	w.CanQuery = false
	w.CanTouch = false
	w.Size = tamanho
	w.CFrame = cf
	w.Color = cor
	w.Material = Enum.Material.SmoothPlastic
	w:SetAttribute("CorOriginal", cor)
	w.Parent = modelo
	return w
end

local function brilho(parte, cor, alcance)
	local luz = Instance.new("PointLight")
	luz.Color = cor
	luz.Range = alcance or 8
	luz.Brightness = 1.5
	luz.Parent = parte
end

local function emblema(parte, cor)
	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Front
	sg.CanvasSize = Vector2.new(100, 100)
	sg.LightInfluence = 0
	sg.Parent = parte
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 1)
	t.Text = "☾"
	t.TextScaled = true
	t.Font = Enum.Font.GothamBlack
	t.TextColor3 = cor
	t.Parent = sg
end

------------------------------------------------------------------------
-- Ninja (humanoide chibi). cf = posição dos pés, olhando para -Z.
------------------------------------------------------------------------
local function ninja(e, cf)
	local m = Instance.new("Model")
	local s = e.escala
	local function at(x, y, z, rot)
		return cf * CFrame.new(x * s, y * s, z * s) * (rot or CFrame.identity)
	end
	local function v(x, y, z)
		return Vector3.new(x * s, y * s, z * s)
	end

	-- Pernas e sapatos
	for _, lado in ipairs({ -1, 1 }) do
		peca(m, "Perna", v(0.85, 1.8, 0.85), at(0.48 * lado, 1.1, 0), e.roupa2)
		peca(m, "Sapato", v(0.95, 0.4, 1.15), at(0.48 * lado, 0.2, -0.1), PRETO)
	end

	-- Tronco, cinto e braços
	local corpo = peca(m, "Corpo", v(2, 2, 1.1), at(0, 3, 0), e.roupa)
	peca(m, "Cinto", v(2.08, 0.32, 1.18), at(0, 2.15, 0), e.acento)
	for _, lado in ipairs({ -1, 1 }) do
		peca(m, "Braco", v(0.75, 1.8, 0.75), at(1.42 * lado, 3, 0, CFrame.Angles(0, 0, 0.18 * lado)), e.roupa)
		peca(m, "Mao", v(0.7, 0.55, 0.7), at(1.6 * lado, 1.95, 0), e.pele)
	end

	-- Manto (Clã do Crepúsculo e chefe)
	if e.manto then
		local manto = peca(m, "Manto", v(2.4, 3.7, 1.3), at(0, 2.55, 0), e.manto, Enum.Material.Fabric)
		peca(m, "Gola", v(2.5, 0.7, 1.45), at(0, 4.05, 0), e.manto, Enum.Material.Fabric)
		peca(m, "Barra", v(2.42, 0.18, 1.32), at(0, 0.78, 0), e.emblema, Enum.Material.Neon)
		peca(m, "Faixa", v(0.18, 3.6, 0.05), at(0.75, 2.6, -0.66), e.emblema, Enum.Material.Neon)
		local placa = peca(m, "Emblema", v(1, 1, 0.05), at(-0.45, 3.2, -0.67), e.manto, Enum.Material.Fabric)
		emblema(placa, e.emblema)
		manto:SetAttribute("CorOriginal", e.manto)
	end

	-- Cabeça grande (chibi)
	local yc = 4.95
	peca(m, "Cabeca", v(1.9, 1.9, 1.9), at(0, yc, 0), e.pele, nil, Enum.PartType.Ball)

	-- Olhos de anime: grandes, com brilhinho branco
	for _, lado in ipairs({ -1, 1 }) do
		local corOlho = e.olhos
		if e.olhosEspiral then
			peca(m, "Olho", v(0.42, 0.42, 0.08), at(0.36 * lado, yc + 0.05, -0.9), corOlho, Enum.Material.Neon)
			peca(m, "Pupila", v(0.2, 0.2, 0.06), at(0.36 * lado, yc + 0.05, -0.95), PRETO, nil, nil, false)
			peca(
				m,
				"Anel",
				v(0.32, 0.32, 0.04),
				at(0.36 * lado, yc + 0.05, -0.93),
				corOlho:Lerp(PRETO, 0.5),
				nil,
				nil,
				false
			)
		else
			local mat = e.olhosNeon and Enum.Material.Neon or Enum.Material.SmoothPlastic
			peca(m, "Olho", v(0.3, 0.46, 0.08), at(0.34 * lado, yc + 0.02, -0.9), corOlho, mat, nil, false)
			peca(
				m,
				"Brilho",
				v(0.11, 0.13, 0.05),
				at(0.3 * lado + 0.05, yc + 0.14, -0.95),
				Color3.new(1, 1, 1),
				Enum.Material.Neon
			)
		end
	end

	-- Máscara ninja cobrindo a boca
	if e.mascara then
		peca(m, "Mascara", v(1.75, 0.65, 0.5), at(0, yc - 0.48, -0.62), e.roupa2)
	end

	-- Faixa na testa (cor própria, sem símbolo)
	if e.faixa then
		peca(m, "FaixaTesta", v(1.98, 0.32, 1.98), at(0, yc + 0.42, 0), e.faixa, Enum.Material.Fabric)
	end

	-- Cabelo / capuz
	if e.capuz then
		peca(m, "Capuz", v(2.15, 2.15, 2.15), at(0, yc + 0.12, 0.28), e.capuz, Enum.Material.Fabric, Enum.PartType.Ball)
		peca(
			m,
			"CapuzPonta",
			v(0.9, 1, 0.9),
			at(0, yc + 1.1, 0.6, CFrame.Angles(-0.5, 0, 0)),
			e.capuz,
			Enum.Material.Fabric
		)
	else
		peca(m, "CabeloBase", v(2, 1.1, 2), at(0, yc + 0.55, 0.12), e.cabelo, nil, Enum.PartType.Ball)
		-- espetos
		local espetos = {
			{ 0, 1.25, 0.2, -0.2, 0 },
			{ 0.6, 1.05, 0.15, -0.1, -0.5 },
			{ -0.6, 1.05, 0.15, -0.1, 0.5 },
			{ 0.35, 0.95, 0.75, 0.5, -0.3 },
			{ -0.35, 0.95, 0.75, 0.5, 0.3 },
			{ 0, 0.8, 0.95, 0.9, 0 },
		}
		for _, sp in ipairs(espetos) do
			cunha(
				m,
				v(0.55, 1.1, 0.85),
				at(sp[1], yc + sp[2], sp[3], CFrame.Angles(sp[4], 0, sp[5]) * CFrame.Angles(0, math.pi, 0)),
				e.cabelo
			)
		end
		-- franja
		for i = -1, 1 do
			cunha(m, v(0.5, 0.6, 0.35), at(i * 0.45, yc + 0.55, -0.8, CFrame.Angles(0.3, 0, 0)), e.cabelo)
		end
		if e.cabeloLongo then
			peca(m, "CabeloLongo", v(1.9, 2.4, 0.5), at(0, yc - 0.9, 0.75), e.cabelo)
		end
	end

	-- Cachecol esvoaçante
	if not e.manto then
		peca(m, "Cachecol", v(1.9, 0.4, 1.3), at(0, 3.95, 0), e.acento, Enum.Material.Fabric)
		peca(
			m,
			"CachecolPonta",
			v(0.5, 0.2, 1.8),
			at(0.5, 3.75, 1.3, CFrame.Angles(0.25, 0.3, 0)),
			e.acento,
			Enum.Material.Fabric
		)
	end

	-- Arma na mão direita
	local mao = at(1.6, 1.95, 0)
	if e.arma == "kunai" then
		peca(m, "Arma", v(0.15, 0.15, 1.2), mao * CFrame.new(0, 0, -0.7 * s), METAL, Enum.Material.Metal)
		peca(m, "Argola", v(0.3, 0.3, 0.12), mao * CFrame.new(0, 0, 0.1 * s), METAL, Enum.Material.Metal)
	elseif e.arma == "espada" then
		peca(m, "Cabo", v(0.2, 0.2, 0.8), mao * CFrame.new(0, 0, 0), MADEIRA)
		peca(m, "Guarda", v(0.6, 0.12, 0.12), mao * CFrame.new(0, 0, -0.45 * s), e.acento, Enum.Material.Metal)
		peca(m, "Lamina", v(0.12, 0.25, 2.6), mao * CFrame.new(0, 0, -1.8 * s), METAL, Enum.Material.Metal)
	elseif e.arma == "bastao" then
		peca(m, "Bastao", v(0.22, 4.2, 0.22), mao * CFrame.new(0, 0.8 * s, 0), Color3.fromRGB(150, 190, 90))
	end

	-- Chefe: esferas flutuando e aura
	if e.esferas then
		for i = 1, 6 do
			local a = (i / 6) * math.pi * 2
			local esf = peca(
				m,
				"Esfera",
				v(0.6, 0.6, 0.6),
				at(math.cos(a) * 2.4, 4.2 + math.sin(a * 2) * 0.4, math.sin(a) * 2.4),
				e.acento,
				Enum.Material.Neon,
				Enum.PartType.Ball
			)
			if i % 2 == 0 then
				brilho(esf, e.acento, 10)
			end
		end
	end
	if e.aura then
		local fx = Instance.new("ParticleEmitter")
		fx.Color = ColorSequence.new(e.aura)
		fx.LightEmission = 1
		fx.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 0) })
		fx.Transparency = NumberSequence.new(0.3, 1)
		fx.Lifetime = NumberRange.new(0.8, 1.4)
		fx.Rate = 30
		fx.Speed = NumberRange.new(1, 3)
		fx.SpreadAngle = Vector2.new(180, 180)
		fx.Acceleration = Vector3.new(0, 4, 0)
		fx.Parent = corpo
		brilho(corpo, e.aura, 16)
	end

	m.PrimaryPart = corpo
	return m, corpo, 6 * s
end

------------------------------------------------------------------------
-- Serpente gigante
------------------------------------------------------------------------
local function serpente(cf)
	local m = Instance.new("Model")
	local cor = Color3.fromRGB(120, 70, 170)
	local barriga = Color3.fromRGB(220, 200, 140)
	local corpo
	local n = 9
	for i = 1, n do
		local t = i / n
		local r = 0.9 + t * 1.1
		local x = math.sin(t * math.pi * 2) * 1.6
		local y = r * 0.6 + t * t * 2.8
		local z = (1 - t) * 6 - 1
		local seg = peca(
			m,
			"Segmento",
			Vector3.new(r * 2, r * 2, r * 2),
			cf * CFrame.new(x, y, z),
			cor,
			nil,
			Enum.PartType.Ball
		)
		if i % 2 == 0 then
			peca(
				m,
				"Escama",
				Vector3.new(r * 1.3, r * 0.6, r * 1.3),
				cf * CFrame.new(x, y - r * 0.6, z),
				barriga,
				nil,
				Enum.PartType.Ball
			)
		end
		if i == n - 2 then
			corpo = seg
		end
	end
	local cabeca = cf * CFrame.new(math.sin(math.pi * 2) * 1.6, 5.2, -1.4)
	peca(m, "Cabeca", Vector3.new(2.6, 1.8, 3), cabeca, cor, nil, Enum.PartType.Ball)
	peca(m, "Focinho", Vector3.new(1.8, 1, 1.4), cabeca * CFrame.new(0, -0.2, -1.3), cor)
	for _, lado in ipairs({ -1, 1 }) do
		peca(
			m,
			"Olho",
			Vector3.new(0.45, 0.6, 0.2),
			cabeca * CFrame.new(0.75 * lado, 0.45, -1.2),
			Color3.fromRGB(250, 220, 40),
			Enum.Material.Neon
		)
		peca(
			m,
			"Fenda",
			Vector3.new(0.1, 0.5, 0.1),
			cabeca * CFrame.new(0.75 * lado, 0.45, -1.32),
			PRETO,
			nil,
			nil,
			false
		)
	end
	peca(
		m,
		"Lingua",
		Vector3.new(0.18, 0.1, 1.2),
		cabeca * CFrame.new(0, -0.45, -2.4),
		Color3.fromRGB(230, 50, 70),
		Enum.Material.Neon
	)
	m.PrimaryPart = corpo
	return m, corpo, 7
end

------------------------------------------------------------------------
-- Personagens 3D da pasta ReplicatedStorage.Arte.Inimigos (salvos no lugar/JogoAnime.rbxl)
------------------------------------------------------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Animação de "respirar" parado (animações padrão do próprio Roblox)
local ANIM_PARADO = {
	[Enum.HumanoidRigType.R6] = "rbxassetid://180435571",
	[Enum.HumanoidRigType.R15] = "rbxassetid://507766666",
}

-- escala = tamanho; giro = graus extras para virar de frente; cor = cor da explosão ao morrer
local AJUSTES = {
	novato = { escala = 1, cor = Color3.fromRGB(80, 80, 90) },
	mascarado = { escala = 1, cor = Color3.fromRGB(220, 220, 230) },
	elite = { escala = 1.05, cor = Color3.fromRGB(80, 120, 200), elite = true },
	discipulo = { escala = 1.05, cor = Color3.fromRGB(150, 100, 210) },
	cloneDoro = { escala = 1.05, cor = Color3.fromRGB(120, 200, 120) },
	dorochimaru = {
		escala = 1.2,
		cor = Color3.fromRGB(150, 90, 220),
		aura = Color3.fromRGB(120, 220, 120),
		elite = true,
	},
	recrutaKatsuki = { escala = 1.05, cor = Color3.fromRGB(220, 60, 70) },
	itachu = { escala = 1.1, cor = Color3.fromRGB(230, 50, 60), elite = true },
	caminhoPen = { escala = 1.15, cor = Color3.fromRGB(240, 140, 60), elite = true },
	pen = { escala = 1.6, cor = Color3.fromRGB(190, 90, 255), aura = Color3.fromRGB(180, 90, 255) },
	-- chefe final do Ato 3 (armadura vermelha, aura de chama escura)
	madaro = { escala = 1.6, cor = Color3.fromRGB(200, 30, 40), aura = Color3.fromRGB(255, 60, 40) },
}
-- enquanto a arte de um chefe novo não chega, usa o boneco de outro (com o tamanho/aura do novo)
local RESERVA = { madaro = "itachu" }

local function aura(raiz, cor)
	local fx = Instance.new("ParticleEmitter")
	fx.Color = ColorSequence.new(cor)
	fx.LightEmission = 1
	fx.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.9), NumberSequenceKeypoint.new(1, 0) })
	fx.Transparency = NumberSequence.new(0.3, 1)
	fx.Lifetime = NumberRange.new(0.8, 1.4)
	fx.Rate = 35
	fx.Speed = NumberRange.new(1, 3)
	fx.SpreadAngle = Vector2.new(180, 180)
	fx.Acceleration = Vector3.new(0, 4, 0)
	fx.Parent = raiz
	brilho(raiz, cor, 18)
end

local function deArte(nomeModelo, cf)
	local arte = ReplicatedStorage:FindFirstChild("Arte")
	local pasta = arte and arte:FindFirstChild("Inimigos")
	local original = pasta and (pasta:FindFirstChild(nomeModelo) or pasta:FindFirstChild(RESERVA[nomeModelo] or ""))
	if not original then
		return nil
	end
	local aj = AJUSTES[nomeModelo] or {}
	local m = original:Clone()
	local hum = m:FindFirstChildWhichIsA("Humanoid", true)
	local raiz = m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart", true)
	m.PrimaryPart = raiz

	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") then
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
			d.Massless = true
			d.Anchored = (d == raiz) or not hum -- só a raiz fica presa; o resto mexe com a animação
		end
	end
	if hum then
		hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
		hum.BreakJointsOnDeath = false
		hum.RequiresNeck = false
	end

	if aj.escala and aj.escala ~= 1 then
		m:ScaleTo(m:GetScale() * aj.escala)
	end

	-- vira de frente para onde o cf olha e apoia os pés no chão
	local desvio = raiz.CFrame:ToObjectSpace(m:GetPivot())
	local alvoRaiz = CFrame.new(cf.Position) * cf.Rotation * CFrame.Angles(0, math.rad(aj.giro or 0), 0)
	m:PivotTo(alvoRaiz * desvio)
	local caixa, tam = m:GetBoundingBox()
	local fundo = caixa.Position.Y - tam.Y / 2
	m:PivotTo(m:GetPivot() + Vector3.new(0, cf.Position.Y - fundo, 0))

	raiz:SetAttribute("CorOriginal", aj.cor or Color3.new(1, 1, 1))
	if aj.aura then
		aura(raiz, aj.aura)
		local contornoAura = Instance.new("Highlight")
		contornoAura.Name = "Aura"
		contornoAura.FillTransparency = 1
		contornoAura.OutlineColor = aj.aura
		contornoAura.OutlineTransparency = 0.2
		contornoAura.Parent = m
	end
	m:SetAttribute("UsaArte", true)
	m:SetAttribute("Escala", m:GetScale())
	if aj.elite then
		m:SetAttribute("Elite", true) -- pose ameaçadora e rugido (AnimInimigos, no cliente)
	end
	return m, raiz, tam.Y, hum
end

-- Animação de golpe (animações padrão do Roblox de atacar com arma)
local ANIM_ATAQUE = {
	[Enum.HumanoidRigType.R6] = "rbxassetid://129967390",
	[Enum.HumanoidRigType.R15] = "rbxassetid://522635514",
}
local faixasAtaque = setmetatable({}, { __mode = "k" })

-- Corrida dos inimigos (mapa linear: eles correm até o herói)
local ANIM_CORRER = {
	[Enum.HumanoidRigType.R6] = "rbxassetid://180426354",
	[Enum.HumanoidRigType.R15] = "rbxassetid://507767714",
}
local faixasCorrer = setmetatable({}, { __mode = "k" })

function Modelos.andar(m, correndo)
	if (m:GetAttribute("Correndo") == true) == correndo then
		return
	end
	m:SetAttribute("Correndo", correndo)
	local hum = m:FindFirstChildWhichIsA("Humanoid", true)
	local animador = hum and hum:FindFirstChildOfClass("Animator")
	if not animador then
		return
	end
	local faixa = faixasCorrer[m]
	if not faixa then
		local anim = Instance.new("Animation")
		anim.AnimationId = ANIM_CORRER[hum.RigType] or ANIM_CORRER[Enum.HumanoidRigType.R6]
		local ok, f = pcall(function()
			return animador:LoadAnimation(anim)
		end)
		if not ok or not f then
			return
		end
		faixa = f
		faixa.Looped = true
		faixa.Priority = Enum.AnimationPriority.Movement
		faixasCorrer[m] = faixa
	end
	if correndo then
		faixa:Play(0.15, 1, 1.25)
	else
		faixa:Stop(0.2)
	end
end

function Modelos.atacar(m)
	-- avisa a tela do jogador para tocar o bote (preparar e avançar) por cima da animação
	m:SetAttribute("Ataque", (m:GetAttribute("Ataque") or 0) + 1)
	local hum = m:FindFirstChildWhichIsA("Humanoid", true)
	local animador = hum and hum:FindFirstChildOfClass("Animator")
	if not animador then
		return
	end
	local faixa = faixasAtaque[m]
	if not faixa then
		local anim = Instance.new("Animation")
		anim.AnimationId = ANIM_ATAQUE[hum.RigType] or ANIM_ATAQUE[Enum.HumanoidRigType.R6]
		local ok, f = pcall(function()
			return animador:LoadAnimation(anim)
		end)
		if not ok or not f then
			return
		end
		faixa = f
		faixa.Priority = Enum.AnimationPriority.Action
		faixasAtaque[m] = faixa
	end
	faixa:Play(0.05, 1, 1.3)
end

-- Alguns bonecos R6 da pasta Arte vieram "estátua" (sem juntas). Criamos as juntas padrão do R6
-- para eles poderem respirar, correr, atacar e fazer as poses do AnimInimigos.
local JUNTAS_R6 = {
	-- nome, peça0, peça1, C0 (para tronco 2x2x1)
	{ "RootJoint", "HumanoidRootPart", "Torso", CFrame.new(0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0) },
	{ "Neck", "Torso", "Head", CFrame.new(0, 1, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0) },
	{ "Right Shoulder", "Torso", "Right Arm", CFrame.new(1, 0.5, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0) },
	{ "Left Shoulder", "Torso", "Left Arm", CFrame.new(-1, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0) },
	{ "Right Hip", "Torso", "Right Leg", CFrame.new(1, -1, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0) },
	{ "Left Hip", "Torso", "Left Leg", CFrame.new(-1, -1, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0) },
}
local function criarJuntasR6(m, hum)
	if hum.RigType ~= Enum.HumanoidRigType.R6 or m:FindFirstChildWhichIsA("Motor6D", true) then
		return
	end
	local pecas = {}
	for _, j in ipairs(JUNTAS_R6) do
		for _, nome in ipairs({ j[2], j[3] }) do
			local p = pecas[nome] or m:FindFirstChild(nome, true)
			if not p or not p:IsA("BasePart") then
				return -- não é um R6 completo: deixa como está
			end
			pecas[nome] = p
		end
	end
	local corpo = {}
	for _, p in pairs(pecas) do
		corpo[p] = true
	end
	-- tira soldas antigas entre partes do corpo (senão os membros ficam presos)
	for _, d in ipairs(m:GetDescendants()) do
		if (d:IsA("JointInstance") or d:IsA("WeldConstraint")) and corpo[d.Part0] and corpo[d.Part1] then
			d:Destroy()
		end
	end
	local tronco = pecas.Torso
	local fator = tronco.Size / Vector3.new(2, 2, 1)
	for _, j in ipairs(JUNTAS_R6) do
		local p0, p1 = pecas[j[2]], pecas[j[3]]
		local c0 = CFrame.new(j[4].Position * (p0 == tronco and fator or Vector3.one)) * j[4].Rotation
		if p0.Name == "HumanoidRootPart" then
			c0 = CFrame.new(p0.CFrame:PointToObjectSpace(tronco.Position)) * j[4].Rotation
		end
		local motor = Instance.new("Motor6D")
		motor.Name = j[1]
		motor.Part0 = p0
		motor.Part1 = p1
		motor.C0 = c0
		motor.C1 = p1.CFrame:ToObjectSpace(p0.CFrame * c0) -- mantém o membro onde já estava
		motor.Parent = p0
	end
end

-- Toca a animação de "respirar" depois que o modelo já está no mundo
function Modelos.animar(m)
	local hum = m:FindFirstChildWhichIsA("Humanoid", true)
	if not hum then
		return
	end
	criarJuntasR6(m, hum)
	-- Acessórios (cabelo, máscara...) sem solda caem quando o boneco se mexe: prende cada peça solta.
	-- Precisa rodar com o modelo já no mundo (antes disso o Roblox não informa as ligações).
	local raiz = m.PrimaryPart
	local cabeca = m:FindFirstChild("Head")
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") and d ~= raiz and not d.Anchored and #d:GetJoints() == 0 then
			local w = Instance.new("WeldConstraint")
			w.Part0 = (d.Parent and d.Parent:IsA("Accessory") and cabeca) or raiz
			w.Part1 = d
			w.Parent = d
		end
	end
	local animador = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator")
	animador.Parent = hum
	local anim = Instance.new("Animation")
	anim.AnimationId = ANIM_PARADO[hum.RigType] or ANIM_PARADO[Enum.HumanoidRigType.R6]
	local ok, faixa = pcall(function()
		return animador:LoadAnimation(anim)
	end)
	if ok and faixa then
		faixa.Looped = true
		faixa:Play(0.2, 1, 0.8 + math.random() * 0.4)
	end
end

------------------------------------------------------------------------
-- Cria o inimigo da fase. Retorna: modelo, peça principal, altura total.
-- Usa o personagem 3D da pasta Arte; se não achar, monta com peças.
------------------------------------------------------------------------
function Modelos.criar(nomeModelo, cf)
	local m, raiz, altura = deArte(nomeModelo, cf)
	if m then
		return m, raiz, altura
	end
	if nomeModelo == "serpente" then
		return serpente(cf)
	end
	return ninja(ESTILOS[nomeModelo] or ESTILOS.aprendiz, cf)
end

------------------------------------------------------------------------
-- Baú especial do chefe
------------------------------------------------------------------------
function Modelos.bau(cf)
	local m = Instance.new("Model")
	m.Name = "BauDoChefe"
	local ouro = Color3.fromRGB(255, 200, 60)
	local caixa = peca(
		m,
		"Caixa",
		Vector3.new(3.2, 2, 2.2),
		cf * CFrame.new(0, 1, 0),
		Color3.fromRGB(120, 60, 160),
		Enum.Material.Wood
	)
	peca(m, "Faixa", Vector3.new(3.3, 0.3, 2.3), cf * CFrame.new(0, 1.4, 0), ouro, Enum.Material.Metal)
	peca(m, "Fecho", Vector3.new(0.5, 0.6, 0.2), cf * CFrame.new(0, 1.6, -1.15), ouro, Enum.Material.Neon)
	local tampa = peca(
		m,
		"Tampa",
		Vector3.new(3.3, 0.8, 2.3),
		cf * CFrame.new(0, 2.4, 0),
		Color3.fromRGB(140, 70, 180),
		Enum.Material.Wood
	)
	brilho(caixa, ouro, 14)
	local fx = Instance.new("ParticleEmitter")
	fx.Color = ColorSequence.new(ouro)
	fx.LightEmission = 1
	fx.Size = NumberSequence.new(0.4, 0)
	fx.Lifetime = NumberRange.new(0.6, 1.2)
	fx.Rate = 40
	fx.Speed = NumberRange.new(4, 9)
	fx.SpreadAngle = Vector2.new(35, 35)
	fx.EmissionDirection = Enum.NormalId.Top
	fx.Parent = caixa
	m.PrimaryPart = caixa
	return m, tampa
end

return Modelos
