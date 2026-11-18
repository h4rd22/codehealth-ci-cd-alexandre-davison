-- VFX: toca os efeitos prontos (grátis) guardados em ReplicatedStorage.Arte.VFX.
-- Categorias: Fogo, Gelo, Raio, Magia, Golpes, Auras. Só roda na tela do jogador.
-- Se o efeito não existir (lugar antigo, nome trocado), não faz nada: os efeitos em código continuam.
--
--   VFX.estouro("Golpes/BasicHit", cf, { anexo = "AttachmentBig", escala = 1.5 })  rajada de partículas
--   VFX.colocar("Gelo/icespike", cf, { escala = 0.3, tempo = 1.5 })               objeto 3D (malhas, beams)
--   VFX.grudar("Auras/SSJ", parte, 3)                                               aura presa numa parte
--   VFX.corpo("Raio/Electrocuted", modelo, 1)                                       efeito no corpo todo

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local VFX = {}

local cache = {}
function VFX.achar(caminho)
	local v = cache[caminho]
	if v and v.Parent then
		return v
	end
	local arte = ReplicatedStorage:FindFirstChild("Arte")
	local a = arte and arte:FindFirstChild("VFX")
	for parte in string.gmatch(caminho, "[^/]+") do
		a = a and a:FindFirstChild(parte)
	end
	cache[caminho] = a
	return a
end

local function pasta()
	local f = workspace:FindFirstChild("EfeitosAnim")
	if not f then
		f = Instance.new("Folder")
		f.Name = "EfeitosAnim"
		f.Parent = workspace
	end
	return f
end

local function escalarSeq(s, k)
	local pts = {}
	for _, p in ipairs(s.Keypoints) do
		table.insert(pts, NumberSequenceKeypoint.new(p.Time, p.Value * k, p.Envelope * k))
	end
	return NumberSequence.new(pts)
end

local function escalarEmissor(e, k)
	if k == 1 then
		return
	end
	e.Size = escalarSeq(e.Size, k)
	e.Speed = NumberRange.new(e.Speed.Min * k, e.Speed.Max * k)
	e.Acceleration *= k
end

-- quantas partículas soltar de uma vez para um emissor feito para ficar ligado
local function quantas(e, mult)
	local n = e:GetAttribute("EmitCount")
	if typeof(n) ~= "number" then
		n = math.clamp(math.ceil(e.Rate * 0.12), 1, 30)
	end
	return math.max(1, math.floor(n * (mult or 1) + 0.5))
end

local function emissoresDe(origem, anexo)
	local lista = {}
	for _, d in ipairs(origem:GetDescendants()) do
		if d:IsA("ParticleEmitter") and (not anexo or (d.Parent and d.Parent.Name == anexo)) then
			table.insert(lista, d)
		end
	end
	return lista
end

-- Rajada: copia só as partículas do efeito para um ponto e solta todas de uma vez
-- opts: anexo (só emissores dentro desse Attachment), escala, mult (mais/menos partículas), cor
function VFX.estouro(caminho, cf, opts)
	opts = opts or {}
	local origem = VFX.achar(caminho)
	if not origem then
		return false
	end
	if typeof(cf) == "Vector3" then
		cf = CFrame.new(cf)
	end
	local base = Instance.new("Part")
	base.Anchored = true
	base.CanCollide = false
	base.CanQuery = false
	base.CanTouch = false
	base.Transparency = 1
	base.Size = Vector3.one * 0.2
	base.CFrame = cf
	local a = Instance.new("Attachment")
	a.Parent = base
	base.Parent = pasta()
	local vida = 0
	for _, e in ipairs(emissoresDe(origem, opts.anexo)) do
		local c = e:Clone()
		c.Enabled = false
		escalarEmissor(c, opts.escala or 1)
		if opts.cor then
			c.Color = ColorSequence.new(opts.cor)
		end
		c.Parent = a
		local atraso = c:GetAttribute("EmitDelay")
		local n = quantas(c, opts.mult)
		if typeof(atraso) == "number" and atraso > 0 then
			task.delay(atraso, function()
				c:Emit(n)
			end)
		else
			c:Emit(n)
		end
		vida = math.max(vida, c.Lifetime.Max + (typeof(atraso) == "number" and atraso or 0))
	end
	Debris:AddItem(base, vida + 0.3)
	return true
end

-- Coloca o efeito inteiro (malhas, beams, partículas) num lugar por um tempo.
-- Retorna o clone (Model) para quem chamou mexer (mover, crescer...). Some sozinho no fim.
-- opts: escala, tempo (s ligado), esconderPecas (deixa as peças invisíveis, só efeitos)
function VFX.colocar(caminho, cf, opts)
	opts = opts or {}
	local origem = VFX.achar(caminho)
	if not origem then
		return nil
	end
	local m
	if origem:IsA("Model") then
		m = origem:Clone()
	else
		m = Instance.new("Model")
		m.Name = origem.Name
		local c = origem:Clone()
		c.Parent = m
		m.PrimaryPart = c:IsA("BasePart") and c or nil
	end
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
			if opts.esconderPecas then
				d.Transparency = 1
			end
		elseif d:IsA("Script") or d:IsA("LocalScript") then
			d:Destroy()
		end
	end
	if typeof(cf) == "Vector3" then
		cf = CFrame.new(cf)
	end
	m:PivotTo(cf)
	if opts.escala and opts.escala ~= 1 then
		m:ScaleTo(m:GetScale() * opts.escala)
	end
	m.Parent = pasta()
	local tempo = opts.tempo or 1
	local vida = 0
	for _, e in ipairs(emissoresDe(m)) do
		vida = math.max(vida, e.Lifetime.Max)
	end
	task.delay(tempo, function()
		for _, d in ipairs(m:GetDescendants()) do
			if d:IsA("ParticleEmitter") or d:IsA("Beam") or d:IsA("Trail") or d:IsA("Light") then
				d.Enabled = false
			end
		end
	end)
	Debris:AddItem(m, tempo + vida + 0.2)
	return m
end

-- Gruda as partículas do efeito numa parte (aura no herói, fogo no inimigo...) por "tempo" segundos.
-- Retorna uma função para parar antes.
function VFX.grudar(caminho, parte, tempo, opts)
	opts = opts or {}
	local origem = VFX.achar(caminho)
	if not origem or not parte then
		return function() end
	end
	local a = Instance.new("Attachment")
	a.Name = "VFX_" .. origem.Name
	a.Position = opts.deslocamento or Vector3.zero
	a.Parent = parte
	local vida = 0
	for _, e in ipairs(emissoresDe(origem, opts.anexo)) do
		local c = e:Clone()
		c.Enabled = true
		escalarEmissor(c, opts.escala or 1)
		c.Parent = a
		vida = math.max(vida, c.Lifetime.Max)
	end
	local parado = false
	local function parar()
		if parado then
			return
		end
		parado = true
		for _, c in ipairs(a:GetChildren()) do
			if c:IsA("ParticleEmitter") then
				c.Enabled = false
			end
		end
		Debris:AddItem(a, vida + 0.1)
	end
	if tempo then
		task.delay(tempo, parar)
	end
	return parar
end

-- Peças do corpo equivalentes entre R6 (nomes do efeito) e R15
local R15 = {
	Torso = { "UpperTorso", "Torso" },
	Head = { "Head" },
	["Left Arm"] = { "LeftUpperArm", "Left Arm", "LeftUpperArm" },
	["Right Arm"] = { "RightUpperArm", "Right Arm" },
	["Left Leg"] = { "LeftUpperLeg", "Left Leg" },
	["Right Leg"] = { "RightUpperLeg", "Right Leg" },
	HumanoidRootPart = { "HumanoidRootPart" },
}

-- Copia os efeitos que o pacote tem em cada parte do corpo (ex.: raios no corpo inteiro)
function VFX.corpo(caminho, modelo, tempo, opts)
	local origem = VFX.achar(caminho)
	if not origem or not modelo then
		return function() end
	end
	local paradas = {}
	for _, parteOrigem in ipairs(origem:GetDescendants()) do
		if not parteOrigem:IsA("BasePart") then
			continue
		end
		local nomes = R15[parteOrigem.Name] or { parteOrigem.Name }
		local destino
		for _, n in ipairs(nomes) do
			destino = modelo:FindFirstChild(n, true)
			if destino and destino:IsA("BasePart") then
				break
			end
			destino = nil
		end
		if destino then
			local a = Instance.new("Attachment")
			a.Name = "VFXCorpo"
			a.Parent = destino
			for _, e in ipairs(parteOrigem:GetDescendants()) do
				if e:IsA("ParticleEmitter") then
					local c = e:Clone()
					c.Enabled = true
					escalarEmissor(c, (opts and opts.escala) or 1)
					c.Parent = a
				end
			end
			table.insert(paradas, a)
		end
	end
	local function parar()
		for _, a in ipairs(paradas) do
			for _, c in ipairs(a:GetChildren()) do
				if c:IsA("ParticleEmitter") then
					c.Enabled = false
				end
			end
			Debris:AddItem(a, 1.2)
		end
		table.clear(paradas)
	end
	if tempo then
		task.delay(tempo, parar)
	end
	return parar
end

return VFX
