--!strict
-- Compras com Robux: gamepasses e produtos.
-- Regras para ser justo com criança: nada abre sozinho na tela, ovo pago
-- mostra as chances antes, e toda compra é entregue uma vez só (recibo salvo).

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Dados = require(script.Parent.Dados)

local Loja = {}

local passesDe: { [Player]: { [string]: boolean } } = {}

-- Entrega do produto. Devolve true quando entregou.
local entregar: ((jogador: Player, chave: string) -> boolean)? = nil
local aoMudarPasses: ((jogador: Player) -> ())? = nil

local function chavePorId(tabela: { [string]: { id: number } }, id: number): string?
	for chave, info in tabela do
		if info.id ~= 0 and info.id == id then
			return chave
		end
	end
	return nil
end

function Loja.tem(jogador: Player, passe: string): boolean
	local passes = passesDe[jogador]
	return passes ~= nil and passes[passe] == true
end

function Loja.passes(jogador: Player): { [string]: boolean }
	return passesDe[jogador] or {}
end

function Loja.carregarPasses(jogador: Player)
	local passes = {}
	for chave, info in Config.Gamepasses do
		if info.id ~= 0 then
			local ok, tem = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, jogador.UserId, info.id)
			passes[chave] = ok and tem == true
		end
	end
	passesDe[jogador] = passes
	if aoMudarPasses then
		aoMudarPasses(jogador)
	end
end

local function processarRecibo(recibo: any): Enum.ProductPurchaseDecision
	local jogador = Players:GetPlayerByUserId(recibo.PlayerId)
	if not jogador then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local perfil = Dados.obter(jogador)
	if not perfil then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local idCompra = tostring(recibo.PurchaseId)
	if Dados.jaRecebido(perfil, idCompra) then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	local chave = chavePorId(Config.Produtos :: any, recibo.ProductId)
	if not chave or not entregar then
		warn("[Loja] produto desconhecido:", recibo.ProductId)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local ok, entregou = pcall(entregar, jogador, chave)
	if not ok or not entregou then
		warn("[Loja] falha ao entregar", chave, entregou)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	Dados.registrarRecibo(perfil, idCompra)
	Dados.salvar(jogador, false)
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

function Loja.iniciar(opcoes: {
	entregar: (jogador: Player, chave: string) -> boolean,
	aoMudarPasses: (jogador: Player) -> (),
})
	entregar = opcoes.entregar
	aoMudarPasses = opcoes.aoMudarPasses
	MarketplaceService.ProcessReceipt = processarRecibo

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(jogador, idPasse, comprou)
		if not comprou then
			return
		end
		local chave = chavePorId(Config.Gamepasses :: any, idPasse)
		if chave then
			passesDe[jogador] = passesDe[jogador] or {}
			passesDe[jogador][chave] = true
			if aoMudarPasses then
				aoMudarPasses(jogador)
			end
		end
	end)

	Players.PlayerRemoving:Connect(function(jogador)
		passesDe[jogador] = nil
	end)
end

return Loja
