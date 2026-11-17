-- ItemArte: desenha cada equipamento como um modelo 3D (para os ícones da mochila e da forja).
-- A forma muda com o tier (raridade) e as cores seguem a cor da raridade.
-- T1-T2 simples, T3 caprichado, T4+ com detalhes em neon brilhando.

local ItemArte = {}

local METAL = Color3.fromRGB(196, 202, 214)
local METAL_ESCURO = Color3.fromRGB(70, 74, 86)
local COURO = Color3.fromRGB(96, 62, 40)
local PANO = Color3.fromRGB(44, 52, 92)
local PRETO = Color3.fromRGB(22, 20, 26)
local OURO = Color3.fromRGB(240, 196, 90)

local function peca(m, tamanho, cf, cor, material, forma)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Size = tamanho
	p.CFrame = cf
	p.Color = cor
	p.Material = material or Enum.Material.SmoothPlastic
	if forma then
		p.Shape = forma
	end
	p.Parent = m
	return p
end

local function cunha(m, tamanho, cf, cor, material)
	local w = Instance.new("WedgePart")
	w.Anchored = true
	w.CanCollide = false
	w.CastShadow = false
	w.Size = tamanho
	w.CFrame = cf
	w.Color = cor
	w.Material = material or Enum.Material.SmoothPlastic
	w.Parent = m
	return w
end

local function brilho(ri)
	return ri >= 4 and Enum.Material.Neon or Enum.Material.Metal
end

------------------------------------------------------------------------
-- Arma: kunai (T1-T2) e katana (T3+)
------------------------------------------------------------------------
local function arma(m, ri, cor)
	local base = CFrame.Angles(0, 0, math.rad(-45)) -- deitada na diagonal, como em ícone de jogo
	if ri <= 2 then
		local lamina = ri == 1 and Color3.fromRGB(150, 140, 130) or METAL
		peca(m, Vector3.new(0.35, 1.6, 0.35), base * CFrame.new(0, -1.1, 0), COURO, Enum.Material.Fabric)
		peca(
			m,
			Vector3.new(0.7, 0.12, 0.7),
			base * CFrame.new(0, -2.0, 0),
			METAL_ESCURO,
			Enum.Material.Metal,
			Enum.PartType.Cylinder
		).CFrame = base
			* CFrame.new(0, -2.05, 0)
			* CFrame.Angles(0, 0, math.rad(90))
		cunha(m, Vector3.new(0.12, 1.4, 0.5), base * CFrame.new(0, 0.4, 0.25), lamina, Enum.Material.Metal)
		cunha(
			m,
			Vector3.new(0.12, 1.4, 0.5),
			base * CFrame.new(0, 0.4, -0.25) * CFrame.Angles(0, math.pi, 0),
			lamina,
			Enum.Material.Metal
		)
		peca(m, Vector3.new(0.5, 0.15, 0.9), base * CFrame.new(0, -0.3, 0), cor, Enum.Material.Metal)
		return
	end
	-- katana: cabo trançado, guarda redonda e lâmina longa levemente curva
	local corLamina = ri >= 4 and cor:Lerp(Color3.new(1, 1, 1), 0.35) or METAL
	peca(m, Vector3.new(0.38, 1.3, 0.38), base * CFrame.new(0, -1.75, 0), PRETO, Enum.Material.Fabric)
	for i = 0, 3 do
		peca(
			m,
			Vector3.new(0.42, 0.08, 0.42),
			base * CFrame.new(0, -1.25 - i * 0.3, 0) * CFrame.Angles(0, 0, 0.3),
			cor,
			Enum.Material.Fabric
		)
	end
	peca(
		m,
		Vector3.new(0.12, 1.1, 1.1),
		base * CFrame.new(0, -1.05, 0) * CFrame.Angles(0, 0, math.rad(90)),
		OURO,
		Enum.Material.Metal,
		Enum.PartType.Cylinder
	)
	for i = 0, 3 do
		local curva = CFrame.Angles(0, 0, math.rad(-3 * i))
		peca(
			m,
			Vector3.new(0.12, 0.85, 0.32),
			base * CFrame.new(0.02 * i * i, -0.55 + i * 0.82, 0) * curva,
			corLamina,
			brilho(ri)
		)
	end
	cunha(
		m,
		Vector3.new(0.12, 0.6, 0.32),
		base * CFrame.new(0.2, 2.95, 0) * CFrame.Angles(0, math.pi / 2, math.rad(-10)),
		corLamina,
		brilho(ri)
	)
	if ri >= 5 then
		-- runas brilhando na lâmina
		for i = 0, 2 do
			peca(
				m,
				Vector3.new(0.14, 0.18, 0.12),
				base * CFrame.new(0.02 * i, 0 + i * 0.8, 0),
				Color3.new(1, 1, 1),
				Enum.Material.Neon
			)
		end
	end
	if ri >= 6 then
		for _, lado in ipairs({ -1, 1 }) do
			cunha(
				m,
				Vector3.new(0.1, 0.9, 0.5),
				base * CFrame.new(0, -0.9, 0.55 * lado) * CFrame.Angles(lado > 0 and 0 or math.pi, 0, 0),
				cor,
				Enum.Material.Neon
			)
		end
	end
end

------------------------------------------------------------------------
-- Elmo: bandana (T1-T2), máscara ANBU (T3), elmo com chifres (T4+)
------------------------------------------------------------------------
local function elmo(m, ri, cor)
	if ri <= 2 then
		peca(
			m,
			Vector3.new(2.6, 0.7, 1.4),
			CFrame.new(0, 0, 0),
			ri == 1 and Color3.fromRGB(150, 120, 90) or PANO,
			Enum.Material.Fabric
		)
		peca(m, Vector3.new(1.3, 0.6, 0.12), CFrame.new(0, 0, -0.72), METAL, Enum.Material.Metal)
		peca(m, Vector3.new(0.5, 0.1, 0.04), CFrame.new(0, 0, -0.79), cor, Enum.Material.Metal)
		for _, lado in ipairs({ -1, 1 }) do
			peca(
				m,
				Vector3.new(0.3, 1.5, 0.1),
				CFrame.new(0.4 * lado, -0.6, 0.8) * CFrame.Angles(0.3, 0, 0.25 * lado),
				ri == 1 and Color3.fromRGB(150, 120, 90) or PANO,
				Enum.Material.Fabric
			)
		end
		return
	end
	if ri == 3 then
		local mascara = peca(
			m,
			Vector3.new(2, 2.5, 1.2),
			CFrame.new(0, 0, 0),
			Color3.fromRGB(245, 244, 240),
			Enum.Material.SmoothPlastic,
			Enum.PartType.Ball
		)
		mascara.Name = "Mascara"
		for _, lado in ipairs({ -1, 1 }) do
			peca(
				m,
				Vector3.new(0.45, 0.22, 0.1),
				CFrame.new(0.42 * lado, 0.25, -0.58) * CFrame.Angles(0, 0, 0.25 * lado),
				PRETO
			)
			peca(
				m,
				Vector3.new(0.1, 0.9, 0.1),
				CFrame.new(0.65 * lado, -0.3, -0.5) * CFrame.Angles(0, 0, -0.2 * lado),
				cor,
				Enum.Material.Neon
			)
		end
		peca(m, Vector3.new(0.1, 0.7, 0.1), CFrame.new(0, 0.85, -0.45), Color3.fromRGB(220, 50, 60), Enum.Material.Neon)
		return
	end
	-- elmo com chifres e gema
	peca(
		m,
		Vector3.new(2.4, 2.4, 2.4),
		CFrame.new(0, 0, 0),
		cor:Lerp(PRETO, 0.35),
		Enum.Material.Metal,
		Enum.PartType.Ball
	)
	peca(m, Vector3.new(2.5, 0.35, 2.5), CFrame.new(0, -0.35, 0), OURO, Enum.Material.Metal)
	peca(m, Vector3.new(1.9, 0.5, 0.15), CFrame.new(0, -0.05, -1.15), PRETO)
	for _, lado in ipairs({ -1, 1 }) do
		cunha(
			m,
			Vector3.new(0.35, 1.6, 0.6),
			CFrame.new(1.05 * lado, 1.15, 0) * CFrame.Angles(0, lado > 0 and 0 or math.pi, math.rad(-25 * lado)),
			cor,
			Enum.Material.Neon
		)
	end
	peca(
		m,
		Vector3.new(0.5, 0.5, 0.5),
		CFrame.new(0, 0.55, -1.15),
		cor:Lerp(Color3.new(1, 1, 1), 0.3),
		Enum.Material.Neon,
		Enum.PartType.Ball
	)
end

------------------------------------------------------------------------
-- Armadura: colete (T1-T3) e manto com ombreiras (T4+)
------------------------------------------------------------------------
local function armadura(m, ri, cor)
	if ri <= 3 then
		local corColete = ri == 1 and Color3.fromRGB(120, 105, 80)
			or (ri == 2 and Color3.fromRGB(80, 110, 70) or Color3.fromRGB(70, 70, 82))
		peca(m, Vector3.new(2.4, 2.6, 1.2), CFrame.new(0, 0, 0), corColete, Enum.Material.Fabric)
		peca(m, Vector3.new(2.5, 0.45, 1.3), CFrame.new(0, 1.2, 0), corColete:Lerp(PRETO, 0.3), Enum.Material.Fabric)
		for _, lado in ipairs({ -1, 1 }) do
			peca(
				m,
				Vector3.new(0.7, 0.55, 0.2),
				CFrame.new(0.6 * lado, -0.2, -0.65),
				corColete:Lerp(Color3.new(1, 1, 1), 0.15),
				Enum.Material.Fabric
			)
			peca(
				m,
				Vector3.new(0.8, 0.6, 1.25),
				CFrame.new(1.45 * lado, 1, 0),
				corColete:Lerp(PRETO, 0.2),
				Enum.Material.Fabric
			)
		end
		peca(m, Vector3.new(2.45, 0.25, 1.25), CFrame.new(0, -0.9, 0), cor, Enum.Material.Metal)
		if ri == 3 then
			peca(m, Vector3.new(1.6, 1.6, 0.12), CFrame.new(0, 0.3, -0.62), METAL, Enum.Material.Metal)
		end
		return
	end
	-- manto com ombreiras e acabamento brilhante
	local escuro = cor:Lerp(PRETO, 0.75)
	peca(m, Vector3.new(2.5, 2.9, 1.3), CFrame.new(0, -0.1, 0), escuro, Enum.Material.Fabric)
	peca(m, Vector3.new(2.6, 0.18, 1.4), CFrame.new(0, -1.5, 0), cor, Enum.Material.Neon)
	peca(m, Vector3.new(0.15, 2.8, 0.05), CFrame.new(0.35, -0.1, -0.68), cor, Enum.Material.Neon)
	for _, lado in ipairs({ -1, 1 }) do
		peca(
			m,
			Vector3.new(1.3, 1.3, 1.3),
			CFrame.new(1.4 * lado, 1.05, 0),
			cor:Lerp(PRETO, 0.4),
			Enum.Material.Metal,
			Enum.PartType.Ball
		)
		cunha(
			m,
			Vector3.new(0.25, 0.8, 0.5),
			CFrame.new(1.6 * lado, 1.8, 0) * CFrame.Angles(0, lado > 0 and 0 or math.pi, math.rad(-20 * lado)),
			OURO,
			Enum.Material.Metal
		)
	end
	peca(m, Vector3.new(0.55, 0.55, 0.2), CFrame.new(-0.45, 0.5, -0.66), OURO, Enum.Material.Neon, Enum.PartType.Ball)
end

------------------------------------------------------------------------
-- Botas: sandália (T1-T2), bota (T3), bota alada (T4+)
------------------------------------------------------------------------
local function botas(m, ri, cor)
	for _, lado in ipairs({ -1, 1 }) do
		local x = 0.75 * lado
		local corCano = ri <= 2 and COURO or cor:Lerp(PRETO, 0.4)
		local altura = ri <= 2 and 0.9 or 1.8
		peca(
			m,
			Vector3.new(0.85, altura, 0.85),
			CFrame.new(x, -0.6 + altura / 2, 0.15),
			corCano,
			ri <= 2 and Enum.Material.Fabric or Enum.Material.Metal
		)
		peca(
			m,
			Vector3.new(0.95, 0.45, 1.6),
			CFrame.new(x, -0.75, -0.25),
			ri <= 2 and Color3.fromRGB(70, 50, 36) or PRETO
		)
		peca(m, Vector3.new(0.9, 0.12, 0.9), CFrame.new(x, -0.4, 0.15), cor, Enum.Material.Metal)
		if ri >= 4 then
			cunha(
				m,
				Vector3.new(0.15, 0.9, 1.2),
				CFrame.new(x + 0.5 * lado, 0.7, 0.4)
					* CFrame.Angles(math.rad(-30), lado > 0 and math.pi / 2 or -math.pi / 2, 0),
				cor,
				Enum.Material.Neon
			)
		end
	end
end

------------------------------------------------------------------------
-- Olho (Rinnegan): anéis concêntricos
------------------------------------------------------------------------
local function olho(m, _, cor)
	local frente = CFrame.Angles(0, math.rad(90), 0)
	peca(
		m,
		Vector3.new(0.3, 2.8, 2.8),
		frente,
		Color3.fromRGB(235, 225, 245),
		Enum.Material.SmoothPlastic,
		Enum.PartType.Cylinder
	)
	local anel = cor:Lerp(Color3.fromRGB(150, 110, 220), 0.5)
	for i, r in ipairs({ 2.5, 1.9, 1.3 }) do
		peca(
			m,
			Vector3.new(0.32 + i * 0.01, r, r),
			frente * CFrame.new(-0.01 * i, 0, 0),
			anel,
			Enum.Material.Neon,
			Enum.PartType.Cylinder
		)
		peca(
			m,
			Vector3.new(0.33 + i * 0.01, r - 0.18, r - 0.18),
			frente * CFrame.new(-0.012 * i, 0, 0),
			Color3.fromRGB(200, 185, 235),
			Enum.Material.SmoothPlastic,
			Enum.PartType.Cylinder
		)
	end
	peca(m, Vector3.new(0.4, 0.6, 0.6), frente, PRETO, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
end

------------------------------------------------------------------------
-- Desenhos por classe: Caçador (arco, capuz, couro) e Mago (cajado, chapéu, túnica).
-- O Guerreiro usa os desenhos de cima (katana, elmo, colete).
------------------------------------------------------------------------
-- peça comprida ligando dois pontos (no plano XY), usada no arco
local function ligar(m, cf, a, b, grossura, cor, material)
	local d = b - a
	local ang = math.atan2(d.X, d.Y)
	return peca(
		m,
		Vector3.new(grossura, d.Magnitude + grossura * 0.5, grossura * 1.3),
		cf * CFrame.new((a + b) / 2) * CFrame.Angles(0, 0, -ang),
		cor,
		material
	)
end

local function arco(m, ri, cor)
	local base = CFrame.Angles(0, 0, math.rad(-45))
	local madeira = ri == 1 and Color3.fromRGB(150, 118, 72)
		or (ri == 2 and Color3.fromRGB(122, 168, 80) or cor:Lerp(PRETO, ri >= 4 and 0.55 or 0.3))
	local mat = ri >= 3 and Enum.Material.Metal or Enum.Material.Wood
	-- braços do arco em ")" : o cabo fica no meio e as pontas curvam para a corda
	local N = 6
	local pontas = {}
	for _, lado in ipairs({ -1, 1 }) do
		local ant = Vector3.new(0, 0, 0)
		for i = 1, N do
			local t = i / N
			local p = Vector3.new(0.95 * t ^ 1.7, lado * (0.35 + 2.6 * t), 0)
			if ri >= 3 and i == N then
				p += Vector3.new(-0.25, 0, 0) -- pontas recurvas
			end
			ligar(m, base, ant, p, 0.36 - t * 0.12, madeira, mat)
			if ri >= 5 and i % 2 == 0 then
				peca(m, Vector3.new(0.16, 0.16, 0.36), base * CFrame.new(p), Color3.new(1, 1, 1), Enum.Material.Neon)
			end
			ant = p
		end
		pontas[lado] = ant
		if ri >= 3 then
			cunha(
				m,
				Vector3.new(0.14, 0.5, 0.3),
				base * CFrame.new(ant + Vector3.new(0, lado * 0.22, 0)) * CFrame.Angles(lado > 0 and 0 or math.pi, 0, 0),
				OURO,
				Enum.Material.Metal
			)
		end
		if ri >= 6 then
			-- lâminas de energia nas costas dos braços
			cunha(
				m,
				Vector3.new(0.08, 1.1, 0.6),
				base * CFrame.new(-0.25, lado * 1.4, 0) * CFrame.Angles(lado > 0 and 0 or math.pi, math.pi / 2, 0),
				cor,
				Enum.Material.Neon
			)
		end
	end
	-- corda
	local corda = ri >= 4 and cor:Lerp(Color3.new(1, 1, 1), 0.3) or Color3.fromRGB(235, 230, 215)
	ligar(m, base, pontas[-1], pontas[1], 0.07, corda, ri >= 4 and Enum.Material.Neon or Enum.Material.Fabric)
	-- cabo
	peca(m, Vector3.new(0.36, 0.9, 0.42), base, COURO, Enum.Material.Fabric)
	peca(m, Vector3.new(0.4, 0.1, 0.46), base * CFrame.new(0, 0.42, 0), cor, Enum.Material.Metal)
	peca(m, Vector3.new(0.4, 0.1, 0.46), base * CFrame.new(0, -0.42, 0), cor, Enum.Material.Metal)
	-- flecha encaixada
	if ri >= 2 then
		local ponta = pontas[1].X
		peca(m, Vector3.new(2.3, 0.07, 0.07), base * CFrame.new(ponta - 1.1, 0, 0), Color3.fromRGB(150, 110, 70))
		cunha(
			m,
			Vector3.new(0.08, 0.45, 0.28),
			base * CFrame.new(ponta - 2.42, 0, 0) * CFrame.Angles(0, 0, math.rad(90)),
			ri >= 4 and cor or METAL,
			brilho(ri)
		)
		for _, lado in ipairs({ -1, 1 }) do
			cunha(
				m,
				Vector3.new(0.04, 0.35, 0.18),
				base * CFrame.new(ponta - 0.15, lado * 0.1, 0) * CFrame.Angles(0, 0, math.rad(-90 * lado)),
				cor,
				ri >= 4 and Enum.Material.Neon or Enum.Material.Fabric
			)
		end
	end
end

local function cajado(m, ri, cor)
	local base = CFrame.Angles(0, 0, math.rad(-45))
	local haste = ri == 1 and Color3.fromRGB(122, 88, 58)
		or (
			ri == 2 and Color3.fromRGB(120, 170, 80)
			or (ri == 3 and Color3.fromRGB(70, 48, 40) or cor:Lerp(PRETO, 0.7))
		)
	peca(
		m,
		Vector3.new(0.3, 4.2, 0.3),
		base * CFrame.new(0, -0.3, 0),
		haste,
		ri >= 4 and Enum.Material.Metal or Enum.Material.Wood
	)
	-- anéis na haste (bambu no T2, ouro do T3 para cima)
	for i = 0, 2 do
		peca(
			m,
			Vector3.new(0.38, 0.12, 0.38),
			base * CFrame.new(0, -1.8 + i * 1.1, 0),
			ri >= 3 and OURO or haste:Lerp(PRETO, 0.28),
			ri >= 3 and Enum.Material.Metal or Enum.Material.Wood
		)
	end
	if ri == 1 then
		peca(
			m,
			Vector3.new(0.6, 0.6, 0.6),
			base * CFrame.new(0, 1.9, 0),
			haste:Lerp(PRETO, 0.2),
			Enum.Material.Wood,
			Enum.PartType.Ball
		)
		return
	end
	-- orbe mágico no topo
	local corOrbe = ri == 2 and Color3.fromRGB(140, 220, 255) or cor:Lerp(Color3.new(1, 1, 1), 0.25)
	local tam = ri >= 4 and 1.05 or 0.8
	peca(m, Vector3.new(tam, tam, tam), base * CFrame.new(0, 2.35, 0), corOrbe, Enum.Material.Neon, Enum.PartType.Ball)
	-- garras em lua segurando o orbe
	if ri >= 3 then
		for i = 0, 6 do
			local a = math.rad(-110 + i * 36.6)
			local r = tam * 0.62
			peca(
				m,
				Vector3.new(0.14, 0.32, 0.18),
				base * CFrame.new(math.sin(a) * r, 2.35 - math.cos(a) * r, 0) * CFrame.Angles(0, 0, -a),
				OURO,
				Enum.Material.Metal
			)
		end
	end
	if ri >= 5 then
		-- cristais flutuando em volta do orbe
		for i = 1, 3 do
			local a = (i / 3) * math.pi * 2
			cunha(
				m,
				Vector3.new(0.1, 0.45, 0.2),
				base * CFrame.new(math.cos(a) * 1.05, 2.35 + math.sin(a) * 0.5, math.sin(a) * 0.4),
				cor,
				Enum.Material.Neon
			)
		end
	end
	if ri >= 6 then
		for _, lado in ipairs({ -1, 1 }) do
			cunha(
				m,
				Vector3.new(0.08, 1.2, 0.7),
				base
					* CFrame.new(0.5 * lado, 1.4, 0)
					* CFrame.Angles(0, lado > 0 and math.pi / 2 or -math.pi / 2, math.rad(15)),
				cor,
				Enum.Material.Neon
			)
		end
	end
end

local function chapeuMago(m, ri, cor)
	local pano = ri == 1 and Color3.fromRGB(120, 90, 60)
		or (ri == 2 and PANO or (ri == 3 and Color3.fromRGB(70, 46, 110) or cor:Lerp(PRETO, 0.5)))
	-- aba larga
	peca(
		m,
		Vector3.new(0.16, 3.2, 3.2),
		CFrame.Angles(0, 0, math.rad(90)),
		pano,
		Enum.Material.Fabric,
		Enum.PartType.Cylinder
	)
	-- cone que entorta na ponta
	for i = 0, 7 do
		local r = 1.75 - i * 0.2
		peca(
			m,
			Vector3.new(0.34, r, r),
			CFrame.new(0.018 * i * i, 0.22 + i * 0.3, 0.01 * i * i) * CFrame.Angles(0, 0, math.rad(90 - i * 3)),
			pano:Lerp(PRETO, i / 22),
			Enum.Material.Fabric,
			Enum.PartType.Cylinder
		)
	end
	-- faixa
	peca(
		m,
		Vector3.new(0.28, 1.82, 1.82),
		CFrame.new(0, 0.32, 0) * CFrame.Angles(0, 0, math.rad(90)),
		ri >= 4 and cor or OURO,
		ri >= 4 and Enum.Material.Neon or Enum.Material.Metal,
		Enum.PartType.Cylinder
	)
	if ri >= 3 then
		-- gema na frente da faixa
		peca(
			m,
			Vector3.new(0.42, 0.42, 0.42),
			CFrame.new(0, 0.34, -0.9),
			ri >= 4 and Color3.new(1, 1, 1) or cor,
			Enum.Material.Neon,
			Enum.PartType.Ball
		)
	end
	if ri >= 5 then
		peca(m, Vector3.new(0.35, 0.35, 0.35), CFrame.new(1.2, 2.35, 0.6), cor, Enum.Material.Neon, Enum.PartType.Ball)
	end
end

local function capuz(m, ri, cor)
	local pano = ri == 1 and Color3.fromRGB(128, 100, 70)
		or (ri == 2 and Color3.fromRGB(70, 110, 60) or (ri == 3 and Color3.fromRGB(56, 70, 60) or cor:Lerp(PRETO, 0.6)))
	-- capuz puxado para trás (o rosto aparece na frente)
	peca(m, Vector3.new(2.5, 2.55, 2.5), CFrame.new(0, 0.12, 0.35), pano, Enum.Material.Fabric, Enum.PartType.Ball)
	cunha(
		m,
		Vector3.new(0.6, 0.9, 1.1),
		CFrame.new(0, 0.95, 1.25) * CFrame.Angles(math.rad(-30), 0, 0),
		pano,
		Enum.Material.Fabric
	)
	-- borda do capuz em volta do rosto
	peca(
		m,
		Vector3.new(0.16, 2.3, 2.3),
		CFrame.new(0, 0.1, -0.55) * CFrame.Angles(0, math.rad(90), 0),
		ri >= 4 and cor or pano:Lerp(Color3.new(1, 1, 1), 0.15),
		ri >= 4 and Enum.Material.Neon or Enum.Material.Fabric,
		Enum.PartType.Cylinder
	)
	-- sombra do rosto (só no ícone; ao vestir, o rosto do herói aparece)
	local sombra = peca(
		m,
		Vector3.new(1.75, 1.95, 0.6),
		CFrame.new(0, 0.05, -0.55),
		Color3.fromRGB(16, 14, 20),
		Enum.Material.SmoothPlastic,
		Enum.PartType.Ball
	)
	sombra.Name = "SombraRosto"
	for _, lado in ipairs({ -1, 1 }) do
		local olhoBrilho = peca(
			m,
			Vector3.new(0.32, 0.14, 0.1),
			CFrame.new(0.32 * lado, 0.12, -0.86) * CFrame.Angles(0, 0, math.rad(-12 * lado)),
			ri >= 4 and cor:Lerp(Color3.new(1, 1, 1), 0.4) or Color3.fromRGB(255, 240, 200),
			Enum.Material.Neon
		)
		olhoBrilho.Name = "SombraRosto"
	end
	if ri >= 3 then
		-- lenço cobrindo a boca (estilo ninja caçador)
		peca(m, Vector3.new(1.7, 0.55, 0.3), CFrame.new(0, -0.62, -0.95), pano:Lerp(PRETO, 0.35), Enum.Material.Fabric)
		peca(
			m,
			Vector3.new(1.72, 0.1, 0.32),
			CFrame.new(0, -0.38, -0.96),
			cor,
			ri >= 4 and Enum.Material.Neon or Enum.Material.Metal
		)
	end
	if ri >= 5 then
		-- pena brilhante
		cunha(
			m,
			Vector3.new(0.1, 1.2, 0.45),
			CFrame.new(1.05, 0.9, 0.6) * CFrame.Angles(0, math.pi / 2, math.rad(-25)),
			cor,
			Enum.Material.Neon
		)
	end
end

local function couro(m, ri, cor)
	local corCouro = ri == 1 and Color3.fromRGB(130, 96, 62)
		or (
			ri == 2 and Color3.fromRGB(84, 120, 66)
			or (ri == 3 and Color3.fromRGB(70, 82, 64) or cor:Lerp(PRETO, 0.65))
		)
	peca(m, Vector3.new(2.4, 2.6, 1.2), CFrame.new(0, 0, 0), corCouro, Enum.Material.Fabric)
	peca(m, Vector3.new(2.5, 0.45, 1.3), CFrame.new(0, 1.2, 0), corCouro:Lerp(PRETO, 0.3), Enum.Material.Fabric)
	-- alça diagonal com fivela
	peca(
		m,
		Vector3.new(0.38, 3.2, 0.12),
		CFrame.new(0, 0.1, -0.64) * CFrame.Angles(0, 0, math.rad(40)),
		COURO,
		Enum.Material.Fabric
	)
	peca(
		m,
		Vector3.new(0.4, 0.4, 0.14),
		CFrame.new(-0.25, -0.15, -0.68) * CFrame.Angles(0, 0, math.rad(40)),
		OURO,
		Enum.Material.Metal
	)
	-- cinto
	peca(
		m,
		Vector3.new(2.45, 0.25, 1.25),
		CFrame.new(0, -0.9, 0),
		ri >= 4 and cor or COURO:Lerp(PRETO, 0.3),
		ri >= 4 and Enum.Material.Neon or Enum.Material.Fabric
	)
	-- aljava nas costas com flechas
	local aljava = CFrame.new(0.55, 0.35, 0.95) * CFrame.Angles(0, 0, math.rad(-20))
	peca(
		m,
		Vector3.new(2.1, 0.7, 0.7),
		aljava * CFrame.Angles(0, 0, math.rad(90)),
		COURO,
		Enum.Material.Fabric,
		Enum.PartType.Cylinder
	)
	peca(
		m,
		Vector3.new(0.16, 0.76, 0.76),
		aljava * CFrame.new(0, 0.55, 0) * CFrame.Angles(0, 0, math.rad(90)),
		cor,
		Enum.Material.Metal,
		Enum.PartType.Cylinder
	)
	for i = -1, 1 do
		peca(m, Vector3.new(0.06, 0.9, 0.06), aljava * CFrame.new(i * 0.18, 1.4, 0), Color3.fromRGB(150, 110, 70))
		cunha(
			m,
			Vector3.new(0.04, 0.3, 0.2),
			aljava * CFrame.new(i * 0.18, 1.75, 0),
			ri >= 4 and cor or Color3.fromRGB(235, 230, 215),
			ri >= 4 and Enum.Material.Neon or Enum.Material.Fabric
		)
	end
	-- ombreira só de um lado (mais ágil)
	peca(m, Vector3.new(0.9, 0.6, 1.3), CFrame.new(-1.45, 1, 0), corCouro:Lerp(PRETO, 0.2), Enum.Material.Fabric)
	if ri >= 3 then
		peca(m, Vector3.new(0.95, 0.12, 1.35), CFrame.new(-1.45, 1.3, 0), cor, brilho(ri))
	end
end

local function tunica(m, ri, cor)
	local pano = ri == 1 and Color3.fromRGB(130, 104, 76)
		or (ri == 2 and PANO or (ri == 3 and Color3.fromRGB(74, 50, 112) or cor:Lerp(PRETO, 0.62)))
	peca(m, Vector3.new(2.4, 2.6, 1.2), CFrame.new(0, 0, 0), pano, Enum.Material.Fabric)
	-- saia da túnica
	peca(m, Vector3.new(2.55, 1.1, 1.35), CFrame.new(0, -1.6, 0), pano:Lerp(PRETO, 0.15), Enum.Material.Fabric)
	-- gola alta e ombros
	for _, lado in ipairs({ -1, 1 }) do
		cunha(
			m,
			Vector3.new(0.2, 0.8, 0.5),
			CFrame.new(0.55 * lado, 1.5, 0.2) * CFrame.Angles(0, 0, math.rad(-10 * lado)),
			pano:Lerp(PRETO, 0.3),
			Enum.Material.Fabric
		)
		peca(
			m,
			Vector3.new(0.8, 0.55, 1.25),
			CFrame.new(1.45 * lado, 1, 0),
			pano:Lerp(PRETO, 0.2),
			Enum.Material.Fabric
		)
	end
	-- faixa da frente e faixa da cintura
	local enfeite = ri >= 4 and cor or OURO
	local matEnfeite = ri >= 4 and Enum.Material.Neon or Enum.Material.Metal
	peca(
		m,
		Vector3.new(0.3, 3.7, 0.08),
		CFrame.new(0, -0.5, -0.66),
		ri >= 3 and enfeite or pano:Lerp(Color3.new(1, 1, 1), 0.3),
		matEnfeite
	)
	peca(m, Vector3.new(2.45, 0.28, 1.27), CFrame.new(0, -0.75, 0), ri >= 2 and cor or COURO, Enum.Material.Fabric)
	if ri >= 3 then
		peca(m, Vector3.new(0.5, 0.5, 0.2), CFrame.new(0, -0.75, -0.66), enfeite, matEnfeite, Enum.PartType.Ball)
	end
	if ri >= 5 then
		for _, lado in ipairs({ -1, 1 }) do
			peca(
				m,
				Vector3.new(0.25, 0.25, 0.1),
				CFrame.new(0.6 * lado, 0.5, -0.64) * CFrame.Angles(0, 0, math.rad(45)),
				Color3.new(1, 1, 1),
				Enum.Material.Neon
			)
		end
	end
end

local DESENHO_CLASSE = {
	cacador = { arma = arco, elmo = capuz, armadura = couro },
	mago = { arma = cajado, elmo = chapeuMago, armadura = tunica },
}

local DESENHO = { arma = arma, elmo = elmo, armadura = armadura, botas = botas, olho = olho }

-- Detalhes dos conjuntos (sets) por cima do desenho normal
local DETALHE_CONJUNTO = {}

-- Conjunto da Vila Oculta: emblema de folha verde
function DETALHE_CONJUNTO.vila(m, slot)
	local verde = Color3.fromRGB(110, 215, 90)
	local function folha(cf, escala)
		cunha(m, Vector3.new(0.06, 0.45, 0.3) * escala, cf, verde, Enum.Material.Neon)
		cunha(m, Vector3.new(0.06, 0.45, 0.3) * escala, cf * CFrame.Angles(0, math.pi, 0), verde, Enum.Material.Neon)
	end
	if slot == "elmo" then
		folha(CFrame.new(0, 0.05, -0.82) * CFrame.Angles(0, math.pi / 2, 0), 1.2)
	elseif slot == "armadura" then
		folha(CFrame.new(-0.6, 0.6, -0.68) * CFrame.Angles(0, math.pi / 2, 0), 1.5)
		peca(m, Vector3.new(2.52, 0.12, 1.32), CFrame.new(0, -0.55, 0), verde, Enum.Material.Neon)
	elseif slot == "arma" then
		peca(
			m,
			Vector3.new(0.5, 0.5, 0.5),
			CFrame.Angles(0, 0, math.rad(-45)) * CFrame.new(0, -2.35, 0),
			verde,
			Enum.Material.Neon,
			Enum.PartType.Ball
		)
	elseif slot == "botas" then
		for _, lado in ipairs({ -1, 1 }) do
			peca(m, Vector3.new(0.92, 0.1, 0.92), CFrame.new(0.75 * lado, -0.15, 0.15), verde, Enum.Material.Neon)
		end
	end
end

-- Conjunto da Katsuki: preto com nuvens vermelhas e chapéu de palha
function DETALHE_CONJUNTO.katsuki(m, slot)
	local vermelho = Color3.fromRGB(225, 40, 50)
	local function nuvem(cf, escala)
		for _, o in ipairs({ { 0, 0, 0.5 }, { 0.22, 0.05, 0.38 }, { -0.22, 0.03, 0.4 }, { 0.1, 0.16, 0.34 } }) do
			peca(
				m,
				Vector3.new(0.08, o[3], o[3]) * escala,
				cf * CFrame.new(0, o[2] * escala, o[1] * escala),
				vermelho,
				Enum.Material.Neon,
				Enum.PartType.Cylinder
			)
		end
	end
	if slot == "armadura" then
		for _, p in ipairs(m:GetChildren()) do
			if p:IsA("BasePart") and p.Material ~= Enum.Material.Neon then
				p.Color = Color3.fromRGB(24, 22, 30)
			end
		end
		nuvem(CFrame.new(0.5, 0.2, -0.7) * CFrame.Angles(0, math.pi / 2, 0), 1.6)
		nuvem(CFrame.new(-0.6, -0.8, -0.7) * CFrame.Angles(0, math.pi / 2, 0), 1.3)
		nuvem(CFrame.new(1.3, 0.9, -0.4) * CFrame.Angles(0, math.pi / 2, 0), 1)
	elseif slot == "elmo" then
		for _, p in ipairs(m:GetChildren()) do
			p:Destroy()
		end
		-- chapéu de palha cônico (cilindros cada vez menores)
		local palha = Color3.fromRGB(196, 160, 96)
		for i = 0, 5 do
			local r = 3.2 - i * 0.5
			peca(
				m,
				Vector3.new(0.28, r, r),
				CFrame.new(0, i * 0.24, 0) * CFrame.Angles(0, 0, math.rad(90)),
				palha:Lerp(Color3.fromRGB(150, 110, 60), i / 8),
				Enum.Material.Fabric,
				Enum.PartType.Cylinder
			)
		end
		for i = 1, 6 do
			local a = (i / 6) * math.pi * 2
			peca(
				m,
				Vector3.new(0.06, 0.9, 0.06),
				CFrame.new(math.cos(a) * 1.35, -0.45, math.sin(a) * 1.35),
				Color3.fromRGB(235, 235, 240),
				Enum.Material.Fabric
			)
		end
		peca(m, Vector3.new(0.3, 0.3, 0.3), CFrame.new(0, 1.45, 0), vermelho, Enum.Material.Neon, Enum.PartType.Ball)
	elseif slot == "arma" then
		for _, p in ipairs(m:GetChildren()) do
			if p:IsA("BasePart") and p.Material ~= Enum.Material.Fabric then
				p.Color = p.Color:Lerp(Color3.fromRGB(30, 26, 34), 0.6)
			end
		end
		peca(
			m,
			Vector3.new(0.05, 2.6, 0.08),
			CFrame.Angles(0, 0, math.rad(-45)) * CFrame.new(0.07, 0.7, 0),
			vermelho,
			Enum.Material.Neon
		)
	elseif slot == "botas" then
		for _, lado in ipairs({ -1, 1 }) do
			peca(m, Vector3.new(0.92, 0.1, 0.92), CFrame.new(0.75 * lado, -0.15, 0.15), vermelho, Enum.Material.Neon)
		end
	end
end

-- Cria o modelo 3D do item. ri = índice da raridade (1 = Comum ... 8 = Secreto)
function ItemArte.criar(slot, ri, cor, conjunto, classe)
	local m = Instance.new("Model")
	m.Name = "Item3D"
	local daClasse = classe and DESENHO_CLASSE[classe]
	local f = (daClasse and daClasse[slot]) or DESENHO[slot]
	if f then
		f(m, ri, cor)
	end
	if conjunto and DETALHE_CONJUNTO[conjunto] then
		DETALHE_CONJUNTO[conjunto](m, slot)
	end
	m.WorldPivot = CFrame.new()
	return m
end

------------------------------------------------------------------------
-- Equipamento no corpo do herói
------------------------------------------------------------------------
local function soldar(m, base)
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Anchored = false
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
			p.Massless = true
			p.CastShadow = true
			local w = Instance.new("WeldConstraint")
			w.Part0 = base
			w.Part1 = p
			w.Parent = p
		end
	end
end

local function pecaCorpo(char, r15, r6)
	return char:FindFirstChild(r15) or char:FindFirstChild(r6)
end

-- Veste o item no personagem (cria o modelo 3D e solda nas partes do corpo)
function ItemArte.vestir(char, pasta, slot, ri, cor, conjunto, classe)
	if slot == "arma" then
		local mao = pecaCorpo(char, "RightHand", "Right Arm")
		if not mao then
			return
		end
		local m = ItemArte.criar(slot, ri, cor, conjunto, classe)
		local pegada = mao.Name == "Right Arm" and mao.CFrame * CFrame.new(0, -0.95, 0)
			or mao.CFrame * CFrame.new(0, -0.15, 0)
		if classe == "cacador" or classe == "mago" then
			-- arco e cajado ficam em pé na mão (o cabo na palma)
			local sc = classe == "cacador" and 0.5 or 0.6
			m:ScaleTo(sc)
			local cabo = classe == "mago" and -0.7 or 0
			m:PivotTo(pegada * CFrame.new(0, -cabo * sc, 0) * CFrame.Angles(0, 0, math.rad(45)))
			soldar(m, mao)
			m.Parent = pasta
			return
		end
		local s = ri <= 2 and 0.55 or 0.62
		m:ScaleTo(s)
		local alturaCabo = (ri <= 2 and 1.1 or 1.75) * s
		m:PivotTo(
			pegada
				* CFrame.Angles(math.rad(-90), 0, 0)
				* CFrame.new(0, alturaCabo, 0)
				* CFrame.Angles(0, 0, math.rad(45))
		)
		soldar(m, mao)
		m.Parent = pasta
	elseif slot == "elmo" then
		local cabeca = char:FindFirstChild("Head")
		if not cabeca then
			return
		end
		local m = ItemArte.criar(slot, ri, cor, conjunto, classe)
		local escala, desloc
		if conjunto == "katsuki" then
			escala, desloc = 0.55, CFrame.new(0, 0.55, 0)
		elseif classe == "mago" then
			escala, desloc = 0.48, CFrame.new(0, 0.62, 0)
		elseif classe == "cacador" then
			escala, desloc = 0.52, CFrame.new(0, 0.08, 0)
		elseif ri <= 2 then
			escala, desloc = 0.5, CFrame.new(0, 0.18, 0)
		elseif ri == 3 then
			escala, desloc = 0.46, CFrame.new(0, 0, -0.32)
		else
			escala, desloc = 0.55, CFrame.new(0, 0.15, 0)
		end
		for _, p in ipairs(m:GetChildren()) do
			if p.Name == "SombraRosto" then
				p:Destroy()
			end
		end
		m:ScaleTo(escala)
		m:PivotTo(cabeca.CFrame * desloc)
		soldar(m, cabeca)
		m.Parent = pasta
	elseif slot == "armadura" then
		local tronco = pecaCorpo(char, "UpperTorso", "Torso")
		if not tronco then
			return
		end
		local m = ItemArte.criar(slot, ri, cor, conjunto, classe)
		local r15 = tronco.Name == "UpperTorso"
		m:ScaleTo(r15 and 0.72 or 0.82)
		m:PivotTo(tronco.CFrame * CFrame.new(0, r15 and -0.15 or -0.05, 0))
		soldar(m, tronco)
		m.Parent = pasta
	elseif slot == "botas" then
		for _, lado in ipairs({ -1, 1 }) do
			local perna = lado < 0 and pecaCorpo(char, "LeftFoot", "Left Leg")
				or pecaCorpo(char, "RightFoot", "Right Leg")
			if perna then
				local m = ItemArte.criar(slot, ri, cor, conjunto)
				-- deixa só a bota deste lado
				for _, p in ipairs(m:GetChildren()) do
					if p:IsA("BasePart") and math.sign(p.Position.X) ~= lado then
						p:Destroy()
					end
				end
				local r15 = perna.Name:find("Foot") ~= nil
				local s = r15 and 0.6 or 0.72
				m:ScaleTo(s)
				local fundo = r15 and -perna.Size.Y / 2 or -1
				m:PivotTo(perna.CFrame * CFrame.new(-lado * 0.75 * s, fundo + 0.975 * s, -0.1 * s))
				soldar(m, perna)
				m.Parent = pasta
			end
		end
	end
end

-- Tira a aura antiga (antes de vestir de novo)
function ItemArte.limparAura(char)
	for _, d in ipairs(char:GetDescendants()) do
		if (d:IsA("Attachment") and d.Name == "AuraRara") or (d:IsA("PointLight") and d:GetAttribute("AuraRara")) then
			d:Destroy()
		end
	end
end

-- Aura no corpo para quem veste item Mítico ou melhor
function ItemArte.aura(char, pasta, ri, cor)
	local tronco = pecaCorpo(char, "UpperTorso", "Torso")
	if not tronco or ri < 6 then
		return
	end
	local ancora = Instance.new("Attachment")
	ancora.Name = "AuraRara"
	ancora.Parent = tronco
	local secreto = ri >= 8
	local fx = Instance.new("ParticleEmitter")
	fx.Color = ColorSequence.new(
		secreto and Color3.fromRGB(20, 18, 26) or cor,
		secreto and Color3.fromRGB(120, 110, 140) or cor:Lerp(Color3.new(1, 1, 1), 0.5)
	)
	fx.LightEmission = secreto and 0 or 1
	fx.Size =
		NumberSequence.new({ NumberSequenceKeypoint.new(0, ri >= 7 and 0.9 or 0.6), NumberSequenceKeypoint.new(1, 0) })
	fx.Transparency = NumberSequence.new(secreto and 0.2 or 0.3, 1)
	fx.Lifetime = NumberRange.new(0.6, 1.1)
	fx.Rate = ri >= 7 and 28 or 16
	fx.Speed = NumberRange.new(1.5, 3.5)
	fx.SpreadAngle = Vector2.new(180, 180)
	fx.Acceleration = Vector3.new(0, 5, 0)
	fx.Parent = ancora
	if secreto then
		-- faíscas brancas no meio da fumaça preta
		local faisca = Instance.new("ParticleEmitter")
		faisca.Color = ColorSequence.new(Color3.new(1, 1, 1))
		faisca.LightEmission = 1
		faisca.Size = NumberSequence.new(0.18, 0)
		faisca.Lifetime = NumberRange.new(0.3, 0.6)
		faisca.Rate = 20
		faisca.Speed = NumberRange.new(4, 7)
		faisca.SpreadAngle = Vector2.new(180, 180)
		faisca.Parent = ancora
	end
	local luz = Instance.new("PointLight")
	luz.Color = secreto and Color3.fromRGB(200, 190, 255) or cor
	luz.Range = ri >= 7 and 14 or 10
	luz.Brightness = 2
	luz.Parent = tronco
	luz:SetAttribute("AuraRara", true)
	if ri >= 7 then
		local h = Instance.new("Highlight")
		h.Name = "AuraContorno"
		h.FillTransparency = 1
		h.OutlineColor = secreto and Color3.fromRGB(235, 235, 255) or cor
		h.OutlineTransparency = 0.15
		h.Parent = pasta
	end
	-- guarda tudo na pasta do equipamento para limpar junto
	ancora:SetAttribute("Pasta", pasta.Name)
end

-- Coloca o item num ViewportFrame com câmera enquadrando tudo
function ItemArte.mostrar(vp, slot, ri, cor, conjunto, classe)
	local m = ItemArte.criar(slot, ri, cor, conjunto, classe)
	m.Parent = vp
	local cam = Instance.new("Camera")
	cam.FieldOfView = 30
	cam.Parent = vp
	vp.CurrentCamera = cam
	local cf, tam = m:GetBoundingBox()
	local raio = tam.Magnitude / 2
	local dist = raio / math.tan(math.rad(cam.FieldOfView / 2)) * 1.05
	local dir = Vector3.new(0.35, 0.25, -1).Unit
	cam.CFrame = CFrame.lookAt(cf.Position + dir * dist, cf.Position)
	vp.Ambient = Color3.fromRGB(200, 195, 190)
	vp.LightColor = Color3.fromRGB(255, 250, 240)
	vp.LightDirection = Vector3.new(-0.4, -1, 0.6)
	return m
end

return ItemArte
