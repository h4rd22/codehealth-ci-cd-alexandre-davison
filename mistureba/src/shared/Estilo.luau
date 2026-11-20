--!strict
-- Direção de arte das Misturebas: cada uma pertence a uma FAMÍLIA com paleta própria
-- e usa um ACESSÓRIO fofo (feito no mesmo estilo arredondado) que lembra o objeto
-- da mistura, no lugar de peças soltas coladas na cabeça.
--
-- Famílias:
--   Doceria     tons pastel de confeitaria, brilho de bala
--   Lar Doce Lar  tons quentinhos de casa (creme, pêssego, sálvia)
--   Oceano      azuis, água-marinha e coral
--   Brinquedos  cores primárias de brinquedo de plástico
--   Cosmos      índigo, violeta e neon de galáxia

local Estilo = {}

local function c(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

export type Familia = {
	nome: string,
	cores: { Color3 },
	barriga: Color3,
	acento: Color3,
	pedestal: Color3,
	brilho: number, -- reflexo do plástico
}

Estilo.Familias = {
	doceria = {
		nome = "Doceria",
		cores = { c(255, 178, 204), c(160, 232, 205), c(255, 232, 150), c(200, 178, 255), c(255, 200, 160) },
		barriga = c(255, 247, 235),
		acento = c(255, 110, 160),
		pedestal = c(255, 225, 238),
		brilho = 0.08,
	},
	casa = {
		nome = "Lar Doce Lar",
		cores = { c(255, 205, 160), c(245, 230, 200), c(165, 205, 180), c(235, 160, 130), c(185, 210, 235) },
		barriga = c(255, 248, 235),
		acento = c(160, 110, 80),
		pedestal = c(245, 232, 210),
		brilho = 0.04,
	},
	oceano = {
		nome = "Oceano",
		cores = { c(110, 195, 245), c(80, 150, 225), c(120, 225, 215), c(255, 150, 140), c(60, 100, 180) },
		barriga = c(235, 250, 255),
		acento = c(255, 255, 255),
		pedestal = c(200, 238, 255),
		brilho = 0.1,
	},
	brinquedos = {
		nome = "Brinquedos",
		cores = { c(255, 95, 95), c(255, 200, 60), c(80, 155, 255), c(110, 210, 110), c(255, 145, 55) },
		barriga = c(255, 252, 245),
		acento = c(45, 55, 90),
		pedestal = c(235, 240, 255),
		brilho = 0.12,
	},
	cosmos = {
		nome = "Cosmos",
		cores = { c(105, 90, 215), c(160, 95, 235), c(70, 70, 150), c(225, 115, 230), c(80, 200, 235) },
		barriga = c(225, 215, 255),
		acento = c(255, 235, 150),
		pedestal = c(60, 50, 110),
		brilho = 0.15,
	},
} :: { [string]: Familia }

export type Visual = { familia: string, tom: number, acessorio: string?, corAcessorio: Color3? }

-- família, tom da paleta e acessório de cada Mistureba
Estilo.PorId = {
	-- Lar Doce Lar
	chaleiruga = { familia = "casa", tom = 3, acessorio = "tampa" },
	torracoelho = { familia = "casa", tom = 2, acessorio = "torrada" },
	geladeirapirata = { familia = "casa", tom = 5, acessorio = "pirata" },
	sofassauro = { familia = "casa", tom = 4, acessorio = "almofada" },
	liquidificorvo = { familia = "casa", tom = 5, acessorio = "helice" },
	microleao = { familia = "casa", tom = 1, acessorio = "telinha", corAcessorio = c(255, 210, 90) },
	abajurubu = { familia = "casa", tom = 3, acessorio = "abajur" },
	chinelefante = { familia = "casa", tom = 5, acessorio = "chinelo" },
	mochilontra = { familia = "casa", tom = 1, acessorio = "mochila" },
	relocoruja = { familia = "casa", tom = 2, acessorio = "relogio" },
	meiaranha = { familia = "casa", tom = 4, acessorio = "meias" },
	escovadragao = { familia = "casa", tom = 3, acessorio = "cerdas" },
	-- Doceria
	pastelossauro = { familia = "doceria", tom = 3, acessorio = "cobertura", corAcessorio = c(255, 215, 90) },
	abacataoninja = { familia = "doceria", tom = 2, acessorio = "bandana", corAcessorio = c(60, 60, 80) },
	bolachorro = { familia = "doceria", tom = 5, acessorio = "cobertura", corAcessorio = c(130, 80, 55) },
	sorvetigre = { familia = "doceria", tom = 1, acessorio = "sorvete" },
	cupcameleao = { familia = "doceria", tom = 4, acessorio = "cobertura" },
	pipocavalo = { familia = "doceria", tom = 3, acessorio = "pipoca" },
	cenourato = { familia = "doceria", tom = 5, acessorio = "broto" },
	fenixicara = { familia = "doceria", tom = 1, acessorio = "xicara" },
	-- Oceano
	tubarone = { familia = "oceano", tom = 2, acessorio = "tenis" },
	polvonete = { familia = "oceano", tom = 4, acessorio = "rodinhas" },
	patinepato = { familia = "oceano", tom = 1, acessorio = "rodinhas" },
	baleiastelo = { familia = "oceano", tom = 5, acessorio = "torre", corAcessorio = c(240, 210, 150) },
	aquariorca = { familia = "oceano", tom = 5, acessorio = "aquario" },
	pinguivulcao = { familia = "oceano", tom = 3, acessorio = "vulcao" },
	-- Brinquedos
	pianoceronte = { familia = "brinquedos", tom = 3, acessorio = "cartola" },
	guardachuvalo = { familia = "brinquedos", tom = 4, acessorio = "guardachuva", corAcessorio = c(255, 95, 95) },
	girafatrem = { familia = "brinquedos", tom = 2, acessorio = "chamine" },
	lapisquilo = { familia = "brinquedos", tom = 5, acessorio = "lapis" },
	televisapo = { familia = "brinquedos", tom = 4, acessorio = "telinha", corAcessorio = c(120, 200, 255) },
	foguetucano = { familia = "brinquedos", tom = 1, acessorio = "foguete" },
	castelobo = { familia = "brinquedos", tom = 3, acessorio = "torre", corAcessorio = c(200, 200, 215) },
	robelha = { familia = "brinquedos", tom = 2, acessorio = "helice" },
	-- Cosmos
	nuvemcornio = { familia = "cosmos", tom = 4 },
	trovanguru = { familia = "cosmos", tom = 1, acessorio = "raio" },
	dragalaxia = { familia = "cosmos", tom = 2, acessorio = "anel" },
	reimistureba = { familia = "cosmos", tom = 3 },
	bugigangacosmica = { familia = "cosmos", tom = 5, acessorio = "anel" },
	misturebasuprema = { familia = "cosmos", tom = 4, acessorio = "anel" },
} :: { [string]: Visual }

function Estilo.de(id: string): (Visual, Familia)
	local v = Estilo.PorId[id] or { familia = "casa", tom = 1 }
	return v, Estilo.Familias[v.familia] or Estilo.Familias.casa
end

------------------------------------------------------------------------
-- Acessórios (todos com peças arredondadas, mesma "massinha" do corpo)
------------------------------------------------------------------------
export type Ctx = {
	modelo: Model,
	corpo: BasePart,
	e: number,
	cor: Color3,
	acento: Color3,
	familia: Familia,
}

local function soldar(a: BasePart, b: BasePart)
	local solda = Instance.new("WeldConstraint")
	solda.Part0 = a
	solda.Part1 = b
	solda.Parent = b
end

local function parte(ctx: Ctx, forma: string, cor: Color3, tam: Vector3, cf: CFrame, material: Enum.Material?): BasePart
	local p: BasePart
	if forma == "cunha" then
		p = Instance.new("WedgePart")
	else
		local q = Instance.new("Part")
		if forma == "cilindro" then
			q.Shape = Enum.PartType.Cylinder
		elseif forma == "bola" then
			local malha = Instance.new("SpecialMesh")
			malha.MeshType = Enum.MeshType.Sphere
			malha.Parent = q
		end
		p = q
	end
	p.Name = "Acessorio"
	p.Size = tam
	p.Color = cor
	p.Material = material or Enum.Material.SmoothPlastic
	p.Reflectance = ctx.familia.brilho
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = true
	p.Massless = true
	p.CastShadow = false
	p.CFrame = ctx.corpo.CFrame * cf
	p.Parent = ctx.modelo
	soldar(ctx.corpo, p)
	return p
end

local function bola(ctx: Ctx, cor: Color3, tam: Vector3, cf: CFrame, material: Enum.Material?): BasePart
	return parte(ctx, "bola", cor, tam * ctx.e, cf, material)
end

-- cilindro em pé (o cilindro do Roblox deita no eixo X; giramos para ficar em Y)
local function tubo(
	ctx: Ctx,
	cor: Color3,
	altura: number,
	diametro: number,
	pos: Vector3,
	material: Enum.Material?
): BasePart
	return parte(
		ctx,
		"cilindro",
		cor,
		Vector3.new(altura, diametro, diametro) * ctx.e,
		CFrame.new(pos * ctx.e) * CFrame.Angles(0, 0, math.pi / 2),
		material
	)
end

local function fumaca(pai: BasePart, cor: Color3, tamanho: number, taxa: number)
	local f = Instance.new("ParticleEmitter")
	f.Texture = "rbxasset://textures/particles/smoke_main.dds"
	f.Color = ColorSequence.new(cor)
	f.Size = NumberSequence.new(tamanho * 0.4, tamanho)
	f.Transparency = NumberSequence.new(0.35, 1)
	f.Lifetime = NumberRange.new(1, 1.6)
	f.Speed = NumberRange.new(1.5, 2.5)
	f.SpreadAngle = Vector2.new(10, 10)
	f.Rate = taxa
	f.EmissionDirection = Enum.NormalId.Top
	f.Parent = pai
end

local BRANCO = Color3.new(1, 1, 1)
local ESCURO = c(45, 40, 55)

local function topo(ctx: Ctx): number
	return ctx.corpo.Size.Y / 2 / ctx.e
end

local A: { [string]: (ctx: Ctx, cor: Color3) -> () } = {}

A.tampa = function(ctx, cor)
	local y = topo(ctx)
	tubo(ctx, cor, 0.3, 1.7, Vector3.new(0, y - 0.05, 0.05))
	bola(ctx, cor:Lerp(BRANCO, 0.3), Vector3.new(1.5, 0.45, 1.5), CFrame.new(0, (y + 0.12) * ctx.e, 0.05 * ctx.e))
	local puxador = bola(ctx, ctx.acento, Vector3.one * 0.5, CFrame.new(0, (y + 0.42) * ctx.e, 0.05 * ctx.e))
	fumaca(puxador, BRANCO, 0.8, 3)
end

A.torrada = function(ctx, _cor)
	local y = topo(ctx)
	for _, lado in { -1, 1 } do
		local cf = CFrame.new(0.2 * lado * ctx.e, (y + 0.35) * ctx.e, 0.1 * ctx.e)
			* CFrame.Angles(0, 0, math.rad(-8 * lado))
		bola(ctx, c(215, 150, 80), Vector3.new(0.8, 1.15, 0.32), cf)
		bola(ctx, c(255, 225, 165), Vector3.new(0.62, 0.92, 0.36), cf)
	end
end

A.bandana = function(ctx, cor)
	local s = ctx.corpo.Size / 2
	parte(ctx, "bola", cor, Vector3.new(s.X * 2.04, 0.42 * ctx.e, s.Z * 2.04), CFrame.new(0, s.Y * 0.42, 0))
	for _, lado in { -1, 1 } do
		bola(
			ctx,
			cor,
			Vector3.new(0.3, 0.3, 1.1),
			CFrame.new(0.25 * lado * ctx.e, s.Y * 0.4, s.Z + 0.35 * ctx.e)
				* CFrame.Angles(math.rad(25), math.rad(20 * lado), 0)
		)
	end
end

A.pirata = function(ctx, _cor)
	local y = topo(ctx)
	bola(ctx, ESCURO, Vector3.new(2.9, 0.45, 1.9), CFrame.new(0, (y - 0.05) * ctx.e, 0))
	bola(ctx, ESCURO, Vector3.new(1.7, 1, 1.4), CFrame.new(0, (y + 0.3) * ctx.e, 0.05 * ctx.e))
	bola(ctx, c(255, 205, 70), Vector3.new(1.75, 0.18, 1.45), CFrame.new(0, (y + 0.08) * ctx.e, 0.05 * ctx.e))
	bola(ctx, BRANCO, Vector3.new(0.4, 0.4, 0.15), CFrame.new(0, (y + 0.4) * ctx.e, -0.7 * ctx.e))
end

A.cobertura = function(ctx, cor)
	local s = ctx.corpo.Size / 2
	local e = ctx.e
	parte(ctx, "bola", cor, Vector3.new(s.X * 1.95, 1 * e, s.Z * 1.95), CFrame.new(0, s.Y - 0.3 * e, 0))
	for k = 0, 7 do
		local a = k / 8 * math.pi * 2
		bola(
			ctx,
			cor,
			Vector3.new(0.45, 0.8 - (k % 2) * 0.25, 0.45),
			CFrame.new(math.cos(a) * s.X * 0.82, s.Y - 0.75 * e - (k % 2) * 0.1 * e, math.sin(a) * s.Z * 0.82)
		)
	end
	bola(ctx, c(240, 40, 70), Vector3.one * 0.6, CFrame.new(0, s.Y + 0.4 * e, 0))
	bola(
		ctx,
		c(240, 120, 140),
		Vector3.new(0.18, 0.15, 0.1),
		CFrame.new(-0.12 * e, s.Y + 0.55 * e, -0.27 * e),
		Enum.Material.Neon
	)
end

A.sorvete = function(ctx, _cor)
	local y = topo(ctx)
	bola(ctx, c(255, 180, 205), Vector3.new(1.7, 1.2, 1.7), CFrame.new(0, (y + 0.15) * ctx.e, 0))
	bola(ctx, c(170, 235, 205), Vector3.new(1.35, 1, 1.35), CFrame.new(0, (y + 0.9) * ctx.e, 0))
	bola(ctx, c(240, 40, 70), Vector3.one * 0.5, CFrame.new(0, (y + 1.5) * ctx.e, 0))
end

A.pipoca = function(ctx, _cor)
	local y = topo(ctx)
	for k = 0, 7 do
		local a = k * 2.4
		local r = if k == 0 then 0 else 0.45 + (k % 2) * 0.15
		bola(
			ctx,
			if k % 3 == 0 then c(255, 240, 170) else BRANCO,
			Vector3.one * (0.75 - (k % 2) * 0.12),
			CFrame.new(
				math.cos(a) * r * ctx.e,
				(y + 0.1 + (if k == 0 then 0.45 else 0)) * ctx.e,
				math.sin(a) * r * ctx.e
			)
		)
	end
end

A.xicara = function(ctx, _cor)
	local y = topo(ctx)
	tubo(ctx, BRANCO, 1, 1.5, Vector3.new(0, y + 0.3, 0.05))
	tubo(ctx, c(120, 70, 45), 0.12, 1.32, Vector3.new(0, y + 0.8, 0.05))
	local alca =
		bola(ctx, BRANCO, Vector3.new(0.18, 0.7, 0.55), CFrame.new(0.85 * ctx.e, (y + 0.3) * ctx.e, 0.05 * ctx.e))
	alca.Name = "Acessorio"
	local espuma =
		bola(ctx, c(255, 245, 230), Vector3.new(0.6, 0.35, 0.6), CFrame.new(0.1 * ctx.e, (y + 0.9) * ctx.e, 0))
	fumaca(espuma, BRANCO, 0.7, 3)
end

A.broto = function(ctx, _cor)
	local y = topo(ctx)
	for k = -1, 1 do
		bola(
			ctx,
			c(100, 200, 90),
			Vector3.new(0.4, 1.2 - math.abs(k) * 0.2, 0.15),
			CFrame.new(k * 0.18 * ctx.e, (y + 0.45) * ctx.e, 0) * CFrame.Angles(0, k * 0.5, math.rad(-k * 28))
		)
	end
end

A.almofada = function(ctx, cor)
	local s = ctx.corpo.Size / 2
	local fofa = cor:Lerp(BRANCO, 0.5)
	bola(ctx, fofa, Vector3.new(2.4, 1.8, 0.7), CFrame.new(0, 0.2 * ctx.e, s.Z + 0.05 * ctx.e))
	bola(ctx, ctx.acento, Vector3.one * 0.3, CFrame.new(0, 0.2 * ctx.e, s.Z + 0.38 * ctx.e))
end

A.helice = function(ctx, cor)
	local y = topo(ctx)
	bola(ctx, cor, Vector3.new(1.2, 0.6, 1.2), CFrame.new(0, (y - 0.05) * ctx.e, 0))
	tubo(ctx, c(200, 205, 215), 0.5, 0.18, Vector3.new(0, y + 0.35, 0), Enum.Material.Metal)
	for k = 0, 2 do
		bola(
			ctx,
			c(210, 225, 240),
			Vector3.new(1.3, 0.08, 0.38),
			CFrame.new(0, (y + 0.6) * ctx.e, 0)
				* CFrame.Angles(0, k * math.pi * 2 / 3, 0)
				* CFrame.new(0.6 * ctx.e, 0, 0)
		)
	end
	bola(ctx, ctx.acento, Vector3.one * 0.3, CFrame.new(0, (y + 0.65) * ctx.e, 0))
end

-- tela na barriga (micro-ondas, televisão)
A.telinha = function(ctx, cor)
	-- telinha pequena na barriga, abaixo do focinho
	local s = ctx.corpo.Size / 2
	local y = -1.0 * ctx.e
	-- encostada na frente da barriga, abaixo da boca
	local z = -s.Z - 0.02 * ctx.e
	bola(ctx, ESCURO, Vector3.new(0.95, 0.62, 0.22), CFrame.new(0, y, z))
	local tela = bola(ctx, cor, Vector3.new(0.76, 0.46, 0.2), CFrame.new(0, y, z - 0.05 * ctx.e), Enum.Material.Neon)
	tela.Transparency = 0.15
	bola(
		ctx,
		BRANCO,
		Vector3.new(0.18, 0.1, 0.08),
		CFrame.new(-0.2 * ctx.e, y + 0.11 * ctx.e, z - 0.11 * ctx.e),
		Enum.Material.Neon
	)
end

A.abajur = function(ctx, _cor)
	local y = topo(ctx)
	local cupula = tubo(ctx, c(255, 240, 200), 1.1, 1.9, Vector3.new(0, y + 0.45, 0))
	tubo(ctx, ctx.acento, 0.14, 1.95, Vector3.new(0, y + 0.95, 0))
	tubo(ctx, ctx.acento, 0.14, 1.95, Vector3.new(0, y - 0.05, 0))
	local luz = Instance.new("PointLight")
	luz.Color = c(255, 220, 150)
	luz.Range = 8
	luz.Brightness = 1.2
	luz.Parent = cupula
end

A.chinelo = function(ctx, cor)
	for _, lado in { -1, 1 } do
		bola(
			ctx,
			cor:Lerp(ctx.acento, 0.5),
			Vector3.new(1.25, 0.2, 1.7),
			CFrame.new(0.8 * lado * ctx.e, -1.66 * ctx.e, -0.3 * ctx.e)
		)
		bola(
			ctx,
			c(255, 110, 140),
			Vector3.new(0.9, 0.16, 0.2),
			CFrame.new(0.8 * lado * ctx.e, -1.4 * ctx.e, -0.75 * ctx.e)
		)
	end
end

A.mochila = function(ctx, cor)
	local s = ctx.corpo.Size / 2
	local bolsa = c(240, 120, 90)
	bola(ctx, bolsa, Vector3.new(2, 2.1, 1), CFrame.new(0, 0, s.Z + 0.1 * ctx.e))
	bola(ctx, bolsa:Lerp(BRANCO, 0.25), Vector3.new(1.3, 0.9, 0.5), CFrame.new(0, -0.35 * ctx.e, s.Z + 0.55 * ctx.e))
	bola(ctx, bolsa:Lerp(ESCURO, 0.3), Vector3.new(1.9, 0.7, 0.6), CFrame.new(0, 0.7 * ctx.e, s.Z + 0.35 * ctx.e))
	local _ = cor
end

A.relogio = function(ctx, _cor)
	local s = ctx.corpo.Size / 2
	local z = -s.Z + 0.1 * ctx.e
	bola(ctx, ctx.acento, Vector3.new(1.45, 1.45, 0.22), CFrame.new(0, -0.55 * ctx.e, z))
	bola(ctx, BRANCO, Vector3.new(1.2, 1.2, 0.24), CFrame.new(0, -0.55 * ctx.e, z - 0.05 * ctx.e))
	parte(ctx, "bloco", ESCURO, Vector3.new(0.08, 0.45, 0.05) * ctx.e, CFrame.new(0, -0.38 * ctx.e, z - 0.18 * ctx.e))
	parte(
		ctx,
		"bloco",
		ESCURO,
		Vector3.new(0.35, 0.08, 0.05) * ctx.e,
		CFrame.new(0.15 * ctx.e, -0.55 * ctx.e, z - 0.18 * ctx.e)
	)
end

A.meias = function(ctx, _cor)
	for _, lado in { -1, 1 } do
		for k = 0, 1 do
			bola(
				ctx,
				if k == 0 then BRANCO else c(255, 120, 150),
				Vector3.new(1.2, 0.2, 1.5),
				CFrame.new(0.8 * lado * ctx.e, (-1.3 + k * 0.18) * ctx.e, -0.25 * ctx.e)
			)
		end
	end
end

A.cerdas = function(ctx, _cor)
	local y = topo(ctx)
	for k = 0, 5 do
		local z = -0.5 + k * 0.2
		tubo(
			ctx,
			if k % 2 == 0 then BRANCO else c(120, 200, 255),
			0.7,
			0.22,
			Vector3.new(0, y + 0.2 - math.abs(z) * 0.25, z)
		)
	end
end

A.tenis = function(ctx, cor)
	for _, lado in { -1, 1 } do
		bola(ctx, BRANCO, Vector3.new(1.2, 0.26, 1.55), CFrame.new(0.8 * lado * ctx.e, -1.62 * ctx.e, -0.3 * ctx.e))
		bola(
			ctx,
			cor:Lerp(ESCURO, 0.4),
			Vector3.new(0.5, 0.12, 0.6),
			CFrame.new(0.8 * lado * ctx.e, -1.3 * ctx.e, -0.65 * ctx.e)
		)
	end
end

A.rodinhas = function(ctx, _cor)
	for _, lado in { -1, 1 } do
		for _, z in { -0.75, 0.25 } do
			parte(
				ctx,
				"cilindro",
				c(255, 205, 70),
				Vector3.new(0.25, 0.56, 0.56) * ctx.e,
				CFrame.new(1.28 * lado * ctx.e, -1.47 * ctx.e, z * ctx.e)
			)
		end
	end
end

A.torre = function(ctx, cor)
	local y = topo(ctx)
	tubo(ctx, cor, 1.2, 1.4, Vector3.new(0.15, y + 0.4, 0.2))
	for k = 0, 3 do
		local a = k / 4 * math.pi * 2
		parte(
			ctx,
			"bloco",
			cor,
			Vector3.new(0.38, 0.38, 0.38) * ctx.e,
			CFrame.new((0.15 + math.cos(a) * 0.55) * ctx.e, (y + 1.15) * ctx.e, (0.2 + math.sin(a) * 0.55) * ctx.e)
		)
	end
	tubo(ctx, ESCURO, 1, 0.08, Vector3.new(0.15, y + 1.6, 0.2))
	parte(
		ctx,
		"cunha",
		c(255, 90, 90),
		Vector3.new(0.06, 0.4, 0.6) * ctx.e,
		CFrame.new(0.15 * ctx.e, (y + 1.9) * ctx.e, 0.5 * ctx.e) * CFrame.Angles(0, 0, 0)
	)
end

A.aquario = function(ctx, _cor)
	local s = ctx.corpo.Size / 2
	local vidro = parte(
		ctx,
		"bola",
		c(200, 240, 255),
		Vector3.new(s.X * 2.5, s.Y * 2.4, s.Z * 2.5),
		CFrame.new(0, 0.15 * ctx.e, 0),
		Enum.Material.Glass
	)
	vidro.Transparency = 0.75
	vidro.CanQuery = false
	local bolhas = Instance.new("ParticleEmitter")
	bolhas.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	bolhas.Color = ColorSequence.new(BRANCO)
	bolhas.Size = NumberSequence.new(0.25)
	bolhas.Transparency = NumberSequence.new(0.3, 1)
	bolhas.Lifetime = NumberRange.new(1.5, 2.2)
	bolhas.Speed = NumberRange.new(1, 1.6)
	bolhas.EmissionDirection = Enum.NormalId.Top
	bolhas.SpreadAngle = Vector2.new(25, 25)
	bolhas.Rate = 4
	bolhas.Parent = ctx.corpo
end

A.vulcao = function(ctx, _cor)
	local y = topo(ctx)
	local terra = c(150, 95, 70)
	bola(ctx, terra, Vector3.new(1.8, 0.8, 1.8), CFrame.new(0, (y + 0.05) * ctx.e, 0))
	bola(ctx, terra, Vector3.new(1.25, 0.8, 1.25), CFrame.new(0, (y + 0.45) * ctx.e, 0))
	local lava = bola(
		ctx,
		c(255, 120, 40),
		Vector3.new(0.9, 0.35, 0.9),
		CFrame.new(0, (y + 0.82) * ctx.e, 0),
		Enum.Material.Neon
	)
	fumaca(lava, c(120, 110, 110), 1, 4)
end

A.cartola = function(ctx, _cor)
	local y = topo(ctx)
	tubo(ctx, ESCURO, 0.14, 2, Vector3.new(0, y - 0.05, 0))
	tubo(ctx, ESCURO, 1.2, 1.25, Vector3.new(0, y + 0.55, 0))
	tubo(ctx, c(255, 90, 110), 0.25, 1.28, Vector3.new(0, y + 0.15, 0))
end

A.guardachuva = function(ctx, cor)
	local y = topo(ctx)
	tubo(ctx, ESCURO, 1.6, 0.1, Vector3.new(0, y + 0.7, 0))
	bola(ctx, cor, Vector3.new(3.6, 1.2, 3.6), CFrame.new(0, (y + 1.6) * ctx.e, 0))
	for k = 0, 5 do
		local a = k / 6 * math.pi * 2
		bola(
			ctx,
			if k % 2 == 0 then BRANCO else cor,
			Vector3.new(0.55, 0.4, 0.55),
			CFrame.new(math.cos(a) * 1.65 * ctx.e, (y + 1.35) * ctx.e, math.sin(a) * 1.65 * ctx.e)
		)
	end
	bola(ctx, ESCURO, Vector3.one * 0.3, CFrame.new(0, (y + 2.25) * ctx.e, 0))
end

A.chamine = function(ctx, _cor)
	local y = topo(ctx)
	tubo(ctx, ESCURO, 0.9, 0.8, Vector3.new(0, y + 0.3, -0.2))
	local boca = tubo(ctx, ESCURO, 0.25, 1.15, Vector3.new(0, y + 0.85, -0.2))
	tubo(ctx, c(255, 200, 60), 0.15, 0.85, Vector3.new(0, y + 0.45, -0.2))
	fumaca(boca, c(230, 230, 235), 1.1, 4)
end

A.lapis = function(ctx, _cor)
	local y = topo(ctx)
	tubo(ctx, c(255, 205, 60), 1, 0.9, Vector3.new(0, y + 0.3, 0))
	bola(ctx, c(255, 225, 180), Vector3.new(0.9, 0.9, 0.9), CFrame.new(0, (y + 0.85) * ctx.e, 0))
	bola(ctx, ESCURO, Vector3.new(0.35, 0.45, 0.35), CFrame.new(0, (y + 1.25) * ctx.e, 0))
	tubo(ctx, c(255, 150, 170), 0.3, 0.92, Vector3.new(0, y - 0.15, 0))
end

A.foguete = function(ctx, _cor)
	local s = ctx.corpo.Size / 2
	for k = 0, 2 do
		local a = (k - 1) * 0.9
		parte(
			ctx,
			"cunha",
			c(255, 90, 90),
			Vector3.new(0.15, 1, 0.9) * ctx.e,
			CFrame.new(math.sin(a) * s.X * 0.9, -0.5 * ctx.e, s.Z * 0.75) * CFrame.Angles(0, a, 0)
		)
	end
	local bocal = bola(
		ctx,
		c(200, 205, 215),
		Vector3.new(0.7, 0.7, 0.4),
		CFrame.new(0, -0.4 * ctx.e, s.Z + 0.05 * ctx.e),
		Enum.Material.Metal
	)
	local fogo = Instance.new("ParticleEmitter")
	fogo.Texture = "rbxasset://textures/particles/fire_main.dds"
	fogo.Color = ColorSequence.new(c(255, 230, 120), c(255, 90, 40))
	fogo.Size = NumberSequence.new(0.7 * ctx.e, 0.1)
	fogo.Lifetime = NumberRange.new(0.25, 0.4)
	fogo.Speed = NumberRange.new(4, 6)
	fogo.EmissionDirection = Enum.NormalId.Back
	fogo.LightEmission = 1
	fogo.Rate = 20
	fogo.Parent = bocal
end

A.raio = function(ctx, _cor)
	local y = topo(ctx)
	local amarelo = c(255, 225, 60)
	parte(
		ctx,
		"bloco",
		amarelo,
		Vector3.new(0.35, 0.9, 0.2) * ctx.e,
		CFrame.new(0.1 * ctx.e, (y + 0.45) * ctx.e, 0) * CFrame.Angles(0, 0, math.rad(-25)),
		Enum.Material.Neon
	)
	parte(
		ctx,
		"bloco",
		amarelo,
		Vector3.new(0.35, 0.9, 0.2) * ctx.e,
		CFrame.new(-0.05 * ctx.e, (y + 1.1) * ctx.e, 0) * CFrame.Angles(0, 0, math.rad(25)),
		Enum.Material.Neon
	)
	local faisca = Instance.new("ParticleEmitter")
	faisca.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	faisca.Color = ColorSequence.new(amarelo, BRANCO)
	faisca.Size = NumberSequence.new(0.4, 0)
	faisca.Lifetime = NumberRange.new(0.2, 0.4)
	faisca.Speed = NumberRange.new(3, 5)
	faisca.SpreadAngle = Vector2.new(180, 180)
	faisca.LightEmission = 1
	faisca.Rate = 8
	faisca.Parent = ctx.corpo
end

A.anel = function(ctx, _cor)
	local s = ctx.corpo.Size / 2
	local r = math.max(s.X, s.Z) + 0.7 * ctx.e
	local giro = CFrame.Angles(math.rad(18), 0, math.rad(-12))
	for k = 0, 15 do
		local a = k / 16 * math.pi * 2
		local p = parte(
			ctx,
			"bola",
			if k % 2 == 0 then ctx.acento else c(190, 160, 255),
			Vector3.new(0.4, 0.2, 0.4) * ctx.e,
			CFrame.new(0, 0.2 * ctx.e, 0) * giro * CFrame.new(math.cos(a) * r, 0, math.sin(a) * r),
			Enum.Material.Neon
		)
		p.CanQuery = false
	end
end

function Estilo.acessorio(ctx: Ctx, tipo: string?, cor: Color3?)
	if not tipo then
		return
	end
	local f = A[tipo]
	if f then
		f(ctx, cor or ctx.cor:Lerp(ctx.acento, 0.35))
	end
end

return Estilo
