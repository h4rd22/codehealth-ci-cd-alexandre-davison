-- Cenario: arena, decoração e iluminação de cada tema do mundo 1.
-- Temas: "vila" (1-1 a 1-3), "pantano" (1-4 a 1-6), "crepusculo" (1-7 a 1-9), "chefe" (1-10).

local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local Cenario = {}

local chao, pastaDecor
local alturaChao, raio = 0, 24
local temaAtual = nil

------------------------------------------------------------------------
-- Ajudantes
------------------------------------------------------------------------
local function peca(pai, tamanho, cf, cor, material, forma)
	local p = Instance.new("Part")
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
	p.Parent = pai
	return p
end

local function luz(parte, cor, alcance, forca)
	local l = Instance.new("PointLight")
	l.Color = cor
	l.Range = alcance or 12
	l.Brightness = forca or 2
	l.Shadows = false
	l.Parent = parte
end

local function noAnel(angulo, r, y)
	return CFrame.new(math.cos(angulo) * r, alturaChao + (y or 0), math.sin(angulo) * r)
		* CFrame.Angles(0, -angulo + math.pi / 2, 0)
end

local function particulas(parte, props)
	local fx = Instance.new("ParticleEmitter")
	for k, val in pairs(props) do
		fx[k] = val
	end
	fx.Parent = parte
	return fx
end

------------------------------------------------------------------------
-- Iluminação estilo anime (cores saturadas, brilho suave)
------------------------------------------------------------------------
local function efeito(classe)
	local e = Lighting:FindFirstChildOfClass(classe)
	if not e then
		e = Instance.new(classe)
		e.Parent = Lighting
	end
	return e
end

local LUZES = {
	vila = {
		ClockTime = 14.5,
		Brightness = 3,
		Ambient = Color3.fromRGB(120, 115, 130),
		OutdoorAmbient = Color3.fromRGB(160, 155, 170),
		atm = {
			Density = 0.28,
			Color = Color3.fromRGB(205, 225, 255),
			Decay = Color3.fromRGB(110, 150, 200),
			Haze = 1,
			Glare = 0.2,
		},
		cor = { Saturation = 0.3, Contrast = 0.08, Brightness = 0.02, TintColor = Color3.fromRGB(255, 250, 245) },
		bloom = { Intensity = 0.5, Size = 24, Threshold = 1.3 },
		chao = { Color3.fromRGB(110, 175, 80), Enum.Material.Grass },
		fundo = Color3.fromRGB(95, 140, 70),
		nuvens = { Cover = 0.5, Density = 0.7, Color = Color3.fromRGB(255, 255, 255) },
		terreno = {
			Grass = Color3.fromRGB(96, 160, 72),
			LeafyGrass = Color3.fromRGB(78, 148, 60),
			Rock = Color3.fromRGB(112, 128, 150),
			Snow = Color3.fromRGB(240, 246, 255),
			Ground = Color3.fromRGB(112, 92, 70),
		},
	},
	pantano = {
		ClockTime = 16.4,
		Brightness = 2.4,
		Ambient = Color3.fromRGB(118, 104, 140),
		OutdoorAmbient = Color3.fromRGB(140, 126, 165),
		atm = {
			Density = 0.34,
			Color = Color3.fromRGB(176, 160, 215),
			Decay = Color3.fromRGB(92, 124, 108),
			Haze = 1.6,
			Glare = 0.15,
		},
		cor = { Saturation = 0.28, Contrast = 0.1, Brightness = 0.04, TintColor = Color3.fromRGB(238, 232, 255) },
		bloom = { Intensity = 0.8, Size = 28, Threshold = 1.1 },
		chao = { Color3.fromRGB(92, 120, 76), Enum.Material.Mud },
		fundo = Color3.fromRGB(52, 70, 56),
		nuvens = { Cover = 0.62, Density = 0.55, Color = Color3.fromRGB(190, 175, 215) },
		terreno = {
			Grass = Color3.fromRGB(78, 112, 70),
			LeafyGrass = Color3.fromRGB(66, 100, 66),
			Rock = Color3.fromRGB(96, 102, 116),
			Snow = Color3.fromRGB(200, 214, 230),
			Ground = Color3.fromRGB(84, 74, 60),
		},
	},
	crepusculo = {
		ClockTime = 17.4,
		Brightness = 2.6,
		Ambient = Color3.fromRGB(128, 100, 98),
		OutdoorAmbient = Color3.fromRGB(172, 132, 118),
		atm = {
			Density = 0.3,
			Color = Color3.fromRGB(255, 196, 150),
			Decay = Color3.fromRGB(160, 96, 120),
			Haze = 1.2,
			Glare = 0.35,
		},
		cor = { Saturation = 0.25, Contrast = 0.08, Brightness = 0.02, TintColor = Color3.fromRGB(255, 240, 228) },
		bloom = { Intensity = 0.7, Size = 26, Threshold = 1.15 },
		chao = { Color3.fromRGB(176, 140, 96), Enum.Material.Ground },
		fundo = Color3.fromRGB(110, 80, 55),
		nuvens = { Cover = 0.55, Density = 0.6, Color = Color3.fromRGB(255, 196, 170) },
		terreno = {
			Grass = Color3.fromRGB(176, 136, 72),
			LeafyGrass = Color3.fromRGB(160, 112, 60),
			Rock = Color3.fromRGB(128, 104, 112),
			Snow = Color3.fromRGB(255, 222, 205),
			Ground = Color3.fromRGB(128, 92, 66),
		},
	},
	chefe = {
		ClockTime = 0.4,
		Brightness = 1.8,
		Ambient = Color3.fromRGB(112, 86, 152),
		OutdoorAmbient = Color3.fromRGB(128, 98, 172),
		atm = {
			Density = 0.5,
			Color = Color3.fromRGB(100, 70, 150),
			Decay = Color3.fromRGB(35, 15, 60),
			Haze = 2.5,
			Glare = 0,
		},
		cor = { Saturation = 0.25, Contrast = 0.15, Brightness = 0.05, TintColor = Color3.fromRGB(232, 218, 255) },
		bloom = { Intensity = 0.65, Size = 28, Threshold = 1.2 },
		chao = { Color3.fromRGB(55, 45, 70), Enum.Material.Basalt },
		fundo = Color3.fromRGB(25, 20, 35),
		nuvens = { Cover = 0.75, Density = 0.8, Color = Color3.fromRGB(90, 60, 130) },
		terreno = {
			Grass = Color3.fromRGB(56, 46, 72),
			LeafyGrass = Color3.fromRGB(50, 40, 66),
			Rock = Color3.fromRGB(52, 42, 62),
			Snow = Color3.fromRGB(160, 125, 210),
			Ground = Color3.fromRGB(42, 34, 52),
		},
	},
}

local function aplicarLuz(tema, baseplate)
	local c = LUZES[tema]
	local info = TweenInfo.new(1.2)
	TweenService:Create(Lighting, info, {
		ClockTime = c.ClockTime,
		Brightness = c.Brightness,
		Ambient = c.Ambient,
		OutdoorAmbient = c.OutdoorAmbient,
	}):Play()
	Lighting.GlobalShadows = true
	Lighting.EnvironmentDiffuseScale = 0.6
	Lighting.EnvironmentSpecularScale = 0.6
	TweenService:Create(efeito("Atmosphere"), info, c.atm):Play()
	TweenService:Create(efeito("ColorCorrectionEffect"), info, c.cor):Play()
	TweenService:Create(efeito("BloomEffect"), info, c.bloom):Play()
	local raios = efeito("SunRaysEffect")
	raios.Intensity = 0.06
	raios.Spread = 0.6
	chao.Material = c.chao[2]
	TweenService:Create(chao, info, { Color = c.chao[1] }):Play()
	if baseplate then
		TweenService:Create(baseplate, info, { Color = c.fundo }):Play()
	end
	local terreno = workspace.Terrain
	local nuvens = terreno:FindFirstChildOfClass("Clouds")
	if not nuvens then
		nuvens = Instance.new("Clouds")
		nuvens.Parent = terreno
	end
	TweenService:Create(nuvens, info, c.nuvens):Play()
	for material, cor in pairs(c.terreno) do
		terreno:SetMaterialColor(Enum.Material[material], cor)
	end
end

-- Mapa fechado: chão de terreno até longe e um anel de montanhas enormes em volta
local function gerarMontanhas()
	local terreno = workspace.Terrain
	terreno:Clear()
	-- chão em volta da arena (logo abaixo dela)
	terreno:FillCylinder(CFrame.new(0, alturaChao - 2, 0), 4, 150, Enum.Material.Grass)
	-- dentro da arena o chão é a peça redonda (sem grama alta escondendo os pés)
	terreno:FillCylinder(CFrame.new(0, alturaChao - 2, 0), 6, raio + 1.5, Enum.Material.Air)
	-- morrinhos de grama entre a vila e as montanhas
	local aleatorio = Random.new(7)
	for i = 1, 30 do
		local a = (i / 30) * math.pi * 2 + aleatorio:NextNumber(-0.1, 0.1)
		local r = 60 + aleatorio:NextNumber(-4, 6)
		local tam = aleatorio:NextNumber(10, 16)
		terreno:FillBall(
			Vector3.new(math.cos(a) * r, alturaChao - tam * 0.45, math.sin(a) * r),
			tam,
			Enum.Material.LeafyGrass
		)
	end
	-- montanhas de rocha (dois anéis para dar profundidade) com neve no topo
	for anel, cfg in ipairs({ { 30, 84, 16, 24, -4 }, { 26, 118, 26, 36, 6 } }) do
		local n, r0, rmin, rmax, sobe = cfg[1], cfg[2], cfg[3], cfg[4], cfg[5]
		for i = 1, n do
			local a = (i / n) * math.pi * 2 + (anel == 2 and math.pi / n or 0) + aleatorio:NextNumber(-0.06, 0.06)
			local r = r0 + aleatorio:NextNumber(-5, 5)
			local tam = aleatorio:NextNumber(rmin, rmax)
			local centro = Vector3.new(math.cos(a) * r, alturaChao + sobe + tam * 0.25, math.sin(a) * r)
			terreno:FillBall(centro, tam, Enum.Material.Rock)
			if tam > rmin + (rmax - rmin) * 0.45 then
				terreno:FillBall(centro + Vector3.new(0, tam * 0.78, 0), tam * 0.38, Enum.Material.Snow)
			end
		end
	end
end

------------------------------------------------------------------------
-- Decoração de cada tema
------------------------------------------------------------------------
local decor = {}

-- Vila Oculta do Bambu: casinhas, bambus, cerejeiras com pétalas, portal de madeira
function decor.vila(p)
	local madeira = Color3.fromRGB(200, 160, 110)
	-- Cerquinha de bambu na borda da arena
	for i = 1, 36 do
		local a = (i / 36) * math.pi * 2
		peca(
			p,
			Vector3.new(1.6, 0.5, 0.5),
			noAnel(a, raio + 0.6, 1.8),
			Color3.fromRGB(150, 190, 90),
			Enum.Material.Wood,
			Enum.PartType.Cylinder
		).CFrame = noAnel(
			a,
			raio + 0.6,
			1.8
		) * CFrame.Angles(0, 0, math.pi / 2)
	end
	-- Casinhas com telhado
	local telhados = { Color3.fromRGB(200, 70, 60), Color3.fromRGB(60, 140, 150), Color3.fromRGB(90, 90, 140) }
	for i = 1, 7 do
		local a = math.rad(i * 51 + 20)
		local base = noAnel(a, raio + 11, 2.2)
		peca(p, Vector3.new(7, 4.4, 4.6), base, madeira, Enum.Material.WoodPlanks)
		peca(
			p,
			Vector3.new(7.8, 3.4, 3.4),
			base * CFrame.new(0, 2.2, 0) * CFrame.Angles(math.rad(45), 0, 0),
			telhados[i % 3 + 1],
			Enum.Material.SmoothPlastic
		)
		peca(
			p,
			Vector3.new(1.4, 2.6, 0.2),
			base * CFrame.new(0, -0.9, -2.35),
			Color3.fromRGB(90, 55, 35),
			Enum.Material.Wood
		)
		peca(
			p,
			Vector3.new(1.4, 1.2, 0.2),
			base * CFrame.new(-2.2, 0.4, -2.35),
			Color3.fromRGB(255, 235, 180),
			Enum.Material.Neon
		)
		local lanterna = peca(
			p,
			Vector3.new(0.9, 1.2, 0.9),
			base * CFrame.new(2.4, 0.6, -2.7),
			Color3.fromRGB(255, 120, 70),
			Enum.Material.Neon,
			Enum.PartType.Ball
		)
		luz(lanterna, Color3.fromRGB(255, 160, 90), 10, 1.5)
	end
	-- Bambuzais
	for i = 1, 10 do
		local a = math.rad(i * 36 + 5)
		for k = 1, 4 do
			local h = 9 + (k * 37 % 5)
			local off = noAnel(a, raio + 5 + k * 0.9, h / 2) * CFrame.new(k * 0.7 - 1.5, 0, 0)
			peca(p, Vector3.new(0.6, h, 0.6), off, Color3.fromRGB(120, 175, 70), Enum.Material.SmoothPlastic)
			for j = 1, 3 do
				peca(
					p,
					Vector3.new(0.7, 0.15, 0.7),
					off * CFrame.new(0, -h / 2 + j * h / 4, 0),
					Color3.fromRGB(90, 140, 55)
				)
			end
			peca(
				p,
				Vector3.new(1.6, 0.15, 0.6),
				off * CFrame.new(0.6, h / 2 - 0.5, 0) * CFrame.Angles(0, 0, 0.4),
				Color3.fromRGB(100, 190, 80)
			)
		end
	end
	-- Cerejeiras
	for i = 1, 5 do
		local a = math.rad(i * 72 + 40)
		local base = noAnel(a, raio + 6, 0)
		peca(
			p,
			Vector3.new(1.2, 6, 1.2),
			base * CFrame.new(0, 3, 0) * CFrame.Angles(0, 0, 0.08),
			Color3.fromRGB(110, 70, 55),
			Enum.Material.Wood
		)
		local copa
		for j, off in ipairs({
			Vector3.new(0, 7, 0),
			Vector3.new(2, 6.2, 0.5),
			Vector3.new(-1.8, 6.4, -0.6),
			Vector3.new(0.4, 6.3, 1.9),
		}) do
			local bola = peca(
				p,
				Vector3.new(5, 4, 5) * (j == 1 and 1 or 0.75),
				base * CFrame.new(off),
				Color3.fromRGB(255, 175, 205),
				Enum.Material.SmoothPlastic,
				Enum.PartType.Ball
			)
			copa = copa or bola
		end
		particulas(copa, {
			Color = ColorSequence.new(Color3.fromRGB(255, 190, 215)),
			Size = NumberSequence.new(0.25),
			Lifetime = NumberRange.new(5, 8),
			Rate = 4,
			Speed = NumberRange.new(0.5, 1.5),
			SpreadAngle = Vector2.new(180, 180),
			Acceleration = Vector3.new(0.6, -1.2, 0),
			RotSpeed = NumberRange.new(-90, 90),
			Rotation = NumberRange.new(0, 360),
		})
	end
	-- Portal de madeira vermelho no fundo
	local pg = noAnel(math.rad(-90), raio + 4, 0)
	for _, lado in ipairs({ -1, 1 }) do
		peca(
			p,
			Vector3.new(11, 1.3, 1.3),
			pg * CFrame.new(5 * lado, 5.5, 0),
			Color3.fromRGB(205, 55, 45),
			Enum.Material.SmoothPlastic,
			Enum.PartType.Cylinder
		).CFrame = pg
			* CFrame.new(5 * lado, 5.5, 0)
			* CFrame.Angles(0, 0, math.pi / 2)
	end
	peca(p, Vector3.new(14, 1.1, 1.8), pg * CFrame.new(0, 11.3, 0), Color3.fromRGB(35, 30, 35))
	peca(p, Vector3.new(12.5, 0.8, 1.3), pg * CFrame.new(0, 9.4, 0), Color3.fromRGB(205, 55, 45))
end

-- Pântano da Seita da Serpente: árvores mortas, cogumelos brilhantes, estátua de cobra, poças
function decor.pantano(p)
	for i = 1, 26 do
		local a = (i / 26) * math.pi * 2
		local h = 1.2 + (i % 3) * 0.7
		peca(
			p,
			Vector3.new(2.3, h, 2.4),
			noAnel(a, raio + 1, h / 2 + 0.5) * CFrame.Angles(0.1 * (i % 3 - 1), 0, 0.12),
			Color3.fromRGB(60, 70, 55),
			Enum.Material.Rock
		)
	end
	for i = 1, 9 do
		local a = math.rad(i * 40 + 10)
		local base = noAnel(a, raio + 7 + (i % 3) * 2, 0)
		local inc = CFrame.Angles(0.1 * (i % 2 == 0 and 1 or -1), 0, 0.15)
		peca(
			p,
			Vector3.new(1.3, 9, 1.3),
			base * CFrame.new(0, 4.5, 0) * inc,
			Color3.fromRGB(55, 45, 50),
			Enum.Material.Wood
		)
		peca(
			p,
			Vector3.new(0.5, 4, 0.5),
			base * CFrame.new(1, 7, 0) * CFrame.Angles(0, 0, -0.9),
			Color3.fromRGB(55, 45, 50),
			Enum.Material.Wood
		)
		peca(
			p,
			Vector3.new(0.4, 3, 0.4),
			base * CFrame.new(-0.9, 8, 0.3) * CFrame.Angles(0.3, 0, 0.8),
			Color3.fromRGB(55, 45, 50),
			Enum.Material.Wood
		)
	end
	for i = 1, 14 do
		local a = math.rad(i * 25.7 + 7)
		local base = noAnel(a, raio + 3 + (i % 4), 0)
		local tam = 0.6 + (i % 3) * 0.3
		peca(
			p,
			Vector3.new(0.4, 1.2, 0.4) * tam * 2,
			base * CFrame.new(0, 0.6 * tam * 2, 0),
			Color3.fromRGB(220, 220, 200)
		)
		local chapeu = peca(
			p,
			Vector3.new(1.6, 0.8, 1.6) * tam * 1.5,
			base * CFrame.new(0, 1.3 * tam * 2, 0),
			Color3.fromRGB(120, 255, 190),
			Enum.Material.Neon,
			Enum.PartType.Ball
		)
		if i % 2 == 0 then
			luz(chapeu, Color3.fromRGB(100, 255, 180), 10, 1.2)
		end
	end
	for i = 1, 6 do
		local a = math.rad(i * 60 + 30)
		peca(
			p,
			Vector3.new(0.4, 9, 9),
			noAnel(a, raio + 15, 0.25) * CFrame.Angles(0, 0, math.pi / 2),
			Color3.fromRGB(60, 120, 110),
			Enum.Material.Glass,
			Enum.PartType.Cylinder
		).Transparency =
			0.3
	end
	-- Estátua da serpente
	local st = noAnel(math.rad(-90), raio + 6, 0)
	local pedra = Color3.fromRGB(105, 115, 95)
	for i = 1, 10 do
		local a = (i / 10) * math.pi * 1.6
		peca(
			p,
			Vector3.new(2.6, 2.6, 2.6),
			st * CFrame.new(math.cos(a) * 3, 1.3 + i * 0.25, math.sin(a) * 3),
			pedra,
			Enum.Material.Slate,
			Enum.PartType.Ball
		)
	end
	local cab = st * CFrame.new(0, 8, 0)
	peca(p, Vector3.new(2.4, 5, 2.4), st * CFrame.new(-0.5, 5.5, -2.5), pedra, Enum.Material.Slate, Enum.PartType.Ball)
	peca(p, Vector3.new(4, 3, 4.5), cab * CFrame.new(0, 0, -2.5), pedra, Enum.Material.Slate, Enum.PartType.Ball)
	for _, lado in ipairs({ -1, 1 }) do
		local olho = peca(
			p,
			Vector3.new(0.7, 0.9, 0.3),
			cab * CFrame.new(lado * 1.1, 0.5, -4.6),
			Color3.fromRGB(255, 60, 60),
			Enum.Material.Neon
		)
		luz(olho, Color3.fromRGB(255, 60, 60), 8, 1)
	end
end

-- Ruínas do Clã do Crepúsculo: pilares quebrados, estandartes, lanternas vermelhas, brasas
function decor.crepusculo(p)
	local pedra = Color3.fromRGB(110, 95, 95)
	for i = 1, 28 do
		local a = (i / 28) * math.pi * 2
		peca(p, Vector3.new(2.8, 0.8, 1.6), noAnel(a, raio + 0.8, 0.9), Color3.fromRGB(90, 80, 85), Enum.Material.Slate)
	end
	for i = 1, 10 do
		local a = math.rad(i * 36 + 15)
		local h = 5 + (i * 7 % 6)
		local base = noAnel(a, raio + 7 + (i % 2) * 3, 0)
		if i % 4 == 0 then
			peca(
				p,
				Vector3.new(2, h, 2),
				base * CFrame.new(0, 1, 0) * CFrame.Angles(0, 0, math.pi / 2 - 0.1),
				pedra,
				Enum.Material.Slate,
				Enum.PartType.Cylinder
			)
		else
			peca(
				p,
				Vector3.new(h, 2.2, 2.2),
				base * CFrame.new(0, h / 2, 0) * CFrame.Angles(0, 0, math.pi / 2),
				pedra,
				Enum.Material.Slate,
				Enum.PartType.Cylinder
			)
			peca(p, Vector3.new(3, 0.8, 3), base * CFrame.new(0, 0.4, 0), pedra, Enum.Material.Slate)
		end
	end
	for i = 1, 6 do
		local a = math.rad(i * 60)
		local base = noAnel(a, raio + 4, 0)
		peca(
			p,
			Vector3.new(0.35, 10, 0.35),
			base * CFrame.new(0, 5, 0),
			Color3.fromRGB(40, 35, 40),
			Enum.Material.Metal
		)
		local pano = peca(
			p,
			Vector3.new(2.6, 5, 0.1),
			base * CFrame.new(0, 7, -0.25),
			Color3.fromRGB(120, 20, 35),
			Enum.Material.Fabric
		)
		local sg = Instance.new("SurfaceGui")
		sg.Face = Enum.NormalId.Front
		sg.LightInfluence = 0.3
		sg.Parent = pano
		local t = Instance.new("TextLabel")
		t.BackgroundTransparency = 1
		t.Size = UDim2.fromScale(1, 0.6)
		t.Position = UDim2.fromScale(0, 0.15)
		t.Text = "☾"
		t.TextScaled = true
		t.TextColor3 = Color3.fromRGB(255, 190, 80)
		t.Parent = sg
		local lant = peca(
			p,
			Vector3.new(1, 1.3, 1),
			base * CFrame.new(0, 3.2, -0.5),
			Color3.fromRGB(255, 60, 50),
			Enum.Material.Neon,
			Enum.PartType.Ball
		)
		luz(lant, Color3.fromRGB(255, 80, 60), 12, 2)
	end
	-- Portal escuro
	local pg = noAnel(math.rad(-90), raio + 5, 0)
	for _, lado in ipairs({ -1, 1 }) do
		peca(p, Vector3.new(1.4, 11, 1.4), pg * CFrame.new(5 * lado, 5.5, 0), Color3.fromRGB(35, 30, 35))
	end
	peca(p, Vector3.new(14, 1.1, 1.8), pg * CFrame.new(0, 11.3, 0), Color3.fromRGB(120, 25, 35))
	-- Brasas subindo do chão
	local emissor = peca(p, Vector3.new(raio * 2, 0.2, raio * 2), CFrame.new(0, alturaChao + 1.2, 0), Color3.new(), nil)
	emissor.Transparency = 1
	particulas(emissor, {
		Color = ColorSequence.new(Color3.fromRGB(255, 140, 60), Color3.fromRGB(255, 60, 40)),
		LightEmission = 1,
		Size = NumberSequence.new(0.18, 0),
		Lifetime = NumberRange.new(3, 5),
		Rate = 15,
		Speed = NumberRange.new(1, 3),
		Acceleration = Vector3.new(0.5, 1.5, 0),
		EmissionDirection = Enum.NormalId.Top,
		SpreadAngle = Vector2.new(30, 30),
	})
end

-- Arena do Lorde Dor: espinhos de pedra, círculo rúnico roxo, rochas flutuando, chuva
function decor.chefe(p)
	local roxo = Color3.fromRGB(180, 90, 255)
	for i = 1, 14 do
		local a = (i / 14) * math.pi * 2
		local h = 10 + (i * 5 % 8)
		local base = noAnel(a, raio + 6 + (i % 3) * 2, 0)
		for k = 0, 2 do
			local larg = 3.4 - k * 1
			peca(
				p,
				Vector3.new(larg, h / 3, larg),
				base * CFrame.new(0, (k + 0.5) * h / 3, 0) * CFrame.Angles(0, k * 0.4, 0.05),
				Color3.fromRGB(45, 38, 55),
				Enum.Material.Basalt
			)
		end
		peca(p, Vector3.new(0.2, h * 0.8, 0.2), base * CFrame.new(0.6, h * 0.4, -1.2), roxo, Enum.Material.Neon)
	end
	for _, r in ipairs({ 6, 11 }) do
		local n = r * 5
		for i = 1, n do
			local a = (i / n) * math.pi * 2
			peca(p, Vector3.new(0.9, 0.06, 0.25), noAnel(a, r, 1.04), roxo, Enum.Material.Neon)
		end
	end
	for i = 1, 6 do
		local a = (i / 6) * math.pi * 2
		peca(
			p,
			Vector3.new(0.3, 0.06, 10),
			CFrame.new(0, alturaChao + 1.05, 0) * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, -6),
			roxo,
			Enum.Material.Neon
		)
	end
	for i = 1, 8 do
		local a = math.rad(i * 45 + 20)
		peca(
			p,
			Vector3.new(3, 2.2, 2.6),
			noAnel(a, raio + 3, 9 + (i % 3) * 3) * CFrame.Angles(i, i * 0.5, i * 0.3),
			Color3.fromRGB(60, 50, 75),
			Enum.Material.Basalt
		)
	end
	local nuvem = peca(p, Vector3.new(90, 1, 90), CFrame.new(0, alturaChao + 45, 0), Color3.new(), nil)
	nuvem.Transparency = 1
	particulas(nuvem, {
		Color = ColorSequence.new(Color3.fromRGB(180, 190, 255)),
		LightEmission = 0.4,
		Transparency = NumberSequence.new(0.4),
		Size = NumberSequence.new(0.12),
		Squash = NumberSequence.new(-4),
		Lifetime = NumberRange.new(1.4, 1.6),
		Rate = 500,
		Speed = NumberRange.new(32, 36),
		EmissionDirection = Enum.NormalId.Bottom,
		SpreadAngle = Vector2.new(4, 4),
	})
end

------------------------------------------------------------------------
-- Cenário com modelos 3D da pasta ReplicatedStorage.Arte.Cenario
------------------------------------------------------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function arte(nome)
	local a = ReplicatedStorage:FindFirstChild("Arte")
	local c = a and a:FindFirstChild("Cenario")
	return c and c:FindFirstChild(nome)
end

-- Coloca um modelo do cenário: tamanho, ângulo na volta da arena, distância e virado para o centro
local function colocar(pai, nome, angulo, distancia, escala, giroExtra)
	local original = arte(nome)
	if not original then
		return nil
	end
	local m = original:Clone()
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
		end
	end
	if escala and escala ~= 1 then
		m:ScaleTo(m:GetScale() * escala)
	end
	local pos = Vector3.new(math.cos(angulo) * distancia, alturaChao, math.sin(angulo) * distancia)
	local olhar = CFrame.lookAt(pos, Vector3.new(0, alturaChao, 0)) * CFrame.Angles(0, math.rad(giroExtra or 0), 0)
	m:PivotTo(olhar)
	local caixa, tam = m:GetBoundingBox()
	m:PivotTo(m:GetPivot() + Vector3.new(0, alturaChao - (caixa.Position.Y - tam.Y / 2), 0))
	m.Parent = pai
	return m
end

local function temArte()
	return arte("casaFeudal") ~= nil
end

-- Vila em 3D: casas feudais e japonesas, bambuzais, cerejeiras e o torii
local function vila3D(p)
	-- cerquinha de bambu na borda (peças)
	for i = 1, 36 do
		local a = (i / 36) * math.pi * 2
		peca(
			p,
			Vector3.new(1.6, 0.5, 0.5),
			noAnel(a, raio + 0.6, 1.8) * CFrame.Angles(0, 0, math.pi / 2),
			Color3.fromRGB(150, 190, 90),
			Enum.Material.Wood,
			Enum.PartType.Cylinder
		)
	end
	colocar(p, "torii", math.rad(-90), raio + 5, 0.9)
	local casas = {
		{ "casaFeudal", 15 },
		{ "casaJaponesa", 55 },
		{ "casaFeudal", 100 },
		{ "casaJaponesa", 145 },
		{ "casaFeudal", 190 },
		{ "casaJaponesa", 330 },
	}
	for _, c in ipairs(casas) do
		colocar(p, c[1], math.rad(c[2]), raio + 19, 0.5)
	end
	for i = 1, 6 do
		colocar(p, "cerejeira", math.rad(i * 60 + 35), raio + 8 + (i % 2) * 3, 0.28 + (i % 3) * 0.03, i * 40)
	end
	for i = 1, 8 do
		colocar(p, "bambu", math.rad(i * 45 + 10), raio + 5 + (i % 2) * 4, 0.24 + (i % 3) * 0.03, i * 25)
	end
	-- lanternas brilhando entre as casas
	for i = 1, 8 do
		local a = math.rad(i * 45 + 30)
		local poste = noAnel(a, raio + 3, 0)
		peca(p, Vector3.new(0.3, 4, 0.3), poste * CFrame.new(0, 2, 0), Color3.fromRGB(60, 40, 30), Enum.Material.Wood)
		local l = peca(
			p,
			Vector3.new(1, 1.3, 1),
			poste * CFrame.new(0, 4.4, 0),
			Color3.fromRGB(255, 170, 90),
			Enum.Material.Neon,
			Enum.PartType.Ball
		)
		luz(l, Color3.fromRGB(255, 170, 100), 12, 1.6)
	end
end

-- Crepúsculo com as casas feudais em volta e o torii escuro
local function crepusculo3D(p)
	decor.crepusculo(p)
	for i, ang in ipairs({ 20, 75, 125, 160, 200, 340 }) do
		colocar(p, i % 2 == 0 and "casaJaponesa" or "casaFeudal", math.rad(ang), raio + 22, 0.5)
	end
	for i = 1, 4 do
		colocar(p, "cerejeira", math.rad(i * 90 + 50), raio + 12, 0.3, i * 70)
	end
end

------------------------------------------------------------------------
-- API
------------------------------------------------------------------------
function Cenario.iniciar(baseplate)
	if baseplate then
		baseplate.Size = Vector3.new(160, baseplate.Size.Y, 160)
		baseplate.Material = Enum.Material.Grass
		baseplate.Transparency = 1 -- o chão de verdade agora é o terreno
		alturaChao = baseplate.Position.Y + baseplate.Size.Y / 2
	end
	gerarMontanhas()
	local velho = workspace:FindFirstChild("Arena")
	if velho then
		velho:Destroy()
	end
	local arena = Instance.new("Model")
	arena.Name = "Arena"
	arena.Parent = workspace
	chao = peca(
		arena,
		Vector3.new(1, raio * 2, raio * 2),
		CFrame.new(0, alturaChao + 0.5, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color3.fromRGB(110, 175, 80),
		Enum.Material.Grass,
		Enum.PartType.Cylinder
	)
	chao.Name = "Chao"
	chao.CanCollide = true
	chao.CanQuery = true
	pastaDecor = Instance.new("Folder")
	pastaDecor.Name = "Decoracao"
	pastaDecor.Parent = arena
	-- Parede invisível em volta da arena: o herói não sai do mapa
	local paredes = Instance.new("Folder")
	paredes.Name = "ParedeInvisivel"
	paredes.Parent = arena
	local n = 40
	for i = 1, n do
		local a = (i / n) * math.pi * 2
		local r = raio + 1.5
		local p = Instance.new("Part")
		p.Anchored = true
		p.Transparency = 1
		p.CanCollide = true
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Size = Vector3.new(2 * math.pi * r / n + 0.6, 60, 1)
		p.CFrame = CFrame.new(math.cos(a) * r, alturaChao + 30, math.sin(a) * r) * CFrame.Angles(0, -a + math.pi / 2, 0)
		p.Parent = paredes
	end
	return alturaChao + 1
end

function Cenario.aplicar(tema, baseplate)
	if tema == temaAtual then
		return
	end
	temaAtual = tema
	pastaDecor:ClearAllChildren()
	if tema == "vila" and temArte() then
		vila3D(pastaDecor)
	elseif tema == "crepusculo" and temArte() then
		crepusculo3D(pastaDecor)
	elseif decor[tema] then
		decor[tema](pastaDecor)
	end
	aplicarLuz(tema, baseplate)
end

return Cenario
