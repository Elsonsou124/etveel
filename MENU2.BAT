@echo off
chcp 65001 >nul
net session >nul 2>&1
if errorlevel 1 (
  powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)
set "BATDRIVE=%~d0"
set "INSTALLER_FILE=%~f0"
powershell -NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -Command "$s=[IO.File]::ReadAllText('%~f0'); $i=$s.IndexOf('#'+'PSSTART'); try { iex $s.Substring($i) } catch { [System.Windows.Forms.MessageBox]::Show(\"$_\") }"
exit /b
#PSSTART
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$drive     = $env:BATDRIVE
$BASE      = "$drive\Windows\Tudo"
$OFFICE    = "$BASE\O365HomePremRetail 64.exe"
$KEY       = "$BASE\rarreg.key"
$WINRARDIR = "C:\Program Files\WinRAR"

# --- GERADOR AUTOMÁTICO DO ARQUIVO RARREG ---
if (-not (Test-Path "$WINRARDIR\rarreg.key")) {
    # 1. Cria a pasta do WinRAR caso ainda não exista no sistema
    if (-not (Test-Path $WINRARDIR)) { New-Item -ItemType Directory -Force -Path $WINRARDIR | Out-Null }
    
    # 2. Cria o arquivo txt provisório
    $txtPath = "$WINRARDIR\rarreg.txt"
    
    # 3. Escreve "oi aqui" no arquivo
    Set-Content -Path $txtPath -Value "RAR registration data`r`nchattchitto.com`r`nUnlimited Company License`r`nUID=45cf7e253572312b6995`r`n64122122506995900ddabb88b22559b8f25d88e1168dd8cea3bd59`r`nfe190143727199246a8460fce6cb5ffde62890079861be57638717`r`n7131ced835ed65cc743d9777f2ea71a8e32c7e593cf66794343565`r`nb41bcf56929486b8bcdac33d50ecf7739960e36503ffdcbcf7dbfc`r`n378eb1e8a5d96ddf9e5c7d6e7b122c103ee81bce156ee5ec1cf50d`r`n174c5a231523f967f5c53a4efdc7ecb9689f18a2ed6166f7608276`r`n7f5dd734a2736b2d5fb6eb5145b50ed0c7033251fe142027056408" -Force
    
    # 4. Renomeia o .txt para .key no final
    Rename-Item -Path $txtPath -NewName "rarreg.key" -Force
}
# --------------------------------------------

# Variaveis de controle do progresso
$global:tasks = New-Object System.Collections.ArrayList
$global:totalEtapas = 0
$global:etapaAtual = 0

function Log($msg) { $logBox.AppendText((Get-Date -Format 'HH:mm:ss') + "  " + $msg + "`r`n") }

function Start-Task($titulo, $script, $total = 1) {
    $out = Join-Path $env:TEMP ("inst_" + ($titulo -replace '[^a-zA-Z0-9]','') + ".txt")
    $script = "& { " + $script + " } *> '$out'; exit `$LASTEXITCODE"
    $enc = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($script))
    $p = Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -EncodedCommand $enc" -WindowStyle Hidden -PassThru
    [void]$global:tasks.Add(@{ Nome = $titulo; Proc = $p; Out = $out })
    
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
    
    Log "Iniciando $titulo..."
}

function W($id) { "winget install -e --id $id --source winget --accept-package-agreements --accept-source-agreements" }
$rarKey = "if (Test-Path '$KEY') { New-Item -ItemType Directory -Force -Path '$WINRARDIR' | Out-Null; Copy-Item '$KEY' '$WINRARDIR\rarreg.key' -Force; Write-Host 'Licenca do WinRAR copiada.' } else { Write-Host 'rarreg.key gerado pelo script.' }"
$officeCmd = "if (Test-Path '$OFFICE') { Start-Process '$OFFICE' } else { Write-Host 'ERRO: instalador do Office nao encontrado: $OFFICE' -ForegroundColor Red }"

$programIcon = [System.Drawing.SystemIcons]::Application

# --- LAYOUT E ESTILIZACAO NOVO ---
$form = New-Object System.Windows.Forms.Form
$form.Icon = $programIcon
$form.ShowIcon = $true
$form.Text = "ASSISTENTE DE FORMATACAO PRO"
$form.Size = New-Object System.Drawing.Size(780, 650)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox = $false
$form.BackColor = [System.Drawing.Color]::FromArgb(12, 14, 20)
$form.ForeColor = [System.Drawing.Color]::White
$form.Font = New-Object System.Drawing.Font("Segoe UI", 10)

# Cabecalho do App
$titlePanel = New-Object System.Windows.Forms.Panel
$titlePanel.Size = New-Object System.Drawing.Size(780, 50)
$titlePanel.Location = New-Object System.Drawing.Point(0, 0)
$titlePanel.BackColor = [System.Drawing.Color]::FromArgb(20, 25, 35)
$form.Controls.Add($titlePanel)

$title = New-Object System.Windows.Forms.Label
$title.Text = "ASSISTENTE DE FORMATACAO"
$title.Font = New-Object System.Drawing.Font("Segoe UI Black", 16, [System.Drawing.FontStyle]::Bold)
$title.ForeColor = [System.Drawing.Color]::FromArgb(0, 255, 160)
$title.AutoSize = $true
$title.Location = New-Object System.Drawing.Point(20, 10)
$titlePanel.Controls.Add($title)

$subTitle = New-Object System.Windows.Forms.Label
$subTitle.Text = "CENTRAL DE AUTOMACAO"
$subTitle.Font = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
$subTitle.ForeColor = [System.Drawing.Color]::FromArgb(0, 180, 255)
$subTitle.AutoSize = $true
$subTitle.Location = New-Object System.Drawing.Point(400, 20)
$titlePanel.Controls.Add($subTitle)

$actions = [ordered]@{
    "Ativacão do Windows" = { Powershell -Command "irm https://get.activated.win | iex" }
    "Instalar Google Chrome"        = { Start-Task "Chrome" (W "Google.Chrome") }
    "Instalar Adobe Acrobat Reader" = { Start-Task "Acrobat" (W "Adobe.Acrobat.Reader.64-bit") }
    "Instalar WinRAR"               = { Start-Task "WinRAR" ((W "RARLab.WinRAR") + "; " + $rarKey) }
    "Instalar MSI Afterburner"      = { Start-Task "Afterburner" (W "Guru3D.Afterburner") }
    "Abrir instalador do Office"    = { if (Test-Path $OFFICE) { Start-Process $OFFICE; Log "Instalador do Office aberto" } else { Log "ERRO: Office nao encontrado em $OFFICE" } }
    "INSTALAR TUDO (Sem MSI)"       = {
        Start-Task "TUDO Sem MSI" ((@(
            "Write-Host '[1/4] Chrome'", (W "Google.Chrome"),
            "Write-Host '[2/4] Acrobat'", (W "Adobe.Acrobat.Reader.64-bit"),
            "Write-Host '[3/4] WinRAR'", (W "RARLab.WinRAR"), $rarKey,
            "Write-Host '[4/4] Office'", $officeCmd
        )) -join "; ") -total 4
    }
    "INSTALAR TUDO + Office"        = {
        Start-Task "TUDO com Office" ((@(
            "Write-Host '[1/5] Chrome'", (W "Google.Chrome"),
            "Write-Host '[2/5] Acrobat'", (W "Adobe.Acrobat.Reader.64-bit"),
            "Write-Host '[3/5] WinRAR'", (W "RARLab.WinRAR"), $rarKey,
            "Write-Host '[4/5] Afterburner'", (W "Guru3D.Afterburner"),
            "Write-Host '[5/5] Office'", $officeCmd
        )) -join "; ") -total 5
    }
}

$y = 65
foreach ($name in $actions.Keys) {
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = $name
    $btn.Size = New-Object System.Drawing.Size(290, 46)
    $btn.Location = New-Object System.Drawing.Point(20, $y)
    $btn.FlatStyle = "Flat"
    $btn.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 10)
    $btn.Cursor = [System.Windows.Forms.Cursors]::Hand

    if ($name -like "INSTALAR TUDO (Sem MSI)*") { 
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

    $bgOriginal = $btn.BackColor
    $btn.Add_MouseEnter({ $this.BackColor = [System.Drawing.Color]::FromArgb(40, 55, 80) })
    $btn.Add_MouseLeave({ $this.BackColor = $bgOriginal })

    $btn.Tag = $actions[$name]
    $btn.Add_Click({ try { & $this.Tag } catch { [System.Windows.Forms.MessageBox]::Show("Erro: $_") } })
    $form.Controls.Add($btn)
    $y += 52
}

$sair = New-Object System.Windows.Forms.Button
$sair.Text = "Sair"
$sair.Size = New-Object System.Drawing.Size(290, 38)
$sair.Location = New-Object System.Drawing.Point(20, ($y + 8))
$sair.FlatStyle = "Flat"
$sair.Font = New-Object System.Drawing.Font("Segoe UI Bold", 10)
$sair.BackColor = [System.Drawing.Color]::FromArgb(140, 20, 30)
$sair.ForeColor = [System.Drawing.Color]::White
$sair.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(255, 60, 80)
$sair.Cursor = [System.Windows.Forms.Cursors]::Hand
$sair.Add_Click({ $form.Close() })
$form.Controls.Add($sair)

# --- ELEMENTOS VISUAIS DE PROGRESSO ---
$logTitle = New-Object System.Windows.Forms.Label
$logTitle.Text = "LOG DE INSTALACAO"
$logTitle.Font = New-Object System.Drawing.Font("Segoe UI Bold", 12)
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
$logBox.Size = New-Object System.Drawing.Size(410, 428)
$logBox.BackColor = [System.Drawing.Color]::FromArgb(6, 8, 12)
$logBox.ForeColor = [System.Drawing.Color]::FromArgb(0, 255, 130)
$logBox.Font = New-Object System.Drawing.Font("Consolas", 9.5)
$logBox.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$form.Controls.Add($logBox)

# --- MARCA D'AGUA ---
$watermark = New-Object System.Windows.Forms.Label
$watermark.Text = "Elson (Criatividade E Tudo)"
$watermark.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Italic)
$watermark.ForeColor = [System.Drawing.Color]::FromArgb(0, 180, 255)
$watermark.AutoSize = $true
$watermark.Location = New-Object System.Drawing.Point(575, 578)
$form.Controls.Add($watermark)

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 1000
$timer.Add_Tick({
    foreach ($t in @($global:tasks)) {
        if ($global:totalEtapas -gt 1 -and (Test-Path $t.Out)) {
            $conteudo = Get-Content $t.Out -ErrorAction SilentlyContinue
            $etapaDetectada = ($conteudo | Select-String -Pattern '\[(\d+)/\d+\]' | Select-Object -Last 1)
            if ($etapaDetectada -match '\[(\d+)/') {
                $num = [int]$matches[1]
                if ($num -gt $global:etapaAtual) {
                    $global:etapaAtual = $num
                    $progressBar.Value = [Math]::Min($num, $global:totalEtapas)
                    $lblStatus.Text = "Progresso do lote: Etapa $num de $global:totalEtapas..."
                }
            }
        }

        if ($t.Proc.HasExited) {
            $c = $t.Proc.ExitCode
            if ($c -eq 0) { Log ("Aplicativo instalado - " + $t.Nome) }
            elseif ($c -eq -1978335189) { Log ("Aplicativo ja estava instalado - " + $t.Nome) }
            else {
                Log ("ERRO ao instalar " + $t.Nome + " (codigo $c)")
                if (Test-Path $t.Out) {
                    Get-Content $t.Out | Where-Object { $_ -match '\w' -and $_ -notmatch '^[\s\-\\|/]+$' } | Select-Object -Last 4 | ForEach-Object { Log ("     > " + $_.Trim()) }
                }
                if ($t.Nome -eq "Afterburner") {
                    Log "     Abrindo o site oficial do MSI Afterburner para baixar manualmente."
                    Start-Process "https://www.msi.com/Landing/afterburner/graphics-cards"
                }
            }
            $global:tasks.Remove($t)
            
            if ($global:tasks.Count -gt 0) {
                $proximaTarefa = $global:tasks[0].Nome
                $lblStatus.Text = "Instalando: $proximaTarefa (Fila: " + $global:tasks.Count + " restante)..."
            } else {
                $progressBar.Style = [System.Windows.Forms.ProgressBarStyle]::Blocks
                $progressBar.Value = $progressBar.Maximum
                $lblStatus.Text = "Concluido com sucesso!"
                $lblStatus.ForeColor = [System.Drawing.Color]::FromArgb(0, 255, 160)
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