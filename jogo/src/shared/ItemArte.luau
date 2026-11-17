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

local DESENHO = { arma = arma, elmo = elmo, armadura = armadura, botas = botas, olho = olho }

-- Cria o modelo 3D do item. ri = índice da raridade (1 = Comum ... 8 = Secreto)
function ItemArte.criar(slot, ri, cor)
	local m = Instance.new("Model")
	m.Name = "Item3D"
	local f = DESENHO[slot]
	if f then
		f(m, ri, cor)
	end
	return m
end

-- Coloca o item num ViewportFrame com câmera enquadrando tudo
function ItemArte.mostrar(vp, slot, ri, cor)
	local m = ItemArte.criar(slot, ri, cor)
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
