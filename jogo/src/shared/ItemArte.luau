-- ItemArte: desenha cada equipamento como um modelo 3D (ícones da mochila/forja e o que vai no corpo).
-- Estilo loot de gacha (TBH / WOG): silhuetas grandes e exageradas, e cada tier muda MUITO:
--   T1-T2 madeira/ferro simples · T3-T4 metal colorido + gema · T5 dourado com runas neon
--   T6 cristal/energia · T7 chamas e raios · T8 preto com contorno branco (Vazio)
-- Nos ícones, orbes, anéis e cristais giram/flutuam; no corpo, tiers altos ganham luz e partículas.

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")

local ItemArte = {}

local MAT = Enum.Material
local BRANCO = Color3.new(1, 1, 1)
local PRETO = Color3.fromRGB(22, 20, 26)
local OURO = Color3.fromRGB(255, 196, 72)
local COURO = Color3.fromRGB(96, 62, 40)
local MADEIRA = Color3.fromRGB(132, 92, 58)
local FERRO = Color3.fromRGB(150, 148, 152)
local ACO = Color3.fromRGB(205, 211, 224)
local PANO = Color3.fromRGB(44, 52, 92)

------------------------------------------------------------------------
-- Ajudantes de construção
------------------------------------------------------------------------
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
	p.Material = material or MAT.SmoothPlastic
	if p.Material == MAT.Glass then
		p.Transparency = 0.3
	end
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
	w.CanQuery = false
	w.CanTouch = false
	w.CastShadow = false
	w.Size = tamanho
	w.CFrame = cf
	w.Color = cor
	w.Material = material or MAT.SmoothPlastic
	if w.Material == MAT.Glass then
		w.Transparency = 0.3
	end
	w.Parent = m
	return w
end

local function bola(m, d, cf, cor, material)
	return peca(m, Vector3.new(d, d, d), cf, cor, material, Enum.PartType.Ball)
end

-- cilindro deitado no eixo X do cf
local function cilindro(m, comprimento, diametro, cf, cor, material)
	return peca(m, Vector3.new(comprimento, diametro, diametro), cf, cor, material, Enum.PartType.Cylinder)
end

-- ponta em losango (duas cunhas espelhadas) apontando para +Y, no plano XY do cf
local function ponta(m, cf, largura, altura, espessura, cor, material)
	cunha(
		m,
		Vector3.new(espessura, altura, largura / 2),
		cf * CFrame.new(largura / 4, 0, 0) * CFrame.Angles(0, -math.pi / 2, 0),
		cor,
		material
	)
	cunha(
		m,
		Vector3.new(espessura, altura, largura / 2),
		cf * CFrame.new(-largura / 4, 0, 0) * CFrame.Angles(0, math.pi / 2, 0),
		cor,
		material
	)
end

-- peça comprida ligando dois pontos (no plano XY do cf)
local function ligar(m, cf, a, b, grossura, cor, material, espessura)
	local d = b - a
	local ang = math.atan2(d.X, d.Y)
	return peca(
		m,
		Vector3.new(grossura, d.Magnitude + grossura * 0.4, espessura or grossura * 1.3),
		cf * CFrame.new((a + b) / 2) * CFrame.Angles(0, 0, -ang),
		cor,
		material
	)
end

------------------------------------------------------------------------
-- Animação dos ícones (só no cliente, dentro dos ViewportFrames)
------------------------------------------------------------------------
local animInfo = setmetatable({}, { __mode = "k" })

-- A peça gira em volta do "centro" (CFrame no espaço do modelo), no eixo dado, e pode flutuar.
local function animar(p, centro, eixo, velocidade, flutua)
	animInfo[p] = { centro = centro, eixo = eixo or Vector3.yAxis, vel = velocidade or 0, flut = flutua or 0 }
	return p
end

-- anel feito de bloquinhos no plano XZ do centro (gira no eixo Y do centro se vel ~= 0)
local function anel(m, centro, raio, grossura, cor, material, n, vel)
	n = n or 16
	for i = 1, n do
		local a = (i / n) * math.pi * 2
		local p = peca(
			m,
			Vector3.new(grossura, grossura, 2 * math.pi * raio / n * 1.15),
			centro * CFrame.Angles(0, a, 0) * CFrame.new(raio, 0, 0),
			cor,
			material
		)
		if vel and vel ~= 0 then
			animar(p, centro, Vector3.yAxis, vel)
		end
	end
end

------------------------------------------------------------------------
-- Paleta de cada tier
------------------------------------------------------------------------
local corChama = { Color3.fromRGB(255, 200, 60), Color3.fromRGB(255, 90, 30) }
local function paleta(ri, cor)
	corChama = { Color3.fromRGB(255, 200, 60), Color3.fromRGB(255, 90, 30) }
	if ri <= 1 then
		return {
			corpo = FERRO,
			matCorpo = MAT.Metal,
			fio = Color3.fromRGB(205, 202, 198),
			matFio = MAT.Metal,
			detalhe = MADEIRA,
			matDetalhe = MAT.Wood,
			cabo = COURO,
		}
	elseif ri == 2 then
		return {
			corpo = ACO,
			matCorpo = MAT.Metal,
			fio = cor:Lerp(BRANCO, 0.2),
			matFio = MAT.Metal,
			detalhe = Color3.fromRGB(70, 130, 70),
			matDetalhe = MAT.Metal,
			gema = cor,
			cabo = Color3.fromRGB(50, 90, 50),
		}
	elseif ri == 3 then
		return {
			corpo = cor:Lerp(BRANCO, 0.1),
			matCorpo = MAT.Metal,
			fio = Color3.fromRGB(235, 248, 255),
			matFio = MAT.Neon,
			detalhe = ACO,
			matDetalhe = MAT.Metal,
			gema = Color3.fromRGB(130, 235, 255),
			cabo = Color3.fromRGB(28, 38, 84),
		}
	elseif ri == 4 then
		return {
			corpo = cor:Lerp(PRETO, 0.4),
			matCorpo = MAT.Metal,
			fio = cor:Lerp(BRANCO, 0.35),
			matFio = MAT.Neon,
			detalhe = cor,
			matDetalhe = MAT.Metal,
			gema = Color3.fromRGB(255, 130, 255),
			cabo = PRETO,
		}
	elseif ri == 5 then
		return {
			corpo = OURO,
			matCorpo = MAT.Metal,
			fio = Color3.fromRGB(255, 130, 30),
			matFio = MAT.Neon,
			detalhe = Color3.fromRGB(255, 236, 170),
			matDetalhe = MAT.Neon,
			gema = Color3.fromRGB(255, 50, 40),
			cabo = Color3.fromRGB(130, 30, 22),
			runas = true,
		}
	elseif ri == 6 then
		return {
			corpo = Color3.fromRGB(255, 150, 200),
			matCorpo = MAT.Glass,
			fio = BRANCO,
			matFio = MAT.Neon,
			detalhe = cor,
			matDetalhe = MAT.Neon,
			gema = Color3.fromRGB(130, 240, 255),
			cabo = Color3.fromRGB(90, 20, 60),
			cristal = true,
		}
	elseif ri == 7 then
		-- Imortal: turquesa, cristal etéreo com chamas frias
		corChama = { Color3.fromRGB(200, 255, 250), Color3.fromRGB(30, 210, 200) }
		return {
			corpo = Color3.fromRGB(120, 235, 225),
			matCorpo = MAT.Glass,
			fio = Color3.fromRGB(60, 255, 235),
			matFio = MAT.Neon,
			detalhe = Color3.fromRGB(220, 255, 252),
			matDetalhe = MAT.Neon,
			gema = Color3.fromRGB(150, 255, 245),
			cabo = Color3.fromRGB(10, 70, 80),
			chama = true,
			runas = true,
		}
	elseif ri == 8 then
		-- Divino: ouro sagrado e luz branca
		corChama = { Color3.fromRGB(255, 255, 230), Color3.fromRGB(255, 205, 50) }
		return {
			corpo = Color3.fromRGB(255, 244, 210),
			matCorpo = MAT.Metal,
			fio = Color3.fromRGB(255, 214, 60),
			matFio = MAT.Neon,
			detalhe = Color3.fromRGB(255, 252, 225),
			matDetalhe = MAT.Neon,
			gema = Color3.fromRGB(255, 250, 200),
			cabo = Color3.fromRGB(190, 140, 40),
			chama = true,
			runas = true,
			cristal = true,
			sagrado = true,
		}
	end
	return {
		corpo = Color3.fromRGB(16, 14, 20),
		matCorpo = MAT.SmoothPlastic,
		fio = BRANCO,
		matFio = MAT.Neon,
		detalhe = Color3.fromRGB(205, 205, 255),
		matDetalhe = MAT.Neon,
		gema = BRANCO,
		cabo = Color3.fromRGB(10, 10, 14),
		vazio = true,
	}
end

-- chamas: cunhas laranja/vermelhas subindo a partir de um ponto
local function chamas(m, cf, tamanho, qtd)
	for i = 1, qtd do
		local lado = (i % 2 == 0) and 1 or -1
		local h = tamanho * (0.7 + (i % 3) * 0.25)
		cunha(
			m,
			Vector3.new(0.08, h, tamanho * 0.45),
			cf
				* CFrame.new(lado * (i - 1) * tamanho * 0.12, h / 2, 0)
				* CFrame.Angles(0, math.pi / 2 * lado, 0.15 * lado),
			i % 2 == 0 and corChama[1] or corChama[2],
			MAT.Neon
		)
	end
end

-- espinhos/cristais em volta de um centro, apontando para cima
local function coroaEspinhos(m, centro, raio, altura, n, cor, material, vel)
	for i = 1, n do
		local a = (i / n) * math.pi * 2
		local p = cunha(
			m,
			Vector3.new(0.12, altura, altura * 0.4),
			centro * CFrame.Angles(0, a, 0) * CFrame.new(raio, altura / 2, 0) * CFrame.Angles(0, math.pi / 2, 0),
			cor,
			material
		)
		if vel then
			animar(p, centro, Vector3.yAxis, vel)
		end
	end
end

------------------------------------------------------------------------
-- Guerreiro: espada
------------------------------------------------------------------------
local ESPADA = {
	-- comprimento, largura na base, largura na ponta, curva
	{ 2.6, 0.42, 0.34, 0 },
	{ 3.0, 0.52, 0.42, 0 },
	{ 3.4, 0.72, 0.56, 0.15 },
	{ 3.8, 0.86, 0.6, 0.35 },
	{ 4.0, 1.0, 0.72, 0.25 },
	{ 4.0, 0.92, 0.62, 0.2 },
	{ 4.2, 1.0, 0.7, 0.35 },
	{ 4.4, 1.05, 0.55, 0.45 },
}

local function lamina(m, cf, L, w0, w1, curva, pal, n)
	n = n or 5
	local pts = {}
	for i = 0, n do
		local t = i / n
		pts[i] = Vector3.new(curva * t * t, L * t, 0)
	end
	for i = 1, n do
		local a, b = pts[i - 1], pts[i]
		local t = (i - 0.5) / n
		local w = w0 + (w1 - w0) * t
		local d = b - a
		local seg = cf * CFrame.new((a + b) / 2) * CFrame.Angles(0, 0, -math.atan2(d.X, d.Y))
		local corpo = peca(m, Vector3.new(w, d.Magnitude + 0.03, 0.16), seg, pal.corpo, pal.matCorpo)
		if i == 2 then
			corpo.Name = "Nucleo"
		end
		-- fio da lâmina (lado de corte) e lombada
		peca(m, Vector3.new(w * 0.22, d.Magnitude + 0.03, 0.1), seg * CFrame.new(w * 0.5, 0, 0), pal.fio, pal.matFio)
		peca(
			m,
			Vector3.new(w * 0.12, d.Magnitude + 0.03, 0.2),
			seg * CFrame.new(-w * 0.5, 0, 0),
			pal.corpo:Lerp(PRETO, 0.3),
			pal.matCorpo
		)
		if pal.runas and i < n then
			peca(
				m,
				Vector3.new(w * 0.22, w * 0.22, 0.18),
				seg * CFrame.Angles(0, 0, math.rad(45)),
				pal.detalhe,
				MAT.Neon
			)
		end
	end
	local topo, ant = pts[n], pts[n - 1]
	local d = topo - ant
	local pcf = cf * CFrame.new(topo) * CFrame.Angles(0, 0, -math.atan2(d.X, d.Y))
	ponta(m, pcf * CFrame.new(0, w1 * 0.55, 0), w1 * 1.05, w1 * 1.1, 0.16, pal.fio, pal.matFio)
	return pts
end

local function espada(m, ri, cor)
	local pal = paleta(ri, cor)
	local base = CFrame.Angles(0, 0, math.rad(-45)) -- deitada na diagonal, como ícone de jogo
	local cfg = ESPADA[ri] or ESPADA[8]
	local w0 = cfg[2]
	local pts = lamina(m, base, cfg[1], w0, cfg[3], cfg[4], pal)
	-- cabo e pomo
	peca(m, Vector3.new(0.3, 1.25, 0.3), base * CFrame.new(0, -0.72, 0), pal.cabo, MAT.Fabric)
	for i = 0, 3 do
		peca(
			m,
			Vector3.new(0.34, 0.07, 0.34),
			base * CFrame.new(0, -0.25 - i * 0.3, 0) * CFrame.Angles(0, 0, 0.35),
			pal.detalhe,
			ri >= 5 and MAT.Metal or MAT.Fabric
		)
	end
	bola(m, 0.42, base * CFrame.new(0, -1.42, 0), pal.gema or pal.detalhe, pal.gema and MAT.Neon or MAT.Metal)
	-- guarda-mão: muda muito com o tier
	local guarda = base * CFrame.new(0, -0.02, 0)
	if ri <= 2 then
		peca(m, Vector3.new(1.0 + ri * 0.2, 0.16, 0.28), guarda, pal.detalhe, MAT.Metal)
	elseif ri <= 4 then
		peca(m, Vector3.new(1.5, 0.22, 0.34), guarda, ri == 3 and ACO or pal.corpo, MAT.Metal)
		for _, lado in ipairs({ -1, 1 }) do
			-- chifres subindo
			cunha(
				m,
				Vector3.new(0.14, 0.7 + (ri - 3) * 0.3, 0.3),
				guarda * CFrame.new(0.72 * lado, 0.3, 0) * CFrame.Angles(0, math.pi / 2 * -lado, 0.3 * lado),
				ri == 4 and pal.fio or ACO,
				ri == 4 and MAT.Neon or MAT.Metal
			)
		end
		bola(m, 0.36, guarda * CFrame.new(0, 0, -0.12), pal.gema, MAT.Neon)
	else
		-- asas grandes (T5+)
		local corAsa = (pal.vazio or pal.cristal) and pal.corpo or OURO
		local matAsa = pal.cristal and MAT.Glass or (pal.vazio and MAT.SmoothPlastic or MAT.Metal)
		for _, lado in ipairs({ -1, 1 }) do
			for k = 0, 2 do
				cunha(
					m,
					Vector3.new(0.12, 0.95 - k * 0.2, 0.55),
					guarda
						* CFrame.new(lado * (0.45 + k * 0.32), 0.12 + k * 0.08, 0)
						* CFrame.Angles(0, math.pi / 2 * -lado, math.rad(-35 - k * 18) * lado),
					corAsa,
					matAsa
				)
			end
			peca(
				m,
				Vector3.new(0.9, 0.08, 0.1),
				guarda * CFrame.new(lado * 0.75, 0.2, -0.05) * CFrame.Angles(0, 0, math.rad(25) * lado),
				pal.fio,
				MAT.Neon
			)
		end
		bola(m, 0.5, guarda * CFrame.new(0, 0, -0.14), pal.gema, MAT.Neon)
	end
	-- extras dos tiers altos
	local meio = base * CFrame.new(pts[3])
	if pal.cristal then
		-- cristais girando em volta da lâmina
		for i = 1, 3 do
			local a = (i / 3) * math.pi * 2
			animar(
				cunha(
					m,
					Vector3.new(0.12, 0.6, 0.3),
					meio * CFrame.new(math.cos(a) * 0.95, -0.6 + i * 0.5, math.sin(a) * 0.95),
					i == 2 and pal.gema or pal.detalhe,
					MAT.Neon
				),
				meio,
				Vector3.yAxis,
				1.6
			)
		end
	end
	if pal.chama then
		-- chamas saindo da lombada
		for i = 1, 4 do
			chamas(
				m,
				base * CFrame.new(pts[i] + Vector3.new(-w0 * 0.55, 0, 0)) * CFrame.Angles(0, 0, math.rad(60)),
				0.55,
				2
			)
		end
	end
	if pal.vazio then
		-- espinhos na lombada e orbes brancos flutuando
		for i = 1, 4 do
			cunha(
				m,
				Vector3.new(0.1, 0.55, 0.35),
				base * CFrame.new(pts[i] + Vector3.new(-w0 * 0.6, 0, 0)) * CFrame.Angles(0, math.pi / 2, math.rad(50)),
				pal.corpo,
				MAT.SmoothPlastic
			)
		end
		for i = 1, 2 do
			animar(
				bola(m, 0.35, meio * CFrame.new(i == 1 and 0.9 or -0.9, i * 0.4, 0), BRANCO, MAT.Neon),
				meio,
				Vector3.yAxis,
				-1.2,
				0.15
			)
		end
	end
	m:SetAttribute("Pomo", (base * CFrame.new(0, -1.42, 0)).Position)
end

------------------------------------------------------------------------
-- Caçador: arco
------------------------------------------------------------------------
local function arco(m, ri, cor)
	local pal = paleta(ri, cor)
	local base = CFrame.Angles(0, 0, math.rad(-45))
	local corBraco = ri <= 2 and (ri == 1 and MADEIRA or Color3.fromRGB(122, 168, 80)) or pal.corpo
	local matBraco = ri <= 2 and MAT.Wood or pal.matCorpo
	local grosso = 0.32 + ri * 0.025
	local N = 6
	local pontas = {}
	for _, lado in ipairs({ -1, 1 }) do
		local ant = Vector3.new(0, 0, 0)
		for i = 1, N do
			local t = i / N
			local p = Vector3.new(1.0 * t ^ 1.7, lado * (0.4 + 2.7 * t), 0)
			if ri >= 3 and i == N then
				p += Vector3.new(-0.3, 0, 0) -- pontas recurvas
			end
			local seg = ligar(m, base, ant, p, grosso - t * 0.12, corBraco, matBraco)
			if i == 2 and lado == 1 then
				seg.Name = "Nucleo"
			end
			-- lâmina afiada nas costas do braço (T3+)
			if ri >= 3 and i >= 2 and i <= 4 then
				cunha(
					m,
					Vector3.new(0.08, 0.7, 0.35 + ri * 0.04),
					base
						* CFrame.new((ant + p) / 2 + Vector3.new(-0.28, 0, 0))
						* CFrame.Angles(lado > 0 and 0 or math.pi, math.pi / 2, 0),
					pal.fio,
					pal.matFio
				)
			end
			if pal.runas and i % 2 == 1 then
				peca(m, Vector3.new(0.16, 0.16, 0.3), base * CFrame.new(p), pal.detalhe, MAT.Neon)
			end
			ant = p
		end
		pontas[lado] = ant
		-- pontas: metal, gema ou cristal grande
		local pcf = base
			* CFrame.new(ant + Vector3.new(0, lado * 0.25, 0))
			* CFrame.Angles(lado > 0 and 0 or math.pi, 0, 0)
		if ri == 2 then
			ponta(m, pcf, 0.3, 0.45, 0.14, ACO, MAT.Metal)
		elseif ri >= 3 then
			ponta(m, pcf * CFrame.new(0, 0.15, 0), 0.45 + ri * 0.03, 0.75 + ri * 0.06, 0.18, pal.gema, MAT.Neon)
		end
		if pal.chama then
			chamas(m, base * CFrame.new(ant), 0.6, 3)
		end
	end
	-- corda
	local corda = ri >= 4 and pal.fio or Color3.fromRGB(235, 230, 215)
	ligar(m, base, pontas[-1], pontas[1], 0.07, corda, ri >= 4 and MAT.Neon or MAT.Fabric)
	-- empunhadura com gema
	peca(m, Vector3.new(0.42, 0.95, 0.46), base, pal.cabo, MAT.Fabric)
	if pal.gema then
		bola(m, 0.4, base * CFrame.new(-0.12, 0, -0.18), pal.gema, MAT.Neon)
	end
	-- flecha encaixada com ponta brilhante
	local cordaX = pontas[1].X
	peca(m, Vector3.new(2.5, 0.08, 0.08), base * CFrame.new(cordaX - 1.2, 0, 0), Color3.fromRGB(150, 110, 70))
	cunha(
		m,
		Vector3.new(0.08, 0.55, 0.32),
		base * CFrame.new(cordaX - 2.6, 0, 0) * CFrame.Angles(0, 0, math.rad(90)),
		pal.gema or ACO,
		pal.gema and MAT.Neon or MAT.Metal
	)
	for _, lado in ipairs({ -1, 1 }) do
		cunha(
			m,
			Vector3.new(0.04, 0.4, 0.2),
			base * CFrame.new(cordaX - 0.15, lado * 0.11, 0) * CFrame.Angles(0, 0, math.rad(-90 * lado)),
			ri >= 4 and pal.fio or cor,
			ri >= 4 and MAT.Neon or MAT.Fabric
		)
	end
	if pal.cristal or pal.vazio then
		-- fragmentos girando em volta do arco
		for i = 1, 3 do
			local a = (i / 3) * math.pi * 2
			animar(
				cunha(
					m,
					Vector3.new(0.1, 0.5, 0.25),
					base * CFrame.new(math.cos(a) * 1.1, math.sin(a) * 1.6, 0.4),
					pal.vazio and BRANCO or pal.detalhe,
					MAT.Neon
				),
				base,
				Vector3.zAxis,
				1.2
			)
		end
	end
end

------------------------------------------------------------------------
-- Mago: cajado com orbe flutuando e anéis girando
------------------------------------------------------------------------
local function cajado(m, ri, cor)
	local pal = paleta(ri, cor)
	local base = CFrame.Angles(0, 0, math.rad(-45))
	local haste = ri == 1 and MADEIRA
		or (ri == 2 and Color3.fromRGB(120, 170, 80) or (ri == 3 and Color3.fromRGB(70, 48, 40) or pal.corpo))
	local matHaste = ri <= 3 and MAT.Wood or pal.matCorpo
	local corpo = peca(m, Vector3.new(0.32, 4.4, 0.32), base * CFrame.new(0, -0.2, 0), haste, matHaste)
	corpo.Name = "Nucleo"
	for i = 0, 2 do
		peca(
			m,
			Vector3.new(0.42, 0.14, 0.42),
			base * CFrame.new(0, -1.9 + i * 1.15, 0),
			ri >= 3 and (ri == 3 and ACO or pal.fio) or haste:Lerp(PRETO, 0.3),
			ri >= 4 and pal.matFio or (ri == 3 and MAT.Metal or MAT.Wood)
		)
	end
	bola(
		m,
		0.45,
		base * CFrame.new(0, -2.45, 0),
		ri >= 3 and (pal.gema or haste) or haste:Lerp(PRETO, 0.2),
		ri >= 3 and MAT.Neon or MAT.Wood
	)
	local topo = base * CFrame.new(0, 2.85, 0)
	if ri == 1 then
		-- galho torto com folhinha
		ligar(m, base, Vector3.new(0, 1.9, 0), Vector3.new(0.45, 2.6, 0), 0.22, haste, MAT.Wood)
		ligar(m, base, Vector3.new(0, 1.9, 0), Vector3.new(-0.35, 2.5, 0), 0.18, haste, MAT.Wood)
		bola(m, 0.4, base * CFrame.new(0.45, 2.7, 0), Color3.fromRGB(120, 190, 90), MAT.SmoothPlastic)
		return
	end
	-- garras em volta do orbe
	local nGarras = ri >= 5 and 4 or 3
	for i = 1, nGarras do
		local garra = topo * CFrame.Angles(0, (i / nGarras) * math.pi * 2, 0)
		ligar(
			m,
			garra,
			Vector3.new(0, -1.05, 0),
			Vector3.new(0.6, -0.2, 0),
			0.14,
			ri >= 5 and OURO or (ri == 2 and haste or ACO),
			MAT.Metal
		)
		cunha(
			m,
			Vector3.new(0.12, 0.5, 0.2),
			garra * CFrame.new(0.62, 0.12, 0) * CFrame.Angles(0, math.pi / 2, math.rad(-15)),
			ri >= 4 and pal.fio or ACO,
			ri >= 4 and MAT.Neon or MAT.Metal
		)
	end
	-- orbe grande flutuando (com núcleo branco)
	local corOrbe = ri == 2 and Color3.fromRGB(140, 230, 140) or (pal.vazio and Color3.fromRGB(14, 12, 18) or cor)
	local tam = 0.75 + ri * 0.13
	if ri >= 6 then
		-- asas de luz abrindo dos lados do orbe
		for _, lado in ipairs({ -1, 1 }) do
			for k = 1, 3 do
				cunha(
					m,
					Vector3.new(0.1, 0.5 + k * 0.32, 0.42),
					topo
						* CFrame.new((0.75 + k * 0.32) * lado, -0.55 + k * 0.18, 0)
						* CFrame.Angles(0, math.rad(90 * lado), math.rad(-(18 + k * 14) * lado)),
					k == 2 and pal.detalhe or pal.fio,
					MAT.Neon
				)
			end
		end
	end
	animar(bola(m, tam, topo, corOrbe, pal.vazio and MAT.SmoothPlastic or MAT.Neon), topo, Vector3.yAxis, 0, 0.12)
	if not pal.vazio then
		animar(bola(m, tam * 0.5, topo, BRANCO, MAT.Neon), topo, Vector3.yAxis, 0, 0.12)
	end
	-- anéis girando: 1 (T3-T4), 2 cruzados (T5-T6), 3 (T7-T8)
	local nAneis = ri >= 7 and 3 or (ri >= 5 and 2 or (ri >= 3 and 1 or 0))
	for k = 1, nAneis do
		local inclin = topo * CFrame.Angles(math.rad(70), math.rad(k * 60), 0)
		anel(
			m,
			inclin,
			tam * 0.85 + k * 0.08,
			0.09,
			k == 2 and pal.detalhe or pal.fio,
			MAT.Neon,
			18,
			(k % 2 == 0) and -2 or 2.4
		)
	end
	if pal.cristal then
		for i = 1, 4 do
			local a = (i / 4) * math.pi * 2
			animar(
				cunha(
					m,
					Vector3.new(0.12, 0.6, 0.3),
					topo * CFrame.new(math.cos(a) * 1.25, math.sin(a) * 0.3, math.sin(a) * 1.25),
					i % 2 == 0 and pal.gema or pal.detalhe,
					MAT.Neon
				),
				topo,
				Vector3.yAxis,
				-1.4
			)
		end
	end
	if pal.chama then
		chamas(m, topo * CFrame.new(0, tam * 0.3, 0), 0.8, 4)
	end
	if pal.runas then
		for i = 1, 3 do
			peca(
				m,
				Vector3.new(0.2, 0.2, 0.36),
				base * CFrame.new(0, -1.35 + i * 0.75, 0) * CFrame.Angles(0, 0, math.rad(45)),
				pal.detalhe,
				MAT.Neon
			)
		end
	end
end

------------------------------------------------------------------------
-- Guerreiro: elmo
------------------------------------------------------------------------
local function elmo(m, ri, cor)
	local pal = paleta(ri, cor)
	if ri == 1 then
		-- bandana de pano com placa de ferro
		peca(m, Vector3.new(2.6, 0.7, 1.4), CFrame.new(0, 0, 0), Color3.fromRGB(150, 120, 90), MAT.Fabric).Name =
			"Nucleo"
		peca(m, Vector3.new(1.3, 0.6, 0.12), CFrame.new(0, 0, -0.72), FERRO, MAT.Metal)
		for _, lado in ipairs({ -1, 1 }) do
			peca(
				m,
				Vector3.new(0.3, 1.5, 0.1),
				CFrame.new(0.4 * lado, -0.6, 0.8) * CFrame.Angles(0.3, 0, 0.25 * lado),
				Color3.fromRGB(150, 120, 90),
				MAT.Fabric
			)
		end
		return
	end
	-- casco puxado para cima e para trás: o rosto do herói fica à mostra
	local casco = bola(m, 2.5, CFrame.new(0, 0.35, 0.25), ri == 2 and ACO or pal.corpo, pal.matCorpo)
	casco.Name = "Nucleo"
	-- protetor de nuca (atrás) e testeira (na frente)
	peca(
		m,
		Vector3.new(2.6, 0.55, 1.3),
		CFrame.new(0, -0.15, 0.75) * CFrame.Angles(math.rad(-20), 0, 0),
		pal.vazio and pal.corpo or (ri >= 5 and OURO or pal.detalhe),
		pal.vazio and MAT.SmoothPlastic or MAT.Metal
	)
	peca(m, Vector3.new(2.0, 0.34, 0.24), CFrame.new(0, 0.62, -0.98), ri == 2 and FERRO or PRETO, MAT.Metal)
	if ri >= 3 then
		peca(m, Vector3.new(2.02, 0.08, 0.26), CFrame.new(0, 0.62, -0.99), pal.fio, MAT.Neon)
	end
	-- sombra do rosto com olhos brilhando (só no ícone)
	peca(
		m,
		Vector3.new(1.6, 1.4, 0.5),
		CFrame.new(0, -0.05, -0.75),
		Color3.fromRGB(16, 14, 20),
		MAT.SmoothPlastic,
		Enum.PartType.Ball
	).Name =
		"SombraRosto"
	for _, lado in ipairs({ -1, 1 }) do
		peca(
			m,
			Vector3.new(0.34, 0.13, 0.1),
			CFrame.new(0.3 * lado, 0.08, -0.98) * CFrame.Angles(0, 0, math.rad(-12 * lado)),
			ri >= 3 and (pal.gema or BRANCO) or Color3.fromRGB(255, 240, 200),
			MAT.Neon
		).Name =
			"SombraRosto"
	end
	if ri == 2 then
		peca(m, Vector3.new(0.3, 0.5, 1.8), CFrame.new(0, 1.6, 0.3), pal.gema, MAT.Fabric) -- penacho
		return
	end
	if ri == 3 then
		-- crista no topo
		for i = -2, 2 do
			peca(
				m,
				Vector3.new(0.18, 0.5 - math.abs(i) * 0.08, 0.38),
				CFrame.new(0, 1.62, 0.25 + i * 0.38),
				pal.fio,
				MAT.Neon
			)
		end
		bola(m, 0.42, CFrame.new(0, 0.66, -1.12), pal.gema, MAT.Neon)
		return
	end
	-- chifres curvados (T4+): segmentos que sobem e abrem
	local corChifre = pal.vazio and pal.corpo or (pal.cristal and pal.detalhe or (ri == 5 and OURO or pal.fio))
	local matChifre = pal.vazio and MAT.SmoothPlastic or ((pal.cristal or ri == 4) and MAT.Neon or MAT.Metal)
	for _, lado in ipairs({ -1, 1 }) do
		local ant = Vector3.new(0.85 * lado, 0.75, -0.3)
		for i = 1, 4 do
			local t = i / 4
			local p = Vector3.new(lado * (0.85 + 0.9 * t), 0.75 + 1.5 * t - 0.4 * t * t, -0.3 + 0.2 * t)
			ligar(m, CFrame.new(), ant, p, 0.36 - t * 0.2, corChifre, matChifre, 0.36 - t * 0.2)
			ant = p
		end
		if pal.vazio then
			bola(m, 0.14, CFrame.new(ant), BRANCO, MAT.Neon)
		end
	end
	if ri >= 5 then
		-- lua crescente na frente (como o enfeite do kabuto), em "U" com as pontas para cima
		local frente = CFrame.new(0, 1.55, -1.12)
		local ant
		for i = 0, 8 do
			local a = math.rad(-80 + i * 20)
			local p = Vector3.new(math.sin(a) * 0.95, -math.cos(a) * 0.85, 0)
			if ant then
				local t = math.abs(i - 4) / 4
				ligar(m, frente, ant, p, 0.26 - t * 0.14, pal.fio, MAT.Neon, 0.12)
			end
			ant = p
		end
	end
	bola(m, 0.5, CFrame.new(0, 0.66, -1.12), pal.gema, MAT.Neon)
	if pal.cristal then
		coroaEspinhos(m, CFrame.new(0, 1.2, 0.25), 0.75, 0.8, 6, pal.detalhe, MAT.Neon)
		anel(m, CFrame.new(0, 2.25, 0.25), 0.75, 0.1, BRANCO, MAT.Neon, 14, 2)
	end
	if pal.chama then
		chamas(m, CFrame.new(0, 1.4, 0.4), 1.0, 5)
	end
end

------------------------------------------------------------------------
-- Guerreiro: armadura
------------------------------------------------------------------------
local function armadura(m, ri, cor)
	local pal = paleta(ri, cor)
	local base = ri == 1 and Color3.fromRGB(120, 105, 80) or (ri == 2 and Color3.fromRGB(96, 76, 54) or pal.corpo)
	local matBase = ri <= 2 and MAT.Fabric or pal.matCorpo
	peca(m, Vector3.new(2.4, 2.6, 1.2), CFrame.new(0, 0, 0), base, matBase).Name = "Nucleo"
	peca(m, Vector3.new(2.5, 0.45, 1.3), CFrame.new(0, 1.2, 0), base:Lerp(PRETO, 0.3), matBase)
	-- peitoral
	if ri >= 2 then
		local corPeito = ri == 2 and FERRO or (ri >= 5 and (pal.vazio and pal.corpo or OURO) or pal.detalhe)
		peca(
			m,
			Vector3.new(2.0, 1.4, 0.2),
			CFrame.new(0, 0.35, -0.66),
			corPeito,
			pal.vazio and MAT.SmoothPlastic or MAT.Metal
		)
		if ri >= 3 then
			-- contorno brilhante do peitoral e gema no meio
			peca(m, Vector3.new(2.05, 0.1, 0.22), CFrame.new(0, 1.05, -0.67), pal.fio, pal.matFio)
			peca(m, Vector3.new(2.05, 0.1, 0.22), CFrame.new(0, -0.35, -0.67), pal.fio, pal.matFio)
			bola(m, 0.5 + ri * 0.03, CFrame.new(0, 0.35, -0.8), pal.gema, MAT.Neon)
		end
	end
	-- cinto
	peca(
		m,
		Vector3.new(2.45, 0.3, 1.25),
		CFrame.new(0, -0.9, 0),
		ri >= 4 and pal.fio or COURO,
		ri >= 4 and pal.matFio or MAT.Fabric
	)
	-- ombreiras: crescem com o tier
	local tamOmbro = 0.8 + ri * 0.075
	for _, lado in ipairs({ -1, 1 }) do
		local cfO = CFrame.new((1.25 + tamOmbro * 0.3) * lado, 1.05, 0)
		if ri <= 2 then
			peca(m, Vector3.new(0.8, 0.55, 1.25), cfO, base:Lerp(PRETO, 0.2), MAT.Fabric)
		else
			local corOmbro = pal.cristal and pal.corpo or (ri == 5 and OURO or pal.corpo:Lerp(PRETO, 0.15))
			bola(m, tamOmbro, cfO, corOmbro, pal.matCorpo)
			peca(
				m,
				Vector3.new(tamOmbro * 0.9, 0.12, tamOmbro * 0.9),
				cfO * CFrame.new(0, -tamOmbro * 0.2, 0),
				pal.fio,
				pal.matFio
			)
			if ri >= 4 then
				-- espinhos para cima
				for k = 0, ri >= 6 and 2 or 1 do
					cunha(
						m,
						Vector3.new(0.14, 0.5 + ri * 0.08, 0.38),
						cfO
							* CFrame.new(0, tamOmbro * 0.4, (k - 0.5) * 0.35)
							* CFrame.Angles(0, math.pi / 2 * -lado, math.rad(-20) * lado),
						pal.vazio and pal.corpo or (pal.cristal and pal.detalhe or pal.fio),
						pal.vazio and MAT.SmoothPlastic or MAT.Neon
					)
				end
			end
			if pal.chama then
				chamas(m, cfO * CFrame.new(0, tamOmbro * 0.35, 0), 0.8, 3)
			end
		end
	end
	-- capa nas costas (T5+)
	if ri >= 5 then
		local corCapa = pal.vazio and Color3.fromRGB(8, 8, 12)
			or (ri == 5 and Color3.fromRGB(170, 30, 30) or cor:Lerp(PRETO, 0.3))
		peca(
			m,
			Vector3.new(2.2, 2.5, 0.1),
			CFrame.new(0, -0.15, 0.66) * CFrame.Angles(math.rad(8), 0, 0),
			corCapa,
			MAT.Fabric
		)
		peca(
			m,
			Vector3.new(2.22, 0.1, 0.12),
			CFrame.new(0, -1.38, 0.84) * CFrame.Angles(math.rad(8), 0, 0),
			pal.fio,
			MAT.Neon
		)
	end
	if pal.runas then
		for _, lado in ipairs({ -1, 1 }) do
			peca(
				m,
				Vector3.new(0.22, 0.22, 0.1),
				CFrame.new(0.65 * lado, -0.35, -0.66) * CFrame.Angles(0, 0, math.rad(45)),
				pal.detalhe,
				MAT.Neon
			)
		end
	end
	if pal.vazio then
		-- rachaduras brancas
		for i = 1, 3 do
			peca(
				m,
				Vector3.new(0.06, 0.7, 0.05),
				CFrame.new(-0.6 + i * 0.3, -0.2 + (i % 2) * 0.3, -0.78) * CFrame.Angles(0, 0, math.rad(i * 25 - 50)),
				BRANCO,
				MAT.Neon
			)
		end
	end
end

------------------------------------------------------------------------
-- Botas (servem para todas as classes)
------------------------------------------------------------------------
local function botas(m, ri, cor)
	local pal = paleta(ri, cor)
	for _, lado in ipairs({ -1, 1 }) do
		local x = 0.75 * lado
		local altura = ri <= 2 and 0.9 or 1.8
		local cano = peca(
			m,
			Vector3.new(0.85, altura, 0.85),
			CFrame.new(x, -0.6 + altura / 2, 0.15),
			ri <= 2 and COURO or pal.corpo,
			ri <= 2 and MAT.Fabric or pal.matCorpo
		)
		if lado == 1 then
			cano.Name = "Nucleo"
		end
		peca(
			m,
			Vector3.new(0.95, 0.45, 1.6),
			CFrame.new(x, -0.75, -0.25),
			ri <= 2 and Color3.fromRGB(70, 50, 36) or (pal.vazio and pal.corpo or PRETO)
		)
		peca(
			m,
			Vector3.new(0.9, 0.12, 0.9),
			CFrame.new(x, -0.4, 0.15),
			ri <= 2 and cor or pal.fio,
			ri <= 2 and MAT.Metal or pal.matFio
		)
		if ri >= 3 then
			-- joelheira com gema
			peca(m, Vector3.new(0.6, 0.55, 0.2), CFrame.new(x, 0.95, -0.32), ri >= 5 and OURO or ACO, MAT.Metal)
			bola(m, 0.24, CFrame.new(x, 0.95, -0.45), pal.gema, MAT.Neon)
			peca(m, Vector3.new(0.92, 0.1, 0.92), CFrame.new(x, 1.15, 0.15), pal.fio, pal.matFio)
		end
		if ri >= 4 then
			-- asinhas no tornozelo (maiores a cada tier)
			for k = 0, ri >= 5 and 1 or 0 do
				cunha(
					m,
					Vector3.new(0.12, 0.8 + ri * 0.08 - k * 0.3, 1.0 + ri * 0.06),
					CFrame.new(x + 0.5 * lado, 0.55 - k * 0.35, 0.45)
						* CFrame.Angles(math.rad(-30), lado > 0 and math.pi / 2 or -math.pi / 2, 0),
					pal.vazio and pal.corpo or (pal.cristal and pal.detalhe or (ri == 5 and OURO or pal.fio)),
					pal.vazio and MAT.SmoothPlastic or (ri == 5 and MAT.Metal or MAT.Neon)
				)
			end
		end
		if pal.chama then
			chamas(m, CFrame.new(x, -0.55, 0.6), 0.6, 2)
		end
	end
end

------------------------------------------------------------------------
-- Olho (Rinnegan): anéis concêntricos, com um anel girando no ícone
------------------------------------------------------------------------
local function olho(m, _, cor)
	local frente = CFrame.Angles(0, math.rad(90), 0)
	cilindro(m, 0.3, 2.8, frente, Color3.fromRGB(235, 225, 245)).Name = "Nucleo"
	local corAnel = cor:Lerp(Color3.fromRGB(150, 110, 220), 0.5)
	for i, r in ipairs({ 2.5, 1.9, 1.3 }) do
		cilindro(m, 0.32 + i * 0.01, r, frente * CFrame.new(-0.01 * i, 0, 0), corAnel, MAT.Neon)
		cilindro(m, 0.33 + i * 0.01, r - 0.18, frente * CFrame.new(-0.012 * i, 0, 0), Color3.fromRGB(200, 185, 235))
	end
	cilindro(m, 0.4, 0.6, frente, PRETO)
	anel(m, CFrame.Angles(math.rad(90), 0, 0), 1.7, 0.1, corAnel, MAT.Neon, 20, 1.5)
end

------------------------------------------------------------------------
-- Caçador: capuz e colete de couro
------------------------------------------------------------------------
local function capuz(m, ri, cor)
	local pal = paleta(ri, cor)
	local pano = ri == 1 and Color3.fromRGB(128, 100, 70)
		or (
			ri == 2 and Color3.fromRGB(70, 110, 60)
			or (ri == 3 and Color3.fromRGB(46, 70, 110) or (pal.vazio and pal.corpo or cor:Lerp(PRETO, 0.55)))
		)
	peca(m, Vector3.new(2.5, 2.55, 2.5), CFrame.new(0, 0.12, 0.35), pano, MAT.Fabric, Enum.PartType.Ball).Name =
		"Nucleo"
	cunha(
		m,
		Vector3.new(0.6, 0.9, 1.1),
		CFrame.new(0, 0.95, 1.25) * CFrame.Angles(math.rad(-30), 0, 0),
		pano,
		MAT.Fabric
	)
	-- borda do capuz em volta do rosto
	cilindro(
		m,
		0.18,
		2.3,
		CFrame.new(0, 0.1, -0.55) * CFrame.Angles(0, math.rad(90), 0),
		ri >= 4 and pal.fio or (ri == 3 and ACO or pano:Lerp(BRANCO, 0.15)),
		ri >= 4 and MAT.Neon or MAT.Fabric
	)
	-- sombra do rosto (só no ícone; ao vestir, o rosto do herói aparece)
	peca(
		m,
		Vector3.new(1.75, 1.95, 0.6),
		CFrame.new(0, 0.05, -0.55),
		Color3.fromRGB(16, 14, 20),
		MAT.SmoothPlastic,
		Enum.PartType.Ball
	).Name =
		"SombraRosto"
	for _, lado in ipairs({ -1, 1 }) do
		peca(
			m,
			Vector3.new(0.34, 0.14, 0.1),
			CFrame.new(0.32 * lado, 0.12, -0.86) * CFrame.Angles(0, 0, math.rad(-12 * lado)),
			ri >= 3 and (pal.gema or BRANCO) or Color3.fromRGB(255, 240, 200),
			MAT.Neon
		).Name =
			"SombraRosto"
	end
	if ri >= 3 then
		-- lenço cobrindo a boca
		peca(m, Vector3.new(1.7, 0.55, 0.3), CFrame.new(0, -0.62, -0.95), pano:Lerp(PRETO, 0.35), MAT.Fabric)
		peca(m, Vector3.new(1.72, 0.1, 0.32), CFrame.new(0, -0.38, -0.96), pal.fio, ri >= 4 and MAT.Neon or MAT.Metal)
	end
	if ri >= 5 then
		-- penas grandes e gema na testa
		for k = 0, ri >= 7 and 2 or 1 do
			cunha(
				m,
				Vector3.new(0.1, 1.3 - k * 0.2, 0.5),
				CFrame.new(1.05, 0.9 + k * 0.2, 0.6 + k * 0.25) * CFrame.Angles(0, math.pi / 2, math.rad(-25 - k * 10)),
				pal.vazio and BRANCO or (k == 1 and pal.detalhe or pal.fio),
				MAT.Neon
			)
		end
		bola(m, 0.4, CFrame.new(0, 0.95, -1.0), pal.gema, MAT.Neon)
	end
	if pal.cristal then
		coroaEspinhos(m, CFrame.new(0, 1.2, 0.3), 0.6, 0.6, 5, pal.detalhe, MAT.Neon)
	end
	if pal.chama then
		chamas(m, CFrame.new(0, 1.2, 0.9), 0.9, 4)
	end
end

local function couro(m, ri, cor)
	local pal = paleta(ri, cor)
	local corCouro = ri == 1 and Color3.fromRGB(130, 96, 62)
		or (
			ri == 2 and Color3.fromRGB(84, 120, 66)
			or (ri == 3 and Color3.fromRGB(60, 80, 110) or (pal.vazio and pal.corpo or cor:Lerp(PRETO, 0.6)))
		)
	peca(m, Vector3.new(2.4, 2.6, 1.2), CFrame.new(0, 0, 0), corCouro, MAT.Fabric).Name = "Nucleo"
	peca(m, Vector3.new(2.5, 0.45, 1.3), CFrame.new(0, 1.2, 0), corCouro:Lerp(PRETO, 0.3), MAT.Fabric)
	-- alça diagonal com fivela
	peca(
		m,
		Vector3.new(0.4, 3.2, 0.12),
		CFrame.new(0, 0.1, -0.64) * CFrame.Angles(0, 0, math.rad(40)),
		ri >= 5 and OURO or COURO,
		ri >= 5 and MAT.Metal or MAT.Fabric
	)
	bola(m, 0.45, CFrame.new(-0.25, -0.15, -0.72), pal.gema or OURO, pal.gema and MAT.Neon or MAT.Metal)
	-- cinto
	peca(
		m,
		Vector3.new(2.45, 0.28, 1.25),
		CFrame.new(0, -0.9, 0),
		ri >= 4 and pal.fio or COURO:Lerp(PRETO, 0.3),
		ri >= 4 and MAT.Neon or MAT.Fabric
	)
	-- aljava nas costas com flechas
	local aljava = CFrame.new(0.55, 0.35, 0.95) * CFrame.Angles(0, 0, math.rad(-20))
	cilindro(
		m,
		2.1,
		0.75,
		aljava * CFrame.Angles(0, 0, math.rad(90)),
		ri >= 5 and OURO or COURO,
		ri >= 5 and MAT.Metal or MAT.Fabric
	)
	cilindro(m, 0.16, 0.8, aljava * CFrame.new(0, 0.55, 0) * CFrame.Angles(0, 0, math.rad(90)), pal.fio, pal.matFio)
	for i = -1, 1 do
		peca(m, Vector3.new(0.06, 0.9, 0.06), aljava * CFrame.new(i * 0.18, 1.4, 0), Color3.fromRGB(150, 110, 70))
		cunha(
			m,
			Vector3.new(0.05, 0.35, 0.22),
			aljava * CFrame.new(i * 0.18, 1.78, 0),
			ri >= 4 and pal.fio or Color3.fromRGB(235, 230, 215),
			ri >= 4 and MAT.Neon or MAT.Fabric
		)
	end
	-- ombreira só de um lado (mais ágil), cresce com o tier
	local t = 0.6 + ri * 0.08
	peca(
		m,
		Vector3.new(1.17 * t, 0.6 * t, 1.3 * t),
		CFrame.new(-1.45, 1, 0),
		ri >= 5 and OURO or corCouro:Lerp(PRETO, 0.2),
		ri >= 5 and MAT.Metal or MAT.Fabric
	)
	if ri >= 3 then
		peca(m, Vector3.new(1.24 * t, 0.12, 1.35 * t), CFrame.new(-1.45, 1 + 0.3 * t, 0), pal.fio, pal.matFio)
	end
	if ri >= 4 then
		cunha(
			m,
			Vector3.new(0.12, 0.7 + ri * 0.06, 0.4),
			CFrame.new(-1.6, 1.5, 0) * CFrame.Angles(0, math.pi / 2, math.rad(20)),
			pal.vazio and pal.corpo or pal.fio,
			pal.vazio and MAT.SmoothPlastic or MAT.Neon
		)
	end
	if pal.chama then
		chamas(m, CFrame.new(-1.45, 1.3, 0), 0.8, 3)
	end
end

------------------------------------------------------------------------
-- Mago: chapéu e túnica
------------------------------------------------------------------------
local function chapeuMago(m, ri, cor)
	local pal = paleta(ri, cor)
	local pano = ri == 1 and Color3.fromRGB(120, 90, 60)
		or (
			ri == 2 and PANO
			or (ri == 3 and Color3.fromRGB(46, 70, 140) or (pal.vazio and pal.corpo or cor:Lerp(PRETO, 0.5)))
		)
	local aba = 3.3 + ri * 0.12
	cilindro(m, 0.16, aba, CFrame.Angles(0, 0, math.rad(90)), pano, MAT.Fabric).Name = "Nucleo"
	if ri >= 3 then
		-- aro na borda da aba
		anel(
			m,
			CFrame.new(0, 0.04, 0),
			aba / 2,
			0.14,
			ri >= 4 and pal.fio or OURO,
			ri >= 4 and MAT.Neon or MAT.Metal,
			24
		)
	end
	-- cone que entorta na ponta (mais alto nos tiers altos)
	local n = 7 + math.floor(ri / 2)
	for i = 0, n do
		cilindro(
			m,
			0.34,
			1.75 - i * (1.6 / n),
			CFrame.new(0.018 * i * i, 0.22 + i * 0.3, 0.008 * i * i) * CFrame.Angles(0, 0, math.rad(90 - i * 3)),
			pano:Lerp(PRETO, i / (n * 3)),
			MAT.Fabric
		)
	end
	local pontaChapeu = CFrame.new(0.018 * n * n, 0.42 + n * 0.3, 0.008 * n * n)
	-- faixa
	cilindro(
		m,
		0.3,
		1.84,
		CFrame.new(0, 0.32, 0) * CFrame.Angles(0, 0, math.rad(90)),
		ri >= 4 and pal.fio or (ri >= 3 and ACO or OURO),
		ri >= 4 and MAT.Neon or MAT.Metal
	)
	if ri >= 3 then
		bola(m, 0.45 + ri * 0.02, CFrame.new(0, 0.36, -0.92), pal.gema, MAT.Neon)
	end
	if ri >= 4 then
		-- estrela/orbe flutuando na ponta
		animar(bola(m, 0.35 + ri * 0.03, pontaChapeu, pal.fio, MAT.Neon), pontaChapeu, Vector3.yAxis, 0, 0.1)
	end
	if ri >= 5 then
		-- anel de runas girando em volta do chapéu
		anel(m, CFrame.new(0, 1.0, 0), 1.35, 0.1, pal.detalhe, MAT.Neon, 18, 1.8)
	end
	if pal.cristal then
		coroaEspinhos(m, CFrame.new(0, 0.4, 0), 0.95, 0.55, 6, pal.detalhe, MAT.Neon)
	end
	if pal.chama then
		chamas(m, pontaChapeu, 0.8, 4)
	end
	if pal.vazio then
		cilindro(
			m,
			0.17,
			3.3 + ri * 0.08,
			CFrame.new(0, -0.02, 0) * CFrame.Angles(0, 0, math.rad(90)),
			BRANCO,
			MAT.Neon
		).Transparency =
			0.5
	end
end

local function tunica(m, ri, cor)
	local pal = paleta(ri, cor)
	local pano = ri == 1 and Color3.fromRGB(130, 104, 76)
		or (
			ri == 2 and PANO
			or (ri == 3 and Color3.fromRGB(46, 70, 140) or (pal.vazio and pal.corpo or cor:Lerp(PRETO, 0.6)))
		)
	peca(m, Vector3.new(2.4, 2.6, 1.2), CFrame.new(0, 0, 0), pano, MAT.Fabric).Name = "Nucleo"
	peca(m, Vector3.new(2.55, 1.1, 1.35), CFrame.new(0, -1.6, 0), pano:Lerp(PRETO, 0.15), MAT.Fabric)
	-- gola alta e ombros
	for _, lado in ipairs({ -1, 1 }) do
		cunha(
			m,
			Vector3.new(0.2, 0.8 + ri * 0.08, 0.5),
			CFrame.new(0.55 * lado, 1.5, 0.2) * CFrame.Angles(0, 0, math.rad(-10 * lado)),
			ri >= 5 and pal.fio or pano:Lerp(PRETO, 0.3),
			ri >= 5 and MAT.Neon or MAT.Fabric
		)
		peca(
			m,
			Vector3.new(0.8 + ri * 0.05, 0.55, 1.25),
			CFrame.new((1.45 + ri * 0.02) * lado, 1, 0),
			ri >= 5 and (pal.vazio and pal.corpo or OURO) or pano:Lerp(PRETO, 0.2),
			ri >= 5 and MAT.Metal or MAT.Fabric
		)
	end
	-- faixas
	local enfeite = ri >= 4 and pal.fio or OURO
	local matEnfeite = ri >= 4 and MAT.Neon or MAT.Metal
	peca(
		m,
		Vector3.new(0.32, 3.7, 0.08),
		CFrame.new(0, -0.5, -0.66),
		ri >= 3 and enfeite or pano:Lerp(BRANCO, 0.3),
		matEnfeite
	)
	peca(
		m,
		Vector3.new(2.45, 0.3, 1.27),
		CFrame.new(0, -0.75, 0),
		ri >= 2 and cor or COURO,
		ri >= 6 and MAT.Neon or MAT.Fabric
	)
	if ri >= 3 then
		bola(m, 0.55, CFrame.new(0, -0.75, -0.7), pal.gema, MAT.Neon)
	end
	if ri >= 4 then
		-- livro de magia preso no cinto
		peca(
			m,
			Vector3.new(0.55, 0.7, 0.2),
			CFrame.new(0.9, -1.05, -0.62) * CFrame.Angles(0, 0, math.rad(10)),
			Color3.fromRGB(110, 40, 40),
			MAT.Fabric
		)
		peca(m, Vector3.new(0.2, 0.2, 0.22), CFrame.new(0.9, -1.05, -0.64), pal.fio, MAT.Neon)
	end
	if pal.runas then
		-- runas flutuando em volta da túnica
		for i = 1, 4 do
			local a = (i / 4) * math.pi * 2
			animar(
				peca(
					m,
					Vector3.new(0.28, 0.28, 0.08),
					CFrame.new(math.cos(a) * 1.9, 0.2, math.sin(a) * 1.2) * CFrame.Angles(0, 0, math.rad(45)),
					pal.detalhe,
					MAT.Neon
				),
				CFrame.new(0, 0.2, 0),
				Vector3.yAxis,
				1.2
			)
		end
	end
	if pal.cristal then
		coroaEspinhos(m, CFrame.new(0, 1.3, 0), 1.2, 0.6, 6, pal.detalhe, MAT.Neon)
	end
	-- saia da túnica abrindo em A (do Incomum para cima)
	if ri >= 2 then
		local saia = pano:Lerp(PRETO, 0.12)
		for _, lado in ipairs({ -1, 1 }) do
			peca(
				m,
				Vector3.new(2.5, 1.9, 0.16),
				CFrame.new(0, -2.7, 0.66 * lado) * CFrame.Angles(math.rad(-12 * lado), 0, 0),
				saia,
				MAT.Fabric
			)
			peca(
				m,
				Vector3.new(0.16, 1.9, 1.3),
				CFrame.new(1.3 * lado, -2.7, 0) * CFrame.Angles(0, 0, math.rad(12 * lado)),
				saia,
				MAT.Fabric
			)
			-- barra brilhante na ponta da saia
			peca(
				m,
				Vector3.new(2.75, 0.2, 0.22),
				CFrame.new(0, -3.6, 0.86 * lado) * CFrame.Angles(math.rad(-12 * lado), 0, 0),
				enfeite,
				matEnfeite
			)
			peca(
				m,
				Vector3.new(0.22, 0.2, 1.6),
				CFrame.new(1.5 * lado, -3.6, 0) * CFrame.Angles(0, 0, math.rad(12 * lado)),
				enfeite,
				matEnfeite
			)
		end
	end
	-- capa de mago nas costas (do Épico para cima), com bordas de luz no Lendário+
	if ri >= 4 then
		local corCapa = pal.vazio and PRETO or cor:Lerp(PRETO, 0.35)
		local capa = CFrame.new(0, -0.9, 0.78) * CFrame.Angles(math.rad(-7), 0, 0)
		peca(m, Vector3.new(2.5, 4.4, 0.12), capa, corCapa, MAT.Fabric)
		peca(m, Vector3.new(2.3, 4.2, 0.06), capa * CFrame.new(0, 0, -0.08), pal.detalhe:Lerp(PRETO, 0.5), MAT.Fabric)
		if ri >= 5 then
			for _, lado in ipairs({ -1, 1 }) do
				peca(m, Vector3.new(0.14, 4.4, 0.16), capa * CFrame.new(1.25 * lado, 0, 0.02), pal.fio, MAT.Neon)
			end
			peca(m, Vector3.new(2.64, 0.16, 0.16), capa * CFrame.new(0, -2.2, 0.02), pal.fio, MAT.Neon)
		end
		-- gola alta abrindo para fora
		for _, lado in ipairs({ -1, 1 }) do
			cunha(
				m,
				Vector3.new(0.14, 1.1 + ri * 0.08, 1.1),
				CFrame.new(0.85 * lado, 1.85, 0.42) * CFrame.Angles(math.rad(-12), 0, math.rad(-24 * lado)),
				corCapa,
				MAT.Fabric
			)
		end
	end
	-- selo mágico girando nas costas (Mítico para cima)
	if ri >= 6 then
		local selo = CFrame.new(0, -0.3, 0.95) * CFrame.Angles(math.rad(90), 0, 0)
		anel(m, selo, 0.85, 0.12, pal.fio, MAT.Neon, 16, 1.6)
		anel(m, selo, 0.5, 0.1, pal.detalhe, MAT.Neon, 10, -2.4)
		animar(bola(m, 0.4, selo, pal.gema, MAT.Neon), selo, Vector3.yAxis, 0, 0.08)
	end
	if pal.vazio then
		peca(m, Vector3.new(2.6, 0.08, 1.4), CFrame.new(0, -2.1, 0), BRANCO, MAT.Neon)
	end
end

------------------------------------------------------------------------
-- Peças novas: arma secundária (escudo, aljava, grimório), luvas, calça e acessórios
------------------------------------------------------------------------

-- gema lapidada: casca de vidro girada (facetas) com miolo de luz
local function joiaFacetada(m, cf, tam, cor)
	local casca = peca(
		m,
		Vector3.new(tam, tam, tam) * 0.72,
		cf * CFrame.Angles(math.rad(45), math.rad(35), math.rad(45)),
		cor:Lerp(BRANCO, 0.3),
		MAT.Glass
	)
	casca.Transparency = 0.2
	return bola(m, tam * 0.62, cf, cor, MAT.Neon)
end

local function metalTier(ri, pal)
	if ri <= 1 then
		return FERRO, MAT.Metal
	elseif ri == 2 then
		return ACO, MAT.Metal
	elseif pal.vazio then
		return pal.corpo, MAT.SmoothPlastic
	elseif ri >= 5 and not pal.cristal and ri ~= 7 then
		return OURO, MAT.Metal
	end
	return pal.corpo, pal.matCorpo
end

-- enfeites que todo item ganha conforme o tier (anel de luz, cristais, chamas, auréola)
local function enfeitesTier(m, ri, pal, centro, raio)
	local antes = #m:GetChildren()
	if ri >= 4 then
		anel(m, centro * CFrame.Angles(math.rad(72), 0, 0), raio * 1.3, 0.08, pal.fio, MAT.Neon, 16, 1.4)
	end
	if pal.cristal or pal.vazio then
		for i = 1, 3 do
			local a = (i / 3) * math.pi * 2
			animar(
				cunha(
					m,
					Vector3.new(0.1, raio * 0.6, raio * 0.25),
					centro * CFrame.new(math.cos(a) * raio * 1.55, 0, math.sin(a) * raio * 1.55),
					pal.vazio and BRANCO or pal.detalhe,
					MAT.Neon
				),
				centro,
				Vector3.yAxis,
				-1.3
			)
		end
	end
	if pal.chama then
		chamas(m, centro * CFrame.new(0, raio * 0.7, 0), raio * 0.7, 3)
	end
	if pal.sagrado then
		-- auréola dourada flutuando por cima
		anel(m, centro * CFrame.new(0, raio * 1.5, 0), raio * 0.6, 0.09, pal.fio, MAT.Neon, 14, 0.8)
	end
	if pal.vazio then
		coroaEspinhos(m, centro, raio * 0.9, raio * 0.5, 6, BRANCO, MAT.Neon)
	end
	-- marca os enfeites: no corpo os acessórios pequenos ficam sem eles (senão vira bagunça)
	for i, p in ipairs(m:GetChildren()) do
		if i > antes then
			p:SetAttribute("Enfeite", true)
		end
	end
end

-- Guerreiro: escudo
local function escudo(m, ri, cor)
	local pal = paleta(ri, cor)
	if ri == 1 then
		-- broquel redondo de madeira com aro de ferro
		cilindro(m, 0.3, 2.8, CFrame.Angles(0, math.rad(90), 0), MADEIRA, MAT.Wood).Name = "Nucleo"
		anel(m, CFrame.Angles(math.rad(90), 0, 0), 1.4, 0.2, FERRO, MAT.Metal, 20)
		bola(m, 0.75, CFrame.new(0, 0, -0.2), FERRO, MAT.Metal)
		return
	end
	local metal, matMetal = metalTier(ri, pal)
	local corpo = pal.vazio and pal.corpo or (ri == 2 and Color3.fromRGB(70, 110, 170) or cor:Lerp(PRETO, 0.35))
	local matCorpo = pal.cristal and MAT.Glass or (pal.vazio and MAT.SmoothPlastic or MAT.Metal)
	local larg = 2.5 + ri * 0.08
	peca(m, Vector3.new(larg, 2.2, 0.3), CFrame.new(0, 0.4, 0), corpo, matCorpo).Name = "Nucleo"
	ponta(m, CFrame.new(0, -1.3, 0) * CFrame.Angles(0, 0, math.pi), larg, 1.8, 0.3, corpo, matCorpo)
	-- aro
	local aro, matAro = ri >= 4 and pal.fio or metal, ri >= 4 and MAT.Neon or matMetal
	for _, lado in ipairs({ -1, 1 }) do
		peca(m, Vector3.new(0.22, 2.3, 0.42), CFrame.new(larg / 2 * lado, 0.4, 0), aro, matAro)
		ligar(m, CFrame.new(), Vector3.new(larg / 2 * lado, -0.72, 0), Vector3.new(0, -2.2, 0), 0.22, aro, matAro, 0.42)
	end
	peca(m, Vector3.new(larg + 0.2, 0.24, 0.42), CFrame.new(0, 1.5, 0), aro, matAro)
	-- cruz e gema no meio
	peca(m, Vector3.new(0.3, 2.9, 0.12), CFrame.new(0, -0.15, -0.2), metal, matMetal)
	peca(m, Vector3.new(larg - 0.4, 0.3, 0.12), CFrame.new(0, 0.55, -0.2), metal, matMetal)
	joiaFacetada(m, CFrame.new(0, 0.55, -0.35), 0.6 + ri * 0.06, pal.gema or cor)
	if ri >= 3 then
		for _, x in ipairs({ -0.8, 0.8 }) do
			for _, y in ipairs({ 1.1, -0.1 }) do
				bola(m, 0.24, CFrame.new(x, y, -0.2), metal, matMetal)
			end
		end
	end
	if ri >= 4 then
		-- pontas nos cantos de cima
		for _, lado in ipairs({ -1, 1 }) do
			ponta(
				m,
				CFrame.new((larg / 2 + 0.1) * lado, 1.75, 0) * CFrame.Angles(0, 0, math.rad(-35 * lado)),
				0.4,
				0.9 + ri * 0.06,
				0.2,
				pal.detalhe,
				pal.matDetalhe
			)
		end
	end
	if ri >= 5 then
		-- asas dos lados
		for _, lado in ipairs({ -1, 1 }) do
			for k = 1, 3 do
				cunha(
					m,
					Vector3.new(0.12, 0.5 + k * 0.35, 0.7),
					CFrame.new((larg / 2 + 0.25 + k * 0.28) * lado, 0.9 - k * 0.25, 0.05)
						* CFrame.Angles(0, math.rad(90 * lado), math.rad(-(30 + k * 12) * lado)),
					k == 2 and pal.detalhe or pal.fio,
					MAT.Neon
				)
			end
		end
	end
	if pal.runas then
		for i = 1, 3 do
			peca(
				m,
				Vector3.new(0.2, 0.2, 0.1),
				CFrame.new(0, -0.6 - i * 0.35, -0.24) * CFrame.Angles(0, 0, math.rad(45)),
				pal.detalhe,
				MAT.Neon
			)
		end
	end
	if pal.sagrado then
		anel(m, CFrame.new(0, 0.4, 0.35) * CFrame.Angles(math.rad(90), 0, 0), 1.9, 0.12, pal.fio, MAT.Neon, 24, 0.6)
	end
	enfeitesTier(m, ri, pal, CFrame.new(0, 0.3, 0), 1.2)
end

-- Caçador: aljava com flechas
local function aljava(m, ri, cor)
	local pal = paleta(ri, cor)
	local base = CFrame.Angles(0, 0, math.rad(-18))
	local metal, matMetal = metalTier(ri, pal)
	local corTubo = ri <= 2 and COURO or (pal.vazio and pal.corpo or cor:Lerp(PRETO, 0.45))
	cilindro(m, 2.8, 0.95, base * CFrame.Angles(0, 0, math.rad(90)), corTubo, ri <= 2 and MAT.Fabric or MAT.Metal).Name =
		"Nucleo"
	bola(m, 0.95, base * CFrame.new(0, -1.4, 0), metal, matMetal)
	for _, y in ipairs({ -1.0, 0.1, 1.2 }) do
		cilindro(
			m,
			0.18,
			1.04,
			base * CFrame.new(0, y, 0) * CFrame.Angles(0, 0, math.rad(90)),
			ri >= 4 and pal.fio or metal,
			ri >= 4 and MAT.Neon or matMetal
		)
	end
	-- alça
	ligar(m, base, Vector3.new(0.55, -1.0, 0), Vector3.new(0.55, 1.2, 0), 0.14, COURO:Lerp(PRETO, 0.3), MAT.Fabric)
	-- flechas saindo da boca
	local n = 3 + math.min(ri, 4)
	for i = 1, n do
		local a = (i / n) * math.pi * 2
		local boca = base * CFrame.new(math.cos(a) * 0.24, 1.3, math.sin(a) * 0.24)
		peca(m, Vector3.new(0.08, 1.2, 0.08), boca * CFrame.new(0, 0.5, 0), MADEIRA, MAT.Wood)
		local corPena = i % 2 == 0 and cor or (ri >= 3 and pal.fio or BRANCO)
		for _, giro in ipairs({ 0, math.pi / 2 }) do
			cunha(
				m,
				Vector3.new(0.04, 0.5, 0.26),
				boca * CFrame.new(0, 1.0, 0) * CFrame.Angles(0, a + giro, 0),
				corPena,
				ri >= 5 and MAT.Neon or MAT.Fabric
			)
		end
	end
	if ri >= 3 then
		joiaFacetada(m, base * CFrame.new(0, 0.6, -0.5), 0.45 + ri * 0.04, pal.gema or cor)
	end
	if ri >= 5 then
		-- penas grandes enfeitando a lateral
		for k = 1, 2 do
			cunha(
				m,
				Vector3.new(0.08, 1.0 + k * 0.3, 0.45),
				base * CFrame.new(-0.55, 0.2 - k * 0.4, 0) * CFrame.Angles(0, -math.pi / 2, math.rad(20 + k * 15)),
				k == 1 and pal.detalhe or pal.fio,
				MAT.Neon
			)
		end
	end
	enfeitesTier(m, ri, pal, base * CFrame.new(0, 0.2, 0), 0.9)
end

-- Mago: grimório
local function grimorio(m, ri, cor)
	local pal = paleta(ri, cor)
	local base = CFrame.Angles(math.rad(-12), math.rad(25), 0)
	local metal, matMetal = metalTier(ri, pal)
	local capa = ri == 1 and Color3.fromRGB(110, 70, 40)
		or (pal.vazio and pal.corpo or (ri == 2 and PANO or cor:Lerp(PRETO, 0.45)))
	peca(m, Vector3.new(2, 2.5, 0.5), base, Color3.fromRGB(245, 235, 210), MAT.SmoothPlastic)
	peca(m, Vector3.new(2.2, 2.7, 0.14), base * CFrame.new(0.05, 0, -0.31), capa, MAT.Fabric).Name = "Nucleo"
	peca(m, Vector3.new(2.2, 2.7, 0.14), base * CFrame.new(0.05, 0, 0.31), capa, MAT.Fabric)
	peca(m, Vector3.new(0.22, 2.7, 0.76), base * CFrame.new(-1.08, 0, 0), capa:Lerp(PRETO, 0.3), MAT.Fabric)
	if ri >= 2 then
		for _, x in ipairs({ -0.92, 0.98 }) do
			for _, y in ipairs({ -1.18, 1.18 }) do
				peca(m, Vector3.new(0.36, 0.36, 0.8), base * CFrame.new(x, y, 0), metal, matMetal)
			end
		end
	end
	if ri >= 4 then
		-- páginas brilhando
		peca(m, Vector3.new(0.06, 2.3, 0.42), base * CFrame.new(1.02, 0, 0), pal.fio, MAT.Neon)
	end
	-- emblema na capa
	anel(
		m,
		base * CFrame.new(0.05, 0, -0.42) * CFrame.Angles(math.rad(90), 0, 0),
		0.62,
		0.09,
		ri >= 4 and pal.fio or metal,
		ri >= 4 and MAT.Neon or matMetal,
		14
	)
	joiaFacetada(
		m,
		base * CFrame.new(0.05, 0, -0.48),
		0.5 + ri * 0.06,
		ri == 1 and Color3.fromRGB(200, 160, 90) or (pal.gema or cor)
	)
	if ri >= 5 then
		-- runas girando em volta do livro
		anel(m, base, 1.85, 0.1, pal.detalhe, MAT.Neon, 10, 1.2)
	end
	if ri >= 6 then
		local topo = base * CFrame.new(0, 2.0, 0)
		animar(bola(m, 0.55, topo, pal.gema or cor, MAT.Neon), topo, Vector3.yAxis, 0, 0.15)
	end
	enfeitesTier(m, ri, pal, base, 1.2)
end

-- Luvas (par): a da direita fica em +X
local function luvas(m, ri, cor)
	local pal = paleta(ri, cor)
	local metal, matMetal = metalTier(ri, pal)
	local corLuva = ri <= 1 and COURO or (pal.vazio and pal.corpo or (ri == 2 and ACO or cor:Lerp(PRETO, 0.4)))
	local matLuva = ri <= 1 and MAT.Fabric or (pal.cristal and MAT.Glass or MAT.Metal)
	for _, lado in ipairs({ -1, 1 }) do
		local x = 0.95 * lado
		local mao = peca(m, Vector3.new(0.85, 0.8, 0.62), CFrame.new(x, 0, 0), corLuva, matLuva)
		if lado == 1 then
			mao.Name = "Nucleo"
		end
		for f = 0, 3 do
			peca(m, Vector3.new(0.18, 0.42, 0.5), CFrame.new(x - 0.3 + f * 0.2, -0.56, -0.02), corLuva, matLuva)
		end
		-- punho largo
		peca(
			m,
			Vector3.new(1.05 + ri * 0.03, 0.55 + ri * 0.05, 0.82),
			CFrame.new(x, 0.62, 0),
			ri <= 2 and COURO:Lerp(PRETO, 0.2) or metal,
			ri <= 2 and MAT.Fabric or matMetal
		)
		peca(
			m,
			Vector3.new(1.1 + ri * 0.03, 0.1, 0.86),
			CFrame.new(x, 0.62 + (0.55 + ri * 0.05) / 2, 0),
			ri >= 4 and pal.fio or metal,
			ri >= 4 and MAT.Neon or matMetal
		)
		if ri >= 2 then
			peca(m, Vector3.new(0.7, 0.6, 0.12), CFrame.new(x, 0.02, -0.36), metal, matMetal)
		end
		if ri >= 3 then
			joiaFacetada(m, CFrame.new(x, 0.05, -0.46), 0.32 + ri * 0.02, pal.gema or cor)
		end
		if ri >= 4 then
			-- espinhos nos nós dos dedos
			for k = -1, 1 do
				cunha(
					m,
					Vector3.new(0.12, 0.18, 0.35 + ri * 0.03),
					CFrame.new(x + k * 0.25, -0.3, -0.48) * CFrame.Angles(math.rad(90), 0, 0),
					pal.detalhe,
					pal.matDetalhe
				)
			end
		end
		if ri >= 5 then
			-- aleta no punho
			cunha(
				m,
				Vector3.new(0.1, 0.7 + ri * 0.06, 0.6),
				CFrame.new(x + 0.55 * lado, 0.9, 0.1) * CFrame.Angles(0, math.rad(90 * lado), math.rad(-15 * lado)),
				pal.fio,
				MAT.Neon
			)
		end
		if pal.chama then
			chamas(m, CFrame.new(x, 1.0, 0), 0.5, 2)
		end
		if pal.vazio then
			peca(m, Vector3.new(0.05, 0.7, 0.05), CFrame.new(x + 0.2, 0, -0.33), BRANCO, MAT.Neon)
		end
	end
	if pal.cristal or pal.sagrado then
		enfeitesTier(m, ri, pal, CFrame.new(0, 0.3, 0), 1.1)
	end
end

-- Calça (par de pernas): coxa em cima (Y > 0) e canela embaixo
local function calca(m, ri, cor)
	local pal = paleta(ri, cor)
	local metal, matMetal = metalTier(ri, pal)
	local pano = ri == 1 and Color3.fromRGB(120, 96, 70)
		or (ri == 2 and PANO or (pal.vazio and pal.corpo or cor:Lerp(PRETO, 0.55)))
	for _, lado in ipairs({ -1, 1 }) do
		local x = 0.55 * lado
		local coxa = peca(m, Vector3.new(1.02, 1.3, 1.02), CFrame.new(x, 0.62, 0), pano, MAT.Fabric)
		if lado == 1 then
			coxa.Name = "Nucleo"
		end
		peca(m, Vector3.new(0.98, 1.3, 0.98), CFrame.new(x, -0.72, 0), pano:Lerp(PRETO, 0.12), MAT.Fabric)
		-- barra na canela
		peca(
			m,
			Vector3.new(1.04, 0.16, 1.04),
			CFrame.new(x, -1.3, 0),
			ri >= 4 and pal.fio or metal,
			ri >= 4 and MAT.Neon or matMetal
		)
		if ri >= 2 then
			-- joelheira
			peca(m, Vector3.new(0.72, 0.5, 0.22), CFrame.new(x, -0.2, -0.55), metal, matMetal)
		end
		if ri >= 3 then
			bola(m, 0.26, CFrame.new(x, -0.2, -0.68), pal.gema or cor, MAT.Neon)
			-- placa da coxa
			peca(
				m,
				Vector3.new(0.86, 0.95, 0.14),
				CFrame.new(x, 0.62, -0.56) * CFrame.Angles(math.rad(-6), 0, 0),
				ri >= 5 and metal or pal.detalhe,
				ri >= 5 and matMetal or pal.matDetalhe
			)
		end
		if ri >= 4 then
			-- faixas de luz dos lados
			peca(m, Vector3.new(0.06, 1.2, 0.3), CFrame.new(x + 0.52 * lado, 0.62, 0), pal.fio, MAT.Neon)
			peca(m, Vector3.new(0.06, 1.2, 0.3), CFrame.new(x + 0.5 * lado, -0.72, 0), pal.fio, MAT.Neon)
		end
		if ri >= 5 then
			-- placa lateral do quadril em leque
			for k = 0, 1 do
				cunha(
					m,
					Vector3.new(0.12, 0.9 - k * 0.2, 0.7),
					CFrame.new(x + (0.62 + k * 0.12) * lado, 0.95 - k * 0.35, 0)
						* CFrame.Angles(0, math.rad(90 * lado), math.rad(-12 * lado)),
					k == 0 and metal or pal.fio,
					k == 0 and matMetal or MAT.Neon
				)
			end
		end
		if pal.chama then
			chamas(m, CFrame.new(x, -0.05, -0.55), 0.45, 2)
		end
		if pal.vazio then
			peca(m, Vector3.new(0.05, 1.0, 0.05), CFrame.new(x - 0.2, -0.7, -0.5), BRANCO, MAT.Neon)
		end
	end
	-- cós com fivela
	peca(
		m,
		Vector3.new(2.16, 0.32, 1.08),
		CFrame.new(0, 1.35, 0),
		ri <= 1 and COURO or metal,
		ri <= 1 and MAT.Fabric or matMetal
	)
	if ri >= 6 then
		enfeitesTier(m, ri, pal, CFrame.new(0, 0.3, 0), 1.2)
	end
end

-- Anel
local function anelItem(m, ri, cor)
	local pal = paleta(ri, cor)
	local metal, matMetal = metalTier(ri, pal)
	anel(m, CFrame.Angles(math.rad(90), 0, 0), 1.0, 0.3, metal, matMetal, 24)
	if ri >= 4 then
		anel(m, CFrame.Angles(math.rad(90), 0, 0), 0.82, 0.1, pal.fio, MAT.Neon, 20)
	end
	peca(m, Vector3.new(0.9, 0.45, 0.6), CFrame.new(0, 1.1, 0), metal, matMetal).Name = "Nucleo"
	local tam = 0.75 + ri * 0.08
	joiaFacetada(m, CFrame.new(0, 1.35 + tam * 0.35, 0), tam, pal.gema or cor)
	if ri >= 3 then
		-- garras segurando a pedra
		for i = 1, 4 do
			local a = (i / 4) * math.pi * 2 + math.pi / 4
			cunha(
				m,
				Vector3.new(0.1, 0.45, 0.16),
				CFrame.new(math.cos(a) * tam * 0.42, 1.45, math.sin(a) * tam * 0.42) * CFrame.Angles(0, -a, 0),
				metal,
				matMetal
			)
		end
	end
	enfeitesTier(m, ri, pal, CFrame.new(0, 0.6, 0), 1.0)
end

-- Brincos (par)
local function brinco(m, ri, cor)
	local pal = paleta(ri, cor)
	local metal, matMetal = metalTier(ri, pal)
	for _, lado in ipairs({ -1, 1 }) do
		local x = 0.75 * lado
		anel(m, CFrame.new(x, 0.75, 0) * CFrame.Angles(math.rad(90), 0, 0), 0.3, 0.1, metal, matMetal, 12)
		local fio = ligar(m, CFrame.new(), Vector3.new(x, 0.45, 0), Vector3.new(x, -0.2, 0), 0.08, metal, matMetal)
		if lado == 1 then
			fio.Name = "Nucleo"
		end
		local tam = 0.5 + ri * 0.05
		joiaFacetada(m, CFrame.new(x, -0.2 - tam * 0.5, 0), tam, pal.gema or cor)
		if ri >= 4 then
			ponta(m, CFrame.new(x, -0.55 - tam, 0) * CFrame.Angles(0, 0, math.pi), 0.3, 0.6, 0.1, pal.fio, MAT.Neon)
		end
		if ri >= 6 then
			bola(m, 0.25, CFrame.new(x, 0.15, 0), pal.detalhe, MAT.Neon)
		end
	end
	if ri >= 5 then
		enfeitesTier(m, ri, pal, CFrame.new(0, 0, 0), 0.9)
	end
end

-- Colar: contas em U e um pingente grande
local function colar(m, ri, cor)
	local pal = paleta(ri, cor)
	local metal, matMetal = metalTier(ri, pal)
	local n = 12
	for i = 0, n do
		local a = math.rad(-80 + i * 160 / n)
		local pos = CFrame.new(math.sin(a) * 1.15, 0.95 - math.cos(a) * 0.95, 0)
		if i % 3 == 0 and ri >= 3 then
			bola(m, 0.26, pos, pal.gema or cor, MAT.Neon)
		else
			bola(m, 0.2, pos, metal, matMetal)
		end
	end
	local tam = 0.75 + ri * 0.07
	local centro = CFrame.new(0, -0.35 - tam * 0.3, 0)
	joiaFacetada(m, centro, tam, pal.gema or cor).Name = "Nucleo"
	anel(
		m,
		centro * CFrame.Angles(math.rad(90), 0, 0),
		tam * 0.62,
		0.1,
		ri >= 4 and pal.fio or metal,
		ri >= 4 and MAT.Neon or matMetal,
		14
	)
	if ri >= 4 then
		for _, lado in ipairs({ -1, 1 }) do
			cunha(
				m,
				Vector3.new(0.1, 0.6 + ri * 0.05, 0.5),
				centro
					* CFrame.new(tam * 0.75 * lado, 0.2, 0)
					* CFrame.Angles(0, math.rad(90 * lado), math.rad(-30 * lado)),
				pal.detalhe,
				pal.matDetalhe
			)
		end
	end
	if ri >= 5 then
		ponta(
			m,
			centro * CFrame.new(0, -tam * 0.85, 0) * CFrame.Angles(0, 0, math.pi),
			0.35,
			0.7,
			0.1,
			pal.fio,
			MAT.Neon
		)
	end
	enfeitesTier(m, ri, pal, centro, tam)
end

-- Bracelete
local function bracelete(m, ri, cor)
	local pal = paleta(ri, cor)
	local metal, matMetal = metalTier(ri, pal)
	anel(m, CFrame.new(), 0.78, 0.38, metal, matMetal, 22)
	local nucleo = peca(m, Vector3.new(0.5, 0.5, 0.3), CFrame.new(0, 0, -0.85), metal, matMetal)
	nucleo.Name = "Nucleo"
	if ri >= 4 then
		anel(m, CFrame.new(0, 0.2, 0), 0.82, 0.08, pal.fio, MAT.Neon, 20)
		anel(m, CFrame.new(0, -0.2, 0), 0.82, 0.08, pal.fio, MAT.Neon, 20)
	end
	local nGemas = ri >= 3 and 4 or 1
	for i = 1, nGemas do
		local a = (i / nGemas) * math.pi * 2 + math.pi / 2
		joiaFacetada(
			m,
			CFrame.new(math.cos(a) * 0.98, 0, math.sin(a) * 0.98),
			i == nGemas and 0.45 + ri * 0.04 or 0.3,
			i == nGemas and (pal.gema or cor) or cor
		)
	end
	enfeitesTier(m, ri, pal, CFrame.new(), 0.9)
end

-- Cinto com fivela
local function cinto(m, ri, cor)
	local pal = paleta(ri, cor)
	local metal, matMetal = metalTier(ri, pal)
	local corCinto = ri <= 2 and COURO or (pal.vazio and pal.corpo or cor:Lerp(PRETO, 0.5))
	peca(m, Vector3.new(2.3, 0.42, 0.14), CFrame.new(0, 0, -0.62), corCinto, MAT.Fabric)
	peca(m, Vector3.new(2.3, 0.42, 0.14), CFrame.new(0, 0, 0.62), corCinto, MAT.Fabric)
	for _, lado in ipairs({ -1, 1 }) do
		peca(m, Vector3.new(0.14, 0.42, 1.3), CFrame.new(1.15 * lado, 0, 0), corCinto, MAT.Fabric)
	end
	local fivela =
		peca(m, Vector3.new(0.85 + ri * 0.04, 0.68 + ri * 0.03, 0.16), CFrame.new(0, 0, -0.74), metal, matMetal)
	fivela.Name = "Nucleo"
	joiaFacetada(m, CFrame.new(0, 0, -0.86), 0.4 + ri * 0.04, pal.gema or cor)
	if ri >= 3 then
		-- bolsinhas dos lados
		for _, lado in ipairs({ -1, 1 }) do
			peca(
				m,
				Vector3.new(0.5, 0.55, 0.35),
				CFrame.new(0.8 * lado, -0.2, -0.75),
				corCinto:Lerp(PRETO, 0.2),
				MAT.Fabric
			)
		end
	end
	if ri >= 4 then
		peca(m, Vector3.new(2.32, 0.07, 0.16), CFrame.new(0, 0.2, -0.63), pal.fio, MAT.Neon)
		peca(m, Vector3.new(2.32, 0.07, 0.16), CFrame.new(0, -0.2, -0.63), pal.fio, MAT.Neon)
	end
	if ri >= 5 then
		-- faixa de pano caindo na frente
		peca(
			m,
			Vector3.new(0.55, 1.2, 0.06),
			CFrame.new(0, -0.95, -0.7) * CFrame.Angles(math.rad(-8), 0, 0),
			cor,
			MAT.Fabric
		)
		peca(m, Vector3.new(0.6, 0.1, 0.08), CFrame.new(0, -1.5, -0.78), pal.fio, MAT.Neon)
	end
	enfeitesTier(m, ri, pal, CFrame.new(0, 0, -0.75), 0.6)
end

-- Broche: estrela de raios com uma gema no meio
local function broche(m, ri, cor)
	local pal = paleta(ri, cor)
	local metal, matMetal = metalTier(ri, pal)
	local n = ri >= 5 and 8 or 6
	for i = 1, n do
		local a = (i / n) * math.pi * 2
		ponta(
			m,
			CFrame.Angles(0, 0, a) * CFrame.new(0, 0.7 + ri * 0.03, 0),
			0.42,
			0.85 + ri * 0.06,
			0.12,
			i % 2 == 0 and metal or (ri >= 4 and pal.fio or metal),
			i % 2 == 0 and matMetal or (ri >= 4 and MAT.Neon or matMetal)
		)
	end
	anel(m, CFrame.Angles(math.rad(90), 0, 0), 0.5, 0.12, metal, matMetal, 14)
	joiaFacetada(m, CFrame.new(0, 0, -0.1), 0.6 + ri * 0.05, pal.gema or cor).Name = "Nucleo"
	if ri >= 6 then
		anel(m, CFrame.Angles(math.rad(90), 0, 0), 1.45, 0.08, pal.detalhe, MAT.Neon, 18, 1.2)
	end
	enfeitesTier(m, ri, pal, CFrame.new(), 0.9)
end

local DESENHO_CLASSE = {
	cacador = { arma = arco, armaSec = aljava, elmo = capuz, armadura = couro },
	mago = { arma = cajado, armaSec = grimorio, elmo = chapeuMago, armadura = tunica },
}

local DESENHO = {
	arma = espada,
	armaSec = escudo,
	elmo = elmo,
	armadura = armadura,
	luvas = luvas,
	calca = calca,
	botas = botas,
	anel = anelItem,
	brinco = brinco,
	colar = colar,
	bracelete = bracelete,
	cinto = cinto,
	broche = broche,
	olho = olho,
}

------------------------------------------------------------------------
-- Detalhes dos conjuntos (sets) por cima do desenho normal
------------------------------------------------------------------------
local DETALHE_CONJUNTO = {}

-- Conjunto da Vila Oculta: emblema de folha verde
function DETALHE_CONJUNTO.vila(m, slot)
	local verde = Color3.fromRGB(110, 225, 90)
	local function folha(cf, escala)
		cunha(m, Vector3.new(0.06, 0.45, 0.3) * escala, cf, verde, MAT.Neon)
		cunha(m, Vector3.new(0.06, 0.45, 0.3) * escala, cf * CFrame.Angles(0, math.pi, 0), verde, MAT.Neon)
	end
	if slot == "elmo" then
		folha(CFrame.new(0, 0.1, -1.3) * CFrame.Angles(0, math.pi / 2, 0), 1.6)
	elseif slot == "armadura" then
		folha(CFrame.new(-0.6, 0.6, -0.8) * CFrame.Angles(0, math.pi / 2, 0), 1.6)
		peca(m, Vector3.new(2.52, 0.12, 1.32), CFrame.new(0, -0.55, 0), verde, MAT.Neon)
	elseif slot == "arma" then
		local pomo = m:GetAttribute("Pomo") or (CFrame.Angles(0, 0, math.rad(-45)) * CFrame.new(0, -2.5, 0)).Position
		bola(m, 0.55, CFrame.new(pomo), verde, MAT.Neon)
		folha(CFrame.new(pomo) * CFrame.new(0, 0, -0.3) * CFrame.Angles(0, math.pi / 2, 0), 1.2)
	elseif slot == "botas" then
		for _, lado in ipairs({ -1, 1 }) do
			peca(m, Vector3.new(0.92, 0.1, 0.92), CFrame.new(0.75 * lado, -0.15, 0.15), verde, MAT.Neon)
		end
	end
end

-- Conjunto da Katsuki: preto com nuvens vermelhas e chapéu de palha
function DETALHE_CONJUNTO.katsuki(m, slot)
	local vermelho = Color3.fromRGB(230, 40, 50)
	local function nuvem(cf, escala)
		for _, o in ipairs({ { 0, 0, 0.5 }, { 0.22, 0.05, 0.38 }, { -0.22, 0.03, 0.4 }, { 0.1, 0.16, 0.34 } }) do
			cilindro(
				m,
				0.08 * escala,
				o[3] * escala,
				cf * CFrame.new(0, o[2] * escala, o[1] * escala),
				vermelho,
				MAT.Neon
			)
		end
	end
	if slot == "armadura" then
		for _, p in ipairs(m:GetChildren()) do
			if p:IsA("BasePart") and p.Material ~= MAT.Neon then
				p.Color = Color3.fromRGB(24, 22, 30)
				p.Material = MAT.Fabric
				p.Transparency = 0
			end
		end
		nuvem(CFrame.new(0.5, 0.2, -0.82) * CFrame.Angles(0, math.pi / 2, 0), 1.6)
		nuvem(CFrame.new(-0.6, -0.8, -0.72) * CFrame.Angles(0, math.pi / 2, 0), 1.3)
		nuvem(CFrame.new(1.3, 0.9, -0.5) * CFrame.Angles(0, math.pi / 2, 0), 1)
	elseif slot == "elmo" then
		for _, p in ipairs(m:GetChildren()) do
			p:Destroy()
		end
		-- chapéu de palha cônico com sininho e franjas
		local palha = Color3.fromRGB(205, 168, 100)
		for i = 0, 5 do
			cilindro(
				m,
				0.28,
				3.2 - i * 0.5,
				CFrame.new(0, i * 0.24, 0) * CFrame.Angles(0, 0, math.rad(90)),
				palha:Lerp(Color3.fromRGB(150, 110, 60), i / 8),
				MAT.Fabric
			).Name = i
						== 0
					and "Nucleo"
				or "Palha"
		end
		for i = 1, 8 do
			local a = (i / 8) * math.pi * 2
			peca(
				m,
				Vector3.new(0.06, 0.9, 0.06),
				CFrame.new(math.cos(a) * 1.35, -0.45, math.sin(a) * 1.35),
				Color3.fromRGB(235, 235, 240),
				MAT.Fabric
			)
		end
		bola(m, 0.34, CFrame.new(0, 1.45, 0), vermelho, MAT.Neon)
		cilindro(m, 0.1, 3.25, CFrame.new(0, 0.02, 0) * CFrame.Angles(0, 0, math.rad(90)), vermelho, MAT.Neon)
	elseif slot == "arma" then
		for _, p in ipairs(m:GetChildren()) do
			if p:IsA("BasePart") and p.Material ~= MAT.Neon and p.Material ~= MAT.Fabric then
				p.Color = p.Color:Lerp(Color3.fromRGB(30, 26, 34), 0.65)
			end
		end
		local pomo = m:GetAttribute("Pomo")
		if pomo then
			nuvem(CFrame.new(pomo) * CFrame.new(0, 0, -0.3) * CFrame.Angles(0, math.pi / 2, 0), 1.2)
		end
		peca(
			m,
			Vector3.new(0.06, 2.6, 0.08),
			CFrame.Angles(0, 0, math.rad(-45)) * CFrame.new(0.07, 1.4, -0.1),
			vermelho,
			MAT.Neon
		)
	elseif slot == "botas" then
		for _, lado in ipairs({ -1, 1 }) do
			peca(m, Vector3.new(0.92, 0.1, 0.92), CFrame.new(0.75 * lado, -0.15, 0.15), vermelho, MAT.Neon)
		end
	end
end

-- Cria o modelo 3D do item. ri = índice da raridade (1 = Comum ... 9 = Secreto)
function ItemArte.criar(slot, ri, cor, conjunto, classe)
	local m = Instance.new("Model")
	m.Name = "Item3D"
	m.WorldPivot = CFrame.new()
	ri = math.clamp(ri or 1, 1, 9)
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
-- Solda as peças no corpo. Peças animadas (anéis, orbes, cristais) ganham uma Weld
-- com a tag "GiroItem": o GameClient gira/flutua essas peças no corpo, igual ao ícone.
local function soldar(m, base)
	local escala = m:GetScale()
	local piv = m:GetPivot()
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Anchored = false
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
			p.Massless = true
			p.CastShadow = p.Material ~= MAT.Neon
			local info = animInfo[p]
			if info and (info.vel ~= 0 or info.flut ~= 0) then
				local centro = piv * CFrame.new(info.centro.Position * escala) * info.centro.Rotation
				local w = Instance.new("Weld")
				w.Name = "GiroItem"
				w.Part0 = base
				w.Part1 = p
				w.C0 = base.CFrame:ToObjectSpace(p.CFrame)
				w:SetAttribute("Centro", base.CFrame:ToObjectSpace(centro))
				w:SetAttribute("Rel", centro:ToObjectSpace(p.CFrame))
				w:SetAttribute("Eixo", info.eixo)
				w:SetAttribute("Vel", info.vel)
				w:SetAttribute("Flut", info.flut * escala)
				CollectionService:AddTag(w, "GiroItem")
				w.Parent = p
			else
				local w = Instance.new("WeldConstraint")
				w.Part0 = base
				w.Part1 = p
				w.Parent = p
			end
		end
	end
end

-- deixa só as peças de um lado do par (luvas, calça, brincos)
local function soLado(m, lado)
	for _, p in ipairs(m:GetChildren()) do
		if p:IsA("BasePart") and math.sign(p.Position.X) ~= lado then
			p:Destroy()
		end
	end
end

local function pecaCorpo(char, r15, r6)
	return char:FindFirstChild(r15) or char:FindFirstChild(r6)
end

-- Luz e partículas no item vestido (do Épico para cima)
-- Rastro de luz da arma (aparece no golpe), do Raro para cima: liga o cabo à ponta
local function rastroArma(m, ri, cor)
	if ri < 3 then
		return
	end
	local nucleo = m:FindFirstChild("Nucleo") or m:FindFirstChildWhichIsA("BasePart")
	if not nucleo then
		return
	end
	local cf, tam = m:GetBoundingBox()
	local eixo = cf.UpVector * tam.Y
	if tam.X >= tam.Y and tam.X >= tam.Z then
		eixo = cf.RightVector * tam.X
	elseif tam.Z >= tam.Y then
		eixo = cf.LookVector * tam.Z
	end
	local a0 = Instance.new("Attachment")
	a0.Parent = nucleo
	a0.WorldPosition = cf.Position - eixo * 0.15
	local a1 = Instance.new("Attachment")
	a1.Parent = nucleo
	a1.WorldPosition = cf.Position + eixo * 0.48
	local t = Instance.new("Trail")
	t.Attachment0 = a0
	t.Attachment1 = a1
	t.Lifetime = ri >= 6 and 0.32 or 0.22
	t.MinLength = 0.05
	t.LightEmission = ri >= 9 and 0.3 or 1
	local claro = ri >= 9 and Color3.fromRGB(235, 235, 255) or cor:Lerp(Color3.new(1, 1, 1), 0.5)
	t.Color = ColorSequence.new(claro, ri >= 9 and Color3.fromRGB(20, 16, 30) or cor)
	t.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, ri >= 6 and 0.05 or 0.3),
		NumberSequenceKeypoint.new(1, 1),
	})
	t.Parent = nucleo
end

local function efeitosNoCorpo(m, ri, cor, slot)
	if ri < 4 then
		return
	end
	local nucleo = m:FindFirstChild("Nucleo") or m:FindFirstChildWhichIsA("BasePart")
	if not nucleo then
		return
	end
	local secreto = ri >= 9
	local corFx = secreto and Color3.fromRGB(235, 235, 255) or cor
	local luz = Instance.new("PointLight")
	luz.Color = corFx
	luz.Range = 4 + ri
	luz.Brightness = slot == "arma" and 1.6 or 0.8
	luz.Shadows = false
	luz.Parent = nucleo
	if ri < 5 or (slot ~= "arma" and ri < 6) then
		return
	end
	local fx = Instance.new("ParticleEmitter")
	fx.Name = "BrilhoItem"
	fx.LightEmission = secreto and 0.2 or 1
	fx.Rate = slot == "arma" and (ri >= 7 and 18 or 10) or 5
	fx.Lifetime = NumberRange.new(0.4, 0.9)
	fx.Speed = NumberRange.new(0.5, 1.5)
	fx.SpreadAngle = Vector2.new(180, 180)
	fx.RotSpeed = NumberRange.new(-180, 180)
	fx.Rotation = NumberRange.new(0, 360)
	if ri == 7 or ri == 8 then
		-- chamas subindo (turquesa no Imortal, ouro branco no Divino)
		fx.Color = ri == 7 and ColorSequence.new(Color3.fromRGB(210, 255, 250), Color3.fromRGB(30, 210, 200))
			or ColorSequence.new(Color3.fromRGB(255, 255, 230), Color3.fromRGB(255, 200, 40))
		fx.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0) })
		fx.Acceleration = Vector3.new(0, 6, 0)
		fx.Transparency = NumberSequence.new(0.1, 1)
	elseif secreto then
		-- fumaça preta com faíscas brancas
		fx.Color = ColorSequence.new(Color3.fromRGB(20, 18, 26), Color3.fromRGB(70, 66, 90))
		fx.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0.8) })
		fx.Transparency = NumberSequence.new(0.3, 1)
		fx.Acceleration = Vector3.new(0, 2, 0)
		local faisca = Instance.new("ParticleEmitter")
		faisca.Color = ColorSequence.new(BRANCO)
		faisca.LightEmission = 1
		faisca.Size = NumberSequence.new(0.12, 0)
		faisca.Lifetime = NumberRange.new(0.2, 0.5)
		faisca.Rate = 12
		faisca.Speed = NumberRange.new(3, 6)
		faisca.SpreadAngle = Vector2.new(180, 180)
		faisca.Parent = nucleo
	else
		-- brilhinhos na cor da raridade (maiores no Mítico)
		fx.Color = ColorSequence.new(cor:Lerp(BRANCO, 0.5), cor)
		fx.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, ri == 6 and 0.3 or 0.2),
			NumberSequenceKeypoint.new(1, 0),
		})
		fx.Transparency = NumberSequence.new(0, 1)
		fx.Acceleration = Vector3.new(0, 1.5, 0)
	end
	fx.Parent = nucleo
	if slot == "arma" and ri >= 6 then
		local h = Instance.new("Highlight")
		h.FillTransparency = 1
		h.OutlineColor = corFx
		h.OutlineTransparency = 0.2
		h.DepthMode = Enum.HighlightDepthMode.Occluded
		h.Parent = m
	end
end

-- Modelo para vestir: nos acessórios e peças pequenas tira os enfeites flutuantes
local SEM_ENFEITE =
	{ luvas = true, calca = true, colar = true, broche = true, cinto = true, bracelete = true, brinco = true }
local function criarNoCorpo(slot, ri, cor, conjunto, classe)
	local m = ItemArte.criar(slot, ri, cor, conjunto, classe)
	if SEM_ENFEITE[slot] then
		for _, p in ipairs(m:GetChildren()) do
			if p:GetAttribute("Enfeite") then
				p:Destroy()
			end
		end
	end
	return m
end

-- Veste o item no personagem (cria o modelo 3D e solda nas partes do corpo)
function ItemArte.vestir(char, pasta, slot, ri, cor, conjunto, classe)
	ri = math.clamp(ri or 1, 1, 9)
	if slot == "arma" then
		local mao = pecaCorpo(char, "RightHand", "Right Arm")
		if not mao then
			return
		end
		local m = criarNoCorpo(slot, ri, cor, conjunto, classe)
		local pegada = mao.Name == "Right Arm" and mao.CFrame * CFrame.new(0, -0.95, 0)
			or mao.CFrame * CFrame.new(0, -0.15, 0)
		if classe == "cacador" or classe == "mago" then
			-- arco e cajado ficam em pé na mão (o cabo na palma)
			local sc = classe == "cacador" and (0.5 + ri * 0.025) or (0.6 + ri * 0.03)
			m:ScaleTo(sc)
			local cabo = classe == "mago" and -0.7 or 0
			m:PivotTo(pegada * CFrame.new(0, -cabo * sc, 0) * CFrame.Angles(0, 0, math.rad(45)))
		else
			local s = 0.55 + ri * 0.03
			m:ScaleTo(s)
			m:PivotTo(
				pegada
					* CFrame.Angles(math.rad(-90), 0, 0)
					* CFrame.new(0, 0.72 * s, 0)
					* CFrame.Angles(0, 0, math.rad(45))
			)
		end
		rastroArma(m, ri, cor)
		soldar(m, mao)
		efeitosNoCorpo(m, ri, cor, slot)
		m.Parent = pasta
	elseif slot == "elmo" then
		local cabeca = char:FindFirstChild("Head")
		if not cabeca then
			return
		end
		local m = criarNoCorpo(slot, ri, cor, conjunto, classe)
		for _, p in ipairs(m:GetChildren()) do
			if p.Name == "SombraRosto" then
				p:Destroy()
			end
		end
		local escala, desloc
		if conjunto == "katsuki" then
			escala, desloc = 0.55, CFrame.new(0, 0.55, 0)
		elseif classe == "mago" then
			escala, desloc = 0.48, CFrame.new(0, 0.62, 0)
		elseif classe == "cacador" then
			escala, desloc = 0.52, CFrame.new(0, 0.08, 0)
		elseif ri == 1 then
			escala, desloc = 0.5, CFrame.new(0, 0.18, 0)
		else
			escala, desloc = 0.55, CFrame.new(0, 0.15, 0)
		end
		m:ScaleTo(escala)
		m:PivotTo(cabeca.CFrame * desloc)
		soldar(m, cabeca)
		efeitosNoCorpo(m, ri, cor, slot)
		m.Parent = pasta
	elseif slot == "armadura" then
		local tronco = pecaCorpo(char, "UpperTorso", "Torso")
		if not tronco then
			return
		end
		local m = criarNoCorpo(slot, ri, cor, conjunto, classe)
		local r15 = tronco.Name == "UpperTorso"
		m:ScaleTo(r15 and 0.72 or 0.82)
		m:PivotTo(tronco.CFrame * CFrame.new(0, r15 and -0.15 or -0.05, 0))
		soldar(m, tronco)
		efeitosNoCorpo(m, ri, cor, slot)
		m.Parent = pasta
	elseif slot == "botas" then
		for _, lado in ipairs({ -1, 1 }) do
			local perna = lado < 0 and pecaCorpo(char, "LeftFoot", "Left Leg")
				or pecaCorpo(char, "RightFoot", "Right Leg")
			if perna then
				local m = criarNoCorpo(slot, ri, cor, conjunto, classe)
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
	elseif slot == "armaSec" then
		local m = criarNoCorpo(slot, ri, cor, conjunto, classe)
		if classe == "cacador" then
			-- aljava nas costas
			local tronco = pecaCorpo(char, "UpperTorso", "Torso")
			if not tronco then
				return m:Destroy()
			end
			m:ScaleTo(0.55 + ri * 0.015)
			m:PivotTo(tronco.CFrame * CFrame.new(0.3, 0.15, tronco.Size.Z / 2 + 0.4) * CFrame.Angles(0, math.pi, 0))
			soldar(m, tronco)
		elseif classe == "mago" then
			-- grimório flutuando ao lado do quadril
			local tronco = pecaCorpo(char, "UpperTorso", "Torso")
			if not tronco then
				return m:Destroy()
			end
			for _, p in ipairs(m:GetDescendants()) do
				if p:IsA("BasePart") and not animInfo[p] then
					animar(p, CFrame.new(), Vector3.yAxis, 0, 0.2)
				end
			end
			m:ScaleTo(0.4 + ri * 0.015)
			m:PivotTo(tronco.CFrame * CFrame.new(-(tronco.Size.X / 2 + 1.0), -0.2, -0.3))
			soldar(m, tronco)
		else
			-- escudo no antebraço esquerdo, virado para fora
			local braco = pecaCorpo(char, "LeftLowerArm", "Left Arm")
			if not braco then
				return m:Destroy()
			end
			m:ScaleTo(0.42 + ri * 0.018)
			local y = braco.Name == "Left Arm" and -0.3 or 0
			m:PivotTo(braco.CFrame * CFrame.new(-(braco.Size.X / 2 + 0.15), y, 0) * CFrame.Angles(0, math.rad(90), 0))
			soldar(m, braco)
		end
		efeitosNoCorpo(m, ri, cor, slot)
		m.Parent = pasta
	elseif slot == "luvas" then
		for _, lado in ipairs({ -1, 1 }) do
			local mao = lado < 0 and pecaCorpo(char, "LeftHand", "Left Arm")
				or pecaCorpo(char, "RightHand", "Right Arm")
			if mao then
				local m = criarNoCorpo(slot, ri, cor, conjunto, classe)
				soLado(m, lado)
				local r15 = mao.Name:find("Hand") ~= nil
				local s = (r15 and mao.Size.X * 0.95 or 1.05) / 0.85
				m:ScaleTo(s)
				local alvo = r15 and mao.CFrame * CFrame.new(0, 0.1, 0) or mao.CFrame * CFrame.new(0, -0.62, 0)
				m:PivotTo(alvo * CFrame.new(-0.95 * lado * s, 0, 0))
				soldar(m, mao)
				m.Parent = pasta
			end
		end
	elseif slot == "calca" then
		for _, lado in ipairs({ -1, 1 }) do
			local coxa = lado < 0 and pecaCorpo(char, "LeftUpperLeg", "Left Leg")
				or pecaCorpo(char, "RightUpperLeg", "Right Leg")
			if coxa then
				local r15 = coxa.Name:find("UpperLeg") ~= nil
				local s = coxa.Size.X * 1.08 / 1.02
				if r15 then
					-- coxa e canela separadas (o joelho dobra)
					local canela = char:FindFirstChild(lado < 0 and "LeftLowerLeg" or "RightLowerLeg")
					for _, parteDe in ipairs({ "coxa", "canela" }) do
						local alvo = parteDe == "coxa" and coxa or canela
						if alvo then
							local m = criarNoCorpo(slot, ri, cor, conjunto, classe)
							soLado(m, lado)
							for _, p in ipairs(m:GetChildren()) do
								if p:IsA("BasePart") and (p.Position.Y > 0) ~= (parteDe == "coxa") then
									p:Destroy()
								end
							end
							m:ScaleTo(s)
							local dy = parteDe == "coxa" and -0.62 or 0.72
							m:PivotTo(alvo.CFrame * CFrame.new(-0.55 * lado * s, dy * s, 0))
							soldar(m, alvo)
							m.Parent = pasta
						end
					end
				else
					local m = criarNoCorpo(slot, ri, cor, conjunto, classe)
					soLado(m, lado)
					m:ScaleTo(s)
					m:PivotTo(coxa.CFrame * CFrame.new(-0.55 * lado * s, 0.05 * s, 0))
					soldar(m, coxa)
					m.Parent = pasta
				end
			end
		end
	elseif slot == "brinco" then
		local cabeca = char:FindFirstChild("Head")
		if not cabeca then
			return
		end
		local meia = cabeca.Size.X > 1.6 and 0.62 or cabeca.Size.X / 2
		for _, lado in ipairs({ -1, 1 }) do
			local m = criarNoCorpo(slot, ri, cor, conjunto, classe)
			soLado(m, lado)
			local s = 0.32
			m:ScaleTo(s)
			local orelha = cabeca.CFrame * CFrame.new(lado * (meia + 0.04), -0.12, 0)
			m:PivotTo(orelha * CFrame.new(-0.75 * lado * s, -0.75 * s, 0))
			soldar(m, cabeca)
			m.Parent = pasta
		end
	elseif slot == "colar" or slot == "broche" then
		local tronco = pecaCorpo(char, "UpperTorso", "Torso")
		if not tronco then
			return
		end
		local m = criarNoCorpo(slot, ri, cor, conjunto, classe)
		local frente = -(tronco.Size.Z / 2 + 0.45)
		if slot == "colar" then
			local s = 0.42
			m:ScaleTo(s)
			m:PivotTo(tronco.CFrame * CFrame.new(0, tronco.Size.Y / 2 - 0.95 * s - 0.02, frente))
		else
			m:ScaleTo(0.3)
			m:PivotTo(tronco.CFrame * CFrame.new(-tronco.Size.X * 0.28, tronco.Size.Y * 0.2, frente - 0.05))
		end
		soldar(m, tronco)
		m.Parent = pasta
	elseif slot == "bracelete" then
		local braco = pecaCorpo(char, "LeftLowerArm", "Left Arm")
		if not braco then
			return
		end
		local m = criarNoCorpo(slot, ri, cor, conjunto, classe)
		m:ScaleTo((braco.Size.X / 2 + 0.06) / 0.59)
		m:PivotTo(braco.CFrame * CFrame.new(0, braco.Name == "Left Arm" and -0.3 or 0, 0))
		soldar(m, braco)
		m.Parent = pasta
	elseif slot == "cinto" then
		local cintura = char:FindFirstChild("LowerTorso") or char:FindFirstChild("Torso")
		if not cintura then
			return
		end
		local m = criarNoCorpo(slot, ri, cor, conjunto, classe)
		m:ScaleTo((cintura.Size.X + 0.1) / 2.3)
		m:PivotTo(cintura.CFrame * CFrame.new(0, cintura.Name == "Torso" and -0.75 or 0.05, 0))
		soldar(m, cintura)
		m.Parent = pasta
	end
end

-- Tira a aura antiga (antes de vestir de novo)
function ItemArte.limparAura(char)
	for _, d in ipairs(char:GetDescendants()) do
		if d.Name == "AuraRara" or (d:IsA("PointLight") and d:GetAttribute("AuraRara")) then
			d:Destroy()
		end
	end
end

local TEX = {
	brilho = "rbxasset://textures/particles/sparkles_main.dds",
	fogo = "rbxasset://textures/particles/fire_main.dds",
	fumaca = "rbxasset://textures/particles/smoke_main.dds",
	onda = "rbxasset://textures/particles/explosion01_shockwave_main.dds",
	vortice = "rbxasset://textures/particles/forcefield_vortex_main.dds",
	faisca = "rbxasset://textures/particles/fire_sparks_main.dds",
}

local function emissor(pai, props)
	local fx = Instance.new("ParticleEmitter")
	fx.LightEmission = 1
	fx.SpreadAngle = Vector2.new(0, 0)
	for k, v in pairs(props) do
		fx[k] = v
	end
	fx.Parent = pai
	return fx
end

local function numSeq(...)
	local pts, args = {}, { ... }
	for i = 1, #args, 2 do
		table.insert(pts, NumberSequenceKeypoint.new(args[i], args[i + 1]))
	end
	return NumberSequence.new(pts)
end

local function pecaInvisivel(pai, tamanho, cf, solda)
	local p = Instance.new("Part")
	p.Name = "AuraRara"
	p.Transparency = 1
	p.Size = tamanho
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.CastShadow = false
	p.CFrame = cf
	local w = Instance.new("WeldConstraint")
	w.Part0 = solda
	w.Part1 = p
	w.Parent = p
	p.Parent = pai
	return p
end

-- Rastro de luz preso numa parte do corpo (aparece quando o herói anda e ataca)
local function rastroCorpo(parte, cor, claro, largura)
	if not parte then
		return
	end
	local a0 = Instance.new("Attachment")
	a0.Name = "AuraRara"
	a0.Position = Vector3.new(0, largura / 2, 0)
	a0.Parent = parte
	local a1 = Instance.new("Attachment")
	a1.Name = "AuraRara"
	a1.Position = Vector3.new(0, -largura / 2, 0)
	a1.Parent = parte
	local t = Instance.new("Trail")
	t.Attachment0 = a0
	t.Attachment1 = a1
	t.Lifetime = 0.35
	t.MinLength = 0.05
	t.LightEmission = 1
	t.FaceCamera = true
	t.Color = ColorSequence.new(claro, cor)
	t.Transparency = numSeq(0, 0.15, 1, 1)
	t.WidthScale = numSeq(0, 1, 1, 0)
	t.Parent = a0
end

-- Aura no corpo (do Raro para cima). Cada tier soma um efeito novo:
-- T3 brilhinhos · T4 anel no chão + luz · T5 coluna de energia + rastros
-- T5 chamas de aura · T6 anéis subindo + contorno · T7 turquesa com raios e auréola · T8 Divino dourado · T9 fumaça preta e faíscas brancas
function ItemArte.aura(char, pasta, ri, cor)
	local raiz = char:FindFirstChild("HumanoidRootPart")
	local tronco = pecaCorpo(char, "UpperTorso", "Torso")
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not raiz or not tronco or not hum or ri < 3 then
		return
	end
	local secreto = ri >= 9
	local principal, claro
	if secreto then
		principal, claro = Color3.fromRGB(16, 12, 24), Color3.fromRGB(235, 235, 255)
	elseif ri == 8 then
		principal, claro = Color3.fromRGB(255, 205, 50), Color3.fromRGB(255, 255, 225)
	elseif ri == 7 then
		principal, claro = Color3.fromRGB(40, 230, 215), Color3.fromRGB(210, 255, 250)
	else
		principal, claro = cor, cor:Lerp(BRANCO, 0.6)
	end
	local r15 = hum.RigType == Enum.HumanoidRigType.R15
	local altura = (r15 and hum.HipHeight or 2) + raiz.Size.Y / 2
	local largura = 3 + ri * 0.3
	local chao = raiz.CFrame * CFrame.new(0, -altura + 0.15, 0)
	-- base invisível no chão: as partículas saem num círculo em volta dos pés
	local base = pecaInvisivel(pasta, Vector3.new(largura, 0.2, largura), chao, raiz)

	-- brilhinhos subindo em volta do corpo
	emissor(base, {
		Texture = TEX.brilho,
		Shape = Enum.ParticleEmitterShape.Cylinder,
		ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface,
		EmissionDirection = Enum.NormalId.Top,
		Color = ColorSequence.new(claro, secreto and Color3.fromRGB(150, 140, 200) or principal),
		Size = numSeq(0, 0, 0.2, ri >= 6 and 0.95 or 0.7, 1, 0),
		Transparency = numSeq(0, 0, 1, 1),
		Lifetime = NumberRange.new(0.8, 1.4),
		Rate = 6 + ri * 3,
		Speed = NumberRange.new(2, 4 + ri * 0.4),
		RotSpeed = NumberRange.new(-120, 120),
		Rotation = NumberRange.new(0, 360),
	})
	if ri < 4 then
		return
	end

	-- anel de luz que nasce nos pés e se abre (pulso no chão)
	emissor(base, {
		Texture = TEX.onda,
		Orientation = Enum.ParticleOrientation.VelocityPerpendicular,
		EmissionDirection = Enum.NormalId.Top,
		Color = ColorSequence.new(secreto and claro or principal:Lerp(BRANCO, 0.25)),
		LightEmission = secreto and 0.6 or 1,
		Size = numSeq(0, 1, 1, largura * 1.5),
		Transparency = numSeq(0, 0, 0.7, 0.45, 1, 1),
		Lifetime = NumberRange.new(1.1),
		Rate = ri >= 6 and 1.6 or 1,
		Speed = NumberRange.new(0.01),
		ZOffset = 0.2,
	})
	-- luz em volta do herói
	local luz = Instance.new("PointLight")
	luz.Color = secreto and Color3.fromRGB(190, 180, 255) or principal
	luz.Range = 8 + ri * 1.5
	luz.Brightness = secreto and 1.4 or 1.5 + (ri - 4) * 0.35
	luz.Shadows = false
	luz:SetAttribute("AuraRara", true)
	luz.Parent = tronco
	if ri < 5 then
		return
	end

	-- coluna de energia: riscos de luz subindo rápido em volta do corpo
	emissor(base, {
		Texture = TEX.brilho,
		Shape = Enum.ParticleEmitterShape.Cylinder,
		ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface,
		EmissionDirection = Enum.NormalId.Top,
		Orientation = Enum.ParticleOrientation.VelocityParallel,
		Color = ColorSequence.new(claro, principal),
		Size = numSeq(0, 0.45, 1, 0.1),
		Squash = numSeq(0, -2.5, 1, -2.5),
		Transparency = numSeq(0, 0, 1, 1),
		Lifetime = NumberRange.new(0.45, 0.7),
		Rate = 14 + ri * 4,
		Speed = NumberRange.new(9, 14),
	})
	-- rastros de luz nas mãos e nos pés
	local largRastro = ri >= 7 and 0.9 or 0.6
	rastroCorpo(pecaCorpo(char, "RightHand", "Right Arm"), principal, claro, largRastro)
	rastroCorpo(pecaCorpo(char, "LeftHand", "Left Arm"), principal, claro, largRastro)
	if ri >= 6 then
		rastroCorpo(pecaCorpo(char, "RightFoot", "Right Leg"), principal, claro, largRastro * 0.7)
		rastroCorpo(pecaCorpo(char, "LeftFoot", "Left Leg"), principal, claro, largRastro * 0.7)
	end
	-- chamas de aura cobrindo o corpo (preta e fumacenta no Secreto)
	local corpo = pecaInvisivel(pasta, Vector3.new(2.4, 4.5, 1.6), raiz.CFrame * CFrame.new(0, 0.2, 0), raiz)
	emissor(corpo, {
		Texture = secreto and TEX.fumaca or TEX.fogo,
		Shape = Enum.ParticleEmitterShape.Box,
		EmissionDirection = Enum.NormalId.Top,
		Color = secreto and ColorSequence.new(Color3.fromRGB(8, 6, 12), Color3.fromRGB(60, 50, 80))
			or ColorSequence.new(claro, principal),
		LightEmission = secreto and 0 or 0.9,
		Size = numSeq(
			0,
			secreto and 1.3 or (ri >= 6 and 1.2 or 0.8),
			0.4,
			secreto and 2.4 or (ri >= 6 and 2 or 1.3),
			1,
			0
		),
		Transparency = numSeq(0, secreto and 0.15 or 0.3, 0.5, secreto and 0.35 or 0.5, 1, 1),
		Lifetime = NumberRange.new(0.6, 1),
		Rate = secreto and 30 or (ri >= 6 and 28 or 18),
		Speed = NumberRange.new(1.5, 3),
		Acceleration = Vector3.new(0, secreto and 4 or 6, 0),
		RotSpeed = NumberRange.new(-60, 60),
		Rotation = NumberRange.new(0, 360),
	})
	if ri < 6 then
		return
	end
	-- anéis de energia subindo pelo corpo
	emissor(base, {
		Texture = TEX.onda,
		Orientation = Enum.ParticleOrientation.VelocityPerpendicular,
		EmissionDirection = Enum.NormalId.Top,
		Color = ColorSequence.new(claro, principal),
		LightEmission = secreto and 0.5 or 1,
		Size = numSeq(0, largura * 0.75, 1, largura * 0.55),
		Transparency = numSeq(0, 0.1, 1, 1),
		Lifetime = NumberRange.new(0.9),
		Rate = 2,
		Speed = NumberRange.new(5),
	})
	-- contorno brilhante no herói
	local h = Instance.new("Highlight")
	h.Name = "AuraContorno"
	h.FillColor = secreto and Color3.fromRGB(40, 30, 70) or principal
	h.FillTransparency = secreto and 0.82 or 0.88
	h.OutlineColor = claro
	h.OutlineTransparency = 0.1
	h.DepthMode = Enum.HighlightDepthMode.Occluded
	h.Adornee = char
	h.Parent = pasta
	if ri < 7 then
		return
	end

	-- auréola nas costas: anel de cristais (turquesa no Imortal, dourado no Divino, preto com fio branco no Secreto)
	local costas = tronco.CFrame * CFrame.new(0, 0.9, 1.1)
	local raio = 1.35
	for i = 1, 14 do
		local ang = (i / 14) * math.pi * 2
		local p = Instance.new("Part")
		p.Name = "AuraRara"
		p.Size = Vector3.new(0.18, 0.5, 0.18)
		p.Material = MAT.Neon
		p.Color = (secreto and i % 2 == 0) and PRETO or claro
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Massless = true
		p.CastShadow = false
		p.CFrame = costas * CFrame.Angles(0, 0, ang) * CFrame.new(0, raio, 0)
		local w = Instance.new("WeldConstraint")
		w.Part0 = tronco
		w.Part1 = p
		w.Parent = p
		p.Parent = pasta
	end
	local centroCostas = pecaInvisivel(pasta, Vector3.new(0.4, 0.4, 0.4), costas, tronco)
	emissor(centroCostas, {
		Texture = TEX.vortice,
		Color = ColorSequence.new(claro),
		LightEmission = secreto and 0.4 or 1,
		Size = numSeq(0, raio * 2.2, 1, raio * 2.6),
		Transparency = numSeq(0, 0.5, 1, 1),
		Lifetime = NumberRange.new(0.8),
		Rate = 3,
		Speed = NumberRange.new(0),
		RotSpeed = NumberRange.new(90, 140),
		Rotation = NumberRange.new(0, 360),
		LockedToPart = true,
	})
	-- faíscas/raios saltando do corpo
	emissor(corpo, {
		Texture = TEX.faisca,
		Shape = Enum.ParticleEmitterShape.Box,
		EmissionDirection = Enum.NormalId.Top,
		SpreadAngle = Vector2.new(180, 180),
		Color = ColorSequence.new(BRANCO, claro),
		Size = numSeq(0, 0.5, 1, 0),
		Lifetime = NumberRange.new(0.2, 0.45),
		Rate = secreto and 24 or 18,
		Speed = NumberRange.new(5, 9),
	})
	if secreto then
		-- rastro de fumaça preta saindo dos pés
		emissor(base, {
			Texture = TEX.fumaca,
			Shape = Enum.ParticleEmitterShape.Cylinder,
			ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
			EmissionDirection = Enum.NormalId.Top,
			Color = ColorSequence.new(Color3.fromRGB(4, 4, 8), Color3.fromRGB(40, 34, 56)),
			LightEmission = 0,
			Size = numSeq(0, 1.5, 1, 3.5),
			Transparency = numSeq(0, 0.35, 1, 1),
			Lifetime = NumberRange.new(1, 1.6),
			Rate = 14,
			Speed = NumberRange.new(0.5, 1.5),
			Acceleration = Vector3.new(0, 1.5, 0),
			RotSpeed = NumberRange.new(-40, 40),
			Rotation = NumberRange.new(0, 360),
		})
	end
end

------------------------------------------------------------------------
-- Ícones (ViewportFrame): enquadramento grande, brilho de fundo e peças animadas
------------------------------------------------------------------------
local ativos = setmetatable({}, { __mode = "k" })
local loopLigado = false

local function ligarLoop()
	if loopLigado or not RunService:IsClient() then
		return
	end
	loopLigado = true
	RunService.RenderStepped:Connect(function()
		local t = os.clock()
		for m, lista in pairs(ativos) do
			if not m.Parent then
				ativos[m] = nil
			else
				local piv = m:GetPivot()
				for _, a in ipairs(lista) do
					local i = a.info
					a.parte.CFrame = piv
						* i.centro
						* CFrame.fromAxisAngle(i.eixo, i.vel * t)
						* CFrame.new(0, math.sin(t * 2.2) * i.flut, 0)
						* a.rel
				end
			end
		end
	end)
end

-- brilho redondo atrás do ícone na cor da raridade (raios girando do Lendário para cima)
local function brilhoFundo(vp, ri, cor)
	local pai = vp.Parent
	if not pai or not pai:IsA("GuiObject") then
		return
	end
	local velho = pai:FindFirstChild("BrilhoRaridade")
	if velho then
		velho:Destroy()
	end
	local corB = ri >= 9 and Color3.fromRGB(235, 235, 255) or cor
	local g = Instance.new("Frame")
	g.Name = "BrilhoRaridade"
	g.BackgroundTransparency = 1
	g.AnchorPoint = Vector2.new(0.5, 0.5)
	g.Position = UDim2.new(
		vp.Position.X.Scale + vp.Size.X.Scale / 2,
		vp.Position.X.Offset + vp.Size.X.Offset / 2,
		vp.Position.Y.Scale + vp.Size.Y.Scale / 2,
		vp.Position.Y.Offset + vp.Size.Y.Offset / 2
	)
	g.Size = vp.Size
	g.ZIndex = math.max(1, vp.ZIndex - 1)
	local aspecto = Instance.new("UIAspectRatioConstraint")
	aspecto.Parent = g
	if ri >= 5 then
		local raios = Instance.new("Frame")
		raios.BackgroundTransparency = 1
		raios.AnchorPoint = Vector2.new(0.5, 0.5)
		raios.Position = UDim2.fromScale(0.5, 0.5)
		raios.Size = UDim2.fromScale(1.15, 1.15)
		raios.ZIndex = g.ZIndex
		raios.Parent = g
		for i = 1, 6 do
			local r = Instance.new("Frame")
			r.AnchorPoint = Vector2.new(0.5, 0.5)
			r.Position = UDim2.fromScale(0.5, 0.5)
			r.Size = UDim2.fromScale(0.16, 1)
			r.Rotation = i * 30
			r.BackgroundColor3 = corB:Lerp(BRANCO, 0.3)
			r.BackgroundTransparency = 0.55
			r.BorderSizePixel = 0
			r.ZIndex = g.ZIndex
			r.Parent = raios
			local gr = Instance.new("UIGradient")
			gr.Rotation = 90
			gr.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.5, 0.2),
				NumberSequenceKeypoint.new(1, 1),
			})
			gr.Parent = r
		end
		TweenService:Create(
			raios,
			TweenInfo.new(ri >= 7 and 6 or 10, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1),
			{ Rotation = 360 }
		):Play()
	end
	for i, tam in ipairs({ 0.95, 0.68, 0.4 }) do
		local c = Instance.new("Frame")
		c.AnchorPoint = Vector2.new(0.5, 0.5)
		c.Position = UDim2.fromScale(0.5, 0.5)
		c.Size = UDim2.fromScale(tam, tam)
		c.BackgroundColor3 = corB:Lerp(BRANCO, (i - 1) * 0.3)
		c.BackgroundTransparency = ({ 0.86, 0.78, 0.68 })[i] - (ri >= 5 and 0.08 or 0)
		c.BorderSizePixel = 0
		c.ZIndex = g.ZIndex
		local cc = Instance.new("UICorner")
		cc.CornerRadius = UDim.new(1, 0)
		cc.Parent = c
		c.Parent = g
	end
	g.Parent = pai
end

-- Coloca o item num ViewportFrame com câmera enquadrando bem grande
function ItemArte.mostrar(vp, slot, ri, cor, conjunto, classe)
	ri = math.clamp(ri or 1, 1, 9)
	local m = ItemArte.criar(slot, ri, cor, conjunto, classe)
	-- peças animadas: guarda a posição de cada uma relativa ao centro da animação
	local lista = {}
	for _, p in ipairs(m:GetDescendants()) do
		local info = p:IsA("BasePart") and animInfo[p]
		if info then
			table.insert(lista, { parte = p, info = info, rel = info.centro:Inverse() * p.CFrame })
		end
	end
	m.Parent = vp
	local cam = Instance.new("Camera")
	cam.FieldOfView = 30
	cam.Parent = vp
	vp.CurrentCamera = cam
	local cf, tam = m:GetBoundingBox()
	local raio = tam.Magnitude / 2
	local dist = raio / math.tan(math.rad(cam.FieldOfView / 2)) * 0.9
	local dir = Vector3.new(0.35, 0.25, -1).Unit
	cam.CFrame = CFrame.lookAt(cf.Position + dir * dist, cf.Position)
	vp.Ambient = Color3.fromRGB(165, 160, 172)
	vp.LightColor = Color3.fromRGB(255, 250, 240)
	vp.LightDirection = Vector3.new(-0.4, -1, 0.6)
	brilhoFundo(vp, ri, cor)
	if #lista > 0 then
		ativos[m] = lista
		ligarLoop()
	end
	return m
end

return ItemArte
