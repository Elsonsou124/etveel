@echo off
title Assistente de Formatacao
color 0B

REM =====================================================================
REM 1. ELEVAÇÃO ADMINISTRATIVA
REM =====================================================================
net session >nul 2>&1
if errorlevel 1 (
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

set "BATDRIVE=%~d0"
set "INSTALLER_FILE=%~f0"
set "APP_VER=v0.90"

:ESCOLHA_MODO
cls
echo  %APP_VER%
echo.
echo  [1] Modo FULL
echo  [2] Modo Lite
echo  [3] Modo Tema GTA 6
echo.
choice /c 123 /n /m "> "

if errorlevel 3 goto INICIAR_GTA6
if errorlevel 2 goto INICIAR_CLI
if errorlevel 1 goto INICIAR_GUI

:INICIAR_GUI
set "UI_MODE=GUI"
powershell -NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -Command "$s=[IO.File]::ReadAllText($env:INSTALLER_FILE,[Text.Encoding]::UTF8); $a=$s.IndexOf('#'+'PSSTART'); $b=$s.IndexOf('#'+'PSEND'); try { iex $s.Substring($a, $b-$a) } catch { Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.MessageBox]::Show(\"Erro: $_\") }"
exit /b

:INICIAR_CLI
cls
set "UI_MODE=CLI"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$s=[IO.File]::ReadAllText($env:INSTALLER_FILE,[Text.Encoding]::UTF8); $a=$s.IndexOf('#'+'PSSTART'); $b=$s.IndexOf('#'+'PSEND'); try { iex $s.Substring($a, $b-$a) } catch { Write-Host \"Erro: $_\" -ForegroundColor Red; pause }"
exit /b

:INICIAR_GTA6
cls
set "UI_MODE=GTA6"
powershell -NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -Command "$s=[IO.File]::ReadAllText($env:INSTALLER_FILE,[Text.Encoding]::UTF8); $a=$s.IndexOf('#'+'PSSTART'); $b=$s.IndexOf('#'+'PSEND'); try { iex $s.Substring($a, $b-$a) } catch { Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.MessageBox]::Show(\"Erro: $_\") }"
exit /b

#PSSTART
# =====================================================================
# SEÇÃO 1: VARIÁVEIS GLOBAIS E AJUSTES DE SISTEMA (COMPARTILHADOS)
# =====================================================================
$VersaoAtual  = $env:APP_VER
$ModoExecucao = $env:UI_MODE
$drive        = $env:BATDRIVE
$BASE         = "$drive\Windows\Tudo"
$WINRARDIR    = "C:\Program Files\WinRAR"

if ($ModoExecucao -eq 'CLI') {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $Host.UI.RawUI.WindowTitle = "Assistente de Formatacao Lite ($VersaoAtual) - Elson (Criatividade E Tudo)"
    Write-Host "Aplicando ajustes iniciais do sistema (Energia, Icones, Visualizador)..." -ForegroundColor DarkCyan
}

# 1.1 - Configuração de Energia (Não suspender durante instalações)
try {
    powercfg /change monitor-timeout-ac 0 > $null
    powercfg /change monitor-timeout-dc 0 > $null
    powercfg /change standby-timeout-ac 0 > $null
    powercfg /change standby-timeout-dc 0 > $null
    powercfg /change hibernate-timeout-ac 0 > $null
    powercfg /change hibernate-timeout-dc 0 > $null
    powercfg /hibernate off > $null
    powercfg /setactive SCHEME_CURRENT > $null
} catch {}

# 1.2 - Ativar ícones clássicos na Área de Trabalho (Este Computador, Usuário, Painel)
$iconsPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel"
if (-not (Test-Path $iconsPath)) { New-Item -Path $iconsPath -Force | Out-Null }
Set-ItemProperty -Path $iconsPath -Name "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" -Value 0 -Type DWord -Force
Set-ItemProperty -Path $iconsPath -Name "{59031a47-3f72-44a7-89c5-5595fe6b30ee}" -Value 0 -Type DWord -Force
Set-ItemProperty -Path $iconsPath -Name "{5399E694-6CE5-4D6C-8FCE-1D8870FDCBA0}" -Value 0 -Type DWord -Force

# 1.3 - Ativar Visualizador de Fotos Clássico do Windows
$photoPath = "HKLM:\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations"
if (-not (Test-Path $photoPath)) { New-Item -Path $photoPath -Force | Out-Null }
foreach ($ext in @('.jpg','.jpeg','.png','.bmp','.gif','.tif','.tiff')) {
    New-ItemProperty -Path $photoPath -Name $ext -Value 'PhotoViewer.FileAssoc.Tiff' -PropertyType String -Force | Out-Null
}

# 1.4 - APIs Nativas (Atualização do Desktop + Scroll do Console GUI)
$winApiCode = @'
[System.Runtime.InteropServices.DllImport("Shell32.dll")]
public static extern int SHChangeNotify(int eventId, int flags, IntPtr item1, IntPtr item2);
public static void Atualizar() { SHChangeNotify(0x08000000, 0x1000, IntPtr.Zero, IntPtr.Zero); }

[System.Runtime.InteropServices.DllImport("user32.dll", CharSet = System.Runtime.InteropServices.CharSet.Auto)]
public static extern IntPtr SendMessage(IntPtr hWnd, int Msg, IntPtr wParam, IntPtr lParam);
'@
Add-Type -MemberDefinition $winApiCode -Namespace "WinAPI" -Name "Desktop" -ErrorAction SilentlyContinue
[WinAPI.Desktop]::Atualizar()

# 1.5 - Gerador automático da chave de registro do WinRAR
if (-not (Test-Path "$WINRARDIR\rarreg.key")) {
    if (-not (Test-Path $WINRARDIR)) { New-Item -ItemType Directory -Force -Path $WINRARDIR | Out-Null }
    $txtPath = "$WINRARDIR\rarreg.txt"
    Set-Content -Path $txtPath -Value "RAR registration data`r`nchattchitto.com`r`nUnlimited Company License`r`nUID=45cf7e253572312b6995`r`n64122122506995900ddabb88b22559b8f25d88e1168dd8cea3bd59`r`nfe190143727199246a8460fce6cb5ffde62890079861be57638717`r`n7131ced835ed65cc743d9777f2ea71a8e32c7e593cf66794343565`r`nb41bcf56929486b8bcdac33d50ecf7739960e36503ffdcbcf7dbfc`r`n378eb1e8a5d96ddf9e5c7d6e7b122c103ee81bce156ee5ec1cf50d`r`n174c5a231523f967f5c53a4efdc7ecb9689f18a2ed6166f7608276`r`n7f5dd734a2736b2d5fb6eb5145b50ed0c7033251fe142027056408" -Force
    Rename-Item -Path $txtPath -NewName "rarreg.key" -Force
}

# 1.6 - Desativar Proteções do Windows Defender temporariamente
try {
    Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue
    Set-MpPreference -DisableBehaviorMonitoring $true -ErrorAction SilentlyContinue
    Set-MpPreference -DisableBlockAtFirstSeen $true -ErrorAction SilentlyContinue
    Set-MpPreference -DisableIOAVProtection $true -ErrorAction SilentlyContinue
    Set-MpPreference -DisableScriptScanning $true -ErrorAction SilentlyContinue
    Set-MpPreference -SubmitSamplesConsent 2 -ErrorAction SilentlyContinue
    Set-MpPreference -MAPSReporting 0 -ErrorAction SilentlyContinue
} catch {}


# =====================================================================
# SEÇÃO 2: MOTOR DE INSTALAÇÃO COMPARTILHADO (COM TIMEOUT E FALLBACKS)
# =====================================================================
$appInstallHelpers = @'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

function Invoke-ProcessWithTimeout {
    param(
        [string]$FilePath,
        [string]$ArgumentList = "",
        [int]$TimeoutSeconds = 180
    )
    try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $FilePath
        $psi.Arguments = $ArgumentList
        $psi.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
        $psi.CreateNoWindow = $true
        $psi.UseShellExecute = $false

        $proc = [System.Diagnostics.Process]::Start($psi)
        if (-not $proc.WaitForExit($TimeoutSeconds * 1000)) {
            Write-Host "##INFO Tempo limite ($($TimeoutSeconds)s) atingido para $([IO.Path]::GetFileName($FilePath)). Encerrando processo para nao travar..."
            try { $proc.Kill() } catch {}
            return 1460
        }
        return [int]$proc.ExitCode
    } catch {
        return 1
    }
}

function Get-WingetExecutable {
    $wingetCommand = Get-Command winget.exe -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($wingetCommand) { return $wingetCommand.Source }
    try {
        $appInstaller = Get-AppxPackage -Name Microsoft.DesktopAppInstaller -ErrorAction SilentlyContinue | Sort-Object Version -Descending | Select-Object -First 1
        if ($appInstaller) {
            $candidate = Join-Path $appInstaller.InstallLocation 'winget.exe'
            if (Test-Path $candidate) { return $candidate }
        }
    } catch {}
    return $null
}

function Ensure-WinGetInstalled {
    if (Get-WingetExecutable) { return }
    Write-Host "##INFO WinGet nao detectado. Instalando App Installer..."
    $tmpFile = Join-Path $env:TEMP ("WinGet_" + [guid]::NewGuid().ToString('N') + ".msixbundle")
    try {
        Invoke-WebRequest -Uri "https://aka.ms/getwinget" -OutFile $tmpFile -UseBasicParsing -TimeoutSec 90 -ErrorAction Stop
        Add-AppxPackage -Path $tmpFile -ErrorAction Stop
        Write-Host "##INFO WinGet instalado com sucesso!"
    } catch {
        Write-Host "##INFO WinGet indisponivel. Usando downloads diretos."
    } finally {
        Remove-Item -LiteralPath $tmpFile -Force -ErrorAction SilentlyContinue
    }
}

function Invoke-WingetSafe {
    param([string]$Id, [int]$TimeoutSeconds = 180)
    $wg = Get-WingetExecutable
    if (-not $wg) { return 1 }
    $args = "install --exact --id $Id --source winget --silent --accept-package-agreements --accept-source-agreements --disable-interactivity"
    return (Invoke-ProcessWithTimeout -FilePath $wg -ArgumentList $args -TimeoutSeconds $TimeoutSeconds)
}

function Download-FileSafe {
    param([string]$Uri, [string]$OutFile, [int]$TimeoutSec = 120, [int]$MinBytes = 500000)
    try {
        Invoke-WebRequest -Uri $Uri -OutFile $OutFile -UseBasicParsing -TimeoutSec $TimeoutSec -ErrorAction Stop
        if ((Test-Path $OutFile) -and (Get-Item $OutFile).Length -gt $MinBytes) { return $true }
    } catch {}
    try {
        $curl = Get-Command curl.exe -ErrorAction SilentlyContinue
        if ($curl) {
            $code = Invoke-ProcessWithTimeout -FilePath $curl.Source -ArgumentList "--fail --location --silent --connect-timeout 20 --max-time $TimeoutSec --output `"$OutFile`" `"$Uri`"" -TimeoutSeconds ($TimeoutSec + 15)
            if ($code -eq 0 -and (Test-Path $OutFile) -and (Get-Item $OutFile).Length -gt $MinBytes) { return $true }
        }
    } catch {}
    return $false
}

function Install-GamerPowerPlan {
    try {
        $guid = (powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61) 2>$null
        if ($guid -match "([a-f0-9\-]{36})") { powercfg -setactive $Matches[1] 2>$null }
        else { powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null }
        $global:LASTEXITCODE = 0
    } catch { $global:LASTEXITCODE = 0 }
}

function Install-GamerNetFx3 {
    try {
        $feat = Get-WindowsOptionalFeature -Online -FeatureName NetFx3 -ErrorAction SilentlyContinue
        if ($feat -and $feat.State -eq 'Enabled') { $global:LASTEXITCODE = -1978335189; return }
        Write-Host "##INFO Ativando recurso NetFx3 via DISM (limite 300s)..."
        $code = Invoke-ProcessWithTimeout -FilePath "dism.exe" -ArgumentList "/Online /Enable-Feature /FeatureName:NetFx3 /All /NoRestart /Quiet" -TimeoutSeconds 300
        if ($code -eq 0 -or $code -eq 3010) { $global:LASTEXITCODE = 0; return }
        Write-Host "##INFO Tentando metodo alternativo via PowerShell..."
        Enable-WindowsOptionalFeature -Online -FeatureName NetFx3 -All -NoRestart -ErrorAction SilentlyContinue | Out-Null
        $global:LASTEXITCODE = 0
    } catch { $global:LASTEXITCODE = 0 }
}

function Install-GamerDotNet8 {
    Ensure-WinGetInstalled
    Write-Host "##INFO Tentativa 1: Instalando .NET Desktop Runtime 8 via WinGet..."
    $code = Invoke-WingetSafe -Id "Microsoft.DotNet.DesktopRuntime.8" -TimeoutSeconds 180
    if ($code -eq 0 -or $code -eq -1978335189) { $global:LASTEXITCODE = $code; return }

    Write-Host "##INFO Tentativa 2: Baixando instalador direto oficial da Microsoft..."
    $urls = @(
        "https://aka.ms/dotnet/8.0/windowsdesktop-runtime-win-x64.exe",
        "https://download.visualstudio.microsoft.com/download/pr/9a622a4b-9706-47b2-a43c-660c6e8cf3a7/1779e3774883f360ecb3f7f02d04a621/windowsdesktop-runtime-8.0.10-win-x64.exe"
    )
    foreach ($u in $urls) {
        $p = Join-Path $env:TEMP ("dotnet8_" + [guid]::NewGuid().ToString('N') + ".exe")
        try {
            if (Download-FileSafe -Uri $u -OutFile $p -TimeoutSec 120) {
                $exit = Invoke-ProcessWithTimeout -FilePath $p -ArgumentList "/install /quiet /norestart" -TimeoutSeconds 180
                if ($exit -eq 0 -or $exit -eq 3010 -or $exit -eq 1638) { $global:LASTEXITCODE = 0; return }
            }
        } finally { Remove-Item -LiteralPath $p -Force -ErrorAction SilentlyContinue }
    }
    $global:LASTEXITCODE = 1
}

function Install-GamerVCRedist {
    Ensure-WinGetInstalled
    Write-Host "##INFO Tentativa 1: Instalando Visual C++ 2015-2022 (x64/x86) via WinGet..."
    $c64 = Invoke-WingetSafe -Id "Microsoft.VCRedist.2015+.x64" -TimeoutSeconds 150
    $c86 = Invoke-WingetSafe -Id "Microsoft.VCRedist.2015+.x86" -TimeoutSeconds 150
    if (($c64 -eq 0 -or $c64 -eq -1978335189) -and ($c86 -eq 0 -or $c86 -eq -1978335189)) {
        Write-Host "##INFO Visual C++ instalado via WinGet!"
        $global:LASTEXITCODE = 0; return
    }

    Write-Host "##INFO Tentativa 2: Baixando Visual C++ AIO (limite 240s)..."
    $aioUrls = @(
        "https://github.com/abbodi1406/vcredist/releases/latest/download/VisualCppRedist_AIO_x86_x64.exe",
        "https://github.com/ChrisTitusTech/winutil/raw/main/vcredist.exe"
    )
    foreach ($u in $aioUrls) {
        $p = Join-Path $env:TEMP ("vcredist_aio_" + [guid]::NewGuid().ToString('N') + ".exe")
        try {
            if (Download-FileSafe -Uri $u -OutFile $p -TimeoutSec 120) {
                $exit = Invoke-ProcessWithTimeout -FilePath $p -ArgumentList "/ai /gm2" -TimeoutSeconds 240
                if ($exit -eq 0 -or $exit -eq 3010) { $global:LASTEXITCODE = 0; return }
            }
        } finally { Remove-Item -LiteralPath $p -Force -ErrorAction SilentlyContinue }
    }

    Write-Host "##INFO Tentativa 3: Forcando instalacao direta oficial Microsoft (x64 e x86)..."
    $msOk = $false
    foreach ($arch in @("x64", "x86")) {
        $msUrl = "https://aka.ms/vs/17/release/vc_redist.$arch.exe"
        $msFile = Join-Path $env:TEMP ("vc_ms_$arch_" + [guid]::NewGuid().ToString('N') + ".exe")
        try {
            if (Download-FileSafe -Uri $msUrl -OutFile $msFile -TimeoutSec 90) {
                $exit = Invoke-ProcessWithTimeout -FilePath $msFile -ArgumentList "/install /quiet /norestart" -TimeoutSeconds 120
                if ($exit -eq 0 -or $exit -eq 3010 -or $exit -eq 1638) { $msOk = $true }
            }
        } finally { Remove-Item -LiteralPath $msFile -Force -ErrorAction SilentlyContinue }
    }
    $global:LASTEXITCODE = if ($msOk) { 0 } else { 1 }
}

function Install-GamerDirectX {
    Ensure-WinGetInstalled
    Write-Host "##INFO Tentativa 1: Instalando DirectX via WinGet..."
    $wgCode = Invoke-WingetSafe -Id "Microsoft.DirectX" -TimeoutSeconds 180
    if ($wgCode -eq 0 -or $wgCode -eq -1978335189) { $global:LASTEXITCODE = $wgCode; return }

    Write-Host "##INFO Tentativa 2: Baixando DirectX Web Installer oficial..."
    $webFile = Join-Path $env:TEMP ("dxweb_" + [guid]::NewGuid().ToString('N') + ".exe")
    try {
        if (Download-FileSafe -Uri "https://download.microsoft.com/download/1/7/1/1718CCC4-6315-4D8E-9543-8E28A4E18C4C/dxwebsetup.exe" -OutFile $webFile -TimeoutSec 90 -MinBytes 100000) {
            $webCode = Invoke-ProcessWithTimeout -FilePath $webFile -ArgumentList "/Q" -TimeoutSeconds 180
            if ($webCode -eq 0 -or $webCode -eq 3010) { $global:LASTEXITCODE = 0; return }
        }
    } finally { Remove-Item -LiteralPath $webFile -Force -ErrorAction SilentlyContinue }

    Write-Host "##INFO Tentativa 3: Baixando pacote offline DirectX Jun 2010..."
    $dxUrls = @(
        "https://github.com/lucasg/Dependencies/releases/download/v1.11.1/directx_Jun2010_redist.exe",
        "https://archive.org/download/directx_Jun2010_redist/directx_Jun2010_redist.exe"
    )
    foreach ($u in $dxUrls) {
        $id = [guid]::NewGuid().ToString('N')
        $d = Join-Path $env:TEMP "dxsetup_$id.exe"
        $dir = Join-Path $env:TEMP "DX_$id"
        try {
            if (Download-FileSafe -Uri $u -OutFile $d -TimeoutSec 120 -MinBytes 5000000) {
                New-Item -ItemType Directory -Force -Path $dir | Out-Null
                $null = Invoke-ProcessWithTimeout -FilePath $d -ArgumentList "/Q /T:`"$dir`"" -TimeoutSeconds 90
                $setupExe = Join-Path $dir "DXSETUP.exe"
                if (Test-Path $setupExe) {
                    $insCode = Invoke-ProcessWithTimeout -FilePath $setupExe -ArgumentList "/silent" -TimeoutSeconds 180
                    if ($insCode -eq 0 -or $insCode -eq 3010) { $global:LASTEXITCODE = 0; return }
                }
            }
        } finally {
            Remove-Item -LiteralPath $d -Force -ErrorAction SilentlyContinue
            Remove-Item -LiteralPath $dir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    $global:LASTEXITCODE = 1
}

function Install-GamerGPUApp {
    Ensure-WinGetInstalled
    Write-Host "##INFO Detectando Hardware de Video (Intel/AMD/NVIDIA)..."
    try {
        $gpus = Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue
        if (-not $gpus) { Write-Host "##INFO Nenhuma placa de video detectada."; $global:LASTEXITCODE = 0; return }
        $gpuNames = $gpus | Select-Object -ExpandProperty Name
        Write-Host "##INFO GPU(s) Detectada(s): $($gpuNames -join ' | ')"

        foreach ($gpu in $gpus) {
            $name = $gpu.Name
            $appId = $null; $appName = $null; $directUrl = $null; $webUrl = $null
            if ($name -match '(?i)NVIDIA') {
                $appId = 'Nvidia.NVIDIAApp'; $appName = 'NVIDIA App (Oficial)'; $directUrl = 'https://dtm.nvidia.com/nvidia-app/direct-download'; $webUrl = 'https://www.nvidia.com/pt-br/software/nvidia-app/'
            } elseif ($name -match '(?i)AMD|Radeon') {
                $appId = 'AdvancedMicroDevices.AMDSoftware'; $appName = 'AMD Software Adrenalin'; $webUrl = 'https://www.amd.com/pt/support/download/drivers.html'
            } elseif ($name -match '(?i)Intel') {
                $appId = 'Intel.DriverAndSupportAssistant'; $appName = 'Intel Driver & Support Assistant'; $directUrl = 'https://dsadata.intel.com/installer'; $webUrl = 'https://www.intel.com.br/content/www/br/pt/support/intel-driver-support-assistant.html'
            }

            if ($appId) {
                $success = $false
                Write-Host "##INFO Processando $appName..."
                $wgCode = Invoke-WingetSafe -Id $appId -TimeoutSeconds 240
                if ($wgCode -eq 0 -or $wgCode -eq -1978335189) { $success = $true }
                if (-not $success -and $directUrl) {
                    $setupPath = Join-Path $env:TEMP ("gpu_setup_" + [guid]::NewGuid().ToString('N') + ".exe")
                    try {
                        if (Download-FileSafe -Uri $directUrl -OutFile $setupPath -TimeoutSec 150) {
                            $exit = Invoke-ProcessWithTimeout -FilePath $setupPath -ArgumentList "/s /noreboot" -TimeoutSeconds 240
                            if ($exit -eq 0 -or $exit -eq 3010) { $success = $true }
                        }
                    } finally { Remove-Item -LiteralPath $setupPath -Force -ErrorAction SilentlyContinue }
                }
                if (-not $success -and $webUrl) {
                    Write-Host "##INFO Abrindo pagina oficial no navegador..."
                    Start-Process $webUrl -ErrorAction SilentlyContinue
                }
            }
        }
        $global:LASTEXITCODE = 0
    } catch { $global:LASTEXITCODE = 0 }
}

function Invoke-WindowsUpdate {
    Write-Host "##INFO Iniciando varredura de atualizacoes do Windows (aguarde)..."
    try {
        $session = New-Object -ComObject Microsoft.Update.Session
        $searcher = $session.CreateUpdateSearcher()
        $result = $searcher.Search("IsInstalled=0 and Type='Software'")
        if ($result.Updates.Count -eq 0) { Write-Host "##INFO Nenhuma atualizacao pendente"; $global:LASTEXITCODE = 0; return }
        Write-Host ("##INFO Encontradas " + $result.Updates.Count + " atualizacoes. Baixando...")
        $downloader = $session.CreateUpdateDownloader(); $downloader.Updates = $result.Updates; $downloader.Download() | Out-Null
        Write-Host "##INFO Baixado. Instalando agora (pode demorar)..."
        $installer = $session.CreateUpdateInstaller(); $installer.Updates = $result.Updates; $installResult = $installer.Install()
        $global:LASTEXITCODE = if ($installResult.ResultCode -eq 2) { 0 } else { $installResult.ResultCode }
    } catch { Write-Host ("##INFO Erro interno: " + $_.Exception.Message); $global:LASTEXITCODE = 1 }
}

function Invoke-DriverUpdate {
    Write-Host "##INFO Buscando drivers oficiais pelo Windows Update..."
    try {
        $session = New-Object -ComObject Microsoft.Update.Session
        $searcher = $session.CreateUpdateSearcher()
        $result = $searcher.Search("IsInstalled=0 and Type='Driver'")
        if ($result.Updates.Count -eq 0) { Write-Host "##INFO Todos os drivers ja estao atualizados"; $global:LASTEXITCODE = 0; return }
        Write-Host ("##INFO Encontrados " + $result.Updates.Count + " drivers pendentes. Baixando...")
        $downloader = $session.CreateUpdateDownloader(); $downloader.Updates = $result.Updates; $downloader.Download() | Out-Null
        Write-Host "##INFO Instalando drivers na maquina..."
        $installer = $session.CreateUpdateInstaller(); $installer.Updates = $result.Updates; $installResult = $installer.Install()
        $global:LASTEXITCODE = if ($installResult.ResultCode -eq 2) { 0 } else { $installResult.ResultCode }
    } catch { Write-Host ("##INFO Erro ao buscar drivers: " + $_.Exception.Message); $global:LASTEXITCODE = 1 }
}

function Get-VerifiedInstaller {
    param([string]$Uri, [string]$FileName, [string]$PublisherPattern)
    $path = Join-Path $env:TEMP $FileName
    Invoke-WebRequest -Uri $Uri -OutFile $path -UseBasicParsing -TimeoutSec 180 -ErrorAction Stop
    $signature = Get-AuthenticodeSignature -FilePath $path
    if ($signature.Status -ne 'Valid' -or $signature.SignerCertificate.Subject -notmatch $PublisherPattern) {
        Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
        throw "Assinatura digital invalida: $Uri"
    }
    return $path
}

function Test-AdobeReaderInstalled {
    $roots = @($env:ProgramFiles, ${env:ProgramFiles(x86)}) | Where-Object { $_ }
    foreach ($root in $roots) {
        foreach ($relative in @('Adobe\Acrobat DC\Acrobat\Acrobat.exe','Adobe\Acrobat Reader DC\Reader\AcroRd32.exe')) {
            if (Test-Path -LiteralPath (Join-Path $root $relative)) { return $true }
        }
    }
    return $false
}

function Install-AdobeReaderDirect {
    $global:LASTEXITCODE = 1
    if (Test-AdobeReaderInstalled) { $global:LASTEXITCODE = -1978335189; return }
    if (-not [Environment]::Is64BitOperatingSystem) { return }
    $url = 'https://ardownload2.adobe.com/pub/adobe/acrobat/win/AcrobatDC/2600322075/AcroRdrDCx642600322075_MUI.exe'
    $setup = Join-Path $env:TEMP ('AdobeReader_' + [guid]::NewGuid().ToString('N') + '.exe')
    try {
        if (Download-FileSafe -Uri $url -OutFile $setup -TimeoutSec 240) {
            $sig = Get-AuthenticodeSignature -FilePath $setup
            if ($sig.Status -eq 'Valid' -and $sig.SignerCertificate.Subject -match '(?i)(CN|O)=Adobe') {
                $code = Invoke-ProcessWithTimeout -FilePath $setup -ArgumentList '-sfx_nu /sAll /rs /msi EULA_ACCEPT=YES' -TimeoutSeconds 240
                if ($code -in @(0,3010,1641)) { $global:LASTEXITCODE = 0 }
                elseif ($code -eq 1638 -and (Test-AdobeReaderInstalled)) { $global:LASTEXITCODE = -1978335189 }
            }
        }
    } finally { Remove-Item -LiteralPath $setup -Force -ErrorAction SilentlyContinue }
}

function Test-MenuPackageInstalled {
    param([string]$Id)
    $roots = @($env:ProgramFiles, ${env:ProgramFiles(x86)}) | Where-Object { $_ }
    $relative = if ($Id -eq 'RARLab.WinRAR') { 'WinRAR\WinRAR.exe' } else { 'MSI Afterburner\MSIAfterburner.exe' }
    foreach ($root in $roots) { if (Test-Path -LiteralPath (Join-Path $root $relative)) { return $true } }
    return $false
}

function Install-MenuPackageDirect {
    param([string]$Id)
    $global:LASTEXITCODE = 1
    if (Test-MenuPackageInstalled -Id $Id) { $global:LASTEXITCODE = -1978335189; return }
    if ($Id -eq 'RARLab.WinRAR') {
        $url = 'https://www.rarlab.com/rar/winrar-x64-723br.exe'
        $dl = Join-Path $env:TEMP ('WinRAR_' + [guid]::NewGuid().ToString('N') + '.exe')
        try {
            if (Download-FileSafe -Uri $url -OutFile $dl -TimeoutSec 180) {
                $code = Invoke-ProcessWithTimeout -FilePath $dl -ArgumentList '-s1' -TimeoutSeconds 180
                if ($code -in @(0,3010,1641) -and (Test-MenuPackageInstalled -Id $Id)) { $global:LASTEXITCODE = 0 }
            }
        } finally { Remove-Item -LiteralPath $dl -Force -ErrorAction SilentlyContinue }
    } else {
        $url = 'https://ftp.nluug.nl/pub/games/PC/guru3d/afterburner/%5BGuru3D%5D-MSIAfterburnerSetup466Build16757.zip'
        $dl = Join-Path $env:TEMP ('AB_' + [guid]::NewGuid().ToString('N') + '.zip')
        $dir = Join-Path $env:TEMP ('AB_' + [guid]::NewGuid().ToString('N'))
        try {
            if (Download-FileSafe -Uri $url -OutFile $dl -TimeoutSec 180) {
                Expand-Archive -LiteralPath $dl -DestinationPath $dir -Force
                $exe = Get-ChildItem -Path $dir -Filter "MSIAfterburnerSetup*.exe" | Select-Object -First 1
                if ($exe) {
                    $code = Invoke-ProcessWithTimeout -FilePath $exe.FullName -ArgumentList '/S' -TimeoutSeconds 180
                    if ($code -in @(0,3010,1641) -and (Test-MenuPackageInstalled -Id $Id)) { $global:LASTEXITCODE = 0 }
                }
            }
        } finally {
            Remove-Item -LiteralPath $dl -Force -ErrorAction SilentlyContinue
            Remove-Item -LiteralPath $dir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

function Install-AppFallback {
    param([string]$Id)
    $global:LASTEXITCODE = 1
    Ensure-WinGetInstalled

    if ($Id -in @('RARLab.WinRAR','Guru3D.Afterburner') -and (Test-MenuPackageInstalled -Id $Id)) {
        $global:LASTEXITCODE = -1978335189; return
    }
    if ($Id -eq 'Adobe.Acrobat.Reader.64-bit' -and (Test-AdobeReaderInstalled)) {
        $global:LASTEXITCODE = -1978335189; return
    }
    try {
        $wingetCode = Invoke-WingetSafe -Id $Id -TimeoutSeconds 240
        if ($wingetCode -eq 0 -or $wingetCode -eq -1978335189) {
            if ($Id -eq 'Google.Chrome') { Set-TaskbarChromeLayout }
            $global:LASTEXITCODE = $wingetCode; return
        }
        switch ($Id) {
            'Google.Chrome' {
                $fileName = 'ChromeEnterprise_' + [guid]::NewGuid().ToString('N') + '.msi'
                $setup = Get-VerifiedInstaller -Uri 'https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise64.msi' -FileName $fileName -PublisherPattern '(?i)(CN=Google LLC|O=Google LLC)'
                $code = Invoke-ProcessWithTimeout -FilePath (Join-Path $env:SystemRoot 'System32\msiexec.exe') -ArgumentList "/i `"$setup`" /qn /norestart" -TimeoutSeconds 180
                Remove-Item -LiteralPath $setup -Force -ErrorAction SilentlyContinue
                if ($code -eq 0 -or $code -eq 3010) { Set-TaskbarChromeLayout }
                $global:LASTEXITCODE = $code; return
            }
            'Adobe.Acrobat.Reader.64-bit' { Install-AdobeReaderDirect; return }
            'RARLab.WinRAR' { Install-MenuPackageDirect -Id $Id; return }
            'Guru3D.Afterburner' { Install-MenuPackageDirect -Id $Id; return }
            default { $global:LASTEXITCODE = 1; return }
        }
    }
    catch {
        if ($Id -eq 'Adobe.Acrobat.Reader.64-bit') { Install-AdobeReaderDirect; return }
        if ($Id -in @('RARLab.WinRAR','Guru3D.Afterburner')) { Install-MenuPackageDirect -Id $Id; return }
        $global:LASTEXITCODE = 1
    }
}

function Get-OfficeInstaller {
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    $uri = 'https://raw.githubusercontent.com/Elsonsou124/etveel/main/OFF.bat'
    $response = Invoke-WebRequest -Uri $uri -UseBasicParsing -TimeoutSec 180 -ErrorAction Stop
    $txt = [string]$response.Content
    $marker = '###' + 'PAYLOAD###'
    $index = $txt.LastIndexOf($marker)
    if ($index -lt 0) { throw 'Payload do Office nao encontrada.' }
    $payload = $txt.Substring($index + $marker.Length) -replace '\s', ''
    $bytes = [Convert]::FromBase64String($payload)
    if ($bytes.Length -lt 2 -or $bytes[0] -ne 77 -or $bytes[1] -ne 90) { throw 'Executavel invalido' }
    $exe = Join-Path $env:TEMP ('OfficeSetup_' + [guid]::NewGuid().ToString('N') + '.exe')
    try {
        [IO.File]::WriteAllBytes($exe, $bytes)
        $signature = Get-AuthenticodeSignature -FilePath $exe
        if ($signature.Status -ne 'Valid' -or -not $signature.SignerCertificate -or $signature.SignerCertificate.Subject -notmatch '(?i)(CN|O)=Microsoft Corporation(?:,|$)') {
            throw 'Assinatura Microsoft invalida'
        }
        return $exe
    } catch {
        Remove-Item -LiteralPath $exe -Force -ErrorAction SilentlyContinue
        throw
    }
}

function Install-OfficeDeployment {

    $exe = $null
    $processo = $null

    try {
        Write-Host "##INFO Baixando e validando instalador do Office..."
        $exe = Get-OfficeInstaller

        if (-not $exe -or -not (Test-Path -LiteralPath $exe)) {
            throw "Instalador do Office não encontrado."
        }

        $regPath = "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration"
        $wordJaExistia = (Test-Path "$env:ProgramFiles\Microsoft Office\root\Office16\WINWORD.EXE") -or (Test-Path "${env:ProgramFiles(x86)}\Microsoft Office\root\Office16\WINWORD.EXE")
        $dataModificacaoAnterior = $null
        if ($wordJaExistia) {
            $arqWord = Get-Item "$env:ProgramFiles\Microsoft Office\root\Office16\WINWORD.EXE", "${env:ProgramFiles(x86)}\Microsoft Office\root\Office16\WINWORD.EXE" -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($arqWord) { $dataModificacaoAnterior = $arqWord.LastWriteTime }
        }

        Write-Host "##INFO Executando instalador do Office..."
        $processo = Start-Process -FilePath $exe -PassThru

        $officePids = New-Object 'System.Collections.Generic.HashSet[int]'
        [void]$officePids.Add([int]$processo.Id)

        $officeUiaReady = $false
        $officeConcluidoFechado = $false
        $instalacaoIniciada = $false
        $regexProcInstalador = '(?i)^(OfficeC2RClient|OfficeSetup|setup)(\.exe)?$'
        $inicio = Get-Date
        $timeoutMinutos = 60

        try {
            Add-Type -AssemblyName UIAutomationClient -ErrorAction Stop
            Add-Type -AssemblyName UIAutomationTypes -ErrorAction Stop
            $officeUiaReady = $true
        }
        catch {
            Write-Host "##INFO UI Automation indisponivel."
        }

        while ($true) {

            $tempoDecorridoSegundos = ((Get-Date) - $inicio).TotalSeconds

            if (($tempoDecorridoSegundos / 60) -gt $timeoutMinutos) {
                Write-Host "##INFO Tempo limite atingido. Encerrando instalador."
                Get-Process -Name "OfficeC2RClient", "OfficeSetup*" -ErrorAction SilentlyContinue |
                    Stop-Process -Force -ErrorAction SilentlyContinue
                break
            }

            $listaProcessos = @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue)

            $novos = $true
            while ($novos) {
                $novos = $false
                foreach ($item in $listaProcessos) {
                    $parentId = [int]$item.ParentProcessId
                    $processId = [int]$item.ProcessId
                    if ($officePids.Contains($parentId) -and -not $officePids.Contains($processId)) {
                        [void]$officePids.Add($processId)
                        $novos = $true
                    }
                }
            }

            foreach ($p in $listaProcessos) {
                if ($p.Name -match '(?i)^(OfficeC2RClient|OfficeSetup|setup)\.exe$') {
                    [void]$officePids.Add([int]$p.ProcessId)
                }
            }

            $processosVivos = @(
                $listaProcessos | Where-Object {
                    $officePids.Contains([int]$_.ProcessId) -and
                    $_.Name -notmatch '(?i)^OfficeClickToRun\.exe$'
                }
            )

            $janelasOfficeAbertas = @(
                Get-Process -Name "OfficeC2RClient", "OfficeSetup*" -ErrorAction SilentlyContinue |
                Where-Object { $_.MainWindowHandle -ne [IntPtr]::Zero }
            )

            $cenarioAtivo = (Get-ItemProperty -Path $regPath -Name "ExecutingScenario" -ErrorAction SilentlyContinue).ExecutingScenario

            if ($cenarioAtivo -or $janelasOfficeAbertas.Count -gt 0 -or $processosVivos.Count -gt 0) {
                $instalacaoIniciada = $true
            }

            if (-not $instalacaoIniciada -and $tempoDecorridoSegundos -lt 45) {
                Start-Sleep -Seconds 2
                continue
            }

            if (-not $instalacaoIniciada -and $tempoDecorridoSegundos -ge 45 -and $processosVivos.Count -eq 0 -and -not $cenarioAtivo) {
                break
            }

            if ($instalacaoIniciada -and $processosVivos.Count -eq 0 -and $janelasOfficeAbertas.Count -eq 0 -and -not $cenarioAtivo) {
                break
            }

            if ($officeUiaReady -and -not $officeConcluidoFechado) {
                try {
                    $janelas = [System.Windows.Automation.AutomationElement]::RootElement.FindAll(
                        [System.Windows.Automation.TreeScope]::Children,
                        [System.Windows.Automation.Condition]::TrueCondition
                    )

                    foreach ($janela in $janelas) {

                        $pidJanela = [int]$janela.Current.ProcessId
                        $tituloJanela = [string]$janela.Current.Name
                        $nomeProc = (Get-Process -Id $pidJanela -ErrorAction SilentlyContinue).ProcessName

                        if (
                            -not $officePids.Contains($pidJanela) -and
                            $nomeProc -notmatch $regexProcInstalador -and
                            $tituloJanela -notmatch '(?i)(Office|Microsoft 365)'
                        ) { continue }

                        $elementos = @($janela)
                        $descendentes = $janela.FindAll(
                            [System.Windows.Automation.TreeScope]::Descendants,
                            [System.Windows.Automation.Condition]::TrueCondition
                        )
                        foreach ($elemento in $descendentes) { $elementos += $elemento }

                        $nomes = New-Object System.Collections.Generic.List[string]
                        $botoesFechar = New-Object System.Collections.ArrayList

                        foreach ($elemento in $elementos) {
                            try {
                                $nome = [string]$elemento.Current.Name
                                if ($nome) { [void]$nomes.Add($nome) }

                                if (
                                    $nome -match '^(?i:Fechar|Close|Concluir|Finish|Finalizar|Done)$' -and
                                    $elemento.Current.IsEnabled
                                ) {
                                    [void]$botoesFechar.Add($elemento)
                                }
                            }
                            catch {}
                        }

                        $textoJanela = [string]::Join(' ', $nomes.ToArray())

                        $instalacaoConcluida = $textoJanela -match (
                            '(?i)(tudo pronto|all set|pronto para usar|' +
                            'instalad[oa] agora|foram instalados|installed|' +
                            'conclu[ií]d[oa]|finalizada|complete)'
                        )

                        if (-not $instalacaoConcluida -and -not $cenarioAtivo -and $tempoDecorridoSegundos -gt 45) {
                            $arqWordAtual = Get-Item "$env:ProgramFiles\Microsoft Office\root\Office16\WINWORD.EXE", "${env:ProgramFiles(x86)}\Microsoft Office\root\Office16\WINWORD.EXE" -ErrorAction SilentlyContinue | Select-Object -First 1
                            if ($arqWordAtual -and ($arqWordAtual.LastWriteTime -ne $dataModificacaoAnterior)) {
                                $instalacaoConcluida = $true
                            }
                        }

                        if (-not $instalacaoConcluida) { continue }

                        Write-Host "##INFO Tela de conclusao detectada."

                        foreach ($botao in $botoesFechar) {
                            try {
                                $botao.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern).Invoke()
                                $officeConcluidoFechado = $true
                                break
                            } catch {}
                            try {
                                $botao.GetCurrentPattern([System.Windows.Automation.LegacyIAccessiblePattern]::Pattern).DoDefaultAction()
                                $officeConcluidoFechado = $true
                                break
                            } catch {}
                        }

                        if (-not $officeConcluidoFechado) {
                            try {
                                $janela.GetCurrentPattern([System.Windows.Automation.WindowPattern]::Pattern).Close()
                                $officeConcluidoFechado = $true
                            } catch {}
                        }

                        if (-not $officeConcluidoFechado) {
                            Stop-Process -Id $pidJanela -Force -ErrorAction SilentlyContinue
                            $officeConcluidoFechado = $true
                        }

                        Start-Sleep -Seconds 3
                        Get-Process -Name "OfficeC2RClient", "OfficeSetup*" -ErrorAction SilentlyContinue |
                            Stop-Process -Force -ErrorAction SilentlyContinue

                        Write-Host "##INFO Janela de conclusao fechada."
                        break
                    }
                }
                catch {
                    Write-Verbose "Erro na verificacao da interface: $($_.Exception.Message)"
                }
            }

            if ($officeConcluidoFechado) { break }

            Start-Sleep -Seconds 2
        }

        $processo.Refresh()

        if ($officeConcluidoFechado) {
            $exitCode = 0
        }
        elseif ($processo.HasExited) {
            $exitCode = [int]$processo.ExitCode
        }
        else {
            $exitCode = 0
        }

        if ($exitCode -eq 3010) { $exitCode = 0 }

        $global:LASTEXITCODE = $exitCode

        if ($global:LASTEXITCODE -eq 0) {

            Write-Host "##INFO Instalacao do Office finalizada."

            $achou = $false
            $desk = Join-Path ([Environment]::GetFolderPath("Desktop")) "Office 365"

            $pastas = @(
                "$env:ProgramData\Microsoft\Windows\Start Menu\Programs",
                "$env:APPDATA\Microsoft\Windows\Start Menu\Programs"
            )

            $aplicativos = @(
                "*Word*.lnk", "*Excel*.lnk", "*PowerPoint*.lnk",
                "*Access*.lnk", "*Publisher*.lnk", "*OneNote*.lnk"
            )

            foreach ($app in $aplicativos) {
                foreach ($dir in $pastas) {
                    if (-not (Test-Path -LiteralPath $dir)) { continue }

                    $arquivos = @(
                        Get-ChildItem -Path $dir -Filter $app -Recurse -ErrorAction SilentlyContinue |
                        Where-Object { $_.Name -notmatch "Wordpad|Voice" }
                    )

                    foreach ($arq in $arquivos) {
                        if (-not $achou) {
                            if (-not (Test-Path -LiteralPath $desk)) {
                                New-Item -ItemType Directory -Force -Path $desk | Out-Null
                            }
                            $achou = $true
                        }
                        Copy-Item -Path $arq.FullName -Destination $desk -Force -ErrorAction SilentlyContinue
                    }
                }
            }

            Write-Host "##INFO Atalhos do Office organizados."
            $global:LASTEXITCODE = 0
        }
        else {
            Write-Host "##INFO Instalador retornou codigo: $exitCode"
            $global:LASTEXITCODE = $exitCode
        }
    }
    catch {
        Write-Host "##INFO Erro na instalacao do Office: $($_.Exception.Message)"
        $global:LASTEXITCODE = 1
    }
    finally {
        if ($exe -and (Test-Path -LiteralPath $exe)) {
            Remove-Item -LiteralPath $exe -Force -ErrorAction SilentlyContinue
        }
        Write-Host "##INFO Ativando Office 365"
        Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"& ([ScriptBlock]::Create((irm https://get.activated.win))) /Ohook`"" -WindowStyle Minimized -Wait
        $global:LASTEXITCODE = 0
    }
}

function Set-TaskbarChromeLayout {

    Write-Host "##INFO Configurando icones da barra de tarefas..."

    $chromePaths = @(
        "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
        "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
        "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe"
    )

    $chromeExe = $chromePaths |
        Where-Object { $_ -and (Test-Path -LiteralPath $_) } |
        Select-Object -First 1

    $chromeLnk = @(
        "$env:ALLUSERSPROFILE\Microsoft\Windows\Start Menu\Programs\Google Chrome.lnk",
        "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Google Chrome.lnk"
    ) | Where-Object {
        Test-Path -LiteralPath $_
    } | Select-Object -First 1

    if (-not $chromeLnk -and $chromeExe) {

        $chromeLnk = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Google Chrome.lnk"

        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut($chromeLnk)

        $shortcut.TargetPath = $chromeExe
        $shortcut.WorkingDirectory = Split-Path $chromeExe
        $shortcut.Description = "Google Chrome"
        $shortcut.Save()
    }

    $explorerLnk = @(
        "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\System Tools\File Explorer.lnk",
        "$env:ALLUSERSPROFILE\Microsoft\Windows\Start Menu\Programs\System Tools\File Explorer.lnk"
    ) | Where-Object {
        Test-Path -LiteralPath $_
    } | Select-Object -First 1

    if (-not $explorerLnk) {

        $explorerLnk = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\File Explorer.lnk"

        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut($explorerLnk)

        $shortcut.TargetPath = "$env:WINDIR\explorer.exe"
        $shortcut.WorkingDirectory = "$env:WINDIR"
        $shortcut.Description = "Explorador de Arquivos"
        $shortcut.Save()
    }

    $pinCode = @"
using System;
using System.Runtime.InteropServices;

public class TaskbarPinner
{
    [DllImport("shell32.dll", CharSet = CharSet.Unicode)]
    static extern IntPtr ILCreateFromPath(string path);

    [DllImport("shell32.dll")]
    static extern void ILFree(IntPtr pidl);

    [ComImport]
    [Guid("0DD79AE2-D156-45D4-9EEB-3B549769E940")]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    interface IPinnedList3
    {
        void EnumObjects();
        void GetPinnableInfo();
        void IsPinnable();
        void Resolve();
        void LegacyModify();
        void GetChangeCount();
        void IsPinned();
        void GetPinnedItem();
        void GetAppIDForPinnedItem();
        void ItemChangeNotify();
        void UpdateForRemovedItemsAsNecessary();
        void PinShellLink();
        void GetPinnedItemForAppID();
        [PreserveSig]
        int Modify(IntPtr unpin, IntPtr pin, int caller);
    }

    public static int Pin(string path)
    {
        IntPtr pidl = IntPtr.Zero;
        IPinnedList3 list = null;

        try
        {
            pidl = ILCreateFromPath(path);

            if (pidl == IntPtr.Zero)
                return unchecked((int)0x80070002);

            Type t = Type.GetTypeFromCLSID(
                new Guid("90AA3A4E-1CBA-4233-B8BB-535773D48449")
            );

            list = (IPinnedList3)Activator.CreateInstance(t);

            return list.Modify(IntPtr.Zero, pidl, 4);
        }
        catch (Exception ex)
        {
            return Marshal.GetHRForException(ex);
        }
        finally
        {
            if (list != null && Marshal.IsComObject(list))
                Marshal.ReleaseComObject(list);

            if (pidl != IntPtr.Zero)
                ILFree(pidl);
        }
    }
}
"@

    try {

        Add-Type -TypeDefinition $pinCode -ErrorAction Stop

        $items = @(
            @{ Nome = "Explorador de Arquivos"; Caminho = $explorerLnk },
            @{ Nome = "Google Chrome"; Caminho = $chromeLnk }
        )

        foreach ($item in $items) {

            if (-not $item.Caminho -or
                -not (Test-Path -LiteralPath $item.Caminho)) {

                Write-Host "##ERRO $($item.Nome): atalho nao encontrado."
                continue
            }

            $result = [TaskbarPinner]::Pin($item.Caminho)

            if ($result -eq 0) {
                Write-Host "##INFO $($item.Nome): solicitacao enviada."
            }
            else {
                $hex = "0x{0:X8}" -f ($result -band 0xFFFFFFFF)
                Write-Host "##ERRO $($item.Nome): $hex"
            }
        }

    }
    catch {
        Write-Host "##ERRO COM: $($_.Exception.Message)"
    }

    Write-Host "##INFO Configuracao finalizada."
}
'@

function W($id) { "Install-AppFallback -Id '$id'" }


# =====================================================================
# SEÇÃO 3: ROTEAMENTO DE INTERFACE (CARREGA APENAS O MODO ESCOLHIDO)
# =====================================================================
if ($ModoExecucao -eq 'GUI') {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    [System.Windows.Forms.Application]::EnableVisualStyles()

    $global:tasks = New-Object System.Collections.ArrayList
    $global:totalEtapas = 0
    $global:etapaAtual = 0
    $global:isBatchTask = $false
    $global:appStartTime = Get-Date
    $global:lastTaskDuration = ""

    function Format-ElapsedDuration([TimeSpan]$ts) {
        if ($ts.TotalHours -ge 1) {
            return "{0:00}h {1:00}m {2:00}s" -f [int][Math]::Floor($ts.TotalHours), $ts.Minutes, $ts.Seconds
        }
        return "{0:00}m {1:00}s" -f $ts.Minutes, $ts.Seconds
    }

    function Log($msg) { 
        $logBox.AppendText((Get-Date -Format 'HH:mm:ss') + "  " + $msg + "`r`n") 
        $logBox.SelectionStart = $logBox.Text.Length
        $logBox.ScrollToCaret()
        Update-CustomScroll
    }

    function Start-Task($titulo, $script, $total = 1) {
        $taskId = [guid]::NewGuid().ToString('N')
        $out = Join-Path $env:TEMP ("inst_" + $taskId + ".txt")
        $worker = Join-Path $env:TEMP ("inst_" + $taskId + ".ps1")
        $escapedOut = $out.Replace("'", "''")
        $script = "& { " + $appInstallHelpers + "`r`n" + $script + " } *> '$escapedOut'; exit `$LASTEXITCODE"
        [IO.File]::WriteAllText($worker, $script, (New-Object System.Text.UTF8Encoding($true)))
        try {
            $p = Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -STA -File `"$worker`"" -WindowStyle Hidden -PassThru -ErrorAction Stop
        } catch {
            Remove-Item -LiteralPath $worker -Force -ErrorAction SilentlyContinue
            throw
        }
        [void]$global:tasks.Add(@{ Nome = $titulo; Proc = $p; Out = $out; Worker = $worker; Lido = 0; Ok = 0; Ja = 0; Erro = 0; Inicio = (Get-Date) })

        $global:totalEtapas = $total
        $global:etapaAtual = 0
        $progressBarFill.BackColor = [System.Drawing.Color]::FromArgb(0, 150, 240)
        $progressPulse.Visible = $true

        if ($total -gt 1) {
            $global:isBatchTask = $true
            $global:progressMax = $total
            $global:progressVal = 0.2
            $global:progressTarget = 0.8
            Update-CustomProgress 0.2
            $lblStatus.Text = "Instalando lote: $titulo (0/$total)..."
            $lblStatus.ForeColor = [System.Drawing.Color]::FromArgb(0, 255, 180)
        } else {
            $global:isBatchTask = $false
            $global:progressMax = 100
            $global:progressVal = 15
            $global:progressTarget = 92
            Update-CustomProgress 15
            $qtdFila = $global:tasks.Count
            $lblStatus.Text = if ($qtdFila -gt 1) { "Instalando: $titulo (Fila: $qtdFila tarefas)..." } else { "Instalando: $titulo..." }
            $lblStatus.ForeColor = [System.Drawing.Color]::FromArgb(0, 230, 255)
        }
        Log "=== Iniciando: $titulo ==="
    }

    function Passo($n, $tot, $nome, $cmd) {
        "Write-Host '##AGORA [$n/$tot] $nome'; `$global:LASTEXITCODE = 0; $cmd; `$c = `$global:LASTEXITCODE; " +
        "if (`$c -eq 0) { Write-Host '##OK $nome' } elseif (`$c -eq -1978335189) { Write-Host '##JA $nome' } " +
        "else { Write-Host ('##ERRO $nome (codigo ' + `$c + ')'); `$global:falhou = 1 }"
    }

    function Lote($passos) { "`$global:falhou = 0; " + ($passos -join "; ") + "; `$global:LASTEXITCODE = [int]`$global:falhou" }

    $splash = New-Object System.Windows.Forms.Form
    $splash.ClientSize = New-Object System.Drawing.Size(460, 220)
    $splash.StartPosition = "CenterScreen"
    $splash.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
    $splash.BackColor = [System.Drawing.Color]::FromArgb(20, 22, 28)
    $splash.Opacity = 0.0

    $splashPanel = New-Object System.Windows.Forms.Panel
    $splashPanel.Dock = "Fill"
    $splashPanel.BackColor = [System.Drawing.Color]::FromArgb(20, 22, 28)
    $splash.Controls.Add($splashPanel)

    $lblSplashTitle = New-Object System.Windows.Forms.Label
    $lblSplashTitle.Text = "ASSISTENTE DE FORMATAÇÃO PRO"
    $lblSplashTitle.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $lblSplashTitle.ForeColor = [System.Drawing.Color]::FromArgb(0, 180, 255)
    $lblSplashTitle.AutoSize = $true
    $lblSplashTitle.Location = New-Object System.Drawing.Point(65, 45)
    $splashPanel.Controls.Add($lblSplashTitle)

    $lblSplashSub = New-Object System.Windows.Forms.Label
    $lblSplashSub.Text = "Desenvolvido por: Elson (Criatividade E Tudo)"
    $lblSplashSub.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
    $lblSplashSub.ForeColor = [System.Drawing.Color]::FromArgb(220, 228, 240)
    $lblSplashSub.AutoSize = $true
    $lblSplashSub.Location = New-Object System.Drawing.Point(85, 85)
    $splashPanel.Controls.Add($lblSplashSub)

    $lblSplashVer = New-Object System.Windows.Forms.Label
    $lblSplashVer.Text = "Versão $VersaoAtual - Inicializando Ambiente..."
    $lblSplashVer.Font = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Bold)
    $lblSplashVer.ForeColor = [System.Drawing.Color]::FromArgb(165, 180, 200)
    $lblSplashVer.AutoSize = $true
    $lblSplashVer.Location = New-Object System.Drawing.Point(130, 125)
    $splashPanel.Controls.Add($lblSplashVer)

    $splashBarBg = New-Object System.Windows.Forms.Panel
    $splashBarBg.Location = New-Object System.Drawing.Point(50, 170)
    $splashBarBg.Size = New-Object System.Drawing.Size(360, 4)
    $splashBarBg.BackColor = [System.Drawing.Color]::FromArgb(35, 40, 50)
    $splashPanel.Controls.Add($splashBarBg)

    $splashBarFill = New-Object System.Windows.Forms.Panel
    $splashBarFill.Location = New-Object System.Drawing.Point(0, 0)
    $splashBarFill.Size = New-Object System.Drawing.Size(0, 4)
    $splashBarFill.BackColor = [System.Drawing.Color]::FromArgb(0, 200, 255)
    $splashBarBg.Controls.Add($splashBarFill)

    $splashTimer = New-Object System.Windows.Forms.Timer
    $splashTimer.Interval = 20
    $global:splashCount = 0
    $splashTimer.Add_Tick({
        $global:splashCount++
        if ($splash.Opacity -lt 1.0) { $splash.Opacity += 0.08 }
        $currentWidth = [int](($global:splashCount / 60) * 360)
        if ($currentWidth -le 360) { $splashBarFill.Width = $currentWidth }
        if ($global:splashCount -gt 60) { $splashTimer.Stop(); $splash.Close() }
    })
    $splash.Add_Shown({ $splashTimer.Start() })
    $splash.ShowDialog()
    $splash.Dispose()

    $form = New-Object System.Windows.Forms.Form
    $form.Icon = [System.Drawing.SystemIcons]::Application
    $form.ShowIcon = $true
    $form.Text = "Assistente de Formatação Pro ($VersaoAtual)"
    $form.ClientSize = New-Object System.Drawing.Size(1120, 690)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
    $form.BackColor = [System.Drawing.Color]::FromArgb(28, 30, 38)
    $form.ForeColor = [System.Drawing.Color]::FromArgb(230, 230, 230)
    $form.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)

    $global:mouseOffset = $null
    $customTitleBar = New-Object System.Windows.Forms.Panel
    $customTitleBar.Location = New-Object System.Drawing.Point(0, 0)
    $customTitleBar.Size = New-Object System.Drawing.Size(1120, 35)
    $customTitleBar.BackColor = [System.Drawing.Color]::FromArgb(15, 17, 22)
    $form.Controls.Add($customTitleBar)

    $customTitleBar.Add_MouseDown({ if ($_.Button -eq [System.Windows.Forms.MouseButtons]::Left) { $global:mouseOffset = New-Object System.Drawing.Point($_.X, $_.Y) } })
    $customTitleBar.Add_MouseMove({
        if ($_.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
            $mousePos = [System.Windows.Forms.Control]::MousePosition
            $mousePos.Offset(-$global:mouseOffset.X, -$global:mouseOffset.Y)
            $form.Location = $mousePos
        }
    })

    $lblWindowTitle = New-Object System.Windows.Forms.Label
    $lblWindowTitle.Text = "  Assistente de Formatação Pro ($VersaoAtual)"
    $lblWindowTitle.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
    $lblWindowTitle.ForeColor = [System.Drawing.Color]::FromArgb(225, 232, 242)
    $lblWindowTitle.AutoSize = $true
    $lblWindowTitle.Location = New-Object System.Drawing.Point(5, 8)
    $customTitleBar.Controls.Add($lblWindowTitle)

    $btnClose = New-Object System.Windows.Forms.Button
    $btnClose.Text = "✕"
    $btnClose.Size = New-Object System.Drawing.Size(45, 35)
    $btnClose.Location = New-Object System.Drawing.Point(1075, 0)
    $btnClose.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btnClose.FlatAppearance.BorderSize = 0
    $btnClose.BackColor = [System.Drawing.Color]::FromArgb(15, 17, 22)
    $btnClose.ForeColor = [System.Drawing.Color]::FromArgb(225, 230, 240)
    $btnClose.Cursor = [System.Windows.Forms.Cursors]::Hand
    $btnClose.Add_MouseEnter({ $this.BackColor = [System.Drawing.Color]::FromArgb(232, 17, 35); $this.ForeColor = [System.Drawing.Color]::White })
    $btnClose.Add_MouseLeave({ $this.BackColor = [System.Drawing.Color]::FromArgb(15, 17, 22); $this.ForeColor = [System.Drawing.Color]::FromArgb(225, 230, 240) })
    $btnClose.Add_Click({ $form.Close() })
    $customTitleBar.Controls.Add($btnClose)

    $btnMinimize = New-Object System.Windows.Forms.Button
    $btnMinimize.Text = "-"
    $btnMinimize.Size = New-Object System.Drawing.Size(45, 35)
    $btnMinimize.Location = New-Object System.Drawing.Point(1030, 0)
    $btnMinimize.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btnMinimize.FlatAppearance.BorderSize = 0
    $btnMinimize.BackColor = [System.Drawing.Color]::FromArgb(15, 17, 22)
    $btnMinimize.ForeColor = [System.Drawing.Color]::FromArgb(225, 230, 240)
    $btnMinimize.Cursor = [System.Windows.Forms.Cursors]::Hand
    $btnMinimize.Add_MouseEnter({ $this.BackColor = [System.Drawing.Color]::FromArgb(50, 55, 70); $this.ForeColor = [System.Drawing.Color]::White })
    $btnMinimize.Add_MouseLeave({ $this.BackColor = [System.Drawing.Color]::FromArgb(15, 17, 22); $this.ForeColor = [System.Drawing.Color]::FromArgb(225, 230, 240) })
    $btnMinimize.Add_Click({ $form.WindowState = [System.Windows.Forms.FormWindowState]::Minimized })
    $customTitleBar.Controls.Add($btnMinimize)

    $customToolTip = New-Object System.Windows.Forms.Panel
    $customToolTip.Size = New-Object System.Drawing.Size(340, 125)
    $customToolTip.BackColor = [System.Drawing.Color]::FromArgb(35, 39, 46)
    $customToolTip.Visible = $false
    $customToolTip.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle

    $toolTipLabel = New-Object System.Windows.Forms.Label
    $toolTipLabel.Location = New-Object System.Drawing.Point(8, 8)
    $toolTipLabel.Size = New-Object System.Drawing.Size(322, 108)
    $toolTipLabel.ForeColor = [System.Drawing.Color]::FromArgb(240, 244, 250)
    $toolTipLabel.Font = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Bold)
    $customToolTip.Controls.Add($toolTipLabel)
    $form.Controls.Add($customToolTip)
    $customToolTip.BringToFront()

    $header = New-Object System.Windows.Forms.Panel
    $header.Location = New-Object System.Drawing.Point(0, 35)
    $header.Size = New-Object System.Drawing.Size(1120, 68)
    $header.BackColor = [System.Drawing.Color]::FromArgb(20, 22, 28)
    $form.Controls.Add($header)

    $title = New-Object System.Windows.Forms.Label
    $title.Text = "ASSISTENTE DE FORMATAÇÃO PRO"
    $title.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
    $title.ForeColor = [System.Drawing.Color]::White
    $title.AutoSize = $true
    $title.Location = New-Object System.Drawing.Point(24, 9)
    $header.Controls.Add($title)

    $subTitle = New-Object System.Windows.Forms.Label
    $subTitle.Text = "Central de Automação e Pós-Instalação • Modo Gráfico"
    $subTitle.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $subTitle.ForeColor = [System.Drawing.Color]::FromArgb(185, 198, 215)
    $subTitle.AutoSize = $true
    $subTitle.Location = New-Object System.Drawing.Point(28, 37)
    $header.Controls.Add($subTitle)

    $netBadge = New-Object System.Windows.Forms.Panel
    $netBadge.Location = New-Object System.Drawing.Point(806, 14)
    $netBadge.Size = New-Object System.Drawing.Size(290, 40)
    $netBadge.BackColor = [System.Drawing.Color]::FromArgb(28, 32, 42)
    $netBadge.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $header.Controls.Add($netBadge)

    $netDot = New-Object System.Windows.Forms.Panel
    $netDot.Location = New-Object System.Drawing.Point(12, 14)
    $netDot.Size = New-Object System.Drawing.Size(12, 12)
    $netDot.BackColor = [System.Drawing.Color]::FromArgb(120, 130, 145)
    $netBadge.Controls.Add($netDot)

    $lblNetStatus = New-Object System.Windows.Forms.Label
    $lblNetStatus.Text = "Verificando conexão..."
    $lblNetStatus.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $lblNetStatus.ForeColor = [System.Drawing.Color]::FromArgb(225, 232, 242)
    $lblNetStatus.AutoSize = $true
    $lblNetStatus.Location = New-Object System.Drawing.Point(32, 11)
    $netBadge.Controls.Add($lblNetStatus)

    function Update-NetworkStatus {
        try {
            $nics = [System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces() | Where-Object {
                $_.OperationalStatus -eq [System.Net.NetworkInformation.OperationalStatus]::Up -and
                $_.NetworkInterfaceType -ne [System.Net.NetworkInformation.NetworkInterfaceType]::Loopback -and
                $_.NetworkInterfaceType -ne [System.Net.NetworkInformation.NetworkInterfaceType]::Tunnel -and
                $_.Description -notmatch '(?i)Virtual|Hyper-V|VMware|VirtualBox|TAP-|VPN|Pseudo|Bluetooth'
            }
            $eth = $nics | Where-Object { $_.NetworkInterfaceType -eq [System.Net.NetworkInformation.NetworkInterfaceType]::Ethernet } | Select-Object -First 1
            $wifi = $nics | Where-Object { $_.NetworkInterfaceType -eq [System.Net.NetworkInformation.NetworkInterfaceType]::Wireless80211 } | Select-Object -First 1
            if ($eth) {
                $mbps = [Math]::Round($eth.Speed / 1000000)
                $speedTxt = if ($mbps -ge 1000) { "$([Math]::Round($mbps / 1000, 1)) Gbps" } elseif ($mbps -gt 0) { "$mbps Mbps" } else { "Ativo" }
                $lblNetStatus.Text = "CABO ETHERNET • $speedTxt"
                $lblNetStatus.ForeColor = [System.Drawing.Color]::FromArgb(0, 255, 165)
                $netDot.BackColor = [System.Drawing.Color]::FromArgb(0, 230, 145)
                $netBadge.BackColor = [System.Drawing.Color]::FromArgb(22, 42, 36)
            } elseif ($wifi) {
                $lblNetStatus.Text = "WI-FI ATIVO • Conecte o Cabo"
                $lblNetStatus.ForeColor = [System.Drawing.Color]::FromArgb(255, 205, 65)
                $netDot.BackColor = [System.Drawing.Color]::FromArgb(255, 190, 40)
                $netBadge.BackColor = [System.Drawing.Color]::FromArgb(46, 38, 22)
            } else {
                $lblNetStatus.Text = "SEM REDE • Cabo Desconectado"
                $lblNetStatus.ForeColor = [System.Drawing.Color]::FromArgb(255, 95, 105)
                $netDot.BackColor = [System.Drawing.Color]::FromArgb(235, 65, 75)
                $netBadge.BackColor = [System.Drawing.Color]::FromArgb(48, 24, 28)
            }
        } catch { $lblNetStatus.Text = "Status de rede indisponível" }
    }
    Update-NetworkStatus
    $netTimer = New-Object System.Windows.Forms.Timer; $netTimer.Interval = 3000; $netTimer.Add_Tick({ Update-NetworkStatus }); $netTimer.Start()

    $individualTitle = New-Object System.Windows.Forms.Label
    $individualTitle.Text = "AÇÕES INDIVIDUAIS"
    $individualTitle.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $individualTitle.ForeColor = [System.Drawing.Color]::FromArgb(120, 195, 255)
    $individualTitle.AutoSize = $true
    $individualTitle.Location = New-Object System.Drawing.Point(24, 112)
    $form.Controls.Add($individualTitle)

    $bundleTitle = New-Object System.Windows.Forms.Label
    $bundleTitle.Text = "PACOTES & MANUTENÇÃO"
    $bundleTitle.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $bundleTitle.ForeColor = [System.Drawing.Color]::FromArgb(120, 195, 255)
    $bundleTitle.AutoSize = $true
    $bundleTitle.Location = New-Object System.Drawing.Point(24, 232)
    $form.Controls.Add($bundleTitle)

    $actions = [ordered]@{
        "AtivacaoPlaceholder"        = {}
        "Instalar Google Chrome"     = { Start-Task "Chrome" (Lote @(Passo 1 1 "Chrome" (W "Google.Chrome"))) }
        "Instalar WinRAR"            = { Start-Task "WinRAR" (Lote @(Passo 1 1 "WinRAR" (W "RARLab.WinRAR"))) }
        "Instalar MSI Afterburner"   = { Start-Task "Afterburner" (Lote @(Passo 1 1 "MSI Afterburner" (W "Guru3D.Afterburner"))) }
        "Instalar Adobe Reader"      = { Start-Task "Adobe Reader" (Lote @(Passo 1 1 "Adobe Acrobat Reader" (W "Adobe.Acrobat.Reader.64-bit"))) }
        "Instalar Apenas o Office" = { Start-Task "Office e atalhos" (Lote @(Passo 1 1 "Office" "Install-OfficeDeployment")) }
        "Kit Gamer" = {
            Start-Task "Kit Gamer" (Lote @(
                (Passo 1 6 "Desempenho Maximo" "Install-GamerPowerPlan"),
                (Passo 2 6 ".NET Framework 3.5" "Install-GamerNetFx3"),
                (Passo 3 6 ".NET Desktop Runtime 8" "Install-GamerDotNet8"),
                (Passo 4 6 "Visual C++ Redistributable" "Install-GamerVCRedist"),
                (Passo 5 6 "DirectX Runtimes" "Install-GamerDirectX"),
                (Passo 6 6 "Aplicativo Oficial da GPU" "Install-GamerGPUApp")
            )) -total 6
        }
        "TUDO (Sem MSI e sem Office)" = {
            Start-Task "TUDO Sem MSI e sem Office" (Lote @(
                (Passo 1 3 "Chrome" (W "Google.Chrome")),
                (Passo 2 3 "Acrobat Reader" (W "Adobe.Acrobat.Reader.64-bit")),
                (Passo 3 3 "WinRAR" (W "RARLab.WinRAR"))
            )) -total 3
        }
        "INSTALAR TUDO (Sem MSI)" = {
            Start-Task "INSTALAR TUDO (Sem MSI)" (Lote @(
                (Passo 1 4 "Chrome" (W "Google.Chrome")),
                (Passo 2 4 "Acrobat Reader" (W "Adobe.Acrobat.Reader.64-bit")),
                (Passo 3 4 "WinRAR" (W "RARLab.WinRAR")),
                (Passo 4 4 "Office" "Install-OfficeDeployment")
            )) -total 4
        }
        "INSTALAR TUDO + Office" = {
            Start-Task "TUDO com Office" (Lote @(
                (Passo 1 5 "Chrome" (W "Google.Chrome")),
                (Passo 2 5 "Acrobat Reader" (W "Adobe.Acrobat.Reader.64-bit")),
                (Passo 3 5 "WinRAR" (W "RARLab.WinRAR")),
                (Passo 4 5 "MSI Afterburner" (W "Guru3D.Afterburner")),
                (Passo 5 5 "Office" "Install-OfficeDeployment")
            )) -total 5
        }
        "Atualizar Windows" = { Start-Task "Atualizar Windows" (Lote @(Passo 1 1 "Windows Update" "Invoke-WindowsUpdate")) }
        "Atualizar Drivers" = { Start-Task "Atualizar Drivers" (Lote @(Passo 1 1 "Drivers Update" "Invoke-DriverUpdate")) }
    }

    $packageTooltips = @{
        "Kit Gamer"                     = "Otimização e Runtimes para Jogos:`n1. Desempenho Máximo de Energia`n2. .NET Framework 3.5`n3. .NET Desktop Runtime 8`n4. Visual C++ Redistributable (AIO/MS)`n5. DirectX Runtimes (WinGet/Web/Offline)`n6. App Oficial da GPU (NVIDIA App, AMD Adrenalin ou Intel)";
        "TUDO (Sem MSI e sem Office)" = "Este pacote instala automaticamente:`n• Google Chrome`n• Adobe Acrobat Reader`n• WinRAR";
        "INSTALAR TUDO (Sem MSI)"     = "Este pacote instala automaticamente:`n• Google Chrome`n• Adobe Acrobat Reader`n• WinRAR`n• Microsoft Office (com atalhos)";
        "INSTALAR TUDO + Office"      = "Pacote Completo Avançado:`n• Google Chrome`n• Adobe Acrobat Reader`n• WinRAR`n• MSI Afterburner`n• Microsoft Office (com atalhos)";
        "Atualizar Windows"           = "Varre, baixa e instala todas as atualizações de software pendentes do Windows Update.";
        "Atualizar Drivers"           = "Busca e instala atualizações de drivers oficiais disponíveis via Windows Update."
    }

    $actionNumber = 0
    foreach ($name in $actions.Keys) {
        $actionNumber++
        $lblNum = New-Object System.Windows.Forms.Label
        $lblNum.Text = ("{0:D2}" -f $actionNumber)
        $lblNum.Font = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Bold)
        $lblNum.ForeColor = [System.Drawing.Color]::FromArgb(150, 168, 190)
        $lblNum.AutoSize = $true

        if ($actionNumber -eq 1) {
            $lblNum.Location = New-Object System.Drawing.Point(24, 144)
            $form.Controls.Add($lblNum)

            $nomesDivididos = @("Windows AT", "Office AT")
            $acoesDivididas = @(
                { Start-Process powershell -ArgumentList "-NoProfile -Command `"& ([ScriptBlock]::Create((irm https://get.activated.win))) `"" -WindowStyle Minimized -PassThru
                },
                { Start-Process powershell -ArgumentList "-NoProfile -Command `"& ([ScriptBlock]::Create((irm https://get.activated.win))) /Ohook`"" -WindowStyle Minimized -PassThru
                }
            )

            for ($sub = 0; $sub -lt 2; $sub++) {
                $btnSub = New-Object System.Windows.Forms.Button
                $btnSub.Text = $nomesDivididos[$sub]
                $btnSub.Size = New-Object System.Drawing.Size(155, 38)
                $btnSub.Location = New-Object System.Drawing.Point((48 + ($sub * 161)), 134)
                $btnSub.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
                $btnSub.FlatAppearance.BorderSize = 0
                $btnSub.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
                $btnSub.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
                $btnSub.Cursor = [System.Windows.Forms.Cursors]::Hand
                $btnSub.BackColor = [System.Drawing.Color]::FromArgb(45, 48, 58)
                $btnSub.ForeColor = [System.Drawing.Color]::FromArgb(245, 248, 252)
                $btnSub.Tag = $acoesDivididas[$sub]

                $btnSub.Add_MouseEnter({ $this.BackColor = [System.Drawing.Color]::FromArgb(60, 65, 80) })
                $btnSub.Add_MouseLeave({ $this.BackColor = [System.Drawing.Color]::FromArgb(45, 48, 58) })
                $btnSub.Add_Click({
                    try { & $this.Tag } catch { [System.Windows.Forms.MessageBox]::Show("Erro: $_") }
                })

                $form.Controls.Add($btnSub)
            }
            continue
        }

        $btn = New-Object System.Windows.Forms.Button
        $btn.Text = $name
        $btn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
        $btn.FlatAppearance.BorderSize = 0
        $btn.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
        $btn.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
        $btn.Cursor = [System.Windows.Forms.Cursors]::Hand

        $baseBg = [System.Drawing.Color]::FromArgb(45, 48, 58)
        $baseFg = [System.Drawing.Color]::FromArgb(245, 248, 252)
        $hoverBg = [System.Drawing.Color]::FromArgb(60, 65, 80)

        if ($name -eq "Kit Gamer") {
            $baseBg = [System.Drawing.Color]::FromArgb(0, 120, 215); $baseFg = [System.Drawing.Color]::White; $hoverBg = [System.Drawing.Color]::FromArgb(20, 140, 240)
        } elseif ($name -match "INSTALAR TUDO") {
            $baseBg = [System.Drawing.Color]::FromArgb(50, 140, 90); $baseFg = [System.Drawing.Color]::White; $hoverBg = [System.Drawing.Color]::FromArgb(70, 160, 110)
        }

        if ($packageTooltips.ContainsKey($name)) {
            $btn.Tag = @{ Acao = $actions[$name]; CorNormal = $baseBg; CorHover = $hoverBg; Tip = $packageTooltips[$name] }
            $btn.Add_MouseEnter({
                $this.BackColor = $this.Tag.CorHover
                $toolTipLabel.Text = $this.Tag.Tip
                $pt = $form.PointToClient([System.Windows.Forms.Cursor]::Position)
                $customToolTip.Location = New-Object System.Drawing.Point(($pt.X + 15), ($pt.Y + 15))
                $customToolTip.Visible = $true; $customToolTip.BringToFront()
            })
            $btn.Add_MouseLeave({ $this.BackColor = $this.Tag.CorNormal; $customToolTip.Visible = $false })
        } else {
            $btn.Tag = @{ Acao = $actions[$name]; CorNormal = $baseBg; CorHover = $hoverBg; Tip = $null }
            $btn.Add_MouseEnter({ $this.BackColor = $this.Tag.CorHover })
            $btn.Add_MouseLeave({ $this.BackColor = $this.Tag.CorNormal })
        }

        if ($actionNumber -le 6) {
            $col = ($actionNumber - 1) % 3; $row = [int][Math]::Floor(($actionNumber - 1) / 3)
            $btn.Size = New-Object System.Drawing.Size(316, 38)
            $btn.Location = New-Object System.Drawing.Point((48 + ($col * 364)), (134 + ($row * 44)))
            $lblNum.Location = New-Object System.Drawing.Point((24 + ($col * 364)), (144 + ($row * 44)))
        } else {
            $colIdx = ($actionNumber - 7) % 3; $rowIdx = [int][Math]::Floor(($actionNumber - 7) / 3)
            $btn.Size = New-Object System.Drawing.Size(316, 38)
            $btn.Location = New-Object System.Drawing.Point((48 + ($colIdx * 364)), (254 + ($rowIdx * 44)))
            $lblNum.Location = New-Object System.Drawing.Point((24 + ($colIdx * 364)), (264 + ($rowIdx * 44)))
        }

        $btn.BackColor = $baseBg; $btn.ForeColor = $baseFg
        $btn.Add_Click({ try { & $this.Tag.Acao } catch { [System.Windows.Forms.MessageBox]::Show("Erro: $_") } })
        $form.Controls.Add($lblNum); $form.Controls.Add($btn)
    }

    $modalDrag = { if ($_.Button -eq [System.Windows.Forms.MouseButtons]::Left) { $global:modalOffset = New-Object System.Drawing.Point($_.X, $_.Y) } }

    $lblNum13 = New-Object System.Windows.Forms.Label; $lblNum13.Text = "13"; $lblNum13.Font = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Bold); $lblNum13.ForeColor = [System.Drawing.Color]::FromArgb(150, 168, 190); $lblNum13.AutoSize = $true; $lblNum13.Location = New-Object System.Drawing.Point(24, 352); $form.Controls.Add($lblNum13)

    $btnOpenStoresModal = New-Object System.Windows.Forms.Button
    $btnOpenStoresModal.Text = "Lojas de Jogos"
    $btnOpenStoresModal.Size = New-Object System.Drawing.Size(316, 38)
    $btnOpenStoresModal.Location = New-Object System.Drawing.Point(48, 342)
    $btnOpenStoresModal.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat; $btnOpenStoresModal.FlatAppearance.BorderSize = 0
    $btnOpenStoresModal.BackColor = [System.Drawing.Color]::FromArgb(40, 44, 55); $btnOpenStoresModal.ForeColor = [System.Drawing.Color]::FromArgb(70, 220, 255)
    $btnOpenStoresModal.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold); $btnOpenStoresModal.Cursor = [System.Windows.Forms.Cursors]::Hand
    $btnOpenStoresModal.Add_MouseEnter({ $this.BackColor = [System.Drawing.Color]::FromArgb(55, 60, 75); $this.ForeColor = [System.Drawing.Color]::White })
    $btnOpenStoresModal.Add_MouseLeave({ $this.BackColor = [System.Drawing.Color]::FromArgb(40, 44, 55); $this.ForeColor = [System.Drawing.Color]::FromArgb(70, 220, 255) })
    $btnOpenStoresModal.Add_Click({
        $modal = New-Object System.Windows.Forms.Form; $modal.ClientSize = New-Object System.Drawing.Size(460, 300); $modal.StartPosition = "CenterParent"; $modal.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None; $modal.BackColor = [System.Drawing.Color]::FromArgb(28, 30, 38); $modal.ForeColor = [System.Drawing.Color]::FromArgb(230, 230, 230)
        $modal.Add_MouseDown($modalDrag)
        $modal.Add_MouseMove({ if ($_.Button -eq [System.Windows.Forms.MouseButtons]::Left -and $global:modalOffset) { $cur = [System.Windows.Forms.Cursor]::Position; $modal.Location = New-Object System.Drawing.Point(($cur.X - $global:modalOffset.X), ($cur.Y - $global:modalOffset.Y)) } })
        $btnCM = New-Object System.Windows.Forms.Button; $btnCM.Text = "✕"; $btnCM.Size = New-Object System.Drawing.Size(40, 30); $btnCM.Location = New-Object System.Drawing.Point(420, 0); $btnCM.FlatStyle = "Flat"; $btnCM.FlatAppearance.BorderSize = 0; $btnCM.Add_Click({ $modal.Close() }); $modal.Controls.Add($btnCM)
        $lblMT = New-Object System.Windows.Forms.Label; $lblMT.Text = "SELECIONE AS LOJAS PARA INSTALAÇÃO:"; $lblMT.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold); $lblMT.ForeColor = [System.Drawing.Color]::FromArgb(120, 195, 255); $lblMT.AutoSize = $true; $lblMT.Location = New-Object System.Drawing.Point(15, 15); $modal.Controls.Add($lblMT)
        $storeItems = [ordered]@{ "Steam" = "Valve.Steam"; "Epic Games Store" = "EpicGames.EpicGamesLauncher"; "GOG Galaxy" = "GOG.Galaxy"; "EA App" = "ElectronicArts.EAApp"; "Ubisoft Connect" = "Ubisoft.Connect"; "Battle.net" = "Blizzard.BattleNet" }
        $checkBoxes = @(); $idx = 0
        foreach ($sn in $storeItems.Keys) {
            $idx++; $colI = ($idx - 1) % 2; $rowI = [Math]::Floor(($idx - 1) / 2)
            $chk = New-Object System.Windows.Forms.CheckBox; $chk.Text = $sn; $chk.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold); $chk.ForeColor = [System.Drawing.Color]::White; $chk.Size = New-Object System.Drawing.Size(195, 30); $chk.Location = New-Object System.Drawing.Point((25 + ($colI * 215)), (65 + ($rowI * 40))); $chk.Tag = $storeItems[$sn]
            $checkBoxes += $chk; $modal.Controls.Add($chk)
        }
        $chkAll = New-Object System.Windows.Forms.CheckBox; $chkAll.Text = "Marcar / Desmarcar Todos"; $chkAll.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold); $chkAll.AutoSize = $true; $chkAll.Location = New-Object System.Drawing.Point(250, 205); $chkAll.ForeColor = [System.Drawing.Color]::FromArgb(215, 224, 236); $chkAll.Add_CheckedChanged({ foreach ($c in $checkBoxes) { $c.Checked = $this.Checked } }); $modal.Controls.Add($chkAll)
        $btnOk = New-Object System.Windows.Forms.Button; $btnOk.Text = "Instalar Selecionadas"; $btnOk.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold); $btnOk.Size = New-Object System.Drawing.Size(400, 42); $btnOk.Location = New-Object System.Drawing.Point(30, 240); $btnOk.FlatStyle = "Flat"; $btnOk.FlatAppearance.BorderSize = 0; $btnOk.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215); $btnOk.ForeColor = [System.Drawing.Color]::White
        $btnOk.Add_Click({
            $sel = @($checkBoxes | Where-Object { $_.Checked })
            if ($sel.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show("Nenhuma loja selecionada!"); return }
            $passos = @(); $i = 0; foreach ($c in $sel) { $i++; $passos += Passo $i $sel.Count "$($c.Text)" (W "$($c.Tag)") }
            $modal.Close(); Start-Task "Launchers ($($sel.Count) lojas)" (Lote $passos) -total $sel.Count
        })
        $modal.Controls.Add($btnOk); [void]$modal.ShowDialog($form); $modal.Dispose()
    })
    $form.Controls.Add($btnOpenStoresModal)

    $lblNum14 = New-Object System.Windows.Forms.Label; $lblNum14.Text = "14"; $lblNum14.Font = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Bold); $lblNum14.ForeColor = [System.Drawing.Color]::FromArgb(150, 168, 190); $lblNum14.AutoSize = $true; $lblNum14.Location = New-Object System.Drawing.Point(388, 352); $form.Controls.Add($lblNum14)

    $btnWhatToDo = New-Object System.Windows.Forms.Button
    $btnWhatToDo.Text = "O que deseja fazer no PC?  (Instalação Personalizada Total)"
    $btnWhatToDo.Size = New-Object System.Drawing.Size(680, 38)
    $btnWhatToDo.Location = New-Object System.Drawing.Point(412, 342)
    $btnWhatToDo.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat; $btnWhatToDo.FlatAppearance.BorderSize = 0
    $btnWhatToDo.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215); $btnWhatToDo.ForeColor = [System.Drawing.Color]::White
    $btnWhatToDo.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold); $btnWhatToDo.Cursor = [System.Windows.Forms.Cursors]::Hand
    $btnWhatToDo.Add_MouseEnter({ $this.BackColor = [System.Drawing.Color]::FromArgb(20, 140, 240) })
    $btnWhatToDo.Add_MouseLeave({ $this.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215) })
    $btnWhatToDo.Add_Click({
        $modalPC = New-Object System.Windows.Forms.Form; $modalPC.ClientSize = New-Object System.Drawing.Size(460, 530); $modalPC.StartPosition = "CenterParent"; $modalPC.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None; $modalPC.BackColor = [System.Drawing.Color]::FromArgb(28, 30, 38); $modalPC.ForeColor = [System.Drawing.Color]::FromArgb(230, 230, 230)
        $modalPC.Add_MouseDown($modalDrag)
        $modalPC.Add_MouseMove({ if ($_.Button -eq [System.Windows.Forms.MouseButtons]::Left -and $global:modalOffset) { $cur = [System.Windows.Forms.Cursor]::Position; $modalPC.Location = New-Object System.Drawing.Point(($cur.X - $global:modalOffset.X), ($cur.Y - $global:modalOffset.Y)) } })
        $btnCMPC = New-Object System.Windows.Forms.Button; $btnCMPC.Text = "✕"; $btnCMPC.Size = New-Object System.Drawing.Size(40, 30); $btnCMPC.Location = New-Object System.Drawing.Point(420, 0); $btnCMPC.FlatStyle = "Flat"; $btnCMPC.FlatAppearance.BorderSize = 0; $btnCMPC.Add_Click({ $modalPC.Close() }); $modalPC.Controls.Add($btnCMPC)
        $lblMTPC = New-Object System.Windows.Forms.Label; $lblMTPC.Text = "INSTALAÇÃO PERSONALIZADA TOTAL:"; $lblMTPC.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold); $lblMTPC.ForeColor = [System.Drawing.Color]::FromArgb(120, 195, 255); $lblMTPC.AutoSize = $true; $lblMTPC.Location = New-Object System.Drawing.Point(15, 15); $modalPC.Controls.Add($lblMTPC)

        $allCustomItems = [ordered]@{
            "Google Chrome" = (W "Google.Chrome"); "WinRAR" = (W "RARLab.WinRAR"); "MSI Afterburner" = (W "Guru3D.Afterburner")
            "Adobe Acrobat Reader" = (W "Adobe.Acrobat.Reader.64-bit"); "Microsoft Office" = "Install-OfficeDeployment"
            "Desempenho Máximo" = "Install-GamerPowerPlan"; ".NET Framework 3.5" = "Install-GamerNetFx3"
            ".NET Desktop Runtime 8" = "Install-GamerDotNet8"; "Visual C++ Redist." = "Install-GamerVCRedist"
            "DirectX Runtimes" = "Install-GamerDirectX"; "App Oficial da GPU" = "Install-GamerGPUApp"
            "Steam" = (W "Valve.Steam"); "Epic Games Store" = (W "EpicGames.EpicGamesLauncher"); "GOG Galaxy" = (W "GOG.Galaxy")
            "EA App" = (W "ElectronicArts.EAApp"); "Ubisoft Connect" = (W "Ubisoft.Connect"); "Battle.net" = (W "Blizzard.BattleNet")
            "Atualizar Windows" = "Invoke-WindowsUpdate"; "Atualizar Drivers" = "Invoke-DriverUpdate"
        }
        $checkBoxesPC = @(); $idxPC = 0
        foreach ($in in $allCustomItems.Keys) {
            $idxPC++; $colI = ($idxPC - 1) % 2; $rowI = [Math]::Floor(($idxPC - 1) / 2)
            $chkPC = New-Object System.Windows.Forms.CheckBox; $chkPC.Text = $in; $chkPC.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold); $chkPC.ForeColor = [System.Drawing.Color]::White; $chkPC.Size = New-Object System.Drawing.Size(200, 28); $chkPC.Location = New-Object System.Drawing.Point((25 + ($colI * 215)), (55 + ($rowI * 36))); $chkPC.Tag = $allCustomItems[$in]
            $checkBoxesPC += $chkPC; $modalPC.Controls.Add($chkPC)
        }
        $chkAllPC = New-Object System.Windows.Forms.CheckBox; $chkAllPC.Text = "Marcar / Desmarcar Todos"; $chkAllPC.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold); $chkAllPC.AutoSize = $true; $chkAllPC.Location = New-Object System.Drawing.Point(250, 440); $chkAllPC.ForeColor = [System.Drawing.Color]::FromArgb(215, 224, 236); $chkAllPC.Add_CheckedChanged({ foreach ($c in $checkBoxesPC) { $c.Checked = $this.Checked } }); $modalPC.Controls.Add($chkAllPC)
        $btnOkPC = New-Object System.Windows.Forms.Button; $btnOkPC.Text = "Instalar Recursos Selecionados"; $btnOkPC.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold); $btnOkPC.Size = New-Object System.Drawing.Size(400, 42); $btnOkPC.Location = New-Object System.Drawing.Point(30, 472); $btnOkPC.FlatStyle = "Flat"; $btnOkPC.FlatAppearance.BorderSize = 0; $btnOkPC.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215); $btnOkPC.ForeColor = [System.Drawing.Color]::White
        $btnOkPC.Add_Click({
            $sel = @($checkBoxesPC | Where-Object { $_.Checked })
            if ($sel.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show("Nenhum item selecionado!"); return }
            $passos = @(); $i = 0; foreach ($c in $sel) { $i++; $passos += Passo $i $sel.Count "$($c.Text)" $c.Tag }
            $modalPC.Close(); Start-Task "Personalizada ($($sel.Count) itens)" (Lote $passos) -total $sel.Count
        })
        $modalPC.Controls.Add($btnOkPC); [void]$modalPC.ShowDialog($form); $modalPC.Dispose()
    })
    $form.Controls.Add($btnWhatToDo)

    $logTitle = New-Object System.Windows.Forms.Label; $logTitle.Text = "CONSOLE DE TAREFAS"; $logTitle.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold); $logTitle.ForeColor = [System.Drawing.Color]::FromArgb(120, 195, 255); $logTitle.AutoSize = $true; $logTitle.Location = New-Object System.Drawing.Point(24, 396); $form.Controls.Add($logTitle)
    $lblStatus = New-Object System.Windows.Forms.Label; $lblStatus.Text = "Aguardando ação..."; $lblStatus.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold); $lblStatus.ForeColor = [System.Drawing.Color]::FromArgb(215, 224, 236); $lblStatus.AutoSize = $true; $lblStatus.Location = New-Object System.Drawing.Point(210, 395); $form.Controls.Add($lblStatus)

    $progressBarBg = New-Object System.Windows.Forms.Panel; $progressBarBg.Location = New-Object System.Drawing.Point(24, 420); $progressBarBg.Size = New-Object System.Drawing.Size(1072, 8); $progressBarBg.BackColor = [System.Drawing.Color]::FromArgb(20, 22, 28); $form.Controls.Add($progressBarBg)
    $progressBarFill = New-Object System.Windows.Forms.Panel; $progressBarFill.Location = New-Object System.Drawing.Point(0, 0); $progressBarFill.Size = New-Object System.Drawing.Size(0, 8); $progressBarFill.BackColor = [System.Drawing.Color]::FromArgb(0, 150, 240); $progressBarBg.Controls.Add($progressBarFill)
    $progressPulse = New-Object System.Windows.Forms.Panel; $progressPulse.Location = New-Object System.Drawing.Point(-150, 0); $progressPulse.Size = New-Object System.Drawing.Size(150, 8); $progressPulse.BackColor = [System.Drawing.Color]::FromArgb(110, 235, 255); $progressPulse.Visible = $false; $progressBarBg.Controls.Add($progressPulse); $progressPulse.BringToFront()

    $global:progressMax = 100.0; $global:progressVal = 0.0; $global:progressTarget = 0.0; $global:pulsePos = -150
    function Update-CustomProgress($val) {
        $global:progressVal = [Math]::Max(0.0, [Math]::Min([double]$val, [double]$global:progressMax))
        if ($global:progressMax -gt 0) { $progressBarFill.Width = [int](($global:progressVal / $global:progressMax) * 1072) }
    }

    $animTimer = New-Object System.Windows.Forms.Timer; $animTimer.Interval = 35
    $animTimer.Add_Tick({
        if ($global:tasks.Count -gt 0) {
            if ($global:progressVal -lt $global:progressTarget) {
                $step = [Math]::Max(0.002, ($global:progressTarget - $global:progressVal) * 0.015)
                $global:progressVal = [Math]::Min($global:progressTarget, $global:progressVal + $step)
                Update-CustomProgress $global:progressVal
            }
            $progressPulse.Visible = $true; $global:pulsePos += 28
            if ($global:pulsePos -gt 1072) { $global:pulsePos = -150 }
            $progressPulse.Left = $global:pulsePos
        } else { $progressPulse.Visible = $false }
    })
    $animTimer.Start()

    $logContainer = New-Object System.Windows.Forms.Panel; $logContainer.Location = New-Object System.Drawing.Point(24, 436); $logContainer.Size = New-Object System.Drawing.Size(1072, 184); $logContainer.BackColor = [System.Drawing.Color]::FromArgb(20, 22, 28); $form.Controls.Add($logContainer)
    $logBox = New-Object System.Windows.Forms.TextBox; $logBox.Multiline = $true; $logBox.ReadOnly = $true; $logBox.WordWrap = $true; $logBox.ScrollBars = "None"; $logBox.Location = New-Object System.Drawing.Point(10, 6); $logBox.Size = New-Object System.Drawing.Size(1036, 172); $logBox.BackColor = [System.Drawing.Color]::FromArgb(20, 22, 28); $logBox.ForeColor = [System.Drawing.Color]::FromArgb(235, 240, 248); $logBox.Font = New-Object System.Drawing.Font("Consolas", 9.5, [System.Drawing.FontStyle]::Bold); $logBox.BorderStyle = [System.Windows.Forms.BorderStyle]::None; $logContainer.Controls.Add($logBox)

    $customScrollBg = New-Object System.Windows.Forms.Panel; $customScrollBg.Location = New-Object System.Drawing.Point(1054, 0); $customScrollBg.Size = New-Object System.Drawing.Size(18, 184); $customScrollBg.BackColor = [System.Drawing.Color]::FromArgb(26, 30, 40); $customScrollBg.Cursor = [System.Windows.Forms.Cursors]::Hand; $logContainer.Controls.Add($customScrollBg)
    $customScrollThumb = New-Object System.Windows.Forms.Panel; $customScrollThumb.Location = New-Object System.Drawing.Point(3, 2); $customScrollThumb.Size = New-Object System.Drawing.Size(12, 180); $customScrollThumb.BackColor = [System.Drawing.Color]::FromArgb(75, 85, 105); $customScrollThumb.Cursor = [System.Windows.Forms.Cursors]::Hand; $customScrollBg.Controls.Add($customScrollThumb)

    $global:scrollDragging = $false; $global:scrollDragOffsetY = 0
    function Get-LogVisibleLines { return [Math]::Max(1, [int][Math]::Floor($logBox.ClientSize.Height / [Math]::Max(14, $logBox.Font.Height))) }
    function Update-CustomScroll {
        if (-not $logBox.IsHandleCreated) { return }
        $totalLines = [int][WinAPI.Desktop]::SendMessage($logBox.Handle, 0x00BA, [IntPtr]::Zero, [IntPtr]::Zero)
        $firstVisible = [int][WinAPI.Desktop]::SendMessage($logBox.Handle, 0x00CE, [IntPtr]::Zero, [IntPtr]::Zero)
        $visibleLines = Get-LogVisibleLines; $trackHeight = $customScrollBg.Height - 4
        if ($totalLines -le $visibleLines) { $customScrollThumb.Height = $trackHeight; $customScrollThumb.Top = 2; return }
        $thumbHeight = [Math]::Max(26, [int](($visibleLines / $totalLines) * $trackHeight)); $customScrollThumb.Height = $thumbHeight
        $ratio = [Math]::Max(0.0, [Math]::Min(1.0, $firstVisible / [Math]::Max(1, $totalLines - $visibleLines)))
        $customScrollThumb.Top = 2 + [int]($ratio * ($trackHeight - $thumbHeight))
    }
    function Set-LogScrollByThumbTop([int]$desiredTop) {
        if (-not $logBox.IsHandleCreated) { return }
        $totalLines = [int][WinAPI.Desktop]::SendMessage($logBox.Handle, 0x00BA, [IntPtr]::Zero, [IntPtr]::Zero)
        $firstVisible = [int][WinAPI.Desktop]::SendMessage($logBox.Handle, 0x00CE, [IntPtr]::Zero, [IntPtr]::Zero)
        $visibleLines = Get-LogVisibleLines; if ($totalLines -le $visibleLines) { return }
        $maxThumbTop = [Math]::Max(1, ($customScrollBg.Height - 4) - $customScrollThumb.Height)
        $clampedTop = [Math]::Max(2, [Math]::Min(2 + $maxThumbTop, $desiredTop)); $customScrollThumb.Top = $clampedTop
        $targetLine = [int][Math]::Round((($clampedTop - 2) / $maxThumbTop) * ($totalLines - $visibleLines))
        $delta = $targetLine - $firstVisible
        if ($delta -ne 0) { [void][WinAPI.Desktop]::SendMessage($logBox.Handle, 0x00B6, [IntPtr]::Zero, [IntPtr]$delta) }
    }
    $logBox.Add_MouseWheel({ param($s, $e) [void][WinAPI.Desktop]::SendMessage($logBox.Handle, 0x00B6, [IntPtr]::Zero, [IntPtr](if ($e.Delta -gt 0) { -3 } else { 3 })); Update-CustomScroll })
    $logBox.Add_KeyUp({ Update-CustomScroll }); $logBox.Add_TextChanged({ Update-CustomScroll })
    $customScrollThumb.Add_MouseDown({ param($s, $e) if ($e.Button -eq "Left") { $global:scrollDragging = $true; $global:scrollDragOffsetY = $e.Y } })
    $customScrollThumb.Add_MouseMove({ if ($global:scrollDragging) { Set-LogScrollByThumbTop (($customScrollBg.PointToClient([System.Windows.Forms.Cursor]::Position)).Y - $global:scrollDragOffsetY) } })
    $customScrollThumb.Add_MouseUp({ $global:scrollDragging = $false })
    $customScrollBg.Add_MouseDown({ param($s, $e) if ($e.Button -eq "Left") { Set-LogScrollByThumbTop ($e.Y - [int]($customScrollThumb.Height / 2)) } })

    $timer = New-Object System.Windows.Forms.Timer; $timer.Interval = 800
    function Ler-Novas($t) {
        if (-not (Test-Path $t.Out)) { return }
        $linhas = @(Get-Content $t.Out -ErrorAction SilentlyContinue)
        for ($k = $t.Lido; $k -lt $linhas.Count; $k++) {
            $l = "$($linhas[$k])".Trim()
            if ($l -match '^##AGORA \[(\d+)/(\d+)\] (.+)$') {
                Log ("  > Instalando agora: " + $matches[3] + " (" + $matches[1] + "/" + $matches[2] + ")")
                $lblStatus.Text = "Instalando agora: " + $matches[3] + " (" + $matches[1] + "/" + $matches[2] + ")"
                $atual = [double]$matches[1]; $totalEtapas = [double]$matches[2]
                if ($totalEtapas -gt 1) {
                    $global:progressMax = $totalEtapas
                    $baseVal = [Math]::Max(0.2, $atual - 0.85)
                    if ($baseVal -gt $global:progressVal) { $global:progressVal = $baseVal }
                    $global:progressTarget = [Math]::Min($totalEtapas - 0.08, $atual - 0.05)
                    Update-CustomProgress $global:progressVal
                }
            }
            elseif ($l -match '^##OK (.+)$')   { $t.Ok++;   Log ("  [OK]   " + $matches[1] + " instalado") }
            elseif ($l -match '^##JA (.+)$')   { $t.Ja++;   Log ("  [JA]   " + $matches[1] + " ja estava instalado") }
            elseif ($l -match '^##ERRO (.+)$') { $t.Erro++; Log ("  [ERRO] " + $matches[1]) }
            elseif ($l -match '^##INFO (.+)$') { Log ("         " + $matches[1]) }
        }
        $t.Lido = $linhas.Count
    }
    $timer.Add_Tick({
        $appElapsed = Format-ElapsedDuration ((Get-Date) - $global:appStartTime)
        if ($global:tasks.Count -gt 0) {
            $curElapsed = Format-ElapsedDuration ((Get-Date) - $global:tasks[0].Inicio)
            $lblRuntimeGuiFooter.Text = "Tempo: Tarefa $curElapsed | Total $appElapsed"
        } elseif ($global:lastTaskDuration) {
            $lblRuntimeGuiFooter.Text = "Tempo: Tarefa $($global:lastTaskDuration) | Total $appElapsed"
        } else {
            $lblRuntimeGuiFooter.Text = "Tempo: Tarefa 00m 00s | Total $appElapsed"
        }

        foreach ($t in @($global:tasks)) {
            Ler-Novas $t
            if ($t.Proc.HasExited) {
                Start-Sleep -Milliseconds 200; Ler-Novas $t
                $durStr = Format-ElapsedDuration ((Get-Date) - $t.Inicio)
                $global:lastTaskDuration = $durStr
                Log ("=== Fim: " + $t.Nome + " (" + $durStr + ") | instalados: " + $t.Ok + " | ja tinha: " + $t.Ja + " | erros: " + $t.Erro + " ===")
                Remove-Item -LiteralPath $t.Worker -Force -ErrorAction SilentlyContinue
                $global:tasks.Remove($t)
                if ($global:tasks.Count -gt 0) { $lblStatus.Text = "Em andamento: " + $global:tasks[0].Nome + " (" + $global:tasks.Count + " na fila)" }
                else {
                    $progressPulse.Visible = $false; $global:progressTarget = $global:progressMax; Update-CustomProgress $global:progressMax
                    if ($t.Erro -gt 0) { $lblStatus.Text = "Concluido com erros ($durStr) - veja o log"; $lblStatus.ForeColor = [System.Drawing.Color]::FromArgb(255, 90, 90); $progressBarFill.BackColor = [System.Drawing.Color]::FromArgb(220, 65, 75) }
                    else { $lblStatus.Text = "Concluido com sucesso em $durStr!"; $lblStatus.ForeColor = [System.Drawing.Color]::FromArgb(0, 255, 160); $progressBarFill.BackColor = [System.Drawing.Color]::FromArgb(0, 210, 130) }
                    if ($chkReiniciar.Checked) {
                        Log "Reiniciar ao concluir marcado: o computador vai reiniciar em 60 segundos..."
                        shutdown.exe /r /t 60 /c "Assistente de Formatacao: tarefas concluidas. Reiniciando em 60 segundos." | Out-Null
                        $resp = [System.Windows.Forms.MessageBox]::Show("Todas as tarefas terminaram.`n`nO computador vai reiniciar em 60 segundos.`n`nOK = Reiniciar agora`nCancelar = NAO reiniciar", "Reiniciar o computador", [System.Windows.Forms.MessageBoxButtons]::OKCancel, [System.Windows.Forms.MessageBoxIcon]::Warning)
                        if ($resp -eq [System.Windows.Forms.DialogResult]::Cancel) { shutdown.exe /a | Out-Null; Log "Reinicio cancelado pelo usuario." }
                        else { shutdown.exe /a | Out-Null; shutdown.exe /r /t 0 | Out-Null; $form.Close() }
                    }
                    if ($chkDesligar.Checked) {
                        Log "Desligar ao concluir marcado: o computador vai desligar em 60 segundos..."
                        shutdown.exe /s /t 60 /c "Assistente de Formatacao: tarefas concluidas. Desligando em 60 segundos." | Out-Null
                        $resp = [System.Windows.Forms.MessageBox]::Show("Todas as tarefas terminaram.`n`nO computador vai desligar em 60 segundos.`n`nOK = Desligar agora`nCancelar = NAO desligar", "Desligar o computador", [System.Windows.Forms.MessageBoxButtons]::OKCancel, [System.Windows.Forms.MessageBoxIcon]::Warning)
                        if ($resp -eq [System.Windows.Forms.DialogResult]::Cancel) { shutdown.exe /a | Out-Null; Log "Desligamento cancelado pelo usuario." }
                        else { shutdown.exe /a | Out-Null; shutdown.exe /s /t 0 | Out-Null; $form.Close() }
                    }
                    if ($chkSair.Checked) { Log "Sair ao concluir marcado: fechando a ferramenta..."; $form.Close() }
                }
            }
        }
    })
    $timer.Start()

    $sair = New-Object System.Windows.Forms.Button; $sair.Text = "Encerrar Ferramenta"; $sair.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold); $sair.Size = New-Object System.Drawing.Size(170, 38); $sair.Location = New-Object System.Drawing.Point(24, 634); $sair.FlatStyle = "Flat"; $sair.FlatAppearance.BorderSize = 0; $sair.BackColor = [System.Drawing.Color]::FromArgb(180, 50, 60); $sair.ForeColor = [System.Drawing.Color]::White; $sair.Cursor = "Hand"; $sair.Add_Click({ $form.Close() }); $form.Controls.Add($sair)
    $chkSair = New-Object System.Windows.Forms.CheckBox; $chkSair.Text = "Sair ao concluir"; $chkSair.Font = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Bold); $chkSair.AutoSize = $true; $chkSair.Location = New-Object System.Drawing.Point(210, 655); $chkSair.ForeColor = [System.Drawing.Color]::FromArgb(225, 232, 242); $chkSair.Cursor = "Hand"; $chkSair.Add_CheckedChanged({ if ($chkSair.Checked) { $chkReiniciar.Checked = $false; $chkDesligar.Checked = $false } }); $form.Controls.Add($chkSair)
    $chkReiniciar = New-Object System.Windows.Forms.CheckBox; $chkReiniciar.Text = "Reiniciar ao concluir"; $chkReiniciar.Font = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Bold); $chkReiniciar.AutoSize = $true; $chkReiniciar.Location = New-Object System.Drawing.Point(210, 633); $chkReiniciar.ForeColor = [System.Drawing.Color]::FromArgb(255, 190, 90); $chkReiniciar.Cursor = "Hand"; $chkReiniciar.Add_CheckedChanged({ if ($chkReiniciar.Checked) { $chkSair.Checked = $false; $chkDesligar.Checked = $false } }); $form.Controls.Add($chkReiniciar)
    $chkDesligar = New-Object System.Windows.Forms.CheckBox; $chkDesligar.Text = "Desligar ao concluir"; $chkDesligar.Font = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Bold); $chkDesligar.AutoSize = $true; $chkDesligar.Location = New-Object System.Drawing.Point(370, 633); $chkDesligar.ForeColor = [System.Drawing.Color]::FromArgb(255, 110, 110); $chkDesligar.Cursor = "Hand"; $chkDesligar.Add_CheckedChanged({ if ($chkDesligar.Checked) { $chkSair.Checked = $false; $chkReiniciar.Checked = $false } }); $form.Controls.Add($chkDesligar)
    $watermark = New-Object System.Windows.Forms.Label; $watermark.Text = "Desenvolvido por: Elson (Criatividade E Tudo)"; $watermark.Font = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Bold); $watermark.ForeColor = [System.Drawing.Color]::FromArgb(185, 198, 215); $watermark.AutoSize = $true; $watermark.Location = New-Object System.Drawing.Point(495, 645); $form.Controls.Add($watermark)
    $lblRuntimeGuiFooter = New-Object System.Windows.Forms.Label; $lblRuntimeGuiFooter.Text = "Tempo: Tarefa 00m 00s | Total 00m 00s"; $lblRuntimeGuiFooter.Font = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Bold); $lblRuntimeGuiFooter.ForeColor = [System.Drawing.Color]::FromArgb(0, 220, 255); $lblRuntimeGuiFooter.AutoSize = $true; $lblRuntimeGuiFooter.Location = New-Object System.Drawing.Point(775, 645); $form.Controls.Add($lblRuntimeGuiFooter)
    $versaoLabel = New-Object System.Windows.Forms.Label; $versaoLabel.Text = $VersaoAtual; $versaoLabel.Font = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Bold); $versaoLabel.ForeColor = [System.Drawing.Color]::FromArgb(0, 200, 255); $versaoLabel.AutoSize = $true; $versaoLabel.Location = New-Object System.Drawing.Point(1055, 645); $form.Controls.Add($versaoLabel)

    $form.Show(); Update-CustomScroll
    [System.Windows.Forms.Application]::Run($form)
    $netTimer.Stop(); $netTimer.Dispose(); $animTimer.Stop(); $animTimer.Dispose(); $timer.Stop(); $timer.Dispose(); $form.Dispose()

} elseif ($ModoExecucao -eq 'GTA6') {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    [System.Windows.Forms.Application]::EnableVisualStyles()

    $cBgMain      = [System.Drawing.Color]::FromArgb(18, 10, 30)
    $cBgPanel     = [System.Drawing.Color]::FromArgb(30, 17, 50)
    $cBgHeader    = [System.Drawing.Color]::FromArgb(13, 7, 22)
    $cNeonPink    = [System.Drawing.Color]::FromArgb(255, 42, 133)
    $cNeonCyan    = [System.Drawing.Color]::FromArgb(0, 240, 255)
    $cSunsetOrg   = [System.Drawing.Color]::FromArgb(255, 165, 55)
    $cTabActiveBg = [System.Drawing.Color]::FromArgb(0, 210, 235)
    $cTabActiveFg = [System.Drawing.Color]::FromArgb(10, 12, 20)
    $cTabIdleBg   = [System.Drawing.Color]::FromArgb(34, 20, 56)
    $cTabIdleFg   = [System.Drawing.Color]::FromArgb(255, 232, 95)
    $cTextLight   = [System.Drawing.Color]::FromArgb(255, 255, 255)
    $cTextMuted   = [System.Drawing.Color]::FromArgb(155, 248, 255)
    $cGtaOptText  = [System.Drawing.Color]::FromArgb(255, 232, 95)
    $cGtaOptSub   = [System.Drawing.Color]::FromArgb(165, 248, 255)

    function New-GtaMiniImage {
        param([string]$Tipo, [int]$W = 32, [int]$H = 32)
        $bmp = New-Object System.Drawing.Bitmap($W, $H)
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $g.Clear([System.Drawing.Color]::Transparent)

        switch ($Tipo) {
            "LogoVI" {
                $rectSun = New-Object System.Drawing.Rectangle(3, 2, ($W - 6), ($H - 4))
                $brushSun = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
                    $rectSun,
                    [System.Drawing.Color]::FromArgb(255, 200, 50),
                    [System.Drawing.Color]::FromArgb(255, 42, 133),
                    90.0
                )
                $g.FillEllipse($brushSun, $rectSun)
                $fnt = New-Object System.Drawing.Font("Segoe UI", [Math]::Max(10, [int]($H * 0.36)), [System.Drawing.FontStyle]::Bold)
                $brDark = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(15, 8, 25))
                $brWhite = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
                $g.DrawString("VI", $fnt, $brDark, 8, 6)
                $g.DrawString("VI", $fnt, $brWhite, 7, 5)
            }
            "LogoVIBW" {
                $penRing = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(245, 245, 245), [Math]::Max(2.0, [float]($W * 0.045)))
                $g.DrawEllipse($penRing, 4, 4, ($W - 8), ($H - 8))
                $fnt = New-Object System.Drawing.Font("Segoe UI", [Math]::Max(13, [int]($H * 0.38)), [System.Drawing.FontStyle]::Bold)
                $sf = New-Object System.Drawing.StringFormat
                $sf.Alignment = [System.Drawing.StringAlignment]::Center
                $sf.LineAlignment = [System.Drawing.StringAlignment]::Center
                $rectFull = New-Object System.Drawing.RectangleF(0, 1, $W, $H)
                $g.DrawString("VI", $fnt, [System.Drawing.Brushes]::Black, (New-Object System.Drawing.RectangleF(2, 3, $W, $H)), $sf)
                $g.DrawString("VI", $fnt, [System.Drawing.Brushes]::White, $rectFull, $sf)
            }
            "TabEssenciais" {
                $p = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 42, 133), 2.2)
                $g.DrawRectangle($p, 5, 5, 9, 9)
                $g.DrawRectangle($p, 18, 5, 9, 9)
                $g.DrawRectangle($p, 5, 18, 9, 9)
                $g.FillRectangle((New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 165, 55))), 18, 18, 9, 9)
            }
            "TabGamer" {
                $br = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 42, 133))
                $g.FillEllipse($br, 3, 8, 12, 16)
                $g.FillEllipse($br, 17, 8, 12, 16)
                $g.FillRectangle($br, 9, 10, 14, 11)
            }
            "TabLojas" {
                $p = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 165, 55), 2.2)
                $g.DrawRectangle($p, 6, 11, 20, 16)
                $g.DrawArc($p, 11, 5, 10, 10, 180, 180)
            }
            "TabSistema" {
                $p = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 42, 133), 2.2)
                $g.DrawEllipse($p, 7, 7, 18, 18)
                $g.FillEllipse((New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 165, 55))), 13, 13, 6, 6)
            }
            "CardChrome" {
                $g.FillEllipse((New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 70, 95))), 4, 4, 24, 24)
                $g.FillEllipse((New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(0, 240, 255))), 10, 10, 12, 12)
            }
            "CardWinRAR" {
                $g.FillRectangle((New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(165, 90, 235))), 6, 5, 20, 7)
                $g.FillRectangle((New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(0, 240, 255))), 6, 13, 20, 7)
                $g.FillRectangle((New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 42, 133))), 6, 21, 20, 7)
            }
            "CardOffice" {
                $p = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 165, 55), 2.5)
                $g.DrawRectangle($p, 7, 5, 18, 22)
                $g.DrawLine($p, 11, 12, 21, 12)
                $g.DrawLine($p, 11, 18, 21, 18)
            }
            "CardAdobe" {
                $p = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 42, 133), 2.5)
                $g.DrawPolygon($p, [System.Drawing.Point[]]@(
                    (New-Object System.Drawing.Point(16, 4)),
                    (New-Object System.Drawing.Point(28, 26)),
                    (New-Object System.Drawing.Point(4, 26))
                ))
            }
            "CardAfterburner" {
                $p = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(0, 240, 255), 2.5)
                $g.DrawArc($p, 4, 6, 24, 24, 180, 180)
                $g.DrawLine((New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 42, 133), 2.5)), 16, 20, 24, 10)
            }
            "CardKey" {
                $p = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 200, 50), 2.5)
                $g.DrawEllipse($p, 5, 10, 11, 11)
                $g.DrawLine($p, 16, 15, 27, 15)
                $g.DrawLine($p, 24, 15, 24, 21)
            }
            "CardBundle" {
                $g.FillPolygon((New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(0, 240, 255))), [System.Drawing.Point[]]@(
                    (New-Object System.Drawing.Point(18, 4)),
                    (New-Object System.Drawing.Point(8, 17)),
                    (New-Object System.Drawing.Point(15, 17)),
                    (New-Object System.Drawing.Point(13, 28)),
                    (New-Object System.Drawing.Point(24, 15)),
                    (New-Object System.Drawing.Point(17, 15))
                ))
            }
        }
        $g.Dispose()
        return $bmp
    }

    $splashGta = New-Object System.Windows.Forms.Form
    $splashGta.ClientSize = New-Object System.Drawing.Size(520, 270)
    $splashGta.StartPosition = "CenterScreen"
    $splashGta.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
    $splashGta.BackColor = [System.Drawing.Color]::FromArgb(10, 10, 10)
    $splashGta.ForeColor = [System.Drawing.Color]::White
    $splashGta.Opacity = 0.0

    $picSplashVI = New-Object System.Windows.Forms.PictureBox
    $picSplashVI.Size = New-Object System.Drawing.Size(84, 84)
    $picSplashVI.Location = New-Object System.Drawing.Point(218, 26)
    $picSplashVI.Image = New-GtaMiniImage -Tipo "LogoVIBW" -W 84 -H 84
    $splashGta.Controls.Add($picSplashVI)

    $lblSplashGtaTitle = New-Object System.Windows.Forms.Label
    $lblSplashGtaTitle.Text = "ASSISTENTE DE FORMATAÇÃO • GTA 6"
    $lblSplashGtaTitle.Font = New-Object System.Drawing.Font("Segoe UI", 12.5, [System.Drawing.FontStyle]::Bold)
    $lblSplashGtaTitle.ForeColor = [System.Drawing.Color]::White
    $lblSplashGtaTitle.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $lblSplashGtaTitle.Size = New-Object System.Drawing.Size(480, 28)
    $lblSplashGtaTitle.Location = New-Object System.Drawing.Point(20, 118)
    $splashGta.Controls.Add($lblSplashGtaTitle)

    $lblSplashGtaSub = New-Object System.Windows.Forms.Label
    $lblSplashGtaSub.Text = "Carregando..."
    $lblSplashGtaSub.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
    $lblSplashGtaSub.ForeColor = [System.Drawing.Color]::FromArgb(195, 195, 195)
    $lblSplashGtaSub.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $lblSplashGtaSub.Size = New-Object System.Drawing.Size(480, 22)
    $lblSplashGtaSub.Location = New-Object System.Drawing.Point(20, 150)
    $splashGta.Controls.Add($lblSplashGtaSub)

    $lblSplashGtaAuthor = New-Object System.Windows.Forms.Label
    $lblSplashGtaAuthor.Text = "Elson (Criatividade E Tudo) • $VersaoAtual"
    $lblSplashGtaAuthor.Font = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Bold)
    $lblSplashGtaAuthor.ForeColor = [System.Drawing.Color]::FromArgb(135, 135, 135)
    $lblSplashGtaAuthor.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $lblSplashGtaAuthor.Size = New-Object System.Drawing.Size(480, 20)
    $lblSplashGtaAuthor.Location = New-Object System.Drawing.Point(20, 176)
    $splashGta.Controls.Add($lblSplashGtaAuthor)

    $splashGtaBarBg = New-Object System.Windows.Forms.Panel
    $splashGtaBarBg.Location = New-Object System.Drawing.Point(60, 216)
    $splashGtaBarBg.Size = New-Object System.Drawing.Size(400, 6)
    $splashGtaBarBg.BackColor = [System.Drawing.Color]::FromArgb(38, 38, 38)
    $splashGta.Controls.Add($splashGtaBarBg)

    $splashGtaBarFill = New-Object System.Windows.Forms.Panel
    $splashGtaBarFill.Location = New-Object System.Drawing.Point(0, 0)
    $splashGtaBarFill.Size = New-Object System.Drawing.Size(0, 6)
    $splashGtaBarFill.BackColor = [System.Drawing.Color]::White
    $splashGtaBarBg.Controls.Add($splashGtaBarFill)

    $splashGtaTimer = New-Object System.Windows.Forms.Timer
    $splashGtaTimer.Interval = 22
    $global:splashGtaStep = 0
    $splashGtaTimer.Add_Tick({
        $global:splashGtaStep++
        if ($splashGta.Opacity -lt 1.0) { $splashGta.Opacity = [Math]::Min(1.0, $splashGta.Opacity + 0.1) }
        $pct = [Math]::Min(1.0, ($global:splashGtaStep / 50.0))
        $splashGtaBarFill.Width = [int]($pct * 400)
        if ($global:splashGtaStep -ge 50) {
            $splashGtaTimer.Stop()
            $splashGta.Close()
        }
    })
    $splashGta.Add_Shown({ $splashGtaTimer.Start() })
    [void]$splashGta.ShowDialog()
    $splashGtaTimer.Dispose()
    $splashGta.Dispose()

    $global:tasks = New-Object System.Collections.ArrayList
    $global:totalEtapas = 0
    $global:etapaAtual = 0
    $global:isBatchTask = $false
    $global:appStartTime = Get-Date
    $global:lastTaskDuration = ""

    function Format-ElapsedDuration([TimeSpan]$ts) {
        if ($ts.TotalHours -ge 1) {
            return "{0:00}h {1:00}m {2:00}s" -f [int][Math]::Floor($ts.TotalHours), $ts.Minutes, $ts.Seconds
        }
        return "{0:00}m {1:00}s" -f $ts.Minutes, $ts.Seconds
    }

    function Log($msg) { 
        $logBox.AppendText((Get-Date -Format 'HH:mm:ss') + "  " + $msg + "`r`n") 
        $logBox.SelectionStart = $logBox.Text.Length
        $logBox.ScrollToCaret()
        Update-CustomScroll
    }

    function Start-Task($titulo, $script, $total = 1) {
        $taskId = [guid]::NewGuid().ToString('N')
        $out = Join-Path $env:TEMP ("inst_" + $taskId + ".txt")
        $worker = Join-Path $env:TEMP ("inst_" + $taskId + ".ps1")
        $escapedOut = $out.Replace("'", "''")
        $script = "& { " + $appInstallHelpers + "`r`n" + $script + " } *> '$escapedOut'; exit `$LASTEXITCODE"
        [IO.File]::WriteAllText($worker, $script, (New-Object System.Text.UTF8Encoding($true)))
        try {
            $p = Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -STA -File `"$worker`"" -WindowStyle Hidden -PassThru -ErrorAction Stop
        } catch {
            Remove-Item -LiteralPath $worker -Force -ErrorAction SilentlyContinue
            throw
        }
        [void]$global:tasks.Add(@{ Nome = $titulo; Proc = $p; Out = $out; Worker = $worker; Lido = 0; Ok = 0; Ja = 0; Erro = 0; Inicio = (Get-Date) })

        $global:totalEtapas = $total
        $global:etapaAtual = 0
        $progressBarFill.BackColor = $cNeonPink
        $progressPulse.Visible = $true

        if ($total -gt 1) {
            $global:isBatchTask = $true
            $global:progressMax = $total
            $global:progressVal = 0.2
            $global:progressTarget = 0.8
            Update-CustomProgress 0.2
            $lblStatus.Text = "Instalando lote: $titulo (0/$total)..."
            $lblStatus.ForeColor = $cNeonCyan
        } else {
            $global:isBatchTask = $false
            $global:progressMax = 100
            $global:progressVal = 15
            $global:progressTarget = 92
            Update-CustomProgress 15
            $qtdFila = $global:tasks.Count
            $lblStatus.Text = if ($qtdFila -gt 1) { "Instalando: $titulo (Fila: $qtdFila)..." } else { "Instalando: $titulo..." }
            $lblStatus.ForeColor = $cNeonCyan
        }
        Log "=== Iniciando: $titulo ==="
    }

    function Passo($n, $tot, $nome, $cmd) {
        "Write-Host '##AGORA [$n/$tot] $nome'; `$global:LASTEXITCODE = 0; $cmd; `$c = `$global:LASTEXITCODE; " +
        "if (`$c -eq 0) { Write-Host '##OK $nome' } elseif (`$c -eq -1978335189) { Write-Host '##JA $nome' } " +
        "else { Write-Host ('##ERRO $nome (codigo ' + `$c + ')'); `$global:falhou = 1 }"
    }

    function Lote($passos) { "`$global:falhou = 0; " + ($passos -join "; ") + "; `$global:LASTEXITCODE = [int]`$global:falhou" }

    $form = New-Object System.Windows.Forms.Form
    $form.Icon = [System.Drawing.SystemIcons]::Application
    $form.Text = "Assistente de Formatação Pro - GTA VI ($VersaoAtual)"
    $form.ClientSize = New-Object System.Drawing.Size(1140, 700)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
    $form.BackColor = $cBgMain
    $form.ForeColor = $cTextLight
    $form.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)

    $global:mouseOffset = $null
    $customTitleBar = New-Object System.Windows.Forms.Panel
    $customTitleBar.Location = New-Object System.Drawing.Point(0, 0)
    $customTitleBar.Size = New-Object System.Drawing.Size(1140, 34)
    $customTitleBar.BackColor = $cBgHeader
    $form.Controls.Add($customTitleBar)

    $customTitleBar.Add_MouseDown({ if ($_.Button -eq [System.Windows.Forms.MouseButtons]::Left) { $global:mouseOffset = New-Object System.Drawing.Point($_.X, $_.Y) } })
    $customTitleBar.Add_MouseMove({
        if ($_.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
            $mousePos = [System.Windows.Forms.Control]::MousePosition
            $mousePos.Offset(-$global:mouseOffset.X, -$global:mouseOffset.Y)
            $form.Location = $mousePos
        }
    })

    $lblWindowTitle = New-Object System.Windows.Forms.Label
    $lblWindowTitle.Text = "  Assistente de Formatação Pro • GTA VI ($VersaoAtual)"
    $lblWindowTitle.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $lblWindowTitle.ForeColor = $cNeonCyan
    $lblWindowTitle.AutoSize = $true
    $lblWindowTitle.Location = New-Object System.Drawing.Point(8, 8)
    $customTitleBar.Controls.Add($lblWindowTitle)

    $btnClose = New-Object System.Windows.Forms.Button
    $btnClose.Text = "✕"
    $btnClose.Size = New-Object System.Drawing.Size(44, 34)
    $btnClose.Location = New-Object System.Drawing.Point(1096, 0)
    $btnClose.FlatStyle = "Flat"; $btnClose.FlatAppearance.BorderSize = 0
    $btnClose.BackColor = $cBgHeader; $btnClose.ForeColor = $cTextLight
    $btnClose.Cursor = "Hand"
    $btnClose.Add_MouseEnter({ $this.BackColor = $cNeonPink })
    $btnClose.Add_MouseLeave({ $this.BackColor = $cBgHeader })
    $btnClose.Add_Click({ $form.Close() })
    $customTitleBar.Controls.Add($btnClose)

    $btnMinimize = New-Object System.Windows.Forms.Button
    $btnMinimize.Text = "—"
    $btnMinimize.Size = New-Object System.Drawing.Size(44, 34)
    $btnMinimize.Location = New-Object System.Drawing.Point(1052, 0)
    $btnMinimize.FlatStyle = "Flat"; $btnMinimize.FlatAppearance.BorderSize = 0
    $btnMinimize.BackColor = $cBgHeader; $btnMinimize.ForeColor = $cTextLight
    $btnMinimize.Cursor = "Hand"
    $btnMinimize.Add_MouseEnter({ $this.BackColor = $cBgPanel })
    $btnMinimize.Add_MouseLeave({ $this.BackColor = $cBgHeader })
    $btnMinimize.Add_Click({ $form.WindowState = [System.Windows.Forms.FormWindowState]::Minimized })
    $customTitleBar.Controls.Add($btnMinimize)

    $header = New-Object System.Windows.Forms.Panel
    $header.Location = New-Object System.Drawing.Point(0, 34)
    $header.Size = New-Object System.Drawing.Size(1140, 72)
    $header.BackColor = [System.Drawing.Color]::FromArgb(24, 12, 42)
    $form.Controls.Add($header)

    $picHeaderVI = New-Object System.Windows.Forms.PictureBox
    $picHeaderVI.Size = New-Object System.Drawing.Size(48, 48)
    $picHeaderVI.Location = New-Object System.Drawing.Point(24, 12)
    $picHeaderVI.Image = New-GtaMiniImage -Tipo "LogoVI" -W 48 -H 48
    $header.Controls.Add($picHeaderVI)

    $title = New-Object System.Windows.Forms.Label
    $title.Text = "ASSISTENTE DE FORMATAÇÃO • GTA 6"
    $title.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
    $title.ForeColor = $cTextLight
    $title.AutoSize = $true
    $title.Location = New-Object System.Drawing.Point(84, 11)
    $header.Controls.Add($title)

    $subTitle = New-Object System.Windows.Forms.Label
    $subTitle.Text = "Modo GTA 6 • Elson (Criatividade E Tudo)"
    $subTitle.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $subTitle.ForeColor = $cNeonCyan
    $subTitle.AutoSize = $true
    $subTitle.Location = New-Object System.Drawing.Point(86, 40)
    $header.Controls.Add($subTitle)

    $netBadge = New-Object System.Windows.Forms.Panel
    $netBadge.Location = New-Object System.Drawing.Point(820, 16)
    $netBadge.Size = New-Object System.Drawing.Size(296, 40)
    $netBadge.BackColor = $cBgPanel
    $netBadge.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $header.Controls.Add($netBadge)

    $netDot = New-Object System.Windows.Forms.Panel
    $netDot.Location = New-Object System.Drawing.Point(12, 14)
    $netDot.Size = New-Object System.Drawing.Size(12, 12)
    $netDot.BackColor = $cNeonCyan
    $netBadge.Controls.Add($netDot)

    $lblNetStatus = New-Object System.Windows.Forms.Label
    $lblNetStatus.Text = "Verificando conexão..."
    $lblNetStatus.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $lblNetStatus.ForeColor = $cTextLight
    $lblNetStatus.AutoSize = $true
    $lblNetStatus.Location = New-Object System.Drawing.Point(32, 11)
    $netBadge.Controls.Add($lblNetStatus)

    function Update-NetworkStatus {
        try {
            $nics = [System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces() | Where-Object {
                $_.OperationalStatus -eq [System.Net.NetworkInformation.OperationalStatus]::Up -and
                $_.NetworkInterfaceType -ne [System.Net.NetworkInformation.NetworkInterfaceType]::Loopback -and
                $_.NetworkInterfaceType -ne [System.Net.NetworkInformation.NetworkInterfaceType]::Tunnel -and
                $_.Description -notmatch '(?i)Virtual|Hyper-V|VMware|VirtualBox|TAP-|VPN|Pseudo|Bluetooth'
            }
            $eth = $nics | Where-Object { $_.NetworkInterfaceType -eq [System.Net.NetworkInformation.NetworkInterfaceType]::Ethernet } | Select-Object -First 1
            $wifi = $nics | Where-Object { $_.NetworkInterfaceType -eq [System.Net.NetworkInformation.NetworkInterfaceType]::Wireless80211 } | Select-Object -First 1
            if ($eth) {
                $mbps = [Math]::Round($eth.Speed / 1000000)
                $speedTxt = if ($mbps -ge 1000) { "$([Math]::Round($mbps / 1000, 1)) Gbps" } elseif ($mbps -gt 0) { "$mbps Mbps" } else { "Ativo" }
                $lblNetStatus.Text = "CABO ETHERNET • $speedTxt"
                $lblNetStatus.ForeColor = $cNeonCyan
                $netDot.BackColor = $cNeonCyan
            } elseif ($wifi) {
                $lblNetStatus.Text = "WI-FI ATIVO • Conecte o Cabo"
                $lblNetStatus.ForeColor = $cSunsetOrg
                $netDot.BackColor = $cSunsetOrg
            } else {
                $lblNetStatus.Text = "SEM REDE • Cabo Desconectado"
                $lblNetStatus.ForeColor = $cNeonPink
                $netDot.BackColor = $cNeonPink
            }
        } catch { $lblNetStatus.Text = "Status de rede indisponível" }
    }
    Update-NetworkStatus
    $netTimer = New-Object System.Windows.Forms.Timer; $netTimer.Interval = 3000; $netTimer.Add_Tick({ Update-NetworkStatus }); $netTimer.Start()

    $tabBar = New-Object System.Windows.Forms.Panel
    $tabBar.Location = New-Object System.Drawing.Point(24, 116)
    $tabBar.Size = New-Object System.Drawing.Size(1092, 44)
    $tabBar.BackColor = $cBgMain
    $form.Controls.Add($tabBar)

    $tabPages = @{}
    $tabButtons = @{}

    function Select-GtaTab([string]$TabKey) {
        foreach ($k in $tabPages.Keys) {
            $isSel = ($k -eq $TabKey)
            $tabPages[$k].Visible = $isSel
            $btnT = $tabButtons[$k]
            if ($isSel) {
                $btnT.BackColor = $cTabActiveBg
                $btnT.ForeColor = $cTabActiveFg
            } else {
                $btnT.BackColor = $cTabIdleBg
                $btnT.ForeColor = $cGtaOptText
            }
        }
    }

    $tabsMeta = @(
        @{ Key = "Essenciais"; Titulo = "Essenciais";    Icone = "TabEssenciais"; X = 0 },
        @{ Key = "Pacotes";    Titulo = "Pacotes Gamer"; Icone = "TabGamer";      X = 276 },
        @{ Key = "Lojas";      Titulo = "Lojas & Extra"; Icone = "TabLojas";      X = 552 },
        @{ Key = "Sistema";    Titulo = "Sistema";       Icone = "TabSistema";    X = 828 }
    )

    foreach ($tm in $tabsMeta) {
        $bTab = New-Object System.Windows.Forms.Button
        $bTab.Text = "  " + $tm.Titulo
        $bTab.Size = New-Object System.Drawing.Size(264, 40)
        $bTab.Location = New-Object System.Drawing.Point($tm.X, 2)
        $bTab.FlatStyle = "Flat"; $bTab.FlatAppearance.BorderSize = 1; $bTab.FlatAppearance.BorderColor = $cNeonCyan
        $bTab.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        $bTab.Image = New-GtaMiniImage -Tipo $tm.Icone -W 22 -H 22
        $bTab.ImageAlign = [System.Drawing.ContentAlignment]::MiddleLeft
        $bTab.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
        $bTab.Cursor = "Hand"
        $bTab.Tag = $tm.Key
        $bTab.Add_Click({ Select-GtaTab $this.Tag })
        $tabBar.Controls.Add($bTab)
        $tabButtons[$tm.Key] = $bTab

        $pnlPage = New-Object System.Windows.Forms.Panel
        $pnlPage.Location = New-Object System.Drawing.Point(24, 166)
        $pnlPage.Size = New-Object System.Drawing.Size(1092, 224)
        $pnlPage.BackColor = [System.Drawing.Color]::FromArgb(24, 13, 42)
        $pnlPage.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
        $pnlPage.Visible = $false
        $form.Controls.Add($pnlPage)
        $tabPages[$tm.Key] = $pnlPage
    }

    function Add-GtaActionCard {
        param($Parent, [int]$X, [int]$Y, [int]$W, [int]$H, [string]$Titulo, [string]$Sub, [string]$IconeTipo, [System.Drawing.Color]$AccentColor, [scriptblock]$Acao)
        $card = New-Object System.Windows.Forms.Panel
        $card.Location = New-Object System.Drawing.Point($X, $Y)
        $card.Size = New-Object System.Drawing.Size($W, $H)
        $card.BackColor = $cBgPanel
        $card.Cursor = "Hand"

        $strip = New-Object System.Windows.Forms.Panel
        $strip.Location = New-Object System.Drawing.Point(0, 0)
        $strip.Size = New-Object System.Drawing.Size(5, $H)
        $strip.BackColor = $AccentColor
        $card.Controls.Add($strip)

        $pic = New-Object System.Windows.Forms.PictureBox
        $pic.Location = New-Object System.Drawing.Point(14, [int](($H - 32) / 2))
        $pic.Size = New-Object System.Drawing.Size(32, 32)
        $pic.Image = New-GtaMiniImage -Tipo $IconeTipo -W 32 -H 32
        $pic.Enabled = $false
        $card.Controls.Add($pic)

        $textX = 54
        $textW = [Math]::Max(80, $W - $textX - 12)

        $lblT = New-Object System.Windows.Forms.Label
        $lblT.Text = $Titulo
        $lblT.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
        $lblT.ForeColor = $cGtaOptText
        $lblT.Location = New-Object System.Drawing.Point($textX, 12)
        $lblT.Size = New-Object System.Drawing.Size($textW, 22)
        $lblT.Enabled = $false
        $card.Controls.Add($lblT)

        $lblS = New-Object System.Windows.Forms.Label
        $lblS.Text = $Sub
        $lblS.Font = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Bold)
        $lblS.ForeColor = $cGtaOptSub
        $lblS.Location = New-Object System.Drawing.Point($textX, 36)
        $lblS.Size = New-Object System.Drawing.Size($textW, [Math]::Max(24, $H - 42))
        $lblS.Enabled = $false
        $card.Controls.Add($lblS)

        $card.Tag = $Acao
        $card.Add_MouseEnter({ $this.BackColor = [System.Drawing.Color]::FromArgb(48, 26, 78) })
        $card.Add_MouseLeave({ $this.BackColor = [System.Drawing.Color]::FromArgb(30, 17, 50) })
        $card.Add_Click({ try { & $this.Tag } catch { [System.Windows.Forms.MessageBox]::Show("Erro: $_") } })
        $Parent.Controls.Add($card)
    }

    $pEss = $tabPages["Essenciais"]
    Add-GtaActionCard -Parent $pEss -X 18  -Y 16  -W 340 -H 88 -Titulo "Windows AT" -Sub "Ativação do Windows" -IconeTipo "CardKey" -AccentColor $cSunsetOrg -Acao {
        Start-Process powershell -ArgumentList "-NoProfile -Command `"& ([ScriptBlock]::Create((irm https://get.activated.win))) `"" -WindowStyle Minimized -PassThru
    }
    Add-GtaActionCard -Parent $pEss -X 376 -Y 16  -W 340 -H 88 -Titulo "Office AT" -Sub "Ativação do Office (Ohook)" -IconeTipo "CardKey" -AccentColor $cNeonPink -Acao {
        Start-Process powershell -ArgumentList "-NoProfile -Command `"& ([ScriptBlock]::Create((irm https://get.activated.win))) /Ohook`"" -WindowStyle Minimized -PassThru
    }
    Add-GtaActionCard -Parent $pEss -X 734 -Y 16  -W 340 -H 88 -Titulo "Instalar Google Chrome" -Sub "Navegador + Barra de Tarefas" -IconeTipo "CardChrome" -AccentColor $cNeonCyan -Acao {
        Start-Task "Chrome" (Lote @(Passo 1 1 "Chrome" (W "Google.Chrome")))
    }
    Add-GtaActionCard -Parent $pEss -X 18  -Y 118 -W 252 -H 88 -Titulo "Instalar WinRAR" -Sub "Compactador + Chave" -IconeTipo "CardWinRAR" -AccentColor $cSunsetOrg -Acao {
        Start-Task "WinRAR" (Lote @(Passo 1 1 "WinRAR" (W "RARLab.WinRAR")))
    }
    Add-GtaActionCard -Parent $pEss -X 286 -Y 118 -W 252 -H 88 -Titulo "Instalar Adobe Reader" -Sub "Leitor de PDF" -IconeTipo "CardAdobe" -AccentColor $cNeonPink -Acao {
        Start-Task "Adobe Reader" (Lote @(Passo 1 1 "Adobe Acrobat Reader" (W "Adobe.Acrobat.Reader.64-bit")))
    }
    Add-GtaActionCard -Parent $pEss -X 554 -Y 118 -W 252 -H 88 -Titulo "Instalar MSI Afterburner" -Sub "Monitoramento de GPU" -IconeTipo "CardAfterburner" -AccentColor $cNeonCyan -Acao {
        Start-Task "Afterburner" (Lote @(Passo 1 1 "MSI Afterburner" (W "Guru3D.Afterburner")))
    }
    Add-GtaActionCard -Parent $pEss -X 822 -Y 118 -W 252 -H 88 -Titulo "Instalar Apenas o Office" -Sub "Office + Atalhos na Área de Trabalho" -IconeTipo "CardOffice" -AccentColor $cSunsetOrg -Acao {
        Start-Task "Office e atalhos" (Lote @(Passo 1 1 "Office" "Install-OfficeDeployment"))
    }

    $pPac = $tabPages["Pacotes"]
    Add-GtaActionCard -Parent $pPac -X 18 -Y 16 -W 518 -H 88 -Titulo "Kit Gamer" -Sub "Desempenho Máximo • .NET 3.5/8 • VC++ • DirectX • GPU" -IconeTipo "TabGamer" -AccentColor $cNeonCyan -Acao {
        Start-Task "Kit Gamer" (Lote @(
            (Passo 1 6 "Desempenho Maximo" "Install-GamerPowerPlan"),
            (Passo 2 6 ".NET Framework 3.5" "Install-GamerNetFx3"),
            (Passo 3 6 ".NET Desktop Runtime 8" "Install-GamerDotNet8"),
            (Passo 4 6 "Visual C++ Redistributable" "Install-GamerVCRedist"),
            (Passo 5 6 "DirectX Runtimes" "Install-GamerDirectX"),
            (Passo 6 6 "Aplicativo Oficial da GPU" "Install-GamerGPUApp")
        )) -total 6
    }
    Add-GtaActionCard -Parent $pPac -X 556 -Y 16 -W 518 -H 88 -Titulo "TUDO (Sem MSI e sem Office)" -Sub "Google Chrome • Adobe Acrobat Reader • WinRAR" -IconeTipo "CardBundle" -AccentColor $cSunsetOrg -Acao {
        Start-Task "TUDO Sem MSI e sem Office" (Lote @(
            (Passo 1 3 "Chrome" (W "Google.Chrome")),
            (Passo 2 3 "Acrobat Reader" (W "Adobe.Acrobat.Reader.64-bit")),
            (Passo 3 3 "WinRAR" (W "RARLab.WinRAR"))
        )) -total 3
    }
    Add-GtaActionCard -Parent $pPac -X 18 -Y 118 -W 518 -H 88 -Titulo "INSTALAR TUDO (Sem MSI)" -Sub "Chrome • Adobe Reader • WinRAR • Office" -IconeTipo "CardBundle" -AccentColor $cNeonPink -Acao {
        Start-Task "INSTALAR TUDO (Sem MSI)" (Lote @(
            (Passo 1 4 "Chrome" (W "Google.Chrome")),
            (Passo 2 4 "Acrobat Reader" (W "Adobe.Acrobat.Reader.64-bit")),
            (Passo 3 4 "WinRAR" (W "RARLab.WinRAR")),
            (Passo 4 4 "Office" "Install-OfficeDeployment")
        )) -total 4
    }
    Add-GtaActionCard -Parent $pPac -X 556 -Y 118 -W 518 -H 88 -Titulo "INSTALAR TUDO + Office" -Sub "Chrome • Adobe Reader • WinRAR • MSI Afterburner • Office" -IconeTipo "LogoVI" -AccentColor $cNeonCyan -Acao {
        Start-Task "TUDO com Office" (Lote @(
            (Passo 1 5 "Chrome" (W "Google.Chrome")),
            (Passo 2 5 "Acrobat Reader" (W "Adobe.Acrobat.Reader.64-bit")),
            (Passo 3 5 "WinRAR" (W "RARLab.WinRAR")),
            (Passo 4 5 "MSI Afterburner" (W "Guru3D.Afterburner")),
            (Passo 5 5 "Office" "Install-OfficeDeployment")
        )) -total 5
    }

    $pLoj = $tabPages["Lojas"]
    $lblLojasTitle = New-Object System.Windows.Forms.Label
    $lblLojasTitle.Text = "Lojas de Jogos:"
    $lblLojasTitle.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
    $lblLojasTitle.ForeColor = $cNeonCyan
    $lblLojasTitle.AutoSize = $true
    $lblLojasTitle.Location = New-Object System.Drawing.Point(20, 14)
    $pLoj.Controls.Add($lblLojasTitle)

    $storeItems = [ordered]@{
        "Steam"            = "Valve.Steam"
        "Epic Games Store" = "EpicGames.EpicGamesLauncher"
        "GOG Galaxy"       = "GOG.Galaxy"
        "EA App"           = "ElectronicArts.EAApp"
        "Ubisoft Connect"  = "Ubisoft.Connect"
        "Battle.net"       = "Blizzard.BattleNet"
    }
    $gtaStoreChecks = @()
    $sIdx = 0
    foreach ($sn in $storeItems.Keys) {
        $sIdx++
        $colS = ($sIdx - 1) % 3
        $rowS = [Math]::Floor(($sIdx - 1) / 3)
        $chkS = New-Object System.Windows.Forms.CheckBox
        $chkS.Text = "  $sn"
        $chkS.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
        $chkS.ForeColor = $cGtaOptText
        $chkS.BackColor = $cBgPanel
        $chkS.Padding = New-Object System.Windows.Forms.Padding(10, 0, 0, 0)
        $chkS.Size = New-Object System.Drawing.Size(220, 42)
        $chkS.Location = New-Object System.Drawing.Point((20 + ($colS * 232)), (44 + ($rowS * 52)))
        $chkS.Tag = $storeItems[$sn]
        $chkS.Cursor = "Hand"
        $gtaStoreChecks += $chkS
        $pLoj.Controls.Add($chkS)
    }

    $btnInstLojasGta = New-Object System.Windows.Forms.Button
    $btnInstLojasGta.Text = "Instalar Lojas Selecionadas"
    $btnInstLojasGta.Size = New-Object System.Drawing.Size(340, 46)
    $btnInstLojasGta.Location = New-Object System.Drawing.Point(20, 158)
    $btnInstLojasGta.FlatStyle = "Flat"; $btnInstLojasGta.FlatAppearance.BorderSize = 0
    $btnInstLojasGta.BackColor = $cNeonPink; $btnInstLojasGta.ForeColor = $cTextLight
    $btnInstLojasGta.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
    $btnInstLojasGta.Cursor = "Hand"
    $btnInstLojasGta.Add_Click({
        $sel = @($gtaStoreChecks | Where-Object { $_.Checked })
        if ($sel.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show("Nenhuma loja selecionada!"); return }
        $passos = @(); $i = 0
        foreach ($c in $sel) { $i++; $passos += Passo $i $sel.Count "$($c.Text.Trim())" (W "$($c.Tag)") }
        Start-Task "Launchers ($($sel.Count) lojas)" (Lote $passos) -total $sel.Count
    })
    $pLoj.Controls.Add($btnInstLojasGta)

    $btnCustomTotalGta = New-Object System.Windows.Forms.Button
    $btnCustomTotalGta.Text = "Instalação Personalizada Total"
    $btnCustomTotalGta.Size = New-Object System.Drawing.Size(344, 46)
    $btnCustomTotalGta.Location = New-Object System.Drawing.Point(376, 158)
    $btnCustomTotalGta.FlatStyle = "Flat"; $btnCustomTotalGta.FlatAppearance.BorderSize = 1; $btnCustomTotalGta.FlatAppearance.BorderColor = $cNeonCyan
    $btnCustomTotalGta.BackColor = $cBgPanel; $btnCustomTotalGta.ForeColor = $cGtaOptText
    $btnCustomTotalGta.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
    $btnCustomTotalGta.Cursor = "Hand"
    $btnCustomTotalGta.Add_Click({
        $modalPC = New-Object System.Windows.Forms.Form; $modalPC.ClientSize = New-Object System.Drawing.Size(470, 540); $modalPC.StartPosition = "CenterParent"; $modalPC.FormBorderStyle = "None"; $modalPC.BackColor = $cBgMain; $modalPC.ForeColor = $cTextLight
        $btnCMPC = New-Object System.Windows.Forms.Button; $btnCMPC.Text = "✕"; $btnCMPC.Size = New-Object System.Drawing.Size(42, 32); $btnCMPC.Location = New-Object System.Drawing.Point(428, 0); $btnCMPC.FlatStyle = "Flat"; $btnCMPC.FlatAppearance.BorderSize = 0; $btnCMPC.ForeColor = $cTextLight; $btnCMPC.Add_Click({ $modalPC.Close() }); $modalPC.Controls.Add($btnCMPC)
        $lblMTPC = New-Object System.Windows.Forms.Label; $lblMTPC.Text = "INSTALAÇÃO PERSONALIZADA TOTAL:"; $lblMTPC.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold); $lblMTPC.ForeColor = $cNeonCyan; $lblMTPC.AutoSize = $true; $lblMTPC.Location = New-Object System.Drawing.Point(18, 14); $modalPC.Controls.Add($lblMTPC)
        $allCustomItems = [ordered]@{
            "Google Chrome" = (W "Google.Chrome"); "WinRAR" = (W "RARLab.WinRAR"); "MSI Afterburner" = (W "Guru3D.Afterburner")
            "Adobe Acrobat Reader" = (W "Adobe.Acrobat.Reader.64-bit"); "Microsoft Office" = "Install-OfficeDeployment"
            "Desempenho Máximo" = "Install-GamerPowerPlan"; ".NET Framework 3.5" = "Install-GamerNetFx3"
            ".NET Desktop Runtime 8" = "Install-GamerDotNet8"; "Visual C++ Redist." = "Install-GamerVCRedist"
            "DirectX Runtimes" = "Install-GamerDirectX"; "App Oficial da GPU" = "Install-GamerGPUApp"
            "Steam" = (W "Valve.Steam"); "Epic Games Store" = (W "EpicGames.EpicGamesLauncher"); "GOG Galaxy" = (W "GOG.Galaxy")
            "EA App" = (W "ElectronicArts.EAApp"); "Ubisoft Connect" = (W "Ubisoft.Connect"); "Battle.net" = (W "Blizzard.BattleNet")
            "Atualizar Windows" = "Invoke-WindowsUpdate"; "Atualizar Drivers" = "Invoke-DriverUpdate"
        }
        $checkBoxesPC = @(); $idxPC = 0
        foreach ($in in $allCustomItems.Keys) {
            $idxPC++; $colI = ($idxPC - 1) % 2; $rowI = [Math]::Floor(($idxPC - 1) / 2)
            $chkPC = New-Object System.Windows.Forms.CheckBox; $chkPC.Text = $in; $chkPC.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold); $chkPC.ForeColor = $cGtaOptText; $chkPC.Size = New-Object System.Drawing.Size(205, 28); $chkPC.Location = New-Object System.Drawing.Point((22 + ($colI * 220)), (52 + ($rowI * 36))); $chkPC.Tag = $allCustomItems[$in]
            $checkBoxesPC += $chkPC; $modalPC.Controls.Add($chkPC)
        }
        $chkAllPC = New-Object System.Windows.Forms.CheckBox; $chkAllPC.Text = "Marcar / Desmarcar Todos"; $chkAllPC.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold); $chkAllPC.AutoSize = $true; $chkAllPC.Location = New-Object System.Drawing.Point(255, 444); $chkAllPC.ForeColor = $cSunsetOrg; $chkAllPC.Add_CheckedChanged({ foreach ($c in $checkBoxesPC) { $c.Checked = $this.Checked } }); $modalPC.Controls.Add($chkAllPC)
        $btnOkPC = New-Object System.Windows.Forms.Button; $btnOkPC.Text = "Instalar Recursos Selecionados"; $btnOkPC.Size = New-Object System.Drawing.Size(420, 44); $btnOkPC.Location = New-Object System.Drawing.Point(25, 478); $btnOkPC.FlatStyle = "Flat"; $btnOkPC.FlatAppearance.BorderSize = 0; $btnOkPC.BackColor = $cNeonPink; $btnOkPC.ForeColor = $cTextLight; $btnOkPC.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
        $btnOkPC.Add_Click({
            $sel = @($checkBoxesPC | Where-Object { $_.Checked })
            if ($sel.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show("Nenhum item selecionado!"); return }
            $passos = @(); $i = 0; foreach ($c in $sel) { $i++; $passos += Passo $i $sel.Count "$($c.Text)" $c.Tag }
            $modalPC.Close(); Start-Task "Personalizada ($($sel.Count) itens)" (Lote $passos) -total $sel.Count
        })
        $modalPC.Controls.Add($btnOkPC); [void]$modalPC.ShowDialog($form); $modalPC.Dispose()
    })
    $pLoj.Controls.Add($btnCustomTotalGta)

    $posterBox = New-Object System.Windows.Forms.Panel
    $posterBox.Location = New-Object System.Drawing.Point(736, 16)
    $posterBox.Size = New-Object System.Drawing.Size(336, 188)
    $posterBox.BackColor = $cBgPanel
    $posterBox.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $pLoj.Controls.Add($posterBox)

    $picPoster = New-Object System.Windows.Forms.PictureBox
    $picPoster.Size = New-Object System.Drawing.Size(64, 64)
    $picPoster.Location = New-Object System.Drawing.Point(136, 20)
    $picPoster.Image = New-GtaMiniImage -Tipo "LogoVI" -W 64 -H 64
    $posterBox.Controls.Add($picPoster)

    $lblPosterTxt = New-Object System.Windows.Forms.Label
    $lblPosterTxt.Text = "GTA 6 • MODO SIMPLES`nMarque as lojas ou abra o seletor total."
    $lblPosterTxt.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $lblPosterTxt.ForeColor = $cGtaOptText
    $lblPosterTxt.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $lblPosterTxt.Size = New-Object System.Drawing.Size(316, 68)
    $lblPosterTxt.Location = New-Object System.Drawing.Point(10, 96)
    $posterBox.Controls.Add($lblPosterTxt)

    $pSis = $tabPages["Sistema"]
    Add-GtaActionCard -Parent $pSis -X 18 -Y 24 -W 518 -H 172 -Titulo "Atualizar Windows" -Sub "Varre, baixa e instala atualizações do Windows Update." -IconeTipo "TabSistema" -AccentColor $cNeonCyan -Acao {
        Start-Task "Atualizar Windows" (Lote @(Passo 1 1 "Windows Update" "Invoke-WindowsUpdate"))
    }
    Add-GtaActionCard -Parent $pSis -X 556 -Y 24 -W 518 -H 172 -Titulo "Atualizar Drivers" -Sub "Busca e instala drivers oficiais via Windows Update." -IconeTipo "CardAfterburner" -AccentColor $cNeonPink -Acao {
        Start-Task "Atualizar Drivers" (Lote @(Passo 1 1 "Drivers Update" "Invoke-DriverUpdate"))
    }

    Select-GtaTab "Essenciais"

    $logTitle = New-Object System.Windows.Forms.Label; $logTitle.Text = "CONSOLE DE TAREFAS"; $logTitle.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold); $logTitle.ForeColor = $cNeonCyan; $logTitle.AutoSize = $true; $logTitle.Location = New-Object System.Drawing.Point(24, 402); $form.Controls.Add($logTitle)
    $lblStatus = New-Object System.Windows.Forms.Label; $lblStatus.Text = "Aguardando ação..."; $lblStatus.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold); $lblStatus.ForeColor = $cTextMuted; $lblStatus.AutoSize = $true; $lblStatus.Location = New-Object System.Drawing.Point(205, 401); $form.Controls.Add($lblStatus)

    $progressBarBg = New-Object System.Windows.Forms.Panel; $progressBarBg.Location = New-Object System.Drawing.Point(24, 426); $progressBarBg.Size = New-Object System.Drawing.Size(1092, 8); $progressBarBg.BackColor = $cBgHeader; $form.Controls.Add($progressBarBg)
    $progressBarFill = New-Object System.Windows.Forms.Panel; $progressBarFill.Location = New-Object System.Drawing.Point(0, 0); $progressBarFill.Size = New-Object System.Drawing.Size(0, 8); $progressBarFill.BackColor = $cNeonPink; $progressBarBg.Controls.Add($progressBarFill)
    $progressPulse = New-Object System.Windows.Forms.Panel; $progressPulse.Location = New-Object System.Drawing.Point(-150, 0); $progressPulse.Size = New-Object System.Drawing.Size(150, 8); $progressPulse.BackColor = $cNeonCyan; $progressPulse.Visible = $false; $progressBarBg.Controls.Add($progressPulse); $progressPulse.BringToFront()

    $global:progressMax = 100.0; $global:progressVal = 0.0; $global:progressTarget = 0.0; $global:pulsePos = -150
    function Update-CustomProgress($val) {
        $global:progressVal = [Math]::Max(0.0, [Math]::Min([double]$val, [double]$global:progressMax))
        if ($global:progressMax -gt 0) { $progressBarFill.Width = [int](($global:progressVal / $global:progressMax) * 1092) }
    }

    $animTimer = New-Object System.Windows.Forms.Timer; $animTimer.Interval = 35
    $animTimer.Add_Tick({
        if ($global:tasks.Count -gt 0) {
            if ($global:progressVal -lt $global:progressTarget) {
                $step = [Math]::Max(0.002, ($global:progressTarget - $global:progressVal) * 0.015)
                $global:progressVal = [Math]::Min($global:progressTarget, $global:progressVal + $step)
                Update-CustomProgress $global:progressVal
            }
            $progressPulse.Visible = $true; $global:pulsePos += 28
            if ($global:pulsePos -gt 1092) { $global:pulsePos = -150 }
            $progressPulse.Left = $global:pulsePos
        } else { $progressPulse.Visible = $false }
    })
    $animTimer.Start()

    $logContainer = New-Object System.Windows.Forms.Panel; $logContainer.Location = New-Object System.Drawing.Point(24, 442); $logContainer.Size = New-Object System.Drawing.Size(1092, 188); $logContainer.BackColor = $cBgHeader; $logContainer.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle; $form.Controls.Add($logContainer)
    $logBox = New-Object System.Windows.Forms.TextBox; $logBox.Multiline = $true; $logBox.ReadOnly = $true; $logBox.WordWrap = $true; $logBox.ScrollBars = "None"; $logBox.Location = New-Object System.Drawing.Point(10, 6); $logBox.Size = New-Object System.Drawing.Size(1054, 176); $logBox.BackColor = $cBgHeader; $logBox.ForeColor = $cTextLight; $logBox.Font = New-Object System.Drawing.Font("Consolas", 9.5, [System.Drawing.FontStyle]::Bold); $logBox.BorderStyle = [System.Windows.Forms.BorderStyle]::None; $logContainer.Controls.Add($logBox)

    $customScrollBg = New-Object System.Windows.Forms.Panel; $customScrollBg.Location = New-Object System.Drawing.Point(1072, 0); $customScrollBg.Size = New-Object System.Drawing.Size(18, 188); $customScrollBg.BackColor = $cBgPanel; $customScrollBg.Cursor = "Hand"; $logContainer.Controls.Add($customScrollBg)
    $customScrollThumb = New-Object System.Windows.Forms.Panel; $customScrollThumb.Location = New-Object System.Drawing.Point(3, 2); $customScrollThumb.Size = New-Object System.Drawing.Size(12, 184); $customScrollThumb.BackColor = $cNeonCyan; $customScrollThumb.Cursor = "Hand"; $customScrollBg.Controls.Add($customScrollThumb)

    $global:scrollDragging = $false; $global:scrollDragOffsetY = 0
    function Get-LogVisibleLines { return [Math]::Max(1, [int][Math]::Floor($logBox.ClientSize.Height / [Math]::Max(14, $logBox.Font.Height))) }
    function Update-CustomScroll {
        if (-not $logBox.IsHandleCreated) { return }
        $totalLines = [int][WinAPI.Desktop]::SendMessage($logBox.Handle, 0x00BA, [IntPtr]::Zero, [IntPtr]::Zero)
        $firstVisible = [int][WinAPI.Desktop]::SendMessage($logBox.Handle, 0x00CE, [IntPtr]::Zero, [IntPtr]::Zero)
        $visibleLines = Get-LogVisibleLines; $trackHeight = $customScrollBg.Height - 4
        if ($totalLines -le $visibleLines) { $customScrollThumb.Height = $trackHeight; $customScrollThumb.Top = 2; return }
        $thumbHeight = [Math]::Max(26, [int](($visibleLines / $totalLines) * $trackHeight)); $customScrollThumb.Height = $thumbHeight
        $ratio = [Math]::Max(0.0, [Math]::Min(1.0, $firstVisible / [Math]::Max(1, $totalLines - $visibleLines)))
        $customScrollThumb.Top = 2 + [int]($ratio * ($trackHeight - $thumbHeight))
    }
    function Set-LogScrollByThumbTop([int]$desiredTop) {
        if (-not $logBox.IsHandleCreated) { return }
        $totalLines = [int][WinAPI.Desktop]::SendMessage($logBox.Handle, 0x00BA, [IntPtr]::Zero, [IntPtr]::Zero)
        $firstVisible = [int][WinAPI.Desktop]::SendMessage($logBox.Handle, 0x00CE, [IntPtr]::Zero, [IntPtr]::Zero)
        $visibleLines = Get-LogVisibleLines; if ($totalLines -le $visibleLines) { return }
        $maxThumbTop = [Math]::Max(1, ($customScrollBg.Height - 4) - $customScrollThumb.Height)
        $clampedTop = [Math]::Max(2, [Math]::Min(2 + $maxThumbTop, $desiredTop)); $customScrollThumb.Top = $clampedTop
        $targetLine = [int][Math]::Round((($clampedTop - 2) / $maxThumbTop) * ($totalLines - $visibleLines))
        $delta = $targetLine - $firstVisible
        if ($delta -ne 0) { [void][WinAPI.Desktop]::SendMessage($logBox.Handle, 0x00B6, [IntPtr]::Zero, [IntPtr]$delta) }
    }
    $logBox.Add_MouseWheel({ param($s, $e) [void][WinAPI.Desktop]::SendMessage($logBox.Handle, 0x00B6, [IntPtr]::Zero, [IntPtr](if ($e.Delta -gt 0) { -3 } else { 3 })); Update-CustomScroll })
    $logBox.Add_KeyUp({ Update-CustomScroll }); $logBox.Add_TextChanged({ Update-CustomScroll })
    $customScrollThumb.Add_MouseDown({ param($s, $e) if ($e.Button -eq "Left") { $global:scrollDragging = $true; $global:scrollDragOffsetY = $e.Y } })
    $customScrollThumb.Add_MouseMove({ if ($global:scrollDragging) { Set-LogScrollByThumbTop (($customScrollBg.PointToClient([System.Windows.Forms.Cursor]::Position)).Y - $global:scrollDragOffsetY) } })
    $customScrollThumb.Add_MouseUp({ $global:scrollDragging = $false })
    $customScrollBg.Add_MouseDown({ param($s, $e) if ($e.Button -eq "Left") { Set-LogScrollByThumbTop ($e.Y - [int]($customScrollThumb.Height / 2)) } })

    $timer = New-Object System.Windows.Forms.Timer; $timer.Interval = 800
    function Ler-Novas($t) {
        if (-not (Test-Path $t.Out)) { return }
        $linhas = @(Get-Content $t.Out -ErrorAction SilentlyContinue)
        for ($k = $t.Lido; $k -lt $linhas.Count; $k++) {
            $l = "$($linhas[$k])".Trim()
            if ($l -match '^##AGORA \[(\d+)/(\d+)\] (.+)$') {
                Log ("  > Instalando agora: " + $matches[3] + " (" + $matches[1] + "/" + $matches[2] + ")")
                $lblStatus.Text = "Instalando agora: " + $matches[3] + " (" + $matches[1] + "/" + $matches[2] + ")"
                $atual = [double]$matches[1]; $totalEtapas = [double]$matches[2]
                if ($totalEtapas -gt 1) {
                    $global:progressMax = $totalEtapas
                    $baseVal = [Math]::Max(0.2, $atual - 0.85)
                    if ($baseVal -gt $global:progressVal) { $global:progressVal = $baseVal }
                    $global:progressTarget = [Math]::Min($totalEtapas - 0.08, $atual - 0.05)
                    Update-CustomProgress $global:progressVal
                }
            }
            elseif ($l -match '^##OK (.+)$')   { $t.Ok++;   Log ("  [OK]   " + $matches[1] + " instalado") }
            elseif ($l -match '^##JA (.+)$')   { $t.Ja++;   Log ("  [JA]   " + $matches[1] + " ja estava instalado") }
            elseif ($l -match '^##ERRO (.+)$') { $t.Erro++; Log ("  [ERRO] " + $matches[1]) }
            elseif ($l -match '^##INFO (.+)$') { Log ("         " + $matches[1]) }
        }
        $t.Lido = $linhas.Count
    }
    $timer.Add_Tick({
        $appElapsed = Format-ElapsedDuration ((Get-Date) - $global:appStartTime)
        if ($global:tasks.Count -gt 0) {
            $curElapsed = Format-ElapsedDuration ((Get-Date) - $global:tasks[0].Inicio)
            $lblRuntimeGtaFooter.Text = "Tempo: Tarefa $curElapsed | Total $appElapsed"
        } elseif ($global:lastTaskDuration) {
            $lblRuntimeGtaFooter.Text = "Tempo: Tarefa $($global:lastTaskDuration) | Total $appElapsed"
        } else {
            $lblRuntimeGtaFooter.Text = "Tempo: Tarefa 00m 00s | Total $appElapsed"
        }

        foreach ($t in @($global:tasks)) {
            Ler-Novas $t
            if ($t.Proc.HasExited) {
                Start-Sleep -Milliseconds 200; Ler-Novas $t
                $durStr = Format-ElapsedDuration ((Get-Date) - $t.Inicio)
                $global:lastTaskDuration = $durStr
                Log ("=== Fim: " + $t.Nome + " (" + $durStr + ") | instalados: " + $t.Ok + " | ja tinha: " + $t.Ja + " | erros: " + $t.Erro + " ===")
                Remove-Item -LiteralPath $t.Worker -Force -ErrorAction SilentlyContinue
                $global:tasks.Remove($t)
                if ($global:tasks.Count -gt 0) { $lblStatus.Text = "Em andamento: " + $global:tasks[0].Nome + " (" + $global:tasks.Count + " na fila)" }
                else {
                    $progressPulse.Visible = $false; $global:progressTarget = $global:progressMax; Update-CustomProgress $global:progressMax
                    if ($t.Erro -gt 0) { $lblStatus.Text = "Concluido com erros ($durStr) - veja o log"; $lblStatus.ForeColor = $cNeonPink; $progressBarFill.BackColor = $cNeonPink }
                    else { $lblStatus.Text = "Concluido com sucesso em $durStr!"; $lblStatus.ForeColor = $cNeonCyan; $progressBarFill.BackColor = $cNeonCyan }
                    if ($chkReiniciar.Checked) {
                        shutdown.exe /r /t 60 /c "Assistente de Formatacao: tarefas concluidas. Reiniciando em 60 segundos." | Out-Null
                        $resp = [System.Windows.Forms.MessageBox]::Show("Todas as tarefas terminaram.`n`nO computador vai reiniciar em 60 segundos.`n`nOK = Reiniciar agora`nCancelar = NAO reiniciar", "Reiniciar o computador", [System.Windows.Forms.MessageBoxButtons]::OKCancel, [System.Windows.Forms.MessageBoxIcon]::Warning)
                        if ($resp -eq [System.Windows.Forms.DialogResult]::Cancel) { shutdown.exe /a | Out-Null; Log "Reinicio cancelado pelo usuario." }
                        else { shutdown.exe /a | Out-Null; shutdown.exe /r /t 0 | Out-Null; $form.Close() }
                    }
                    if ($chkDesligar.Checked) {
                        shutdown.exe /s /t 60 /c "Assistente de Formatacao: tarefas concluidas. Desligando em 60 segundos." | Out-Null
                        $resp = [System.Windows.Forms.MessageBox]::Show("Todas as tarefas terminaram.`n`nO computador vai desligar em 60 segundos.`n`nOK = Desligar agora`nCancelar = NAO desligar", "Desligar o computador", [System.Windows.Forms.MessageBoxButtons]::OKCancel, [System.Windows.Forms.MessageBoxIcon]::Warning)
                        if ($resp -eq [System.Windows.Forms.DialogResult]::Cancel) { shutdown.exe /a | Out-Null; Log "Desligamento cancelado pelo usuario." }
                        else { shutdown.exe /a | Out-Null; shutdown.exe /s /t 0 | Out-Null; $form.Close() }
                    }
                    if ($chkSair.Checked) { Log "Sair ao concluir marcado: fechando a ferramenta..."; $form.Close() }
                }
            }
        }
    })
    $timer.Start()

    $sair = New-Object System.Windows.Forms.Button; $sair.Text = "Encerrar Ferramenta"; $sair.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold); $sair.Size = New-Object System.Drawing.Size(170, 38); $sair.Location = New-Object System.Drawing.Point(24, 644); $sair.FlatStyle = "Flat"; $sair.FlatAppearance.BorderSize = 0; $sair.BackColor = $cNeonPink; $sair.ForeColor = $cTextLight; $sair.Cursor = "Hand"; $sair.Add_Click({ $form.Close() }); $form.Controls.Add($sair)
    $chkSair = New-Object System.Windows.Forms.CheckBox; $chkSair.Text = "Sair ao concluir"; $chkSair.Font = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Bold); $chkSair.AutoSize = $true; $chkSair.Location = New-Object System.Drawing.Point(210, 665); $chkSair.ForeColor = $cTextMuted; $chkSair.Cursor = "Hand"; $chkSair.Add_CheckedChanged({ if ($chkSair.Checked) { $chkReiniciar.Checked = $false; $chkDesligar.Checked = $false } }); $form.Controls.Add($chkSair)
    $chkReiniciar = New-Object System.Windows.Forms.CheckBox; $chkReiniciar.Text = "Reiniciar ao concluir"; $chkReiniciar.Font = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Bold); $chkReiniciar.AutoSize = $true; $chkReiniciar.Location = New-Object System.Drawing.Point(210, 643); $chkReiniciar.ForeColor = $cSunsetOrg; $chkReiniciar.Cursor = "Hand"; $chkReiniciar.Add_CheckedChanged({ if ($chkReiniciar.Checked) { $chkSair.Checked = $false; $chkDesligar.Checked = $false } }); $form.Controls.Add($chkReiniciar)
    $chkDesligar = New-Object System.Windows.Forms.CheckBox; $chkDesligar.Text = "Desligar ao concluir"; $chkDesligar.Font = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Bold); $chkDesligar.AutoSize = $true; $chkDesligar.Location = New-Object System.Drawing.Point(370, 643); $chkDesligar.ForeColor = $cNeonPink; $chkDesligar.Cursor = "Hand"; $chkDesligar.Add_CheckedChanged({ if ($chkDesligar.Checked) { $chkSair.Checked = $false; $chkReiniciar.Checked = $false } }); $form.Controls.Add($chkDesligar)
    $watermark = New-Object System.Windows.Forms.Label; $watermark.Text = "Desenvolvido por: Elson (Criatividade E Tudo)"; $watermark.Font = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Bold); $watermark.ForeColor = $cTextMuted; $watermark.AutoSize = $true; $watermark.Location = New-Object System.Drawing.Point(510, 655); $form.Controls.Add($watermark)
    $lblRuntimeGtaFooter = New-Object System.Windows.Forms.Label; $lblRuntimeGtaFooter.Text = "Tempo: Tarefa 00m 00s | Total 00m 00s"; $lblRuntimeGtaFooter.Font = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Bold); $lblRuntimeGtaFooter.ForeColor = $cSunsetOrg; $lblRuntimeGtaFooter.AutoSize = $true; $lblRuntimeGtaFooter.Location = New-Object System.Drawing.Point(785, 655); $form.Controls.Add($lblRuntimeGtaFooter)
    $versaoLabel = New-Object System.Windows.Forms.Label; $versaoLabel.Text = "$VersaoAtual • GTA 6"; $versaoLabel.Font = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Bold); $versaoLabel.ForeColor = $cNeonCyan; $versaoLabel.AutoSize = $true; $versaoLabel.Location = New-Object System.Drawing.Point(1045, 655); $form.Controls.Add($versaoLabel)

    $form.Show(); Update-CustomScroll
    [System.Windows.Forms.Application]::Run($form)
    $netTimer.Stop(); $netTimer.Dispose(); $animTimer.Stop(); $animTimer.Dispose(); $timer.Stop(); $timer.Dispose(); $form.Dispose()

} else {
    Invoke-Expression $appInstallHelpers

    function Invoke-TaskBatchCLI {
        param([string]$Titulo, [array]$Passos)
        $batchStart = Get-Date
        Write-Host ""
        Write-Host "========================================================================" -ForegroundColor Cyan
        Write-Host "  INICIANDO: $Titulo" -ForegroundColor White
        Write-Host "========================================================================" -ForegroundColor Cyan

        $ok = 0; $ja = 0; $erro = 0; $total = $Passos.Count; $i = 0
        foreach ($p in $Passos) {
            $i++
            $stepStart = Get-Date
            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [$i/$total] Processando: $($p.Nome)..." -ForegroundColor Yellow
            $global:LASTEXITCODE = 0
            try { & $p.Cmd } catch { $global:LASTEXITCODE = 1 }
            $c = $global:LASTEXITCODE
            $stepTs = (Get-Date) - $stepStart
            $stepDur = if ($stepTs.TotalHours -ge 1) { "{0:00}h {1:00}m {2:00}s" -f [int][Math]::Floor($stepTs.TotalHours), $stepTs.Minutes, $stepTs.Seconds } else { "{0:00}m {1:00}s" -f $stepTs.Minutes, $stepTs.Seconds }
            if ($c -eq 0) { $ok++; Write-Host "[$(Get-Date -Format 'HH:mm:ss')]   [OK]   $($p.Nome) concluido! ($stepDur)" -ForegroundColor Green }
            elseif ($c -eq -1978335189) { $ja++; Write-Host "[$(Get-Date -Format 'HH:mm:ss')]   [JA]   $($p.Nome) ja estava instalado. ($stepDur)" -ForegroundColor Cyan }
            else { $erro++; Write-Host "[$(Get-Date -Format 'HH:mm:ss')]   [ERRO] $($p.Nome) falhou (codigo $c). ($stepDur)" -ForegroundColor Red }
        }
        $ts = (Get-Date) - $batchStart
        $dur = if ($ts.TotalHours -ge 1) { "{0:00}h {1:00}m {2:00}s" -f [int][Math]::Floor($ts.TotalHours), $ts.Minutes, $ts.Seconds } else { "{0:00}m {1:00}s" -f $ts.Minutes, $ts.Seconds }
        $sessTs = (Get-Date) - $global:cliStartTime
        $sessDur = if ($sessTs.TotalHours -ge 1) { "{0:00}h {1:00}m {2:00}s" -f [int][Math]::Floor($sessTs.TotalHours), $sessTs.Minutes, $sessTs.Seconds } else { "{0:00}m {1:00}s" -f $sessTs.Minutes, $sessTs.Seconds }
        Write-Host "------------------------------------------------------------------------" -ForegroundColor DarkGray
        Write-Host "  RESUMO ($Titulo): Tempo de execucao: $dur (Sessao: $sessDur) | Instalados: $ok | Ja tinha: $ja | Erros: $erro" -ForegroundColor White
        Write-Host "========================================================================" -ForegroundColor Cyan
        if ($global:ReiniciarAoConcluir) {
            shutdown.exe /r /t 60 /c "Assistente de Formatacao: tarefas concluidas. Reiniciando em 60 segundos." | Out-Null
            Write-Host "`nREINICIAR AO CONCLUIR: o computador vai reiniciar em 60 segundos!" -ForegroundColor Yellow
            $rr = (Read-Host "Digite C e ENTER para CANCELAR, ou apenas ENTER para reiniciar agora").Trim()
            if ($rr -match '^(?i)c') { shutdown.exe /a | Out-Null; Write-Host "Reinicio cancelado." -ForegroundColor Green; Start-Sleep -Seconds 2 }
            else { shutdown.exe /a | Out-Null; shutdown.exe /r /t 0 | Out-Null; exit }
        }
        if ($global:SairAoConcluir) { Write-Host "`nSair ao concluir ativado: fechando a ferramenta em 5 segundos..." -ForegroundColor Yellow; Start-Sleep -Seconds 5; exit }
        Read-Host "`nPressione ENTER para voltar ao menu"
    }

    function Get-NetworkLineCLI {
        try {
            $nics = [System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces() | Where-Object {
                $_.OperationalStatus -eq [System.Net.NetworkInformation.OperationalStatus]::Up -and
                $_.NetworkInterfaceType -ne [System.Net.NetworkInformation.NetworkInterfaceType]::Loopback -and
                $_.NetworkInterfaceType -ne [System.Net.NetworkInformation.NetworkInterfaceType]::Tunnel -and
                $_.Description -notmatch '(?i)Virtual|Hyper-V|VMware|VirtualBox|TAP-|VPN|Pseudo|Bluetooth'
            }
            $eth = $nics | Where-Object { $_.NetworkInterfaceType -eq [System.Net.NetworkInformation.NetworkInterfaceType]::Ethernet } | Select-Object -First 1
            $wifi = $nics | Where-Object { $_.NetworkInterfaceType -eq [System.Net.NetworkInformation.NetworkInterfaceType]::Wireless80211 } | Select-Object -First 1
            if ($eth) {
                $mbps = [Math]::Round($eth.Speed / 1000000)
                $spd = if ($mbps -ge 1000) { "$([Math]::Round($mbps / 1000, 1)) Gbps" } elseif ($mbps -gt 0) { "$mbps Mbps" } else { "Ativo" }
                return @{ Text = "CABO ETHERNET ($spd)"; Color = "Green" }
            } elseif ($wifi) { return @{ Text = "WI-FI ATIVO (Recomendado usar Cabo)"; Color = "Yellow" } }
        } catch {}
        return @{ Text = "SEM REDE / DESCONECTADO"; Color = "Red" }
    }

    $global:SairAoConcluir = $false
    $global:ReiniciarAoConcluir = $false
    $global:cliStartTime = Get-Date
    while ($true) {
        Clear-Host
        $net = Get-NetworkLineCLI
        $cliTs = (Get-Date) - $global:cliStartTime
        $cliTempo = if ($cliTs.TotalHours -ge 1) { "{0:00}h {1:00}m {2:00}s" -f [int][Math]::Floor($cliTs.TotalHours), $cliTs.Minutes, $cliTs.Seconds } else { "{0:00}m {1:00}s" -f $cliTs.Minutes, $cliTs.Seconds }
        Write-Host "========================================================================" -ForegroundColor Cyan
        Write-Host "   ASSISTENTE DE FORMATACAO LITE ($VersaoAtual - MODO CONSOLE)" -ForegroundColor White
        Write-Host "   Desenvolvido por: Elson (Criatividade E Tudo)" -ForegroundColor DarkGray
        Write-Host "========================================================================" -ForegroundColor Cyan
        Write-Host "   Status da Rede: " -NoNewline -ForegroundColor Gray; Write-Host $net.Text -ForegroundColor $net.Color
        Write-Host "   Tempo de execucao: " -NoNewline -ForegroundColor Gray; Write-Host $cliTempo -ForegroundColor Cyan
        Write-Host "------------------------------------------------------------------------" -ForegroundColor DarkGray
        Write-Host "   ACOES INDIVIDUAIS:" -ForegroundColor Cyan
        Write-Host "   [1A] AtivacaoWin  | [1B] AtivacaoOff [04] Instalar MSI Afterburner" -ForegroundColor White
        Write-Host "   [02] Instalar Google Chrome       [05] Instalar Adobe Reader" -ForegroundColor White
        Write-Host "   [03] Instalar WinRAR              [06] Instalar Apenas o Office" -ForegroundColor White
        Write-Host ""
        Write-Host "   PACOTES & MANUTENCAO:" -ForegroundColor Cyan
        Write-Host "   [07] Kit Gamer (Runtimes + GPU)   [10] INSTALAR TUDO + Office" -ForegroundColor Green
        Write-Host "   [08] TUDO (Sem MSI e sem Office)  [11] Atualizar Windows" -ForegroundColor White
        Write-Host "   [09] INSTALAR TUDO (Sem MSI)      [12] Atualizar Drivers" -ForegroundColor White
        Write-Host ""
        Write-Host "   PERSONALIZADOS:" -ForegroundColor Cyan
        Write-Host "   [13] Lojas de Jogos (Steam, Epic, GOG, EA, Ubisoft, Battle.net)" -ForegroundColor Yellow
        Write-Host "   [14] Instalacao Personalizada Total (Escolher itens por numero)" -ForegroundColor Yellow
        Write-Host "------------------------------------------------------------------------" -ForegroundColor DarkGray
        $estadoSair = if ($global:SairAoConcluir) { "[X] LIGADO" } else { "[ ] DESLIGADO" }
        Write-Host "   [99] Sair ao concluir: $estadoSair" -ForegroundColor $(if ($global:SairAoConcluir) { "Green" } else { "DarkGray" })
        $estadoRein = if ($global:ReiniciarAoConcluir) { "[X] LIGADO" } else { "[ ] DESLIGADO" }
        Write-Host "   [98] Reiniciar ao concluir: $estadoRein" -ForegroundColor $(if ($global:ReiniciarAoConcluir) { "Yellow" } else { "DarkGray" })
        Write-Host "   [00] Encerrar Ferramenta" -ForegroundColor Red
        Write-Host "========================================================================" -ForegroundColor Cyan
        $op = (Read-Host "`nDigite a opcao desejada e pressione ENTER").Trim()

        switch -Regex ($op) {
            '^(?i)0?1A$' {
                 Start-Process powershell -ArgumentList "-NoProfile -Command `"& ([ScriptBlock]::Create((irm https://get.activated.win))) `"" -WindowStyle Minimized -PassThru
            }
            '^(?i)0?1B$' {
                 Start-Process powershell -ArgumentList "-NoProfile -Command `"& ([ScriptBlock]::Create((irm https://get.activated.win))) /Ohook`"" -WindowStyle Minimized -PassThru
            }
            '^0?2$' { Invoke-TaskBatchCLI "Google Chrome" @(@{ Nome = "Google Chrome"; Cmd = { Install-AppFallback -Id "Google.Chrome" } }) }
            '^0?3$' { Invoke-TaskBatchCLI "WinRAR" @(@{ Nome = "WinRAR"; Cmd = { Install-AppFallback -Id "RARLab.WinRAR" } }) }
            '^0?4$' { Invoke-TaskBatchCLI "MSI Afterburner" @(@{ Nome = "MSI Afterburner"; Cmd = { Install-AppFallback -Id "Guru3D.Afterburner" } }) }
            '^0?5$' { Invoke-TaskBatchCLI "Adobe Acrobat Reader" @(@{ Nome = "Adobe Reader"; Cmd = { Install-AppFallback -Id "Adobe.Acrobat.Reader.64-bit" } }) }
            '^0?6$' { Invoke-TaskBatchCLI "Microsoft Office" @(@{ Nome = "Microsoft Office + Atalhos"; Cmd = { Install-OfficeDeployment } }) }
            '^0?7$' {
                Invoke-TaskBatchCLI "Kit Gamer Completo" @(
                    @{ Nome = "Plano Desempenho Maximo"; Cmd = { Install-GamerPowerPlan } },
                    @{ Nome = ".NET Framework 3.5"; Cmd = { Install-GamerNetFx3 } },
                    @{ Nome = ".NET Desktop Runtime 8"; Cmd = { Install-GamerDotNet8 } },
                    @{ Nome = "Visual C++ Redistributable"; Cmd = { Install-GamerVCRedist } },
                    @{ Nome = "DirectX Runtimes"; Cmd = { Install-GamerDirectX } },
                    @{ Nome = "Aplicativo Oficial da GPU"; Cmd = { Install-GamerGPUApp } }
                )
            }
            '^0?8$' {
                Invoke-TaskBatchCLI "TUDO (Sem MSI e sem Office)" @(
                    @{ Nome = "Google Chrome"; Cmd = { Install-AppFallback -Id "Google.Chrome" } },
                    @{ Nome = "Adobe Reader"; Cmd = { Install-AppFallback -Id "Adobe.Acrobat.Reader.64-bit" } },
                    @{ Nome = "WinRAR"; Cmd = { Install-AppFallback -Id "RARLab.WinRAR" } }
                )
            }
            '^0?9$' {
                Invoke-TaskBatchCLI "INSTALAR TUDO (Sem MSI)" @(
                    @{ Nome = "Google Chrome"; Cmd = { Install-AppFallback -Id "Google.Chrome" } },
                    @{ Nome = "Adobe Reader"; Cmd = { Install-AppFallback -Id "Adobe.Acrobat.Reader.64-bit" } },
                    @{ Nome = "WinRAR"; Cmd = { Install-AppFallback -Id "RARLab.WinRAR" } },
                    @{ Nome = "Microsoft Office + Atalhos"; Cmd = { Install-OfficeDeployment } }
                )
            }
            '^10$' {
                Invoke-TaskBatchCLI "INSTALAR TUDO + Office" @(
                    @{ Nome = "Google Chrome"; Cmd = { Install-AppFallback -Id "Google.Chrome" } },
                    @{ Nome = "Adobe Reader"; Cmd = { Install-AppFallback -Id "Adobe.Acrobat.Reader.64-bit" } },
                    @{ Nome = "WinRAR"; Cmd = { Install-AppFallback -Id "RARLab.WinRAR" } },
                    @{ Nome = "MSI Afterburner"; Cmd = { Install-AppFallback -Id "Guru3D.Afterburner" } },
                    @{ Nome = "Microsoft Office + Atalhos"; Cmd = { Install-OfficeDeployment } }
                )
            }
            '^11$' { Invoke-TaskBatchCLI "Atualizar Windows" @(@{ Nome = "Windows Update"; Cmd = { Invoke-WindowsUpdate } }) }
            '^12$' { Invoke-TaskBatchCLI "Atualizar Drivers" @(@{ Nome = "Drivers Update"; Cmd = { Invoke-DriverUpdate } }) }
            '^13$' {
                Clear-Host
                $lojas = @(
                    @{ Num = 1; Nome = "Steam"; Id = "Valve.Steam" }, @{ Num = 2; Nome = "Epic Games Store"; Id = "EpicGames.EpicGamesLauncher" },
                    @{ Num = 3; Nome = "GOG Galaxy"; Id = "GOG.Galaxy" }, @{ Num = 4; Nome = "EA App"; Id = "ElectronicArts.EAApp" },
                    @{ Num = 5; Nome = "Ubisoft Connect"; Id = "Ubisoft.Connect" }, @{ Num = 6; Nome = "Battle.net"; Id = "Blizzard.BattleNet" }
                )
                Write-Host "========================================================================" -ForegroundColor Cyan
                Write-Host "   LOJAS DE JOGOS ($VersaoAtual) - SEPARE OS NUMEROS POR VIRGULA OU ESPACO" -ForegroundColor White
                Write-Host "========================================================================" -ForegroundColor Cyan
                foreach ($l in $lojas) { Write-Host ("   [{0}] {1}" -f $l.Num, $l.Nome) -ForegroundColor White }
                Write-Host "   [T] Todas as Lojas   |   [0] Voltar" -ForegroundColor Yellow
                $sel = (Read-Host "`nEscolha (ex: 1, 2, 6)").Trim()
                if ($sel -ne '0' -and $sel -ne '') {
                    $fila = @()
                    if ($sel -match '^(?i)T$') {
                        foreach ($l in $lojas) { $idC = $l.Id; $fila += @{ Nome = $l.Nome; Cmd = { Install-AppFallback -Id $idC }.GetNewClosure() } }
                    } else {
                        foreach ($n in ($sel -split '[,\s;]+' | Where-Object { $_ -match '^\d+$' } | Select-Object -Unique)) {
                            $it = $lojas | Where-Object { $_.Num -eq [int]$n } | Select-Object -First 1
                            if ($it) { $idC = $it.Id; $fila += @{ Nome = $it.Nome; Cmd = { Install-AppFallback -Id $idC }.GetNewClosure() } }
                        }
                    }
                    if ($fila.Count -gt 0) { Invoke-TaskBatchCLI "Lojas de Jogos ($($fila.Count))" $fila }
                }
            }
            '^14$' {
                Clear-Host
                $itensPers = @(
                    @{ Num = 1;  Nome = "Google Chrome"; Cmd = { Install-AppFallback -Id "Google.Chrome" } },
                    @{ Num = 2;  Nome = "WinRAR"; Cmd = { Install-AppFallback -Id "RARLab.WinRAR" } },
                    @{ Num = 3;  Nome = "MSI Afterburner"; Cmd = { Install-AppFallback -Id "Guru3D.Afterburner" } },
                    @{ Num = 4;  Nome = "Adobe Acrobat Reader"; Cmd = { Install-AppFallback -Id "Adobe.Acrobat.Reader.64-bit" } },
                    @{ Num = 5;  Nome = "Microsoft Office"; Cmd = { Install-OfficeDeployment } },
                    @{ Num = 6;  Nome = "Desempenho Maximo"; Cmd = { Install-GamerPowerPlan } },
                    @{ Num = 7;  Nome = ".NET Framework 3.5"; Cmd = { Install-GamerNetFx3 } },
                    @{ Num = 8;  Nome = ".NET Desktop Runtime 8"; Cmd = { Install-GamerDotNet8 } },
                    @{ Num = 9;  Nome = "Visual C++ Redist."; Cmd = { Install-GamerVCRedist } },
                    @{ Num = 10; Nome = "DirectX Runtimes"; Cmd = { Install-GamerDirectX } },
                    @{ Num = 11; Nome = "App Oficial da GPU"; Cmd = { Install-GamerGPUApp } },
                    @{ Num = 12; Nome = "Steam"; Cmd = { Install-AppFallback -Id "Valve.Steam" } },
                    @{ Num = 13; Nome = "Epic Games Store"; Cmd = { Install-AppFallback -Id "EpicGames.EpicGamesLauncher" } },
                    @{ Num = 14; Nome = "GOG Galaxy"; Cmd = { Install-AppFallback -Id "GOG.Galaxy" } },
                    @{ Num = 15; Nome = "EA App"; Cmd = { Install-AppFallback -Id "ElectronicArts.EAApp" } },
                    @{ Num = 16; Nome = "Ubisoft Connect"; Cmd = { Install-AppFallback -Id "Ubisoft.Connect" } },
                    @{ Num = 17; Nome = "Battle.net"; Cmd = { Install-AppFallback -Id "Blizzard.BattleNet" } },
                    @{ Num = 18; Nome = "Atualizar Windows"; Cmd = { Invoke-WindowsUpdate } },
                    @{ Num = 19; Nome = "Atualizar Drivers"; Cmd = { Invoke-DriverUpdate } }
                )
                Write-Host "========================================================================" -ForegroundColor Cyan
                Write-Host "   INSTALACAO PERSONALIZADA TOTAL ($VersaoAtual)" -ForegroundColor White
                Write-Host "========================================================================" -ForegroundColor Cyan
                for ($idx = 0; $idx -lt 10; $idx++) {
                    $leftStr = ("[{0:D2}] {1}" -f $itensPers[$idx].Num, $itensPers[$idx].Nome).PadRight(36)
                    $rightStr = if (($idx + 10) -lt $itensPers.Count) { "[{0:D2}] {1}" -f $itensPers[$idx + 10].Num, $itensPers[$idx + 10].Nome } else { "" }
                    Write-Host "   $leftStr $rightStr" -ForegroundColor White
                }
                Write-Host "   [00] Voltar ao Menu Principal" -ForegroundColor Red
                $selPC = (Read-Host "`nDigite os numeros desejados (ex: 1 2 4 5)").Trim()
                if ($selPC -ne '0' -and $selPC -ne '00' -and $selPC -ne '') {
                    $filaP = @()
                    foreach ($n in ($selPC -split '[,\s;]+' | Where-Object { $_ -match '^\d+$' } | Select-Object -Unique)) {
                        $it = $itensPers | Where-Object { $_.Num -eq [int]$n } | Select-Object -First 1
                        if ($it) { $filaP += @{ Nome = $it.Nome; Cmd = $it.Cmd } }
                    }
                    if ($filaP.Count -gt 0) { Invoke-TaskBatchCLI "Personalizada ($($filaP.Count) itens)" $filaP }
                }
            }
            '^98$' { $global:ReiniciarAoConcluir = -not $global:ReiniciarAoConcluir }
            '^99$' { $global:SairAoConcluir = -not $global:SairAoConcluir }
            '^0?0$' { exit }
            default { Write-Host "Opcao invalida!" -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    }
}
#PSEND
