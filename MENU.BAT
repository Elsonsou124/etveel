@echo off
net session >nul 2>&1
if errorlevel 1 (
  powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)
set "BATDRIVE=%~d0"
set "INSTALLER_FILE=%~f0"
powershell -NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -Command "$s=[IO.File]::ReadAllText($env:INSTALLER_FILE); $a=$s.IndexOf('#'+'PSSTART'); $b=$s.IndexOf('#'+'PSEND'); try { iex $s.Substring($a, $b-$a) } catch { Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.MessageBox]::Show(\"Erro no menu: $_\") }"
exit /b

#PSSTART
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# =====================================================================
# CONFIGURACOES INICIAIS E VARIAVEIS
# =====================================================================
$drive     = $env:BATDRIVE
$BASE      = "$drive\Windows\Tudo"
$WINRARDIR = "C:\Program Files\WinRAR"

# =====================================================================
# TWEAKS DO SISTEMA (Executados invisivelmente ao abrir o BAT)
# =====================================================================

# --- DESATIVAR SUSPENSAO, DESLIGAMENTO DE TELA E HIBERNACAO ---
try {
    # Desligar tela / Video (Tomada e Bateria -> 0 = Nunca)
    powercfg /change monitor-timeout-ac 0 > $null
    powercfg /change monitor-timeout-dc 0 > $null
    
    # Suspender / Standby (Tomada e Bateria -> 0 = Nunca)
    powercfg /change standby-timeout-ac 0 > $null
    powercfg /change standby-timeout-dc 0 > $null

    # Hibernar (Tomada e Bateria -> 0 = Nunca)
    powercfg /change hibernate-timeout-ac 0 > $null
    powercfg /change hibernate-timeout-dc 0 > $null
    
    # Desativa completamente o recurso de hibernação do Windows para evitar travamentos
    powercfg /hibernate off > $null

    # Forca a aplicacao imediata no plano atual
    powercfg /setactive SCHEME_CURRENT > $null
} catch {
    # Silencioso caso nao tenha permissao ou suporte a algum parametro
}

# --- ATIVAR ICONES DA AREA DE TRABALHO (Meu Computador, Usuario e Painel de Controle) ---
$iconsPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel"
if (-not (Test-Path $iconsPath)) { New-Item -Path $iconsPath -Force | Out-Null }
Set-ItemProperty -Path $iconsPath -Name "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" -Value 0 -Type DWord -Force 
Set-ItemProperty -Path $iconsPath -Name "{59031a47-3f72-44a7-89c5-5595fe6b30ee}" -Value 0 -Type DWord -Force 
Set-ItemProperty -Path $iconsPath -Name "{5399E694-6CE5-4D6C-8FCE-1D8870FDCBA0}" -Value 0 -Type DWord -Force 

# --- ATIVAR VISUALIZADOR DE FOTOS CLASSICO (SILENCIOSO) ---
$photoPath = "HKLM:\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations"
if (-not (Test-Path $photoPath)) { New-Item -Path $photoPath -Force | Out-Null }
foreach ($ext in @('.jpg','.jpeg','.png','.bmp','.gif','.tif','.tiff')) {
    New-ItemProperty -Path $photoPath -Name $ext -Value 'PhotoViewer.FileAssoc.Tiff' -PropertyType String -Force | Out-Null
}

# --- GERADOR AUTOMATICO DO ARQUIVO RARREG ---
if (-not (Test-Path "$WINRARDIR\rarreg.key")) {
    if (-not (Test-Path $WINRARDIR)) { New-Item -ItemType Directory -Force -Path $WINRARDIR | Out-Null }
    $txtPath = "$WINRARDIR\rarreg.txt"
    Set-Content -Path $txtPath -Value "RAR registration data`r`nchattchitto.com`r`nUnlimited Company License`r`nUID=45cf7e253572312b6995`r`n64122122506995900ddabb88b22559b8f25d88e1168dd8cea3bd59`r`nfe190143727199246a8460fce6cb5ffde62890079861be57638717`r`n7131ced835ed65cc743d9777f2ea71a8e32c7e593cf66794343565`r`nb41bcf56929486b8bcdac33d50ecf7739960e36503ffdcbcf7dbfc`r`n378eb1e8a5d96ddf9e5c7d6e7b122c103ee81bce156ee5ec1cf50d`r`n174c5a231523f967f5c53a4efdc7ecb9689f18a2ed6166f7608276`r`n7f5dd734a2736b2d5fb6eb5145b50ed0c7033251fe142027056408" -Force
    Rename-Item -Path $txtPath -NewName "rarreg.key" -Force
}

# --- FORCA A ATUALIZACAO DA AREA DE TRABALHO (PISCA/REFRESH) ---
$refreshCode = @'
[System.Runtime.InteropServices.DllImport("Shell32.dll")]
public static extern int SHChangeNotify(int eventId, int flags, IntPtr item1, IntPtr item2);
public static void Atualizar() { SHChangeNotify(0x08000000, 0x1000, IntPtr.Zero, IntPtr.Zero); }
'@
Add-Type -MemberDefinition $refreshCode -Namespace "WinAPI" -Name "Desktop" -ErrorAction SilentlyContinue
[WinAPI.Desktop]::Atualizar()

# =====================================================================
# VARIAVEIS DE EXECUCAO SILENCIOSA (Para os lotes de instalacao)
# =====================================================================

# --- GERADOR DE LICENCA WINRAR ---
$rarKey = '$WINRARDIR = "C:\Program Files\WinRAR"; if (-not (Test-Path "$WINRARDIR\rarreg.key")) { if (-not (Test-Path $WINRARDIR)) { New-Item -ItemType Directory -Force -Path $WINRARDIR | Out-Null }; Set-Content -Path "$WINRARDIR\rarreg.key" -Value "RAR registration data`r`nchattchitto.com`r`nUnlimited Company License`r`nUID=45cf7e253572312b6995`r`n64122122506995900ddabb88b22559b8f25d88e1168dd8cea3bd59`r`nfe190143727199246a8460fce6cb5ffde62890079861be57638717`r`n7131ced835ed65cc743d9777f2ea71a8e32c7e593cf66794343565`r`nb41bcf56929486b8bcdac33d50ecf7739960e36503ffdcbcf7dbfc`r`n378eb1e8a5d96ddf9e5c7d6e7b122c103ee81bce156ee5ec1cf50d`r`n174c5a231523f967f5c53a4efdc7ecb9689f18a2ed6166f7608276`r`n7f5dd734a2736b2d5fb6eb5145b50ed0c7033251fe142027056408" -Force; Write-Host "##INFO Licenca do WinRAR gerada automaticamente" }'

# --- COPIADOR DE ATALHOS DO OFFICE ---
$officeShortcuts = '$achou = $false; $desk = Join-Path ([Environment]::GetFolderPath("Desktop")) "Office 365"; $pastas = @("$env:ProgramData\Microsoft\Windows\Start Menu\Programs", "$env:APPDATA\Microsoft\Windows\Start Menu\Programs"); foreach ($app in @("*Word*.lnk", "*Excel*.lnk", "*PowerPoint*.lnk", "*Access*.lnk", "*Publisher*.lnk", "*OneNote*.lnk")) { foreach ($dir in $pastas) { if (Test-Path $dir) { $arquivos = Get-ChildItem -Path $dir -Filter $app -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Name -notmatch "Wordpad|Voice" }; foreach ($arq in $arquivos) { if (-not $achou) { if (-not (Test-Path $desk)) { New-Item -ItemType Directory -Force -Path $desk | Out-Null }; $achou = $true }; Copy-Item -Path $arq.FullName -Destination $desk -Force } } } }; if ($achou) { Write-Host "##INFO Atalhos do Office copiados com sucesso!" } else { Write-Host "##INFO Nenhum atalho achado. O Office ja terminou de instalar?" }'

# =====================================================================
# FUNCOES DO SISTEMA DE TAREFAS E LOGS
# =====================================================================

$global:tasks = New-Object System.Collections.ArrayList
$global:totalEtapas = 0
$global:etapaAtual = 0

function Log($msg) { $logBox.AppendText((Get-Date -Format 'HH:mm:ss') + "  " + $msg + "`r`n") }

function Start-Task($titulo, $script, $total = 1) {
    $out = Join-Path $env:TEMP ("inst_" + ($titulo -replace '[^a-zA-Z0-9]','') + ".txt")
    $script = "& { " + $script + " } *> '$out'; exit `$LASTEXITCODE"

    # Executa o lote por arquivo .ps1, evitando limites de tamanho do -EncodedCommand.
    $worker = Join-Path $env:TEMP ("inst_worker_" + [guid]::NewGuid().ToString("N") + ".ps1")
    [IO.File]::WriteAllText($worker, $script, [Text.Encoding]::Unicode)

    if (Test-Path $out) { Remove-Item $out -Force -ErrorAction SilentlyContinue }
    $args = '-NoProfile -ExecutionPolicy Bypass -File "' + $worker + '"'
    $p = Start-Process -FilePath "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -ArgumentList $args -WindowStyle Hidden -PassThru
    [void]$global:tasks.Add(@{ Nome = $titulo; Proc = $p; Out = $out; Lido = 0; Ok = 0; Ja = 0; Erro = 0 })

    $global:totalEtapas = $total
    $global:etapaAtual = 0

    if ($total -gt 1) {
        $progressBar.Style = [System.Windows.Forms.ProgressBarStyle]::Blocks
        $progressBar.Minimum = 0
        $progressBar.Maximum = $total
        $progressBar.Value = 0
        $lblStatus.Text = "Instalando lote: $titulo (0/$total)..."
        $lblStatus.ForeColor = [System.Drawing.Color]::FromArgb(0, 255, 180)
    } else {
        $progressBar.Style = [System.Windows.Forms.ProgressBarStyle]::Marquee
        $progressBar.MarqueeAnimationSpeed = 30

        $qtdFila = $global:tasks.Count
        if ($qtdFila -gt 1) {
            $lblStatus.Text = "Instalando: $titulo (Fila: $qtdFila tarefas)..."
        } else {
            $lblStatus.Text = "Instalando: $titulo..."
        }
        $lblStatus.ForeColor = [System.Drawing.Color]::FromArgb(0, 230, 255)
    }

    Log "=== Iniciando: $titulo ==="
}

function W($id) { "winget install -e --id $id --source winget --accept-package-agreements --accept-source-agreements" }

function Passo($n, $tot, $nome, $cmd) {
    "Write-Host '##AGORA [$n/$tot] $nome'; `$global:LASTEXITCODE = 0; $cmd; `$c = `$global:LASTEXITCODE; " +
    "if (`$c -eq 0) { Write-Host '##OK $nome' } elseif (`$c -eq -1978335189) { Write-Host '##JA $nome' } " +
    "else { Write-Host ('##ERRO $nome (codigo ' + `$c + ')'); `$global:falhou = 1 }"
}

function Lote($passos) { "`$global:falhou = 0; " + ($passos -join "; ") + "; `$global:LASTEXITCODE = [int]`$global:falhou" }

# =====================================================================
# FUNCOES DO OFFICE
# =====================================================================

function Preparar-Office {
    try {
        Log "Preparando o instalador do Office..."
        $exe = Join-Path $env:TEMP 'OfficeSetup.exe'
        $txt = [IO.File]::ReadAllText($env:INSTALLER_FILE)
        $m = '###' + 'PAYLOAD###'
        $i = $txt.LastIndexOf($m)
        if ($i -lt 0) { throw "Instalador do Office nao encontrado dentro do arquivo." }
        $bytes = [Convert]::FromBase64String(($txt.Substring($i + $m.Length) -replace '[^A-Za-z0-9+/=]',''))
        try { [IO.File]::WriteAllBytes($exe, $bytes) }
        catch { $exe = Join-Path $env:TEMP ("OfficeSetup_" + (Get-Date -Format 'HHmmss') + ".exe"); [IO.File]::WriteAllBytes($exe, $bytes) }
        Log "Instalador pronto: $exe"
        return $exe
    } catch {
        Log "ERRO ao preparar o Office: $_"
        [System.Windows.Forms.MessageBox]::Show("Erro ao preparar o Office:`r`n$_") | Out-Null
        return $null
    }
}

# =====================================================================
# INTERFACE GRAFICA (Forms, Cores e Design)
# =====================================================================

$programIcon = [System.Drawing.SystemIcons]::Application

$form = New-Object System.Windows.Forms.Form
$form.Icon = $programIcon
$form.ShowIcon = $true
$form.Text = "ASSISTENTE DE FORMATAÇÃO PRO"
$form.Size = New-Object System.Drawing.Size(780, 710)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox = $false
$form.BackColor = [System.Drawing.Color]::FromArgb(12, 14, 20)
$form.ForeColor = [System.Drawing.Color]::White
$form.Font = New-Object System.Drawing.Font("Segoe UI", 10)

$titlePanel = New-Object System.Windows.Forms.Panel
$titlePanel.Size = New-Object System.Drawing.Size(780, 50)
$titlePanel.Location = New-Object System.Drawing.Point(0, 0)
$titlePanel.BackColor = [System.Drawing.Color]::FromArgb(20, 25, 35)
$form.Controls.Add($titlePanel)

$title = New-Object System.Windows.Forms.Label
$title.Text = "ASSISTENTE DE FORMATAÇÃO"
$title.Font = New-Object System.Drawing.Font("Segoe UI Black", 16, [System.Drawing.FontStyle]::Bold)
$title.ForeColor = [System.Drawing.Color]::FromArgb(0, 255, 160)
$title.AutoSize = $true
$title.Location = New-Object System.Drawing.Point(20, 10)
$titlePanel.Controls.Add($title)

$subTitle = New-Object System.Windows.Forms.Label
$subTitle.Text = "CENTRAL DE AUTOMAÇÃO"
$subTitle.Font = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
$subTitle.ForeColor = [System.Drawing.Color]::FromArgb(0, 180, 255)
$subTitle.AutoSize = $true
$subTitle.Location = New-Object System.Drawing.Point(400, 20)
$titlePanel.Controls.Add($subTitle)

# =====================================================================
# LISTA DE ACOES DOS BOTOES
# =====================================================================

$actions = [ordered]@{
    "Ativação Windows"           = { Start-Process powershell -ArgumentList "-NoProfile -WindowStyle Hidden -Command `"& ([ScriptBlock]::Create((irm https://get.activated.win))) `"" ; Log "Tela de Ativacao do Windows foi Aberta" }
    "Instalar Google Chrome"        = { Start-Task "Chrome" (Lote @(Passo 1 1 "Chrome" (W "Google.Chrome"))) }
    "Instalar WinRAR"               = { Start-Task "WinRAR" (Lote @((Passo 1 1 "WinRAR" (W "RARLab.WinRAR")), $rarKey)) }
    "Instalar MSI Afterburner"      = { Start-Task "Afterburner" (Lote @(Passo 1 1 "MSI Afterburner" (W "Guru3D.Afterburner"))) }
    
    "Instalar Apenas o Office"      = {
        $exe = Preparar-Office
        if ($exe) {
            Start-Process -FilePath $exe
            Log "Instalador do Office aberto na tela com sucesso."
        }
    }
    
    "Copiar Atalhos do Office"      = { Start-Task "Copiando Atalhos" (Lote @($officeShortcuts)) }
    
    "TUDO (Sem MSI e sem Office)"   = {
        Start-Task "TUDO Sem MSI e sem Office" (Lote @(
            (Passo 1 3 "Chrome" (W "Google.Chrome")),
            (Passo 2 3 "Acrobat Reader" (W "Adobe.Acrobat.Reader.64-bit")),
            (Passo 3 3 "WinRAR" (W "RARLab.WinRAR")), $rarKey
        ))
    }
    
    "INSTALAR TUDO (Sem MSI)"       = {
        Start-Task "INSTALAR TUDO (Sem MSI)" (Lote @(
            (Passo 1 4 "Chrome" (W "Google.Chrome")),
            (Passo 2 4 "Acrobat Reader" (W "Adobe.Acrobat.Reader.64-bit")),
            (Passo 3 4 "WinRAR" (W "RARLab.WinRAR")),
            (Passo 4 4 "Office" ('$txt = [IO.File]::ReadAllText("$env:INSTALLER_FILE"); $m = "###" + "PAYLOAD###"; $i = $txt.LastIndexOf($m); if ($i -ge 0) { $bytes = [Convert]::FromBase64String(($txt.Substring($i + $m.Length) -replace "[^A-Za-z0-9+/=]","")); $exe = Join-Path $env:TEMP "OfficeSetup.exe"; try { [IO.File]::WriteAllBytes($exe, $bytes) } catch { $exe = Join-Path $env:TEMP ("OfficeSetup_" + (Get-Date -Format "HHmmss") + ".exe"); [IO.File]::WriteAllBytes($exe, $bytes) }; Start-Process -FilePath $exe }'))
        )) -total 4
    }
    
    "INSTALAR TUDO + Office"        = {
        Start-Task "TUDO com Office" (Lote @(
            (Passo 1 5 "Chrome" (W "Google.Chrome")),
            (Passo 2 5 "Acrobat Reader" (W "Adobe.Acrobat.Reader.64-bit")),
            (Passo 3 5 "WinRAR" (W "RARLab.WinRAR")), $rarKey,
            (Passo 4 5 "MSI Afterburner" (W "Guru3D.Afterburner")),
            (Passo 5 5 "Office" ('$txt = [IO.File]::ReadAllText("$env:INSTALLER_FILE"); $m = "###" + "PAYLOAD###"; $i = $txt.LastIndexOf($m); if ($i -ge 0) { $bytes = [Convert]::FromBase64String(($txt.Substring($i + $m.Length) -replace "[^A-Za-z0-9+/=]","")); $exe = Join-Path $env:TEMP "OfficeSetup.exe"; try { [IO.File]::WriteAllBytes($exe, $bytes) } catch { $exe = Join-Path $env:TEMP ("OfficeSetup_" + (Get-Date -Format "HHmmss") + ".exe"); [IO.File]::WriteAllBytes($exe, $bytes) }; Start-Process -FilePath $exe }'))
        )) -total 5
    }
}

# =====================================================================
# RENDERIZACAO DOS BOTOES
# =====================================================================

$y = 65
foreach ($name in $actions.Keys) {
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = $name
if ($name -eq "Instalar Apenas o Office") {
    $script:btnOffice = $btn
}
    $btn.Size = New-Object System.Drawing.Size(290, 46)
    $btn.Location = New-Object System.Drawing.Point(20, $y)
    $btn.FlatStyle = "Flat"
    $btn.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 10)
    $btn.Cursor = [System.Windows.Forms.Cursors]::Hand

    if ($name -like "INSTALAR TUDO (Sem MSI)*" -or $name -like "TUDO (Sem MSI e sem Office)*") { 
        $btn.BackColor = [System.Drawing.Color]::FromArgb(0, 160, 200)
        $btn.ForeColor = [System.Drawing.Color]::White
        $btn.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(0, 230, 255)
        $btn.FlatAppearance.BorderSize = 2
    }
    elseif ($name -like "INSTALAR TUDO + Office*") { 
        $btn.BackColor = [System.Drawing.Color]::FromArgb(0, 200, 100)
        $btn.ForeColor = [System.Drawing.Color]::FromArgb(10, 20, 10)
        $btn.Font = New-Object System.Drawing.Font("Segoe UI Black", 10, [System.Drawing.FontStyle]::Bold)
        $btn.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(0, 255, 150)
        $btn.FlatAppearance.BorderSize = 2
    }
    else {
        $btn.BackColor = [System.Drawing.Color]::FromArgb(24, 30, 42)
        $btn.ForeColor = [System.Drawing.Color]::FromArgb(220, 235, 255)
        $btn.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(0, 180, 220)
        $btn.FlatAppearance.BorderSize = 1
    }

    $btn.Tag = @{ Acao = $actions[$name]; Cor = $btn.BackColor }
    $btn.Add_MouseEnter({ $this.BackColor = [System.Drawing.Color]::FromArgb(40, 55, 80) })
    $btn.Add_MouseLeave({ $this.BackColor = $this.Tag.Cor })
    $btn.Add_Click({ try { & $this.Tag.Acao } catch { [System.Windows.Forms.MessageBox]::Show("Erro: $_") } })
    $form.Controls.Add($btn)
    $y += 52
}

$sair = New-Object System.Windows.Forms.Button
$sair.Text = "Sair"
$sair.Size = New-Object System.Drawing.Size(290, 38)
$sair.Location = New-Object System.Drawing.Point(20, ($y + 8))
$sair.FlatStyle = "Flat"
$sair.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$sair.BackColor = [System.Drawing.Color]::FromArgb(140, 20, 30)
$sair.ForeColor = [System.Drawing.Color]::White
$sair.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(255, 60, 80)
$sair.Cursor = [System.Windows.Forms.Cursors]::Hand
$sair.Add_Click({ $form.Close() })
$form.Controls.Add($sair)

$logTitle = New-Object System.Windows.Forms.Label
$logTitle.Text = "LOG DE INSTALAÇÃO"
$logTitle.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$logTitle.ForeColor = [System.Drawing.Color]::FromArgb(0, 255, 160)
$logTitle.AutoSize = $true
$logTitle.Location = New-Object System.Drawing.Point(335, 65)
$form.Controls.Add($logTitle)

$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Text = "Aguardando comando..."
$lblStatus.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9)
$lblStatus.ForeColor = [System.Drawing.Color]::FromArgb(160, 175, 200)
$lblStatus.AutoSize = $true
$lblStatus.Location = New-Object System.Drawing.Point(335, 93)
$form.Controls.Add($lblStatus)

$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(335, 115)
$progressBar.Size = New-Object System.Drawing.Size(410, 20)
$progressBar.Style = [System.Windows.Forms.ProgressBarStyle]::Blocks
$form.Controls.Add($progressBar)

$logBox = New-Object System.Windows.Forms.TextBox
$logBox.Multiline = $true
$logBox.ReadOnly = $true
$logBox.ScrollBars = "Vertical"
$logBox.Location = New-Object System.Drawing.Point(335, 142)
$logBox.Size = New-Object System.Drawing.Size(410, 488)
$logBox.BackColor = [System.Drawing.Color]::FromArgb(6, 8, 12)
$logBox.ForeColor = [System.Drawing.Color]::FromArgb(0, 255, 130)
$logBox.Font = New-Object System.Drawing.Font("Consolas", 9.5)
$logBox.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$form.Controls.Add($logBox)

$watermark = New-Object System.Windows.Forms.Label
$watermark.Text = "ELSON (Criatividade E Tudo)"
$watermark.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Italic)
$watermark.ForeColor = [System.Drawing.Color]::FromArgb(0, 180, 255)
$watermark.AutoSize = $true
$watermark.Location = New-Object System.Drawing.Point(575, 638)
$form.Controls.Add($watermark)

# =====================================================================
# TIMER: PROCESSAMENTO DO LOG E FILA
# =====================================================================

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 1000
function Ler-Novas($t) {
    if (-not (Test-Path $t.Out)) { return }
    $linhas = @(Get-Content $t.Out -ErrorAction SilentlyContinue)
    for ($k = $t.Lido; $k -lt $linhas.Count; $k++) {
        $l = "$($linhas[$k])".Trim()
		if ($l -eq "##CLIQUE_OFFICE") {
    $form.BeginInvoke([Action]{
        Clicar-Office
    }) | Out-Null
    continue
    }
        if ($l -match '^##AGORA \[(\d+)/(\d+)\] (.+)$') {
            Log ("  > Instalando agora: " + $matches[3] + " (" + $matches[1] + "/" + $matches[2] + ")")
            $lblStatus.Text = "Instalando agora: " + $matches[3] + " (" + $matches[1] + "/" + $matches[2] + ")"
            if ($global:totalEtapas -gt 1) { $progressBar.Value = [Math]::Min([int]$matches[1] - 1, $progressBar.Maximum) }
        }
        elseif ($l -match '^##OK (.+)$')   { $t.Ok++;   Log ("  [OK]   " + $matches[1] + " instalado") }
        elseif ($l -match '^##JA (.+)$')   { $t.Ja++;   Log ("  [JA]   " + $matches[1] + " ja estava instalado") }
        elseif ($l -match '^##ERRO (.+)$') {
            $t.Erro++; Log ("  [ERRO] " + $matches[1])
            if ($matches[1] -like '*Afterburner*') { Log "         Baixe manualmente no site da MSI (abrindo...)"; Start-Process "https://www.msi.com/Landing/afterburner/graphics-cards" }
        }
        elseif ($l -match '^##INFO (.+)$') { Log ("         " + $matches[1]) }
    }
    $t.Lido = $linhas.Count
}

$timer.Add_Tick({
    foreach ($t in @($global:tasks)) {
        Ler-Novas $t
        if ($t.Proc.HasExited) {
            Start-Sleep -Milliseconds 200
            Ler-Novas $t
            Log ("=== Fim: " + $t.Nome + " | instalados: " + $t.Ok + " | ja tinha: " + $t.Ja + " | erros: " + $t.Erro + " ===")
            $global:tasks.Remove($t)
            if ($global:tasks.Count -gt 0) {
                $lblStatus.Text = "Ainda em andamento: " + $global:tasks[0].Nome + " (" + $global:tasks.Count + " na fila)"
            } else {
                $progressBar.Style = [System.Windows.Forms.ProgressBarStyle]::Blocks
                $progressBar.Value = $progressBar.Maximum
                if ($t.Erro -gt 0) {
                    $lblStatus.Text = "Concluido com erros - veja o log"
                    $lblStatus.ForeColor = [System.Drawing.Color]::FromArgb(255, 90, 90)
                } else {
                    $lblStatus.Text = "Concluido com sucesso!"
                    $lblStatus.ForeColor = [System.Drawing.Color]::FromArgb(0, 255, 160)
                }
            }
        }
    }
})
$timer.Start()

$form.Show()
[System.Windows.Forms.Application]::Run($form)


$timer.Stop()
$timer.Dispose()
$form.Dispose()
#PSEND
###PAYLOAD###
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
iU3ox0XsBwAAAGaJRdhRUY1F2IlN/FBoAwAAgLm4z6gA6N17AACLReyD+Ad2J4tN2I0ERQIAAAA9
ABAAAHIPi1H8K8qNQfyD+B93GovKUejcTDwAWWhkVoMA6O6KOwBZ6LeTOwDDagVZzSloblaDAOjY
ijsAWcNoiVaDAOjMijsAWcNopFaDAOjAijsAWcNov1aDAOi0ijsAWcNo2laDAOioijsAWcNo9VaD
AOicijsAWcNoEFeDAOiQijsAWcNoK1eDAOiEijsAWcNoRleDAOh4ijsAWcNoYVeDAOhsijsAWcNo
fFeDAOhgijsAWcNol1eDAOhUijsAWcNosleDAOhIijsAWcNozVeDAOg8ijsAWcNo6FeDAOgwijsA
WcNoA1iDAOgkijsAWcNoHliDAOgYijsAWcNoOViDAOgMijsAWcNoVFiDAOgAijsAWcNob1iDAOj0
iTsAWcNoiliDAOjoiTsAWcNopViDAOjciTsAWcNowFiDAOjQiTsAWcNo21iDAOjEiTsAWcNo9liD
AOi4iTsAWcNoEVmDAOisiTsAWcNoLFmDAOigiTsAWcNoR1mDAOiUiTsAWcNoYlmDAOiIiTsAWcNo
fVmDAOh8iTsAWcNomFmDAOhwiTsAWcNos1mDAOhkiTsAWcNozlmDAOhYiTsAWcNo6VmDAOhMiTsA
WcNoaMyGALnkz6gA6OVfAABoBFqDAOgxiTsAWcNoDlqDAOgliTsAWcNoUM6GALkE0KgA6L5fAABo
GFqDAOgKiTsAWcNoIlqDAOj+iDsAWcNowOCHALkc0KgA6JdfAABoLFqDAOjjiDsAWcNoyKWGALmg
eqgA6HxfAABoNlqDAOjIiDsAWcNoSKWGALm4eqgA6GFfAABoQFqDAOitiDsAWcNoc1qDAMcFgCuj
AHwrowDol4g7AFnDaH5agwDowYs7AFnDaJFagwDHBYwrowCIK6MA6HWIOwBZw2icWoMA6GmIOwBZ
w6EccagAuSB2owCjCHajAMcFHHGoAAh2owDomMIIALlUdqMAxwVQdqMAAAAAAOiEwggAaLdagwDH
BYR2owAAAAAAxwUAdqMAjLCIAMcFBHajALCwiADoDYg7AFnDM8AzyaOQdqMAiQ2UdqMAw2jLWoMA
6CeLOwBZw+jyCQkAaN5agwDo4Ic7AFnDaATCiAC5eHyoAOh5XgAAaOhagwDoxYc7AFnDaJDBiAC5
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
iYVQ8P//jYVM8P//UOiSLhkAaGiNiwCNjZD3///GRfwe6KXxBwCNhZj+//9QjY2o9///6HwsGQCN
havw///GRfwfUGhgm4sAjY2o+v//xoWr8P//AehulhkAUVGNjQD7///GRfwg6Co+GgCNharw///G
RfwhUGgMm4sAjY1Y+///iJ2q8P//6DyWGQDGRfwijYWo+v//iYVE8P//jY1Y/v//jYWw+///iYVI
8P//jYVE8P//UOjqLRkAaNiOiwCNjej3///GRfwj6P3wBwCNhVj+//9QjY0A+P//6NQrGQBotHWL
AI2NsPv//8ZF/CTo1/AHAGgAACAAjY3I+///xkX8JejbkhkAaKR1iwCNjQj8///GRfwm6K/wBwBq
BY2NIPz//8ZF/CfotpIZAI2FqfD//8ZF/ChQaHSbiwCNjWD8///Ghanw//8B6HmVGQBolHWLAI2N
uPz//8ZF/CnoaPAHAGiIjYsAjY3Q/P//xkX8Kui7KxkAxkX8K42FsPv//4mFdPD//42NGP7//42F
EP3//4mFePD//42FdPD//1Do/ywZAGjAdYsAjY1A+P//xkX8LOgS8AcAjYUY/v//UI2NWPj//+jp
KhkAjYWo8P//xkX8LVBoUJuLAI2NEP3//8aFqPD//wHo25QZAGi8josAjY1o/f//xkX8LujK7wcA
aLSNiwCNjYD9///GRfwv6B0rGQDGRfwwjYUQ/f//iYVs8P//jY1Y////jYXA/f//iYVw8P//jYVs
8P//UOhhLBkAaMx1iwCNjZj4///GRfwx6HTvBwCNhVj///9QjY2w+P//6EsqGQBorI2LAI1NmMZF
/DLoUe8HAFONTbDGRfwz6FyRGQDGRfw0jUWYiYVk8P//jY0Y////jUXwiYVo8P//jYVk8P//UOj1
KxkAaHSNiwCNjfD4///GRfw16AjvBwCNhRj///9QjY0I+f//6N8pGQDGRfxCjYWw8P//iYVc8P//
uXyRqACNhUj5//+JhWDw//+NhVzw//9Q6PSKGQBoWzNZAGoZalhfV42FsPD//8ZF/EFQ6AhzOwCN
jRj////oa+kYAL5bM1kAxkX8P1ZqAVeNRZhQ6OdyOwCNjVj////oSukYAFZqAleNhRD9///GRfw9
UOjIcjsAjY0Y/v//6CvpGABWagRXjYWw+///xkX8O1DoqXI7AI2NWP7//+gM6RgAVmoDV42FqPr/
/8ZF/DlQ6IpyOwCNjZj+///o7egYAFZqAVeNhcD9///GRfw3UOhrcjsAjY3Y/v//6M7oGABWagRX
jYVI+f//x0X8/////1DoSXI7AGghZIMA6AdyOwBZ6NB6OwDDaFxkgwDo9nE7AFnDaLAPAAC4wBCB
AOgFezsAaHh1iwCNjbDw///os+0HADPbjY3I8P//agSJXfzouY8ZAGiMdYsAjY0I8f//x0X8AQAA
AOiK7QcAU42NIPH//8ZF/ALoko8ZAI2FpvD//8ZF/ANQaOSbiwCNjWDx//+Inabw///oVpIZAI2F
fPD//8ZF/ARQaCSciwCNjbjx///HhXzw//8AADAA6GySGQCNhYDw///GRfwFUGgUnIsAjY0Q8v//
x4WA8P//AAAIAOhHkhkAjYWI8P//xkX8BlBoEJyLAI2NaPL//4mdiPD//+gmkhkAjYWl8P//xkX8
B1Bo7JuLAI2NwPL//8aFpfD//wHoyZEZAI2FpPD//8ZF/AhQaACciwCNjRjz//+InaTw///oqJEZ
AI2FjPD//8ZF/AlQaBiciwCNjXDz///HhYzw//8BAAAA6L6RGQCNhZDw///GRfwKUMeFkPD//wQA
AABo4JuLAI2NyPP//+iZkRkAjYWU8P//xkX8C1BoDJyLAI2NIPT//8eFlPD//wMAAADodJEZAI2F
mPD//8ZF/AxQaPSbiwCNjXj0//+JnZjw///oU5EZAI2Fr/D//8ZF/A1QaAiciwCNjdD0///Gha/w
//8B6PaQGQBonHSLAI2NKPX//8ZF/A7o5esHAGi8e4sAjY1A9f//xkX8D+g4JxkAaktejYWc8P//
xkX8EFBo6JuLAI2NgPX//4m1nPD//+jlkBkAjYWg8P//xkX8EVBoIJyLAI2N2PX//8eFoPD//4gT
AADowJAZAI2FhPD//8ZF/BJQaPybiwCNjTD2//+JtYTw///on5AZAI2FrvD//8ZF/BNQaCiciwCN
jYj2///Gha7w//8B6EKQGQCNhafw///GRfwUUGgcnIsAjY3g9v//iJ2n8P//6CGQGQDGRfwViJ2t
8P//jYWt8P//UFGNjUj5///oJDcaAGgQdYsAjY2g+f//xkX8Fujz6gcAaAgHAACNjbj5///GRfwX
6PeMGQBRUY2N+Pn//8ZF/BjoJjcaAFFRjY1Q+v//xkX8GehONxoAxkX8Go2FSPn//4mFVPD//42N
2P7//42FqPr//4mFWPD//42FVPD//1DoaCcZAGgIdYsAjY049///xkX8G+h76gcAjYXY/v//UI2N
UPf//+hSJRkAjYWs8P//xkX8HFBoMJyLAI2NwP3//4idrPD//+hFjxkAxkX8HY2FwP3//4mFTPD/
/42NmP7//42FGP7//4mFUPD//42FTPD//1Do8yYZAGhojYsAjY2Q9///xkX8HugG6gcAjYWY/v//
UI2NqPf//+jdJBkAjYWr8P//xkX8H1Bo+JuLAI2NqPr//8aFq/D//wHoz44ZAFFRjY0A+///xkX8
IOiLNhoAjYWq8P//xkX8IVBoBJyLAI2NWPv//4idqvD//+idjhkAxkX8Io2FqPr//4mFRPD//42N
WP7//42FsPv//4mFSPD//42FRPD//1DoSyYZAGjYjosAjY3o9///xkX8I+he6QcAjYVY/v//UI2N
APj//+g1JBkAaLR1iwCNjbD7///GRfwk6DjpBwBoAAAgAI2NyPv//8ZF/CXoPIsZAGikdYsAjY0I
/P//xkX8JugQ6QcAagWNjSD8///GRfwn6BeLGQCNhanw///GRfwoUGgsnIsAjY1g/P//xoWp8P//
AejajRkAaJR1iwCNjbj8///GRfwp6MnoBwBoiI2LAI2N0Pz//8ZF/CroHCQZAMZF/CuNhbD7//+J
hXTw//+NjRj+//+NhRD9//+JhXjw//+NhXTw//9Q6GAlGQBowHWLAI2NQPj//8ZF/Czoc+gHAI2F
GP7//1CNjVj4///oSiMZAI2FqPD//8ZF/C1QaPCbiwCNjRD9///Ghajw//8B6DyNGQBovI6LAI2N
aP3//8ZF/C7oK+gHAGi0jYsAjY2A/f//xkX8L+h+IxkAxkX8MI2FEP3//4mFbPD//42NWP///42F
wP3//4mFcPD//42FbPD//1DowiQZAGjMdYsAjY2Y+P//xkX8MejV5wcAjYVY////UI2NsPj//+is
IhkAaKyNiwCNTZjGRfwy6LLnBwBTjU2wxkX8M+i9iRkAxkX8NI1FmImFZPD//42NGP///41F8ImF
aPD//42FZPD//1DoViQZAGh0jYsAjY3w+P//xkX8Nehp5wcAjYUY////UI2NCPn//+hAIhkAxkX8
Qo2FsPD//4mFXPD//7mMkagAjYVI+f//iYVg8P//jYVc8P//UOhVgxkAaFszWQBqGWpYX1eNhbDw
///GRfxBUOhpazsAjY0Y////6MzhGAC+WzNZAMZF/D9WagFXjUWYUOhIazsAjY1Y////6KvhGABW
agJXjYUQ/f//xkX8PVDoKWs7AI2NGP7//+iM4RgAVmoEV42FsPv//8ZF/DtQ6AprOwCNjVj+///o
beEYAFZqA1eNhaj6///GRfw5UOjrajsAjY2Y/v//6E7hGABWagFXjYXA/f//xkX8N1DozGo7AI2N
2P7//+gv4RgAVmoEV42FSPn//8dF/P////9Q6KpqOwBoX2SDAOhoajsAWegxczsAwzPAM8mjZIaj
AIkNaIajAMNqALheHIEA6DJzOwBqFMdF/AAAAADoKiw8AFmFwHQkiQCJQASJQAhmx0AMAQFoc2SD
AKOckagA6BVqOwBZ6MpyOwDD6FSwCADMaLAPAAC4wBCBAOgZczsAaHh1iwCNjbDw///ox+UHADPb
jY3I8P//agSJXfzozYcZAGiMdYsAjY0I8f//x0X8AQAAAOie5QcAU42NIPH//8ZF/ALopocZAI2F
pvD//8ZF/ANQaAyeiwCNjWDx//+Inabw///oaooZAI2FfPD//8ZF/ARQaEyeiwCNjbjx///HhXzw
//8AADAA6ICKGQCNhYDw///GRfwFUGgInosAjY0Q8v//x4WA8P//AAAIAOhbihkAjYWI8P//xkX8
BlBoNJ6LAI2NaPL//4mdiPD//+g6ihkAjYWl8P//xkX8B1BoGJ6LAI2NwPL//8aFpfD//wHo3YkZ
AI2FpPD//8ZF/AhQaCieiwCNjRjz//+InaTw///ovIkZAI2FjPD//8ZF/AlQaASeiwCNjXDz///H
hYzw//8BAAAA6NKJGQCNhZDw///GRfwKUMeFkPD//wQAAABoEJ6LAI2NyPP//+itiRkAjYWU8P//
xkX8C1BoMJ6LAI2NIPT//8eFlPD//wMAAADoiIkZAI2FmPD//8ZF/AxQaByeiwCNjXj0//+JnZjw
///oZ4kZAI2Fr/D//8ZF/A1QaDieiwCNjdD0///Gha/w//8B6AqJGQBonHSLAI2NKPX//8ZF/A7o
+eMHAGi8e4sAjY1A9f//xkX8D+hMHxkAaktejYWc8P//xkX8EFBoFJ6LAI2NgPX//4m1nPD//+j5
iBkAjYWg8P//xkX8EVBoUJ6LAI2N2PX//8eFoPD//4gTAADo1IgZAI2FhPD//8ZF/BJQaCCeiwCN
jTD2//+JtYTw///os4gZAI2FrvD//8ZF/BNQaDyeiwCNjYj2///Gha7w//8B6FaIGQCNhafw///G
RfwUUGhUnosAjY3g9v//iJ2n8P//6DWIGQDGRfwViJ2t8P//jYWt8P//UFGNjUj5///oOC8aAGgQ
dYsAjY2g+f//xkX8FugH4wcAaAgHAACNjbj5///GRfwX6AuFGQBRUY2N+Pn//8ZF/BjoOi8aAFFR
jY1Q+v//xkX8GehiLxoAxkX8Go2FSPn//4mFVPD//42N2P7//42FqPr//4mFWPD//42FVPD//1Do
fB8ZAGgIdYsAjY049///xkX8G+iP4gcAjYXY/v//UI2NUPf//+hmHRkAjYWs8P//xkX8HFBoRJ6L
AI2NwP3//4idrPD//+hZhxkAxkX8HY2FwP3//4mFTPD//42NmP7//42FGP7//4mFUPD//42FTPD/
/1DoBx8ZAGhojYsAjY2Q9///xkX8Huga4gcAjYWY/v//UI2NqPf//+jxHBkAjYWr8P//xkX8H1Bo
JJ6LAI2NqPr//8aFq/D//wHo44YZAFFRjY0A+///xkX8IOifLhoAjYWq8P//xkX8IVBoLJ6LAI2N
WPv//4idqvD//+ixhhkAxkX8Io2FqPr//4mFRPD//42NWP7//42FsPv//4mFSPD//42FRPD//1Do
Xx4ZAGjYjosAjY3o9///xkX8I+hy4QcAjYVY/v//UI2NAPj//+hJHBkAaLR1iwCNjbD7///GRfwk
6EzhBwBoAAAgAI2NyPv//8ZF/CXoUIMZAGikdYsAjY0I/P//xkX8Jugk4QcAagWNjSD8///GRfwn
6CuDGQCNhanw///GRfwoUGhAnosAjY1g/P//xoWp8P//AejuhRkAaJR1iwCNjbj8///GRfwp6N3g
BwBoiI2LAI2N0Pz//8ZF/CroMBwZAMZF/CuNhbD7//+JhXTw//+NjRj+//+NhRD9//+JhXjw//+N
hXTw//9Q6HQdGQBowHWLAI2NQPj//8ZF/Czoh+AHAI2FGP7//1CNjVj4///oXhsZAI2FqPD//8ZF
/C1QaEieiwCNjRD9///Ghajw//8B6FCFGQBovI6LAI2NaP3//8ZF/C7oP+AHAGi0jYsAjY2A/f//
xkX8L+iSGxkAxkX8MI2FEP3//4mFbPD//42NWP///42FwP3//4mFcPD//42FbPD//1Do1hwZAGjM
dYsAjY2Y+P//xkX8Mejp3wcAjYVY////UI2NsPj//+jAGhkAaKyNiwCNTZjGRfwy6MbfBwBTjU2w
xkX8M+jRgRkAxkX8NI1FmImFZPD//42NGP///41F8ImFaPD//42FZPD//1DoahwZAGh0jYsAjY3w
+P//xkX8Neh93wcAjYUY////UI2NCPn//+hUGhkAxkX8Qo2FsPD//4mFXPD//7mkkagAjYVI+f//
iYVg8P//jYVc8P//UOhpexkAaFszWQBqGWpYX1eNhbDw///GRfxBUOh9YzsAjY0Y////6ODZGAC+
WzNZAMZF/D9WagFXjUWYUOhcYzsAjY1Y////6L/ZGABWagJXjYUQ/f//xkX8PVDoPWM7AI2NGP7/
/+ig2RgAVmoEV42FsPv//8ZF/DtQ6B5jOwCNjVj+///ogdkYAFZqA1eNhaj6///GRfw5UOj/YjsA
jY2Y/v//6GLZGABWagFXjYXA/f//xkX8N1Do4GI7AI2N2P7//+hD2RgAVmoEV42FSPn//8dF/P//
//9Q6L5iOwBofWSDAOh8YjsAWehFazsAw2iRZIMA6GtiOwBZw2ilZIMA6F9iOwBZw2ioZIMA6FNi
OwBZw2jGZIMA6EdiOwBZw2jQZIMA6DtiOwBZw2jaZIMA6C9iOwBZw2jkZIMA6CNiOwBZw2juZIMA
6BdiOwBZw2gkuIsAufyRqADo5N0HAGj4ZIMA6PxhOwBZw2gQuIsAucyRqADoyd0HAGgCZYMA6OFh
OwBZw2j4t4sAueSRqADort0HAGgMZYMA6MZhOwBZw2jgt4sAubSRqADok90HAGgWZYMA6KthOwBZ
w2pMuBVYgQDovWo7AGhgu4sAjU2o6G7dBwBoULuLAI1NwMdF/AAAAADoWt0HAGhEu4sAjU3YxkX8
AehJ3QcAx0X8AgAAAI1dqI118McFRJKoAAAAAADHBUiSqAAAAAAAxkX8A+jDlwcAo0SSqABWU8ZF
/ATojjUcAGhZOkgAagNqGIvDx0X8/////1DoUWE7AGggZYMA6A9hOwBZ6NhpOwDDuTySqADo1hUZ
AGgqZYMA6PRgOwBZw7kUkqgA6MAVGQBoNGWDAOjeYDsAWcMzwDPJo2SHowCJDWiHowDDagC411iB
AOitaTsAakzHRfwAAAAA6KUiPABZhcB0JIkAiUAEiUAIZsdADAEBaD5lgwCjHJKoAOiQYDsAWehF
aTsAw+jPpggAzGhgu4sAuSSSqADoUtwHAGhIZYMA6GpgOwBZw+ivDhwAaFJlgwDoWWA7AFnDoRxx
qACjlIejAMcFHHGoAJSHowDDubSHowDoh5oIADPAaFVlgwCj5IejAKPoh6MAo+yHowCi8IejAOgY
YDsAWcOhHHGoALkUiKMAo/yHowDHBRxxqAD8h6MA6JWKBgAzwGhfZYMAo0SIowCjSIijAKNMiKMA
olCIowDo2F87AFnDagC47BqAAOi3aDsAoRxxqACjWIijAMcFHHGoAFiIowAz22iAAAAAiV386KjN
KwCL8FmF9nQ8anyNTgRTUejniTsAg8QMxwYgrIwAjU4E6NKZCACNTkCJXjSJXjiJXjzowZkIAIle
cIledIleeIlefOsCi/O4dIijAIkddIijAGhpZYMAo3iIowCjfIijAIkdgIijAIkdhIijAIk1iIij
AIgdjIijAMcFcIijABSsjADoIV87AFno1mc7AMPMzMzMzKEccagAo5SIowDHBRxxqACUiKMAw2h9
ZYMA6PZeOwBZw2iMZYMAxwWsiKMApMSMAOjgXjsAWcOhHHGoAKPAiKMAxwUccagAwIijAMOhHHGo
AGiWZYMAo9yIowDHBRxxqADciKMA6KteOwBZw6EccagAo/yIowDHBRxxqAD8iKMAw2i7ZYMAxwUU
iaMA9MSMAOiAXjsAWcNosWWDAMcFJImjAAjFjADoal47AFnDaMVlgwDHBTSJowBoyIwA6FReOwBZ
w2oAuOwagADoM2c7AIM9KHqoAAB1G2jPZYMAxwUoeqgAkO1lAOgpXjsAWejeZjsAw2oAaNbQeB3o
epcIAMzMzMzMzDPAM8kLBI1EiaMAQYP5DXLzo0ySqADDaONlgwDo7107AFnDaKjbjAC5qJKoAOiI
NAAAaO1lgwDo1F07AFnDaOTbjAC5kJKoAOhtNAAAaPdlgwDouV07AFnDaNjcjAC5eJKoAOhSNAAA
aAFmgwDonl07AFnDaAjfjAC52JKoAOg3NAAAaAtmgwDog107AFnDaEjfjAC5wJKoAOgcNAAAaBVm
gwDoaF07AFnDaFDgjAC58JKoAOgBNAAAaB9mgwDoTV07AFnDaKDujAC5CJOoAOga2QcAaClmgwDo
Ml07AFnDaMjujAC5SJOoAOjLMwAAaDNmgwDoF107AFnDaD1mgwDoC107AFnDaFz5jAC5YJOoAOik
MwAAaFFmgwDo8Fw7AFnDaFj9jAC5eJOoAOiJMwAAaFtmgwDo1Vw7AFnDaMD8jAC5kJOoAOhuMwAA
aGVmgwDoulw7AFnDaFz5jAC52JOoAOhTMwAAaG9mgwDon1w7AFnDaFj9jAC5qJOoAOg4MwAAaHlm
gwDohFw7AFnDaMD8jAC5wJOoAOgdMwAAaINmgwDoaVw7AFnDoRxxqABojWaDAKN8iaMAxwUccagA
fImjAOhJXDsAWcNol2aDAOhzXzsAWcPoV7wnAGiqZoMA6CxcOwBZw2i0ZoMA6CBcOwBZw2jPZoMA
6BRcOwBZw2jZZoMA6AhcOwBZw2j0ZoMA6PxbOwBZw2g9Z4MA6PBbOwBZw2jYHZMAuSylqADoiTIA
AGhHZ4MA6NVbOwBZw2i8HZMAuUSlqADobjIAAGhRZ4MA6LpbOwBZw2gAHpMAuVylqADoUzIAAGhb
Z4MA6J9bOwBZw2jsHZMAuXSlqADoODIAAGhlZ4MA6IRbOwBZw2jEHpMAuYylqADoHTIAAGhvZ4MA
6GlbOwBZw2h5Z4MA6F1bOwBZw2igHpMAuaSlqADo9jEAAGiDZ4MA6EJbOwBZw2iNZ4MA6DZbOwBZ
w2iXZ4MA6CpbOwBZw2gAH5MAubylqADowzEAAGihZ4MA6A9bOwBZw2jYHpMAudSlqADoqDEAAGir
Z4MA6PRaOwBZw2hMHpMAueylqADojTEAAGi1Z4MA6NlaOwBZw2i/Z4MA6M1aOwBZw2gcHpMAuQSm
qADoZjEAAGjJZ4MA6LJaOwBZw2jTZ4MA6KZaOwBZw2jdZ4MA6JpaOwBZw2iIHpMAuRymqADoMzEA
AGjnZ4MA6H9aOwBZw2hoHpMAuTSmqADoGDEAAGjxZ4MA6GRaOwBZw2gUIJMAuUymqADo/TAAAGj7
Z4MA6ElaOwBZw2jsH5MAuWSmqADo4jAAAGgFaIMA6C5aOwBZw2hAIJMAuXymqADoxzAAAGgPaIMA
6BNaOwBZw2gZaIMA6AdaOwBZw2gsIJMAuZSmqADooDAAAGgjaIMA6OxZOwBZw2hgH5MAuaymqADo
hTAAAGgtaIMA6NFZOwBZw2gYH5MAucSmqADoajAAAGg3aIMA6LZZOwBZw2i4H5MAudymqADoTzAA
AGhBaIMA6JtZOwBZw2j80YcAufSmqADoNDAAAGhLaIMA6IBZOwBZw2igH5MAuQynqADoGTAAAGhV
aIMA6GVZOwBZw2joIJMAuSSnqADo/i8AAGhfaIMA6EpZOwBZw2jIeIYAuTynqADo4y8AAGhpaIMA
6C9ZOwBZw2jAIJMAuVSnqADoyC8AAGhzaIMA6BRZOwBZw2gkIZMAuWynqADorS8AAGh9aIMA6PlY
OwBZw2gIIZMAuYSnqADoki8AAGiHaIMA6N5YOwBZw2hwIJMAuZynqADody8AAGiRaIMA6MNYOwBZ
w2icvpIAubSnqADoXC8AAGibaIMA6KhYOwBZw2hcIJMAucynqADoQS8AAGilaIMA6I1YOwBZw2ic
IJMAueSnqADoJi8AAGivaIMA6HJYOwBZw2iIIJMAufynqADoCy8AAGi5aIMA6FdYOwBZw2jQIZMA
uRSoqADo8C4AAGjDaIMA6DxYOwBZw2iwIZMAuSyoqADo1S4AAGjNaIMA6CFYOwBZw2gIIpMAuUSo
qADoui4AAGjXaIMA6AZYOwBZw2joIZMAuVyoqADony4AAGjhaIMA6OtXOwBZw2hUIZMAuXSoqADo
hC4AAGjraIMA6NBXOwBZw2hAIZMAuYyoqADoaS4AAGj1aIMA6LVXOwBZw2iIIZMAuaSoqADoTi4A
AGj/aIMA6JpXOwBZw2gJaYMA6I5XOwBZw2h0IZMAubyoqADoJy4AAGgTaYMA6HNXOwBZw6EccagA
o6SKowDHBRxxqACkiqMAw+gBmSkAaDhpgwDoTVc7AFnDM8AzyaPEiqMAiQ3IiqMAw7mgq6gA6PLz
KQBoQmmDAOgnVzsAWcNoTGmDAOgbVzsAWcMzwDPJowSLowCJDQiLowDDaGZpgwDo/1Y7AFnDaHBp
gwDo81Y7AFnDM8AzyaM0i6MAiQ04i6MAw2h6aYMA6NdWOwBZw6EccagAo2SLowDHBRxxqABki6MA
w2iVaYMA6LZWOwBZw1WL7FFRjUX8x0X8AAAAAFDoGU0qAGiYaYMA6JVWOwBZycMzwDPJo4SLowCJ
DYiLowDDaKJpgwDoeFY7AFnDoRxxqABorGmDAKO0i6MAxwUccagAtIujAOhYVjsAWcNqALjsGoAA
6DdfOwC53IujAOjdgAYAxwUMjKMA9AEAAMcFEIyjAAAAAADo4l47AMPMzMzMzGoAuM+7gQDoAl87
AGosx0X8AAAAAOj6FzwAWYXAdCSJAIlABIlACGbHQAwBAWjAaYMAo+irqADo5VU7AFnoml47AMPo
JJwIAMyhHHGoAKMYjKMAxwUccagAGIyjAMOhHHGoAKM0jKMAxwUccagANIyjAMMzwDPJo1CMowCJ
DVSMowDDM8AzyaOEjKMAiQ2IjKMAw6EccagAo7SMowDHBRxxqAC0jKMAw2jKaYMA6G9VOwBZw2jU
aYMA6GNVOwBZw2jraYMA6FdVOwBZwzPAM8mj0IyjAIkN1IyjAMMzwDPJowCNowCJDQSNowDDoRxx
qACjMI2jAMcFHHGoADCNowDDaB5qgwDoFlU7AFnDaChqgwDoClU7AFnDoRxxqACjTI2jAMcFHHGo
AEyNowDDoRxxqACjaI2jAMcFHHGoAGiNowDDM8AzyaOEjaMAiQ2IjaMAw6EccagAo7SNowDHBRxx
qAC0jaMAw6EccagAo9CNowDHBRxxqADQjaMAw6EccagAo+yNowDHBRxxqADsjaMAw6EccagAowiO
owDHBRxxqAAIjqMAw6EccagAaDxqgwCjJI6jAMcFHHGoACSOowDoXFQ7AFnDoRxxqACjYI6jAMcF
HHGoAGCOowDDoRxxqABoWmqDAKN8jqMAxwUccagAfI6jAOgnVDsAWcNoXWqDAOgbVDsAWcOhHHGo
AKMgj6MAxwUccagAII+jAMNojmqDAOj6UzsAWcNomGqDAOjuUzsAWcNoomqDAOjiUzsAWcNqALjs
GoAA6MFcOwC5VI+jAOhnfgYAah5YZqOEj6MAxwWIj6MAAAAAAOhtXDsAw8zMzMzMM8AzyaOQj6MA
iQ2Uj6MAw2i2aoMA6JJTOwBZw1WL7FFRjU346EuhMAAz0okV8KuoAIkV9KuoAIsIiQ3wq6gAi0gE
iQ30q6gAiRCJUASLTfyFyXQF6O5fBwBowGqDAOhJUzsAWcnDaPCrqAC5+KuoAOjY9AIAaMpqgwDo
LVM7AFnDoRxxqABo1GqDAKPMj6MAxwUccagAzI+jAOgNUzsAWcNqALjsGoAA6OxbOwBqDOjrFDwA
WYXAdCrHQAQBAAAAxwAID5cAx0AInw9xAGjeaoMAowCsqADo0FI7AFnohVs7AMNoYvQxAejciwgA
zMzMzMzMaPlqgwDor1I7AFnDaPxqgwDoo1I7AFnDM8AzyaMAkKMAiQ0EkKMAw2oAuOwagADocls7
ALk8kKMA6Bh9BgBqBVhmo2yQowDHBXCQowAAAAAA6B5bOwDDzMzMzMxqALjsGoAA6D5bOwC5hJCj
AOjkfAYAah5YZqO0kKMAxwW4kKMAAAAAAOjqWjsAw8zMzMzMagC47BqAAOgKWzsAucyQowDosHwG
AGoyWGaj/JCjAMcFAJGjAAAAAADotlo7AMPMzMzMzGoAuOwagADo1lo7ALkUkaMA6Hx8BgC4LAEA
AMcFSJGjAAAAAABmo0SRowDogFo7AMPMzMzMzGoAuOwagADooFo7ALlckaMA6EZ8BgBqBVhmo4yR
owDHBZCRowAAAAAA6ExaOwDDzMzMzMyhHHGoAKOYkaMAxwUccagAmJGjAMOhHHGoAKO0kaMAxwUc
cagAtJGjAMNVi+xRUY1F+A9XwFBmDxNF+P8V1HCDAItF+ItN/KMErKgAiQ0IrKgAycOhHHGoAKPQ
kaMAxwUccagA0JGjAMOhHHGoAGgba4MAo+yRowDHBRxxqADskaMA6ARROwBZw2jIvHMA6OZYOwBZ
w2hsa4MA6OxQOwBZw2iza4MA6OBQOwBZw2i9a4MAxwUEkqMAwGmGAOjKUDsAWcNoyGuDAMcFIJKj
AMBphgDotFA7AFnDaNNrgwDHBTySowDAaYYA6J5QOwBZw2g4BQAAuB2jggDorVk7AGoHW2oKXmoD
WjPAxoXI+v//BmoEWWoFiYXM+v//iIXo+v//iIUA+///iIUY+///iIUk+///WMaF0Pr//wbGhdT6
//8Gx4XY+v//AQAAAMaF3Pr//wbGheD6//8GiZ3k+v//xoXs+v//BseF8Pr//wgAAADGhfT6//8G
xoX4+v//BseF/Pr//wkAAADGhQT7//8GibUI+///xoUM+///BsaFEPv//wbHhRT7//8CAAAAxoUc
+///BomVIPv//8aFKPv//waJjSz7///GhTD7//8GxoU0+///BomFOPv//8aFPPv//wDGhUD7//8G
x4VE+///BgAAAMaFSPv//wbGhUz7//8Ix4VQ+///AAAAAMaFVPv//wDGhVj7//8Ix4Vc+///AQAA
AMaFYPv//wjGhWT7//8IiZ1o+///xoVs+///CMaFcPv//wjHhXT7//8IAAAAxoV4+///CMaFfPv/
/wjHhYD7//8JAAAAxoWE+///AMaFiPv//wiJtYz7///GhZD7//8IxoWU+///CMeFmPv//wIAAADG
hZz7//8AxoWg+///CImVpPv//8aFqPv//wDGhaz7//8IiY2w+///xoW0+///CMaFuPv//wiJhbz7
///GhcD7//8AxoXE+///CMeFyPv//wYAAADGhcz7//8IxoXQ+///CceF1Pv//wAAAADGhdj7//8A
xoXc+///CceF4Pv//wEAAADGheT7//8JxoXo+///CYmd7Pv//8aF8Pv//wDGhfT7//8Jx4X4+///
CAAAAMaF/Pv//wnGhQD8//8Jx4UE/P//CQAAAMaFCPz//wnGhQz8//8JibUQ/P//xoUU/P//CcaF
GPz//wnHhRz8//8CAAAAxoUg/P//AMaFJPz//wmJlSj8///GhSz8//8AxoUw/P//CYmNNPz//8aF
OPz//wnGhTz8//8JiYVA/P//xoVE/P//AMaFSPz//wnHhUz8//8GAAAAxoVQ/P//CYiNVPz//8eF
WPz//wAAAADGhVz8//8AiI1g/P//x4Vk/P//AQAAAIiNaPz//4iNbPz//4mdcPz//8aFdPz//wCI
jXj8///HhXz8//8IAAAAiI2A/P//iI2E/P//x4WI/P//CQAAAMaFjPz//wCIjZD8//+JtZT8//+I
jZj8//+IjZz8///HhaD8//8CAAAAiI2k/P//iI2o/P//iZWs/P//iI2w/P//iI20/P//iY24/P//
iI28/P//iI3A/P//iYXE/P//iI3I/P//iI3M/P//x4XQ/P//BgAAAIiN1Pz//8aF2Pz//wLHhdz8
//8AAAAAxoXg/P//AMaF5Pz//wLHhej8//8BAAAAxoXs/P//AsaF8Pz//wKJnfT8///Ghfj8//8A
xoX8/P//AseFAP3//wgAAADGhQT9//8CxoUI/f//AseFDP3//wkAAADGhRD9//8AxoUU/f//Aom1
GP3//8aFHP3//wLGhSD9//8Cx4Uk/f//AgAAAMaFKP3//wLGhSz9//8CiZUw/f//xoU0/f//AsaF
OP3//wKJjTz9///GhUD9//8CxoVE/f//AomFSP3//8aFTP3//wLGhVD9//8Cx4VU/f//BgAAAMaF
WP3//wKIhVz9///HhWD9//8AAAAAxoVk/f//AIiFaP3//8eFbP3//wEAAACIhXD9//+IhXT9//+J
nXj9///GhXz9//8AiIWA/f//x4WE/f//CAAAAIiFiP3//4iFjP3//8eFkP3//wkAAADGhZT9//8A
iIWY/f//ibWc/f//iIWg/f//iIWk/f//x4Wo/f//AgAAAIiFrP3//4iFsP3//4mVtP3//4iFuP3/
/4iFvP3//4mNwP3//4iFxP3//4iFyP3//4mFzP3//4iF0P3//4iF1P3//8eF2P3//wYAAACIhdz9
///GheD9//8Bx4Xk/f//AAAAAMaF6P3//wDGhez9//8Bx4Xw/f//AQAAAMaF9P3//wHGhfj9//8B
iZ38/f//xoUA/v//AMaFBP7//wHHhQj+//8IAAAAxoUM/v//AcaFEP7//wHHhRT+//8JAAAAxoUY
/v//AMaFHP7//wGJtSD+///GhST+//8BxoUo/v//AceFLP7//wIAAADGhTD+//8BxoU0/v//AYmV
OP7//8aFPP7//wHGhUD+//8BiY1E/v//xoVI/v//AcaFTP7//wGJhVD+///GhVT+//8BxoVY/v//
AceFXP7//wYAAADGhWD+//8BiJVk/v//iZ2A/v//iJ3o/v//iJ30/v//iJ38/v//iJ0A////iZ0E
////iJ0M////iJ0U////iJ0Y////iJ0k////iJ0s////iJ0w////iJ04////iJ08////iJ1E////
iJ1I////iJ1Q////iJ1U////iJ1c////iJ1g////iJ1o////iV2IM9vHhWj+//8AAAAAxoVs/v//
AIiVcP7//8eFdP7//wEAAACIlXj+//+IlXz+///GhYT+//8AiJWI/v//x4WM/v//CAAAAIiVkP7/
/4iVlP7//8eFmP7//wkAAADGhZz+//8AiJWg/v//ibWk/v//iJWo/v//iJWs/v//x4Ww/v//AgAA
AIiVtP7//4iVuP7//4mVvP7//4iVwP7//4iVxP7//4mNyP7//4iVzP7//4iV0P7//4mF1P7//4iV
2P7//4iV3P7//8eF4P7//wYAAACIleT+///Hhez+//8AAAAAxoXw/v//AMeF+P7//wEAAADGhQj/
//8Ax4UQ////CAAAAMeFHP///wkAAADGhSD///8AibUo////x4U0////AgAAAImVQP///4mNTP//
/4mFWP///8eFZP///wYAAADGhWz///8Ax4Vw////AAAAAMaFdP///wbGhXj///8Ax4V8////AQAA
AMZFgAbGRYQAxkWMCIhdkMdFlAgAAADGRZgIiF2cx0WgCQAAAMZFpAmJRdyNffBRjYXE+v//iXWs
UIhdqI21yPr//8ZFsAmIXbTHRbgCAAAAxkW8AohdwIlVxMZFyAKIXcyJTdDGRdQCiF3YxkXgAohd
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
QABqA2oYjUWox0X8/////1DoDz07AGhHbIMA6M08OwBZ6JZFOwDDaH1sgwDovDw7AFnDUeix0zYA
aJFsgwDoqjw7AFnDaNB7mAC5iKyoAOhDEwAAaJtsgwDojzw7AFnDaNigmAC5oKyoAOgoEwAAaK9s
gwDodDw7AFnDaFigmAC5uKyoAOgNEwAAaLlsgwDoWTw7AFnD6KO5NwBow2yDAOhIPDsAWcNo6KGZ
ALnQrKgA6OESAABozWyDAOgtPDsAWcNo+PCZALnorKgA6MYSAABo12yDAOgSPDsAWcNoqPCZALkA
ragA6KsSAABo4WyDAOj3OzsAWcNofPGZALkYragA6JASAABo62yDAOjcOzsAWcNoSPGZALkwragA
6HUSAABo9WyDAOjBOzsAWcNo/2yDAOi1OzsAWcNowNaVALlIragA6E4SAABoCW2DAOiaOzsAWcNo
LPCZALlgragA6DMSAABoE22DAOh/OzsAWcNoAPCZALl4ragA6BgSAABoHW2DAOhkOzsAWcNoiPCZ
ALmQragA6P0RAABoJ22DAOhJOzsAWcNozFWJALmoragA6OIRAABoMW2DAOguOzsAWcNoXPCZALnA
ragA6McRAABoO22DAOgTOzsAWcNoRW2DAOgHOzsAWcNoT22DAOj7OjsAWcNoQLOJALnYragA6JQR
AABoWW2DAOjgOjsAWcNokO+ZALnwragA6HkRAABoY22DAOjFOjsAWcNobW2DAOi5OjsAWcNod22D
AOitOjsAWcNoeO+ZALkIrqgA6EYRAABogW2DAOiSOjsAWcNo0KyoALo4opkAuSCuqADoc78BAGiL
bYMA6HI6OwBZw2jg75kAuiCuqAC5OK6oAOgqwgcAaJVtgwDoUjo7AFnDaNDvmQC6IK6oALlQrqgA
6ArCBwBon22DAOgyOjsAWcNoLO+ZALogrqgAuWiuqADo6sEHAGipbYMA6BI6OwBZw2j47pkAuiCu
qAC5gK6oAOjKwQcAaLNtgwDo8jk7AFnDaFDvmQC5mK6oAOiLEAAAaL1tgwDo1zk7AFnDaEDvmQC6
mK6oALmwrqgA6I/BBwBox22DAOi3OTsAWcNo7PGZALqYrqgAuciuqADob8EHAGjRbYMA6Jc5OwBZ
w2h4ragAueCuqADoHeAHAGjbbYMA6Hw5OwBZw2hA75kAuuCuqAC5+K6oAOg0wQcAaOVtgwDoXDk7
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
/IP4H3cKi8pR6GLpOwBZw2oFWc0pVYvsg+T4gey0AwAAoQASowAzxImEJLADAABTVleL2ov5i8vo
688HAIN/EAAPhNEAAABoZGyGAI1MJBTo4v3//2oAUIvP6LjHBwCNTCQQjXAB6Nr+//+LVxCNRCQQ
K9aLz1JWUOjaxAcAUIvL6ITKBwCNTCQQ6Lb+//9oaGyGAI1MJBTomv3//1FQi8vogcQHAI1MJBCL
+OiU/v//aGxshgCNTCQU6Hj9//9RUIvL6F/EBwCNTCQQi/Docv7//4tDEI1WAY1PATvKi8sPR/dG
K8ZQVo1EJBhQ6GbEBwBQi8voEMoHAI1MJBDoQv7//4uMJLwDAABfXlszzOgtJDsAi+Vdw2gkbIYA
ajqNTCQw6OLOBwBomL+iAI1EJCxQ6AlSOwDMaJAAAAC45T5/AOhmLzsAi/KJtWz///+JjWj///+L
RQiNfcCJhWT///8z24mdcP///zPAq2oHWqurqzPAiV3QiVXUZolFwIlF/I192Kurq6szwIld6IlV
7GaJRdiNfZCrq6urM8CJXaCJVaRmiUWQjYVw////xkX8AlCNVZDouAIAAFaNTdiIhXf////o1MIH
AIPO/zidd////3UraGxshgCNTajoVvz//4u9bP///0NqAFCLz+glxgcAO8Z0D8aFdv///wHrDYu9
bP///8aFdv///wD2wwF0C41NqIPj/ugp/f//gL12////AHRGaGhshgCNjXj////oAvz//4vwaGxs
hgCNTajGRfwD6O/7//9RVovQxkX8BI1N2Og1wAcAjU2o6OX8//+NjXj////pkgAAAIC9d////wB0
KGhobIYAjY14////6LP7//9qAFCLz4PLAuiGxQcAxoV3////ATvGdQfGhXf///8A9sMCdAuNjXj/
///okvz//4C9d////wB0TWhsbIYAjU2o6G77//+L8GhobIYAjY14////xkX8BehY+///UVaL0MZF
/AaNTdjonr8HAI2NeP///+hL/P//jU2oxkX8Aug//P//g87/i03oZoudcP///4XJdGyDfewHjUXY
D0dF2GY5GHVcM8CNfairq6urx0W4AAAAAMdFvAAAAADGRfwHg/kBD4LfAAAAjUH/O8aNTagPQvCD
fewHjUXYD0dF2IPAAlZQ6Br7//+NRajGRfwCUI1N2OiPxwcAjU2o6ML7////tWj///+NTcDoDMEH
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
///HhfT7//8QAAAAUI2N+Pv//+iRngcAaAiGhgCNjST+///GRfwk6Gva//9qEVuNhST+//+JnRD8
//9QjY0U/P//6GKeBwBoMIaGAI2NLP///8ZF/CboPNr//42FLP///8eFLPz//xIAAABQjY0w/P//
6DKeBwBoUIaGAI2NHPr//8ZF/CjoDNr//42FHPr//8eFSPz//xMAAABQjY1M/P//6AKeBwBogIaG
AI2NBPr//8ZF/Cro3Nn//42FBPr//8eFZPz//xQAAABQjY1o/P//6NKdBwBooIaGAI2N7Pn//8ZF
/CzorNn//42F7Pn//8eFgPz//xUAAABQjY2E/P//6KKdBwBoyIaGAI2N1Pn//8ZF/C7ofNn//42F
1Pn//8eFnPz//xYAAABQjY2g/P//6HKdBwBo8IaGAI2NvPn//8ZF/DDoTNn//42FvPn//8eFuPz/
/xcAAABQjY28/P//6EKdBwBouHeGAI2NpPn//8ZF/DLoHNn//42FpPn//8eF1Pz//xgAAABQjY3Y
/P//6BKdBwBoLIeGAI2NjPn//8ZF/DTo7Nj//42FjPn//8eF8Pz//xkAAABQjY30/P//6OKcBwBo
UIeGAI2NdPn//8ZF/DbovNj//42FdPn//8eFDP3//xoAAABQjY0Q/f//6LKcBwBodIeGAI2NXPn/
/8ZF/DjojNj//42FXPn//8eFKP3//xsAAABQjY0s/f//6IKcBwBomIeGAI2NRPn//8ZF/DroXNj/
/42FRPn//8eFRP3//xwAAABQjY1I/f//6FKcBwBowIeGAI2NLPn//8ZF/DzoLNj//42FLPn//8eF
YP3//x0AAABQjY1k/f//6CKcBwBo5IeGAI2NFPn//8ZF/D7o/Nf//42FFPn//8eFfP3//x4AAABQ
jY2A/f//6PKbBwBoAIiGAI2N/Pj//8ZF/EDozNf//42F/Pj//8eFmP3//x8AAABQjY2c/f//6MKb
BwBoHIiGAI2N5Pj//8ZF/ELonNf//42F5Pj//8eFtP3//yAAAABQjY24/f//6JKbBwBoXIiGAI2N
zPj//8ZF/ETobNf//42FzPj//8eF0P3//yEAAABQjY3U/f//6GKbBwBofIiGAI2NtPj//8ZF/Ebo
PNf//42FtPj//8eF7P3//yIAAABQjY3w/f//6DKbBwBooIiGAI2NnPj//8ZF/EjoDNf//42FnPj/
/8eFCP7//yMAAABQjY0M/v//6AKbBwCNhST+///GRfxtjY00+v//UFGNTgTo1rICAGikjUAAaiRq
HI2FNPr//8ZF/GxQ6EsAOwCNjZz4///owNf//42NtPj//+i11///jY3M+P//6KrX//+NjeT4///o
n9f//42N/Pj//+iU1///jY0U+f//6InX//+NjSz5///oftf//42NRPn//+hz1///jY1c+f//6GjX
//+NjXT5///oXdf//42NjPn//+hS1///jY2k+f//6EfX//+Njbz5///oPNf//42N1Pn//+gx1///
jY3s+f//6CbX//+NjQT6///oG9f//42NHPr//+gQ1///jY0s////6AXX//+NjST+///o+tb//42N
PP7//+jv1v//jY1U/v//6OTW//+NjWz+///o2db//42NhP7//+jO1v//jY2c/v//6MPW//+NjbT+
///ouNb//42NzP7//+it1v//jY3k/v//6KLW//+Njfz+///ol9b//42NFP///+iM1v//jY1E////
6IHW//+NjVz////odtb//42NdP///+hr1v//jU2M6GPW//+NTaToW9b//41NvOhT1v//jU3UxkX8
AuhH1v//aKxohgCNjUT////oKdX//42FRP///8eFXP3//wAAAABQjY1g/f//6B+ZBwBoyIiGAI2N
XP///8ZF/G/o+dT//42FXP///8eFeP3//wEAAABQjY18/f//6O+YBwBo3IiGAI2NdP///8ZF/HHo
ydT//42FdP///8eFlP3//wIAAABQjY2Y/f//6L+YBwBo7HaGAI1NjMZF/HPonNT//41FjMeFsP3/
/wMAAABQjY20/f//6JWYBwBo+IiGAI1NpMZF/HXoctT//41FpMeFzP3//wQAAABQjY3Q/f//6GuY
BwBoDImGAI1NvMZF/HfoSNT//41FvMeF6P3//wUAAABQjY3s/f//6EGYBwBoKImGAI1N1MZF/Hno
HtT//41F1MeFBP7//wYAAABQjY0I/v//6BeYBwCNhSD+///GRfyBjY1c/f//UFGLz+jsrwIAaKSN
QABqB19XahyNhVz9///GRfyAUOhf/ToAjU3U6NfU//+NTbzoz9T//41NpOjH1P//jU2M6L/U//+N
jXT////otNT//42NXP///+ip1P//jY1E////xkX8Auia1P//aFSJhgCNjSz////ofNP//42FLP//
/8eFDPz//wEAAABQjY0Q/P//6HKXBwBokHiGAI2NJP7//8ZF/IPoTNP//42FJP7//8eFKPz//wIA
AABQjY0s/P//6EKXBwBoaImGAI2NPP7//8ZF/IXoHNP//42FPP7//8eFRPz//wAAAABQjY1I/P//
6BKXBwBoCHiGAI2NVP7//8ZF/Ifo7NL//42FVP7//8eFYPz//wMAAABQjY1k/P//6OKWBwBogImG
AI2NbP7//8ZF/InovNL//42FbP7//8eFfPz//wQAAABQjY2A/P//6LKWBwBooImGAI2NhP7//8ZF
/IvojNL//42FhP7//8eFmPz//wUAAABQjY2c/P//6IKWBwBo0ImGAI2NnP7//8ZF/I3oXNL//42F
nP7//8eFtPz//wYAAABQjY24/P//6FKWBwBo8ImGAI2NtP7//8ZF/I/oLNL//42FtP7//4m90Pz/
/1CNjdT8///oJpYHAMZF/JGNjcz+//9oEIqGAOgA0v//jYXM/v//x4Xs/P//CAAAAFCNjfD8///o
9pUHAGhQd4YAjY3k/v//xkX8k+jQ0f//jYXk/v//x4UI/f//CQAAAFCNjQz9///oxpUHAGg4eIYA
jY38/v//xkX8leig0f//jYX8/v//x4Uk/f//CgAAAFCNjSj9///olpUHAGhceIYAjY0U////xkX8
l+hw0f//jYUU////x4VA/f//CwAAAFCNjUT9///oZpUHAGgwioYAjY1E////xkX8mehA0f//jYVE
////x4Vc/f//DAAAAFCNjWD9///oNpUHAGhMioYAjY1c////xkX8m+gQ0f//jYVc////x4V4/f//
DQAAAFCNjXz9///oBpUHAGhwd4YAjY10////xkX8nejg0P//jYV0////x4WU/f//DgAAAFCNjZj9
///o1pQHAGh4ioYAjU2MxkX8n+iz0P//x4Ww/f//DwAAAI1FjFCNjbT9///orJQHAGiUioYAjU2k
xkX8oeiJ0P//jUWkx4XM/f//EAAAAFCNjdD9///ogpQHAGjAioYAjU28xkX8o+hf0P//jUW8iZ3o
/f//UI2N7P3//+hclAcAaOiKhgCNTdTGRfyl6DnQ//+NRdTHhQT+//8SAAAAUI2NCP7//+gylAcA
jYUg/v//xkX8uY2NDPz//1BRjU4M6AasAgBopI1AAGoTahyNhQz8///GRfy4UOh7+ToAjU3U6PPQ
//+NTbzo69D//41NpOjj0P//jU2M6NvQ//+NjXT////o0ND//42NXP///+jF0P//jY1E////6LrQ
//+NjRT////or9D//42N/P7//+ik0P//jY3k/v//6JnQ//+Njcz+///ojtD//42NtP7//+iD0P//
jY2c/v//6HjQ//+NjYT+///obdD//42NbP7//+hi0P//jY1U/v//6FfQ//+NjTz+///oTND//42N
JP7//+hB0P//jY0s////6DbQ//+LxuhGATsAwgQA6Lo+CADMagy4eEh/AOhPATsAi/GJdfBqJOhX
ZisAWYlF8MdF/AAAAACFwHQLagGLyOjy8P//6wIzwFCLzsdF/P/////olHsBAIvG6N8AOwDDagi4
p0h/AOgEATsAi/GJdfBqJOgMZisAWYlF8MdF/AAAAACFwHQLagKLyOin8P//6wIzwFCLzsdF/P//
///oSXsBAIvG6JQAOwDDVYvsUYtNCGjIdoYA6HHO//+LRQjJwgQAagS40Uh/AOihADsAi3UIM8CJ
BolGBGociUX86JO5OwBZhcB0GokAiUAEiUAIZsdADAEBiQaLxug/ADsAwgQA6Mc9CADMVYvsVovx
jU4c6PKpAgCLzugYAAAA9kUIAXQLhfZ0B1boObk7AFmLxl5dwgQAVovxjU4U6DeBAgCNTgzowKkC
AI1OBF7pt6kCAOmyqQIA6YipAgCLQQTDVYvsVovxjU4g6AqBAgCNTgjoxs7///ZFCAF0C4X2dAdW
6OG4OwBZi8ZeXcIEAFWL7FaL8Y1OHOjcgAIAjU4E6JjO///2RQgBdAuF9nQHVuizuDsAWYvGXl3C
BABWi/GNThzosYACAI1OBF7pbM7//1WL7Gr/aO5IfwBkoQAAAABQoQASowAzxVCNRfRkowAAAACN
gQQBAACLTQhQ6I8AAACLRQiLTfRkiQ0AAAAAWcnCBADMzMzMzIqBRQMAAMOKgUYDAADDioFHAwAA
w1WL7FGNkdwBAACLTQjoCaA0AItFCMnCBABqBLgYSX8A6B//OgCL+Yl98It1CFbodC4oAI1GHMdF
/AAAAABQjU8c6KicBwCLx+jF/joAwgQAVovxjU4c6LTN///HBiBshgBew2oEuEJJfwDo1f46AIv5
iX3wi3UIVuhxnAcAjUYYx0X8AAAAAFCNTxjoXpwHAIvH6Hv+OgDCBABWi/GNThjoas3//4vOXuli
zf//i9EzwFNXM9uJGo16JIlaBIlaCIlaDIlaEIlaFIlaGIlaHIlaIKtqBlmrqzPAjXow86tmq4vC
X4haSlvDagS4bEl/AOhP/joAi/GJdfDGRhgAi0UIx0X8AAAAAIB4GAB0ClDo2psHAMZGGAGLxujz
/ToAwgQAVovxjU5I6OLM//+NTjDo2sz//41OGOjSzP//i85e6crM//9qBLisSX8A6PP9OgCL8Yl1
8P91CDPbjU4QiB6JXgSJXgiJXgzogJsHAI1OKIld/Gh4aoYA6IPL//+NfkCJfQiJH4lfBGpoxkX8
Aui2tjsAWYXAdBGJAIlABIkHi8boa/06AMIEAOjzOggAzGoMuORJfwDoiP06AIv5iX3wjU8ExweM
aIYA6GaVBwAz24ld/IlfHIlfIP91CI1PBMZF/AHofpEHAItVCI1N6OiGeAEAiwiLUASJGIlYBIlP
HItPIIlXIIXJdAXo4gAHAI1N6OgzfgIAxwd4aIYAi8eJXySJXyjo5/w6AMIEAFWL7FaL8egYAAAA
9kUIAXQLhfZ0B1bo8bU7AFmLxl5dwgQAVleL+Y1PJOiWjQMAjU8cx0ck4U0AAOjffQIAjU8EX17p
mcv//2oMuDRKfwDowvw6AIv6i/GJdewz24ld/GosiV3w6MBhKwBZiUXox0X8AQAAAIXAdAxXi8jo
Af///4v46wKL+4keiV4EahDHRfwCAAAA6IK1OwBZhcB0LDPJxwDoBYYAQYl4DIlIBIlICIk+iUYE
iV38iweJTfCLz/9QBIvG6Br8OgDD6KQ5CADMVjP2VlZR/xWgcIMAhcB1FP8VOHCDAA+38IHOAAAH
gIXAD07wi8Zew2pkuI5KfwDoRPw6AIlNoOhgKTMAUI1NkOh7tAIAx0X8AAAAAItFlIt9kIlFnDv4
D4QYAQAAM9tDV41NwOiGmQcAaCyNhgCNTaiIXfzoicn//2ioaYYAjU3YxkX8Auh4yf//UY1FqMZF
/ANQjVXYjU3A6LqNBwCNTdjoasr//41NqIhd/Ohfyv//jUXAujSNhgBQjU2o6BNyAQCL8MZF/ASN
TeDHRdwAAAAA6DW4AgDGRfwFi86DfhQHdgKLDotGEI0EQXYCizZoAQEAAFBWjU3c6H7VAgBRi02g
jVXcxkX8BuiddwEAi03ciEWnhcl0JYPI//APwUEgdRuLddzrEovOjUYMizDHAAAAAABTiwH/EIX2
deqNTejHRdzhTQAA6ERXBwCNTaiIXfzoucn//4B9pwCNTcB1J8ZF/ADop8n//4PHGDt9nA+F6/7/
/zLbjU2Q6CGEBwCKw+ih+joAw+iEyf//6+lqMLgbS38A6N76OgCL8Yl1yItFEI1OCIpdCIt9DIlF
zItFFIl1xIlF0ItFHFeJRdTHBpRlhgCIXgToI5gHAP91zI1OIMdF/AAAAADoEZgHAP910I1OOMZF
/AHoApgHAI1OUOhBkgcAjU5o6DmSBwCNjoAAAADoLpIHAI2OmAAAAOgjkgcAi0UYjY64AAAA/3XU
xkX8BsaGsAAAAACLAImGtAAAAOi4lwcAxkX8B4B+BAPGhtAAAAABdQmLzujQ6TQAitj/ddSK041N
2P910P91zFfo+uc0AFCNTlDoZ5QHAI1N2OiayP//i8boqvk6AMIYAFWL7Gr/aMBLfwBkoQAAAABQ
gewIAQAAoQASowAzxYlF7FNWV1CNRfRkowAAAACJZfCL8Ym1BP///4m1/P7//8cGlGWGAMdF/AAA
AACNfmjGRfwIsgGJvQT///+Lz+g1ACgA6TYBAAAzwMeF7P7//0gPhgBmiYX4/v//jX2MqzPJagdb
x4Xw/v//lI2GAKvHhfT+//9QjYYAq6szwGaJRYyNfaSriU2ciV2gq6urM8BmiUWkjX28q4lNtIld
uKurqzPAZolFvI191KuJTcyJXdCrq6szwIlN5Ild6GaJRdT/FThwgwCJhQD///+NjQj///+NRYxQ
jUWkUI1FvFCNRdRQjYUA////UOgbJQcAi/CNvXD///8zwIvL86uNjXT////HhXD////saYYA6IaQ
BwCNhez+//+6rgMAAFBWjYVw////uaIkaQBQaKyNhgBqCuiIbgEAjY10////6DDH//+NjQj////o
U4EHAI1N1Ogdx///jU286BXH//+NTaToDcf//41NjOgFx///uNa5QADDi70E////i7X8/v//jY64
AAAA6OjG//+NjpgAAADo3cb//42OgAAAAOjSxv//i8/oy8b//41OUOjDxv//jU446LvG//+NTiDo
s8b//41OCOirxv//i030ZIkNAAAAAFlfXluLTewzzeiP7DoAycNVi+xq/2juSH8AZKEAAAAAUKEA
EqMAM8VQjUX0ZKMAAAAAjUFQi00IUOhClQcAi0UIi030ZIkNAAAAAFnJwgQAzMzMzMxVi+xWi/Ho
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
6gYAageL8I29ZP///1kzwPOrjY1o////x4Vk////7GmGAOhEVgcAU1aNhWT///+6sAMAAFBoSKCG
AGoKuQMWHCLoTDQBAI2NaP///+j0jP//jY18/v//6BdHBwCNTYzo4Yz//41NpOjZjP//jU3U6NGM
//+NjUj////oxoz//42NOP///+iRRwcAjU286LOM//+4KPRAAMOLtdz6///HRfwCAAAAi73E+v//
i53k+v//ib3Y+v//x4XI+v//AAAAAMeFzPr//wAAAADHhdD6//8AAAAAaCRkhgCNTbzGRfwI6FGL
//+NRbzGRfwJUI2VyPr//4vO6CJDBwCNTbzGRfwI6D6M//+Lhcz6//+Ltcj6//878ImF3Pr//+ki
AgAAagBoHG2GAIvO6EN3AgCJheD6//+D+P8PhbIAAAAzwI191Kurq6szwMdF5AAAAADHRegHAAAA
ZolF1I1F1MZF/ApQjU286LpaBwCNRbzGRfwLUI2NYP///+g5YgIAi/D/tej6//+NjRD////GRfwM
agHoKPYGAFZQxkX8DY2FuPr//4u92Pr//4vPUOj+PgEAjY0Y////6IqL//+NjWD////HhRD///8g
bIYA6GBhAgCNTbzobYv//41N1MZF/AjoYYv//4u16Pr//+lKAQAAav9Ai85QjUWkUOhaUQcAi4XU
+v//xkX8DoN4EAB1GY1FpFCNhRz///9Q6If2///GRfwPg8sB6xZQjY1o////6PFZBwDHRfwQAAAA
g8sCUI1NvImd5Pr//+jYWQcAjUW8x0X8EQAAAFCNjUD////oVGECAI1NvOjbiv//9sMCdBSD4/2N
jWj///+JneT6///owor//8ZF/BX2wwF0FIPj/o2NHP///4md5Pr//+iliv//aBxthgCNTdToion/
/41F1MZF/BZQjZVA////jU2k6M0+AQCNTdTGRfwV6HaK////teD6//+NRdSLzmoAUOh2UAcAUGoB
jU2AxkX8F+jN9AYAjY1A////xkX8GFFQjYWw+v//i89Q6BU/AQCNTYjoMor//41N1MdFgCBshgDo
I4r//42NQP///+gDYAIAjU2kxkX8COgMiv//g8YYO7Xc+v//ibXo+v//D4XS/f//jY3I+v//6HxE
BwCLx+gLuzoAwggAaLCfhgCNTdTox4j//1ZokJ+GAI1F1FCNjeT+///oYTwBAI2NaP///4mF4Pr/
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
9seFmP7//5SNhgCrq6szwGaJRaCNfbiriXWwiV20q6urM8BmiUW4jUWgUI1FuIl1yFD/tXj+//+J
XczoH9wGAIvwjb08////M8CLy/OrjY1A////x4U8////7GmGAOhYSwcAjYWU/v//uq4DAABQVo2F
PP///7nCtBwBUGh8ooYAagroWikBAI2NQP///+gCgv//jY24/v//6CU8BwCNTbjo74H//41NoOjn
gf//jU3U6N+B//+4/P5AAMPHRfwCAAAAM/aLjYj+//+JjZD+//+Ljaj+//9qB4mNpP7//1szwI19
1KuL0aurqzPAZolF1IuFhP7//4l15Ild6DkYdgKLEY1F1FBSjY2s/v//6IvZAQCNTdTGRfwG6HaB
//+NhUD///9QjY2s/v//6DBWAgBQjY1Y////6B1NBwCNjUD////oTYH//4uFjP7//4tIJIXJD4T5
BAAAiwGNlVj///9Si0AI/9CEwHQeOZ1s////jYVY////ibVo////D0eFWP///zPJZokIjY2s/v//
6M4EAADHRfwCAAAAi72Q/v//6W8CAAD/taj+//+6qKKGAI2NQP///+ieKAEAagdbOVgUdgKLAImF
nP7//4191DPAx4WU/v//SA+GAGaJhaD+//8z9qvHhZj+//+UjYYAq6urM8BmiUXUjX2Iq4l15Ild
6KurqzPAZolFiI19uKuJdZiJXZyrq6szwGaJRbiNfaCriXXIiV3Mq6urM8CJdbCJXbRmiUWg/xU4
cIMAiYWQ/v//jY24/v//jUXUUI1FiFCNRbhQjUWgUI2FkP7//1DoyN0GAIvwjb0g////M8CLy/Or
jY0k////x4Ug////7GmGAOgzSQcAjYWU/v//uq4DAABQVo2FIP///7nDtBwBUGh8ooYAagroNScB
AI2NJP///+jdf///jY24/v//6AA6BwCNTaDoyn///41NuOjCf///jU2I6Lp///+NTdTosn///42N
QP///+inf///uPz+QADD/7Wo/v//ujijhgCNjUD////oUCcBAGoHWzlYFHYCiwCJhZz+//+NfYgz
wMeFlP7//0gPhgBmiYWg/v//jY24/v//qzP2x4WY/v//lI2GAKurqzPAZolFiI191KuJdZiJXZyr
q6szwGaJRdSNRYhQjUXUiXXkUP+1dP7//4ld6Ojn2AYAi/CNvSD///8zwIvL86uNjST////HhSD/
///saYYA6CBIBwCNhZT+//+6rgMAAFBWjYUg////ucS0HAFQaHyihgBqCugiJgEAjY0k////6Mp+
//+Njbj+///o7TgHAI1N1Oi3fv//jU2I6K9+//+NjUD////opH7//7g3AkEAw4uFqP7//zP2agfH
RfwCAAAAi72I/v//iYWk/v//W4N9gACNjXD///+NhVj///8PRcGLz1DovUMHADl3EHUN/7V8/v//
i8/oq0MHAFeNhVj///+6SKSGAFCNhXD///9Q/7Wk/v//jY1A////6Jc1AQA5WBR2AosAD1fAiYWc
/v//M8DHhZT+//9ID4YAjU3Ux4WY/v//lI2GAGaJhaD+//9mDxNF1GYPE0XcZg8TReTHRdDsaYYA
6AlHBwCNhZT+//+5xrQcAVCNRdBQaHyihgBqMmoOWui9JAEAjU3U6Lx9//+NjUD////osX3//42N
cP///+imff//jY1Y////6Jt9//+Lx+i6rjoAwggA/7Wo/v//usCjhgCNjUD////oQCUBAGoHWzlY
FHYCiwCJhZz+//+NfbgzwMeFlP7//0gPhgBmiYWg/v//M/arx4WY/v//lI2GAKurqzPAZolFuI19
oKuJdciJXcyrq6szwGaJRaCNfYiriXWwiV20q6urM8BmiUWIjX3Uq4l1mIldnKurqzPAiXXkiV3o
ZolF1P8VOHCDAImFhP7//42NuP7//41FuFCNRaBQjUWIUI1F1FCNhYT+//9Q6GraBgCL8I29IP//
/zPAi8vzq42NJP///8eFIP///+xphgDo1UUHAI2FlP7//7quAwAAUFaNhSD///+5xbQcAVBofKKG
AGoK6NcjAQCNjST////of3z//42NuP7//+iiNgcAjU3U6Gx8//+NTYjoZHz//41NoOhcfP//jU24
6FR8//+NjUD////oSXz//7g3AkEAw+gjdS0AzOlTLgIA6QAAAABWi/GNTjTo7vb//41OKOjLUQIA
jU4Y6N72//+Lzl7pEHz//2pQuFhgfwDobK06AIvxiXWsi0UIUIl1pOjSSgcAx0X8AAAAAI1+GI1N
qIl9rOhZhjUAVo1F5MZF/AFQjU2o6B5tAwBW/3Xs6CRwAwCLTaiEwA9FTew7Tah0DY1BKIvPUOiK
SgcA6wxoFBmYAIvP6I96//+NTajoa1UCAGjwpIYAjU3YxkX8Auh2ev//jUWwx0WwdAyGAMdFtFT8
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
uZ6GLCNQjUXUUGgYrIYAamRqDlroZQkBAI1N2OhkYv//UY2FCP///8eFDP///xEAAAC+gKyGAI1N
iFCJtQj////oTRsHAI1N2Il9/Oh4qwYAjU2IxkX8AVGL0I2NRP///+iFrgYAjU3Y6Bdi//+NTYjG
RfwE6Ati//+NlQj///+NjUT////ojKkGAITAD4SsAAAAaKishgCNTbzo12D//41FvFCNjVz////o
TggBAA9XwMdFoOxphgCNTaRmDxNFpIvwZg8TRaxmDxNFtOjZKgcAVo1FoLmdhiwjUGgYrIYAajJq
DlrokwgBAI1NpOiSYf//jY1w////6Idh//+NjWD////oUhwHAI1NvOh0Yf//jYUI////UI2VRP//
/41NvOhspwYAV1CNi6AAAADGRfwF6PoyAgCNTbzpCAIAADPAjX2kq6urqzPAx0W0AAAAAMdFuAcA
AABmiUWkjU2kxkX8BuiPaigAUY2FEP///4m1EP///1CNTbzHhRT///8RAAAA6AsaBwDGRfwHjUWk
g324B4tNtA9HRaSJhRD///+NhRD///9RiY0U////jU2IUOjdGQcAjUW8xkX8CFCNVYiNTdjoIq0G
AFCNjUT////odSwHAI1N2OioYP//jU2I6KBg//+NTbzGRfwG6JRg//+NlQj///+NjUT////oFagG
AI1NvITAD4SqAAAAaACthgDoYF///41FvFCNjVz////o1wYBAA9XwMdF1OxphgCNTdhmDxNF2Ivw
Zg8TReBmDxNF6OhiKQcAVo1F1LmchiwjUGgYrIYAajJqDlroHAcBAI1N2OgbYP//jY1w////6BBg
//+NjWD////o2xoHAI1NvOj9X///jYUI////UI2VRP///41N2Oj1pQYAagBQjYugAAAAxkX8CeiC
MQIAjU3Y6YgAAABoaK2GAOi2Xv//jUW8UI2NGP///+gtBgEAD1fAx4Vs////7GmGAI2NcP///2YP
E4Vw////i/BmDxOFeP///2YPE0WA6KwoBwBWjYVs////udthACFQaBishgBqMmoOWuhjBgEAjY1w
////6F9f//+NjSz////oVF///42NHP///+gfGgcAjU286EFf//+NTaToOV///42NRP///+guX///
6ECQOgDDVYvsg+T4g+xsoQASowAzxIlEJGhTVleL+WoQjV8gi8voHS8CAITAdA1qEIvL6AglAQCL
MOsDagVeiXQkEIP+BHQKg/4BdAWD/gN1JY2PoAAAAOhLLQIAhMB1FmoQjU9A6N0uAgCEwGoFWA9E
8Il0JBBRagqNRCQYi8tQ6HcYAwBowK2GAI1MJDTojF3//41EJDBQjUwkTOgEBQEAD1fAx0QkFOxp
hgCNTCQYZg8TRCQYi/BmDxNEJCBmDxNEJCjoiicHAFaNRCQYuVclECNQaBCuhgBqMmoOWuhDBQEA
jUwkGOhBXv//jUwkXOg4Xv//jUwkTOgFGQcAjUwkMOgmXv//i0wkdF9eWzPM6BSEOgCL5V3DanC4
1md/AOhwjzoAjbEACgAAahCLzugTLgIAhMB0X2oQi87oizcBAFCNTYTok0cCAGj8YoYAjU3Yx0X8
AAAAAOjBXP//jUXYxkX8AVCNTYTo6EYCAI1N2MZF/ADos13//1FqCo1FhIvOUOjxFgMAjU2Ex0X8
/////+gmGAcAaHiuhgCNTdjoe1z//41F2FCNTZDo9QMBAA9XwMdFvOxphgCNTcBmDxNFwIvwZg8T
RchmDxNF0OiAJgcAVo1FvLmFc4UCUGjQroYAajJqDlroOgQBAI1NwOg5Xf//jU2k6DFd//+NTZTo
/xcHAI1N2OghXf//6DOOOgDDaBQBAAC4Umh/AOh0jjoAi9mJXYCNsyALAADHhUj///8AAAAAi87o
aisCAITAD4QHBAAAUYvO6HoEAABRjY0g////x4V0////AAAAAItAIImFfP///42FdP///1DolwgH
AFGLzsdF/AAAAADoRQQAAMeFdP///wEAAACLeASLN+nCAgAAjV4Ig3sUB41DGImFeP///4vDdgKL
A1BoKLKGAOiRsTsAWVmFwHUwi4V4////jY1s////i12AUOiv4///x4Vs////hF+GAI2FbP///42L
IAEAAOkCAQAAg3sUB4vDdgKLA1BoRLKGAOhGsTsAWVmFwHUwi4V4////jY1k////i12AUOhk4///
x4Vk////fF+GAI2FZP///42LQAsAAOk5AQAAg3sUB4vDdgKLA1BoAGmGAOj7sDsAWVmFwHUOi12A
jYuACwAA6ZUBAACDexQHi8N2AosDUGgIeIYA6NKwOwBZWYXAdS2LhXj///+NjVz///+LXYBQ6PDi
///HhVz///+EX4YAjYVc////jYtAAgAA60aDexQHi8N2AosDUGg4eIYA6IqwOwBZWYXAdT6LhXj/
//+NjVT///+LXYBQ6Kji///HhVT///+EX4YAjYVU////jYugCgAAahD/tXz///9Q6OoWAwDpVAEA
AIN7FAeLw3YCiwNQaFx4hgDoMbA7AFlZhcB1DotdgI2LwAoAAOnLAAAAg3sUB4vDdgKLA1BotIuG
AOgIsDsAWVmFwHU+i4V4////jY1M////i12AUOgm4v//x4VM////fF+GAI2FTP///42LYAsAAGoQ
/7V8////UOj+FQMA6dIAAACDexQHi8N2AosDUGj4iIYA6K+vOwBZWYXAdTOLlXj///+NTbiLXYDo
QGz//4B4EAAPhJwAAABR/7V8////jYtgDAAAUOh9rgMA6YQAAACDexQHi8N2AosDUGioX4YA6GGv
OwBZWYXAdR+LXYCNi4AMAACLhXj///9qEP+1fP///1DoIRgDAOtKU41NhOj3KAcAjUMYxkX8AVCN
TZzo5ygHAI1FhMZF/AJQjYVA////UI2NIP///+jetAIAjU2cxkX8AOjiWf//jU2E6NpZ//+LXYCL
Njv3D4U2/f//g70o////AHUgaghZM8CNveD+///zq42N4P7//+irJwIAjb3g/v//62uNjQD////o
mCcCAI2FIP///8dF/AQAAABQjU3M6HoDBwDHRewKAAAAjUXMxkX8BVCNhXT////HhXT///8QAAAA
UI2FQP///1CNjQD////oS6wCAI1NzOiiBgcAjb0A////x4V0////AgAAAI2zIAsAADv3dBOLzugx
rgMAiweLzleJBuh8rgMAi510////9sMCdA6NjQD///+D4/3o4CYCAPbDAXQLjY3g/v//6NAmAgCN
jSD////HRfz/////6DoGBwBoaLKGAI1NtOjGV///jUW0UI1NiOhA/wAAD1fAx0XU7GmGAI1N2GYP
E0XYi/BmDxNF4GYPE0Xo6MshBwBWjUXUucKUZSNQaMiyhgBqMmoOWuiF/wAAjU3Y6IRY//+NTZzo
fFj//41NjOhKEwcAjU206GxY///ofok6AMNoaAEAALgSZn8A6L+JOgCL8WoEjZWU/v//x4WU/v//
EAAAAOjgEQcAUIvCi85QjYWM/v//UOjORwMAi0AEhcB1A4tGBDtGBHQLg8AM6CyJOgDCBABo3KmG
AI1N2Ogr/AYAUVFoSK+GAI1V2MdF/AAAAACNjZj+///oq/oGAIv4ahBajU2oxkX8Aeh8pQYAi/Bo
EKqGAI1NwMZF/ALot1b//1aNRcDGRfwDUIvP6B7+BgBQjY0g////6AoCBwBoRL+iAI2FIP///1Do
k6s6AMxoxAAAALjgaH8A6PCIOgCL+Y23AAEAAGoQi87okScCAITAD4QzAgAAahCLzugV7v//UI2F
MP///1Do1e7//8dF/AAAAACKhUj///+EwA+E8gEAAGoQi87o6u3//4C9SP///wCLWBgPhGoCAABq
EFONhTD///+LzlDoGBUDAIC9SP///wAPhEwCAABqEI2FMP///1CNjVD////oJr0GAFCNjXT////o
bL0GAGhIqYYAjU2YxkX8AujOVf//UY2FTP///8ZF/ANQjU3Qx4VM////AAAAAOi2HAMAjUWwxkX8
BFCNhXT///9QjU3Q6ElhAwCNRdDGRfwFUI1NsOgoPQIAahBTjUWwxkX8BlCNjyADAADoMREDAI1N
sOjoPAIAjU3Q6OA8AgBoQHhBAGoBajyNhXT////GRfwBUOjYfjoAjY1Y////xkX8AOhJVv//aEip
hgCNTbjoLlX//2oQU1CNj2ADAADGRfwH6CcUAwCNTbjGRfwA6B1W//9qEI2PIAMAAOidKwEAjU24
UYvI6ATc///GRfwIgL1I////AA+EMwEAAGhQs4YAjY1c////6NZU//+NRbhQUY2FMP///1BRjYVc
////UFGNTYToIWoCAA9XwMdFhCARhgCNTdhmDxNF2GYPE0XgZg8TRejHRdTsaYYA6MUeBwCNRYS5
SVJIHlCNRdRQaKizhgBqMmoOWuh8/AAAjU3Y6HtV//+NTZjoc1X//41NiOhBEAcAjY1c////6GBV
//+NTbjoWFX//4qFSP///8dF/P////+EwHQLjY0w////6DxV//9oBLSGAI1NuOghVP//jUW4UI1N
hOib+wAAD1fAx0XU7GmGAI1N2GYPE0XYi/BmDxNF4GYPE0Xo6CYeBwBWjUXUuUhSSB5QaKizhgBq
MmoOWujg+wAAjU3Y6N9U//+NTZjo11T//41NiOilDwcAjU246MdU///o2YU6AMPo17wGAMxVi+yD
5PiD7GShABKjADPEiUQkYFZqAY2BwAcAAFDomhEBAGhItIYAjUwkJOh8U///jUQkIFCNTCQ86PT6
AAAPV8DHRCQE7GmGAI1MJAhmDxNEJAiL8GYPE0QkEGYPE0QkGOh6HQcAVo1EJAi5R1JIHlBoqLSG
AGoyag5a6DP7AACNTCQI6DFU//+NTCRM6ChU//+NTCQ86PUOBwCNTCQg6BZU//+LTCRkXjPM6AZ6
OgCL5V3DVYvsg+T4g+xkoQASowAzxIlEJGBWagCNgeAHAABQ6OUQAQBoKLWGAI1MJCTox1L//41E
JCBQjUwkPOg/+gAAD1fAx0QkBOxphgCNTCQIZg8TRCQIi/BmDxNEJBBmDxNEJBjoxRwHAFaNRCQI
uUZSSB5QaJC1hgBqMmoOWuh++gAAjUwkCOh8U///jUwkTOhzU///jUwkPOhADgcAjUwkIOhhU///
i0wkZF4zzOhReToAi+Vdw2hAAgAAuJxpfwDoqoQ6AIvxibUs////jZ7gBwAAi8vopyECAITAD4Qb
BAAAUYvL6P3o//9RjY1M/v//i0AMiYU8////6E4/AgDHRfwAAAAAjX3YM8CragdZq6urM8DHRegA
AAAAiU3sZolF2I19jKurq6szwMdFnAAAAACJTaBmiUWMjUXYxkX8AlCNRYxQjY3k/v//6M7D//9Q
jY5ACAAAxkX8A+j3IgIAUI2NDP///+ghSgAAjY3k/v//6N8oAgCNTYzoiFL//41N2MZF/AfofFL/
/1GLy+hU6P//iziLQASJvUD///+JhTD///87+A+EjgIAAI1fCImdRP///7okZIYAjY1M/v//6Ovq
BgBTjU3Yi/DoFiEHAI1V2MZF/AiLzujGoQYAjU3YxkX8B+gdUv//i0dUjU3YUztHWA+F2QAAAOjn
IAcAahCNRdjGRfwJUI2NUP///+gguAYAi/BWxkX8CuhEsgMAUFaNhQT///9QjY0M////6HBjAgCL
tRD///+NjVj///+LQASFwA9F8Im1RP///+i0Uf//jU3Yx4VQ////IGyGAMZF/AfonlH//zu1EP//
/w+EpwEAALocbYYAjY1M/v//6CvqBgBoHG2GAI1NwIvw6GVQ//+LlUT///+NRcBQg8IsxkX8C41N
qOhQAgEAi9DGRfwMi87o6qAGAI1NqOhFUf//jU3AxkX8B+g5Uf//6UkBAADoDiAHAIN97AeNRdho
wKaGAA9HRdhQ6DSmOwBZWY1N2ImFNP///+gJUf//i0dYi3dUiYU4////O/APhO4AAACLvTT///+L
2FaNTdjowx8HAMZF/A2F/w+FlAAAAIN+FAeLxnYCiwZo/GKGAFDo3qU7AFlZhcB0eWoAaJRfhgCL
zujbOwIAg/j/dWZRjY20/f//6OQ8AgCL1sZF/A6NjbT9///oKqAGALqUX4YAi8joKukGAI1FwFCN
jbj9///o+uoGAI1FwFCNTdjoKxwHAI1NwOheUP//jY0E/v//xkX8Deg3oAYAjY0E/v//6Ax9BgC6
HG2GAI2NTP7//+jd6AYAjVXYi8jox58GAI1N2MZF/AfoHlD//4PGGDvzD4Um////i71A////i51E
////uhxthgCNjUz+///ooOgGALr8YoYAi8jolOgGAIPHbIPDbIm9QP///4mdRP///zu9MP///w+F
e/3//42FdP///1CNjVD+///oQ+oGALokZIYAjY10////6CsKAQCDfYQAdGiLtSz///+NfdgzwKur
q6szwMdF6AAAAADHRewHAAAAZolF2I1F2MZF/BBQjYV0////UI2N5P7//+h/wP//ahD/tTz///+N
jiAIAADGRfwRUOicBwMAjY3k/v//6JQlAgCNTdjoPU///42NdP///+gyT///jY0M////6HYlAgCN
jZz+///HRfz/////6P2eBgCNjZz+///o0nsGAGgYtoYAjU3A6O9N//+NRcBQjY1I////6Gb1AAAP
V8DHRaTsaYYAjU2oZg8TRaiL8GYPE0WwZg8TRbjo8RcHAFaNRaS5jWFYI1BocLaGAGoyag5a6Kv1
AACNTajoqk7//42NXP///+ifTv//jY1M////6GoJBwCNTcDojE7//+iefzoAw2gcAQAAuD5qfwDo
3386AIvZjbMACAAAahCLzuiAHgIAhMAPhTUBAACNuwABAABqEIvP6GkeAgCEwA+EHgEAAI2LAAoA
AGoQ6FQeAgCEwA+ECQEAAGoQi8/o2OT//2oQi9CNTdjoH5MGAFFRjUXYx0X8AAAAAFCNjdj+///o
aDkCAI1N2MZF/ALo+U3//78cbYYAjY3Y/v//i9fokOYGAGoQjYsACgAAi/DodycBAFeL0I1NwOi/
BwEAi9DGRfwDi87oXZ0GAI1NwOi4Tf//M8CNfdirq6urM8DHRegAAAAAx0XsBwAAAGaJRdiNRcDG
RfwEUI2N3P7//+gQ6AYAjUXYxkX8BVCNRcBQjU2g6Iu+//9qEGoKjbMACAAAxkX8BlCLzuiqBQMA
jU2g6KUjAgCNTcDoTk3//41N2OhGTf//jY0o////x0X8/////+gcnQYAjY0o////6PF5BgCBw2AI
AABqD4vL6DQdAgCEwA+EoQAAADPAjX3Yq2oHq6urM8Bfx0XoAAAAAIl97GaJRdhoeGqGAI1NwIl9
/OjYS///jUXYxkX8CFCNRcBQjU2A6Om9//9Qi87GRfwJ6BYdAgBQjU2g6ENEAACNTYDoBCMCAI1N
wOitTP//jU3YxkX8DeihTP//ag+Ly+hSLAEAUI1NoOhOxP//ahBqCo1FoIvOUOjMBAMAjU2gx0X8
/////+jAIgIAahCLy+iCHAIAhMAPhKYAAAAzwI192Kurq6szwMdF6AAAAADHRewHAAAAZolF2Gh4
aoYAjU3Ax0X8DgAAAOghS///jUXYxkX8D1CNRcBQjU2A6DK9//9Qi87GRfwQ6F8cAgBQjU2g6IxD
AACNTYDoTSICAI1NwOj2S///jU3YxkX8FOjqS///ahCLy+ibKwEAUI1NoOiXw///ahBqCo1FoIvO
UOgVBAMAjU2gx0X8/////+gJIgIAaOi2hgCNTcDon0r//41FwFCNjXT////oFvIAAA9XwMdFpOxp
hgCNTahmDxNFqIvwZg8TRbBmDxNFuOihFAcAVo1FpLmGc4UCUGgot4YAajJqDlroW/IAAI1NqOha
S///jU2I6FJL//+NjXj////oHQYHAI1NwOg/S///6FF8OgDDaKAAAAC4vmp/AOiSfDoAi/mJvXT/
//+NnwAIAABqEIvLiV2E6CobAgCEwA+ETgIAADPAiYV4////iYV8////iUWAjbfABQAAiUX8ahCL
zuj/GgIAhMB0HWoQi87oiSgBAIPAGI2NeP///1DoxzMCAOkbAQAAjZ8ABgAAM8CNtyAGAACNj0AG
AACNfdirq6urM8DHRegAAAAAx0XsBwAAAGaJRdiNRdjGRfwBUOgSHQIAUIvO6AodAgBQi8voAh0C
AFCNTbzoThkHAI1N2MZF/APoY0r//4u9dP///41NlOjHHgIAi/BqEI2PYAUAAMZF/AToXBoCAITA
dA9qEI2PYAUAAOjZJQEAi/BWjY1U////6CseAgCNTZTGRfwG6P0dAgCLvVj///+LNzv3dEKDfdAH
jU28jUYID0dNvIN4FAd2AosAUVDoCZ87AFlZhcB0Bos2O/d114u9WP///zv3dA+DxiCNjXj///9W
6McyAgCNjVT////opB0CAI1NvMZF/ADoskn//4u9dP///4tdhIuFeP///zuFfP///w+EywAAAFGN
RYTHRYQAAAAAUI1NlIHHIAMAAOh1DwMAjUWUxkX8B1CNTbTo/i
