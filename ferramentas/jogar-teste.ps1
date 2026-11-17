# Atalho "Jogar Teste": abre o jogo de teste no Roblox Studio,
# mas NÃO abre de novo se ele já estiver aberto (dois Studios com o mesmo jogo dão conflito).
param(
  [string]$Arquivo = 'D:\Claude\jogo-roblox\jogo\lugar\JogoAnime.rbxl',
  [switch]$SoVerificar   # usado nos testes: só diz o que faria, sem abrir nada
)

Add-Type -AssemblyName System.Windows.Forms
$nome = [IO.Path]::GetFileNameWithoutExtension($Arquivo)

function Aviso($texto, $icone) {
  if ($SoVerificar) { return }
  [System.Windows.Forms.MessageBox]::Show($texto, 'Jogar Teste', 'OK', $icone) | Out-Null
}

if (-not (Test-Path $Arquivo)) {
  if ($SoVerificar) { 'FALTA_ARQUIVO'; return }
  Aviso "Não achei o arquivo do jogo:`n$Arquivo`n`nPeça ao Claude para reinstalar o jogo." 'Error'
  return
}

$abertos = @(Get-Process RobloxStudioBeta -ErrorAction SilentlyContinue |
  Where-Object { $_.MainWindowTitle -like "*$nome*" })

if ($abertos.Count -gt 0) {
  if ($SoVerificar) { "JA_ABERTO:$($abertos.Count)"; return }
  # Traz o Studio que já está aberto para a frente
  $shell = New-Object -ComObject WScript.Shell
  $null = $shell.AppActivate($abertos[0].Id)
  $extra = ''
  if ($abertos.Count -gt 1) {
    $extra = "`n`nATENÇÃO: há $($abertos.Count) Studios abertos com este jogo. Feche os que sobrarem e deixe só um (se perguntar, escolha 'Não salvar')."
  }
  Aviso ("O jogo já está aberto no Roblox Studio, então não vou abrir de novo para não dar conflito.`n`nUse a janela que já está aberta e aperte F5 para jogar." + $extra) 'Warning'
  return
}

if ($SoVerificar) { 'VAI_ABRIR'; return }

# Liga o Rojo (que manda o código para o Studio), se ainda não estiver ligado
$rojo = Join-Path $env:USERPROFILE '.rokit\bin\rojo.exe'
$projeto = Join-Path $PSScriptRoot '..\jogo\default.project.json'
if ((Test-Path $rojo) -and -not (Get-Process rojo -ErrorAction SilentlyContinue)) {
  Start-Process -FilePath $rojo -ArgumentList 'serve', "`"$projeto`"" -WindowStyle Minimized
}

Start-Process -FilePath $Arquivo
Aviso "Abrindo o jogo no Roblox Studio...`n`nQuando ele carregar, clique em 'Connect' no aviso do Rojo e depois aperte F5 (ou o botão Testar) para jogar." 'Information'
