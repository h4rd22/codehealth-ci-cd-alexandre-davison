-- Chefe: comportamento do chefe final do ato (Pen).
-- Ele desce do céu com um raio e ruge, flutua indo atrás do herói, se teleporta
-- e usa 3 habilidades com aviso no chão. As poses (braços, corpo) são desenhadas na tela
-- do jogador pelo AnimInimigos: aqui só avisamos com o atributo "Pose" e "Movendo".
--   Repulsão Divina  - onda de choque em volta dele que empurra o herói
--   Esferas Negras   - 3 esferas que voam até onde o herói estava
--   Chuva de Pregos  - círculos vermelhos no chão que viram pregos caindo do céu

local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

local Chefe = {}

local ROXO = Color3.fromRGB(180, 90, 255)
local VERMELHO = Color3.fromRGB(255, 60, 70)
local LARANJA = Color3.fromRGB(255, 120, 40)
local XZ = Vector3.new(1, 0, 1)

local ALTURA_ENTRADA = 22 -- de onde ele desce na entrada
local VELOCIDADE = 5 -- studs por segundo indo atrás do herói (passo pesado)
local DISTANCIA_IDEAL = 9 -- para de chegar perto a essa distância

local function peca(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.Neon
	for k, v in pairs(props) do
		p[k] = v
	end
	p.Parent = workspace
	return p
end

-- Disco plano no chão (aviso de onde vai acertar)
local function disco(pos, raio, cor, transp)
	return peca({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.15, raio * 2, raio * 2),
		CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90)),
		Color = cor,
		Transparency = transp or 0.55,
	})
end

local function luz(parte, cor, alcance)
	local l = Instance.new("PointLight")
	l.Color = cor
	l.Range = alcance or 12
	l.Brightness = 3
	l.Parent = parte
end

--[[
	ctx = {
		player = Player,
		vivo = function(): boolean,          -- o chefe ainda está vivo?
		raizHeroi = function(): BasePart?,   -- HumanoidRootPart do herói
		chao = number,                        -- altura do chão da arena
		dano = number,                        -- dano base do chefe (do nível dele)
		acertar = function(pos, raio, dano)  -- causa dano se o herói estiver no raio
		empurrar = function(direcao: Vector3, forca: number)
		atacar = function()                   -- toca a animação de ataque
		aviso = function(texto: string)       -- nome da habilidade na tela
	}
]]
function Chefe.iniciar(m, ctx)
	local contadorPose = 0
	local function pose(nome)
		contadorPose += 1
		m:SetAttribute("Pose", nome .. "#" .. contadorPose)
	end

	local p0 = m:GetPivot().Position
	local pivo0 = m:GetPivot()
	local base = pivo0.Position
	local rot0 = pivo0.Rotation
	local centroLuta = ctx.centro or Vector3.new(0, base.Y, 0)
	local frente0 = (Vector3.new(centroLuta.X, base.Y, centroLuta.Z) - base) * XZ
	if frente0.Magnitude < 0.1 then
		frente0 = Vector3.new(0, 0, 1)
	end
	frente0 = frente0.Unit
	local rMax = ctx.raioTeleporte or 14
	local alturaQueda = ALTURA_ENTRADA -- cai do céu e depois fica sempre com os pés no chão
	local velQueda = 0
	local pousou = false
	local angAtual = 0
	local ocupado = true -- parado (entrada e habilidades); senão vai atrás do herói
	local movendo = false

	-- movimento suave a cada quadro: desce do céu, flutua, vira e anda até o herói
	local con
	con = RunService.Heartbeat:Connect(function(dt)
		if not (ctx.vivo() and m.Parent) then
			con:Disconnect()
			return
		end
		local raiz = ctx.raizHeroi()
		local angAlvo = angAtual
		local andou = false
		if raiz then
			local d = (raiz.Position - base) * XZ
			if d.Magnitude > 0.5 then
				local u = d.Unit
				angAlvo = math.atan2(frente0.X * u.Z - frente0.Z * u.X, frente0.X * u.X + frente0.Z * u.Z)
			end
			if not ocupado and d.Magnitude > DISTANCIA_IDEAL + 1 then
				local nova = base + d.Unit * math.min(d.Magnitude - DISTANCIA_IDEAL, VELOCIDADE * dt)
				local rel = (nova - centroLuta) * XZ
				if rel.Magnitude > rMax then
					nova = Vector3.new(centroLuta.X, base.Y, centroLuta.Z) + rel.Unit * rMax
				end
				andou = (nova - base).Magnitude > 0.001
				base = Vector3.new(nova.X, base.Y, nova.Z)
			end
		end
		if andou ~= movendo then
			movendo = andou
			m:SetAttribute("Movendo", movendo)
		end
		local dif = (angAlvo - angAtual + math.pi) % (2 * math.pi) - math.pi
		angAtual += dif * math.min(1, dt * 5)
		-- queda da entrada com gravidade (pouso pesado)
		if alturaQueda > 0 then
			velQueda += 70 * dt
			alturaQueda = math.max(0, alturaQueda - velQueda * dt)
			if alturaQueda == 0 and not pousou then
				pousou = true
				pose("pouso")
			end
		end
		-- pés no chão: mede onde fica a sola e encosta no chão da arena
		local giro = CFrame.Angles(0, -angAtual, 0) * rot0
		m:PivotTo(CFrame.new(base) * giro)
		local caixa, tam = m:GetBoundingBox()
		local sola = caixa.Position.Y - tam.Y / 2
		m:PivotTo(CFrame.new(base + Vector3.new(0, ctx.chao - sola + alturaQueda, 0)) * giro)
	end)

	-- Entrada: desce do céu, um raio roxo cai onde ele pousa e ele ruge
	pose("entrada")
	task.delay(0.75, function()
		if not ctx.vivo() then
			return
		end
		local relampago = peca({
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(120, 6, 6),
			CFrame = CFrame.new(p0 + Vector3.new(0, 60, 0)) * CFrame.Angles(0, 0, math.rad(90)),
			Color = ROXO,
			Transparency = 0.1,
		})
		luz(relampago, ROXO, 40)
		TweenService:Create(relampago, TweenInfo.new(0.9), { Size = Vector3.new(120, 0.2, 0.2), Transparency = 1 })
			:Play()
		Debris:AddItem(relampago, 1)
		local anel = disco(Vector3.new(base.X, ctx.chao + 0.15, base.Z), 2, ROXO, 0.2)
		TweenService:Create(anel, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = Vector3.new(0.15, 40, 40),
			Transparency = 1,
		}):Play()
		Debris:AddItem(anel, 0.85)
	end)

	task.spawn(function()
		task.wait(1.4) -- espera ele pousar
		if not ctx.vivo() then
			return
		end
		pose("rugido")

		local function posHeroi()
			local raiz = ctx.raizHeroi()
			return raiz and Vector3.new(raiz.Position.X, ctx.chao, raiz.Position.Z)
		end

		local habilidades = {}

		-- 1) Repulsão Divina
		function habilidades.repulsao()
			ctx.aviso("Repulsão Divina!")
			pose("repulsao")
			local centro = Vector3.new(base.X, ctx.chao + 0.1, base.Z)
			local raio = 15
			local aviso = disco(centro, 2, ROXO, 0.6)
			TweenService:Create(aviso, TweenInfo.new(1.4), {
				Size = Vector3.new(0.15, raio * 2, raio * 2),
				Transparency = 0.35,
			}):Play()
			task.wait(1.4)
			if not ctx.vivo() then
				aviso:Destroy()
				return
			end
			ctx.atacar()
			pose("repulsaoSolta")
			aviso:Destroy()
			local onda = peca({
				Shape = Enum.PartType.Ball,
				Size = Vector3.new(4, 4, 4),
				Position = centro + Vector3.new(0, 2, 0),
				Color = ROXO,
				Transparency = 0.3,
				Material = Enum.Material.ForceField,
			})
			luz(onda, ROXO, 30)
			TweenService:Create(onda, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = Vector3.new(raio * 2.2, raio * 2.2, raio * 2.2),
				Transparency = 1,
			}):Play()
			Debris:AddItem(onda, 0.5)
			local acertou = ctx.acertar(centro, raio, ctx.dano * 3)
			if acertou then
				local raiz = ctx.raizHeroi()
				if raiz then
					local dir = (raiz.Position - centro) * Vector3.new(1, 0, 1)
					ctx.empurrar(dir.Magnitude > 0.1 and dir.Unit or Vector3.new(0, 0, 1), 85)
				end
			end
		end

		-- 2) Esferas Negras
		function habilidades.esferas()
			ctx.aviso("Esferas Negras!")
			ctx.atacar()
			for i = 1, 3 do
				local alvo = posHeroi()
				if not alvo or not ctx.vivo() then
					break
				end
				pose("esferas")
				local inicio = base + Vector3.new(math.random(-3, 3), 7, math.random(-3, 3))
				local esf = peca({
					Shape = Enum.PartType.Ball,
					Size = Vector3.new(2.2, 2.2, 2.2),
					Position = inicio,
					Color = Color3.fromRGB(25, 10, 40),
					Material = Enum.Material.Neon,
				})
				luz(esf, ROXO, 14)
				local marca = disco(alvo + Vector3.new(0, 0.1, 0), 4.5, ROXO, 0.5)
				local voo =
					TweenService:Create(esf, TweenInfo.new(0.75, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
						Position = alvo + Vector3.new(0, 1, 0),
					})
				voo.Completed:Connect(function()
					marca:Destroy()
					local boom = peca({
						Shape = Enum.PartType.Ball,
						Size = Vector3.new(2, 2, 2),
						Position = alvo + Vector3.new(0, 1, 0),
						Color = ROXO,
						Transparency = 0.2,
					})
					TweenService:Create(boom, TweenInfo.new(0.3), { Size = Vector3.new(10, 10, 10), Transparency = 1 })
						:Play()
					Debris:AddItem(boom, 0.35)
					esf:Destroy()
					if ctx.vivo() then
						ctx.acertar(alvo, 4.5, ctx.dano * 1.3)
					end
				end)
				voo:Play()
				task.wait(0.45 + i * 0.05)
			end
		end

		-- 3) Chuva de Pregos
		function habilidades.pregos()
			ctx.aviso("Chuva de Pregos!")
			pose("pregos")
			local centro = posHeroi()
			if not centro then
				return
			end
			local pontos = { centro }
			for _ = 1, 5 do
				local a = math.random() * math.pi * 2
				local r = 3 + math.random() * 5
				table.insert(pontos, centro + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r))
			end
			local marcas = {}
			for _, p in ipairs(pontos) do
				local d = disco(p + Vector3.new(0, 0.1, 0), 3.2, VERMELHO, 0.45)
				table.insert(marcas, d)
			end
			ctx.atacar()
			task.wait(1.2)
			pose("pregosSolta")
			local jaAcertou = false -- cada chuva acerta o herói no máximo uma vez
			for i, p in ipairs(pontos) do
				marcas[i]:Destroy()
				if not ctx.vivo() then
					continue
				end
				local prego = peca({
					Size = Vector3.new(0.8, 9, 0.8),
					CFrame = CFrame.new(p + Vector3.new(0, 30, 0)),
					Color = Color3.fromRGB(30, 28, 36),
					Material = Enum.Material.Metal,
				})
				local queda =
					TweenService:Create(prego, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
						CFrame = CFrame.new(p + Vector3.new(0, 3.5, 0)),
					})
				queda.Completed:Connect(function()
					local poeira = peca({
						Shape = Enum.PartType.Ball,
						Size = Vector3.new(1, 1, 1),
						Position = p + Vector3.new(0, 0.5, 0),
						Color = VERMELHO,
						Transparency = 0.3,
					})
					TweenService:Create(poeira, TweenInfo.new(0.3), { Size = Vector3.new(7, 2, 7), Transparency = 1 })
						:Play()
					Debris:AddItem(poeira, 0.35)
					if ctx.vivo() and not jaAcertou then
						jaAcertou = ctx.acertar(p, 3.2, ctx.dano * 2.2)
					end
				end)
				queda:Play()
				Debris:AddItem(prego, 1.6)
				task.wait(0.08)
			end
		end

		-- Teleporte: gira e some numa fumaça, aparece em outro canto da arena
		local function fumaca(pos)
			local f = peca({
				Shape = Enum.PartType.Ball,
				Size = Vector3.new(6, 6, 6),
				Position = pos + Vector3.new(0, 3, 0),
				Color = Color3.fromRGB(60, 40, 80),
				Material = Enum.Material.SmoothPlastic,
				Transparency = 0.2,
			})
			TweenService:Create(f, TweenInfo.new(0.5), { Size = Vector3.new(12, 12, 12), Transparency = 1 }):Play()
			Debris:AddItem(f, 0.55)
		end
		-- 4) Chuva de Meteoros (Madaro): meteoros caem em volta do herói, com círculo de aviso
		function habilidades.meteoros()
			ctx.aviso("Chuva de Meteoros!")
			pose("pregos")
			local centro = posHeroi()
			if not centro then
				return
			end
			local pontos = { centro }
			for _ = 1, 4 do
				local a = math.random() * math.pi * 2
				local r = 3 + math.random() * 6
				table.insert(pontos, centro + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r))
			end
			local marcas = {}
			for _, p in ipairs(pontos) do
				table.insert(marcas, disco(p + Vector3.new(0, 0.1, 0), 4, LARANJA, 0.45))
			end
			ctx.atacar()
			task.wait(1.1)
			pose("pregosSolta")
			local jaAcertou = false
			for i, p in ipairs(pontos) do
				marcas[i]:Destroy()
				if not ctx.vivo() then
					continue
				end
				local pedra = peca({
					Shape = Enum.PartType.Ball,
					Size = Vector3.new(3, 3, 3),
					Position = p + Vector3.new(-14, 40, 10),
					Color = LARANJA,
				})
				luz(pedra, LARANJA, 20)
				local queda = TweenService:Create(
					pedra,
					TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
					{ Position = p + Vector3.new(0, 1, 0) }
				)
				queda.Completed:Connect(function()
					pedra:Destroy()
					local boom = peca({
						Shape = Enum.PartType.Ball,
						Size = Vector3.new(2, 2, 2),
						Position = p + Vector3.new(0, 1, 0),
						Color = LARANJA,
						Transparency = 0.2,
					})
					TweenService:Create(boom, TweenInfo.new(0.35), { Size = Vector3.new(10, 10, 10), Transparency = 1 })
						:Play()
					Debris:AddItem(boom, 0.4)
					if ctx.vivo() and not jaAcertou then
						jaAcertou = ctx.acertar(p, 4, ctx.dano * 2.4)
					end
				end)
				queda:Play()
				Debris:AddItem(pedra, 1)
				task.wait(0.14)
			end
		end

		-- 5) Muralha de Fogo (Madaro): uma parede de fogo sai dele e varre o caminho até o herói
		function habilidades.muralha()
			ctx.aviso("Muralha de Fogo!")
			pose("esferas")
			local alvo = posHeroi()
			if not alvo then
				return
			end
			local inicio = Vector3.new(base.X, ctx.chao, base.Z)
			local dir = (alvo - inicio) * XZ
			dir = dir.Magnitude > 0.5 and dir.Unit or Vector3.new(0, 0, 1)
			local largura, alcance = 14, 30
			-- aviso: corredor vermelho no chão
			local corredor = peca({
				Size = Vector3.new(largura, 0.15, alcance),
				CFrame = CFrame.lookAt(
					inicio + dir * (alcance / 2) + Vector3.new(0, 0.1, 0),
					inicio + dir * alcance + Vector3.new(0, 0.1, 0)
				),
				Color = VERMELHO,
				Transparency = 0.6,
			})
			task.wait(0.9)
			corredor:Destroy()
			if not ctx.vivo() then
				return
			end
			ctx.atacar()
			pose("pregosSolta")
			local parede = peca({
				Size = Vector3.new(largura, 7, 1.4),
				Color = LARANJA,
				Transparency = 0.15,
			})
			luz(parede, LARANJA, 24)
			local fogo = Instance.new("Fire")
			fogo.Size = 12
			fogo.Heat = 15
			fogo.Color = LARANJA
			fogo.SecondaryColor = Color3.fromRGB(255, 220, 90)
			fogo.Parent = parede
			local jaAcertou = false
			local t0 = os.clock()
			local tempo = 1.2
			local conParede
			conParede = RunService.Heartbeat:Connect(function()
				local a = math.min(1, (os.clock() - t0) / tempo)
				local pos = inicio + dir * (2 + (alcance - 2) * a) + Vector3.new(0, 3.5, 0)
				parede.CFrame = CFrame.lookAt(pos, pos + dir)
				local raiz = ctx.raizHeroi()
				if raiz and not jaAcertou and ctx.vivo() then
					local rel = (raiz.Position - pos) * XZ
					if math.abs(rel:Dot(dir)) < 1.6 and math.abs(rel:Dot(dir:Cross(Vector3.yAxis))) < largura / 2 then
						jaAcertou = ctx.acertar(raiz.Position, 1, ctx.dano * 2)
					end
				end
				if a >= 1 then
					conParede:Disconnect()
					TweenService:Create(parede, TweenInfo.new(0.3), { Transparency = 1 }):Play()
					fogo.Enabled = false
					Debris:AddItem(parede, 0.6)
				end
			end)
		end

		local function teleportar()
			pose("sumir")
			task.wait(0.25)
			fumaca(base)
			local a = math.random() * math.pi * 2
			local rMin = math.min(8, rMax * 0.6)
			local r = rMin + math.random() * (rMax - rMin)
			base = Vector3.new(centroLuta.X + math.cos(a) * r, base.Y, centroLuta.Z + math.sin(a) * r)
			fumaca(base)
			pose("surgir")
		end

		local ordem = { "repulsao", "esferas", "pregos" }
		if m:GetAttribute("Modelo") == "madaro" then
			ordem = { "meteoros", "muralha", "repulsao" } -- habilidades próprias do Madaro
		end
		local ultima
		task.wait(1.4) -- termina o rugido
		ocupado = false
		task.wait(0.6) -- respiro antes da primeira habilidade
		while ctx.vivo() and m.Parent do
			task.wait(3.5 + math.random() * 2)
			if not ctx.vivo() then
				break
			end
			ocupado = true
			if math.random() < 0.35 then
				teleportar()
				task.wait(0.6)
			end
			local escolha
			repeat
				escolha = ordem[math.random(#ordem)]
			until escolha ~= ultima
			ultima = escolha
			habilidades[escolha]()
			task.wait(0.4)
			ocupado = false
		end
	end)
end

return Chefe
