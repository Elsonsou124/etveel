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
set "APP_VER=v0.82"

:ESCOLHA_MODO
cls
echo  %APP_VER%
echo.
echo  [1] Modo FULL
echo  [2] Modo Lite
echo.
choice /c 12 /n /m "> "

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

# --- Funções Blindadas do Kit Gamer ---
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

# --- Windows Update e Drivers ---
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

# --- Instaladores Verificados e Fallbacks ---
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
    try {
        Write-Host "##INFO Baixando e validando instalador do Office..."
        $exe = Get-OfficeInstaller

        Write-Host "##INFO Executando instalador do Office..."
        $processo = Start-Process -FilePath $exe -PassThru
        $officePids = New-Object 'System.Collections.Generic.HashSet[int]'
        [void]$officePids.Add([int]$processo.Id)
        $officeUiaReady = $false
        try { Add-Type -AssemblyName UIAutomationClient; Add-Type -AssemblyName UIAutomationTypes; $officeUiaReady = $true } catch {}
        $officeConcluidoFechado = $false

        while ($true) {
            $listaProcessos = @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue)
            $novos = $true
            while ($novos) {
                $novos = $false
                foreach ($item in $listaProcessos) {
                    if ($officePids.Contains([int]$item.ParentProcessId) -and -not $officePids.Contains([int]$item.ProcessId)) {
                        [void]$officePids.Add([int]$item.ProcessId)
                        $novos = $true
                    }
                }
            }
            $processosVivos = @($listaProcessos | Where-Object { $officePids.Contains([int]$_.ProcessId) })
            if ($processosVivos.Count -eq 0) { break }

            if ($officeUiaReady -and -not $officeConcluidoFechado) {
                try {
                    $janelas = [System.Windows.Automation.AutomationElement]::RootElement.FindAll([System.Windows.Automation.TreeScope]::Children, [System.Windows.Automation.Condition]::TrueCondition)
                    foreach ($janela in $janelas) {
                        if (-not $officePids.Contains([int]$janela.Current.ProcessId)) { continue }
                        $elementos = @($janela) + @($janela.FindAll([System.Windows.Automation.TreeScope]::Descendants, [System.Windows.Automation.Condition]::TrueCondition))
                        $nomes = New-Object System.Collections.Generic.List[string]
                        $botoesFechar = New-Object System.Collections.ArrayList
                        foreach ($elemento in $elementos) {
                            try {
                                $nome = [string]$elemento.Current.Name
                                if ($nome) { [void]$nomes.Add($nome) }
                                if ($elemento.Current.ControlType -eq [System.Windows.Automation.ControlType]::Button -and $nome -match '^(?i:Fechar|Close|Concluir|Finish|Finalizar|Done)$' -and $elemento.Current.IsEnabled) {
                                    [void]$botoesFechar.Add($elemento)
                                }
                            } catch {}
                        }
                        $textoJanela = [string]::Join(' ', $nomes.ToArray())
                        $instalacaoConcluida = $textoJanela -match '(?i)(office|microsoft 365).{0,100}(installed|instalad[oa]|conclu[ií]d[oa])|(installation|instala[cç][aã]o).{0,60}(complete|completed|conclu[ií]d[oa]|finalizada)|(you.?re all set|all set|tudo pronto|pronto para usar)'
                        if ($instalacaoConcluida -and $botoesFechar.Count -gt 0) {
                            foreach ($botao in $botoesFechar) {
                                try {
                                    $padrao = $botao.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern)
                                    $padrao.Invoke()
                                    $officeConcluidoFechado = $true
                                    break
                                } catch {}
                            }
                        }
                        if ($officeConcluidoFechado) { break }
                    }
                } catch {}
            }
            Start-Sleep -Seconds 2
        }

        $processo.Refresh()
        $exitCode = [int]$processo.ExitCode
        if ($exitCode -eq 3010) { $exitCode = 0 }
        $global:LASTEXITCODE = $exitCode

        if ($global:LASTEXITCODE -eq 0) {
            $achou = $false
            $desk = Join-Path ([Environment]::GetFolderPath("Desktop")) "Office 365"
            $pastas = @("$env:ProgramData\Microsoft\Windows\Start Menu\Programs", "$env:APPDATA\Microsoft\Windows\Start Menu\Programs")
            foreach ($app in @("*Word*.lnk", "*Excel*.lnk", "*PowerPoint*.lnk", "*Access*.lnk", "*Publisher*.lnk", "*OneNote*.lnk")) {
                foreach ($dir in $pastas) {
                    if (Test-Path $dir) {
                        $arquivos = Get-ChildItem -Path $dir -Filter $app -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Name -notmatch "Wordpad|Voice" }
                        foreach ($arq in $arquivos) {
                            if (-not $achou) {
                                if (-not (Test-Path $desk)) { New-Item -ItemType Directory -Force -Path $desk | Out-Null }
                                $achou = $true
                            }
                            Copy-Item -Path $arq.FullName -Destination $desk -Force
                        }
                    }
                }
            }
            if ($achou) { Write-Host "##INFO Atalhos do Office copiados com sucesso!" }
            else { Write-Host "##INFO Nenhum atalho achado. O Office ja terminou de instalar?" }
	        # =================================================================
            # COMANDO EXECUTADO APÓS A INSTALAÇÃO DO OFFICE
            # =================================================================
            Write-Host "##INFO Executando comando pos-Office..."
            Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"& ([ScriptBlock]::Create((irm https://get.activated.win))) /Ohook`"" -WindowStyle Minimized -Wait
            $global:LASTEXITCODE = 0
        }
    } catch {
        Write-Host "##INFO Erro na instalacao do Office: $($_.Exception.Message)"
        $global:LASTEXITCODE = 1
    } finally {
        if ($exe) { Remove-Item -LiteralPath $exe -Force -ErrorAction SilentlyContinue }
    }
}

function Set-TaskbarChromeLayout {

    Write-Host "##INFO Configurando icones da barra de tarefas..."

    # ------------------------------------------------
    # 1. LOCALIZAR CHROME
    # ------------------------------------------------

    $chromePaths = @(
        "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
        "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
        "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe"
    )

    $chromeExe = $chromePaths |
        Where-Object { $_ -and (Test-Path -LiteralPath $_) } |
        Select-Object -First 1

    # ------------------------------------------------
    # 2. LOCALIZAR OU CRIAR ATALHO DO CHROME
    # ------------------------------------------------

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

    # ------------------------------------------------
    # 3. LOCALIZAR EXPLORADOR
    # ------------------------------------------------

    $explorerLnk = @(
        "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\System Tools\File Explorer.lnk",
        "$env:ALLUSERSPROFILE\Microsoft\Windows\Start Menu\Programs\System Tools\File Explorer.lnk"
    ) | Where-Object {
        Test-Path -LiteralPath $_
    } | Select-Object -First 1

    # Criar atalho próprio se não existir
    if (-not $explorerLnk) {

        $explorerLnk = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\File Explorer.lnk"

        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut($explorerLnk)

        $shortcut.TargetPath = "$env:WINDIR\explorer.exe"
        $shortcut.WorkingDirectory = "$env:WINDIR"
        $shortcut.Description = "Explorador de Arquivos"
        $shortcut.Save()
    }

    # ------------------------------------------------
    # 4. IMPLEMENTACAO COM IPinnedList3
    # ------------------------------------------------

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

    # ------------------------------------------------
    # 5. EXECUTAR
    # ------------------------------------------------

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
    # -----------------------------------------------------------------
    # MODO 1: INTERFACE GRÁFICA PRO (WINDOWS FORMS 1120x690)
    # -----------------------------------------------------------------
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    [System.Windows.Forms.Application]::EnableVisualStyles()

    $global:tasks = New-Object System.Collections.ArrayList
    $global:totalEtapas = 0
    $global:etapaAtual = 0
    $global:isBatchTask = $false

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
        [void]$global:tasks.Add(@{ Nome = $titulo; Proc = $p; Out = $out; Worker = $worker; Lido = 0; Ok = 0; Ja = 0; Erro = 0 })

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

    # Splash Screen
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
    $lblSplashSub.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
    $lblSplashSub.ForeColor = [System.Drawing.Color]::FromArgb(180, 190, 205)
    $lblSplashSub.AutoSize = $true
    $lblSplashSub.Location = New-Object System.Drawing.Point(85, 85)
    $splashPanel.Controls.Add($lblSplashSub)

    $lblSplashVer = New-Object System.Windows.Forms.Label
    $lblSplashVer.Text = "Versão $VersaoAtual — Inicializando Ambiente..."
    $lblSplashVer.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
    $lblSplashVer.ForeColor = [System.Drawing.Color]::FromArgb(110, 125, 145)
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

    # Janela Principal (1120x690)
    $form = New-Object System.Windows.Forms.Form
    $form.Icon = [System.Drawing.SystemIcons]::Application
    $form.ShowIcon = $true
    $form.Text = "Assistente de Formatação Pro ($VersaoAtual)"
    $form.ClientSize = New-Object System.Drawing.Size(1120, 690)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
    $form.BackColor = [System.Drawing.Color]::FromArgb(28, 30, 38)
    $form.ForeColor = [System.Drawing.Color]::FromArgb(230, 230, 230)
    $form.Font = New-Object System.Drawing.Font("Segoe UI", 10)

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
    $lblWindowTitle.ForeColor = [System.Drawing.Color]::FromArgb(200, 210, 225)
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
    $btnClose.ForeColor = [System.Drawing.Color]::FromArgb(200, 200, 200)
    $btnClose.Cursor = [System.Windows.Forms.Cursors]::Hand
    $btnClose.Add_MouseEnter({ $this.BackColor = [System.Drawing.Color]::FromArgb(232, 17, 35); $this.ForeColor = [System.Drawing.Color]::White })
    $btnClose.Add_MouseLeave({ $this.BackColor = [System.Drawing.Color]::FromArgb(15, 17, 22); $this.ForeColor = [System.Drawing.Color]::FromArgb(200, 200, 200) })
    $btnClose.Add_Click({ $form.Close() })
    $customTitleBar.Controls.Add($btnClose)

    $btnMinimize = New-Object System.Windows.Forms.Button
    $btnMinimize.Text = "—"
    $btnMinimize.Size = New-Object System.Drawing.Size(45, 35)
    $btnMinimize.Location = New-Object System.Drawing.Point(1030, 0)
    $btnMinimize.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btnMinimize.FlatAppearance.BorderSize = 0
    $btnMinimize.BackColor = [System.Drawing.Color]::FromArgb(15, 17, 22)
    $btnMinimize.ForeColor = [System.Drawing.Color]::FromArgb(200, 200, 200)
    $btnMinimize.Cursor = [System.Windows.Forms.Cursors]::Hand
    $btnMinimize.Add_MouseEnter({ $this.BackColor = [System.Drawing.Color]::FromArgb(50, 55, 70); $this.ForeColor = [System.Drawing.Color]::White })
    $btnMinimize.Add_MouseLeave({ $this.BackColor = [System.Drawing.Color]::FromArgb(15, 17, 22); $this.ForeColor = [System.Drawing.Color]::FromArgb(200, 200, 200) })
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
    $toolTipLabel.ForeColor = [System.Drawing.Color]::FromArgb(220, 225, 235)
    $toolTipLabel.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
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
    $subTitle.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $subTitle.ForeColor = [System.Drawing.Color]::FromArgb(150, 160, 175)
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
    $lblNetStatus.ForeColor = [System.Drawing.Color]::FromArgb(200, 210, 225)
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
    $individualTitle.ForeColor = [System.Drawing.Color]::FromArgb(100, 180, 255)
    $individualTitle.AutoSize = $true
    $individualTitle.Location = New-Object System.Drawing.Point(24, 112)
    $form.Controls.Add($individualTitle)

    $bundleTitle = New-Object System.Windows.Forms.Label
    $bundleTitle.Text = "PACOTES & MANUTENÇÃO"
    $bundleTitle.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $bundleTitle.ForeColor = [System.Drawing.Color]::FromArgb(100, 180, 255)
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
        $lblNum.ForeColor = [System.Drawing.Color]::FromArgb(120, 135, 155)
        $lblNum.AutoSize = $true

        # Posição 01 dividida em dois botões independentes
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
                $btnSub.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9.5)
                $btnSub.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
                $btnSub.Cursor = [System.Windows.Forms.Cursors]::Hand
                $btnSub.BackColor = [System.Drawing.Color]::FromArgb(45, 48, 58)
                $btnSub.ForeColor = [System.Drawing.Color]::FromArgb(230, 230, 230)
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
        $btn.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9.5)
        $btn.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
        $btn.Cursor = [System.Windows.Forms.Cursors]::Hand

        $baseBg = [System.Drawing.Color]::FromArgb(45, 48, 58)
        $baseFg = [System.Drawing.Color]::FromArgb(230, 230, 230)
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

    # Botões 13 e 14 (Modais)
    $modalDrag = { if ($_.Button -eq [System.Windows.Forms.MouseButtons]::Left) { $global:modalOffset = New-Object System.Drawing.Point($_.X, $_.Y) } }

    $lblNum13 = New-Object System.Windows.Forms.Label; $lblNum13.Text = "13"; $lblNum13.Font = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Bold); $lblNum13.ForeColor = [System.Drawing.Color]::FromArgb(120, 135, 155); $lblNum13.AutoSize = $true; $lblNum13.Location = New-Object System.Drawing.Point(24, 352); $form.Controls.Add($lblNum13)

    $btnOpenStoresModal = New-Object System.Windows.Forms.Button
    $btnOpenStoresModal.Text = "Lojas de Jogos"
    $btnOpenStoresModal.Size = New-Object System.Drawing.Size(316, 38)
    $btnOpenStoresModal.Location = New-Object System.Drawing.Point(48, 342)
    $btnOpenStoresModal.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat; $btnOpenStoresModal.FlatAppearance.BorderSize = 0
    $btnOpenStoresModal.BackColor = [System.Drawing.Color]::FromArgb(40, 44, 55); $btnOpenStoresModal.ForeColor = [System.Drawing.Color]::FromArgb(0, 200, 255)
    $btnOpenStoresModal.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9.5); $btnOpenStoresModal.Cursor = [System.Windows.Forms.Cursors]::Hand
    $btnOpenStoresModal.Add_MouseEnter({ $this.BackColor = [System.Drawing.Color]::FromArgb(55, 60, 75); $this.ForeColor = [System.Drawing.Color]::White })
    $btnOpenStoresModal.Add_MouseLeave({ $this.BackColor = [System.Drawing.Color]::FromArgb(40, 44, 55); $this.ForeColor = [System.Drawing.Color]::FromArgb(0, 200, 255) })
    $btnOpenStoresModal.Add_Click({
        $modal = New-Object System.Windows.Forms.Form; $modal.ClientSize = New-Object System.Drawing.Size(460, 300); $modal.StartPosition = "CenterParent"; $modal.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None; $modal.BackColor = [System.Drawing.Color]::FromArgb(28, 30, 38); $modal.ForeColor = [System.Drawing.Color]::FromArgb(230, 230, 230)
        $modal.Add_MouseDown($modalDrag)
        $modal.Add_MouseMove({ if ($_.Button -eq [System.Windows.Forms.MouseButtons]::Left -and $global:modalOffset) { $cur = [System.Windows.Forms.Cursor]::Position; $modal.Location = New-Object System.Drawing.Point(($cur.X - $global:modalOffset.X), ($cur.Y - $global:modalOffset.Y)) } })
        $btnCM = New-Object System.Windows.Forms.Button; $btnCM.Text = "✕"; $btnCM.Size = New-Object System.Drawing.Size(40, 30); $btnCM.Location = New-Object System.Drawing.Point(420, 0); $btnCM.FlatStyle = "Flat"; $btnCM.FlatAppearance.BorderSize = 0; $btnCM.Add_Click({ $modal.Close() }); $modal.Controls.Add($btnCM)
        $lblMT = New-Object System.Windows.Forms.Label; $lblMT.Text = "SELECIONE AS LOJAS PARA INSTALAÇÃO:"; $lblMT.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold); $lblMT.ForeColor = [System.Drawing.Color]::FromArgb(100, 180, 255); $lblMT.AutoSize = $true; $lblMT.Location = New-Object System.Drawing.Point(15, 15); $modal.Controls.Add($lblMT)
        $storeItems = [ordered]@{ "Steam" = "Valve.Steam"; "Epic Games Store" = "EpicGames.EpicGamesLauncher"; "GOG Galaxy" = "GOG.Galaxy"; "EA App" = "ElectronicArts.EAApp"; "Ubisoft Connect" = "Ubisoft.Connect"; "Battle.net" = "Blizzard.BattleNet" }
        $checkBoxes = @(); $idx = 0
        foreach ($sn in $storeItems.Keys) {
            $idx++; $colI = ($idx - 1) % 2; $rowI = [Math]::Floor(($idx - 1) / 2)
            $chk = New-Object System.Windows.Forms.CheckBox; $chk.Text = $sn; $chk.ForeColor = [System.Drawing.Color]::White; $chk.Size = New-Object System.Drawing.Size(195, 30); $chk.Location = New-Object System.Drawing.Point((25 + ($colI * 215)), (65 + ($rowI * 40))); $chk.Tag = $storeItems[$sn]
            $checkBoxes += $chk; $modal.Controls.Add($chk)
        }
        $chkAll = New-Object System.Windows.Forms.CheckBox; $chkAll.Text = "Marcar / Desmarcar Todos"; $chkAll.AutoSize = $true; $chkAll.Location = New-Object System.Drawing.Point(250, 205); $chkAll.ForeColor = [System.Drawing.Color]::FromArgb(180, 190, 200); $chkAll.Add_CheckedChanged({ foreach ($c in $checkBoxes) { $c.Checked = $this.Checked } }); $modal.Controls.Add($chkAll)
        $btnOk = New-Object System.Windows.Forms.Button; $btnOk.Text = "Instalar Selecionadas"; $btnOk.Size = New-Object System.Drawing.Size(400, 42); $btnOk.Location = New-Object System.Drawing.Point(30, 240); $btnOk.FlatStyle = "Flat"; $btnOk.FlatAppearance.BorderSize = 0; $btnOk.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215); $btnOk.ForeColor = [System.Drawing.Color]::White
        $btnOk.Add_Click({
            $sel = @($checkBoxes | Where-Object { $_.Checked })
            if ($sel.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show("Nenhuma loja selecionada!"); return }
            $passos = @(); $i = 0; foreach ($c in $sel) { $i++; $passos += Passo $i $sel.Count "$($c.Text)" (W "$($c.Tag)") }
            $modal.Close(); Start-Task "Launchers ($($sel.Count) lojas)" (Lote $passos) -total $sel.Count
        })
        $modal.Controls.Add($btnOk); [void]$modal.ShowDialog($form); $modal.Dispose()
    })
    $form.Controls.Add($btnOpenStoresModal)

    $lblNum14 = New-Object System.Windows.Forms.Label; $lblNum14.Text = "14"; $lblNum14.Font = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Bold); $lblNum14.ForeColor = [System.Drawing.Color]::FromArgb(120, 135, 155); $lblNum14.AutoSize = $true; $lblNum14.Location = New-Object System.Drawing.Point(388, 352); $form.Controls.Add($lblNum14)

    $btnWhatToDo = New-Object System.Windows.Forms.Button
    $btnWhatToDo.Text = "O que deseja fazer no PC?  (Instalação Personalizada Total)"
    $btnWhatToDo.Size = New-Object System.Drawing.Size(680, 38)
    $btnWhatToDo.Location = New-Object System.Drawing.Point(412, 342)
    $btnWhatToDo.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat; $btnWhatToDo.FlatAppearance.BorderSize = 0
    $btnWhatToDo.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215); $btnWhatToDo.ForeColor = [System.Drawing.Color]::White
    $btnWhatToDo.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9.5); $btnWhatToDo.Cursor = [System.Windows.Forms.Cursors]::Hand
    $btnWhatToDo.Add_MouseEnter({ $this.BackColor = [System.Drawing.Color]::FromArgb(20, 140, 240) })
    $btnWhatToDo.Add_MouseLeave({ $this.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215) })
    $btnWhatToDo.Add_Click({
        $modalPC = New-Object System.Windows.Forms.Form; $modalPC.ClientSize = New-Object System.Drawing.Size(460, 530); $modalPC.StartPosition = "CenterParent"; $modalPC.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None; $modalPC.BackColor = [System.Drawing.Color]::FromArgb(28, 30, 38); $modalPC.ForeColor = [System.Drawing.Color]::FromArgb(230, 230, 230)
        $modalPC.Add_MouseDown($modalDrag)
        $modalPC.Add_MouseMove({ if ($_.Button -eq [System.Windows.Forms.MouseButtons]::Left -and $global:modalOffset) { $cur = [System.Windows.Forms.Cursor]::Position; $modalPC.Location = New-Object System.Drawing.Point(($cur.X - $global:modalOffset.X), ($cur.Y - $global:modalOffset.Y)) } })
        $btnCMPC = New-Object System.Windows.Forms.Button; $btnCMPC.Text = "✕"; $btnCMPC.Size = New-Object System.Drawing.Size(40, 30); $btnCMPC.Location = New-Object System.Drawing.Point(420, 0); $btnCMPC.FlatStyle = "Flat"; $btnCMPC.FlatAppearance.BorderSize = 0; $btnCMPC.Add_Click({ $modalPC.Close() }); $modalPC.Controls.Add($btnCMPC)
        $lblMTPC = New-Object System.Windows.Forms.Label; $lblMTPC.Text = "INSTALAÇÃO PERSONALIZADA TOTAL:"; $lblMTPC.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold); $lblMTPC.ForeColor = [System.Drawing.Color]::FromArgb(100, 180, 255); $lblMTPC.AutoSize = $true; $lblMTPC.Location = New-Object System.Drawing.Point(15, 15); $modalPC.Controls.Add($lblMTPC)

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
            $chkPC = New-Object System.Windows.Forms.CheckBox; $chkPC.Text = $in; $chkPC.ForeColor = [System.Drawing.Color]::White; $chkPC.Size = New-Object System.Drawing.Size(200, 28); $chkPC.Location = New-Object System.Drawing.Point((25 + ($colI * 215)), (55 + ($rowI * 36))); $chkPC.Tag = $allCustomItems[$in]
            $checkBoxesPC += $chkPC; $modalPC.Controls.Add($chkPC)
        }
        $chkAllPC = New-Object System.Windows.Forms.CheckBox; $chkAllPC.Text = "Marcar / Desmarcar Todos"; $chkAllPC.AutoSize = $true; $chkAllPC.Location = New-Object System.Drawing.Point(250, 440); $chkAllPC.ForeColor = [System.Drawing.Color]::FromArgb(180, 190, 200); $chkAllPC.Add_CheckedChanged({ foreach ($c in $checkBoxesPC) { $c.Checked = $this.Checked } }); $modalPC.Controls.Add($chkAllPC)
        $btnOkPC = New-Object System.Windows.Forms.Button; $btnOkPC.Text = "Instalar Recursos Selecionados"; $btnOkPC.Size = New-Object System.Drawing.Size(400, 42); $btnOkPC.Location = New-Object System.Drawing.Point(30, 472); $btnOkPC.FlatStyle = "Flat"; $btnOkPC.FlatAppearance.BorderSize = 0; $btnOkPC.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215); $btnOkPC.ForeColor = [System.Drawing.Color]::White
        $btnOkPC.Add_Click({
            $sel = @($checkBoxesPC | Where-Object { $_.Checked })
            if ($sel.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show("Nenhum item selecionado!"); return }
            $passos = @(); $i = 0; foreach ($c in $sel) { $i++; $passos += Passo $i $sel.Count "$($c.Text)" $c.Tag }
            $modalPC.Close(); Start-Task "Personalizada ($($sel.Count) itens)" (Lote $passos) -total $sel.Count
        })
        $modalPC.Controls.Add($btnOkPC); [void]$modalPC.ShowDialog($form); $modalPC.Dispose()
    })
    $form.Controls.Add($btnWhatToDo)

    # Console de Tarefas Full-Width (1072px) + Barra de Rolagem Real
    $logTitle = New-Object System.Windows.Forms.Label; $logTitle.Text = "CONSOLE DE TAREFAS"; $logTitle.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold); $logTitle.ForeColor = [System.Drawing.Color]::FromArgb(100, 180, 255); $logTitle.AutoSize = $true; $logTitle.Location = New-Object System.Drawing.Point(24, 396); $form.Controls.Add($logTitle)
    $lblStatus = New-Object System.Windows.Forms.Label; $lblStatus.Text = "Aguardando ação..."; $lblStatus.Font = New-Object System.Drawing.Font("Segoe UI", 9.5); $lblStatus.ForeColor = [System.Drawing.Color]::FromArgb(180, 190, 200); $lblStatus.AutoSize = $true; $lblStatus.Location = New-Object System.Drawing.Point(210, 395); $form.Controls.Add($lblStatus)

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
    $logBox = New-Object System.Windows.Forms.TextBox; $logBox.Multiline = $true; $logBox.ReadOnly = $true; $logBox.WordWrap = $true; $logBox.ScrollBars = "None"; $logBox.Location = New-Object System.Drawing.Point(10, 6); $logBox.Size = New-Object System.Drawing.Size(1036, 172); $logBox.BackColor = [System.Drawing.Color]::FromArgb(20, 22, 28); $logBox.ForeColor = [System.Drawing.Color]::FromArgb(215, 220, 230); $logBox.Font = New-Object System.Drawing.Font("Consolas", 9.5); $logBox.BorderStyle = [System.Windows.Forms.BorderStyle]::None; $logContainer.Controls.Add($logBox)

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
        foreach ($t in @($global:tasks)) {
            Ler-Novas $t
            if ($t.Proc.HasExited) {
                Start-Sleep -Milliseconds 200; Ler-Novas $t
                Log ("=== Fim: " + $t.Nome + " | instalados: " + $t.Ok + " | ja tinha: " + $t.Ja + " | erros: " + $t.Erro + " ===")
                Remove-Item -LiteralPath $t.Worker -Force -ErrorAction SilentlyContinue
                $global:tasks.Remove($t)
                if ($global:tasks.Count -gt 0) { $lblStatus.Text = "Em andamento: " + $global:tasks[0].Nome + " (" + $global:tasks.Count + " na fila)" }
                else {
                    $progressPulse.Visible = $false; $global:progressTarget = $global:progressMax; Update-CustomProgress $global:progressMax
                    if ($t.Erro -gt 0) { $lblStatus.Text = "Concluido com erros - veja o log"; $lblStatus.ForeColor = [System.Drawing.Color]::FromArgb(255, 90, 90); $progressBarFill.BackColor = [System.Drawing.Color]::FromArgb(220, 65, 75) }
                    else { $lblStatus.Text = "Concluido com sucesso!"; $lblStatus.ForeColor = [System.Drawing.Color]::FromArgb(0, 255, 160); $progressBarFill.BackColor = [System.Drawing.Color]::FromArgb(0, 210, 130) }
                    if ($chkReiniciar.Checked) {
                        Log "Reiniciar ao concluir marcado: o computador vai reiniciar em 60 segundos..."
                        shutdown.exe /r /t 60 /c "Assistente de Formatacao: tarefas concluidas. Reiniciando em 60 segundos." | Out-Null
                        $resp = [System.Windows.Forms.MessageBox]::Show("Todas as tarefas terminaram.`n`nO computador vai reiniciar em 60 segundos.`n`nOK = Reiniciar agora`nCancelar = NAO reiniciar", "Reiniciar o computador", [System.Windows.Forms.MessageBoxButtons]::OKCancel, [System.Windows.Forms.MessageBoxIcon]::Warning)
                        if ($resp -eq [System.Windows.Forms.DialogResult]::Cancel) { shutdown.exe /a | Out-Null; Log "Reinicio cancelado pelo usuario." }
                        else { shutdown.exe /a | Out-Null; shutdown.exe /r /t 0 | Out-Null; $form.Close() }
                    }
                    if ($chkSair.Checked) { Log "Sair ao concluir marcado: fechando a ferramenta..."; $form.Close() }
                }
            }
        }
    })
    $timer.Start()

    # Rodapé
    $sair = New-Object System.Windows.Forms.Button; $sair.Text = "Encerrar Ferramenta"; $sair.Size = New-Object System.Drawing.Size(170, 38); $sair.Location = New-Object System.Drawing.Point(24, 634); $sair.FlatStyle = "Flat"; $sair.FlatAppearance.BorderSize = 0; $sair.BackColor = [System.Drawing.Color]::FromArgb(180, 50, 60); $sair.ForeColor = [System.Drawing.Color]::White; $sair.Cursor = "Hand"; $sair.Add_Click({ $form.Close() }); $form.Controls.Add($sair)
    $chkSair = New-Object System.Windows.Forms.CheckBox; $chkSair.Text = "Sair ao concluir"; $chkSair.AutoSize = $true; $chkSair.Location = New-Object System.Drawing.Point(210, 655); $chkSair.ForeColor = [System.Drawing.Color]::FromArgb(200, 205, 215); $chkSair.Cursor = "Hand"; $form.Controls.Add($chkSair)
    $chkReiniciar = New-Object System.Windows.Forms.CheckBox; $chkReiniciar.Text = "Reiniciar ao concluir"; $chkReiniciar.AutoSize = $true; $chkReiniciar.Location = New-Object System.Drawing.Point(210, 633); $chkReiniciar.ForeColor = [System.Drawing.Color]::FromArgb(255, 190, 90); $chkReiniciar.Cursor = "Hand"; $form.Controls.Add($chkReiniciar)
    $watermark = New-Object System.Windows.Forms.Label; $watermark.Text = "Desenvolvido por: Elson (Criatividade E Tudo)"; $watermark.Font = New-Object System.Drawing.Font("Segoe UI", 8.5); $watermark.ForeColor = [System.Drawing.Color]::FromArgb(100, 110, 120); $watermark.AutoSize = $true; $watermark.Location = New-Object System.Drawing.Point(435, 645); $form.Controls.Add($watermark)
    $versaoLabel = New-Object System.Windows.Forms.Label; $versaoLabel.Text = $VersaoAtual; $versaoLabel.Font = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Bold); $versaoLabel.ForeColor = [System.Drawing.Color]::FromArgb(0, 180, 255); $versaoLabel.AutoSize = $true; $versaoLabel.Location = New-Object System.Drawing.Point(1055, 645); $form.Controls.Add($versaoLabel)

    $form.Show(); Update-CustomScroll
    [System.Windows.Forms.Application]::Run($form)
    $netTimer.Stop(); $netTimer.Dispose(); $animTimer.Stop(); $animTimer.Dispose(); $timer.Stop(); $timer.Dispose(); $form.Dispose()

} else {
    # -----------------------------------------------------------------
    # MODO 2: TERMINAL LITE (CLI NUMÉRICO — ZERO WINDOWS FORMS)
    # -----------------------------------------------------------------
    Invoke-Expression $appInstallHelpers

    function Invoke-TaskBatchCLI {
        param([string]$Titulo, [array]$Passos)
        Write-Host ""
        Write-Host "========================================================================" -ForegroundColor Cyan
        Write-Host "  INICIANDO: $Titulo" -ForegroundColor White
        Write-Host "========================================================================" -ForegroundColor Cyan

        $ok = 0; $ja = 0; $erro = 0; $total = $Passos.Count; $i = 0
        foreach ($p in $Passos) {
            $i++
            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [$i/$total] Processando: $($p.Nome)..." -ForegroundColor Yellow
            $global:LASTEXITCODE = 0
            try { & $p.Cmd } catch { $global:LASTEXITCODE = 1 }
            $c = $global:LASTEXITCODE
            if ($c -eq 0) { $ok++; Write-Host "[$(Get-Date -Format 'HH:mm:ss')]   [OK]   $($p.Nome) concluido!" -ForegroundColor Green }
            elseif ($c -eq -1978335189) { $ja++; Write-Host "[$(Get-Date -Format 'HH:mm:ss')]   [JA]   $($p.Nome) ja estava instalado." -ForegroundColor Cyan }
            else { $erro++; Write-Host "[$(Get-Date -Format 'HH:mm:ss')]   [ERRO] $($p.Nome) falhou (codigo $c)." -ForegroundColor Red }
        }
        Write-Host "------------------------------------------------------------------------" -ForegroundColor DarkGray
        Write-Host "  RESUMO ($Titulo): Instalados: $ok | Ja tinha: $ja | Erros: $erro" -ForegroundColor White
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
    while ($true) {
        Clear-Host
        $net = Get-NetworkLineCLI
        Write-Host "========================================================================" -ForegroundColor Cyan
        Write-Host "   ASSISTENTE DE FORMATACAO LITE ($VersaoAtual - MODO CONSOLE)" -ForegroundColor White
        Write-Host "   Desenvolvido por: Elson (Criatividade E Tudo)" -ForegroundColor DarkGray
        Write-Host "========================================================================" -ForegroundColor Cyan
        Write-Host "   Status da Rede: " -NoNewline -ForegroundColor Gray; Write-Host $net.Text -ForegroundColor $net.Color
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
