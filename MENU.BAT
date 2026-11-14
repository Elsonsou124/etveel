@echo off
REM =====================================================================
REM INICIALIZADOR E ELEVAÇÃO ADMINISTRATIVA
REM =====================================================================
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
# =====================================================================
# INICIALIZAÇÃO DO AMBIENTE GRÁFICO (WINDOWS FORMS)
# =====================================================================
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()


# =====================================================================
# SEÇÃO 1: CONFIGURAÇÕES INICIAIS E CAMINHOS
# =====================================================================
$drive     = $env:BATDRIVE
$BASE      = "$drive\Windows\Tudo"
$KEY       = "$BASE\rarreg.key"
$WINRARDIR = "C:\Program Files\WinRAR"


# =====================================================================
# SEÇÃO 2: TWEAKS DO SISTEMA (Executados invisivelmente ao abrir)
# =====================================================================

# 2.1 - Gerador automático da chave de registro do WinRAR
if (-not (Test-Path "$WINRARDIR\rarreg.key")) {
    if (-not (Test-Path $WINRARDIR)) { New-Item -ItemType Directory -Force -Path $WINRARDIR | Out-Null }
    $txtPath = "$WINRARDIR\rarreg.txt"
    Set-Content -Path $txtPath -Value "RAR registration data`r`nchattchitto.com`r`nUnlimited Company License`r`nUID=45cf7e253572312b6995`r`n64122122506995900ddabb88b22559b8f25d88e1168dd8cea3bd59`r`nfe190143727199246a8460fce6cb5ffde62890079861be57638717`r`n7131ced835ed65cc743d9777f2ea71a8e32c7e593cf66794343565`r`nb41bcf56929486b8bcdac33d50ecf7739960e36503ffdcbcf7dbfc`r`n378eb1e8a5d96ddf9e5c7d6e7b122c103ee81bce156ee5ec1cf50d`r`n174c5a231523f967f5c53a4efdc7ecb9689f18a2ed6166f7608276`r`n7f5dd734a2736b2d5fb6eb5145b50ed0c7033251fe142027056408" -Force
    Rename-Item -Path $txtPath -NewName "rarreg.key" -Force
}

# 2.2 - Configuração de Energia (Nunca desligar/suspender)
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

# 2.3 - Desativar Proteções do Windows Defender temporariamente
try {
    Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue
    Set-MpPreference -DisableBehaviorMonitoring $true -ErrorAction SilentlyContinue
    Set-MpPreference -DisableBlockAtFirstSeen $true -ErrorAction SilentlyContinue
    Set-MpPreference -DisableIOAVProtection $true -ErrorAction SilentlyContinue
    Set-MpPreference -DisableScriptScanning $true -ErrorAction SilentlyContinue
    Set-MpPreference -SubmitSamplesConsent 2 -ErrorAction SilentlyContinue
    Set-MpPreference -MAPSReporting 0 -ErrorAction SilentlyContinue
} catch {}

# 2.4 - Ativar ícones clássicos na Área de Trabalho
$iconsPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel"
if (-not (Test-Path $iconsPath)) { New-Item -Path $iconsPath -Force | Out-Null }
Set-ItemProperty -Path $iconsPath -Name "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" -Value 0 -Type DWord -Force 
Set-ItemProperty -Path $iconsPath -Name "{59031a47-3f72-44a7-89c5-5595fe6b30ee}" -Value 0 -Type DWord -Force 
Set-ItemProperty -Path $iconsPath -Name "{5399E694-6CE5-4D6C-8FCE-1D8870FDCBA0}" -Value 0 -Type DWord -Force 

# 2.5 - Ativar Visualizador de Fotos Clássico
$photoPath = "HKLM:\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations"
if (-not (Test-Path $photoPath)) { New-Item -Path $photoPath -Force | Out-Null }
foreach ($ext in @('.jpg','.jpeg','.png','.bmp','.gif','.tif','.tiff')) {
    New-ItemProperty -Path $photoPath -Name $ext -Value 'PhotoViewer.FileAssoc.Tiff' -PropertyType String -Force | Out-Null
}

# 2.6 - Atualizar o Shell do Windows e API de Scroll do Console
$refreshCode = @'
[System.Runtime.InteropServices.DllImport("Shell32.dll")]
public static extern int SHChangeNotify(int eventId, int flags, IntPtr item1, IntPtr item2);
public static void Atualizar() { SHChangeNotify(0x08000000, 0x1000, IntPtr.Zero, IntPtr.Zero); }

[System.Runtime.InteropServices.DllImport("user32.dll", CharSet = System.Runtime.InteropServices.CharSet.Auto)]
public static extern IntPtr SendMessage(IntPtr hWnd, int Msg, IntPtr wParam, IntPtr lParam);
'@
Add-Type -MemberDefinition $refreshCode -Namespace "WinAPI" -Name "Desktop" -ErrorAction SilentlyContinue
[WinAPI.Desktop]::Atualizar()


# =====================================================================
# SEÇÃO 3: FUNÇÕES DE SUPORTE, ANTI-TRAVAMENTO E INSTALAÇÃO
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

# =====================================================================
# FUNÇÕES BLINDADAS DO KIT GAMER (COM TIMEOUT E FALLBACKS EM CADEIA)
# =====================================================================

function Install-GamerPowerPlan {
    try {
        $guid = (powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61) 2>$null
        if ($guid -match "([a-f0-9\-]{36})") {
            powercfg -setactive $Matches[1] 2>$null
        } else {
            powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null
        }
        $global:LASTEXITCODE = 0
    } catch {
        $global:LASTEXITCODE = 0
    }
}

function Install-GamerNetFx3 {
    try {
        $feat = Get-WindowsOptionalFeature -Online -FeatureName NetFx3 -ErrorAction SilentlyContinue
        if ($feat -and $feat.State -eq 'Enabled') {
            $global:LASTEXITCODE = -1978335189
            return
        }
        Write-Host "##INFO Ativando recurso NetFx3 via DISM (limite 300s)..."
        $code = Invoke-ProcessWithTimeout -FilePath "dism.exe" -ArgumentList "/Online /Enable-Feature /FeatureName:NetFx3 /All /NoRestart /Quiet" -TimeoutSeconds 300
        if ($code -eq 0 -or $code -eq 3010) {
            $global:LASTEXITCODE = 0
            return
        }
        Write-Host "##INFO Tentando metodo alternativo via PowerShell..."
        Enable-WindowsOptionalFeature -Online -FeatureName NetFx3 -All -NoRestart -ErrorAction SilentlyContinue | Out-Null
        $global:LASTEXITCODE = 0
    } catch {
        $global:LASTEXITCODE = 0
    }
}

function Install-GamerDotNet8 {
    Ensure-WinGetInstalled
    Write-Host "##INFO Tentativa 1: Instalando .NET Desktop Runtime 8 via WinGet..."
    $code = Invoke-WingetSafe -Id "Microsoft.DotNet.DesktopRuntime.8" -TimeoutSeconds 180
    if ($code -eq 0 -or $code -eq -1978335189) {
        $global:LASTEXITCODE = $code
        return
    }

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
                if ($exit -eq 0 -or $exit -eq 3010 -or $exit -eq 1638) {
                    $global:LASTEXITCODE = 0
                    return
                }
            }
        } finally {
            Remove-Item -LiteralPath $p -Force -ErrorAction SilentlyContinue
        }
    }
    $global:LASTEXITCODE = 1
}

function Install-GamerVCRedist {
    Ensure-WinGetInstalled
    
    # Plano A: WinGet Oficial
    Write-Host "##INFO Tentativa 1: Instalando Visual C++ 2015-2022 (x64/x86) via WinGet..."
    $c64 = Invoke-WingetSafe -Id "Microsoft.VCRedist.2015+.x64" -TimeoutSeconds 150
    $c86 = Invoke-WingetSafe -Id "Microsoft.VCRedist.2015+.x86" -TimeoutSeconds 150
    if (($c64 -eq 0 -or $c64 -eq -1978335189) -and ($c86 -eq 0 -or $c86 -eq -1978335189)) {
        Write-Host "##INFO Visual C++ instalado via WinGet!"
        $global:LASTEXITCODE = 0
        return
    }

    # Plano B: Pacote AIO
    Write-Host "##INFO Tentativa 2: Baixando Visual C++ AIO (limite 240s)..."
    $aioUrls = @(
        "https://github.com/abbodi1406/vcredist/releases/latest/download/VisualCppRedist_AIO_x86_x64.exe",
        "https://github.com/ChrisTitusTech/winutil/raw/main/vcredist.exe"
    )
    foreach ($u in $aioUrls) {
        $p = Join-Path $env:TEMP ("vcredist_aio_" + [guid]::NewGuid().ToString('N') + ".exe")
        try {
            if (Download-FileSafe -Uri $u -OutFile $p -TimeoutSec 120) {
                Write-Host "##INFO Executando instalacao silenciosa do AIO..."
                $exit = Invoke-ProcessWithTimeout -FilePath $p -ArgumentList "/ai /gm2" -TimeoutSeconds 240
                if ($exit -eq 0 -or $exit -eq 3010) {
                    $global:LASTEXITCODE = 0
                    return
                }
            }
        } finally {
            Remove-Item -LiteralPath $p -Force -ErrorAction SilentlyContinue
        }
    }

    # Plano C: Fallback Direto da Microsoft
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
        } finally {
            Remove-Item -LiteralPath $msFile -Force -ErrorAction SilentlyContinue
        }
    }
    $global:LASTEXITCODE = if ($msOk) { 0 } else { 1 }
}

function Install-GamerDirectX {
    Ensure-WinGetInstalled

    # Plano A: WinGet Oficial (Microsoft.DirectX)
    Write-Host "##INFO Tentativa 1: Instalando DirectX via WinGet..."
    $wgCode = Invoke-WingetSafe -Id "Microsoft.DirectX" -TimeoutSeconds 180
    if ($wgCode -eq 0 -or $wgCode -eq -1978335189) {
        Write-Host "##INFO DirectX instalado via WinGet!"
        $global:LASTEXITCODE = $wgCode
        return
    }

    # Plano B: Instalador Web Oficial Microsoft (dxwebsetup.exe)
    Write-Host "##INFO Tentativa 2: Baixando DirectX Web Installer oficial..."
    $webFile = Join-Path $env:TEMP ("dxweb_" + [guid]::NewGuid().ToString('N') + ".exe")
    try {
        if (Download-FileSafe -Uri "https://download.microsoft.com/download/1/7/1/1718CCC4-6315-4D8E-9543-8E28A4E18C4C/dxwebsetup.exe" -OutFile $webFile -TimeoutSec 90 -MinBytes 100000) {
            Write-Host "##INFO Instalando runtimes do DirectX (Web)..."
            $webCode = Invoke-ProcessWithTimeout -FilePath $webFile -ArgumentList "/Q" -TimeoutSeconds 180
            if ($webCode -eq 0 -or $webCode -eq 3010) {
                Write-Host "##INFO DirectX instalado via Web Installer!"
                $global:LASTEXITCODE = 0
                return
            }
        }
    } finally {
        Remove-Item -LiteralPath $webFile -Force -ErrorAction SilentlyContinue
    }

    # Plano C: Espelho Completo Jun 2010 Redist
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
                Write-Host "##INFO Extraindo arquivos do DirectX..."
                $null = Invoke-ProcessWithTimeout -FilePath $d -ArgumentList "/Q /T:`"$dir`"" -TimeoutSeconds 90
                $setupExe = Join-Path $dir "DXSETUP.exe"
                if (Test-Path $setupExe) {
                    Write-Host "##INFO Instalando runtimes do DirectX..."
                    $insCode = Invoke-ProcessWithTimeout -FilePath $setupExe -ArgumentList "/silent" -TimeoutSeconds 180
                    if ($insCode -eq 0 -or $insCode -eq 3010) {
                        $global:LASTEXITCODE = 0
                        return
                    }
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

        $installedSomething = $false
        foreach ($gpu in $gpus) {
            $name = $gpu.Name
            $appId = $null
            $appName = $null
            $directUrl = $null
            $webUrl = $null
            
            if ($name -match '(?i)NVIDIA') {
                $appId = 'Nvidia.NVIDIAApp'
                $appName = 'NVIDIA App (Oficial)'
                $directUrl = 'https://dtm.nvidia.com/nvidia-app/direct-download'
                $webUrl = 'https://www.nvidia.com/pt-br/software/nvidia-app/'
            } elseif ($name -match '(?i)AMD|Radeon') {
                $appId = 'AdvancedMicroDevices.AMDSoftware'
                $appName = 'AMD Software Adrenalin'
                $directUrl = '' 
                $webUrl = 'https://www.amd.com/pt/support/download/drivers.html'
            } elseif ($name -match '(?i)Intel') {
                $appId = 'Intel.DriverAndSupportAssistant'
                $appName = 'Intel Driver & Support Assistant'
                $directUrl = 'https://dsadata.intel.com/installer'
                $webUrl = 'https://www.intel.com.br/content/www/br/pt/support/intel-driver-support-assistant.html'
            }

            if ($appId) {
                $success = $false
                Write-Host "##INFO Processando $appName..."
                
                Write-Host "##INFO Tentativa 1: Baixando via WinGet (limite 240s)..."
                $wgCode = Invoke-WingetSafe -Id $appId -TimeoutSeconds 240
                if ($wgCode -eq 0 -or $wgCode -eq -1978335189) { $success = $true }

                if (-not $success -and $directUrl) {
                    Write-Host "##INFO Tentativa 2: Baixando executavel direto oficial..."
                    $setupPath = Join-Path $env:TEMP ("gpu_setup_" + [guid]::NewGuid().ToString('N') + ".exe")
                    try {
                        if (Download-FileSafe -Uri $directUrl -OutFile $setupPath -TimeoutSec 150) {
                            $exit = Invoke-ProcessWithTimeout -FilePath $setupPath -ArgumentList "/s /noreboot" -TimeoutSeconds 240
                            if ($exit -eq 0 -or $exit -eq 3010) { $success = $true }
                        }
                    } finally {
                        Remove-Item -LiteralPath $setupPath -Force -ErrorAction SilentlyContinue
                    }
                }

                if (-not $success -and $webUrl) {
                    Write-Host "##INFO Tentativa 3: Abrindo pagina oficial no navegador..."
                    Start-Process $webUrl -ErrorAction SilentlyContinue
                    $success = $true
                }

                if ($success) {
                    Write-Host "##INFO $appName concluido!"
                    $installedSomething = $true
                }
            }
        }
        if (-not $installedSomething) { Write-Host "##INFO Nenhuma placa compativel com apps automaticos." }
        $global:LASTEXITCODE = 0
    } catch {
        Write-Host "##INFO Erro ao processar app da GPU: $($_.Exception.Message)"
        $global:LASTEXITCODE = 0
    }
}

# =====================================================================
# FUNÇÕES DO WINDOWS UPDATE E DRIVERS
# =====================================================================

function Invoke-WindowsUpdate {
    Write-Host "##INFO Iniciando varredura de atualizacoes do Windows (aguarde)..."
    try {
        $session = New-Object -ComObject Microsoft.Update.Session
        $searcher = $session.CreateUpdateSearcher()
        $result = $searcher.Search("IsInstalled=0 and Type='Software'")
        if ($result.Updates.Count -eq 0) { Write-Host "##INFO Nenhuma atualizacao pendente"; $global:LASTEXITCODE = 0; return }
        Write-Host ("##INFO Encontradas " + $result.Updates.Count + " atualizacoes. Baixando...")
        $downloader = $session.CreateUpdateDownloader()
        $downloader.Updates = $result.Updates
        $downloader.Download()
        Write-Host "##INFO Baixado. Instalando agora (pode demorar)..."
        $installer = $session.CreateUpdateInstaller()
        $installer.Updates = $result.Updates
        $installResult = $installer.Install()
        $global:LASTEXITCODE = if ($installResult.ResultCode -eq 2) { 0 } else { $installResult.ResultCode }
    } catch {
        Write-Host ("##INFO Erro interno: " + $_.Exception.Message)
        $global:LASTEXITCODE = 1
    }
}

function Invoke-DriverUpdate {
    Write-Host "##INFO Buscando drivers oficiais pelo Windows Update..."
    try {
        $session = New-Object -ComObject Microsoft.Update.Session
        $searcher = $session.CreateUpdateSearcher()
        $result = $searcher.Search("IsInstalled=0 and Type='Driver'")
        if ($result.Updates.Count -eq 0) { Write-Host "##INFO Todos os drivers ja estao atualizados"; $global:LASTEXITCODE = 0; return }
        Write-Host ("##INFO Encontrados " + $result.Updates.Count + " drivers pendentes. Baixando...")
        $downloader = $session.CreateUpdateDownloader()
        $downloader.Updates = $result.Updates
        $downloader.Download()
        Write-Host "##INFO Instalando drivers na maquina..."
        $installer = $session.CreateUpdateInstaller()
        $installer.Updates = $result.Updates
        $installResult = $installer.Install()
        $global:LASTEXITCODE = if ($installResult.ResultCode -eq 2) { 0 } else { $installResult.ResultCode }
    } catch {
        Write-Host ("##INFO Erro ao buscar drivers: " + $_.Exception.Message)
        $global:LASTEXITCODE = 1
    }
}

# =====================================================================
# FUNÇÕES DE INSTALAÇÃO DE APLICATIVOS E LOJAS (COM TIMEOUT)
# =====================================================================

function Get-VerifiedInstaller {
    param([string]$Uri, [string]$FileName, [string]$PublisherPattern)
    $path = Join-Path $env:TEMP $FileName
    Invoke-WebRequest -Uri $Uri -OutFile $path -UseBasicParsing -TimeoutSec 180 -ErrorAction Stop
    $signature = Get-AuthenticodeSignature -FilePath $path
    if ($signature.Status -ne 'Valid' -or $signature.SignerCertificate.Subject -notmatch $PublisherPattern) {
        Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
        throw "Assinatura digital invalida ou publicador inesperado: $Uri"
    }
    return $path
}

function Get-AdobeVerifiedDownload {
    param([string]$Uri)
    $parsed = [uri]$Uri
    if ($parsed.Scheme -ne 'https' -or $parsed.Host -notin @('ardownload.adobe.com','ardownload2.adobe.com')) {
        throw 'Link fora dos servidores da Adobe.'
    }
    $path = Join-Path $env:TEMP ('AdobeReader_' + [guid]::NewGuid().ToString('N') + '.exe')
    if (Download-FileSafe -Uri $Uri -OutFile $path -TimeoutSec 240) {
        $sig = Get-AuthenticodeSignature -FilePath $path
        if ($sig.Status -eq 'Valid' -and $sig.SignerCertificate -and $sig.SignerCertificate.Subject -match '(?i)(CN|O)=Adobe (Inc\.|Systems Incorporated)(?:,|$)') {
            return $path
        }
    }
    Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
    throw 'Falha ao baixar instalador Adobe'
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

function Get-AdobeDownloadCandidates {
    $url = $null
    try {
        $headers = @{ 'User-Agent' = 'Windows-Installer-Menu'; 'Accept' = 'application/vnd.github+json' }
        $listing = Invoke-RestMethod -Uri 'https://api.github.com/repos/microsoft/winget-pkgs/contents/manifests/a/Adobe/Acrobat/Reader/64-bit' -Headers $headers -TimeoutSec 20 -ErrorAction Stop
        $versions = @($listing | Where-Object { $_.type -eq 'dir' -and $_.name -match '^\d+\.\d+\.\d+$' } | Sort-Object { [version]$_.name } -Descending | Select-Object -First 3)
        foreach ($version in $versions) {
            try {
                $manifestUrl = 'https://raw.githubusercontent.com/microsoft/winget-pkgs/master/manifests/a/Adobe/Acrobat/Reader/64-bit/' + $version.name + '/Adobe.Acrobat.Reader.64-bit.installer.yaml'
                $manifest = Invoke-WebRequest -Uri $manifestUrl -UseBasicParsing -TimeoutSec 20 -ErrorAction Stop
                $match = [regex]::Match([string]$manifest.Content, '(?m)^\s*InstallerUrl:\s*(https://ardownload(?:2)?\.adobe\.com/[^\s]+_MUI\.exe)\s*$')
                if ($match.Success) { $url = $match.Groups[1].Value; break }
            } catch {}
        }
    } catch {}
    if (-not $url) {
        $url = 'https://ardownload2.adobe.com/pub/adobe/acrobat/win/AcrobatDC/2600322075/AcroRdrDCx642600322075_MUI.exe'
    }
    $url
    if (([uri]$url).Host -eq 'ardownload2.adobe.com') { $url.Replace('https://ardownload2.adobe.com/', 'https://ardownload.adobe.com/') }
    else { $url.Replace('https://ardownload.adobe.com/', 'https://ardownload2.adobe.com/') }
}

function Install-AdobeReaderDirect {
    $global:LASTEXITCODE = 1
    if (Test-AdobeReaderInstalled) { $global:LASTEXITCODE = -1978335189; return }
    if (-not [Environment]::Is64BitOperatingSystem) { return }
    $setup = $null
    foreach ($uri in @(Get-AdobeDownloadCandidates)) {
        try { $setup = Get-AdobeVerifiedDownload -Uri $uri; break } catch {}
    }
    if (-not $setup) {
        try { Start-Process 'https://get.adobe.com/reader/enterprise/' -ErrorAction Stop } catch {}
        return
    }
    try {
        $code = Invoke-ProcessWithTimeout -FilePath $setup -ArgumentList '-sfx_nu /sAll /rs /msi EULA_ACCEPT=YES' -TimeoutSeconds 240
        if ($code -in @(0,3010,1641)) { $global:LASTEXITCODE = 0 }
        elseif ($code -eq 1638 -and (Test-AdobeReaderInstalled)) { $global:LASTEXITCODE = -1978335189 }
        else { $global:LASTEXITCODE = if ($code -ne 0) { $code } else { 1 } }
    } catch {
        $global:LASTEXITCODE = 1
    } finally { Remove-Item -LiteralPath $setup -Force -ErrorAction SilentlyContinue }
}

function Get-PackageVerifiedDownload {
    param([string]$Uri, [string]$Name, [string]$Extension, [string]$Sha256)
    $path = Join-Path $env:TEMP ('Setup_' + [guid]::NewGuid().ToString('N') + '.' + $Extension)
    if (Download-FileSafe -Uri $Uri -OutFile $path -TimeoutSec 180) {
        if ($Sha256 -match '^[A-Fa-f0-9]{64}$' -and (Get-FileHash -LiteralPath $path -Algorithm SHA256 -ErrorAction Stop).Hash -eq $Sha256) {
            return $path
        }
    }
    Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
    throw 'Falha ao baixar pacote'
}

function Test-MenuPackageInstalled {
    param([string]$Id)
    $roots = @($env:ProgramFiles, ${env:ProgramFiles(x86)}) | Where-Object { $_ }
    $relative = if ($Id -eq 'RARLab.WinRAR') { 'WinRAR\WinRAR.exe' } else { 'MSI Afterburner\MSIAfterburner.exe' }
    foreach ($root in $roots) { if (Test-Path -LiteralPath (Join-Path $root $relative)) { return $true } }
    return $false
}

function Get-MenuPackageMetadata {
    param([string]$Id)
    if ($Id -eq 'RARLab.WinRAR') {
        $repo = 'r/RARLab/WinRAR'
        $reserve = @{ Name='WinRAR'; Url='https://www.rarlab.com/rar/winrar-x64-723br.exe'; Hash='6EBE807D40F179C12B40CDE6A9DAEF03E7CDB06B904B6732ADE9CEC9E6D4D56B'; Extension='exe'; Nested=''; Args='-s1'; Manual='https://www.rarlab.com/download.htm' }
    } else {
        $repo = 'g/Guru3D/Afterburner'
        $reserve = @{ Name='MSI Afterburner'; Url='https://ftp.nluug.nl/pub/games/PC/guru3d/afterburner/%5BGuru3D%5D-MSIAfterburnerSetup466Build16757.zip'; Hash='348E9690A638D84E30E32E9C7C2DD7AAD9FD82D71ECED1942C04C4C5620B0E1E'; Extension='zip'; Nested='MSIAfterburnerSetup466.exe'; Args='/S'; Manual='https://www.msi.com/Landing/afterburner/graphics-cards' }
    }
    try {
        $headers = @{ 'User-Agent'='Windows-Installer-Menu'; 'Accept'='application/vnd.github+json' }
        $listing = Invoke-RestMethod -Uri ('https://api.github.com/repos/microsoft/winget-pkgs/contents/manifests/' + $repo) -Headers $headers -TimeoutSec 20 -ErrorAction Stop
        $versions = @($listing | Where-Object { $_.type -eq 'dir' -and $_.name -match '^\d+\.\d+\.\d+(\.\d+)?$' } | Sort-Object { [version]$_.name } -Descending | Select-Object -First 3)
        foreach ($version in $versions) {
            try {
                $manifest = Invoke-WebRequest -Uri ('https://raw.githubusercontent.com/microsoft/winget-pkgs/master/manifests/' + $repo + '/' + $version.name + '/' + $Id + '.installer.yaml') -UseBasicParsing -TimeoutSec 20 -ErrorAction Stop
                $text = [string]$manifest.Content
                if ($Id -eq 'RARLab.WinRAR') {
                    $m = [regex]::Match($text, '(?ms)^- InstallerLocale: pt-BR\s+Architecture: x64\s+InstallerUrl: (https://www\.rarlab\.com/rar/winrar-x64-\d+br\.exe)\s+InstallerSha256: ([A-Fa-f0-9]{64})')
                    if (-not $m.Success) { $m = [regex]::Match($text, '(?ms)^- InstallerLocale: en\s+Architecture: x64\s+InstallerUrl: (https://www\.rarlab\.com/rar/winrar-x64-\d+\.exe)\s+InstallerSha256: ([A-Fa-f0-9]{64})') }
                } else {
                    $m = [regex]::Match($text, '(?m)^\s*InstallerUrl: (https://ftp\.nluug\.nl/pub/games/PC/guru3d/afterburner/[^\r\n]+\.zip)\s+InstallerSha256: ([A-Fa-f0-9]{64})')
                    $nested = [regex]::Match($text, '(?m)^- RelativeFilePath: (MSIAfterburnerSetup\d+\.exe)\s*$')
                    if (-not $nested.Success) { continue }
                }
                if ($m.Success) {
                    $reserve.Url=$m.Groups[1].Value; $reserve.Hash=$m.Groups[2].Value
                    if ($Id -eq 'Guru3D.Afterburner') { $reserve.Nested=$nested.Groups[1].Value }
                    break
                }
            } catch {}
        }
    } catch {}
    return $reserve
}

function Install-MenuPackageDirect {
    param([string]$Id)
    $global:LASTEXITCODE=1
    if (Test-MenuPackageInstalled -Id $Id) { $global:LASTEXITCODE=-1978335189; return }
    $meta=Get-MenuPackageMetadata -Id $Id
    $download=$null; $folder=$null
    try {
        try { $download=Get-PackageVerifiedDownload -Uri $meta.Url -Name $meta.Name -Extension $meta.Extension -Sha256 $meta.Hash }
        catch {
            Start-Process $meta.Manual -ErrorAction Stop
            return
        }
        $setup=$download
        if ($meta.Extension -eq 'zip') {
            $folder=Join-Path $env:TEMP ('Afterburner_' + [guid]::NewGuid().ToString('N'))
            Expand-Archive -LiteralPath $download -DestinationPath $folder -Force -ErrorAction Stop
            $setup=Join-Path $folder $meta.Nested
            if (-not (Test-Path -LiteralPath $setup)) { throw 'Instalador nao encontrado' }
        }
        $code = Invoke-ProcessWithTimeout -FilePath $setup -ArgumentList $meta.Args -TimeoutSeconds 180
        if ($code -in @(0,3010,1641)) {
            if (Test-MenuPackageInstalled -Id $Id) { $global:LASTEXITCODE=0 } else { $global:LASTEXITCODE=1 }
        } else { $global:LASTEXITCODE=$code }
    } catch {
        $global:LASTEXITCODE=1
    } finally {
        if ($download) { Remove-Item -LiteralPath $download -Force -ErrorAction SilentlyContinue }
        if ($folder) { Remove-Item -LiteralPath $folder -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

function Install-AppFallback {
    param([string]$Id)
    $global:LASTEXITCODE = 1
    Ensure-WinGetInstalled

    if ($Id -in @('RARLab.WinRAR','Guru3D.Afterburner') -and (Test-MenuPackageInstalled -Id $Id)) {
        $global:LASTEXITCODE=-1978335189; return
    }
    if ($Id -eq 'Adobe.Acrobat.Reader.64-bit' -and (Test-AdobeReaderInstalled)) {
        $global:LASTEXITCODE = -1978335189
        return
    }
    try {
        $wingetCode = Invoke-WingetSafe -Id $Id -TimeoutSeconds 240
        if ($wingetCode -eq 0 -or $wingetCode -eq -1978335189) {
            $global:LASTEXITCODE = $wingetCode
            return
        }
        switch ($Id) {
            'Google.Chrome' {
                $fileName = 'ChromeEnterprise_' + [guid]::NewGuid().ToString('N') + '.msi'
                $setup = Get-VerifiedInstaller -Uri 'https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise64.msi' -FileName $fileName -PublisherPattern '(?i)(CN=Google LLC|O=Google LLC)'
                $code = Invoke-ProcessWithTimeout -FilePath (Join-Path $env:SystemRoot 'System32\msiexec.exe') -ArgumentList "/i `"$setup`" /qn /norestart" -TimeoutSeconds 180
                Remove-Item -LiteralPath $setup -Force -ErrorAction SilentlyContinue
                $global:LASTEXITCODE = $code
                return
            }
            'RARLab.WinRAR' { Install-MenuPackageDirect -Id $Id; return }
            'Adobe.Acrobat.Reader.64-bit' { Install-AdobeReaderDirect; return }
            'Guru3D.Afterburner' { Install-MenuPackageDirect -Id $Id; return }
            default { $global:LASTEXITCODE = 1; return }
        }
    } catch {
        if ($Id -eq 'Adobe.Acrobat.Reader.64-bit') { Install-AdobeReaderDirect; return }
        if ($Id -in @('RARLab.WinRAR','Guru3D.Afterburner')) { Install-MenuPackageDirect -Id $Id; return }
        $global:LASTEXITCODE = 1
    }
}
'@


# =====================================================================
# SEÇÃO 4: ROTINAS DO OFFICE (Download, Atalhos e Fechamento Automático)
# =====================================================================

$officeShortcuts = '$achou = $false; $desk = Join-Path ([Environment]::GetFolderPath("Desktop")) "Office 365"; $pastas = @("$env:ProgramData\Microsoft\Windows\Start Menu\Programs", "$env:APPDATA\Microsoft\Windows\Start Menu\Programs"); foreach ($app in @("*Word*.lnk", "*Excel*.lnk", "*PowerPoint*.lnk", "*Access*.lnk", "*Publisher*.lnk", "*OneNote*.lnk")) { foreach ($dir in $pastas) { if (Test-Path $dir) { $arquivos = Get-ChildItem -Path $dir -Filter $app -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Name -notmatch "Wordpad|Voice" }; foreach ($arq in $arquivos) { if (-not $achou) { if (-not (Test-Path $desk)) { New-Item -ItemType Directory -Force -Path $desk | Out-Null }; $achou = $true }; Copy-Item -Path $arq.FullName -Destination $desk -Force } } } }; if ($achou) { Write-Host "##INFO Atalhos do Office copiados com sucesso!" } else { Write-Host "##INFO Nenhum atalho achado. O Office ja terminou de instalar?" }'

$officeWaitAndClose = @'
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
                        if ($elemento.Current.ControlType -eq [System.Windows.Automation.ControlType]::Button -and $nome -match '^(?i:Fechar|Close|Concluir|Finish|Finalizar|Done)$' -and $elemento.Current.IsEnabled) { [void]$botoesFechar.Add($elemento) }
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
$global:LASTEXITCODE = [int]$processo.ExitCode
'@

$officeDownloadHelper = @'
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
'@

$officeInstallAndShortcuts = $officeDownloadHelper + "`r`n" + @'
$exe = $null
try {
    $exe = Get-OfficeInstaller
'@ + "`r`n" + $officeWaitAndClose + "`r`n" + @'
    if ($global:LASTEXITCODE -eq 3010) { $global:LASTEXITCODE = 0 }
    if ($global:LASTEXITCODE -eq 0) {
'@ + "`r`n" + $officeShortcuts + "`r`n" + @'
    }
} catch {
    $global:LASTEXITCODE = 1
} finally {
    if ($exe) { Remove-Item -LiteralPath $exe -Force -ErrorAction SilentlyContinue }
}
'@


# =====================================================================
# SEÇÃO 5: GERENCIAMENTO DE TAREFAS E FILAS DA INTERFACE
# =====================================================================

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
        if ($qtdFila -gt 1) {
            $lblStatus.Text = "Instalando: $titulo (Fila: $qtdFila tarefas)..."
        } else {
            $lblStatus.Text = "Instalando: $titulo..."
        }
        $lblStatus.ForeColor = [System.Drawing.Color]::FromArgb(0, 230, 255)
    }
    Log "=== Iniciando: $titulo ==="
}

function W($id) { "Install-AppFallback -Id '$id'" }

function Passo($n, $tot, $nome, $cmd) {
    "Write-Host '##AGORA [$n/$tot] $nome'; `$global:LASTEXITCODE = 0; $cmd; `$c = `$global:LASTEXITCODE; " +
    "if (`$c -eq 0) { Write-Host '##OK $nome' } elseif (`$c -eq -1978335189) { Write-Host '##JA $nome' } " +
    "else { Write-Host ('##ERRO $nome (codigo ' + `$c + ')'); `$global:falhou = 1 }"
}

function Lote($passos) { "`$global:falhou = 0; " + ($passos -join "; ") + "; `$global:LASTEXITCODE = [int]`$global:falhou" }


# =====================================================================
# SEÇÃO 5.5: SPLASH SCREEN (MINI ANIMAÇÃO DE ABERTURA)
# =====================================================================
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
$lblSplashVer.Text = "Versão 0.71 — Inicializando Ambiente..."
$lblSplashVer.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
$lblSplashVer.ForeColor = [System.Drawing.Color]::FromArgb(110, 125, 145)
$lblSplashVer.AutoSize = $true
$lblSplashVer.Location = New-Object System.Drawing.Point(135, 125)
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
    $currentWidth = [int](($global:splashCount / 75) * 360)
    if ($currentWidth -le 360) { $splashBarFill.Width = $currentWidth }
    if ($global:splashCount -gt 75) { $splashTimer.Stop(); $splash.Close() }
})

$splash.Add_Shown({ $splashTimer.Start() })
$splash.ShowDialog()
$splash.Dispose()


# =====================================================================
# SEÇÃO 6: CRIAÇÃO DA INTERFACE GRÁFICA PRINCIPAL (1120x690 COMPACTA)
# =====================================================================

$programIcon = [System.Drawing.SystemIcons]::Application

$form = New-Object System.Windows.Forms.Form
$form.Icon = $programIcon
$form.ShowIcon = $true
$form.Text = "Assistente de Formatação Pro"
$form.ClientSize = New-Object System.Drawing.Size(1120, 690)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
$form.MaximizeBox = $false
$form.MinimizeBox = $false
$form.BackColor = [System.Drawing.Color]::FromArgb(28, 30, 38)
$form.ForeColor = [System.Drawing.Color]::FromArgb(230, 230, 230)
$form.Font = New-Object System.Drawing.Font("Segoe UI", 10)

$global:mouseOffset = $null

$customTitleBar = New-Object System.Windows.Forms.Panel
$customTitleBar.Location = New-Object System.Drawing.Point(0, 0)
$customTitleBar.Size = New-Object System.Drawing.Size(1120, 35)
$customTitleBar.BackColor = [System.Drawing.Color]::FromArgb(15, 17, 22)
$form.Controls.Add($customTitleBar)

$customTitleBar.Add_MouseDown({
    if ($_.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
        $global:mouseOffset = New-Object System.Drawing.Point($_.X, $_.Y)
    }
})
$customTitleBar.Add_MouseMove({
    if ($_.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
        $mousePos = [System.Windows.Forms.Control]::MousePosition
        $mousePos.Offset(-$global:mouseOffset.X, -$global:mouseOffset.Y)
        $form.Location = $mousePos
    }
})

$lblWindowTitle = New-Object System.Windows.Forms.Label
$lblWindowTitle.Text = "  Assistente de Formatação Pro"
$lblWindowTitle.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
$lblWindowTitle.ForeColor = [System.Drawing.Color]::FromArgb(200, 210, 225)
$lblWindowTitle.AutoSize = $true
$lblWindowTitle.Location = New-Object System.Drawing.Point(5, 8)
$customTitleBar.Controls.Add($lblWindowTitle)

$lblWindowTitle.Add_MouseDown({
    if ($_.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
        $global:mouseOffset = New-Object System.Drawing.Point(($_.X + $this.Location.X), ($_.Y + $this.Location.Y))
    }
})
$lblWindowTitle.Add_MouseMove({
    if ($_.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
        $mousePos = [System.Windows.Forms.Control]::MousePosition
        $mousePos.Offset(-$global:mouseOffset.X, -$global:mouseOffset.Y)
        $form.Location = $mousePos
    }
})

$btnClose = New-Object System.Windows.Forms.Button
$btnClose.Text = "✕"
$btnClose.Size = New-Object System.Drawing.Size(45, 35)
$btnClose.Location = New-Object System.Drawing.Point(1075, 0)
$btnClose.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnClose.FlatAppearance.BorderSize = 0
$btnClose.BackColor = [System.Drawing.Color]::FromArgb(15, 17, 22)
$btnClose.ForeColor = [System.Drawing.Color]::FromArgb(200, 200, 200)
$btnClose.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$btnClose.Cursor = [System.Windows.Forms.Cursors]::Hand
$btnClose.Add_MouseEnter({ $this.BackColor = [System.Drawing.Color]::FromArgb(232, 17, 35); $this.ForeColor = [System.Drawing.Color]::White })
$btnClose.Add_MouseLeave({ $this.BackColor = [System.Drawing.Color]::FromArgb(15, 17, 22); $this.ForeColor = [System.Drawing.Color]::FromArgb(200, 200, 200) })
$btnClose.Add_Click({ 
    try {
        Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction SilentlyContinue
        Set-MpPreference -DisableBehaviorMonitoring $false -ErrorAction SilentlyContinue
        Set-MpPreference -DisableBlockAtFirstSeen $false -ErrorAction SilentlyContinue
        Set-MpPreference -DisableIOAVProtection $false -ErrorAction SilentlyContinue
        Set-MpPreference -DisableScriptScanning $false -ErrorAction SilentlyContinue
        Set-MpPreference -SubmitSamplesConsent 0 -ErrorAction SilentlyContinue
        Set-MpPreference -MAPSReporting 1 -ErrorAction SilentlyContinue
    } catch {}
    $form.Close() 
})
$customTitleBar.Controls.Add($btnClose)

$btnMinimize = New-Object System.Windows.Forms.Button
$btnMinimize.Text = "—"
$btnMinimize.Size = New-Object System.Drawing.Size(45, 35)
$btnMinimize.Location = New-Object System.Drawing.Point(1030, 0)
$btnMinimize.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnMinimize.FlatAppearance.BorderSize = 0
$btnMinimize.BackColor = [System.Drawing.Color]::FromArgb(15, 17, 22)
$btnMinimize.ForeColor = [System.Drawing.Color]::FromArgb(200, 200, 200)
$btnMinimize.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$btnMinimize.Cursor = [System.Windows.Forms.Cursors]::Hand
$btnMinimize.Add_MouseEnter({ $this.BackColor = [System.Drawing.Color]::FromArgb(50, 55, 70); $this.ForeColor = [System.Drawing.Color]::White })
$btnMinimize.Add_MouseLeave({ $this.BackColor = [System.Drawing.Color]::FromArgb(15, 17, 22); $this.ForeColor = [System.Drawing.Color]::FromArgb(200, 200, 200) })
$btnMinimize.Add_Click({ $form.WindowState = [System.Windows.Forms.FormWindowState]::Minimized })
$customTitleBar.Controls.Add($btnMinimize)


# =====================================================================
# SISTEMA DE TOOLTIP PERSONALIZADO (100% ESCURO)
# =====================================================================
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


# Cabeçalho interno
$header = New-Object System.Windows.Forms.Panel
$header.Location = New-Object System.Drawing.Point(0, 35)
$header.Size = New-Object System.Drawing.Size(1120, 68)
$header.BackColor = [System.Drawing.Color]::FromArgb(20, 22, 28)
$form.Controls.Add($header)

$title = New-Object System.Windows.Forms.Label
$title.Text = "ASSISTENTE DE FORMATAÇÃO PRO"
$title.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$title.ForeColor = [System.Drawing.Color]::FromArgb(255, 255, 255)
$title.AutoSize = $true
$title.Location = New-Object System.Drawing.Point(24, 9)
$header.Controls.Add($title)

$subTitle = New-Object System.Windows.Forms.Label
$subTitle.Text = "Central de Automação e Pós-Instalação"
$subTitle.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$subTitle.ForeColor = [System.Drawing.Color]::FromArgb(150, 160, 175)
$subTitle.AutoSize = $true
$subTitle.Location = New-Object System.Drawing.Point(28, 37)
$header.Controls.Add($subTitle)

# =====================================================================
# INDICADOR DE STATUS DE REDE / CABO ETHERNET (CANTO DIREITO DO HEADER)
# =====================================================================
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
    } catch {
        $lblNetStatus.Text = "Status de rede indisponível"
    }
}

Update-NetworkStatus

$netTimer = New-Object System.Windows.Forms.Timer
$netTimer.Interval = 3000
$netTimer.Add_Tick({ Update-NetworkStatus })
$netTimer.Start()

# Rótulos das Seções (Parte Superior em 3 Colunas)
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


# =====================================================================
# SEÇÃO 7: DEFINIÇÃO DOS BOTÕES (GRADE SUPERIOR DE 3 COLUNAS)
# =====================================================================

$actions = [ordered]@{
    "Ativação Windows"             = { Start-Process powershell -ArgumentList "-NoProfile -WindowStyle Hidden -Command `"& ([ScriptBlock]::Create((irm https://get.activated.win))) `"" ; Log "Tela de Ativacao do Windows foi Aberta" }
    "Instalar Google Chrome"     = { Start-Task "Chrome" (Lote @(Passo 1 1 "Chrome" (W "Google.Chrome"))) }
    "Instalar WinRAR"            = { Start-Task "WinRAR" (Lote @(Passo 1 1 "WinRAR" (W "RARLab.WinRAR"))) }
    "Instalar MSI Afterburner"   = { Start-Task "Afterburner" (Lote @(Passo 1 1 "MSI Afterburner" (W "Guru3D.Afterburner"))) }
    "Instalar Adobe Reader"      = { Start-Task "Adobe Reader" (Lote @(Passo 1 1 "Adobe Acrobat Reader" (W "Adobe.Acrobat.Reader.64-bit"))) }
    "Instalar Apenas o Office" = { Start-Task "Office e atalhos" (Lote @(Passo 1 1 "Office" $officeInstallAndShortcuts)) }

    # Bloco de Pacotes Blindado contra Travamentos
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
            (Passo 4 4 "Office" $officeInstallAndShortcuts)
        )) -total 4
    }

    "INSTALAR TUDO + Office" = {
        Start-Task "TUDO com Office" (Lote @(
            (Passo 1 5 "Chrome" (W "Google.Chrome")),
            (Passo 2 5 "Acrobat Reader" (W "Adobe.Acrobat.Reader.64-bit")),
            (Passo 3 5 "WinRAR" (W "RARLab.WinRAR")),
            (Passo 4 5 "MSI Afterburner" (W "Guru3D.Afterburner")),
            (Passo 5 5 "Office" $officeInstallAndShortcuts)
        )) -total 5
    }

    "Atualizar Windows" = {
        Start-Task "Atualizar Windows" (Lote @(Passo 1 1 "Windows Update" "Invoke-WindowsUpdate"))
    }

    "Atualizar Drivers" = {
        Start-Task "Atualizar Drivers" (Lote @(Passo 1 1 "Drivers Update" "Invoke-DriverUpdate"))
    }
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
        $baseBg = [System.Drawing.Color]::FromArgb(0, 120, 215)
        $baseFg = [System.Drawing.Color]::White
        $hoverBg = [System.Drawing.Color]::FromArgb(20, 140, 240)
    } elseif ($name -match "INSTALAR TUDO") {
        $baseBg = [System.Drawing.Color]::FromArgb(50, 140, 90)
        $baseFg = [System.Drawing.Color]::White
        $hoverBg = [System.Drawing.Color]::FromArgb(70, 160, 110)
    }

    if ($packageTooltips.ContainsKey($name)) {
        $tipText = $packageTooltips[$name]
        $btn.Tag = @{ Acao = $actions[$name]; CorNormal = $baseBg; CorHover = $hoverBg; Tip = $tipText }
        
        $btn.Add_MouseEnter({
            $this.BackColor = $this.Tag.CorHover
            if ($this.Tag.Tip) {
                $toolTipLabel.Text = $this.Tag.Tip
                $pt = $form.PointToClient([System.Windows.Forms.Cursor]::Position)
                $customToolTip.Location = New-Object System.Drawing.Point(($pt.X + 15), ($pt.Y + 15))
                $customToolTip.Visible = $true
                $customToolTip.BringToFront()
            }
        })
        $btn.Add_MouseLeave({
            $this.BackColor = $this.Tag.CorNormal
            $customToolTip.Visible = $false
        })
    } else {
        $btn.Tag = @{ Acao = $actions[$name]; CorNormal = $baseBg; CorHover = $hoverBg; Tip = $null }
        $btn.Add_MouseEnter({ $this.BackColor = $this.Tag.CorHover })
        $btn.Add_MouseLeave({ $this.BackColor = $this.Tag.CorNormal })
    }

    if ($actionNumber -le 6) {
        # 3 Colunas x 2 Linhas (01 a 06)
        $col = ($actionNumber - 1) % 3
        $row = [int][Math]::Floor(($actionNumber - 1) / 3)
        $btn.Size = New-Object System.Drawing.Size(316, 38)
        $btn.Location = New-Object System.Drawing.Point((48 + ($col * 364)), (134 + ($row * 44)))
        $lblNum.Location = New-Object System.Drawing.Point((24 + ($col * 364)), (144 + ($row * 44)))
    } else {
        # 3 Colunas x 3 Linhas (07 a 14)
        $colIdx = ($actionNumber - 7) % 3
        $rowIdx = [int][Math]::Floor(($actionNumber - 7) / 3)
        $btn.Size = New-Object System.Drawing.Size(316, 38)
        $btn.Location = New-Object System.Drawing.Point((48 + ($colIdx * 364)), (254 + ($rowIdx * 44)))
        $lblNum.Location = New-Object System.Drawing.Point((24 + ($colIdx * 364)), (264 + ($rowIdx * 44)))
    }

    $btn.BackColor = $baseBg
    $btn.ForeColor = $baseFg
    $btn.Add_Click({ try { & $this.Tag.Acao } catch { [System.Windows.Forms.MessageBox]::Show("Erro: $_") } })
    
    $form.Controls.Add($lblNum)
    $form.Controls.Add($btn)
}


# =====================================================================
# BOTÕES 13 E 14: Lojas de Jogos e Instalação Personalizada Total
# =====================================================================

$modalDrag = {
    if ($_.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
        $global:modalOffset = New-Object System.Drawing.Point($_.X, $_.Y)
    }
}

# 13. Lojas de Jogos (Coluna 1, Linha 3 dos Pacotes)
$lblNum13 = New-Object System.Windows.Forms.Label
$lblNum13.Text = "13"
$lblNum13.Font = New-Object System.Drawing.Font -ArgumentList "Segoe UI", ([single]8.5), ([System.Drawing.FontStyle]::Bold)
$lblNum13.ForeColor = [System.Drawing.Color]::FromArgb(120, 135, 155)
$lblNum13.AutoSize = $true
$lblNum13.Location = New-Object System.Drawing.Point(24, 352)
$form.Controls.Add($lblNum13)

$btnOpenStoresModal = New-Object System.Windows.Forms.Button
$btnOpenStoresModal.Text = "Lojas de Jogos"
$btnOpenStoresModal.Size = New-Object System.Drawing.Size(316, 38)
$btnOpenStoresModal.Location = New-Object System.Drawing.Point(48, 342)
$btnOpenStoresModal.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnOpenStoresModal.FlatAppearance.BorderSize = 0
$btnOpenStoresModal.BackColor = [System.Drawing.Color]::FromArgb(40, 44, 55)
$btnOpenStoresModal.ForeColor = [System.Drawing.Color]::FromArgb(0, 200, 255)
$btnOpenStoresModal.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9.5)
$btnOpenStoresModal.Cursor = [System.Windows.Forms.Cursors]::Hand
$btnOpenStoresModal.Add_MouseEnter({ $this.BackColor = [System.Drawing.Color]::FromArgb(55, 60, 75); $this.ForeColor = [System.Drawing.Color]::White })
$btnOpenStoresModal.Add_MouseLeave({ $this.BackColor = [System.Drawing.Color]::FromArgb(40, 44, 55); $this.ForeColor = [System.Drawing.Color]::FromArgb(0, 200, 255) })

$btnOpenStoresModal.Add_Click({
    $modal = New-Object System.Windows.Forms.Form
    $modal.ClientSize = New-Object System.Drawing.Size(460, 300)
    $modal.StartPosition = "CenterParent"
    $modal.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
    $modal.BackColor = [System.Drawing.Color]::FromArgb(28, 30, 38)
    $modal.ForeColor = [System.Drawing.Color]::FromArgb(230, 230, 230)

    $modal.Add_MouseDown($modalDrag)
    $modalMove = {
        if ($_.Button -eq [System.Windows.Forms.MouseButtons]::Left -and $global:modalOffset) {
            $frm = $this.FindForm()
            $cur = [System.Windows.Forms.Cursor]::Position
            $frm.Location = New-Object System.Drawing.Point(($cur.X - $global:modalOffset.X), ($cur.Y - $global:modalOffset.Y))
        }
    }
    $modal.Add_MouseMove($modalMove)

    $btnCloseModal = New-Object System.Windows.Forms.Button
    $btnCloseModal.Text = "✕"
    $btnCloseModal.Size = New-Object System.Drawing.Size(40, 30)
    $btnCloseModal.Location = New-Object System.Drawing.Point(420, 0)
    $btnCloseModal.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btnCloseModal.FlatAppearance.BorderSize = 0
    $btnCloseModal.BackColor = [System.Drawing.Color]::FromArgb(28, 30, 38)
    $btnCloseModal.ForeColor = [System.Drawing.Color]::FromArgb(200, 200, 200)
    $btnCloseModal.Cursor = [System.Windows.Forms.Cursors]::Hand
    $btnCloseModal.Add_MouseEnter({ $this.BackColor = [System.Drawing.Color]::FromArgb(232, 17, 35); $this.ForeColor = [System.Drawing.Color]::White })
    $btnCloseModal.Add_MouseLeave({ $this.BackColor = [System.Drawing.Color]::FromArgb(28, 30, 38); $this.ForeColor = [System.Drawing.Color]::FromArgb(200, 200, 200) })
    $btnCloseModal.Add_Click({ $modal.Close() })
    $modal.Controls.Add($btnCloseModal)

    $lblModalTitle = New-Object System.Windows.Forms.Label
    $lblModalTitle.Text = "SELECIONE AS LOJAS PARA INSTALAÇÃO:"
    $lblModalTitle.Font = New-Object System.Drawing.Font -ArgumentList "Segoe UI", ([single]9.5), ([System.Drawing.FontStyle]::Bold)
    $lblModalTitle.ForeColor = [System.Drawing.Color]::FromArgb(100, 180, 255)
    $lblModalTitle.AutoSize = $true
    $lblModalTitle.Location = New-Object System.Drawing.Point(15, 15)
    $lblModalTitle.Add_MouseDown({
        if ($_.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
            $global:modalOffset = New-Object System.Drawing.Point(($_.X + $this.Location.X), ($_.Y + $this.Location.Y))
        }
    })
    $lblModalTitle.Add_MouseMove($modalMove)
    $modal.Controls.Add($lblModalTitle)

    $chkSelectAll = New-Object System.Windows.Forms.CheckBox
    $chkSelectAll.Text = "Marcar / Desmarcar Todos"
    $chkSelectAll.AutoSize = $true
    $chkSelectAll.Location = New-Object System.Drawing.Point((430 - $chkSelectAll.PreferredSize.Width), 213)
    $chkSelectAll.ForeColor = [System.Drawing.Color]::FromArgb(180, 190, 200)
    $chkSelectAll.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
    $chkSelectAll.Cursor = [System.Windows.Forms.Cursors]::Hand
    $modal.Controls.Add($chkSelectAll)

    $modalToolTip = New-Object System.Windows.Forms.Panel
    $modalToolTip.Size = New-Object System.Drawing.Size(300, 70)
    $modalToolTip.BackColor = [System.Drawing.Color]::FromArgb(35, 39, 46)
    $modalToolTip.Visible = $false
    $modalToolTip.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle

    $modalToolTipLbl = New-Object System.Windows.Forms.Label
    $modalToolTipLbl.Location = New-Object System.Drawing.Point(8, 8)
    $modalToolTipLbl.Size = New-Object System.Drawing.Size(282, 54)
    $modalToolTipLbl.ForeColor = [System.Drawing.Color]::FromArgb(220, 225, 235)
    $modalToolTipLbl.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
    $modalToolTip.Controls.Add($modalToolTipLbl)
    $modal.Controls.Add($modalToolTip)
    $modalToolTip.BringToFront()

    $storeItems = [ordered]@{
        "Steam"             = "Valve.Steam"
        "Epic Games Store"  = "EpicGames.EpicGamesLauncher"
        "GOG Galaxy"        = "GOG.Galaxy"
        "EA App"            = "ElectronicArts.EAApp"
        "Ubisoft Connect"   = "Ubisoft.Connect"
        "Battle.net"        = "Blizzard.BattleNet"
    }

    $storeDescriptions = @{
        "Steam"             = "Plataforma líder da Valve para jogos de PC, comunidade e biblioteca digital.";
        "Epic Games Store"  = "Loja da Epic Games com jogos gratuitos semanais e lançamentos de peso.";
        "GOG Galaxy"        = "Cliente da GOG sem DRM para gerenciar todos os seus jogos em um só lugar.";
        "EA App"            = "Aplicativo oficial da Electronic Arts para EA Play e franquias Battlefield/Fifa.";
        "Ubisoft Connect"   = "Launcher da Ubisoft para Assassin's Creed, Far Cry e recompensas exclusivas.";
        "Battle.net"        = "Plataforma oficial da Blizzard para Diablo, World of Warcraft, Overwatch e Call of Duty."
    }

    $colPanels = @()
    foreach ($cx in @(15, 235)) {
        $cp = New-Object System.Windows.Forms.Panel
        $cp.Location = New-Object System.Drawing.Point($cx, 75)
        $cp.Size = New-Object System.Drawing.Size(210, 124)
        $cp.BackColor = [System.Drawing.Color]::FromArgb(36, 39, 50)
        $modal.Controls.Add($cp)
        $colPanels += $cp
    }
    $checkBoxes = @()
    $idx = 0
    foreach ($storeName in $storeItems.Keys) {
        $idx++

        $lblNumModal = New-Object System.Windows.Forms.Label
        $lblNumModal.Text = ("{0:D2}" -f $idx)
        $lblNumModal.Font = New-Object System.Drawing.Font -ArgumentList "Segoe UI", ([single]8.5), ([System.Drawing.FontStyle]::Bold)
        $lblNumModal.ForeColor = [System.Drawing.Color]::FromArgb(120, 135, 155)
        $lblNumModal.AutoSize = $true
        $colI = ($idx - 1) % 2; $rowI = [Math]::Floor(($idx - 1) / 2)
        $lblNumModal.Location = New-Object System.Drawing.Point(8, (17 + ($rowI * 38)))
        $colPanels[$colI].Controls.Add($lblNumModal)

        $chk = New-Object System.Windows.Forms.CheckBox
        $chk.Text = $storeName
        $chk.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
        $chk.ForeColor = [System.Drawing.Color]::FromArgb(230, 235, 245)
        $chk.BackColor = [System.Drawing.Color]::FromArgb(36, 39, 50)
        $chk.UseVisualStyleBackColor = $false
        $chk.Size = New-Object System.Drawing.Size(172, 30)
        $chk.Location = New-Object System.Drawing.Point(34, (10 + ($rowI * 38)))
        $chk.Tag = @{ Id = $storeItems[$storeName]; Desc = $storeDescriptions[$storeName] }
        
        $chk.Add_MouseEnter({
            if ($this.Tag.Desc) {
                $modalToolTipLbl.Text = $this.Tag.Desc
                $pt = $modal.PointToClient([System.Windows.Forms.Cursor]::Position)
                $modalToolTip.Location = New-Object System.Drawing.Point(($pt.X + 10), ($pt.Y + 10))
                $modalToolTip.Visible = $true
                $modalToolTip.BringToFront()
            }
        })
        $chk.Add_MouseLeave({
            $modalToolTip.Visible = $false
        })

        $checkBoxes += $chk
        $colPanels[$colI].Controls.Add($chk)
    }

    $chkSelectAll.Add_CheckedChanged({
        $state = $this.Checked
        foreach ($c in $checkBoxes) { $c.Checked = $state }
    })

    $btnConfirm = New-Object System.Windows.Forms.Button
    $btnConfirm.Text = "Instalar Selecionadas"
    $btnConfirm.Size = New-Object System.Drawing.Size(400, 42)
    $btnConfirm.Location = New-Object System.Drawing.Point(30, 240)
    $btnConfirm.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btnConfirm.FlatAppearance.BorderSize = 0
    $btnConfirm.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
    $btnConfirm.ForeColor = [System.Drawing.Color]::White
    $btnConfirm.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 10)
    $btnConfirm.Cursor = [System.Windows.Forms.Cursors]::Hand
    $btnConfirm.Add_MouseEnter({ $this.BackColor = [System.Drawing.Color]::FromArgb(20, 140, 240) })
    $btnConfirm.Add_MouseLeave({ $this.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215) })

    $btnConfirm.Add_Click({
        $selected = @($checkBoxes | Where-Object { $_.Checked })
        if ($selected.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show("Nenhuma loja foi selecionada!", "Aviso", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            return
        }

        $passosLote = @()
        $sIdx = 0
        $totalSel = $selected.Count
        foreach ($c in $selected) {
            $sIdx++
            $passosLote += Passo $sIdx $totalSel "$($c.Text)" (W "$($c.Tag.Id)")
        }

        $modal.Close()
        Start-Task "Instalação de Launchers ($totalSel lojas)" (Lote $passosLote) -total $totalSel
    })

    $modal.Controls.Add($btnConfirm)
    [void]$modal.ShowDialog($form)
    $modal.Dispose()
})

$form.Controls.Add($btnOpenStoresModal)


# 14. O que deseja fazer no PC? (Colunas 2 e 3 unificadas na Linha 3 — Destaque Largo!)
$lblNum14 = New-Object System.Windows.Forms.Label
$lblNum14.Text = "14"
$lblNum14.Font = New-Object System.Drawing.Font -ArgumentList "Segoe UI", ([single]8.5), ([System.Drawing.FontStyle]::Bold)
$lblNum14.ForeColor = [System.Drawing.Color]::FromArgb(120, 135, 155)
$lblNum14.AutoSize = $true
$lblNum14.Location = New-Object System.Drawing.Point(388, 352)
$form.Controls.Add($lblNum14)

$btnWhatToDo = New-Object System.Windows.Forms.Button
$btnWhatToDo.Text = "O que deseja fazer no PC?  (Instalação Personalizada Total)"
$btnWhatToDo.Size = New-Object System.Drawing.Size(680, 38)
$btnWhatToDo.Location = New-Object System.Drawing.Point(412, 342)
$btnWhatToDo.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnWhatToDo.FlatAppearance.BorderSize = 0
$btnWhatToDo.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
$btnWhatToDo.ForeColor = [System.Drawing.Color]::White
$btnWhatToDo.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9.5)
$btnWhatToDo.Cursor = [System.Windows.Forms.Cursors]::Hand
$btnWhatToDo.Add_MouseEnter({ $this.BackColor = [System.Drawing.Color]::FromArgb(20, 140, 240) })
$btnWhatToDo.Add_MouseLeave({ $this.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215) })

$btnWhatToDo.Add_Click({
    $modalPC = New-Object System.Windows.Forms.Form
    $modalPC.ClientSize = New-Object System.Drawing.Size(460, 530)
    $modalPC.StartPosition = "CenterParent"
    $modalPC.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
    $modalPC.BackColor = [System.Drawing.Color]::FromArgb(28, 30, 38)
    $modalPC.ForeColor = [System.Drawing.Color]::FromArgb(230, 230, 230)

    $modalPC.Add_MouseDown($modalDrag)
    $modalMovePC = {
        if ($_.Button -eq [System.Windows.Forms.MouseButtons]::Left -and $global:modalOffset) {
            $frm = $this.FindForm()
            $cur = [System.Windows.Forms.Cursor]::Position
            $frm.Location = New-Object System.Drawing.Point(($cur.X - $global:modalOffset.X), ($cur.Y - $global:modalOffset.Y))
        }
    }
    $modalPC.Add_MouseMove($modalMovePC)

    $btnCloseModalPC = New-Object System.Windows.Forms.Button
    $btnCloseModalPC.Text = "✕"
    $btnCloseModalPC.Size = New-Object System.Drawing.Size(40, 30)
    $btnCloseModalPC.Location = New-Object System.Drawing.Point(420, 0)
    $btnCloseModalPC.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btnCloseModalPC.FlatAppearance.BorderSize = 0
    $btnCloseModalPC.BackColor = [System.Drawing.Color]::FromArgb(28, 30, 38)
    $btnCloseModalPC.ForeColor = [System.Drawing.Color]::FromArgb(200, 200, 200)
    $btnCloseModalPC.Cursor = [System.Windows.Forms.Cursors]::Hand
    $btnCloseModalPC.Add_MouseEnter({ $this.BackColor = [System.Drawing.Color]::FromArgb(232, 17, 35); $this.ForeColor = [System.Drawing.Color]::White })
    $btnCloseModalPC.Add_MouseLeave({ $this.BackColor = [System.Drawing.Color]::FromArgb(28, 30, 38); $this.ForeColor = [System.Drawing.Color]::FromArgb(200, 200, 200) })
    $btnCloseModalPC.Add_Click({ $modalPC.Close() })
    $modalPC.Controls.Add($btnCloseModalPC)

    $lblModalTitlePC = New-Object System.Windows.Forms.Label
    $lblModalTitlePC.Text = "INSTALAÇÃO PERSONALIZADA TOTAL:"
    $lblModalTitlePC.Font = New-Object System.Drawing.Font -ArgumentList "Segoe UI", ([single]9.5), ([System.Drawing.FontStyle]::Bold)
    $lblModalTitlePC.ForeColor = [System.Drawing.Color]::FromArgb(100, 180, 255)
    $lblModalTitlePC.AutoSize = $true
    $lblModalTitlePC.Location = New-Object System.Drawing.Point(15, 15)
    $lblModalTitlePC.Add_MouseDown({
        if ($_.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
            $global:modalOffset = New-Object System.Drawing.Point(($_.X + $this.Location.X), ($_.Y + $this.Location.Y))
        }
    })
    $lblModalTitlePC.Add_MouseMove($modalMovePC)
    $modalPC.Controls.Add($lblModalTitlePC)

    $chkSelectAllPC = New-Object System.Windows.Forms.CheckBox
    $chkSelectAllPC.Text = "Marcar / Desmarcar Todos"
    $chkSelectAllPC.AutoSize = $true
    $chkSelectAllPC.Location = New-Object System.Drawing.Point((430 - $chkSelectAllPC.PreferredSize.Width), 445)
    $chkSelectAllPC.ForeColor = [System.Drawing.Color]::FromArgb(180, 190, 200)
    $chkSelectAllPC.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
    $chkSelectAllPC.Cursor = [System.Windows.Forms.Cursors]::Hand
    $modalPC.Controls.Add($chkSelectAllPC)

    $modalToolTipPC = New-Object System.Windows.Forms.Panel
    $modalToolTipPC.Size = New-Object System.Drawing.Size(300, 70)
    $modalToolTipPC.BackColor = [System.Drawing.Color]::FromArgb(35, 39, 46)
    $modalToolTipPC.Visible = $false
    $modalToolTipPC.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle

    $modalToolTipLblPC = New-Object System.Windows.Forms.Label
    $modalToolTipLblPC.Location = New-Object System.Drawing.Point(8, 8)
    $modalToolTipLblPC.Size = New-Object System.Drawing.Size(282, 54)
    $modalToolTipLblPC.ForeColor = [System.Drawing.Color]::FromArgb(220, 225, 235)
    $modalToolTipLblPC.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
    $modalToolTipPC.Controls.Add($modalToolTipLblPC)
    $modalPC.Controls.Add($modalToolTipPC)
    $modalToolTipPC.BringToFront()

    $allCustomItems = [ordered]@{
        "Google Chrome"          = @{ Cmd = (W "Google.Chrome"); Desc = "Instala o navegador Google Chrome." }
        "WinRAR"                 = @{ Cmd = (W "RARLab.WinRAR"); Desc = "Instala o compactador WinRAR com chave de registro ativa." }
        "MSI Afterburner"        = @{ Cmd = (W "Guru3D.Afterburner"); Desc = "Instala o monitorador de hardware MSI Afterburner." }
        "Adobe Acrobat Reader"   = @{ Cmd = (W "Adobe.Acrobat.Reader.64-bit"); Desc = "Instala o leitor oficial de arquivos PDF Adobe Reader." }
        "Microsoft Office"       = @{ Cmd = $officeInstallAndShortcuts; Desc = "Instala o Microsoft Office 365 com atalhos na Área de Trabalho." }
        
        # Kit Gamer Desmembrado (Funções Blindadas com Timeout)
        "Desempenho Máximo"      = @{ Cmd = "Install-GamerPowerPlan"; Desc = "Ativa o plano oculto de Desempenho Máximo de Energia do Windows." }
        ".NET Framework 3.5"     = @{ Cmd = "Install-GamerNetFx3"; Desc = "Habilita o recurso essencial .NET Framework 3.5 para jogos e apps antigos." }
        ".NET Desktop Runtime 8" = @{ Cmd = "Install-GamerDotNet8"; Desc = "Instala os runtimes modernos do .NET 8 para aplicações atuais." }
        "Visual C++ Redist."     = @{ Cmd = "Install-GamerVCRedist"; Desc = "Instala os pacotes Visual C++ (WinGet, AIO ou Oficial MS sem travar)." }
        "DirectX Runtimes"       = @{ Cmd = "Install-GamerDirectX"; Desc = "Instala o DirectX (WinGet, Web Installer ou Offline Jun 2010)." }
        "App Oficial da GPU"     = @{ Cmd = "Install-GamerGPUApp"; Desc = "Detecta sua placa (NVIDIA, AMD ou Intel) e instala o software oficial de controle." }

        # Lojas de Jogos
        "Steam"                  = @{ Cmd = (W "Valve.Steam"); Desc = "Plataforma líder da Valve para jogos de PC, comunidade e biblioteca digital." }
        "Epic Games Store"       = @{ Cmd = (W "EpicGames.EpicGamesLauncher"); Desc = "Loja da Epic Games com jogos gratuitos semanais e lançamentos de peso." }
        "GOG Galaxy"             = @{ Cmd = (W "GOG.Galaxy"); Desc = "Cliente da GOG sem DRM para gerenciar todos os seus jogos em um só lugar." }
        "EA App"                 = @{ Cmd = (W "ElectronicArts.EAApp"); Desc = "Aplicativo oficial da Electronic Arts para EA Play e franquias Battlefield/Fifa." }
        "Ubisoft Connect"        = @{ Cmd = (W "Ubisoft.Connect"); Desc = "Launcher da Ubisoft para Assassin's Creed, Far Cry e recompensas exclusivas." }
        "Battle.net"             = @{ Cmd = (W "Blizzard.BattleNet"); Desc = "Plataforma oficial da Blizzard para Diablo, World of Warcraft, Overwatch e Call of Duty." }
        
        # Manutenção
        "Atualizar Windows"      = @{ Cmd = "Invoke-WindowsUpdate"; Desc = "Busca e instala todas as atualizações pendentes do Windows Update." }
        "Atualizar Drivers"      = @{ Cmd = "Invoke-DriverUpdate"; Desc = "Busca e instala atualizações de drivers oficiais via Windows Update." }
    }

    $colPanelsPC = @()
    foreach ($cx in @(15, 235)) {
        $cp = New-Object System.Windows.Forms.Panel
        $cp.Location = New-Object System.Drawing.Point($cx, 75)
        $cp.Size = New-Object System.Drawing.Size(210, 355)
        $cp.BackColor = [System.Drawing.Color]::FromArgb(36, 39, 50)
        $modalPC.Controls.Add($cp)
        $colPanelsPC += $cp
    }
    $checkBoxesPC = @()
    $idxPC = 0
    foreach ($itemName in $allCustomItems.Keys) {
        $idxPC++

        $lblNumModalPC = New-Object System.Windows.Forms.Label
        $lblNumModalPC.Text = ("{0:D2}" -f $idxPC)
        $lblNumModalPC.Font = New-Object System.Drawing.Font -ArgumentList "Segoe UI", ([single]8.5), ([System.Drawing.FontStyle]::Bold)
        $lblNumModalPC.ForeColor = [System.Drawing.Color]::FromArgb(120, 135, 155)
        $lblNumModalPC.AutoSize = $true
        $colI = ($idxPC - 1) % 2; $rowI = [Math]::Floor(($idxPC - 1) / 2)
        $lblNumModalPC.Location = New-Object System.Drawing.Point(8, (17 + ($rowI * 38)))
        $colPanelsPC[$colI].Controls.Add($lblNumModalPC)

        $chkPC = New-Object System.Windows.Forms.CheckBox
        $chkPC.Text = $itemName
        $chkPC.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9.5)
        $chkPC.ForeColor = [System.Drawing.Color]::FromArgb(230, 235, 245)
        $chkPC.BackColor = [System.Drawing.Color]::FromArgb(36, 39, 50)
        $chkPC.UseVisualStyleBackColor = $false
        $chkPC.Size = New-Object System.Drawing.Size(172, 30)
        $chkPC.Location = New-Object System.Drawing.Point(34, (10 + ($rowI * 38)))
        $chkPC.Tag = $allCustomItems[$itemName]
        
        $chkPC.Add_MouseEnter({
            if ($this.Tag.Desc) {
                $modalToolTipLblPC.Text = $this.Tag.Desc
                $pt = $modalPC.PointToClient([System.Windows.Forms.Cursor]::Position)
                $modalToolTipPC.Location = New-Object System.Drawing.Point(($pt.X + 10), ($pt.Y + 10))
                $modalToolTipPC.Visible = $true
                $modalToolTipPC.BringToFront()
            }
        })
        $chkPC.Add_MouseLeave({
            $modalToolTipPC.Visible = $false
        })

        $checkBoxesPC += $chkPC
        $colPanelsPC[$colI].Controls.Add($chkPC)
    }

    $chkSelectAllPC.Add_CheckedChanged({
        $statePC = $this.Checked
        foreach ($c in $checkBoxesPC) { $c.Checked = $statePC }
    })

    $btnConfirmPC = New-Object System.Windows.Forms.Button
    $btnConfirmPC.Text = "Instalar Recursos Selecionados"
    $btnConfirmPC.Size = New-Object System.Drawing.Size(400, 42)
    $btnConfirmPC.Location = New-Object System.Drawing.Point(30, 472)
    $btnConfirmPC.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btnConfirmPC.FlatAppearance.BorderSize = 0
    $btnConfirmPC.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
    $btnConfirmPC.ForeColor = [System.Drawing.Color]::White
    $btnConfirmPC.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 10)
    $btnConfirmPC.Cursor = [System.Windows.Forms.Cursors]::Hand
    $btnConfirmPC.Add_MouseEnter({ $this.BackColor = [System.Drawing.Color]::FromArgb(20, 140, 240) })
    $btnConfirmPC.Add_MouseLeave({ $this.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215) })

    $btnConfirmPC.Add_Click({
        $selectedPC = @($checkBoxesPC | Where-Object { $_.Checked })
        if ($selectedPC.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show("Nenhum item foi selecionado!", "Aviso", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            return
        }

        $passosPersonalizados = @()
        $pIdx = 0
        $totalPers = $selectedPC.Count
        foreach ($c in $selectedPC) {
            $pIdx++
            $passosPersonalizados += Passo $pIdx $totalPers "$($c.Text)" $c.Tag.Cmd
        }

        $modalPC.Close()
        Start-Task "Instalação Personalizada Total ($totalPers itens)" (Lote $passosPersonalizados) -total $totalPers
    })

    $modalPC.Controls.Add($btnConfirmPC)
    [void]$modalPC.ShowDialog($form)
    $modalPC.Dispose()
})

$form.Controls.Add($btnWhatToDo)

# =====================================================================
# SEÇÃO 8: CONSOLE DE TAREFAS FULL-WIDTH (1072px) + BARRA DE ROLAGEM REAL
# =====================================================================

$logTitle = New-Object System.Windows.Forms.Label
$logTitle.Text = "CONSOLE DE TAREFAS"
$logTitle.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$logTitle.ForeColor = [System.Drawing.Color]::FromArgb(100, 180, 255)
$logTitle.AutoSize = $true
$logTitle.Location = New-Object System.Drawing.Point(24, 396)
$form.Controls.Add($logTitle)

$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Text = "Aguardando ação..."
$lblStatus.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
$lblStatus.ForeColor = [System.Drawing.Color]::FromArgb(180, 190, 200)
$lblStatus.AutoSize = $true
$lblStatus.Location = New-Object System.Drawing.Point(210, 395)
$form.Controls.Add($lblStatus)

$progressBarBg = New-Object System.Windows.Forms.Panel
$progressBarBg.Location = New-Object System.Drawing.Point(24, 420)
$progressBarBg.Size = New-Object System.Drawing.Size(1072, 8)
$progressBarBg.BackColor = [System.Drawing.Color]::FromArgb(20, 22, 28)
$form.Controls.Add($progressBarBg)

$progressBarFill = New-Object System.Windows.Forms.Panel
$progressBarFill.Location = New-Object System.Drawing.Point(0, 0)
$progressBarFill.Size = New-Object System.Drawing.Size(0, 8)
$progressBarFill.BackColor = [System.Drawing.Color]::FromArgb(0, 150, 240)
$progressBarBg.Controls.Add($progressBarFill)

$progressPulse = New-Object System.Windows.Forms.Panel
$progressPulse.Location = New-Object System.Drawing.Point(-150, 0)
$progressPulse.Size = New-Object System.Drawing.Size(150, 8)
$progressPulse.BackColor = [System.Drawing.Color]::FromArgb(110, 235, 255)
$progressPulse.Visible = $false
$progressBarBg.Controls.Add($progressPulse)
$progressPulse.BringToFront()

$global:progressMax = 100.0
$global:progressVal = 0.0
$global:progressTarget = 0.0
$global:pulsePos = -150

function Update-CustomProgress($val) {
    $global:progressVal = [Math]::Max(0.0, [Math]::Min([double]$val, [double]$global:progressMax))
    if ($global:progressMax -gt 0) {
        $newWidth = [int](($global:progressVal / $global:progressMax) * 1072)
        $progressBarFill.Width = $newWidth
    }
}

# Timer rápido (35ms) para animação contínua e intermitente da barra de progresso
$animTimer = New-Object System.Windows.Forms.Timer
$animTimer.Interval = 35
$animTimer.Add_Tick({
    if ($global:tasks.Count -gt 0) {
        if ($global:progressVal -lt $global:progressTarget) {
            $step = ($global:progressTarget - $global:progressVal) * 0.015
            if ($step -lt 0.002) { $step = 0.002 }
            $global:progressVal = [Math]::Min($global:progressTarget, $global:progressVal + $step)
            Update-CustomProgress $global:progressVal
        }

        $progressPulse.Visible = $true
        $global:pulsePos += 28
        if ($global:pulsePos -gt 1072) {
            $global:pulsePos = -150
        }
        $progressPulse.Left = $global:pulsePos
    } else {
        $progressPulse.Visible = $false
    }
})
$animTimer.Start()

$logContainer = New-Object System.Windows.Forms.Panel
$logContainer.Location = New-Object System.Drawing.Point(24, 436)
$logContainer.Size = New-Object System.Drawing.Size(1072, 184)
$logContainer.BackColor = [System.Drawing.Color]::FromArgb(20, 22, 28)
$form.Controls.Add($logContainer)

$logBox = New-Object System.Windows.Forms.TextBox
$logBox.Multiline = $true
$logBox.ReadOnly = $true
$logBox.WordWrap = $true
$logBox.ScrollBars = "None"
$logBox.Location = New-Object System.Drawing.Point(10, 6)
$logBox.Size = New-Object System.Drawing.Size(1036, 172)
$logBox.BackColor = [System.Drawing.Color]::FromArgb(20, 22, 28)
$logBox.ForeColor = [System.Drawing.Color]::FromArgb(215, 220, 230)
$logBox.Font = New-Object System.Drawing.Font("Consolas", 9.5)
$logBox.BorderStyle = [System.Windows.Forms.BorderStyle]::None
$logContainer.Controls.Add($logBox)

$customScrollBg = New-Object System.Windows.Forms.Panel
$customScrollBg.Location = New-Object System.Drawing.Point(1054, 0)
$customScrollBg.Size = New-Object System.Drawing.Size(18, 184)
$customScrollBg.BackColor = [System.Drawing.Color]::FromArgb(26, 30, 40)
$customScrollBg.Cursor = [System.Windows.Forms.Cursors]::Hand
$logContainer.Controls.Add($customScrollBg)

$customScrollThumb = New-Object System.Windows.Forms.Panel
$customScrollThumb.Location = New-Object System.Drawing.Point(3, 2)
$customScrollThumb.Size = New-Object System.Drawing.Size(12, 180)
$customScrollThumb.BackColor = [System.Drawing.Color]::FromArgb(75, 85, 105)
$customScrollThumb.Cursor = [System.Windows.Forms.Cursors]::Hand
$customScrollBg.Controls.Add($customScrollThumb)

# Sincronização completa da Barra de Rolagem (MouseWheel, Arraste e Clique na Trilha)
$global:scrollDragging = $false
$global:scrollDragOffsetY = 0

function Get-LogVisibleLines {
    $lineHeight = [Math]::Max(14, $logBox.Font.Height)
    return [Math]::Max(1, [int][Math]::Floor($logBox.ClientSize.Height / $lineHeight))
}

function Update-CustomScroll {
    if (-not $logBox.IsHandleCreated) { return }
    $totalLines = [int][WinAPI.Desktop]::SendMessage($logBox.Handle, 0x00BA, [IntPtr]::Zero, [IntPtr]::Zero) # EM_GETLINECOUNT
    $firstVisible = [int][WinAPI.Desktop]::SendMessage($logBox.Handle, 0x00CE, [IntPtr]::Zero, [IntPtr]::Zero) # EM_GETFIRSTVISIBLELINE
    $visibleLines = Get-LogVisibleLines
    $trackHeight = $customScrollBg.Height - 4

    if ($totalLines -le $visibleLines) {
        $customScrollThumb.Height = $trackHeight
        $customScrollThumb.Top = 2
        return
    }

    $thumbHeight = [Math]::Max(26, [int](($visibleLines / $totalLines) * $trackHeight))
    $customScrollThumb.Height = $thumbHeight

    $maxFirst = [Math]::Max(1, $totalLines - $visibleLines)
    $ratio = [Math]::Max(0.0, [Math]::Min(1.0, $firstVisible / $maxFirst))
    $maxThumbTop = $trackHeight - $thumbHeight
    $customScrollThumb.Top = 2 + [int]($ratio * $maxThumbTop)
}

function Set-LogScrollByThumbTop([int]$desiredTop) {
    if (-not $logBox.IsHandleCreated) { return }
    $totalLines = [int][WinAPI.Desktop]::SendMessage($logBox.Handle, 0x00BA, [IntPtr]::Zero, [IntPtr]::Zero)
    $firstVisible = [int][WinAPI.Desktop]::SendMessage($logBox.Handle, 0x00CE, [IntPtr]::Zero, [IntPtr]::Zero)
    $visibleLines = Get-LogVisibleLines
    if ($totalLines -le $visibleLines) { return }

    $trackHeight = $customScrollBg.Height - 4
    $maxThumbTop = [Math]::Max(1, $trackHeight - $customScrollThumb.Height)
    $clampedTop = [Math]::Max(2, [Math]::Min(2 + $maxThumbTop, $desiredTop))
    $customScrollThumb.Top = $clampedTop

    $ratio = ($clampedTop - 2) / $maxThumbTop
    $targetLine = [int][Math]::Round($ratio * ($totalLines - $visibleLines))
    $delta = $targetLine - $firstVisible
    if ($delta -ne 0) {
        [void][WinAPI.Desktop]::SendMessage($logBox.Handle, 0x00B6, [IntPtr]::Zero, [IntPtr]$delta) # EM_LINESCROLL
    }
}

$logBox.Add_MouseWheel({
    param($sender, $e)
    $linesToScroll = if ($e.Delta -gt 0) { -3 } else { 3 }
    [void][WinAPI.Desktop]::SendMessage($logBox.Handle, 0x00B6, [IntPtr]::Zero, [IntPtr]$linesToScroll)
    Update-CustomScroll
})

$logBox.Add_KeyUp({ Update-CustomScroll })
$logBox.Add_TextChanged({ Update-CustomScroll })

$customScrollThumb.Add_MouseEnter({ $this.BackColor = [System.Drawing.Color]::FromArgb(0, 170, 255) })
$customScrollThumb.Add_MouseLeave({ if (-not $global:scrollDragging) { $this.BackColor = [System.Drawing.Color]::FromArgb(75, 85, 105) } })

$customScrollThumb.Add_MouseDown({
    param($sender, $e)
    if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
        $global:scrollDragging = $true
        $global:scrollDragOffsetY = $e.Y
        $customScrollThumb.BackColor = [System.Drawing.Color]::FromArgb(0, 190, 255)
    }
})

$customScrollThumb.Add_MouseMove({
    param($sender, $e)
    if ($global:scrollDragging) {
        $ptInBg = $customScrollBg.PointToClient([System.Windows.Forms.Cursor]::Position)
        Set-LogScrollByThumbTop ($ptInBg.Y - $global:scrollDragOffsetY)
    }
})

$customScrollThumb.Add_MouseUp({
    $global:scrollDragging = $false
    $customScrollThumb.BackColor = [System.Drawing.Color]::FromArgb(75, 85, 105)
})

$customScrollBg.Add_MouseDown({
    param($sender, $e)
    if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
        $targetTop = $e.Y - [int]($customScrollThumb.Height / 2)
        Set-LogScrollByThumbTop $targetTop
    }
})

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 800

function Ler-Novas($t) {
    if (-not (Test-Path $t.Out)) { return }
    $linhas = @(Get-Content $t.Out -ErrorAction SilentlyContinue)
    for ($k = $t.Lido; $k -lt $linhas.Count; $k++) {
        $l = "$($linhas[$k])".Trim()
        if ($l -match '^##AGORA \[(\d+)/(\d+)\] (.+)$') {
            Log ("  > Instalando agora: " + $matches[3] + " (" + $matches[1] + "/" + $matches[2] + ")")
            $lblStatus.Text = "Instalando agora: " + $matches[3] + " (" + $matches[1] + "/" + $matches[2] + ")"
            $atual = [double]$matches[1]
            $totalEtapas = [double]$matches[2]
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
            Start-Sleep -Milliseconds 200
            Ler-Novas $t
            Log ("=== Fim: " + $t.Nome + " | instalados: " + $t.Ok + " | ja tinha: " + $t.Ja + " | erros: " + $t.Erro + " ===")
            Remove-Item -LiteralPath $t.Worker -Force -ErrorAction SilentlyContinue
            $global:tasks.Remove($t)
            if ($global:tasks.Count -gt 0) {
                $lblStatus.Text = "Ainda em andamento: " + $global:tasks[0].Nome + " (" + $global:tasks.Count + " na fila)"
            } else {
                $progressPulse.Visible = $false
                $global:progressTarget = $global:progressMax
                Update-CustomProgress $global:progressMax
                if ($t.Erro -gt 0) {
                    $lblStatus.Text = "Concluido com erros - veja o log"
                    $lblStatus.ForeColor = [System.Drawing.Color]::FromArgb(255, 90, 90)
                    $progressBarFill.BackColor = [System.Drawing.Color]::FromArgb(220, 65, 75)
                } else {
                    $lblStatus.Text = "Concluido com sucesso!"
                    $lblStatus.ForeColor = [System.Drawing.Color]::FromArgb(0, 255, 160)
                    $progressBarFill.BackColor = [System.Drawing.Color]::FromArgb(0, 210, 130)
                }
            }
        }
    }
})
$timer.Start()


# =====================================================================
# SEÇÃO 9: RODAPÉ (BOTÃO ENCERRAR, MARCAS E VERSÃO)
# =====================================================================
$sair = New-Object System.Windows.Forms.Button
$sair.Text = "Encerrar Ferramenta"
$sair.Size = New-Object System.Drawing.Size(170, 38)
$sair.Location = New-Object System.Drawing.Point(24, 634)
$form.Controls.Add($sair)
$sair.BringToFront()
$sair.FlatStyle = "Flat"
$sair.FlatAppearance.BorderSize = 0
$sair.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Regular)
$sair.BackColor = [System.Drawing.Color]::FromArgb(180, 50, 60)
$sair.ForeColor = [System.Drawing.Color]::White
$sair.Cursor = [System.Windows.Forms.Cursors]::Hand
$sair.Add_MouseEnter({ $this.BackColor = [System.Drawing.Color]::FromArgb(220, 60, 70) })
$sair.Add_MouseLeave({ $this.BackColor = [System.Drawing.Color]::FromArgb(180, 50, 60) })
$sair.Add_Click({ 
    try {
        Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction SilentlyContinue
        Set-MpPreference -DisableBehaviorMonitoring $false -ErrorAction SilentlyContinue
        Set-MpPreference -DisableBlockAtFirstSeen $false -ErrorAction SilentlyContinue
        Set-MpPreference -DisableIOAVProtection $false -ErrorAction SilentlyContinue
        Set-MpPreference -DisableScriptScanning $false -ErrorAction SilentlyContinue
        Set-MpPreference -SubmitSamplesConsent 0 -ErrorAction SilentlyContinue
        Set-MpPreference -MAPSReporting 1 -ErrorAction SilentlyContinue
    } catch {}
    $form.Close() 
})

$watermark = New-Object System.Windows.Forms.Label
$watermark.Text = "Desenvolvido por: Elson (Criatividade E Tudo)"
$watermark.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
$watermark.ForeColor = [System.Drawing.Color]::FromArgb(100, 110, 120)
$watermark.AutoSize = $true
$watermark.Location = New-Object System.Drawing.Point(435, 645)
$form.Controls.Add($watermark)

$versaoLabel = New-Object System.Windows.Forms.Label
$versaoLabel.Text = "v0.71"
$versaoLabel.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
$versaoLabel.ForeColor = [System.Drawing.Color]::FromArgb(100, 110, 120)
$versaoLabel.AutoSize = $true
$versaoLabel.Location = New-Object System.Drawing.Point(1058, 645)
$form.Controls.Add($versaoLabel)


# =====================================================================
# EXECUÇÃO E LIMPEZA FINAL DO WINDOWS FORMS
# =====================================================================
$form.Show()
Update-CustomScroll
[System.Windows.Forms.Application]::Run($form)

$netTimer.Stop()
$netTimer.Dispose()
$animTimer.Stop()
$animTimer.Dispose()
$timer.Stop()
$timer.Dispose()
$form.Dispose()
#PSEND
