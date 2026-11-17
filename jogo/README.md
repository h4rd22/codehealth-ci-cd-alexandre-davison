# RPG Idle de Loot (Roblox)

Leia antes: [`CONTEXTO.md`](CONTEXTO.md) (regras e ideia do jogo) e [`BACKUPS.md`](BACKUPS.md).

## Como o projeto está organizado

| Pasta / arquivo | O que é | Onde aparece no Roblox |
|---|---|---|
| `src/server/` | Código do servidor (combate, loot, forja, fases) | `ServerScriptService.Server` |
| `src/client/` | Código da tela do jogador (HUD, menus, efeitos) | `StarterPlayerScripts.Client` |
| `src/shared/` | Coisas usadas pelos dois lados, como o `Config` com todos os números | `ReplicatedStorage.Shared` |
| `default.project.json` | Mapa do Rojo: diz qual pasta vai para onde no Studio | |
| `rokit.toml` | Versões travadas das ferramentas | |
| `wally.toml` | Bibliotecas externas (ainda nenhuma) | `ReplicatedStorage.Packages` |
| `selene.toml` / `stylua.toml` | Regras de qualidade e de formatação do código | |

Tipo de arquivo pelo nome: `.server.luau` = Script, `.client.luau` = LocalScript, `.luau` = ModuleScript.

## Ferramentas

- **Rokit**: instala e trava as versões das outras ferramentas.
- **Rojo**: manda os arquivos daqui para o Studio em tempo real.
- **Wally**: baixa bibliotecas da comunidade.
- **Selene**: procura erros e código suspeito.
- **StyLua**: deixa o código formatado sempre do mesmo jeito.

## Comandos (rodar dentro da pasta `jogo`)

```bash
rokit install
```
Instala as ferramentas nas versões do `rokit.toml` (só na primeira vez).

```bash
wally install
```
Baixa as bibliotecas do `wally.toml`.

```bash
rojo serve
```
Liga a sincronização. No Studio, aba **Plugins → Rojo → Connect**.

```bash
stylua src
```
Formata o código.

```bash
selene src
```
Procura problemas no código.

```bash
rojo build -o jogo.rbxl
```
Gera um arquivo do jogo a partir do código.

## Verificação automática

Todo push que muda a pasta `jogo/` roda no GitHub (`.github/workflows/qualidade.yml`): formatação (StyLua), lint (Selene) e build (Rojo). Se algo quebrar, aparece um X vermelho no commit.
