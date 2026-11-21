--!strict
-- Visual próprio das Misturebas mais raras (Lendária, Mítica e Secreta).
-- Em vez dos enfeites de raridade iguais para todas (asinhas, coroa, auréola),
-- cada uma ganha cor, olhos, silhueta e aura só dela. Ex.: Dragaláxia é um
-- mini dragão roxo com asas de morcego e chamas roxas em volta.
-- Poucas peças e poucas partículas por bicho para continuar leve no celular.

local CollectionService = game:GetService("CollectionService")

local Especiais = {}

export type Ctx = { modelo: Model, corpo: BasePart, e: number }
export type Especial = {
	corpo: Color3,
	barriga: Color3,
	iris: Color3,
	aura: Color3, -- luz, brilhinhos e ondas no chão
	brilho: number?,
	semAcessorio: boolean?, -- tira o acessório da família (o especial já tem o seu)
	montar: (ctx: Ctx) -> (),
}

local function c(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

-- texturas: as do Roblox e as da biblioteca do VFX Studio
local FOGO = "rbxasset://textures/particles/fire_main.dds"
local FAISCA = "rbxasset://textures/particles/sparkles_main.dds"
local FUMACA = "rbxasset://textures/particles/smoke_main.dds"
local ESTRELA = "rbxassetid://12386386944"
local CRUZ = "rbxassetid://8733488500"
local FEIXE = "rbxassetid://74970414136395"

local OURO = c(255, 195, 50)

local function soldar(a: BasePart, b: BasePart)
	local solda = Instance.new("WeldConstraint")
	solda.Part0 = a
	solda.Part1 = b
	solda.Parent = b
end

-- Peça presa no corpo. cf é a posição em studs relativa ao corpo (já com escala).
local function pecaCF(ctx: Ctx, forma: string, cor: Color3, tam: Vector3, cf: CFrame, material: Enum.Material?): BasePart
	local p = Instance.new("Part")
	if forma == "cilindro" then
		p.Shape = Enum.PartType.Cylinder
	elseif forma == "bola" then
		local malha = Instance.new("SpecialMesh")
		malha.MeshType = Enum.MeshType.Sphere
		malha.Parent = p
	end
	p.Name = "Especial"
	p.Size = tam * ctx.e
	p.Color = cor
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.Massless = true
	p.CastShadow = false
	p.CFrame = ctx.corpo.CFrame * cf
	p.Parent = ctx.modelo
	soldar(ctx.corpo, p)
	return p
end

-- Mesma coisa, com tam e pos em "unidades de bicho" (multiplicadas pela escala e).
local function peca(
	ctx: Ctx,
	forma: string,
	cor: Color3,
	tam: Vector3,
	pos: Vector3,
	rot: CFrame?,
	material: Enum.Material?
): BasePart
	return pecaCF(ctx, forma, cor, tam, CFrame.new(pos * ctx.e) * (rot or CFrame.identity), material)
end

type Particula = {
	textura: string,
	cor0: Color3,
	cor1: Color3?,
	taxa: number,
	vida: { number },
	vel: { number },
	tam0: number,
	tam1: number?,
	transp0: number?,
	direcao: Enum.NormalId?,
	espalha: number?,
	luz: number?,
	gravidade: number?,
	giro: number?,
	zoffset: number?,
}

local function particulas(pai: Instance, e: number, p: Particula): ParticleEmitter
	local f = Instance.new("ParticleEmitter")
	f.Texture = p.textura
	f.Color = ColorSequence.new(p.cor0, p.cor1 or p.cor0)
	f.Rate = p.taxa
	f.Lifetime = NumberRange.new(p.vida[1], p.vida[2])
	f.Speed = NumberRange.new(p.vel[1] * e, p.vel[2] * e)
	f.Size = NumberSequence.new(p.tam0 * e, (p.tam1 or 0) * e)
	f.Transparency = NumberSequence.new(p.transp0 or 0.1, 1)
	f.EmissionDirection = p.direcao or Enum.NormalId.Top
	local abre = p.espalha or 180
	f.SpreadAngle = Vector2.new(abre, abre)
	f.LightEmission = p.luz or 1
	if p.gravidade then
		f.Acceleration = Vector3.new(0, -p.gravidade * e, 0)
	end
	if p.giro then
		f.RotSpeed = NumberRange.new(-p.giro, p.giro)
		f.Rotation = NumberRange.new(0, 360)
	end
	f.ZOffset = p.zoffset or 0
	f.Parent = pai
	return f
end

-- ponto invisível para emitir partículas de um lugar específico
local function ponto(ctx: Ctx, pos: Vector3): Attachment
	local a = Instance.new("Attachment")
	a.Position = pos * ctx.e
	a.Parent = ctx.corpo
	return a
end

-- Asa de morcego: três "dedos" escuros abrindo em leque com membrana brilhante entre eles.
local function asaMorcego(ctx: Ctx, lado: number, osso: Color3, membrana: Color3)
	local raiz = CFrame.new(Vector3.new(0.95 * lado, 0.55, 0.95) * ctx.e)
		* CFrame.Angles(0, math.rad(-28 * lado), 0)
	for k = 1, 3 do
		local l = 2.5 - 0.35 * (k - 1)
		local abre = CFrame.Angles(0, 0, math.rad(lado * (42 - 30 * (k - 1))))
		local base = raiz * abre
		local centro = base * CFrame.new(lado * l / 2 * ctx.e, 0, 0)
		local m = pecaCF(
			ctx,
			"bola",
			membrana,
			Vector3.new(l, 1.05, 0.07),
			centro * CFrame.new(0, -0.38 * ctx.e, 0),
			Enum.Material.Neon
		)
		m.Transparency = 0.25
		pecaCF(ctx, "cilindro", osso, Vector3.new(l, 0.16, 0.16), centro * CFrame.new(0, 0.12 * ctx.e, 0))
		-- garrinha na ponta do dedo
		pecaCF(
			ctx,
			"bola",
			osso:Lerp(Color3.new(1, 1, 1), 0.5),
			Vector3.new(0.28, 0.28, 0.28),
			base * CFrame.new(lado * l * ctx.e, 0.12 * ctx.e, 0)
		)
	end
end

-- Asa de fogo: penas compridas do vermelho (perto do corpo) ao amarelo (na ponta).
local function asaFogo(ctx: Ctx, lado: number)
	local raiz = CFrame.new(Vector3.new(0.95 * lado, 0.5, 0.9) * ctx.e) * CFrame.Angles(0, math.rad(-30 * lado), 0)
	for k = 1, 5 do
		local l = 2.6 - 0.28 * (k - 1)
		local cor = c(255, 70, 40):Lerp(c(255, 220, 70), (k - 1) / 4)
		local abre = CFrame.Angles(0, 0, math.rad(lado * (58 - 24 * (k - 1))))
		local p = pecaCF(
			ctx,
			"bola",
			cor,
			Vector3.new(l, 0.55, 0.12),
			raiz * abre * CFrame.new(lado * l / 2 * ctx.e, 0, 0.02 * k * ctx.e),
			Enum.Material.Neon
		)
		p.Transparency = 0.1
	end
end

-- pontos em volta da cabeça/corpo, em círculo deitado
local function circulo(n: number, raio: number, altura: number): { Vector3 }
	local lista = {}
	for k = 0, n - 1 do
		local a = k / n * math.pi * 2
		table.insert(lista, Vector3.new(math.cos(a) * raio, altura, math.sin(a) * raio))
	end
	return lista
end

local ARCOIRIS = { c(255, 110, 120), c(255, 175, 80), c(255, 235, 100), c(120, 230, 140), c(100, 190, 255), c(190, 130, 255) }

local Lista: { [string]: Especial } = {}

------------------------------------------------------------------------
-- Míticas e Secretas: silhueta nova
------------------------------------------------------------------------

Lista.dragalaxia = {
	-- mini dragão galáctico: roxo escuro, asas de morcego e chamas roxas
	corpo = c(85, 45, 150),
	barriga = c(200, 165, 255),
	iris = c(205, 110, 255),
	aura = c(170, 70, 255),
	brilho = 0.06,
	semAcessorio = true,
	montar = function(ctx)
		for _, lado in { -1, 1 } do
			asaMorcego(ctx, lado, c(55, 30, 100), c(170, 90, 255))
		end
		-- escamas claras na barriga
		for k = 0, 2 do
			peca(
				ctx,
				"bola",
				c(225, 200, 255),
				Vector3.new(1.5 - k * 0.25, 0.22, 0.3),
				Vector3.new(0, -0.35 - k * 0.32, -1.48 + k * 0.07)
			)
		end
		-- fumacinha roxa saindo do nariz
		local nariz = ponto(ctx, Vector3.new(0, -0.05, -1.6))
		particulas(nariz, ctx.e, {
			textura = FUMACA,
			cor0 = c(190, 120, 255),
			taxa = 2,
			vida = { 0.8, 1.2 },
			vel = { 0.6, 1 },
			tam0 = 0.3,
			tam1 = 0.8,
			transp0 = 0.5,
			espalha = 15,
			luz = 0.5,
		})
		-- chamas roxas subindo do chão em volta
		local pe = ponto(ctx, Vector3.new(0, -1.5, 0))
		particulas(pe, ctx.e, {
			textura = FOGO,
			cor0 = c(150, 60, 255),
			cor1 = c(255, 90, 230),
			taxa = 16,
			vida = { 0.5, 0.9 },
			vel = { 2, 3.5 },
			tam0 = 1.4,
			tam1 = 0.2,
			transp0 = 0.35,
			espalha = 35,
			zoffset = -1,
		})
		particulas(ctx.corpo, ctx.e, {
			textura = ESTRELA,
			cor0 = c(220, 170, 255),
			taxa = 4,
			vida = { 1, 1.6 },
			vel = { 0.5, 1 },
			tam0 = 0.45,
		})
	end,
}

Lista.fenixicara = {
	-- fênix de fogo: asas e crista de chamas
	corpo = c(255, 125, 55),
	barriga = c(255, 225, 150),
	iris = c(255, 200, 60),
	aura = c(255, 120, 40),
	montar = function(ctx)
		for _, lado in { -1, 1 } do
			asaFogo(ctx, lado)
		end
		-- crista de três chamas na cabeça
		for k = -1, 1 do
			local p = peca(
				ctx,
				"bola",
				c(255, 90, 40):Lerp(c(255, 220, 80), math.abs(k) * 0.5),
				Vector3.new(0.35, 1.1 - math.abs(k) * 0.3, 0.35),
				Vector3.new(k * 0.3, 1.55 - math.abs(k) * 0.12, 0.25),
				CFrame.Angles(math.rad(-15), 0, math.rad(-k * 22)),
				Enum.Material.Neon
			)
			p.Transparency = 0.05
		end
		particulas(ponto(ctx, Vector3.new(0, 0.2, 0.6)), ctx.e, {
			textura = FOGO,
			cor0 = c(255, 120, 30),
			cor1 = c(255, 60, 40),
			taxa = 14,
			vida = { 0.4, 0.8 },
			vel = { 2, 4 },
			tam0 = 1.3,
			tam1 = 0.1,
			transp0 = 0.3,
			espalha = 40,
			zoffset = -1,
		})
		particulas(ctx.corpo, ctx.e, {
			textura = FAISCA,
			cor0 = c(255, 200, 80),
			taxa = 6,
			vida = { 0.8, 1.4 },
			vel = { 2, 3 },
			tam0 = 0.35,
			espalha = 50,
		})
	end,
}

Lista.nuvemcornio = {
	-- unicórnio de nuvem: crina de arco-íris e pisando em nuvens
	corpo = c(252, 250, 255),
	barriga = c(255, 225, 240),
	iris = c(255, 120, 210),
	aura = c(255, 150, 230),
	montar = function(ctx)
		for k, cor in ARCOIRIS do
			peca(
				ctx,
				"bola",
				cor,
				Vector3.new(0.75, 0.6, 0.6),
				Vector3.new(0, 1.45 - (k - 1) * 0.28, 0.15 + (k - 1) * 0.3),
				CFrame.Angles(math.rad(25 + k * 8), 0, 0)
			)
		end
		for k, p in circulo(7, 1.55, -1.55) do
			peca(ctx, "bola", Color3.new(1, 1, 1), Vector3.new(1.1, 0.75, 1.1) * (1 - (k % 2) * 0.2), p)
		end
		local f = particulas(ctx.corpo, ctx.e, {
			textura = ESTRELA,
			cor0 = Color3.new(1, 1, 1),
			taxa = 8,
			vida = { 1, 1.6 },
			vel = { 1, 2 },
			tam0 = 0.5,
		})
		local cores = {}
		for k, cor in ARCOIRIS do
			table.insert(cores, ColorSequenceKeypoint.new((k - 1) / (#ARCOIRIS - 1), cor))
		end
		f.Color = ColorSequence.new(cores)
	end,
}

Lista.pinguivulcao = {
	-- pinguim de pedra vulcânica com rachaduras de lava
	corpo = c(65, 55, 60),
	barriga = c(255, 238, 222),
	iris = c(255, 120, 40),
	aura = c(255, 110, 30),
	montar = function(ctx)
		local metade = ctx.corpo.Size / 2 / ctx.e
		for k = 1, 8 do
			local a = k * 2.4
			local alt = math.sin(k * 1.7) * 0.75
			local dir = Vector3.new(math.cos(a), alt, math.abs(math.sin(a)) + 0.2).Unit
			local pos = dir * metade * 0.97
			pecaCF(
				ctx,
				"cilindro",
				c(255, 110, 30),
				Vector3.new(0.9, 0.09, 0.09),
				CFrame.lookAt(pos * ctx.e, pos * 2 * ctx.e) * CFrame.Angles(0, 0, k),
				Enum.Material.Neon
			)
		end
		particulas(ctx.corpo, ctx.e, {
			textura = FAISCA,
			cor0 = c(255, 150, 40),
			cor1 = c(255, 60, 20),
			taxa = 10,
			vida = { 0.8, 1.4 },
			vel = { 2.5, 4 },
			tam0 = 0.35,
			espalha = 30,
		})
		particulas(ponto(ctx, Vector3.new(0, -1.5, 0)), ctx.e, {
			textura = FOGO,
			cor0 = c(255, 120, 30),
			cor1 = c(200, 40, 20),
			taxa = 8,
			vida = { 0.4, 0.7 },
			vel = { 1.5, 2.5 },
			tam0 = 1,
			tam1 = 0.1,
			transp0 = 0.45,
			espalha = 40,
			zoffset = -1,
		})
	end,
}

Lista.reimistureba = {
	-- o rei: coroa grande de joias, cetro e brilho dourado
	corpo = c(115, 75, 210),
	barriga = c(255, 232, 180),
	iris = c(255, 195, 60),
	aura = OURO,
	montar = function(ctx)
		local y = ctx.corpo.Size.Y / 2 / ctx.e
		local faixa = peca(
			ctx,
			"cilindro",
			OURO,
			Vector3.new(0.5, 1.6, 1.6),
			Vector3.new(0, y + 0.05, 0.05),
			CFrame.Angles(0, 0, math.pi / 2)
		)
		faixa.Reflectance = 0.1
		for k, p in circulo(5, 0.68, y + 0.5) do
			local ponta = peca(ctx, "bola", OURO, Vector3.new(0.32, 0.75, 0.32), p + Vector3.new(0, 0, 0.05))
			ponta.Reflectance = 0.1
			peca(
				ctx,
				"bola",
				if k % 2 == 0 then c(255, 60, 90) else c(80, 200, 255),
				Vector3.new(0.24, 0.24, 0.24),
				p + Vector3.new(0, 0.42, 0.05),
				nil,
				Enum.Material.Neon
			)
		end
		peca(ctx, "bola", c(255, 50, 80), Vector3.new(0.35, 0.35, 0.2), Vector3.new(0, y + 0.08, -0.78), nil, Enum.Material.Neon)
		-- cetro na mão
		peca(
			ctx,
			"cilindro",
			OURO,
			Vector3.new(2.4, 0.16, 0.16),
			Vector3.new(1.85, 0.1, -0.6),
			CFrame.Angles(0, 0, math.rad(80))
		)
		peca(ctx, "bola", c(255, 60, 90), Vector3.new(0.5, 0.5, 0.5), Vector3.new(2.05, 1.3, -0.6), nil, Enum.Material.Neon)
		particulas(ctx.corpo, ctx.e, {
			textura = FEIXE,
			cor0 = c(255, 220, 120),
			taxa = 2,
			vida = { 1.2, 1.8 },
			vel = { 0, 0 },
			tam0 = 3,
			tam1 = 3.5,
			transp0 = 0.7,
			luz = 1,
			giro = 20,
			zoffset = -2,
		})
		particulas(ctx.corpo, ctx.e, {
			textura = CRUZ,
			cor0 = c(255, 225, 120),
			taxa = 6,
			vida = { 0.6, 1 },
			vel = { 1, 2 },
			tam0 = 0.6,
		})
	end,
}

Lista.bugigangacosmica = {
	-- bugiganga do espaço: planetinhas girando em volta
	corpo = c(50, 60, 130),
	barriga = c(140, 225, 255),
	iris = c(110, 240, 255),
	aura = c(90, 220, 255),
	semAcessorio = true,
	montar = function(ctx)
		local planetas = {
			{ pos = Vector3.new(2.5, 0.9, 0.3), tam = 0.8, cor = c(255, 150, 90), anel = true },
			{ pos = Vector3.new(-2.4, 0.4, 0.6), tam = 0.6, cor = c(140, 255, 180), anel = false },
			{ pos = Vector3.new(-1.2, 2.2, 0.9), tam = 0.5, cor = c(255, 120, 200), anel = false },
		}
		for _, pl in planetas do
			peca(ctx, "bola", pl.cor, Vector3.one * pl.tam, pl.pos)
			if pl.anel then
				local anel = peca(
					ctx,
					"cilindro",
					c(255, 230, 170),
					Vector3.new(0.05, pl.tam * 1.9, pl.tam * 1.9),
					pl.pos,
					CFrame.Angles(0, 0, math.rad(70)) * CFrame.Angles(math.rad(20), 0, 0),
					Enum.Material.Neon
				)
				anel.Transparency = 0.3
			end
		end
		particulas(ctx.corpo, ctx.e, {
			textura = ESTRELA,
			cor0 = c(150, 235, 255),
			cor1 = Color3.new(1, 1, 1),
			taxa = 8,
			vida = { 1.2, 2 },
			vel = { 0.5, 1.2 },
			tam0 = 0.5,
		})
	end,
}

Lista.misturebasuprema = {
	-- a suprema: perolada, auréola dupla e joias de arco-íris que trocam de cor
	corpo = c(250, 246, 255),
	barriga = c(255, 222, 245),
	iris = c(255, 110, 200),
	aura = c(255, 140, 240),
	brilho = 0.15,
	semAcessorio = true,
	montar = function(ctx)
		local y = ctx.corpo.Size.Y / 2 / ctx.e
		local n = 0
		for anel = 0, 1 do
			for _, p in circulo(12, 0.95 - anel * 0.25, y + 0.55 + anel * 0.35) do
				n += 1
				local b = peca(ctx, "bola", Color3.new(1, 1, 1), Vector3.new(0.26, 0.2, 0.26), p, nil, Enum.Material.Neon)
				b:SetAttribute("Matiz", (n / 12) % 1)
			end
		end
		for k, p in circulo(3, 2.4, 0.6) do
			local joia = peca(
				ctx,
				"bloco",
				Color3.new(1, 1, 1),
				Vector3.new(0.55, 0.55, 0.55),
				p + Vector3.new(0, (k - 2) * 0.4, 0),
				CFrame.Angles(math.rad(45), 0, math.rad(45)),
				Enum.Material.Neon
			)
			joia:SetAttribute("Matiz", k / 3)
		end
		CollectionService:AddTag(ctx.modelo, "Arcoiris")
		local f = particulas(ctx.corpo, ctx.e, {
			textura = FAISCA,
			cor0 = Color3.new(1, 1, 1),
			taxa = 12,
			vida = { 1, 1.6 },
			vel = { 1.5, 3 },
			tam0 = 0.5,
		})
		local cores = {}
		for k, cor in ARCOIRIS do
			table.insert(cores, ColorSequenceKeypoint.new((k - 1) / (#ARCOIRIS - 1), cor))
		end
		f.Color = ColorSequence.new(cores)
		particulas(ctx.corpo, ctx.e, {
			textura = FEIXE,
			cor0 = c(255, 200, 250),
			taxa = 2,
			vida = { 1.2, 1.8 },
			vel = { 0, 0 },
			tam0 = 3.5,
			tam1 = 4,
			transp0 = 0.7,
			giro = 25,
			zoffset = -2,
		})
	end,
}

------------------------------------------------------------------------
-- Lendárias: uma marca própria + aura da cor delas
------------------------------------------------------------------------

Lista.microleao = {
	-- leão dourado com raios de sol atrás
	corpo = c(255, 205, 95),
	barriga = c(255, 245, 222),
	iris = c(255, 160, 40),
	aura = c(255, 180, 40),
	montar = function(ctx)
		particulas(ctx.corpo, ctx.e, {
			textura = FEIXE,
			cor0 = c(255, 210, 90),
			taxa = 2,
			vida = { 1.2, 1.8 },
			vel = { 0, 0 },
			tam0 = 3,
			tam1 = 3.5,
			transp0 = 0.65,
			giro = 15,
			zoffset = -2,
		})
		particulas(ctx.corpo, ctx.e, {
			textura = FAISCA,
			cor0 = c(255, 220, 100),
			taxa = 5,
			vida = { 0.8, 1.2 },
			vel = { 1.5, 2.5 },
			tam0 = 0.35,
		})
	end,
}

Lista.baleiastelo = {
	-- baleia-castelo com espuma de onda em volta e bolhas subindo
	corpo = c(85, 145, 235),
	barriga = c(230, 245, 255),
	iris = c(90, 200, 255),
	aura = c(80, 200, 255),
	montar = function(ctx)
		for k, p in circulo(10, 2.0, -1.5) do
			local b = peca(
				ctx,
				"bola",
				if k % 2 == 0 then Color3.new(1, 1, 1) else c(170, 230, 255),
				Vector3.new(0.75, 0.45, 0.75),
				p
			)
			b.Transparency = 0.1
		end
		particulas(ctx.corpo, ctx.e, {
			textura = CRUZ,
			cor0 = c(200, 240, 255),
			taxa = 6,
			vida = { 1, 1.6 },
			vel = { 1, 2 },
			tam0 = 0.4,
			espalha = 60,
		})
	end,
}

Lista.girafatrem = {
	-- girafa-trem: rodas de locomotiva nos lados e vapor
	corpo = c(255, 200, 90),
	barriga = c(255, 240, 210),
	iris = c(255, 170, 50),
	aura = c(255, 190, 70),
	montar = function(ctx)
		local x = ctx.corpo.Size.X / 2 / ctx.e
		for _, lado in { -1, 1 } do
			for _, z in { -0.55, 0.55 } do
				peca(ctx, "cilindro", c(45, 45, 55), Vector3.new(0.25, 1, 1), Vector3.new((x - 0.05) * lado, -1.1, z))
				peca(ctx, "cilindro", c(230, 60, 60), Vector3.new(0.3, 0.45, 0.45), Vector3.new((x + 0.0) * lado, -1.1, z))
			end
			peca(
				ctx,
				"cilindro",
				OURO,
				Vector3.new(1.3, 0.12, 0.12),
				Vector3.new((x + 0.12) * lado, -1.1, 0),
				CFrame.Angles(0, math.pi / 2, 0)
			)
		end
		particulas(ctx.corpo, ctx.e, {
			textura = FAISCA,
			cor0 = c(255, 220, 120),
			taxa = 4,
			vida = { 0.8, 1.2 },
			vel = { 1.5, 2.5 },
			tam0 = 0.35,
		})
	end,
}

Lista.castelobo = {
	-- lobo cavaleiro: escudo e espada
	corpo = c(150, 160, 190),
	barriga = c(235, 240, 250),
	iris = c(120, 190, 255),
	aura = c(170, 210, 255),
	montar = function(ctx)
		local x = ctx.corpo.Size.X / 2 / ctx.e
		peca(ctx, "cilindro", c(205, 210, 225), Vector3.new(0.18, 1.5, 1.5), Vector3.new(-(x + 0.3), -0.3, -0.35))
		peca(ctx, "cilindro", c(60, 90, 200), Vector3.new(0.2, 1.1, 1.1), Vector3.new(-(x + 0.33), -0.3, -0.35))
		peca(ctx, "bola", OURO, Vector3.new(0.25, 0.4, 0.4), Vector3.new(-(x + 0.42), -0.3, -0.35))
		-- espada em pé na outra mão
		peca(ctx, "bloco", c(230, 235, 245), Vector3.new(0.12, 1.9, 0.32), Vector3.new(x + 0.3, 0.55, -0.55), nil, Enum.Material.Metal)
		peca(ctx, "bloco", OURO, Vector3.new(0.18, 0.16, 0.8), Vector3.new(x + 0.3, -0.42, -0.55))
		peca(ctx, "bloco", c(110, 70, 50), Vector3.new(0.16, 0.45, 0.16), Vector3.new(x + 0.3, -0.72, -0.55))
		particulas(ctx.corpo, ctx.e, {
			textura = CRUZ,
			cor0 = Color3.new(1, 1, 1),
			cor1 = c(170, 210, 255),
			taxa = 4,
			vida = { 0.5, 0.9 },
			vel = { 0.5, 1 },
			tam0 = 0.7,
		})
	end,
}

Lista.trovanguru = {
	-- canguru do trovão: raios em ziguezague em volta e faíscas elétricas
	corpo = c(80, 105, 220),
	barriga = c(220, 235, 255),
	iris = c(255, 230, 70),
	aura = c(120, 200, 255),
	montar = function(ctx)
		for k, p in circulo(4, 2.3, 0.3) do
			local giro = CFrame.Angles(0, -k * math.pi / 2, 0)
			for s = 0, 2 do
				peca(
					ctx,
					"bloco",
					c(255, 235, 80),
					Vector3.new(0.14, 0.75, 0.14),
					p + Vector3.new(0, 0.6 - s * 0.55, 0),
					giro * CFrame.Angles(0, 0, math.rad(if s % 2 == 0 then 30 else -30)),
					Enum.Material.Neon
				)
			end
		end
		particulas(ctx.corpo, ctx.e, {
			textura = CRUZ,
			cor0 = c(160, 230, 255),
			cor1 = c(255, 255, 160),
			taxa = 12,
			vida = { 0.12, 0.25 },
			vel = { 0, 0.5 },
			tam0 = 1,
			tam1 = 0.4,
		})
	end,
}

Lista.aquariorca = {
	-- orca no aquário: peixinhos coloridos nadando em volta
	corpo = c(45, 50, 70),
	barriga = c(245, 248, 255),
	iris = c(90, 220, 255),
	aura = c(90, 210, 255),
	montar = function(ctx)
		local cores = { c(255, 150, 60), c(255, 230, 80), c(255, 120, 180), c(120, 240, 200) }
		for k, p in circulo(4, 2.15, 0) do
			local pos = p + Vector3.new(0, (k % 2) * 0.7 - 0.2, 0)
			local virar = CFrame.Angles(0, -k * math.pi / 2, 0)
			peca(ctx, "bola", cores[k], Vector3.new(0.3, 0.32, 0.6), pos, virar)
			pecaCF(
				ctx,
				"bola",
				cores[k]:Lerp(Color3.new(1, 1, 1), 0.3),
				Vector3.new(0.08, 0.3, 0.25),
				CFrame.new(pos * ctx.e) * virar * CFrame.new(0, 0, 0.38 * ctx.e)
			)
		end
		particulas(ctx.corpo, ctx.e, {
			textura = FAISCA,
			cor0 = c(180, 240, 255),
			taxa = 5,
			vida = { 1, 1.6 },
			vel = { 1, 1.8 },
			tam0 = 0.35,
		})
	end,
}

function Especiais.de(id: string): Especial?
	return Lista[id]
end

return Especiais
