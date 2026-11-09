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

# 2.6 - Atualizar o Shell do Windows (Refresh Desktop)
$refreshCode = @'
[System.Runtime.InteropServices.DllImport("Shell32.dll")]
public static extern int SHChangeNotify(int eventId, int flags, IntPtr item1, IntPtr item2);
public static void Atualizar() { SHChangeNotify(0x08000000, 0x1000, IntPtr.Zero, IntPtr.Zero); }
'@
Add-Type -MemberDefinition $refreshCode -Namespace "WinAPI" -Name "Desktop" -ErrorAction SilentlyContinue
[WinAPI.Desktop]::Atualizar()


# =====================================================================
# SEÇÃO 3: FUNÇÕES DE SUPORTE E INSTALAÇÃO DE APLICATIVOS (WINGS / FALLBACKS)
# =====================================================================

$appInstallHelpers = @'
$ProgressPreference = 'SilentlyContinue'

function Get-VerifiedInstaller {
    param([string]$Uri, [string]$FileName, [string]$PublisherPattern)
    $path = Join-Path $env:TEMP $FileName
    Invoke-WebRequest -Uri $Uri -OutFile $path -UseBasicParsing -ErrorAction Stop
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
        throw 'Link de instalacao fora dos servidores oficiais da Adobe.'
    }
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    $path = Join-Path $env:TEMP ('AdobeReader_' + [guid]::NewGuid().ToString('N') + '.exe')
    foreach ($method in @('PowerShell','BITS','curl')) {
        try {
            switch ($method) {
                'PowerShell' { Invoke-WebRequest -Uri $Uri -OutFile $path -UseBasicParsing -TimeoutSec 900 -ErrorAction Stop }
                'BITS' {
                    Import-Module BitsTransfer -ErrorAction Stop
                    $job = Start-BitsTransfer -Source $Uri -Destination $path -Asynchronous -ErrorAction Stop
                    $deadline = (Get-Date).AddMinutes(15)
                    while ($true) {
                        $job = Get-BitsTransfer -Id $job.Id -ErrorAction Stop
                        if ($job.JobState -eq 'Transferred') { Complete-BitsTransfer -BitsJob $job -ErrorAction Stop; break }
                        if ($job.JobState -in @('Error','Cancelled','Suspended') -or (Get-Date) -gt $deadline) { throw 'BITS interrompido' }
                        Start-Sleep -Seconds 2
                    }
                }
                'curl' {
                    $curl = Get-Command curl.exe -ErrorAction Stop
                    & $curl.Source --fail --location --silent --show-error --connect-timeout 30 --max-time 900 --retry 2 --output $path $Uri
                    if ($LASTEXITCODE -ne 0) { throw 'curl falhou' }
                }
            }
            if (-not (Test-Path -LiteralPath $path) -or (Get-Item -LiteralPath $path).Length -lt 1000000) { throw 'Arquivo incompleto' }
            $sig = Get-AuthenticodeSignature -FilePath $path
            if ($sig.Status -ne 'Valid' -or -not $sig.SignerCertificate -or $sig.SignerCertificate.Subject -notmatch '(?i)(CN|O)=Adobe (Inc\.|Systems Incorporated)(?:,|$)') {
                throw 'Assinatura Adobe invalida'
            }
            return $path
        } catch {
            Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
        }
    }
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
        $listing = Invoke-RestMethod -Uri 'https://api.github.com/repos/microsoft/winget-pkgs/contents/manifests/a/Adobe/Acrobat/Reader/64-bit' -Headers $headers -TimeoutSec 30 -ErrorAction Stop
        $versions = @($listing | Where-Object { $_.type -eq 'dir' -and $_.name -match '^\d+\.\d+\.\d+$' } | Sort-Object { [version]$_.name } -Descending | Select-Object -First 3)
        foreach ($version in $versions) {
            try {
                $manifestUrl = 'https://raw.githubusercontent.com/microsoft/winget-pkgs/master/manifests/a/Adobe/Acrobat/Reader/64-bit/' + $version.name + '/Adobe.Acrobat.Reader.64-bit.installer.yaml'
                $manifest = Invoke-WebRequest -Uri $manifestUrl -UseBasicParsing -TimeoutSec 30 -ErrorAction Stop
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
        $proc = Start-Process -FilePath $setup -ArgumentList '-sfx_nu /sAll /rs /msi EULA_ACCEPT=YES' -Wait -PassThru -ErrorAction Stop
        $code = [int]$proc.ExitCode
        if ($code -in @(0,3010,1641)) { $global:LASTEXITCODE = 0 }
        elseif ($code -eq 1638 -and (Test-AdobeReaderInstalled)) { $global:LASTEXITCODE = -1978335189 }
        else { $global:LASTEXITCODE = if ($code -ne 0) { $code } else { 1 } }
    } catch {
        $global:LASTEXITCODE = 1
    } finally { Remove-Item -LiteralPath $setup -Force -ErrorAction SilentlyContinue }
}

function Get-PackageVerifiedDownload {
    param([string]$Uri, [string]$Name, [string]$Extension, [string]$Sha256)
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    $path = Join-Path $env:TEMP ('Setup_' + [guid]::NewGuid().ToString('N') + '.' + $Extension)
    foreach ($method in @('PowerShell','BITS','curl')) {
        try {
            switch ($method) {
                'PowerShell' { Invoke-WebRequest -Uri $Uri -OutFile $path -UseBasicParsing -TimeoutSec 900 -ErrorAction Stop }
                'BITS' {
                    Import-Module BitsTransfer -ErrorAction Stop
                    $job = Start-BitsTransfer -Source $Uri -Destination $path -Asynchronous -ErrorAction Stop
                    $deadline = (Get-Date).AddMinutes(15)
                    while ($true) {
                        $job = Get-BitsTransfer -Id $job.Id -ErrorAction Stop
                        if ($job.JobState -eq 'Transferred') { Complete-BitsTransfer -BitsJob $job -ErrorAction Stop; break }
                        if ($job.JobState -in @('Error','Cancelled','Suspended') -or (Get-Date) -gt $deadline) { throw 'BITS interrompido' }
                        Start-Sleep -Seconds 2
                    }
                }
                'curl' {
                    $curl = Get-Command curl.exe -ErrorAction Stop
                    & $curl.Source --fail --location --silent --show-error --connect-timeout 30 --max-time 900 --retry 2 --output $path $Uri
                    if ($LASTEXITCODE -ne 0) { throw 'curl falhou' }
                }
            }
            if (-not (Test-Path -LiteralPath $path) -or (Get-Item -LiteralPath $path).Length -lt 1000000) { throw 'Arquivo incompleto' }
            if ($Sha256 -notmatch '^[A-Fa-f0-9]{64}$' -or (Get-FileHash -LiteralPath $path -Algorithm SHA256 -ErrorAction Stop).Hash -ne $Sha256) {
                throw 'Hash invalido'
            }
            return $path
        } catch {
            Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
        }
    }
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
        $listing = Invoke-RestMethod -Uri ('https://api.github.com/repos/microsoft/winget-pkgs/contents/manifests/' + $repo) -Headers $headers -TimeoutSec 30 -ErrorAction Stop
        $versions = @($listing | Where-Object { $_.type -eq 'dir' -and $_.name -match '^\d+\.\d+\.\d+(\.\d+)?$' } | Sort-Object { [version]$_.name } -Descending | Select-Object -First 3)
        foreach ($version in $versions) {
            try {
                $manifest = Invoke-WebRequest -Uri ('https://raw.githubusercontent.com/microsoft/winget-pkgs/master/manifests/' + $repo + '/' + $version.name + '/' + $Id + '.installer.yaml') -UseBasicParsing -TimeoutSec 30 -ErrorAction Stop
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
        $proc=Start-Process -FilePath $setup -ArgumentList $meta.Args -Wait -PassThru -ErrorAction Stop
        $code=[int]$proc.ExitCode
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
    $wingetCode = 1
    $wingetPath = $null
    if ($Id -in @('RARLab.WinRAR','Guru3D.Afterburner') -and (Test-MenuPackageInstalled -Id $Id)) {
        $global:LASTEXITCODE=-1978335189; return
    }
    if ($Id -eq 'Adobe.Acrobat.Reader.64-bit' -and (Test-AdobeReaderInstalled)) {
        $global:LASTEXITCODE = -1978335189
        return
    }
    try {
        $wingetCommand = Get-Command winget.exe -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($wingetCommand) { $wingetPath = $wingetCommand.Source }
        if (-not $wingetPath) {
            try {
                $appInstaller = Get-AppxPackage -Name Microsoft.DesktopAppInstaller -ErrorAction SilentlyContinue | Sort-Object Version -Descending | Select-Object -First 1
                if ($appInstaller) {
                    $candidate = Join-Path $appInstaller.InstallLocation 'winget.exe'
                    if (Test-Path $candidate) { $wingetPath = $candidate }
                }
            } catch {}
        }
        if ($wingetPath) {
            & $wingetPath install --exact --id $Id --source winget --silent --accept-package-agreements --accept-source-agreements --disable-interactivity
            $wingetCode = [int]$LASTEXITCODE
            if ($wingetCode -eq 0 -or $wingetCode -eq -1978335189) {
                $global:LASTEXITCODE = $wingetCode
                return
            }
        }
        switch ($Id) {
            'Google.Chrome' {
                $fileName = 'ChromeEnterprise_' + [guid]::NewGuid().ToString('N') + '.msi'
                $setup = Get-VerifiedInstaller -Uri 'https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise64.msi' -FileName $fileName -PublisherPattern '(?i)(CN=Google LLC|O=Google LLC)'
                $proc = Start-Process -FilePath (Join-Path $env:SystemRoot 'System32\msiexec.exe') -ArgumentList "/i `"$setup`" /qn /norestart" -Wait -PassThru
                $global:LASTEXITCODE = [int]$proc.ExitCode
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

function Log($msg) { $logBox.AppendText((Get-Date -Format 'HH:mm:ss') + "  " + $msg + "`r`n") }

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

function W($id) { "Install-AppFallback -Id '$id'" }

function Passo($n, $tot, $nome, $cmd) {
    "Write-Host '##AGORA [$n/$tot] $nome'; `$global:LASTEXITCODE = 0; $cmd; `$c = `$global:LASTEXITCODE; " +
    "if (`$c -eq 0) { Write-Host '##OK $nome' } elseif (`$c -eq -1978335189) { Write-Host '##JA $nome' } " +
    "else { Write-Host ('##ERRO $nome (codigo ' + `$c + ')'); `$global:falhou = 1 }"
}

function Lote($passos) { "`$global:falhou = 0; " + ($passos -join "; ") + "; `$global:LASTEXITCODE = [int]`$global:falhou" }


# =====================================================================
# SEÇÃO 6: CRIAÇÃO DA INTERFACE GRÁFICA (JANELA E BOTÕES)
# =====================================================================

$programIcon = [System.Drawing.SystemIcons]::Application

$form = New-Object System.Windows.Forms.Form
$form.Icon = $programIcon
$form.ShowIcon = $true
$form.Text = "ASSISTENTE DE FORMATAÇÃO PRO"
$form.ClientSize = New-Object System.Drawing.Size(1120, 720)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox = $false
$form.BackColor = [System.Drawing.Color]::FromArgb(12, 14, 20)
$form.ForeColor = [System.Drawing.Color]::White
$form.Font = New-Object System.Drawing.Font("Segoe UI", 10)

# Cabeçalho da Janela
$header = New-Object System.Windows.Forms.Panel
$header.Location = New-Object System.Drawing.Point(0, 0)
$header.Size = New-Object System.Drawing.Size(1120, 80)
$header.BackColor = [System.Drawing.Color]::FromArgb(20, 25, 35)
$form.Controls.Add($header)

$title = New-Object System.Windows.Forms.Label
$title.Text = "ASSISTENTE DE FORMATAÇÃO"
$title.Font = New-Object System.Drawing.Font("Segoe UI Black", 17, [System.Drawing.FontStyle]::Bold)
$title.ForeColor = [System.Drawing.Color]::FromArgb(0, 255, 160)
$title.AutoSize = $true
$title.Location = New-Object System.Drawing.Point(24, 10)
$header.Controls.Add($title)

$subTitle = New-Object System.Windows.Forms.Label
$subTitle.Text = "CENTRAL DE AUTOMAÇÃO  |  AÇÕES NUMERADAS"
$subTitle.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$subTitle.ForeColor = [System.Drawing.Color]::FromArgb(0, 180, 255)
$subTitle.AutoSize = $true
$subTitle.Location = New-Object System.Drawing.Point(27, 48)
$header.Controls.Add($subTitle)

# Botão Sair (Restaura o Defender e fecha)
$sair = New-Object System.Windows.Forms.Button
$sair.Text = "Sair"
$sair.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left
$sair.Location = New-Object System.Drawing.Point(20, ($form.ClientSize.Height - $sair.Height - 40))
$sair.Size = New-Object System.Drawing.Size(150, 50)
$form.Controls.Add($sair)
$sair.BringToFront()
$sair.FlatStyle = "Flat"
$sair.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$sair.BackColor = [System.Drawing.Color]::FromArgb(140, 20, 30)
$sair.ForeColor = [System.Drawing.Color]::White
$sair.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(255, 60, 80)
$sair.Cursor = [System.Windows.Forms.Cursors]::Hand
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

# Rótulos das Seções
$individualTitle = New-Object System.Windows.Forms.Label
$individualTitle.Text = "AÇÕES INDIVIDUAIS  |  01-06"
$individualTitle.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$individualTitle.ForeColor = [System.Drawing.Color]::FromArgb(0, 200, 220)
$individualTitle.AutoSize = $true
$individualTitle.Location = New-Object System.Drawing.Point(24, 101)
$form.Controls.Add($individualTitle)

$bundleTitle = New-Object System.Windows.Forms.Label
$bundleTitle.Text = "PACOTES E MANUTENÇÃO  |  07-12"
$bundleTitle.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$bundleTitle.ForeColor = [System.Drawing.Color]::FromArgb(0, 255, 160)
$bundleTitle.AutoSize = $true
$bundleTitle.Location = New-Object System.Drawing.Point(24, 432)
$form.Controls.Add($bundleTitle)


# =====================================================================
# SEÇÃO 7: DEFINIÇÃO DOS BOTÕES E AÇÕES DO MENU
# =====================================================================

$actions = [ordered]@{
    "Ativação Windows"           = { Start-Process powershell -ArgumentList "-NoProfile -WindowStyle Hidden -Command `"& ([ScriptBlock]::Create((irm https://get.activated.win))) `"" ; Log "Tela de Ativacao do Windows foi Aberta" }
    "Instalar Google Chrome"     = { Start-Task "Chrome" (Lote @(Passo 1 1 "Chrome" (W "Google.Chrome"))) }
    "Instalar WinRAR"            = { Start-Task "WinRAR" (Lote @(Passo 1 1 "WinRAR" (W "RARLab.WinRAR"))) }
    "Instalar MSI Afterburner"   = { Start-Task "Afterburner" (Lote @(Passo 1 1 "MSI Afterburner" (W "Guru3D.Afterburner"))) }
    "Instalar Adobe Reader"     = { Start-Task "Adobe Reader" (Lote @(Passo 1 1 "Adobe Acrobat Reader" (W "Adobe.Acrobat.Reader.64-bit"))) }
    "Instalar Apenas o Office" = { Start-Task "Office e atalhos" (Lote @(Passo 1 1 "Office" $officeInstallAndShortcuts)) }

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

    "Kit Gamer" = {
        Start-Task "Kit Gamer" (Lote @(
            'Write-Host "##AGORA [1/5] Ativando Desempenho Maximo..."; $guid = (powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61); if ($guid -match "([a-f0-9\-]{36})") { powercfg -setactive $Matches[1] }; Write-Host "##OK Desempenho Maximo"',
            'Write-Host "##AGORA [2/5] Habilitando .NET Framework 3.5..."; DISM /Online /Enable-Feature /FeatureName:NetFx3 /All /NoRestart /Quiet | Out-Null; Write-Host "##OK .NET Framework 3.5"',
            'Write-Host "##AGORA [3/5] Instalando .NET Desktop Runtime..."; $ok = $false; try { winget install -e --id Microsoft.DotNet.DesktopRuntime.8 --source winget --silent --accept-package-agreements --accept-source-agreements; if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq -1978335189) { $ok = $true } } catch {}; if (-not $ok) { $urls = @("https://aka.ms/dotnet/8.0/windowsdesktop-runtime-win-x64.exe", "https://download.visualstudio.microsoft.com/download/pr/9a622a4b-9706-47b2-a43c-660c6e8cf3a7/1779e3774883f360ecb3f7f02d04a621/windowsdesktop-runtime-8.0.10-win-x64.exe"); foreach ($u in $urls) { try { $p = "$env:TEMP\dotnet_runtime.exe"; Invoke-WebRequest -Uri $u -OutFile $p -UseBasicParsing; if ((Get-Item $p).Length -gt 1000000) { $proc = Start-Process -FilePath $p -ArgumentList "/install /quiet /norestart" -Wait -PassThru; if ($proc.ExitCode -eq 0) { $ok = $true; break } } } catch {} finally { Remove-Item -LiteralPath "$env:TEMP\dotnet_runtime.exe" -Force -ErrorAction SilentlyContinue } } }; if (-not $ok) { throw ".NET Desktop Runtime falhou" }; Write-Host "##OK .NET Desktop Runtime"',
            'Write-Host "##AGORA [4/5] Instalando Visual C++ Redistributable..."; $ok = $false; $vcUrls = @("https://github.com/abbodi1406/vcredist/releases/latest/download/VisualCppRedist_AIO_x86_x64.exe", "https://github.com/ChrisTitusTech/winutil/raw/main/vcredist.exe"); foreach ($u in $vcUrls) { try { $p = "$env:TEMP\vcredist.exe"; Invoke-WebRequest -Uri $u -OutFile $p -UseBasicParsing; if ((Get-Item $p).Length -gt 1000000) { Start-Process -FilePath $p -ArgumentList "-y /ai /q" -Wait; $ok = $true; break } } catch {} finally { Remove-Item -LiteralPath "$env:TEMP\vcredist.exe" -Force -ErrorAction SilentlyContinue } }; if (-not $ok) { throw "Visual C++ falhou" }; Write-Host "##OK Visual C++"',
            'Write-Host "##AGORA [5/5] Instalando DirectX Runtimes..."; $ok = $false; $dxUrls = @("https://download.microsoft.com/download/8/4/A/84A35BF1-DAFE-4AE8-B9BF-ACAF96D5B92F/directx_jun2010_redist.exe", "https://archive.org/download/directx_jun2010_redist/directx_jun2010_redist.exe"); foreach ($u in $dxUrls) { try { $d = "$env:TEMP\dxsetup.exe"; Invoke-WebRequest -Uri $u -OutFile $d -UseBasicParsing; if ((Get-Item $d).Length -gt 1000000) { Start-Process -FilePath $d -ArgumentList "/Q /T:$env:TEMP\DX" -Wait; Start-Process -FilePath "$env:TEMP\DX\DXSETUP.exe" -ArgumentList "/silent" -Wait; $ok = $true; break } } catch {} finally { Remove-Item -LiteralPath "$env:TEMP\dxsetup.exe" -Force -ErrorAction SilentlyContinue; Remove-Item -LiteralPath "$env:TEMP\DX" -Recurse -Force -ErrorAction SilentlyContinue } }; if (-not $ok) { throw "DirectX falhou" }; Write-Host "##OK DirectX"'
        )) -total 5
    }

    "Atualizar Windows" = {
        Start-Task "Atualizar Windows" (Lote @(
            'Write-Host "##AGORA [1/2] Iniciando varredura de atualizacoes do Windows..."; $session = New-Object -ComObject Microsoft.Update.Session; $searcher = $session.CreateUpdateSearcher(); $result = $searcher.Search("IsInstalled=0 and Type=\'Software\'"); if ($result.Updates.Count -eq 0) { Write-Host "##OK Nenhuma atualizacao pendente"; return }; Write-Host ("##INFO Encontradas " + $result.Updates.Count + " atualizacoes. Baixando e instalando..."); $downloader = $session.CreateUpdateDownloader(); $downloader.Updates = $result.Updates; $downloader.Download(); $installer = $session.CreateUpdateInstaller(); $installer.Updates = $result.Updates; $installResult = $installer.Install(); if ($installResult.ResultCode -eq 2) { Write-Host "##OK Atualizacao do Windows concluida com sucesso" } else { throw "Atualizacao finalizada com codigo de resultado: $($installResult.ResultCode)" }'
        )) -total 1
    }

    "Atualizar Drivers" = {
        Start-Task "Atualizar Drivers" (Lote @(
            'Write-Host "##AGORA [1/1] Buscando e instalando drivers oficiais via Windows Update..."; $session = New-Object -ComObject Microsoft.Update.Session; $searcher = $session.CreateUpdateSearcher(); $result = $searcher.Search("IsInstalled=0 and Type=\'Driver\'"); if ($result.Updates.Count -eq 0) { Write-Host "##OK Todos os drivers ja estao atualizados"; return }; Write-Host ("##INFO Encontrados " + $result.Updates.Count + " drivers para atualizar. Baixando..."); $downloader = $session.CreateUpdateDownloader(); $downloader.Updates = $result.Updates; $downloader.Download(); $installer = $session.CreateUpdateInstaller(); $installer.Updates = $result.Updates; $installResult = $installer.Install(); if ($installResult.ResultCode -eq 2) { Write-Host "##OK Drivers atualizados com sucesso" } else { throw "Instalacao de drivers concluida com codigo: $($installResult.ResultCode)" }'
        )) -total 1
    }
}

$actionNumber = 0
foreach ($name in $actions.Keys) {
    $actionNumber++
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = ("{0:D2}`r`n{1}" -f $actionNumber, $name)
    $btn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btn.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9.5)
    $btn.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $btn.Cursor = [System.Windows.Forms.Cursors]::Hand
    $btn.UseVisualStyleBackColor = $false

    if ($actionNumber -le 6) {
        $column = ($actionNumber - 1) % 2
        $row = [int][Math]::Floor(($actionNumber - 1) / 2)
        $btn.Size = New-Object System.Drawing.Size(292, 82)
        $btn.Location = New-Object System.Drawing.Point((24 + ($column * 310)), (143 + ($row * 94)))
        $btn.BackColor = [System.Drawing.Color]::FromArgb(24, 30, 42)
        $btn.ForeColor = [System.Drawing.Color]::FromArgb(220, 235, 255)
        $btn.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(0, 180, 220)
        $btn.FlatAppearance.BorderSize = 1
    } else {
        $colIdx = ($actionNumber - 7) % 3
        $rowIdx = [int][Math]::Floor(($actionNumber - 7) / 3)
        $btn.Size = New-Object System.Drawing.Size(196, 52)
        $btn.Location = New-Object System.Drawing.Point((24 + ($colIdx * 208)), (466 + ($rowIdx * 60)))
        
        if ($actionNumber -eq 7) {
            $btn.BackColor = [System.Drawing.Color]::FromArgb(15, 82, 112)
            $btn.ForeColor = [System.Drawing.Color]::White
            $btn.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(34, 211, 238)
        } elseif ($actionNumber -eq 8) {
            $btn.BackColor = [System.Drawing.Color]::FromArgb(76, 55, 120)
            $btn.ForeColor = [System.Drawing.Color]::White
            $btn.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(167, 139, 250)
        } elseif ($actionNumber -eq 9) {
            $btn.BackColor = [System.Drawing.Color]::FromArgb(20, 105, 74)
            $btn.ForeColor = [System.Drawing.Color]::FromArgb(230, 255, 240)
            $btn.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(52, 211, 153)
        } elseif ($actionNumber -eq 10) {
            $btn.BackColor = [System.Drawing.Color]::FromArgb(120, 30, 30)
            $btn.ForeColor = [System.Drawing.Color]::FromArgb(255, 230, 230)
            $btn.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(255, 80, 80)
        } elseif ($actionNumber -eq 11) {
            $btn.BackColor = [System.Drawing.Color]::FromArgb(30, 90, 130)
            $btn.ForeColor = [System.Drawing.Color]::FromArgb(220, 245, 255)
            $btn.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(80, 180, 255)
        } else {
            $btn.BackColor = [System.Drawing.Color]::FromArgb(90, 70, 30)
            $btn.ForeColor = [System.Drawing.Color]::FromArgb(255, 245, 220)
            $btn.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(255, 200, 80)
        }
        $btn.FlatAppearance.BorderSize = 2
    }

    $btn.Tag = @{ Acao = $actions[$name]; Cor = $btn.BackColor }
    $btn.Add_MouseEnter({ $this.BackColor = [System.Drawing.Color]::FromArgb(40, 55, 80) })
    $btn.Add_MouseLeave({ $this.BackColor = $this.Tag.Cor })
    $btn.Add_Click({ try { & $this.Tag.Acao } catch { [System.Windows.Forms.MessageBox]::Show("Erro: $_") } })
    $form.Controls.Add($btn)
}


# =====================================================================
# SEÇÃO 8: PAINEL DE STATUS, LOGS E TIMER DE EXECUÇÃO
# =====================================================================

$logTitle = New-Object System.Windows.Forms.Label
$logTitle.Text = "ACOMPANHAMENTO"
$logTitle.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$logTitle.ForeColor = [System.Drawing.Color]::FromArgb(0, 255, 160)
$logTitle.AutoSize = $true
$logTitle.Location = New-Object System.Drawing.Point(680, 101)
$form.Controls.Add($logTitle)

$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Text = "Aguardando comando..."
$lblStatus.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9)
$lblStatus.ForeColor = [System.Drawing.Color]::FromArgb(160, 175, 200)
$lblStatus.AutoSize = $true
$lblStatus.Location = New-Object System.Drawing.Point(680, 133)
$form.Controls.Add($lblStatus)

$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(680, 160)
$progressBar.Size = New-Object System.Drawing.Size(416, 20)
$progressBar.Style = [System.Windows.Forms.ProgressBarStyle]::Blocks
$form.Controls.Add($progressBar)

$logBox = New-Object System.Windows.Forms.TextBox
$logBox.Multiline = $true
$logBox.ReadOnly = $true
$logBox.ScrollBars = "Vertical"
$logBox.Location = New-Object System.Drawing.Point(680, 190)
$logBox.Size = New-Object System.Drawing.Size(416, 430)
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
$watermark.Location = New-Object System.Drawing.Point(680, 645)
$form.Controls.Add($watermark)

# Timer de atualização dos logs da fila
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 1000

function Ler-Novas($t) {
    if (-not (Test-Path $t.Out)) { return }
    $linhas = @(Get-Content $t.Out -ErrorAction SilentlyContinue)
    for ($k = $t.Lido; $k -lt $linhas.Count; $k++) {
        $l = "$($linhas[$k])".Trim()
        if ($l -match '^##AGORA \[(\d+)/(\d+)\] (.+)$') {
            Log ("  > Instalando agora: " + $matches[3] + " (" + $matches[1] + "/" + $matches[2] + ")")
            $lblStatus.Text = "Instalando agora: " + $matches[3] + " (" + $matches[1] + "/" + $matches[2] + ")"
            if ($global:totalEtapas -gt 1) { $progressBar.Value = [Math]::Min([int]$matches[1] - 1, $progressBar.Maximum) }
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


# =====================================================================
# SEÇÃO 9: CONTROLE DE VERSÃO (FÁCIL ALTERAÇÃO NA ÚLTIMA LINHA)
# =====================================================================
$versaoLabel = New-Object System.Windows.Forms.Label
$versaoLabel.Text = "VERSÃO 0.30"
$versaoLabel.Font = New-Object System.Drawing.Font("Segoe UI Black", 14, [System.Drawing.FontStyle]::Bold)
$versaoLabel.ForeColor = [System.Drawing.Color]::FromArgb(255, 220, 0)
$versaoLabel.AutoSize = $true
$versaoLabel.Location = New-Object System.Drawing.Point(950, 640)
$form.Controls.Add($versaoLabel)


# =====================================================================
# EXECUÇÃO E LIMPEZA FINAL DO WINDOWS FORMS
# =====================================================================
$form.Show()
[System.Windows.Forms.Application]::Run($form)

$timer.Stop()
$timer.Dispose()
$form.Dispose()
#PSEND