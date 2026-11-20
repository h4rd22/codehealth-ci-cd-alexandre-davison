--!strict
-- Traços de bicho de cada Mistureba: formato do corpo, orelhas, focinho, chifres,
-- cauda, coisas nas costas e padrão da pele. É isso que deixa cada uma diferente
-- das outras (a "fantasia" de objeto vem do Config e fica em cima da cabeça).
-- Frente do bicho = -Z, cima = +Y, lado = X. Tudo com bolinhas ovais (leve no celular).

local Tracos = {}

export type Ficha = {
	forma: Vector3?, -- multiplica o tamanho do corpo (X largura, Y altura, Z comprimento)
	orelhas: string?,
	focinho: string?,
	chifre: string?,
	cauda: string?,
	costas: { string }?,
	padrao: string?,
	corPadrao: Color3?,
}

local function c(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

-- Ficha de cada Mistureba (a metade "bicho" do nome)
Tracos.Fichas = {
	chaleiruga = { forma = Vector3.new(1.15, 1, 1.1), orelhas = "nenhuma", cauda = "curta", costas = { "casco" } },
	tubarone = {
		forma = Vector3.new(1.05, 1, 1.3),
		orelhas = "nenhuma",
		focinho = "dentes",
		cauda = "peixe",
		costas = { "barbatana" },
	},
	meiaranha = { orelhas = "nenhuma", costas = { "patas" }, padrao = "listras", corPadrao = c(255, 255, 255) },
	pastelossauro = {
		forma = Vector3.new(1, 1.1, 1.15),
		orelhas = "nenhuma",
		cauda = "dragao",
		costas = { "espinhos" },
	},
	torracoelho = { orelhas = "coelho", focinho = "dentes", cauda = "pom" },
	abacataoninja = { orelhas = "folha", cauda = "curta", costas = { "caroco" } },
	geladeirapirata = {
		forma = Vector3.new(1, 1.15, 1),
		orelhas = "redonda",
		cauda = "curta",
		costas = { "tapaolho" },
	},
	polvonete = { forma = Vector3.new(1, 1.2, 1), orelhas = "nenhuma", costas = { "patas" }, padrao = "pintas" },
	escovadragao = {
		orelhas = "nenhuma",
		chifre = "dragao",
		cauda = "dragao",
		costas = { "espinhos" },
		padrao = "pintas",
	},
	sofassauro = {
		forma = Vector3.new(1.1, 1.05, 1.2),
		orelhas = "nenhuma",
		focinho = "dentes",
		cauda = "dragao",
		costas = { "espinhos" },
	},
	pianoceronte = {
		forma = Vector3.new(1.25, 1, 1.2),
		orelhas = "redonda",
		chifre = "rino",
		cauda = "fina",
		padrao = "teclas",
	},
	guardachuvalo = { orelhas = "gato", focinho = "focinho", cauda = "crina", costas = { "crina" } },
	liquidificorvo = { orelhas = "nenhuma", focinho = "bico", cauda = "pena", costas = { "crista" } },
	microleao = { orelhas = "redonda", focinho = "focinho", cauda = "gato", costas = { "juba" } },
	baleiastelo = { forma = Vector3.new(1.35, 1, 1.35), orelhas = "nenhuma", cauda = "baleia", costas = { "jato" } },
	girafatrem = {
		forma = Vector3.new(1, 1.2, 1.05),
		orelhas = "gato",
		focinho = "focinho",
		chifre = "girafa",
		cauda = "fina",
		padrao = "pintas",
		corPadrao = c(150, 90, 40),
	},
	pinguivulcao = { forma = Vector3.new(1, 1.2, 1), orelhas = "nenhuma", focinho = "bico", costas = { "nadadeiras" } },
	nuvemcornio = { orelhas = "gato", chifre = "unicornio", cauda = "crina", costas = { "nuvem", "crina" } },
	reimistureba = {
		forma = Vector3.new(1.1, 1.1, 1.1),
		orelhas = "gato",
		chifre = "dragao",
		cauda = "dragao",
		costas = { "capa", "juba" },
	},
	bugigangacosmica = { orelhas = "nenhuma", chifre = "antena", cauda = "curta", costas = { "cubos" } },
	lapisquilo = { orelhas = "gato", focinho = "dentes", cauda = "fofa" },
	bolachorro = { orelhas = "caida", focinho = "focinho", cauda = "gato", padrao = "pintas" },
	chinelefante = { forma = Vector3.new(1.2, 1, 1.1), orelhas = "elefante", focinho = "tromba", cauda = "fina" },
	cenourato = { orelhas = "redonda", focinho = "dentes", cauda = "fina", costas = { "bigode" } },
	abajurubu = { orelhas = "nenhuma", focinho = "bico", cauda = "pena", costas = { "crista" } },
	sorvetigre = { orelhas = "redonda", focinho = "focinho", cauda = "gato", padrao = "listras" },
	relocoruja = { forma = Vector3.new(1.05, 1.1, 1), orelhas = "tufo", focinho = "bico", cauda = "pena" },
	mochilontra = { orelhas = "redonda", focinho = "focinho", cauda = "grossa", costas = { "bigode" } },
	patinepato = { orelhas = "nenhuma", focinho = "bicopato", cauda = "pena", costas = { "topete" } },
	cupcameleao = { orelhas = "nenhuma", cauda = "enrolada", costas = { "crista" }, padrao = "pintas" },
	robelha = {
		orelhas = "nenhuma",
		chifre = "antena",
		cauda = "ferrao",
		costas = { "asinseto" },
		padrao = "listras",
		corPadrao = c(40, 35, 40),
	},
	televisapo = { forma = Vector3.new(1.25, 1, 1.05), orelhas = "nenhuma", costas = { "olhosapo" }, padrao = "pintas" },
	foguetucano = { orelhas = "nenhuma", focinho = "tucano", cauda = "pena", costas = { "crista" } },
	pipocavalo = { orelhas = "gato", focinho = "focinho", cauda = "crina", costas = { "crina" }, padrao = "pintas" },
	castelobo = { orelhas = "gato", focinho = "focinho", cauda = "fofa", costas = { "juba" } },
	trovanguru = {
		forma = Vector3.new(1, 1.15, 1),
		orelhas = "coelho",
		focinho = "focinho",
		cauda = "grossa",
		costas = { "bolsa" },
	},
	aquariorca = {
		forma = Vector3.new(1.15, 1, 1.3),
		orelhas = "nenhuma",
		cauda = "baleia",
		costas = { "barbatana", "manchaorca" },
	},
	fenixicara = { orelhas = "nenhuma", focinho = "bico", cauda = "fenix", costas = { "crista", "fogo" } },
	dragalaxia = {
		forma = Vector3.new(1.05, 1.05, 1.2),
		orelhas = "nenhuma",
		chifre = "dragao",
		cauda = "dragao",
		costas = { "espinhos" },
		padrao = "estrelas",
	},
	misturebasuprema = {
		forma = Vector3.new(1.1, 1.1, 1.1),
		orelhas = "coelho",
		chifre = "unicornio",
		cauda = "dragao",
		costas = { "juba", "capa", "cubos" },
		padrao = "estrelas",
	},
} :: { [string]: Ficha }

type Ctx = {
	modelo: Model,
	corpo: BasePart,
	e: number,
	cor: Color3,
	segunda: Color3,
	clara: Color3,
}

local function oval(part: BasePart)
	local malha = Instance.new("SpecialMesh")
	malha.MeshType = Enum.MeshType.Sphere
	malha.Parent = part
end

local function soldar(a: BasePart, b: BasePart)
	local solda = Instance.new("WeldConstraint")
	solda.Part0 = a
	solda.Part1 = b
	solda.Parent = b
end

-- bolinha oval presa no corpo; tam em studs (sem escala), cf em relação ao corpo
local function bola(ctx: Ctx, nome: string, cor: Color3, tam: Vector3, cf: CFrame, material: Enum.Material?): BasePart
	local p = Instance.new("Part")
	oval(p)
	p.Name = nome
	p.Size = tam
	p.Color = cor
	p.Material = material or Enum.Material.SmoothPlastic
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

local function cunha(ctx: Ctx, nome: string, cor: Color3, tam: Vector3, cf: CFrame): BasePart
	local p = Instance.new("WedgePart")
	p.Name = nome
	p.Size = tam
	p.Color = cor
	p.Material = Enum.Material.SmoothPlastic
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

-- ponto na pele do corpo (elipsoide) na direção dada, e a normal ali
local function pele(ctx: Ctx, dir: Vector3, fora: number?): (Vector3, Vector3)
	local s = ctx.corpo.Size / 2
	local d = dir.Unit
	local t = 1 / math.sqrt((d.X / s.X) ^ 2 + (d.Y / s.Y) ^ 2 + (d.Z / s.Z) ^ 2)
	local p = d * t
	local n = Vector3.new(p.X / (s.X * s.X), p.Y / (s.Y * s.Y), p.Z / (s.Z * s.Z)).Unit
	return p + n * (fora or 0) * ctx.e, n
end

-- pintinha achatada deitada na pele
local function mancha(ctx: Ctx, nome: string, cor: Color3, tam: Vector3, dir: Vector3, material: Enum.Material?)
	local p, n = pele(ctx, dir, -0.02)
	return bola(ctx, nome, cor, tam * ctx.e, CFrame.lookAt(p, p + n), material)
end

local ROSA = c(255, 150, 180)

local function orelhas(ctx: Ctx, tipo: string)
	local e = ctx.e
	local function par(fn: (lado: number) -> ())
		fn(-1)
		fn(1)
	end
	if tipo == "gato" then
		par(function(lado)
			local p = pele(ctx, Vector3.new(0.55 * lado, 0.85, 0.05))
			local giro = CFrame.Angles(0, 0, math.rad(-18 * lado))
			bola(
				ctx,
				"Orelha",
				ctx.cor,
				Vector3.new(0.75, 1.05, 0.4) * e,
				CFrame.new(p + Vector3.new(0, 0.3 * e, 0)) * giro
			)
			bola(
				ctx,
				"Orelha",
				ROSA,
				Vector3.new(0.42, 0.65, 0.2) * e,
				CFrame.new(p + Vector3.new(0, 0.28 * e, -0.14 * e)) * giro
			)
		end)
	elseif tipo == "coelho" then
		par(function(lado)
			local p = pele(ctx, Vector3.new(0.38 * lado, 0.95, 0.05))
			local giro = CFrame.Angles(math.rad(8), 0, math.rad(-10 * lado))
			bola(
				ctx,
				"Orelha",
				ctx.cor,
				Vector3.new(0.6, 2, 0.4) * e,
				CFrame.new(p + Vector3.new(0.1 * lado, 0.85, 0) * e) * giro
			)
			bola(
				ctx,
				"Orelha",
				ROSA,
				Vector3.new(0.34, 1.5, 0.2) * e,
				CFrame.new(p + Vector3.new(0.1 * lado, 0.85, -0.14) * e) * giro
			)
		end)
	elseif tipo == "redonda" then
		par(function(lado)
			local p = pele(ctx, Vector3.new(0.7 * lado, 0.75, 0.05))
			bola(ctx, "Orelha", ctx.cor, Vector3.new(0.95, 0.95, 0.4) * e, CFrame.new(p + Vector3.new(0, 0.2 * e, 0)))
			bola(
				ctx,
				"Orelha",
				ROSA,
				Vector3.new(0.55, 0.55, 0.2) * e,
				CFrame.new(p + Vector3.new(0, 0.2 * e, -0.15 * e))
			)
		end)
	elseif tipo == "caida" then
		par(function(lado)
			local p = pele(ctx, Vector3.new(0.85 * lado, 0.55, -0.05))
			bola(
				ctx,
				"Orelha",
				ctx.segunda,
				Vector3.new(0.45, 1.5, 0.75) * e,
				CFrame.new(p + Vector3.new(0.12 * lado, -0.35, 0) * e) * CFrame.Angles(0, 0, math.rad(20 * lado))
			)
		end)
	elseif tipo == "elefante" then
		par(function(lado)
			local p = pele(ctx, Vector3.new(lado, 0.25, 0.15))
			bola(
				ctx,
				"Orelha",
				ctx.cor:Lerp(Color3.new(0, 0, 0), 0.12),
				Vector3.new(0.3, 1.9, 1.7) * e,
				CFrame.new(p + Vector3.new(0.12 * lado, 0.1, 0.1) * e) * CFrame.Angles(0, math.rad(-25 * lado), 0)
			)
			bola(
				ctx,
				"Orelha",
				ROSA,
				Vector3.new(0.2, 1.3, 1.1) * e,
				CFrame.new(p + Vector3.new(0.05 * lado, 0.1, 0) * e) * CFrame.Angles(0, math.rad(-25 * lado), 0)
			)
		end)
	elseif tipo == "folha" then
		par(function(lado)
			local p = pele(ctx, Vector3.new(0.3 * lado, 1, 0))
			bola(
				ctx,
				"Orelha",
				c(110, 200, 80),
				Vector3.new(0.6, 1.4, 0.15) * e,
				CFrame.new(p + Vector3.new(0.25 * lado, 0.55, 0) * e) * CFrame.Angles(0, 0, math.rad(-35 * lado))
			)
		end)
	elseif tipo == "tufo" then
		par(function(lado)
			local p = pele(ctx, Vector3.new(0.6 * lado, 0.85, -0.1))
			bola(
				ctx,
				"Orelha",
				ctx.segunda,
				Vector3.new(0.4, 1, 0.35) * e,
				CFrame.new(p + Vector3.new(0.1 * lado, 0.35, 0) * e) * CFrame.Angles(0, 0, math.rad(-30 * lado))
			)
		end)
	end
end

local function focinho(ctx: Ctx, tipo: string)
	local e = ctx.e
	local frente = -ctx.corpo.Size.Z / 2
	if tipo == "bico" then
		bola(
			ctx,
			"Focinho",
			c(255, 170, 50),
			Vector3.new(0.6, 0.4, 0.8) * e,
			CFrame.new(0, -0.12 * e, frente - 0.1 * e)
		)
	elseif tipo == "bicopato" then
		bola(
			ctx,
			"Focinho",
			c(255, 170, 50),
			Vector3.new(1.1, 0.3, 0.9) * e,
			CFrame.new(0, -0.2 * e, frente - 0.15 * e)
		)
	elseif tipo == "tucano" then
		bola(
			ctx,
			"Focinho",
			c(255, 160, 40),
			Vector3.new(0.75, 0.7, 1.8) * e,
			CFrame.new(0, -0.15 * e, frente - 0.55 * e)
		)
		bola(ctx, "Focinho", c(40, 30, 30), Vector3.new(0.45, 0.4, 0.45) * e, CFrame.new(0, -0.2 * e, frente - 1.3 * e))
		bola(
			ctx,
			"Focinho",
			c(255, 230, 60),
			Vector3.new(0.65, 0.3, 0.9) * e,
			CFrame.new(0, 0.05 * e, frente - 0.35 * e)
		)
	elseif tipo == "focinho" then
		bola(ctx, "Focinho", ctx.clara, Vector3.new(1.05, 0.7, 0.6) * e, CFrame.new(0, -0.25 * e, frente + 0.1 * e))
		bola(
			ctx,
			"Focinho",
			c(60, 35, 45),
			Vector3.new(0.38, 0.26, 0.2) * e,
			CFrame.new(0, -0.05 * e, frente - 0.15 * e)
		)
	elseif tipo == "tromba" then
		for i = 0, 3 do
			bola(
				ctx,
				"Focinho",
				ctx.cor,
				Vector3.one * (0.62 - i * 0.08) * e,
				CFrame.new(0, (-0.15 - i * 0.32) * e, frente - (0.2 + i * 0.12) * e)
			)
		end
	elseif tipo == "dentes" then
		for _, lado in { -1, 1 } do
			local d = Instance.new("Part")
			d.Name = "Dente"
			d.Size = Vector3.new(0.16, 0.2, 0.08) * e
			d.Color = Color3.new(1, 1, 1)
			d.CanCollide = false
			d.CanTouch = false
			d.Massless = true
			d.CastShadow = false
			d.CFrame = ctx.corpo.CFrame * CFrame.new(0.09 * lado * e, -0.36 * e, frente - 0.04 * e)
			d.Parent = ctx.modelo
			soldar(ctx.corpo, d)
		end
	end
end

local function chifre(ctx: Ctx, tipo: string)
	local e = ctx.e
	if tipo == "unicornio" then
		local p = pele(ctx, Vector3.new(0, 0.9, -0.45))
		local giro = CFrame.Angles(math.rad(-25), 0, 0)
		for i = 0, 2 do
			bola(
				ctx,
				"Chifre",
				if i % 2 == 0 then c(255, 230, 120) else c(255, 255, 255),
				Vector3.new(0.42 - i * 0.11, 0.6, 0.42 - i * 0.11) * e,
				CFrame.new(p) * giro * CFrame.new(0, (0.2 + i * 0.42) * e, 0),
				Enum.Material.Neon
			)
		end
	elseif tipo == "rino" then
		local frente = -ctx.corpo.Size.Z / 2
		bola(
			ctx,
			"Chifre",
			c(250, 240, 220),
			Vector3.new(0.45, 1, 0.45) * e,
			CFrame.new(0, 0.05 * e, frente - 0.1 * e) * CFrame.Angles(math.rad(-40), 0, 0) * CFrame.new(0, 0.4 * e, 0)
		)
	elseif tipo == "dragao" then
		for _, lado in { -1, 1 } do
			local p = pele(ctx, Vector3.new(0.45 * lado, 0.9, 0.15))
			local giro = CFrame.Angles(math.rad(35), 0, math.rad(-20 * lado))
			bola(
				ctx,
				"Chifre",
				c(250, 235, 200),
				Vector3.new(0.34, 0.75, 0.34) * e,
				CFrame.new(p) * giro * CFrame.new(0, 0.3 * e, 0)
			)
			bola(
				ctx,
				"Chifre",
				c(250, 235, 200),
				Vector3.new(0.22, 0.55, 0.22) * e,
				CFrame.new(p) * giro * CFrame.new(0, 0.7 * e, 0.18 * e)
			)
		end
	elseif tipo == "antena" then
		for _, lado in { -1, 1 } do
			local p = pele(ctx, Vector3.new(0.35 * lado, 0.95, -0.1))
			local giro = CFrame.Angles(math.rad(-15), 0, math.rad(-20 * lado))
			bola(
				ctx,
				"Chifre",
				c(40, 35, 40),
				Vector3.new(0.12, 1, 0.12) * e,
				CFrame.new(p) * giro * CFrame.new(0, 0.45 * e, 0)
			)
			bola(
				ctx,
				"Chifre",
				ctx.segunda,
				Vector3.one * 0.32 * e,
				CFrame.new(p) * giro * CFrame.new(0, 0.95 * e, 0),
				Enum.Material.Neon
			)
		end
	elseif tipo == "girafa" then
		for _, lado in { -1, 1 } do
			local p = pele(ctx, Vector3.new(0.25 * lado, 1, 0.1))
			bola(ctx, "Chifre", ctx.cor, Vector3.new(0.2, 0.7, 0.2) * e, CFrame.new(p + Vector3.new(0, 0.3 * e, 0)))
			bola(ctx, "Chifre", c(150, 90, 40), Vector3.one * 0.3 * e, CFrame.new(p + Vector3.new(0, 0.65 * e, 0)))
		end
	end
end

local function cauda(ctx: Ctx, tipo: string)
	local e = ctx.e
	local tras = ctx.corpo.Size.Z / 2
	local base = Vector3.new(0, -0.55 * e, tras - 0.1 * e)
	if tipo == "curta" then
		bola(ctx, "Rabo", ctx.segunda, Vector3.one * 0.8 * e, CFrame.new(base))
	elseif tipo == "pom" then
		bola(ctx, "Rabo", Color3.new(1, 1, 1), Vector3.one * 1 * e, CFrame.new(base + Vector3.new(0, 0, 0.1 * e)))
	elseif tipo == "peixe" or tipo == "baleia" then
		bola(ctx, "Rabo", ctx.cor, Vector3.new(0.6, 0.6, 1) * e, CFrame.new(base + Vector3.new(0, 0.1, 0.4) * e))
		for _, lado in { -1, 1 } do
			local giro = if tipo == "peixe"
				then CFrame.Angles(math.rad(-35 * lado), 0, 0)
				else CFrame.Angles(0, math.rad(35 * lado), 0)
			local tam = if tipo == "peixe" then Vector3.new(0.2, 1.3, 0.7) else Vector3.new(1.3, 0.2, 0.7)
			local off = if tipo == "peixe"
				then Vector3.new(0, 0.45 * lado, 0.95)
				else Vector3.new(0.45 * lado, 0.1, 0.95)
			bola(ctx, "Rabo", ctx.segunda, tam * e, CFrame.new(base + off * e) * giro)
		end
	elseif tipo == "gato" or tipo == "fina" or tipo == "dragao" then
		local n = if tipo == "fina" then 3 else 4
		local grossura = if tipo == "dragao" then 0.7 elseif tipo == "fina" then 0.3 else 0.42
		for i = 1, n do
			local t = i / n
			local pos = base + Vector3.new(0, (t * t * 1.2 - 0.1) * e, (0.25 + t * 0.9) * e)
			bola(ctx, "Rabo", ctx.cor, Vector3.one * grossura * (1.1 - t * 0.45) * e, CFrame.new(pos))
		end
		local ponta = base + Vector3.new(0, 1.15 * e, 1.2 * e)
		if tipo == "gato" then
			bola(ctx, "Rabo", ctx.segunda, Vector3.one * 0.5 * e, CFrame.new(ponta))
		elseif tipo == "dragao" then
			cunha(
				ctx,
				"Rabo",
				ctx.segunda,
				Vector3.new(0.12, 0.6, 0.6) * e,
				CFrame.new(ponta + Vector3.new(0, 0.15 * e, 0.1 * e))
			)
		end
	elseif tipo == "fofa" then
		bola(
			ctx,
			"Rabo",
			ctx.segunda,
			Vector3.new(1, 2.1, 0.9) * e,
			CFrame.new(base + Vector3.new(0, 1, 0.55) * e) * CFrame.Angles(math.rad(-20), 0, 0)
		)
		bola(ctx, "Rabo", ctx.clara, Vector3.new(0.75, 0.8, 0.7) * e, CFrame.new(base + Vector3.new(0, 2, 0.35) * e))
	elseif tipo == "crina" then
		for i = 0, 2 do
			bola(
				ctx,
				"Rabo",
				ctx.segunda,
				Vector3.new(0.35, 1.2, 0.35) * e,
				CFrame.new(base + Vector3.new((i - 1) * 0.15, -0.1, 0.3) * e)
					* CFrame.Angles(math.rad(-30), 0, math.rad((i - 1) * 15))
					* CFrame.new(0, -0.3 * e, 0)
			)
		end
	elseif tipo == "pena" or tipo == "fenix" then
		local n = if tipo == "fenix" then 5 else 3
		for i = 1, n do
			local a = (i - (n + 1) / 2) * 22
			bola(
				ctx,
				"Rabo",
				if tipo == "fenix" then (if i % 2 == 0 then c(255, 200, 60) else c(255, 90, 40)) else ctx.segunda,
				Vector3.new(0.35, 0.18, if tipo == "fenix" then 2.2 else 1.3) * e,
				CFrame.new(base + Vector3.new(0, 0.2, 0.2) * e)
					* CFrame.Angles(math.rad(-20), math.rad(a), 0)
					* CFrame.new(0, 0, (if tipo == "fenix" then 1 else 0.6) * e),
				if tipo == "fenix" then Enum.Material.Neon else nil
			)
		end
	elseif tipo == "grossa" then
		bola(
			ctx,
			"Rabo",
			ctx.cor,
			Vector3.new(0.7, 0.6, 2) * e,
			CFrame.new(base + Vector3.new(0, -0.45, 0.75) * e) * CFrame.Angles(math.rad(12), 0, 0)
		)
	elseif tipo == "enrolada" then
		for i = 0, 6 do
			local a = i * 0.9
			local r = (0.55 - i * 0.05) * e
			bola(
				ctx,
				"Rabo",
				if i % 2 == 0 then ctx.cor else ctx.segunda,
				Vector3.one * (0.45 - i * 0.03) * e,
				CFrame.new(base + Vector3.new(0, 0.5 * e + math.sin(a) * r, 0.75 * e + math.cos(a) * r))
			)
		end
	elseif tipo == "ferrao" then
		bola(ctx, "Rabo", c(40, 35, 40), Vector3.new(0.3, 0.3, 0.8) * e, CFrame.new(base + Vector3.new(0, 0, 0.35 * e)))
	end
end

local function costas(ctx: Ctx, tipo: string)
	local e = ctx.e
	local s = ctx.corpo.Size / 2
	if tipo == "casco" then
		local meio = Vector3.new(s.X * 0.95, s.Y * 0.8, s.Z * 0.9)
		local centro = Vector3.new(0, 0.2 * e, 0.38 * e)
		bola(ctx, "Casco", ctx.segunda, meio * 2, CFrame.new(centro))
		-- placas mais claras no casco
		for i = 0, 5 do
			local a = i / 6 * math.pi * 2
			local d = (if i == 0
				then Vector3.new(0, 1, 0.15)
				else Vector3.new(math.cos(a) * 0.7, 0.6, 0.25 + math.sin(a) * 0.6)).Unit
			local t = 1 / math.sqrt((d.X / meio.X) ^ 2 + (d.Y / meio.Y) ^ 2 + (d.Z / meio.Z) ^ 2)
			local p = centro + d * t
			local n = Vector3.new(d.X * t / meio.X ^ 2, d.Y * t / meio.Y ^ 2, d.Z * t / meio.Z ^ 2).Unit
			bola(
				ctx,
				"Casco",
				ctx.segunda:Lerp(Color3.new(1, 1, 1), 0.35),
				Vector3.new(0.8, 0.8, 0.15) * e,
				CFrame.lookAt(p, p + n)
			)
		end
	elseif tipo == "barbatana" then
		local p = pele(ctx, Vector3.new(0, 1, 0.35))
		cunha(
			ctx,
			"Barbatana",
			ctx.cor,
			Vector3.new(0.25, 1.2, 1.1) * e,
			CFrame.new(p + Vector3.new(0, 0.45 * e, 0.1 * e))
		)
	elseif tipo == "espinhos" then
		for i = 0, 3 do
			local p, n = pele(ctx, Vector3.new(0, 1 - i * 0.28, 0.15 + i * 0.45))
			cunha(
				ctx,
				"Espinho",
				ctx.segunda,
				Vector3.new(0.18, 0.6 - i * 0.08, 0.6 - i * 0.08) * e,
				CFrame.lookAt(p, p + Vector3.new(0, 0, 1), n) * CFrame.new(0, (0.25 - i * 0.03) * e, 0)
			)
		end
	elseif tipo == "juba" then
		for i = 0, 11 do
			local a = i / 12 * math.pi * 2
			bola(
				ctx,
				"Juba",
				ctx.segunda,
				Vector3.new(0.95, 0.95, 0.55) * e,
				CFrame.new(math.cos(a) * s.X * 0.9, 0.15 * e + math.sin(a) * s.Y * 0.88, 0.05 * e)
			)
		end
	elseif tipo == "crina" then
		for i = 0, 4 do
			local p = pele(ctx, Vector3.new(0, 1 - i * 0.18, -0.2 + i * 0.35), 0.05)
			bola(
				ctx,
				"Crina",
				ctx.segunda,
				Vector3.new(0.3, 0.7, 0.55) * e,
				CFrame.new(p) * CFrame.Angles(math.rad(25 + i * 10), 0, 0)
			)
		end
	elseif tipo == "capa" then
		local capa = Instance.new("Part")
		capa.Name = "Capa"
		capa.Size = Vector3.new(s.X * 1.7, s.Y * 1.5, 0.15 * e)
		capa.Color = c(200, 30, 60)
		capa.Material = Enum.Material.Fabric
		capa.CanCollide = false
		capa.CanTouch = false
		capa.Massless = true
		capa.CastShadow = false
		capa.CFrame = ctx.corpo.CFrame * CFrame.new(0, 0.05 * e, s.Z + 0.1 * e) * CFrame.Angles(math.rad(-12), 0, 0)
		capa.Parent = ctx.modelo
		soldar(ctx.corpo, capa)
		local barra = capa:Clone()
		barra.Name = "Capa"
		barra.Size = Vector3.new(capa.Size.X + 0.05 * e, 0.25 * e, 0.2 * e)
		barra.Color = c(255, 205, 60)
		barra.Material = Enum.Material.Foil
		barra.CFrame = capa.CFrame * CFrame.new(0, -capa.Size.Y / 2, 0)
		barra.Parent = ctx.modelo
		soldar(ctx.corpo, barra)
	elseif tipo == "nuvem" then
		for i = 0, 6 do
			local a = i / 7 * math.pi * 2
			bola(
				ctx,
				"Nuvem",
				Color3.new(1, 1, 1),
				Vector3.one * (1.1 + (i % 2) * 0.3) * e,
				CFrame.new(math.cos(a) * s.X * 0.95, -s.Y * 0.45, math.sin(a) * s.Z * 0.95)
			)
		end
	elseif tipo == "cubos" then
		for i = 0, 3 do
			local a = i / 4 * math.pi * 2 + 0.4
			local cubo = Instance.new("Part")
			cubo.Name = "Cubo"
			cubo.Size = Vector3.one * 0.45 * e
			cubo.Color = Color3.fromHSV(i / 4, 0.6, 1)
			cubo.Material = Enum.Material.Neon
			cubo.CanCollide = false
			cubo.CanTouch = false
			cubo.Massless = true
			cubo.CastShadow = false
			cubo.CFrame = ctx.corpo.CFrame
				* CFrame.new(math.cos(a) * (s.X + 0.9 * e), 0.3 * e + (i % 2) * 0.6 * e, math.sin(a) * (s.Z + 0.9 * e))
				* CFrame.Angles(a, a * 2, 0.6)
			cubo.Parent = ctx.modelo
			soldar(ctx.corpo, cubo)
		end
	elseif tipo == "patas" then
		for i = 0, 7 do
			local a = (i + 0.5) / 8 * math.pi * 2
			for k = 0, 1 do
				bola(
					ctx,
					"Pata",
					if k == 1 then ctx.segunda else ctx.cor,
					Vector3.one * (0.5 - k * 0.1) * e,
					CFrame.new(
						math.cos(a) * (s.X + (0.05 + k * 0.4) * e),
						-s.Y * 0.75 - k * 0.15 * e,
						math.sin(a) * (s.Z + (0.05 + k * 0.4) * e)
					)
				)
			end
		end
	elseif tipo == "jato" then
		local p = pele(ctx, Vector3.new(0, 1, 0.2))
		local bico =
			bola(ctx, "Jato", c(140, 210, 255), Vector3.new(0.35, 0.2, 0.35) * e, CFrame.new(p), Enum.Material.Glass)
		local agua = Instance.new("ParticleEmitter")
		agua.Texture = "rbxasset://textures/particles/smoke_main.dds"
		agua.Color = ColorSequence.new(c(170, 225, 255), Color3.new(1, 1, 1))
		agua.Size = NumberSequence.new(0.5 * e, 0.9 * e)
		agua.Transparency = NumberSequence.new(0.2, 1)
		agua.Lifetime = NumberRange.new(0.6, 0.9)
		agua.Speed = NumberRange.new(5 * e, 7 * e)
		agua.SpreadAngle = Vector2.new(12, 12)
		agua.Acceleration = Vector3.new(0, -14, 0)
		agua.Rate = 12
		agua.EmissionDirection = Enum.NormalId.Top
		agua.Parent = bico
	elseif tipo == "nadadeiras" then
		for _, lado in { -1, 1 } do
			bola(
				ctx,
				"Nadadeira",
				ctx.segunda,
				Vector3.new(0.3, 1.4, 0.8) * e,
				CFrame.new(s.X * lado, -0.15 * e, 0) * CFrame.Angles(0, 0, math.rad(30 * lado))
			)
		end
	elseif tipo == "crista" then
		for i = 0, 2 do
			local p = pele(ctx, Vector3.new(0, 1, -0.15 + i * 0.25))
			bola(
				ctx,
				"Crista",
				ctx.segunda,
				Vector3.new(0.2, 0.75 - i * 0.12, 0.4) * e,
				CFrame.new(p) * CFrame.Angles(math.rad(-15 + i * 25), 0, 0) * CFrame.new(0, 0.3 * e, 0)
			)
		end
	elseif tipo == "fogo" then
		local chama = Instance.new("ParticleEmitter")
		chama.Texture = "rbxasset://textures/particles/fire_main.dds"
		chama.Color = ColorSequence.new(c(255, 220, 90), c(255, 70, 30))
		chama.Size = NumberSequence.new(1.2 * e, 0.2 * e)
		chama.Transparency = NumberSequence.new(0.3, 1)
		chama.Lifetime = NumberRange.new(0.4, 0.7)
		chama.Speed = NumberRange.new(2, 3)
		chama.LightEmission = 1
		chama.Rate = 14
		chama.Parent = ctx.corpo
	elseif tipo == "caroco" then
		local frente = -s.Z
		bola(ctx, "Caroco", c(150, 95, 50), Vector3.new(1.1, 1.1, 0.5) * e, CFrame.new(0, -0.65 * e, frente + 0.12 * e))
	elseif tipo == "tapaolho" then
		local frente = -s.Z
		bola(
			ctx,
			"TapaOlho",
			c(25, 20, 25),
			Vector3.new(1, 1.2, 0.3) * e,
			CFrame.new(0.64 * e, 0.36 * e, frente - 0.1 * e)
		)
		local tira = Instance.new("Part")
		tira.Name = "TapaOlho"
		tira.Size = Vector3.new(s.X * 2.05, 0.14 * e, s.Z * 2.05)
		tira.Color = c(25, 20, 25)
		tira.CanCollide = false
		tira.CanTouch = false
		tira.Massless = true
		tira.CastShadow = false
		oval(tira)
		tira.CFrame = ctx.corpo.CFrame * CFrame.new(0, 0.55 * e, 0) * CFrame.Angles(0, 0, math.rad(-12))
		tira.Parent = ctx.modelo
		soldar(ctx.corpo, tira)
	elseif tipo == "bigode" then
		local frente = -s.Z
		for _, lado in { -1, 1 } do
			for k = -1, 1, 2 do
				local b = Instance.new("Part")
				b.Name = "Bigode"
				b.Size = Vector3.new(0.9, 0.06, 0.06) * e
				b.Color = c(60, 40, 40)
				b.CanCollide = false
				b.CanTouch = false
				b.Massless = true
				b.CastShadow = false
				b.CFrame = ctx.corpo.CFrame
					* CFrame.new(0.65 * lado * e, -0.15 * e + k * 0.07 * e, frente + 0.12 * e)
					* CFrame.Angles(0, 0, math.rad(k * 10 * lado))
				b.Parent = ctx.modelo
				soldar(ctx.corpo, b)
			end
		end
	elseif tipo == "topete" then
		for i = -1, 1 do
			local p = pele(ctx, Vector3.new(i * 0.15, 1, -0.2))
			bola(
				ctx,
				"Topete",
				ctx.cor,
				Vector3.new(0.25, 0.7, 0.25) * e,
				CFrame.new(p) * CFrame.Angles(math.rad(-20), 0, math.rad(-i * 25)) * CFrame.new(0, 0.3 * e, 0)
			)
		end
	elseif tipo == "asinseto" then
		for _, lado in { -1, 1 } do
			local p = pele(ctx, Vector3.new(0.5 * lado, 0.7, 0.7))
			local asa = bola(
				ctx,
				"AsaInseto",
				c(220, 245, 255),
				Vector3.new(0.12, 1.5, 1) * e,
				CFrame.new(p) * CFrame.Angles(0, math.rad(-30 * lado), math.rad(-35 * lado)) * CFrame.new(0, 0.6 * e, 0),
				Enum.Material.Glass
			)
			asa.Transparency = 0.35
		end
	elseif tipo == "bolsa" then
		local frente = -s.Z
		bola(
			ctx,
			"Bolsa",
			ctx.clara:Lerp(ctx.cor, 0.3),
			Vector3.new(1.5, 0.9, 0.5) * e,
			CFrame.new(0, -0.8 * e, frente + 0.25 * e)
		)
	elseif tipo == "olhosapo" then
		-- olhos em cima da cabeça (o rosto do sapo fica bem largo)
		for _, lado in { -1, 1 } do
			local p = pele(ctx, Vector3.new(0.45 * lado, 0.9, -0.3))
			bola(ctx, "Pele", ctx.cor, Vector3.one * 0.85 * e, CFrame.new(p + Vector3.new(0, 0.1 * e, 0)))
		end
	elseif tipo == "manchaorca" then
		for _, lado in { -1, 1 } do
			mancha(
				ctx,
				"Mancha",
				Color3.new(1, 1, 1),
				Vector3.new(0.7, 0.45, 0.15),
				Vector3.new(0.55 * lado, 0.55, -0.6)
			)
		end
	end
end

local function padrao(ctx: Ctx, tipo: string, cor: Color3?)
	if tipo == "listras" then
		local corL = cor or ctx.cor:Lerp(Color3.new(0, 0, 0), 0.55)
		for i = 0, 3 do
			local z = -0.1 + i * 0.4
			for _, lado in { -1, 1 } do
				mancha(ctx, "Listra", corL, Vector3.new(0.3, 1.2, 0.12), Vector3.new(0.9 * lado, 0.35, z))
			end
			mancha(ctx, "Listra", corL, Vector3.new(1.3, 0.3, 0.12), Vector3.new(0, 1, z + 0.3))
		end
	elseif tipo == "pintas" or tipo == "estrelas" then
		local corP = cor
			or (if tipo == "estrelas" then Color3.fromRGB(255, 250, 200) else ctx.cor:Lerp(ctx.segunda, 0.6))
		for k = 1, 7 do
			local a = k * 2.4
			local dir = Vector3.new(math.cos(a), 0.35 + (k % 3) * 0.25, math.sin(a) * 0.9 + 0.35)
			local t = if tipo == "estrelas" then 0.28 else 0.5 + (k % 2) * 0.2
			mancha(
				ctx,
				"Pinta",
				corP,
				Vector3.new(t, t, 0.12),
				dir,
				if tipo == "estrelas" then Enum.Material.Neon else nil
			)
		end
	elseif tipo == "teclas" then
		-- teclas de piano na barriga
		for i = -2, 2 do
			mancha(
				ctx,
				"Tecla",
				if i % 2 == 0 then Color3.new(1, 1, 1) else c(25, 25, 30),
				Vector3.new(0.38, 0.9, 0.14),
				Vector3.new(i * 0.2, -0.25, -1)
			)
		end
	end
end

-- Aplica a ficha no modelo.
function Tracos.aplicar(ctx: Ctx, ficha: Ficha)
	if ficha.padrao then
		padrao(ctx, ficha.padrao, ficha.corPadrao)
	end
	if ficha.orelhas then
		orelhas(ctx, ficha.orelhas)
	end
	if ficha.focinho then
		focinho(ctx, ficha.focinho)
	end
	if ficha.chifre then
		chifre(ctx, ficha.chifre)
	end
	cauda(ctx, ficha.cauda or "curta")
	for _, t in ficha.costas or {} do
		costas(ctx, t)
	end
end

return Tracos
