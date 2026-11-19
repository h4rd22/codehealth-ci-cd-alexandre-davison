-- Salvamento: guarda o progresso do jogador no DataStore do Roblox.
--
-- Como funciona:
--   * carregar(player, st)  ao entrar: trava a sessão e copia o save para st
--   * autosave a cada ~2,5 min (espalhado por jogador)
--   * sair(player)          ao sair: salva e solta a trava
--   * game:BindToClose      ao fechar o servidor: salva todo mundo
--
-- Regras de segurança:
--   * toda chamada ao DataStore usa pcall + nova tentativa com espera crescente
--   * só UpdateAsync (nunca SetAsync), para não brigar com outro servidor
--   * trava de sessão: um servidor por jogador; trava velha (servidor caiu) expira
--   * se o carregamento falhar, o jogador é desconectado SEM sobrescrever o save
--   * versão do esquema + migrações; campos estragados voltam ao padrão

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Salvamento = {}

local VERSAO = 1 -- versão do formato do save; suba e crie uma migração ao mudar o formato
local AUTOSAVE = 150 -- segundos entre autosaves
local TRAVA_VELHA = AUTOSAVE * 2 + 30 -- trava sem renovação há esse tempo = servidor morreu
local TENTATIVAS = 5
local NO_STUDIO = RunService:IsStudio()

-- No Studio os testes usam outro "banco", para nunca estragar o save real dos jogadores.
local NOME_STORE = NO_STUDIO and "Jogadores_Studio_v1" or "Jogadores_v1"
local ID_SESSAO = (game.JobId ~= "" and game.JobId) or ("studio-" .. HttpService:GenerateGUID(false))

local store = nil
local okStore, erroStore = pcall(function()
	store = DataStoreService:GetDataStore(NOME_STORE)
end)
if not okStore then
	warn("[Salvamento] DataStore indisponível:", erroStore)
end

-- Campos de progresso que vão para o save (o resto é temporário: kills, vida, timers...)
local CAMPOS = {
	nivel = "number",
	xp = "number",
	ouro = "number",
	fase = "number",
	faseMax = "number",
	proximoId = "number",
	pergaminhos = "number",
	pontosHabilidade = "number",
	avatarAtivo = "number",
	classe = "string",
	autoVenda = "string",
	autoFarm = "boolean",
	repetir = "boolean",
	esconderEquip = "boolean",
	equipado = "table",
	joias = "table",
	secretos = "table",
	avatares = "table",
	treino = "table",
	configForja = "table",
	habilidades = "table",
	barraHab = "table",
	-- "itens" é tratado à parte (vira lista no save)
}

-- Migrações: MIGRACOES[n] transforma um save da versão n na versão n + 1.
-- Exemplo para o futuro: [1] = function(d) d.cristais = 0 return d end
local MIGRACOES: { [number]: (any) -> any } = {}

-- v1 -> v2: raridades passam a ter 7 tiers (Lucas). Fica pronta, mas só roda
-- quando VERSAO virar 2 — suba VERSAO no MESMO commit que muda o Config.
local RARIDADE_V2 = { incomum = "raro", epico = "ultraRaro", mitico = "lendario" }
MIGRACOES[1] = function(d)
	if type(d) ~= "table" then
		return d
	end
	local function nova(r)
		return RARIDADE_V2[r] or r
	end
	for _, item in ipairs(type(d.itens) == "table" and d.itens or {}) do
		if type(item) == "table" and type(item.raridade) == "string" then
			item.raridade = nova(item.raridade)
		end
	end
	if type(d.autoVenda) == "string" then
		d.autoVenda = nova(d.autoVenda)
	end
	if type(d.configForja) == "table" and type(d.configForja.ate) == "string" then
		d.configForja.ate = nova(d.configForja.ate)
	end
	return d
end

local sessoes = {} -- sessoes[player] = { st = ..., chave = ..., salvando = bool }
local saindo = {} -- userId -> true enquanto o save final ainda está sendo gravado

------------------------------------------------------------------------
-- Utilidades
------------------------------------------------------------------------
local function log(...)
	print("[Salvamento]", ...)
end

local function comRetentativa(nome, fn)
	local espera = 1
	for tentativa = 1, TENTATIVAS do
		local ok, a, b = pcall(fn)
		if ok then
			return true, a, b
		end
		warn(`[Salvamento] {nome} falhou ({tentativa}/{TENTATIVAS}): {a}`)
		if string.find(tostring(a), "403", 1, true) then
			return false, "semAcesso" -- sem permissão: tentar de novo não adianta
		end
		if tentativa < TENTATIVAS then
			task.wait(espera)
			espera = math.min(espera * 2, 16)
		end
	end
	return false
end

local function numeroValido(v)
	return type(v) == "number" and v == v and v ~= math.huge and v ~= -math.huge
end

-- Cópia que só aceita o que o DataStore consegue guardar (texto, número, sim/não, tabelas)
local function copiaSegura(v, profundidade)
	profundidade = profundidade or 0
	local t = type(v)
	if t == "number" then
		return numeroValido(v) and v or nil
	elseif t == "string" or t == "boolean" then
		return v
	elseif t ~= "table" or profundidade > 8 then
		return nil
	end
	-- lista (1..n sem buracos) continua lista; o resto vira dicionário com chave texto
	local n = #v
	local ehLista = true
	local total = 0
	for k in pairs(v) do
		total += 1
		if type(k) ~= "number" or k < 1 or k > n or k % 1 ~= 0 then
			ehLista = false
		end
	end
	ehLista = ehLista and total == n
	local saida = {}
	if ehLista then
		for i = 1, n do
			local c = copiaSegura(v[i], profundidade + 1)
			if c ~= nil then
				table.insert(saida, c)
			end
		end
	else
		for k, val in pairs(v) do
			if type(k) == "string" or numeroValido(k) then
				local c = copiaSegura(val, profundidade + 1)
				if c ~= nil then
					saida[tostring(k)] = c
				end
			end
		end
	end
	return saida
end

------------------------------------------------------------------------
-- Estado do jogo <-> save
------------------------------------------------------------------------
local function paraSave(st)
	local dados = {}
	for campo in pairs(CAMPOS) do
		if st[campo] ~= nil then
			dados[campo] = copiaSegura(st[campo])
		end
	end
	local itens = {}
	for _, item in pairs(st.itens or {}) do
		local c = copiaSegura(item)
		if c then
			table.insert(itens, c)
		end
	end
	dados.itens = itens
	return dados
end

-- Copia o save para o estado do jogo, campo a campo. Campo com tipo errado fica no padrão.
local function aplicarSave(st, dados)
	local problemas = 0
	for campo, tipo in pairs(CAMPOS) do
		local v = dados[campo]
		if v ~= nil then
			if type(v) == tipo and (tipo ~= "number" or numeroValido(v)) then
				st[campo] = v
			else
				problemas += 1
				warn(`[Salvamento] campo "{campo}" estragado; usando o padrão`)
			end
		end
	end
	-- números que não podem ser negativos
	st.nivel = math.max(1, math.floor(st.nivel or 1))
	st.xp = math.max(0, st.xp or 0)
	st.ouro = math.max(0, st.ouro or 0)
	st.pergaminhos = math.max(0, st.pergaminhos or 0)
	st.faseMax = math.max(1, math.floor(st.faseMax or 1))
	st.fase = math.clamp(math.floor(st.fase or 1), 1, st.faseMax)
	-- itens: lista no save -> dicionário por id no jogo
	st.itens = {}
	local maiorId = 0
	if type(dados.itens) == "table" then
		for _, item in ipairs(dados.itens) do
			if
				type(item) == "table"
				and numeroValido(item.id)
				and type(item.slot) == "string"
				and type(item.raridade) == "string"
			then
				if type(item.joias) ~= "table" then
					item.joias = {}
				end
				st.itens[item.id] = item
				maiorId = math.max(maiorId, item.id)
			else
				problemas += 1
			end
		end
	end
	st.proximoId = math.max(st.proximoId or 0, maiorId)
	-- equipados que apontam para item que não existe saem
	local equipado = {}
	for slot, id in pairs(st.equipado or {}) do
		local num = tonumber(id)
		if num and st.itens[num] then
			equipado[slot] = num
		end
	end
	st.equipado = equipado
	-- habilidades: chave texto, nível número
	local hab = {}
	for id, nv in pairs(st.habilidades or {}) do
		if type(id) == "string" and numeroValido(nv) then
			hab[id] = nv
		end
	end
	st.habilidades = hab
	-- avatares: lista de números
	local avatares = {}
	for _, a in ipairs(st.avatares or {}) do
		if numeroValido(a) then
			table.insert(avatares, a)
		end
	end
	st.avatares = avatares
	return problemas
end

local function migrar(registro)
	local v = registro.versao or 1
	while v < VERSAO do
		local passo = MIGRACOES[v]
		if not passo then
			error(`falta a migração da versão {v}`)
		end
		registro.dados = passo(registro.dados)
		v += 1
	end
	registro.versao = v
	return registro
end

local function travaAlheia(registro)
	local trava = registro and registro.trava
	if type(trava) ~= "table" or trava.sessao == ID_SESSAO then
		return false
	end
	if type(trava.hora) ~= "number" or os.time() - trava.hora > TRAVA_VELHA then
		return false -- trava velha: o servidor que tinha caiu
	end
	if NO_STUDIO and type(trava.sessao) == "string" and string.sub(trava.sessao, 1, 7) == "studio-" then
		return false -- Play anterior do Studio que foi parado
	end
	return true
end

------------------------------------------------------------------------
-- Carregar
------------------------------------------------------------------------
-- Retorna true se pode jogar. Em caso de falha o jogador é desconectado
-- e o save antigo continua intacto.
function Salvamento.carregar(player, st)
	if not store then
		if NO_STUDIO then
			warn(
				"[Salvamento] sem DataStore no Studio (ligue 'Enable Studio Access to API Services'); jogando sem salvar"
			)
			return true
		end
		player:Kick("Não foi possível carregar seu progresso. Entre de novo em instantes.")
		return false
	end
	-- se o jogador acabou de sair deste mesmo servidor, espera o save final terminar
	local limite = os.clock() + 20
	while saindo[player.UserId] and os.clock() < limite do
		task.wait(0.25)
	end

	local chave = "jogador_" .. player.UserId
	for _ = 1, 6 do
		local resultado, registroLido = nil, nil
		local ok, motivo = comRetentativa("carregar", function()
			store:UpdateAsync(chave, function(antigo)
				resultado, registroLido = nil, nil
				if antigo ~= nil and type(antigo) ~= "table" then
					resultado = "estragado"
					return nil -- não mexe
				end
				if travaAlheia(antigo) then
					resultado = "travado"
					return nil
				end
				local registro = antigo or { versao = VERSAO }
				if type(registro.versao) == "number" and registro.versao > VERSAO then
					resultado = "versaoNova"
					return nil
				end
				local okMig, migrado = pcall(migrar, registro)
				if not okMig then
					resultado = "estragado"
					warn("[Salvamento] migração falhou:", migrado)
					return nil
				end
				migrado.trava = { sessao = ID_SESSAO, hora = os.time() }
				resultado = antigo and "carregado" or "novo"
				registroLido = migrado
				return migrado
			end)
		end)
		if not ok and NO_STUDIO and motivo == "semAcesso" then
			warn("[Salvamento] Studio sem acesso às APIs (Game Settings > Security); jogando SEM salvar")
			return true
		elseif not ok then
			player:Kick("Não foi possível carregar seu progresso (servidores do Roblox). Entre de novo em instantes.")
			return false
		elseif not player.Parent then
			return false
		elseif resultado == "travado" then
			log(player.Name, "ainda está salvando em outro servidor; esperando...")
			task.wait(5)
		elseif resultado == "estragado" then
			player:Kick("Seu save precisa de verificação. Ele NÃO foi apagado. Fale com o criador do jogo.")
			return false
		elseif resultado == "versaoNova" then
			player:Kick("Este servidor está desatualizado. Entre de novo para ir a um servidor novo.")
			return false
		elseif resultado == "carregado" or resultado == "novo" then
			if resultado == "carregado" and type(registroLido.dados) == "table" then
				local problemas = aplicarSave(st, registroLido.dados)
				log(
					`{player.Name} carregado: nível {st.nivel}, ouro {math.floor(st.ouro)}, fase {st.fase}/{st.faseMax}, itens {#(registroLido.dados.itens or {})}, classe {st.classe or "-"}`
						.. (problemas > 0 and ` ({problemas} problema(s) corrigidos)` or "")
				)
			else
				log(player.Name, "é novo: começando do zero")
			end
			sessoes[player] = { st = st, chave = chave, salvando = false }
			if not player.Parent then
				task.spawn(Salvamento.sair, player) -- saiu enquanto carregava: solta a trava
				return false
			end
			return true
		end
	end
	player:Kick("Seu progresso ainda está sendo salvo em outro servidor. Entre de novo em 1 minuto.")
	return false
end

------------------------------------------------------------------------
-- Salvar
------------------------------------------------------------------------
local function salvar(player, soltar)
	local s = sessoes[player]
	if not s or not store then
		return false
	end
	if s.salvando and not soltar then
		return false -- já tem um autosave em andamento
	end
	while s.salvando do
		task.wait(0.1)
	end
	s.salvando = true
	local dados = paraSave(s.st)
	local okJson, json = pcall(HttpService.JSONEncode, HttpService, dados)
	if not okJson then
		warn("[Salvamento] dados não convertem para JSON; save cancelado:", json)
		s.salvando = false
		return false
	end
	local perdeuTrava = false
	local ok = comRetentativa("salvar", function()
		store:UpdateAsync(s.chave, function(antigo)
			perdeuTrava = false
			if travaAlheia(antigo) then
				perdeuTrava = true
				return nil -- outro servidor é dono agora: não sobrescreve
			end
			return {
				versao = VERSAO,
				dados = dados,
				salvoEm = os.time(),
				trava = (not soltar) and { sessao = ID_SESSAO, hora = os.time() } or nil,
			}
		end)
	end)
	s.salvando = false
	if perdeuTrava then
		warn(`[Salvamento] {player.Name}: outro servidor assumiu o save; este não grava mais`)
		sessoes[player] = nil
		return false
	end
	if ok then
		log(
			`{player.Name} salvo ({#json} bytes, nível {s.st.nivel}, {#dados.itens} itens){soltar and " e liberado" or ""}`
		)
	end
	return ok
end

function Salvamento.salvarAgora(player)
	return salvar(player, false)
end

-- Ao sair: grava e solta a trava. Chame ANTES de apagar estado[player].
function Salvamento.sair(player)
	local s = sessoes[player]
	if not s or s.saindo then
		return
	end
	s.saindo = true
	local id = player.UserId
	saindo[id] = true
	salvar(player, true)
	sessoes[player] = nil
	saindo[id] = nil
end

------------------------------------------------------------------------
-- Autosave e fechamento do servidor
------------------------------------------------------------------------
task.spawn(function()
	while true do
		task.wait(1)
		local agora = os.time()
		for player, s in pairs(sessoes) do
			-- cada jogador salva num segundo diferente do ciclo
			if not s.saindo and (agora + player.UserId) % AUTOSAVE == 0 then
				local orcamento = DataStoreService:GetRequestBudgetForRequestType(Enum.DataStoreRequestType.UpdateAsync)
				if orcamento > 5 then
					task.spawn(salvar, player, false)
				end
			end
		end
	end
end)

game:BindToClose(function()
	for player in pairs(sessoes) do
		task.spawn(Salvamento.sair, player)
	end
	-- espera todos os saves (inclusive os que já começaram no PlayerRemoving)
	local limite = os.clock() + 25
	while next(sessoes) ~= nil and os.clock() < limite do
		task.wait(0.1)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	-- garantia extra caso o GameServer não chame sair()
	task.defer(Salvamento.sair, player)
end)

return Salvamento
