# Mistureba (Roblox)

Jogo original de pegar, fundir e roubar criaturas. Ovos de cristal caem no meio do mapa, você leva para a sua base, e cada Mistureba na base gera moedas. Os outros jogadores podem invadir e roubar, e você recupera com uma bolha que prende o ladrão por um instante.

## Regra de dinheiro
**Nunca gastar dinheiro real nem Robux sem perguntar ao dono antes, toda vez.** Criar gamepass e produto no Creator Hub é grátis; anúncios, UGC e plugins pagos precisam de um "sim" claro.

## Como o jogo funciona

| Sistema | Onde está | Resumo |
|---|---|---|
| Números do jogo | `src/shared/Config.luau` | Criaturas, chances, preços, cadeado, Robux. Mude aqui para balancear. |
| Mapa | `src/server/Mapa.luau` | Campo dos ovos no meio e 8 bases em volta, tudo criado por código. |
| Regras | `src/server/Jogo.server.luau` | Chuva de ovos, carregar, roubar, bolha, cadeado, fusão, renda. |
| Modelos | `src/server/Criaturas.luau` | Monta as Misturebas com peças simples. Trocar por arte própria aqui. |
| Salvamento | `src/server/Dados.luau` | DataStore com nova tentativa, trava de servidor, autosave e recibos. |
| Robux | `src/server/Loja.luau` | Gamepasses e produtos, entregues uma vez só. |
| Tela | `src/client/Hud.client.luau` | Moedas, painéis Ovos/Fusão/Base/Loja, avisos. |

**Regras de roubo:** só dá para roubar com a porta aberta. Quem acabou de entrar fica 2 minutos protegido, e quem tem menos de 3 Misturebas não pode ser roubado. Quem carrega anda mais devagar e brilha em vermelho; uma bolha (F) prende o ladrão por 1,5 s e faz ele soltar tudo, sem empurrar nem machucar.

**Fusão:** duas da mesma raridade viram uma da raridade seguinte. As duas secretas só saem por receita.

## Robux, do jeito justo para criança
- Nada abre sozinho na tela. A loja só aparece quando o jogador clica.
- Todo ovo com sorte (inclusive o pago) mostra as chances antes da compra, como o Roblox exige.
- Sem "oferta acaba em 5 minutos" e sem compra de pânico. O cadeado é de graça para todo mundo.

| Item | Tipo | Robux |
|---|---|---|
| VIP (2x moedas, nome dourado) | Gamepass | 299 |
| Mochila Dupla (2 ovos) | Gamepass | 199 |
| Cadeado Reforçado (90 s) | Gamepass | 149 |
| Base Grande (+4 vagas) | Gamepass | 149 |
| Sorte do Servidor (15 min, para todos) | Produto | 79 |
| Ovo Arco-íris (chances na tela) | Produto | 49 |
| Saco de Moedas | Produto | 25 |

## Para testar no Studio
1. `rokit install` (só na primeira vez) e `rojo serve` dentro desta pasta.
2. No Studio, crie um lugar vazio, abra **Plugins → Rojo → Connect**.
3. Em **Game Settings → Security**, ligue **Enable Studio Access to API Services** (para salvar).
4. Em **Game Settings → Places**, deixe **Max Players = 8** (são 8 bases).
5. Para testar roubo, use **Test → Clients and Servers** com 2 jogadores.

## Para ligar os Robux
1. No Creator Hub, crie os 4 gamepasses e os 3 produtos (é grátis) com os preços acima.
2. Copie cada ID para `Config.Gamepasses` e `Config.Produtos` em `src/shared/Config.luau`.
3. Enquanto o ID for `0`, o botão aparece como "Em breve".

## Verificação automática
Todo push que muda esta pasta roda `.github/workflows/mistureba.yml`: formatação (StyLua), lint (Selene) e build (Rojo).
