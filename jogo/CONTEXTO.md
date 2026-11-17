# Contexto do jogo (leia antes de trabalhar)

O dono do projeto não programa. Claude faz todo o código, explica tudo em português simples e testa sozinho sempre que der.

## Conceito
- RPG idle de loot em **3D** no Roblox, com tema anime **original**. Nada de nomes, símbolos ou personagens de animes existentes (Naruto, Solo Leveling etc.).
- O herói anda e luta sozinho num mapa. Um **botão de auto-farm** liga e desliga, e o jogador também pode controlar.
- **70 monstros por fase**, depois a próxima fase com monstros novos.
- **Mundos de 10 fases.** A fase 10 tem o boss final do mundo, que dropa um **baú especial**.
- **Perdeu pro boss:** volta uma fase e o auto-farm continua.
- **Ouro e Página de Runas**, abríveis durante a luta, para melhorias permanentes.
- **Loot com raridades** (comum até lendário), atributos aleatórios, inventário e equipamento visível no personagem.
- **Classes:** Assassino, Mago, Tanque, Curandeiro e uma classe secreta (invocador de sombras).
- **Olho despertado:** olho raro que evolui de nível e dá passivas. Design original.
- **Progresso offline** com limite (por exemplo, 8 h, rendendo menos que jogando).
- **Fora do jogo:** sistema de "Despertar"/renascimento. O dono não gostou.
- **Efeitos "dopaminérgicos":** VFX de magia, números de dano, tremida de tela e drop lendário chamativo.
- **Social:** anúncio de lendário para o servidor e ranking.

## Economia
- Ouro **não** é negociável entre jogadores. Troca de itens só item por item, com taxa, nível mínimo e prazo.
- Ouro sempre precisa ter onde ser gasto. Todos os números de balanceamento ficam num arquivo de configuração.
- Simular a economia antes de lançar.
- **UGC:** só poucos cosméticos especiais. Conferir as regras oficiais atuais do Roblox antes (taxas, Premium, verificação, regras de itens aleatórios ligados a Robux). Nada de venda por dinheiro fora do Roblox.

## Como trabalhamos
- **Backups:** ver `BACKUPS.md`. Commit a cada mudança e commit `BACKUP:` antes de mudanças grandes.
- **Painel de acompanhamento:** https://claude.ai/artifact/J3brf31C7iDuHGNpm476sE. Atualizar o status das funções a cada mudança.
- **Ordem:** primeiro uma versão jogável pequena (mundo 1), depois o resto.
