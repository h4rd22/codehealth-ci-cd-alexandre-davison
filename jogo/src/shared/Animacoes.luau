-- Animacoes: animação "feita em código" (procedural), sem subir animação na conta do dono.
-- Mexe nas juntas (Motor6D) dos bonecos R6 e R15, por cima das animações padrão do Roblox.
-- Roda só na tela do jogador (cliente): cada um vê o próprio combate bem vivo.
--
-- Pose = { junta = { rx, ry, rz, tx, ty, tz } }  (graus e studs) ou { junta = CFrame }
--   no espaço da peça "pai" da junta (o tronco, para braços e cabeça):
--   rx > 0 levanta o braço para a frente / inclina o corpo para trás
--   ry > 0 gira para a esquerda
--   rz > 0 abre o braço direito para o lado (o esquerdo abre com rz < 0)
--   tz < 0 empurra para a frente
-- Juntas: raiz, tronco, pescoco, ombroD, ombroE, cotoveloD, cotoveloE, quadrilD, quadrilE, joelhoD, joelhoE
--
-- Também tem efeitos visuais prontos (anel de choque, círculo mágico, rastro de espada, brilhos).
-- E a ponte com as magias: Animacoes.conjurar(player, "gelo" | "raio" | "fogo", alvo?) pode ser
-- chamado do servidor ou do cliente; o AnimHeroi (cliente) toca a pose e o círculo mágico.

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Animacoes = {}

------------------------------------------------------------------------
-- Ponte com as habilidades (servidor ou cliente)
------------------------------------------------------------------------
local contadorConjurar = 0
function Animacoes.conjurar(player, tipo, alvo)
	contadorConjurar += 1
	if typeof(alvo) == "Vector3" then
		player:SetAttribute("AnimConjurarAlvo", alvo)
	end
	player:SetAttribute("AnimConjurar", tostring(tipo) .. "|" .. contadorConjurar)
end

------------------------------------------------------------------------
-- Juntas
------------------------------------------------------------------------
local NOMES = {
	raiz = { "RootJoint", "Root" },
	tronco = { false, "Waist" },
	pescoco = { "Neck", "Neck" },
	ombroD = { "Right Shoulder", "RightShoulder" },
	ombroE = { "Left Shoulder", "LeftShoulder" },
	cotoveloD = { false, "RightElbow" },
	cotoveloE = { false, "LeftElbow" },
	quadrilD = { "Right Hip", "RightHip" },
	quadrilE = { "Left Hip", "LeftHip" },
	joelhoD = { false, "RightKnee" },
	joelhoE = { false, "LeftKnee" },
}

local function paraCFrame(v)
	if typeof(v) == "CFrame" then
		return v
	end
	return CFrame.new(v[4] or 0, v[5] or 0, v[6] or 0)
		* CFrame.Angles(math.rad(v[1] or 0), math.rad(v[2] or 0), math.rad(v[3] or 0))
end

-- Converte { junta = {rx...} } em { junta = CFrame }
function Animacoes.pose(t)
	local p = {}
	for k, v in pairs(t) do
		p[k] = paraCFrame(v)
	end
	return p
end

-- Mistura uma pose com "nada" (0 = parado, 1 = pose inteira)
function Animacoes.peso(pose, a)
	if a >= 0.999 then
		return pose
	end
	local p = {}
	for k, v in pairs(pose) do
		p[k] = CFrame.new():Lerp(v, a)
	end
	return p
end

------------------------------------------------------------------------
-- Clipes: lista de quadros-chave { tempo, pose, estilo? }
-- estilo do trecho que CHEGA no quadro: "suave" (padrão), "sai" (rápido no começo),
-- "entra" (rápido no fim), "linear", "volta" (passa do ponto e volta, estilo mola)
------------------------------------------------------------------------
local function suavizar(a, estilo)
	if estilo == "linear" then
		return a
	elseif estilo == "sai" then
		return 1 - (1 - a) * (1 - a)
	elseif estilo == "entra" then
		return a * a
	elseif estilo == "volta" then
		local c1, c3 = 1.70158, 2.70158
		return 1 + c3 * (a - 1) ^ 3 + c1 * (a - 1) ^ 2
	end
	return 0.5 - math.cos(a * math.pi) / 2
end

function Animacoes.clipe(quadros)
	local lista = {}
	local juntas = {}
	for _, q in ipairs(quadros) do
		local pose = Animacoes.pose(q[2] or {})
		for k in pairs(pose) do
			juntas[k] = true
		end
		table.insert(lista, { t = q[1], pose = pose, estilo = q[3] })
	end
	return { quadros = lista, juntas = juntas, dur = lista[#lista].t }
end

local function avaliar(clipe, t)
	local q = clipe.quadros
	local b = #q
	for i = 2, #q do
		if t < q[i].t then
			b = i
			break
		end
	end
	local qa, qb = q[math.max(1, b - 1)], q[b]
	local a = 1
	if qb.t > qa.t then
		a = suavizar(math.clamp((t - qa.t) / (qb.t - qa.t), 0, 1), qb.estilo)
	end
	local saida = {}
	for k in pairs(clipe.juntas) do
		local ca = qa.pose[k] or CFrame.identity
		local cb = qb.pose[k] or CFrame.identity
		saida[k] = ca:Lerp(cb, a)
	end
	return saida
end

------------------------------------------------------------------------
-- Bonecos animados
-- Mexemos no C0 da junta (a mudança só existe na tela deste jogador).
-- Se outra coisa mudar o C0 (ex.: o boneco crescer), pegamos o novo valor como base.
------------------------------------------------------------------------
local rigs = {}
local laco

local function atualizar()
	local agora = os.clock()
	for m, r in pairs(rigs) do
		if not m.Parent then
			rigs[m] = nil
			continue
		end
		local dt = agora - r.ultimo
		r.ultimo = agora
		-- soma as camadas ativas
		local soma = {}
		for nome, c in pairs(r.camadas) do
			local t = agora - c.t0
			local pose
			if c.clipe then
				if t >= c.clipe.dur then
					r.camadas[nome] = nil
					continue
				end
				pose = avaliar(c.clipe, t * 1)
			else
				-- camada contínua: peso entra/sai suave
				c.peso += (c.alvo - c.peso) * math.min(1, dt * (c.rapidez or 8))
				if c.alvo == 0 and c.peso < 0.01 then
					r.camadas[nome] = nil
					continue
				end
				pose = c.fn(t, dt, c)
				if pose then
					pose = Animacoes.peso(pose, c.peso)
				end
			end
			if pose then
				local forca = c.forca or 1
				for k, cf in pairs(pose) do
					local j = r.juntas[k]
					if j then
						if forca ~= 1 then
							cf = CFrame.new():Lerp(cf, forca)
						end
						soma[j] = (soma[j] or CFrame.identity) * cf
					end
				end
			end
		end
		-- aplica nas juntas
		local escala = r.escalaFixa or (m:IsA("Model") and m:GetScale()) or 1
		for _, j in ipairs(r.lista) do
			local motor = j.motor
			if not motor.Parent then
				continue
			end
			local off = soma[j]
			if j.escrito and not motor.C0:FuzzyEq(j.escrito, 1e-4) then
				j.base = motor.C0 -- alguém mudou o C0 por fora (crescer, trocar corpo...)
			end
			if off then
				local base = j.base
				local novo = CFrame.new(off.Position * escala)
					* CFrame.new(base.Position)
					* off.Rotation
					* base.Rotation
				motor.C0 = novo
				j.escrito = novo
			elseif j.escrito then
				motor.C0 = j.base
				j.escrito = nil
			end
		end
	end
	if next(rigs) == nil and laco then
		laco:Disconnect()
		laco = nil
	end
end

-- Prepara o boneco (R6 ou R15). Retorna nil se ele não tiver juntas.
function Animacoes.rig(m)
	local r = rigs[m]
	if r then
		return r
	end
	local hum = m:FindFirstChildWhichIsA("Humanoid", true)
	local r15 = hum ~= nil and hum.RigType == Enum.HumanoidRigType.R15
	local motores = {}
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("Motor6D") and not motores[d.Name] then
			motores[d.Name] = d
		end
	end
	local juntas, lista = {}, {}
	for nome, par in pairs(NOMES) do
		local nm = par[r15 and 2 or 1]
		local motor = nm and motores[nm]
		if not motor and not hum then
			motor = (par[1] and motores[par[1]]) or (par[2] and motores[par[2]])
		end
		if motor then
			local j = { motor = motor, base = motor.C0 }
			juntas[nome] = j
			table.insert(lista, j)
		end
	end
	if not juntas.raiz then
		return nil
	end
	juntas.tronco = juntas.tronco or juntas.raiz -- R6 não tem cintura: o corpo todo inclina
	r = { modelo = m, juntas = juntas, lista = lista, camadas = {}, ultimo = os.clock(), r15 = r15 }
	rigs[m] = r
	if not laco and RunService:IsClient() then
		laco = RunService.RenderStepped:Connect(atualizar)
	end
	return r
end

-- Toca um clipe uma vez. nome = "canal" (um clipe novo no mesmo canal substitui o anterior).
function Animacoes.tocar(m, clipe, nome, forca)
	local r = Animacoes.rig(m)
	if not r then
		return
	end
	r.camadas[nome or "acao"] = { clipe = clipe, t0 = os.clock(), forca = forca }
end

-- Camada contínua (correr inclinado, flutuar, pose ameaçadora...). fn(t, dt, camada) -> pose
function Animacoes.manter(m, nome, fn, rapidez)
	local r = Animacoes.rig(m)
	if not r then
		return
	end
	local c = r.camadas[nome]
	if c and not c.clipe then
		c.alvo = 1
		c.fn = fn
		return
	end
	r.camadas[nome] = { fn = fn, t0 = os.clock(), peso = 0, alvo = 1, rapidez = rapidez }
end

function Animacoes.soltar(m, nome)
	local r = rigs[m]
	local c = r and r.camadas[nome]
	if c then
		if c.clipe then
			r.camadas[nome] = nil
		else
			c.alvo = 0
		end
	end
end

function Animacoes.tocando(m, nome)
	local r = rigs[m]
	return r ~= nil and r.camadas[nome] ~= nil
end

function Animacoes.esquecer(m)
	rigs[m] = nil
end

------------------------------------------------------------------------
-- Efeitos visuais (só no cliente)
------------------------------------------------------------------------
local pastaFx
local function fx()
	if not pastaFx or not pastaFx.Parent then
		pastaFx = workspace:FindFirstChild("EfeitosAnim") or Instance.new("Folder")
		pastaFx.Name = "EfeitosAnim"
		pastaFx.Parent = workspace
	end
	return pastaFx
end
Animacoes.pastaFx = fx

local function pecaFx(tam, cor, forma)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.Neon
	p.Color = cor
	p.Size = tam
	if forma then
		p.Shape = forma
	end
	return p
end
Animacoes.pecaFx = pecaFx

-- Roda fn(a) a cada quadro, com a indo de 0 a 1 em "tempo" segundos; no fim chama fim()
function Animacoes.durante(tempo, fn, fim)
	local t0 = os.clock()
	local con
	con = RunService.Heartbeat:Connect(function()
		local a = math.min((os.clock() - t0) / tempo, 1)
		local ok = pcall(fn, a)
		if a >= 1 or not ok then
			con:Disconnect()
			if fim then
				fim()
			end
		end
	end)
	return con
end

-- Anel de choque no chão (ou em pé, se "cf" vier girado)
local MALHA_ANEL = "rbxassetid://3270017"
function Animacoes.anel(cf, cor, raio, tempo, grossura)
	if typeof(cf) == "Vector3" then
		cf = CFrame.new(cf)
	end
	tempo = tempo or 0.45
	local p = pecaFx(Vector3.new(1, 1, 1), cor)
	p.CFrame = cf * CFrame.Angles(math.rad(90), 0, 0)
	p.Transparency = 0.05
	local malha = Instance.new("SpecialMesh")
	malha.MeshType = Enum.MeshType.FileMesh
	malha.MeshId = MALHA_ANEL
	local g = grossura or 1
	malha.Scale = Vector3.new(0.4, 0.4, g)
	malha.Parent = p
	p.Parent = fx()
	local d = raio * 0.95
	TweenService:Create(malha, TweenInfo.new(tempo, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Scale = Vector3.new(d, d, g * 2.5),
	}):Play()
	TweenService:Create(p, TweenInfo.new(tempo, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Transparency = 1,
	}):Play()
	Debris:AddItem(p, tempo + 0.05)
	return p
end

-- Esfera de luz que cresce e some (clarão)
function Animacoes.clarao(pos, cor, tamanho, tempo, luz)
	tempo = tempo or 0.3
	local p = pecaFx(Vector3.new(1, 1, 1), cor, Enum.PartType.Ball)
	p.Position = pos
	p.Transparency = 0.1
	p.Parent = fx()
	if luz then
		local l = Instance.new("PointLight")
		l.Color = cor
		l.Range = luz
		l.Brightness = 4
		l.Parent = p
		TweenService:Create(l, TweenInfo.new(tempo), { Brightness = 0 }):Play()
	end
	TweenService:Create(p, TweenInfo.new(tempo, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.one * tamanho,
		Transparency = 1,
	}):Play()
	Debris:AddItem(p, tempo + 0.05)
	return p
end

-- Estrelinhas/faíscas espirrando de um ponto
function Animacoes.brilhos(pos, cor, quantidade, velocidade, textura)
	local a = Instance.new("Attachment")
	a.WorldPosition = pos
	a.Parent = workspace.Terrain
	local e = Instance.new("ParticleEmitter")
	e.Color = ColorSequence.new(Color3.new(1, 1, 1), cor)
	e.LightEmission = 1
	e.LightInfluence = 0
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.9), NumberSequenceKeypoint.new(1, 0) })
	e.Transparency = NumberSequence.new(0, 1)
	e.Lifetime = NumberRange.new(0.35, 0.8)
	e.Speed = NumberRange.new((velocidade or 14) * 0.5, velocidade or 14)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Drag = 4
	e.Rotation = NumberRange.new(0, 360)
	e.RotSpeed = NumberRange.new(-200, 200)
	if textura then
		e.Texture = textura
	end
	e.Enabled = false
	e.Parent = a
	e:Emit(quantidade or 20)
	Debris:AddItem(a, 1)
end

-- Rastro de golpe: fita de luz em arco. base = centro do arco; o arco fica no plano XZ da base.
-- a0 -> a1 em graus (0 = frente, positivo = para a direita). Varre de a0 até a1 e some.
function Animacoes.arco(base, raio, a0, a1, cor, largura, tempo)
	tempo = tempo or 0.28
	local n = 14
	local partes, cfs = {}, {}
	for i = 1, n do
		local f = (i - 0.5) / n
		local ang = math.rad(a0 + (a1 - a0) * f)
		local passoAng = math.rad(math.abs(a1 - a0) / n)
		local ponto = Vector3.new(math.sin(ang) * raio, 0, -math.cos(ang) * raio)
		local tangente = Vector3.new(math.cos(ang), 0, math.sin(ang)) * (a1 >= a0 and 1 or -1)
		local cfLocal = CFrame.lookAt(ponto, ponto + tangente, Vector3.yAxis)
		local afina = math.sin(f * math.pi) * 0.7 + 0.3 * f -- mais grosso no fim do golpe
		local p = pecaFx(Vector3.new(largura * afina, 0.08, raio * passoAng * 1.15), cor)
		p.CFrame = base * cfLocal
		p.Transparency = 1
		p.Parent = fx()
		partes[i] = p
		cfs[i] = f
	end
	local varre = tempo * 0.35
	Animacoes.durante(tempo, function(a)
		local t = a * tempo
		for i, p in ipairs(partes) do
			local nasce = cfs[i] * varre
			if t < nasce then
				p.Transparency = 1
			else
				local vida = (t - nasce) / (tempo - nasce)
				p.Transparency = 0.05 + vida * 0.95
			end
		end
	end, function()
		for _, p in ipairs(partes) do
			p:Destroy()
		end
	end)
end

-- Círculo mágico no chão: dois anéis, estrela de 6 pontas e runas, girando e sumindo
function Animacoes.circuloMagico(cf, cor, raio, tempo)
	tempo = tempo or 0.7
	local partes, rel = {}, {}
	local function add(tam, cfl)
		local p = pecaFx(tam, cor)
		p.Transparency = 1
		p.Parent = fx()
		table.insert(partes, p)
		table.insert(rel, cfl)
	end
	local function anel(r, n, grossura)
		for i = 1, n do
			local a = (i / n) * math.pi * 2
			local comp = 2 * math.pi * r / n * 1.08
			add(
				Vector3.new(grossura, 0.06, comp),
				CFrame.new(math.cos(a) * r, 0, math.sin(a) * r) * CFrame.Angles(0, -a, 0)
			)
		end
	end
	anel(raio, 22, 0.16)
	anel(raio * 0.72, 16, 0.1)
	-- estrela de 6 pontas: dois triângulos
	local ri = raio * 0.72
	for tri = 0, 1 do
		for i = 0, 2 do
			local a1 = (i / 3) * math.pi * 2 + tri * math.pi / 3
			local a2 = ((i + 1) / 3) * math.pi * 2 + tri * math.pi / 3
			local p1 = Vector3.new(math.cos(a1) * ri, 0, math.sin(a1) * ri)
			local p2 = Vector3.new(math.cos(a2) * ri, 0, math.sin(a2) * ri)
			add(Vector3.new(0.1, 0.06, (p2 - p1).Magnitude), CFrame.lookAt((p1 + p2) / 2, p2))
		end
	end
	-- runas entre os anéis
	for i = 1, 8 do
		local a = (i / 8) * math.pi * 2 + 0.2
		local r = raio * 0.86
		add(
			Vector3.new(0.32, 0.06, 0.32),
			CFrame.new(math.cos(a) * r, 0, math.sin(a) * r) * CFrame.Angles(0, a + 0.785, 0)
		)
	end
	local luz = pecaFx(Vector3.new(0.2, 0.2, 0.2), cor)
	luz.Transparency = 1
	luz.CFrame = cf * CFrame.new(0, 1, 0)
	luz.Parent = fx()
	local l = Instance.new("PointLight")
	l.Color = cor
	l.Range = raio * 3
	l.Brightness = 3
	l.Parent = luz
	local lista = table.create(#partes)
	Animacoes.durante(tempo, function(a)
		local esc = 0.35 + 0.65 * suavizar(math.min(a * 4, 1), "volta")
		local giro = CFrame.Angles(0, a * 2.2, 0)
		local transp = a < 0.6 and 0.05 or (0.05 + (a - 0.6) / 0.4 * 0.95)
		for i, p in ipairs(partes) do
			local c = rel[i]
			lista[i] = cf * giro * CFrame.new(c.Position * esc) * c.Rotation
			p.Transparency = transp
		end
		workspace:BulkMoveTo(partes, lista, Enum.BulkMoveMode.FireCFrameChanged)
		l.Brightness = 3 * (1 - a)
	end, function()
		for _, p in ipairs(partes) do
			p:Destroy()
		end
		luz:Destroy()
	end)
end

-- Raio em zigue-zague entre dois pontos
function Animacoes.relampago(de, ate, cor, tempo, espessura)
	tempo = tempo or 0.18
	local pontos = { de }
	local n = 6
	local dir = ate - de
	local lado = dir:Cross(Vector3.yAxis)
	if lado.Magnitude < 0.01 then
		lado = Vector3.xAxis
	end
	lado = lado.Unit
	local outro = dir.Magnitude > 0 and dir.Unit:Cross(lado) or Vector3.zAxis
	for i = 1, n - 1 do
		local desvio = dir.Magnitude * 0.08
		table.insert(
			pontos,
			de + dir * (i / n) + lado * (math.random() * 2 - 1) * desvio + outro * (math.random() * 2 - 1) * desvio
		)
	end
	table.insert(pontos, ate)
	for i = 1, #pontos - 1 do
		local a, b = pontos[i], pontos[i + 1]
		local p = pecaFx(Vector3.new(espessura or 0.25, espessura or 0.25, (b - a).Magnitude), cor)
		p.CFrame = CFrame.lookAt((a + b) / 2, b)
		p.Parent = fx()
		TweenService:Create(p, TweenInfo.new(tempo), { Transparency = 1 }):Play()
		Debris:AddItem(p, tempo + 0.05)
	end
end

return Animacoes
