-- Habilidades (servidor): pontos, aprender, barra de magias e o lançamento
-- automático das magias no auto-farm, com efeitos elementais:
--   Gelo  = lentidão e congelar (o inimigo para de andar e de bater)
--   Raio  = salta entre inimigos e atordoa
--   Fogo  = queimadura (dano por segundo) e explosões em área
-- Os números ficam em ReplicatedStorage.Shared.Habilidades.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Dados = require(Shared:WaitForChild("Habilidades"))

local Hab = {}

-- Animação de conjurar do herói (módulo do Henrique); se não existir, só não anima
local Animacoes
do
	local mod = Shared:FindFirstChild("Animacoes")
	if mod then
		local ok, m = pcall(require, mod)
		Animacoes = ok and m or nil
	end
end

local api -- funções do GameServer (ver Hab.iniciar)
local proxima = {} -- proxima[player][habId] = os.clock() em que a recarga acaba
local recargaGlobal = {} -- recargaGlobal[player] = os.clock()
local ultimoPedido = {}

local function agoraServidor()
	return workspace:GetServerTimeNow()
end

------------------------------------------------------------------------
-- Estado do jogador
------------------------------------------------------------------------
function Hab.garantir(st)
	if st.habilidades == nil then
		st.habilidades = {} -- [id] = nível
	end
	if st.barraHab == nil then
		st.barraHab = {} -- ids das ativas na barra, na ordem de prioridade
	end
	if st.pontosHabilidade == nil then
		local devidos = Dados.PontosIniciais + (st.nivel - 1) * Dados.PontosPorNivel
		st.pontosHabilidade = math.max(0, devidos - Dados.gastos(st.habilidades))
	end
end

-- Chamado a cada nível que o herói sobe
function Hab.ganharNivel(st)
	Hab.garantir(st)
	st.pontosHabilidade += Dados.PontosPorNivel
end

local function nivelDe(st, id)
	return st.habilidades and st.habilidades[id] or 0
end

local function valorPassiva(st, id, campo)
	local n = nivelDe(st, id)
	if n <= 0 then
		return 0
	end
	return Dados.valor(Dados.PorId[id], campo, n)
end

------------------------------------------------------------------------
-- Efeitos de controle nos inimigos (atributos lidos pelo GameServer e pela tela)
------------------------------------------------------------------------
local function ativo(m, atributo)
	return (m:GetAttribute(atributo) or 0) > agoraServidor()
end

-- Multiplicador da velocidade do inimigo (0 = parado)
function Hab.velocidade(m)
	if ativo(m, "CongeladoAte") or ativo(m, "AtordoadoAte") then
		return 0
	end
	if ativo(m, "LentoAte") then
		return 1 - (m:GetAttribute("LentoFrac") or 0.4)
	end
	return 1
end

-- Congelado ou atordoado: não ataca
function Hab.impedido(m)
	return ativo(m, "CongeladoAte") or ativo(m, "AtordoadoAte")
end

local function estender(m, atributo, segundos)
	if m:GetAttribute("Chefe") then
		segundos *= Dados.CCChefe
	end
	local fim = agoraServidor() + segundos
	if fim > (m:GetAttribute(atributo) or 0) then
		m:SetAttribute(atributo, fim)
	end
end

local function deixarLento(m, frac, segundos)
	m:SetAttribute("LentoFrac", math.max(frac, ativo(m, "LentoAte") and (m:GetAttribute("LentoFrac") or 0) or 0))
	local fim = agoraServidor() + segundos
	if fim > (m:GetAttribute("LentoAte") or 0) then
		m:SetAttribute("LentoAte", fim)
	end
end

local function queimar(m, dps, segundos)
	local dpsAtual = ativo(m, "QueimaAte") and (m:GetAttribute("QueimaDps") or 0) or 0
	m:SetAttribute("QueimaDps", math.max(dps, dpsAtual))
	local fim = agoraServidor() + segundos
	if fim > (m:GetAttribute("QueimaAte") or 0) then
		m:SetAttribute("QueimaAte", fim)
	end
end

------------------------------------------------------------------------
-- Dano das magias
------------------------------------------------------------------------
local PASSIVA_DO_ELEMENTO = { gelo = "frioCortante", raio = "sobrecarga", fogo = "combustao", queima = "combustao" }

local function vivo(m)
	return m and m.Parent ~= nil and m.PrimaryPart ~= nil and (m:GetAttribute("Vida") or 0) > 0
end

local function posDe(m)
	return m.PrimaryPart.Position
end

local function plano(a, b)
	return ((a - b) * Vector3.new(1, 0, 1)).Magnitude
end

-- Contexto de um lançamento: poder mágico e bônus calculados uma vez só
local function contexto(player, st, root)
	local stats = api.calcularStats(st)
	return {
		player = player,
		st = st,
		root = root,
		poder = stats.dano,
		critico = stats.critico,
		poderArcano = valorPassiva(st, "poderArcano", "poder"),
		critMaestria = valorPassiva(st, "maestria", "critMagia"),
		danoCritico = Config.Heroi.MultCritico + valorPassiva(st, "maestria", "danoCritico"),
		estilhacar = valorPassiva(st, "frioCortante", "estilhacar"),
	}
end

local explodirAoMorrer -- definida abaixo

-- Causa dano de magia: pct = % do Poder Mágico
local function danoMagia(ctx, alvo, pct, elemento, semCritico)
	if not vivo(alvo) or not api.estado[ctx.player] then
		return 0
	end
	local passiva = PASSIVA_DO_ELEMENTO[elemento]
	local mult = 1 + ctx.poderArcano + (passiva and valorPassiva(ctx.st, passiva, "bonusElem") or 0)
	if ctx.estilhacar > 0 and (ativo(alvo, "LentoAte") or ativo(alvo, "CongeladoAte")) then
		mult += ctx.estilhacar
	end
	local d = ctx.poder * pct / 100 * mult
	if elemento ~= "queima" then
		d *= 1 + (math.random() * 2 - 1) * Dados.Variacao
	end
	local critico = false
	if not semCritico then
		local chance = ctx.critico + ctx.critMaestria
		if elemento == "raio" then
			chance += valorPassiva(ctx.st, "sobrecarga", "critMagia")
		end
		critico = math.random() < math.min(chance, 0.9)
		if critico then
			d *= ctx.danoCritico
		end
	end
	d = math.max(1, math.floor(d + 0.5))
	local queimando = ativo(alvo, "QueimaAte")
	local pos = posDe(alvo)
	api.ferirInimigo(ctx.player, alvo, d, critico, elemento)
	if queimando and (alvo:GetAttribute("Vida") or 0) <= 0 then
		explodirAoMorrer(ctx, pos)
	end
	return d
end

local function monstrosPerto(player, centro, raio, exceto)
	local lista = {}
	for _, m in ipairs(api.monstrosDe(player)) do
		if m ~= exceto and vivo(m) and plano(posDe(m), centro) <= raio then
			table.insert(lista, m)
		end
	end
	return lista
end

-- Combustão: inimigo que morre queimando explode e acerta quem está perto
explodirAoMorrer = function(ctx, pos)
	local pct = valorPassiva(ctx.st, "combustao", "explodir")
	if pct <= 0 then
		return
	end
	task.delay(0.12, function()
		if not api.estado[ctx.player] then
			return
		end
		api.evDano:FireClient(ctx.player, "magia", "explosaoMorte", { centro = pos, raio = 6 })
		for _, m in ipairs(monstrosPerto(ctx.player, pos, 6)) do
			danoMagia(ctx, m, pct, "fogo", true)
		end
	end)
end

------------------------------------------------------------------------
-- Cada magia: devolve true se lançou (tinha alvo)
------------------------------------------------------------------------
local function alvoMaisPerto(player, origem, alcance)
	local melhor, menor = nil, math.huge
	for _, m in ipairs(api.monstrosDe(player)) do
		if vivo(m) then
			local d = plano(posDe(m), origem)
			if d <= alcance and d < menor then
				melhor, menor = m, d
			end
		end
	end
	return melhor
end

local function embaralhar(t)
	for i = #t, 2, -1 do
		local j = math.random(i)
		t[i], t[j] = t[j], t[i]
	end
	return t
end

local Lancar = {}

Lancar.lancaGelo = function(ctx, hab, n, alvo)
	local origem = ctx.root.Position
	local dir = (posDe(alvo) - origem) * Vector3.new(1, 0, 1)
	if dir.Magnitude < 0.1 then
		dir = Vector3.new(0, 0, -1)
	end
	dir = dir.Unit
	local alcance = Dados.AlcanceMagia + 6
	local acertos = {}
	for _, m in ipairs(api.monstrosDe(ctx.player)) do
		if vivo(m) then
			local rel = (posDe(m) - origem) * Vector3.new(1, 0, 1)
			local t = rel:Dot(dir)
			local lado = (rel - dir * t).Magnitude
			if t > -1 and t <= alcance and lado <= 3 then
				table.insert(acertos, { m = m, t = t })
			end
		end
	end
	table.sort(acertos, function(a, b)
		return a.t < b.t
	end)
	local maximo = math.floor(Dados.valor(hab, "perfura", n))
	local fim = origem + dir * alcance
	api.evDano:FireClient(ctx.player, "magia", hab.id, { de = origem, para = fim })
	local velocidade = 70
	for i = 1, math.min(maximo, #acertos) do
		local a = acertos[i]
		task.delay(math.max(0, a.t) / velocidade, function()
			if vivo(a.m) then
				deixarLento(a.m, hab.lentidao, Dados.valor(hab, "tempoLento", n))
				danoMagia(ctx, a.m, Dados.valor(hab, "dano", n), "gelo")
			end
		end)
	end
	return true
end

Lancar.novaGelo = function(ctx, hab, n)
	local centro = ctx.root.Position
	local alvos = monstrosPerto(ctx.player, centro, hab.raio)
	if #alvos == 0 then
		return false
	end
	api.evDano:FireClient(ctx.player, "magia", hab.id, { centro = centro, raio = hab.raio })
	for _, m in ipairs(alvos) do
		estender(m, "CongeladoAte", Dados.valor(hab, "congelar", n))
		danoMagia(ctx, m, Dados.valor(hab, "dano", n), "gelo")
	end
	return true
end

Lancar.nevasca = function(ctx, hab, n, alvo)
	local centro = posDe(alvo)
	local intervalo = 0.45
	api.evDano:FireClient(
		ctx.player,
		"magia",
		hab.id,
		{ centro = centro, raio = hab.raio, duracao = hab.pulsos * intervalo }
	)
	task.spawn(function()
		for p = 1, hab.pulsos do
			if not api.estado[ctx.player] then
				return
			end
			for _, m in ipairs(monstrosPerto(ctx.player, centro, hab.raio)) do
				deixarLento(m, 0.6, 1.5)
				if p == hab.pulsos then
					estender(m, "CongeladoAte", Dados.valor(hab, "congelar", n))
				end
				danoMagia(ctx, m, Dados.valor(hab, "dano", n), "gelo")
			end
			task.wait(intervalo)
		end
	end)
	return true
end

Lancar.correnteRaio = function(ctx, hab, n, alvo)
	local saltos = math.floor(Dados.valor(hab, "saltos", n))
	local cadeia = { alvo }
	local usados = { [alvo] = true }
	local atual = alvo
	for _ = 2, saltos do
		local prox, menor = nil, 14
		for _, m in ipairs(api.monstrosDe(ctx.player)) do
			if not usados[m] and vivo(m) then
				local d = plano(posDe(m), posDe(atual))
				if d < menor then
					prox, menor = m, d
				end
			end
		end
		if not prox then
			break
		end
		usados[prox] = true
		table.insert(cadeia, prox)
		atual = prox
	end
	local pontos = {}
	for _, m in ipairs(cadeia) do
		table.insert(pontos, posDe(m))
	end
	api.evDano:FireClient(ctx.player, "magia", hab.id, { de = ctx.root.Position, pontos = pontos })
	local dano = Dados.valor(hab, "dano", n)
	local chance = Dados.valor(hab, "atordoar", n)
	for i, m in ipairs(cadeia) do
		task.delay((i - 1) * 0.07, function()
			if vivo(m) then
				if math.random() < chance then
					estender(m, "AtordoadoAte", hab.tempoAtordoar)
				end
				danoMagia(ctx, m, dano * (1 - hab.perdaSalto) ^ (i - 1), "raio")
			end
		end)
	end
	return true
end

Lancar.furiaTrovao = function(ctx, hab, n)
	local lista = embaralhar(monstrosPerto(ctx.player, ctx.root.Position, Dados.AlcanceMagia))
	if #lista == 0 then
		return false
	end
	local qtd = math.min(#lista, math.floor(Dados.valor(hab, "alvos", n)))
	local pontos, alvos = {}, {}
	for i = 1, qtd do
		table.insert(alvos, lista[i])
		table.insert(pontos, posDe(lista[i]))
	end
	api.evDano:FireClient(ctx.player, "magia", hab.id, { pontos = pontos })
	task.delay(0.22, function()
		for _, m in ipairs(alvos) do
			if vivo(m) then
				estender(m, "AtordoadoAte", hab.tempoAtordoar)
				danoMagia(ctx, m, Dados.valor(hab, "dano", n), "raio")
			end
		end
	end)
	return true
end

Lancar.tempestade = function(ctx, hab, n)
	if #monstrosPerto(ctx.player, ctx.root.Position, Dados.AlcanceMagia) == 0 then
		return false
	end
	local golpes = math.floor(Dados.valor(hab, "golpes", n))
	local intervalo = 0.25
	api.evDano:FireClient(ctx.player, "magia", hab.id, { duracao = golpes * intervalo })
	task.spawn(function()
		for _ = 1, golpes do
			local st = api.estado[ctx.player]
			local char = ctx.player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			if not st or st.morto or not root then
				return
			end
			local lista = monstrosPerto(ctx.player, root.Position, Dados.AlcanceMagia)
			if #lista > 0 then
				local m = lista[math.random(#lista)]
				local pos = posDe(m)
				api.evDano:FireClient(ctx.player, "magia", "tempestadeGolpe", { pos = pos })
				task.delay(0.12, function()
					if vivo(m) then
						if math.random() < Dados.valor(hab, "atordoar", n) then
							estender(m, "AtordoadoAte", hab.tempoAtordoar)
						end
						danoMagia(ctx, m, Dados.valor(hab, "dano", n), "raio")
					end
				end)
			end
			task.wait(intervalo)
		end
	end)
	return true
end

-- explosão de fogo com dano cheio no alvo e parcial em volta, deixando todos queimando
local function explosaoFogo(ctx, hab, n, alvo, centro)
	local dano = Dados.valor(hab, "dano", n)
	local queima = Dados.valor(hab, "queima", n) * ctx.poder / 100
	if vivo(alvo) then
		queimar(alvo, queima, hab.tempoQueima)
		danoMagia(ctx, alvo, dano, "fogo")
	end
	for _, m in ipairs(monstrosPerto(ctx.player, centro, hab.raio, alvo)) do
		queimar(m, queima, hab.tempoQueima)
		danoMagia(ctx, m, dano * hab.danoArea, "fogo")
	end
end

Lancar.bolaFogo = function(ctx, hab, n, alvo)
	local de = ctx.root.Position
	local para = posDe(alvo)
	local tempo = math.clamp((para - de).Magnitude / 45, 0.15, 0.6)
	api.evDano:FireClient(ctx.player, "magia", hab.id, { de = de, para = para, tempo = tempo, raio = hab.raio })
	task.delay(tempo, function()
		local centro = vivo(alvo) and posDe(alvo) or para
		explosaoFogo(ctx, hab, n, alvo, centro)
	end)
	return true
end

Lancar.anelChamas = function(ctx, hab, n)
	local centro = ctx.root.Position
	local alvos = monstrosPerto(ctx.player, centro, hab.raio)
	if #alvos == 0 then
		return false
	end
	api.evDano:FireClient(ctx.player, "magia", hab.id, { centro = centro, raio = hab.raio })
	local queima = Dados.valor(hab, "queima", n) * ctx.poder / 100
	for _, m in ipairs(alvos) do
		task.delay(plano(posDe(m), centro) / 40, function()
			if vivo(m) then
				queimar(m, queima, hab.tempoQueima)
				danoMagia(ctx, m, Dados.valor(hab, "dano", n), "fogo")
			end
		end)
	end
	return true
end

Lancar.meteoro = function(ctx, hab, n, alvo)
	local centro = posDe(alvo)
	local queda = 0.9
	api.evDano:FireClient(ctx.player, "magia", hab.id, { centro = centro, raio = hab.raio, tempo = queda })
	task.delay(queda, function()
		local c = vivo(alvo) and posDe(alvo) or centro
		explosaoFogo(ctx, hab, n, alvo, c)
	end)
	return true
end

------------------------------------------------------------------------
-- Loop: lança as magias da barra sozinho e faz a queimadura doer
------------------------------------------------------------------------
local function recargaDe(st, hab, n)
	local reducao = math.min(valorPassiva(st, "menteRapida", "reducao"), Dados.ReducaoRecargaMax)
	return math.max(0.6, Dados.valor(hab, "recarga", n) * (1 - reducao))
end

local function tentarLancar(player, st, root, id, eco)
	local hab = Dados.PorId[id]
	local n = nivelDe(st, id)
	local fn = hab and Lancar[id]
	if not fn or n <= 0 then
		return false
	end
	local alvo = alvoMaisPerto(player, root.Position, Dados.AlcanceMagia)
	if not alvo then
		return false
	end
	local ctx = contexto(player, st, root)
	if not fn(ctx, hab, n, alvo) then
		return false
	end
	if Animacoes then
		pcall(Animacoes.conjurar, player, id, posDe(alvo))
	end
	if eco then
		api.evDano:FireClient(player, "magia", "eco", { pos = root.Position, nome = hab.nome })
	end
	return true
end

local function lancarDaBarra(player, st, root)
	local agora = os.clock()
	if agora < (recargaGlobal[player] or 0) then
		return
	end
	local prox = proxima[player]
	if not prox then
		prox = {}
		proxima[player] = prox
	end
	-- supremas primeiro, depois a ordem da barra
	local ordem = {}
	for _, id in ipairs(st.barraHab) do
		local h = Dados.PorId[id]
		if h and h.tipo == "suprema" then
			table.insert(ordem, id)
		end
	end
	for _, id in ipairs(st.barraHab) do
		local h = Dados.PorId[id]
		if h and h.tipo ~= "suprema" then
			table.insert(ordem, id)
		end
	end
	for _, id in ipairs(ordem) do
		if agora >= (prox[id] or 0) then
			if tentarLancar(player, st, root, id) then
				local hab = Dados.PorId[id]
				local recarga = recargaDe(st, hab, nivelDe(st, id))
				prox[id] = agora + recarga
				recargaGlobal[player] = agora + Dados.RecargaGlobal
				api.evDano:FireClient(player, "recarga", id, recarga)
				-- Eco Arcano: chance de sair de novo, de graça
				local eco = valorPassiva(st, "ecoArcano", "eco")
				if eco > 0 and math.random() < eco then
					task.delay(0.3, function()
						local s = api.estado[player]
						local char = player.Character
						local r = char and char:FindFirstChild("HumanoidRootPart")
						if s and not s.morto and r then
							tentarLancar(player, s, r, id, true)
						end
					end)
				end
				return
			end
		end
	end
end

local function queimaduras(player, st, root, passo)
	local agora = agoraServidor()
	local ctx
	for _, m in ipairs(api.monstrosDe(player)) do
		if vivo(m) and (m:GetAttribute("QueimaAte") or 0) > agora then
			ctx = ctx or contexto(player, st, root)
			-- a queimadura já está em dano real (não em %); bônus aplicados em danoMagia
			local dps = m:GetAttribute("QueimaDps") or 0
			if dps > 0 then
				danoMagia(ctx, m, dps * passo / ctx.poder * 100, "queima", true)
			end
		end
	end
end

function Hab.loop(player)
	local ultimaQueima = os.clock()
	while player.Parent and api.estado[player] do
		local st = api.estado[player]
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if st and Dados.arvoreDe(st.classe) and not st.morto and hum and root and hum.Health > 0 then
			Hab.garantir(st)
			lancarDaBarra(player, st, root)
			if os.clock() - ultimaQueima >= 0.5 then
				queimaduras(player, st, root, os.clock() - ultimaQueima)
				ultimaQueima = os.clock()
			end
		else
			ultimaQueima = os.clock()
		end
		task.wait(0.1)
	end
end

------------------------------------------------------------------------
-- Pedidos da tela: aprender, equipar na barra, tirar, mover e resetar
------------------------------------------------------------------------
local function naBarra(st, id)
	return table.find(st.barraHab, id)
end

local function pedido(player, acao, id, extra)
	local st = api.estado[player]
	if not st or type(acao) ~= "string" then
		return
	end
	local agora = os.clock()
	if ultimoPedido[player] and agora - ultimoPedido[player] < 0.06 then
		return
	end
	ultimoPedido[player] = agora
	Hab.garantir(st)
	local hab = type(id) == "string" and Dados.PorId[id] or nil

	if acao == "aprender" and hab then
		local ok = Dados.podeAprender(st.habilidades, st.pontosHabilidade, st.classe, id)
		if not ok then
			return
		end
		local antes = nivelDe(st, id)
		st.habilidades[id] = antes + 1
		st.pontosHabilidade -= 1
		if antes == 0 and Dados.eAtiva(hab) and #st.barraHab < Dados.SlotsBarra and not naBarra(st, id) then
			table.insert(st.barraHab, id)
		end
	elseif acao == "equipar" and hab then
		if Dados.eAtiva(hab) and nivelDe(st, id) > 0 and not naBarra(st, id) and #st.barraHab < Dados.SlotsBarra then
			table.insert(st.barraHab, id)
		end
	elseif acao == "tirar" and hab then
		local i = naBarra(st, id)
		if i then
			table.remove(st.barraHab, i)
		end
	elseif acao == "mover" and hab and (extra == 1 or extra == -1) then
		local i = naBarra(st, id)
		local j = i and i + extra
		if i and j >= 1 and j <= #st.barraHab then
			st.barraHab[i], st.barraHab[j] = st.barraHab[j], st.barraHab[i]
		end
	elseif acao == "resetar" then
		local gastos = Dados.gastos(st.habilidades)
		local custo = Dados.CustoReset(st.nivel)
		if gastos <= 0 or st.ouro < custo then
			return
		end
		st.ouro -= custo
		st.pontosHabilidade += gastos
		st.habilidades = {}
		st.barraHab = {}
		proxima[player] = {}
	else
		return
	end
	api.enviarEstado(player)
end

------------------------------------------------------------------------
-- api = { estado, calcularStats, monstrosDe, ferirInimigo, evDano, enviarEstado }
------------------------------------------------------------------------
function Hab.iniciar(funcoes)
	api = funcoes
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local ev = remotes:FindFirstChild("Habilidade") or Instance.new("RemoteEvent")
	ev.Name = "Habilidade"
	ev.Parent = remotes
	ev.OnServerEvent:Connect(pedido)
	Players.PlayerRemoving:Connect(function(player)
		proxima[player] = nil
		recargaGlobal[player] = nil
		ultimoPedido[player] = nil
	end)
end

-- O que vai para a tela junto com o estado
function Hab.dadosTela(st)
	Hab.garantir(st)
	return st.pontosHabilidade, st.habilidades, st.barraHab
end

return Hab
