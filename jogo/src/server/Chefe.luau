-- Chefe: comportamento do chefe final do ato (Pen).
-- Ele flutua, olha para o herói, se teleporta e usa 3 habilidades com aviso no chão:
--   Repulsão Divina  - onda de choque em volta dele que empurra o herói
--   Esferas Negras   - 3 esferas que voam até onde o herói estava
--   Chuva de Pregos  - círculos vermelhos no chão que viram pregos caindo do céu

local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Chefe = {}

local ROXO = Color3.fromRGB(180, 90, 255)
local VERMELHO = Color3.fromRGB(255, 60, 70)

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
	-- Entrada: um raio roxo cai do céu onde ele aparece
	local p0 = m:GetPivot().Position
	local relampago = peca({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(120, 6, 6),
		CFrame = CFrame.new(p0 + Vector3.new(0, 60, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = ROXO,
		Transparency = 0.1,
	})
	luz(relampago, ROXO, 40)
	TweenService:Create(relampago, TweenInfo.new(0.9), { Size = Vector3.new(120, 0.2, 0.2), Transparency = 1 }):Play()
	Debris:AddItem(relampago, 1)
	local anel = disco(Vector3.new(p0.X, ctx.chao + 0.15, p0.Z), 2, ROXO, 0.2)
	TweenService:Create(anel, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.15, 40, 40),
		Transparency = 1,
	}):Play()
	Debris:AddItem(anel, 0.85)

	task.spawn(function()
		task.wait(0.6) -- espera ele terminar de aparecer
		if not ctx.vivo() then
			return
		end
		local pivo0 = m:GetPivot()
		local base = pivo0.Position
		local rot0 = pivo0.Rotation
		local centroLuta = ctx.centro or Vector3.new(0, base.Y, 0)
		local frente0 = (Vector3.new(centroLuta.X, base.Y, centroLuta.Z) - base) * Vector3.new(1, 0, 1)
		if frente0.Magnitude < 0.1 then
			frente0 = Vector3.new(0, 0, 1)
		end
		frente0 = frente0.Unit
		local alturaExtra = 0
		local t = 0

		-- movimento: flutua e vira para o herói
		task.spawn(function()
			while ctx.vivo() and m.Parent do
				t += 0.05
				local raiz = ctx.raizHeroi()
				local ang = 0
				if raiz then
					local d = (raiz.Position - base) * Vector3.new(1, 0, 1)
					if d.Magnitude > 0.5 then
						d = d.Unit
						ang = math.atan2(frente0.X * d.Z - frente0.Z * d.X, frente0.X * d.X + frente0.Z * d.Z)
					end
				end
				local sobe = 1.2 + math.sin(t * 2) * 0.5 + alturaExtra
				m:PivotTo(CFrame.new(base + Vector3.new(0, sobe, 0)) * CFrame.Angles(0, -ang, 0) * rot0)
				task.wait(0.05)
			end
		end)

		local function posHeroi()
			local raiz = ctx.raizHeroi()
			return raiz and Vector3.new(raiz.Position.X, ctx.chao, raiz.Position.Z)
		end

		local habilidades = {}

		-- 1) Repulsão Divina
		function habilidades.repulsao()
			ctx.aviso("Repulsão Divina!")
			local centro = Vector3.new(base.X, ctx.chao + 0.1, base.Z)
			local raio = 15
			local aviso = disco(centro, 2, ROXO, 0.6)
			TweenService:Create(aviso, TweenInfo.new(1.4), {
				Size = Vector3.new(0.15, raio * 2, raio * 2),
				Transparency = 0.35,
			}):Play()
			alturaExtra = 2.5
			task.wait(1.4)
			if not ctx.vivo() then
				aviso:Destroy()
				return
			end
			ctx.atacar()
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
			alturaExtra = 0
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

		-- Teleporte: some numa fumaça e aparece em outro canto da arena
		local function teleportar()
			local fumaca = peca({
				Shape = Enum.PartType.Ball,
				Size = Vector3.new(6, 6, 6),
				Position = base + Vector3.new(0, 3, 0),
				Color = Color3.fromRGB(60, 40, 80),
				Material = Enum.Material.SmoothPlastic,
				Transparency = 0.2,
			})
			TweenService:Create(fumaca, TweenInfo.new(0.5), { Size = Vector3.new(12, 12, 12), Transparency = 1 }):Play()
			Debris:AddItem(fumaca, 0.55)
			local a = math.random() * math.pi * 2
			local rMax = ctx.raioTeleporte or 14
			local r = math.min(8, rMax * 0.6) + math.random() * (rMax - math.min(8, rMax * 0.6))
			base = Vector3.new(centroLuta.X + math.cos(a) * r, base.Y, centroLuta.Z + math.sin(a) * r)
		end

		local ordem = { "repulsao", "esferas", "pregos" }
		local ultima
		task.wait(2) -- respiro antes da primeira habilidade
		while ctx.vivo() and m.Parent do
			task.wait(3.5 + math.random() * 2)
			if not ctx.vivo() then
				break
			end
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
		end
	end)
end

return Chefe
