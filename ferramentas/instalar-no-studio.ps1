# Gera o código Luau que instala todos os scripts de jogo/src no Roblox Studio.
# Pasta = serviço do Roblox. Sufixo do arquivo = tipo:
#   .server.lua -> Script   |  .client.lua -> LocalScript  |  .lua -> ModuleScript
param(
  [string]$Raiz = (Join-Path $PSScriptRoot '..\jogo\src'),
  [string]$Saida
)
$Raiz = (Resolve-Path $Raiz).Path
$linhas = New-Object System.Collections.Generic.List[string]
$linhas.Add(@'
local function pastaDe(caminho)
  local partes = string.split(caminho, "/")
  local atual = game:GetService(partes[1])
  for i = 2, #partes do
    atual = atual:FindFirstChild(partes[i]) or atual:WaitForChild(partes[i], 5)
  end
  return atual
end
local function instalar(classe, caminho, nome, fonte)
  local pai = pastaDe(caminho)
  local velho = pai:FindFirstChild(nome)
  if velho then velho:Destroy() end
  local s = Instance.new(classe)
  s.Name = nome
  s.Source = fonte
  s.Parent = pai
end
local feitos = {}
'@)
Get-ChildItem $Raiz -Recurse -File -Filter *.lua | Sort-Object FullName | ForEach-Object {
  $rel = $_.FullName.Substring($Raiz.Length + 1)
  $pasta = (Split-Path $rel -Parent) -replace '\\', '/'
  $arq = $_.Name
  if ($arq -like '*.server.lua') { $classe = 'Script'; $nome = $arq -replace '\.server\.lua$', '' }
  elseif ($arq -like '*.client.lua') { $classe = 'LocalScript'; $nome = $arq -replace '\.client\.lua$', '' }
  else { $classe = 'ModuleScript'; $nome = $arq -replace '\.lua$', '' }
  $fonte = [IO.File]::ReadAllText($_.FullName, [Text.Encoding]::UTF8)
  if ($fonte.Contains(']====]')) { throw "conteudo invalido em $rel" }
  $linhas.Add("instalar(`"$classe`", `"$pasta`", `"$nome`", [====[`n$fonte]====])")
  $linhas.Add("table.insert(feitos, `"$nome`")")
}
$linhas.Add('return "instalado: " .. table.concat(feitos, ", ")')
$codigo = $linhas -join "`n"
if ($Saida) { [IO.File]::WriteAllText($Saida, $codigo, (New-Object Text.UTF8Encoding $false)) } else { $codigo }
