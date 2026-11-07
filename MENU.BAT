@echo off
REM Inicia o BAT sem mostrar os comandos do CMD na tela.
REM A tentativa de net session verifica se o processo atual tem privilégios administrativos.
net session >nul 2>&1
if errorlevel 1 (
  REM Se não estiver elevado, pede ao Windows para reabrir este mesmo BAT como administrador.
  powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)
REM Guarda a unidade de origem e o caminho completo deste arquivo.
REM INSTALLER_FILE permite ao PowerShell localizar o codigo do menu.
set "BATDRIVE=%~d0"
set "INSTALLER_FILE=%~f0"
REM O PowerShell é iniciado oculto; a interface visível é criada depois com Windows Forms.
REM Bypass afeta a política desta chamada; STA é necessário para os componentes gráficos usados.
powershell -NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -Command "$s=[IO.File]::ReadAllText($env:INSTALLER_FILE); $a=$s.IndexOf('#'+'PSSTART'); $b=$s.IndexOf('#'+'PSEND'); try { iex $s.Substring($a, $b-$a) } catch { Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.MessageBox]::Show(\"Erro no menu: $_\") }"
exit /b

#PSSTART
# O Office e baixado do GitHub e validado antes da instalacao.
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# =====================================================================
# CONFIGURACOES INICIAIS E VARIAVEIS
# =====================================================================
# Unidade de onde o BAT foi aberto e caminho-base configurado para arquivos da rotina.
$drive     = $env:BATDRIVE
$BASE      = "$drive\Windows\Tudo"
$KEY       = "$BASE\rarreg.key"
$WINRARDIR = "C:\Program Files\WinRAR"
# =====================================================================
# TWEAKS DO SISTEMA (Executados invisivelmente ao abrir o BAT)
# =====================================================================

# --- GERADOR AUTOMATICO DO ARQUIVO RARREG ---

if (-not (Test-Path "$WINRARDIR\rarreg.key")) {
    if (-not (Test-Path $WINRARDIR)) { New-Item -ItemType Directory -Force -Path $WINRARDIR | Out-Null }
    $txtPath = "$WINRARDIR\rarreg.txt"
    Set-Content -Path $txtPath -Value "RAR registration data`r`nchattchitto.com`r`nUnlimited Company License`r`nUID=45cf7e253572312b6995`r`n64122122506995900ddabb88b22559b8f25d88e1168dd8cea3bd59`r`nfe190143727199246a8460fce6cb5ffde62890079861be57638717`r`n7131ced835ed65cc743d9777f2ea71a8e32c7e593cf66794343565`r`nb41bcf56929486b8bcdac33d50ecf7739960e36503ffdcbcf7dbfc`r`n378eb1e8a5d96ddf9e5c7d6e7b122c103ee81bce156ee5ec1cf50d`r`n174c5a231523f967f5c53a4efdc7ecb9689f18a2ed6166f7608276`r`n7f5dd734a2736b2d5fb6eb5145b50ed0c7033251fe142027056408" -Force
    Rename-Item -Path $txtPath -NewName "rarreg.key" -Force
}
# --------------------------------------------

# CONFIGURAÇÃO DE ENERGIA: define tela e suspensão como "nunca" na tomada e na bateria.
# Também desativa completamente a hibernação; essas alterações não são restauradas ao sair.
# Falhas ou opções não suportadas são ignoradas pelo try/catch para não interromper o menu.
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

# --- DESATIVAR TODAS AS PROTECOES E TEMPO REAL AO ABRIR ---
try {
    Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue
    Set-MpPreference -DisableBehaviorMonitoring $true -ErrorAction SilentlyContinue
    Set-MpPreference -DisableBlockAtFirstSeen $true -ErrorAction SilentlyContinue
    Set-MpPreference -DisableIOAVProtection $true -ErrorAction SilentlyContinue
    Set-MpPreference -DisableScriptScanning $true -ErrorAction SilentlyContinue
    Set-MpPreference -SubmitSamplesConsent 2 -ErrorAction SilentlyContinue
    Set-MpPreference -MAPSReporting 0 -ErrorAction SilentlyContinue
} catch {}

# Ajusta valores do Registro do usuário atual para exibir ícones clássicos na Área de Trabalho.
# Os identificadores abaixo correspondem a Este Computador, Pasta do Usuário e Painel de Controle.
# --- ATIVAR ICONES DA AREA DE TRABALHO (Meu Computador, Usuario e Painel de Controle) ---
$iconsPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel"
if (-not (Test-Path $iconsPath)) { New-Item -Path $iconsPath -Force | Out-Null }
Set-ItemProperty -Path $iconsPath -Name "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" -Value 0 -Type DWord -Force 
Set-ItemProperty -Path $iconsPath -Name "{59031a47-3f72-44a7-89c5-5595fe6b30ee}" -Value 0 -Type DWord -Force 
Set-ItemProperty -Path $iconsPath -Name "{5399E694-6CE5-4D6C-8FCE-1D8870FDCBA0}" -Value 0 -Type DWord -Force 

# Registra o Visualizador de Fotos clássico para os formatos de imagem listados.
# Isso disponibiliza as associações no Registro, mas não garante que ele vire o aplicativo padrão do usuário.
# --- ATIVAR VISUALIZADOR DE FOTOS CLASSICO (SILENCIOSO) ---
$photoPath = "HKLM:\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations"
if (-not (Test-Path $photoPath)) { New-Item -Path $photoPath -Force | Out-Null }
foreach ($ext in @('.jpg','.jpeg','.png','.bmp','.gif','.tif','.tiff')) {
    New-ItemProperty -Path $photoPath -Name $ext -Value 'PhotoViewer.FileAssoc.Tiff' -PropertyType String -Force | Out-Null
}

# Declara a chamada nativa SHChangeNotify e avisa o Explorer que configurações do shell mudaram.
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

# --- COPIADOR DE ATALHOS DO OFFICE ---
# Este comando procura atalhos do Office nos menus Iniciar do usuário e do computador.
# Copia os atalhos encontrados para "Office 365" na Área de Trabalho; não cria atalhos que não existam.
$officeShortcuts = '$achou = $false; $desk = Join-Path ([Environment]::GetFolderPath("Desktop")) "Office 365"; $pastas = @("$env:ProgramData\Microsoft\Windows\Start Menu\Programs", "$env:APPDATA\Microsoft\Windows\Start Menu\Programs"); foreach ($app in @("*Word*.lnk", "*Excel*.lnk", "*PowerPoint*.lnk", "*Access*.lnk", "*Publisher*.lnk", "*OneNote*.lnk")) { foreach ($dir in $pastas) { if (Test-Path $dir) { $arquivos = Get-ChildItem -Path $dir -Filter $app -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Name -notmatch "Wordpad|Voice" }; foreach ($arq in $arquivos) { if (-not $achou) { if (-not (Test-Path $desk)) { New-Item -ItemType Directory -Force -Path $desk | Out-Null }; $achou = $true }; Copy-Item -Path $arq.FullName -Destination $desk -Force } } } }; if ($achou) { Write-Host "##INFO Atalhos do Office copiados com sucesso!" } else { Write-Host "##INFO Nenhum atalho achado. O Office ja terminou de instalar?" }'
# Worker do Office: inicia o instalador e acompanha o processo sem congelar a janela principal.
$officeWaitAndClose = @'
# Guarda o processo inicial; os processos filhos do instalador também serão monitorados.
$processo = Start-Process -FilePath $exe -PassThru
# Guarda os IDs do instalador e dos processos descendentes para não confundir outras janelas com o Office.
$officePids = New-Object 'System.Collections.Generic.HashSet[int]'
[void]$officePids.Add([int]$processo.Id)
$officeUiaReady = $false
try { Add-Type -AssemblyName UIAutomationClient; Add-Type -AssemblyName UIAutomationTypes; $officeUiaReady = $true } catch {}
$officeConcluidoFechado = $false
while ($true) {
    # Atualiza a lista de processos do Windows para acompanhar o instalador e os componentes que ele iniciou.
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
    # Se a automação de interface estiver disponível, procura uma indicação visível de conclusão.
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
                # Só tenta acionar o botão final quando encontra texto de instalação concluída e botão Fechar habilitado.
                # Os nomes aceitos contemplam português e inglês: Fechar, Close, Concluir, Finish, Finalizar ou Done.
                $instalacaoConcluida = $textoJanela -match '(?i)(office|microsoft 365).{0,100}(installed|instalad[oa]|conclu[ií]d[oa])|(installation|instala[cç][aã]o).{0,60}(complete|completed|conclu[ií]d[oa]|finalizada)|(you.?re all set|all set|tudo pronto|pronto para usar)'
                if ($instalacaoConcluida -and $botoesFechar.Count -gt 0) {
                    foreach ($botao in $botoesFechar) {
                        try {
                            $padrao = $botao.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern)
                            $padrao.Invoke()
                            Write-Host '##INFO Office terminou a instalacao. Fechando a tela automaticamente.'
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
if (-not $officeConcluidoFechado) { Write-Host '##INFO O instalador do Office foi encerrado.' }
'@
# Baixa somente o conteudo; nunca executa o codigo BAT remoto.
$officeDownloadHelper = @'
function Get-OfficeInstaller {
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    $uri = 'https://raw.githubusercontent.com/Elsonsou124/etveel/main/OFF.bat'
    Write-Host '##INFO Baixando o instalador do Office do GitHub...'
    $response = Invoke-WebRequest -Uri $uri -UseBasicParsing -TimeoutSec 180 -ErrorAction Stop
    $txt = [string]$response.Content
    $marker = '###' + 'PAYLOAD###'
    $index = $txt.LastIndexOf($marker)
    if ($index -lt 0) { throw 'O arquivo do GitHub nao contem a payload do Office.' }
    Write-Host '##INFO Extraindo o instalador do Office...'
    $payload = $txt.Substring($index + $marker.Length) -replace '\s', ''
    $bytes = [Convert]::FromBase64String($payload)
    if ($bytes.Length -lt 2 -or $bytes[0] -ne 77 -or $bytes[1] -ne 90) {
        throw 'A payload nao e um executavel Windows valido.'
    }
    $exe = Join-Path $env:TEMP ('OfficeSetup_' + [guid]::NewGuid().ToString('N') + '.exe')
    try {
        [IO.File]::WriteAllBytes($exe, $bytes)
        Write-Host '##INFO Conferindo a assinatura digital da Microsoft...'
        $signature = Get-AuthenticodeSignature -FilePath $exe
        if ($signature.Status -ne 'Valid' -or -not $signature.SignerCertificate -or $signature.SignerCertificate.Subject -notmatch '(?i)(CN|O)=Microsoft Corporation(?:,|$)') {
            throw 'Assinatura da Microsoft invalida. O instalador nao sera executado.'
        }
        Write-Host '##INFO Download conferido. Iniciando a instalacao do Office...'
        return $exe
    } catch {
        Remove-Item -LiteralPath $exe -Force -ErrorAction SilentlyContinue
        throw
    }
}
'@
# A mesma rotina e usada no botao individual e nos dois pacotes com Office.
$officeInstallAndShortcuts = $officeDownloadHelper + "`r`n" + @'
$exe = $null
try {
    $exe = Get-OfficeInstaller
'@ + "`r`n" + $officeWaitAndClose + "`r`n" + @'
    if ($global:LASTEXITCODE -eq 3010) {
        Write-Host '##INFO Office solicitou reinicializacao do Windows.'
        $global:LASTEXITCODE = 0
    }
    if ($global:LASTEXITCODE -eq 0) {
'@ + "`r`n" + $officeShortcuts + "`r`n" + @'
    }
} catch {
    Write-Host ("##INFO Falha no Office: " + $_.Exception.Message)
    $global:LASTEXITCODE = 1
} finally {
    if ($exe) { Remove-Item -LiteralPath $exe -Force -ErrorAction SilentlyContinue }
}
'@

# =====================================================================
# FUNCOES DO SISTEMA DE TAREFAS E LOGS
# =====================================================================

$global:tasks = New-Object System.Collections.ArrayList
$global:totalEtapas = 0
$global:etapaAtual = 0

function Log($msg) { $logBox.AppendText((Get-Date -Format 'HH:mm:ss') + "  " + $msg + "`r`n") }

# Código auxiliar enviado para cada PowerShell de instalação em segundo plano.
# Contém validação de assinatura digital e as alternativas oficiais usadas quando o WinGet falha.
$appInstallHelpers = @'
# Reduz mensagens de progresso desnecessárias no arquivo de log do menu.
$ProgressPreference = 'SilentlyContinue'
# Baixa o instalador e verifica assinatura Authenticode e publicador esperado antes de executá-lo.
# Se a assinatura ou o publicador não corresponder, o arquivo é removido e a instalação é interrompida.
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
# Download alternativo exclusivo do Adobe; nao muda as rotinas dos outros programas.
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
            Write-Host ("##INFO Adobe: baixando por " + $method + '...')
            switch ($method) {
                'PowerShell' {
                    Invoke-WebRequest -Uri $Uri -OutFile $path -UseBasicParsing -TimeoutSec 900 -ErrorAction Stop
                }
                'BITS' {
                    Import-Module BitsTransfer -ErrorAction Stop
                    $job = $null
                    try {
                        $job = Start-BitsTransfer -Source $Uri -Destination $path -Asynchronous -ErrorAction Stop
                        $deadline = (Get-Date).AddMinutes(15)
                        while ($true) {
                            $job = Get-BitsTransfer -Id $job.Id -ErrorAction Stop
                            if ($job.JobState -eq 'Transferred') { Complete-BitsTransfer -BitsJob $job -ErrorAction Stop; $job = $null; break }
                            if ($job.JobState -in @('Error','Cancelled','Suspended') -or (Get-Date) -gt $deadline) {
                                throw ('Download BITS interrompido: ' + $job.JobState)
                            }
                            Start-Sleep -Seconds 2
                        }
                    } finally {
                        if ($job) { Remove-BitsTransfer -BitsJob $job -ErrorAction SilentlyContinue }
                    }
                }
                'curl' {
                    $curl = Get-Command curl.exe -ErrorAction Stop
                    & $curl.Source --fail --location --silent --show-error --connect-timeout 30 --max-time 900 --retry 2 --output $path $Uri
                    if ($LASTEXITCODE -ne 0) { throw ("curl falhou, codigo " + $LASTEXITCODE) }
                }
            }
            if (-not (Test-Path -LiteralPath $path) -or (Get-Item -LiteralPath $path).Length -lt 1000000) {
                throw 'Arquivo incompleto ou pagina web recebida no lugar do instalador.'
            }
            Write-Host '##INFO Adobe: conferindo assinatura digital...'
            $sig = Get-AuthenticodeSignature -FilePath $path
            if ($sig.Status -ne 'Valid' -or -not $sig.SignerCertificate -or $sig.SignerCertificate.Subject -notmatch '(?i)(CN|O)=Adobe (Inc\.|Systems Incorporated)(?:,|$)') {
                throw 'Assinatura digital da Adobe invalida; arquivo bloqueado.'
            }
            return $path
        } catch {
            Write-Host ("##INFO Adobe: " + $method + " falhou: " + $_.Exception.Message)
            Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
        }
    }
    throw 'Nenhum dos tres metodos conseguiu baixar um instalador Adobe valido.'
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
    # Catalogo Microsoft fornece apenas metadados; o EXE vem sempre de adobe.com.
    $url = $null
    try {
        Write-Host '##INFO Adobe: procurando a versao atual no catalogo Microsoft...'
        $headers = @{ 'User-Agent' = 'Windows-Installer-Menu'; 'Accept' = 'application/vnd.github+json' }
        $listing = Invoke-RestMethod -Uri 'https://api.github.com/repos/microsoft/winget-pkgs/contents/manifests/a/Adobe/Acrobat/Reader/64-bit' -Headers $headers -TimeoutSec 30 -ErrorAction Stop
        $versions = @($listing | Where-Object { $_.type -eq 'dir' -and $_.name -match '^\d+\.\d+\.\d+$' } | Sort-Object { [version]$_.name } -Descending | Select-Object -First 3)
        foreach ($version in $versions) {
            try {
                $manifestUrl = 'https://raw.githubusercontent.com/microsoft/winget-pkgs/master/manifests/a/Adobe/Acrobat/Reader/64-bit/' + $version.name + '/Adobe.Acrobat.Reader.64-bit.installer.yaml'
                $manifest = Invoke-WebRequest -Uri $manifestUrl -UseBasicParsing -TimeoutSec 30 -ErrorAction Stop
                $match = [regex]::Match([string]$manifest.Content, '(?m)^\s*InstallerUrl:\s*(https://ardownload(?:2)?\.adobe\.com/[^\s]+_MUI\.exe)\s*$')
                if ($match.Success) { $url = $match.Groups[1].Value; break }
            } catch { Write-Host ('##INFO Adobe: catalogo indisponivel para ' + $version.name + '. Tentando alternativa...') }
        }
    } catch { Write-Host '##INFO Adobe: catalogo Microsoft indisponivel; usando link de reserva.' }
    if (-not $url) {
        # Reserva conferida em 06/11/2026; nunca monta caminhos de versao por adivinhacao.
        $url = 'https://ardownload2.adobe.com/pub/adobe/acrobat/win/AcrobatDC/2600322075/AcroRdrDCx642600322075_MUI.exe'
    }
    $url
    if (([uri]$url).Host -eq 'ardownload2.adobe.com') { $url.Replace('https://ardownload2.adobe.com/', 'https://ardownload.adobe.com/') }
    else { $url.Replace('https://ardownload.adobe.com/', 'https://ardownload2.adobe.com/') }
}
function Install-AdobeReaderDirect {
    $global:LASTEXITCODE = 1
    if (Test-AdobeReaderInstalled) {
        Write-Host '##INFO Adobe Reader ou Acrobat ja encontrado neste computador.'
        $global:LASTEXITCODE = -1978335189
        return
    }
    if (-not [Environment]::Is64BitOperatingSystem) {
        Write-Host '##INFO Este pacote Adobe exige Windows de 64 bits.'
        return
    }
    $setup = $null
    foreach ($uri in @(Get-AdobeDownloadCandidates)) {
        try { $setup = Get-AdobeVerifiedDownload -Uri $uri; break }
        catch { Write-Host ('##INFO Adobe: servidor indisponivel: ' + ([uri]$uri).Host + '. Tentando outro...') }
    }
    if (-not $setup) {
        Write-Host '##INFO Adobe: todas as tentativas automaticas falharam. Abrindo download oficial para instalacao manual.'
        try { Start-Process 'https://get.adobe.com/reader/enterprise/' -ErrorAction Stop } catch { Write-Host '##INFO Abra https://get.adobe.com/reader/enterprise/ no navegador.' }
        return
    }
    try {
        Write-Host '##INFO Adobe: download concluido. Instalando; aguarde...'
        # Parametros do pacote EXE registrados no manifesto winget atual.
        $proc = Start-Process -FilePath $setup -ArgumentList '-sfx_nu /sAll /rs /msi EULA_ACCEPT=YES' -Wait -PassThru -ErrorAction Stop
        $code = [int]$proc.ExitCode
        if ($code -in @(0,3010,1641)) {
            $global:LASTEXITCODE = 0
            if ($code -ne 0) { Write-Host '##INFO Adobe instalado; reinicie o Windows quando terminar.' }
        } elseif ($code -eq 1638 -and (Test-AdobeReaderInstalled)) {
            $global:LASTEXITCODE = -1978335189
        } else {
            $global:LASTEXITCODE = if ($code -ne 0) { $code } else { 1 }
            if ($code -eq 1618) { Write-Host '##INFO Adobe: outra instalacao esta em andamento. Aguarde e tente novamente.' }
            elseif ($code -eq 1602) { Write-Host '##INFO Adobe: instalacao cancelada.' }
            else { Write-Host ('##INFO Adobe: instalador retornou erro ' + $code + '. Verifique espaco livre e permissoes.') }
        }
    } catch {
        Write-Host ('##INFO Adobe: nao foi possivel instalar: ' + $_.Exception.Message)
        $global:LASTEXITCODE = 1
    } finally { Remove-Item -LiteralPath $setup -Force -ErrorAction SilentlyContinue }
}
function Get-PackageVerifiedDownload {
    param([string]$Uri, [string]$Name, [string]$Extension, [string]$Sha256)
    $parsed = [uri]$Uri
    if ($parsed.Scheme -ne 'https' -or $parsed.Host -notin @('www.rarlab.com','rarlab.com','ftp.nluug.nl','download.msi.com','download-2.msi.com')) {
        throw 'Link fora das fontes permitidas para WinRAR e Afterburner.'
    }
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    $path = Join-Path $env:TEMP ('Setup_' + [guid]::NewGuid().ToString('N') + '.' + $Extension)
    foreach ($method in @('PowerShell','BITS','curl')) {
        try {
            Write-Host ("##INFO ${Name}: baixando por " + $method + '...')
            switch ($method) {
                'PowerShell' {
                    Invoke-WebRequest -Uri $Uri -OutFile $path -UseBasicParsing -TimeoutSec 900 -ErrorAction Stop
                }
                'BITS' {
                    Import-Module BitsTransfer -ErrorAction Stop
                    $job = $null
                    try {
                        $job = Start-BitsTransfer -Source $Uri -Destination $path -Asynchronous -ErrorAction Stop
                        $deadline = (Get-Date).AddMinutes(15)
                        while ($true) {
                            $job = Get-BitsTransfer -Id $job.Id -ErrorAction Stop
                            if ($job.JobState -eq 'Transferred') { Complete-BitsTransfer -BitsJob $job -ErrorAction Stop; $job = $null; break }
                            if ($job.JobState -in @('Error','Cancelled','Suspended') -or (Get-Date) -gt $deadline) {
                                throw ('Download BITS interrompido: ' + $job.JobState)
                            }
                            Start-Sleep -Seconds 2
                        }
                    } finally {
                        if ($job) { Remove-BitsTransfer -BitsJob $job -ErrorAction SilentlyContinue }
                    }
                }
                'curl' {
                    $curl = Get-Command curl.exe -ErrorAction Stop
                    & $curl.Source --fail --location --silent --show-error --connect-timeout 30 --max-time 900 --retry 2 --output $path $Uri
                    if ($LASTEXITCODE -ne 0) { throw ("curl falhou, codigo " + $LASTEXITCODE) }
                }
            }
            if (-not (Test-Path -LiteralPath $path) -or (Get-Item -LiteralPath $path).Length -lt 1000000) {
                throw 'Arquivo incompleto ou pagina web recebida no lugar do instalador.'
            }
            Write-Host ("##INFO ${Name}: conferindo integridade do download...")
            if ($Sha256 -notmatch '^[A-Fa-f0-9]{64}$' -or (Get-FileHash -LiteralPath $path -Algorithm SHA256 -ErrorAction Stop).Hash -ne $Sha256) {
                throw 'Arquivo diferente do catalogo Microsoft; download bloqueado.'
            }
            return $path
        } catch {
            Write-Host ("##INFO ${Name}: " + $method + " falhou: " + $_.Exception.Message)
            Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
        }
    }
    throw 'Nenhum dos tres metodos conseguiu baixar um instalador valido.'
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
        Write-Host ("##INFO " + $reserve.Name + ': procurando a versao estavel no catalogo Microsoft...')
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
            } catch { Write-Host '##INFO Catalogo indisponivel; tentando alternativa...' }
        }
    } catch { Write-Host '##INFO Usando link de reserva com integridade conferida.' }
    return $reserve
}
function Install-MenuPackageDirect {
    param([string]$Id)
    $global:LASTEXITCODE=1
    if (Test-MenuPackageInstalled -Id $Id) { $global:LASTEXITCODE=-1978335189; Write-Host '##INFO Programa ja encontrado neste computador.'; return }
    if ($Id -eq 'RARLab.WinRAR' -and -not [Environment]::Is64BitOperatingSystem) { Write-Host '##INFO Este pacote WinRAR exige Windows de 64 bits.'; return }
    $meta=Get-MenuPackageMetadata -Id $Id
    $download=$null; $folder=$null
    try {
        try { $download=Get-PackageVerifiedDownload -Uri $meta.Url -Name $meta.Name -Extension $meta.Extension -Sha256 $meta.Hash }
        catch {
            Write-Host ("##INFO " + $meta.Name + ': downloads automaticos falharam. Abrindo pagina para instalacao manual.')
            Start-Process $meta.Manual -ErrorAction Stop
            return
        }
        $setup=$download
        if ($meta.Extension -eq 'zip') {
            Write-Host '##INFO MSI Afterburner: extraindo o instalador verificado...'
            $folder=Join-Path $env:TEMP ('Afterburner_' + [guid]::NewGuid().ToString('N'))
            Expand-Archive -LiteralPath $download -DestinationPath $folder -Force -ErrorAction Stop
            $setup=Join-Path $folder $meta.Nested
            if (-not (Test-Path -LiteralPath $setup)) { throw 'Instalador do Afterburner nao encontrado no ZIP.' }
        }
        Write-Host ("##INFO " + $meta.Name + ': instalando; aguarde...')
        $proc=Start-Process -FilePath $setup -ArgumentList $meta.Args -Wait -PassThru -ErrorAction Stop
        $code=[int]$proc.ExitCode
        if ($code -in @(0,3010,1641)) {
            if (Test-MenuPackageInstalled -Id $Id) { $global:LASTEXITCODE=0 }
            else { Write-Host '##INFO Instalador encerrou, mas o programa nao foi encontrado. Confira a instalacao.'; $global:LASTEXITCODE=1 }
            if ($code -ne 0) { Write-Host '##INFO Pode ser necessario reiniciar o Windows.' }
        } else {
            $global:LASTEXITCODE=$code
            Write-Host ("##INFO " + $meta.Name + ': instalador retornou erro ' + $code + '.')
        }
    } catch { Write-Host ('##INFO Falha na instalacao: ' + $_.Exception.Message); $global:LASTEXITCODE=1 }
    finally {
        if ($download) { Remove-Item -LiteralPath $download -Force -ErrorAction SilentlyContinue }
        if ($folder) { Remove-Item -LiteralPath $folder -Recurse -Force -ErrorAction SilentlyContinue }
    }
}
# Estratégia: tentar WinGet primeiro; se falhar, usar uma alternativa oficial específica para aquele aplicativo.
# O código de saída é mantido para o menu não registrar falsamente uma instalação como bem-sucedida.
function Install-AppFallback {
    param([string]$Id)
    $global:LASTEXITCODE = 1
    $wingetCode = 1
    $wingetPath = $null
    if ($Id -in @('RARLab.WinRAR','Guru3D.Afterburner') -and (Test-MenuPackageInstalled -Id $Id)) {
        $global:LASTEXITCODE=-1978335189; Write-Host '##INFO Programa ja encontrado neste computador.'; return
    }
    if ($Id -eq 'Adobe.Acrobat.Reader.64-bit' -and (Test-AdobeReaderInstalled)) {
        Write-Host '##INFO Adobe Reader ou Acrobat ja encontrado neste computador.'
        $global:LASTEXITCODE = -1978335189
        return
    }
    try {
        $wingetCommand = Get-Command winget.exe -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($wingetCommand) { $wingetPath = $wingetCommand.Source }
        # Se winget.exe não estiver no PATH, procura o executável dentro do pacote App Installer.
        if (-not $wingetPath) {
            try {
                $appInstaller = Get-AppxPackage -Name Microsoft.DesktopAppInstaller -ErrorAction SilentlyContinue | Sort-Object Version -Descending | Select-Object -First 1
                if ($appInstaller) {
                    $candidate = Join-Path $appInstaller.InstallLocation 'winget.exe'
                    if (Test-Path $candidate) { $wingetPath = $candidate }
                }
            } catch {}
        }
        # O WinGet é a primeira tentativa, em modo silencioso e sem perguntas de aceite interativas.
        if ($wingetPath) {
            Write-Host "##INFO Tentando instalar $Id pelo WinGet..."
            & $wingetPath install --exact --id $Id --source winget --silent --accept-package-agreements --accept-source-agreements --disable-interactivity
            $wingetCode = [int]$LASTEXITCODE
            if ($wingetCode -eq 0 -or $wingetCode -eq -1978335189) {
                $global:LASTEXITCODE = $wingetCode
                return
            }
            Write-Host "##INFO WinGet falhou (codigo $wingetCode). Tentando o canal oficial alternativo..."
        } else {
            Write-Host '##INFO WinGet nao foi encontrado. Tentando o canal oficial alternativo...'
        }
        switch ($Id) {
            # Chrome: alternativa é o MSI empresarial x64 do domínio Google; valida o certificado antes do msiexec.
            'Google.Chrome' {
                $fileName = 'ChromeEnterprise_' + [guid]::NewGuid().ToString('N') + '.msi'
                $setup = Get-VerifiedInstaller -Uri 'https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise64.msi' -FileName $fileName -PublisherPattern '(?i)(CN=Google LLC|O=Google LLC)'
                $proc = Start-Process -FilePath (Join-Path $env:SystemRoot 'System32\msiexec.exe') -ArgumentList "/i `"$setup`" /qn /norestart" -Wait -PassThru
                if ([int]$proc.ExitCode -eq 3010) { Write-Host '##INFO Chrome instalado; o Windows sinalizou que uma reinicializacao pode ser necessaria.'; $global:LASTEXITCODE = 0 }
                else { $global:LASTEXITCODE = [int]$proc.ExitCode }
                return
            }
            'RARLab.WinRAR' {
                Install-MenuPackageDirect -Id $Id
                return
            }
            # Adobe: download direto com PowerShell, BITS e curl; dois servidores oficiais.
            'Adobe.Acrobat.Reader.64-bit' {
                Install-AdobeReaderDirect
                return
            }
            'Guru3D.Afterburner' {
                Install-MenuPackageDirect -Id $Id
                return
            }
            default {
                Write-Host "##INFO Nao existe fallback configurado para $Id."
                $global:LASTEXITCODE = 1
                return
            }
        }
    } catch {
        if ($Id -eq 'Adobe.Acrobat.Reader.64-bit') {
            Write-Host ('##INFO Adobe: tentativa inicial falhou: ' + $_.Exception.Message)
            Install-AdobeReaderDirect
            return
        }
        if ($Id -in @('RARLab.WinRAR','Guru3D.Afterburner')) {
            Write-Host ('##INFO Tentativa inicial falhou: ' + $_.Exception.Message)
            Install-MenuPackageDirect -Id $Id
            return
        }
        Write-Host "##INFO A alternativa oficial falhou: $_"
        $global:LASTEXITCODE = 1
    }
}
'@
# Inicia cada instalação em outro PowerShell para manter o menu responsivo.
# A saída e os erros do processo filho são redirecionados para um arquivo temporário lido pela interface.
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

# Gera a chamada para a rotina WinGet + fallback oficial, usando o ID exato do pacote.
function W($id) { "Install-AppFallback -Id '$id'" }

# Cria uma etapa numerada: informa o progresso, executa o comando e classifica o código de saída.
function Passo($n, $tot, $nome, $cmd) {
    "Write-Host '##AGORA [$n/$tot] $nome'; `$global:LASTEXITCODE = 0; $cmd; `$c = `$global:LASTEXITCODE; " +
    "if (`$c -eq 0) { Write-Host '##OK $nome' } elseif (`$c -eq -1978335189) { Write-Host '##JA $nome' } " +
    "else { Write-Host ('##ERRO $nome (codigo ' + `$c + ')'); `$global:falhou = 1 }"
}

# Junta as etapas de um pacote para execução em sequência e devolve um código final de sucesso ou falha.
function Lote($passos) { "`$global:falhou = 0; " + ($passos -join "; ") + "; `$global:LASTEXITCODE = [int]`$global:falhou" }

# =====================================================================
# FUNCOES DO OFFICE
# =====================================================================

# =====================================================================
# INTERFACE GRAFICA (Layout numerado em painel)
# =====================================================================

$programIcon = [System.Drawing.SystemIcons]::Application

# Janela principal fixa: ações à esquerda; status, progresso e log à direita.
$form = New-Object System.Windows.Forms.Form
$form.Icon = $programIcon
$form.ShowIcon = $true
$form.Text = "ASSISTENTE DE FORMATAÇÃO PRO"
$form.ClientSize = New-Object System.Drawing.Size(1120, 680)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox = $false
$form.BackColor = [System.Drawing.Color]::FromArgb(12, 14, 20)
$form.ForeColor = [System.Drawing.Color]::White
$form.Font = New-Object System.Drawing.Font("Segoe UI", 10)

# Cabeçalho
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

# O botao Sair fecha a janela e religa o Windows Defender
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

# Seções do menu
$individualTitle = New-Object System.Windows.Forms.Label
$individualTitle.Text = "AÇÕES INDIVIDUAIS  |  01-06"
$individualTitle.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$individualTitle.ForeColor = [System.Drawing.Color]::FromArgb(0, 200, 220)
$individualTitle.AutoSize = $true
$individualTitle.Location = New-Object System.Drawing.Point(24, 101)
$form.Controls.Add($individualTitle)

$bundleTitle = New-Object System.Windows.Forms.Label
$bundleTitle.Text = "PACOTES DE INSTALAÇÃO  |  07-10"
$bundleTitle.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$bundleTitle.ForeColor = [System.Drawing.Color]::FromArgb(0, 255, 160)
$bundleTitle.AutoSize = $true
$bundleTitle.Location = New-Object System.Drawing.Point(24, 432)
$form.Controls.Add($bundleTitle)

# =====================================================================
# LISTA DE ACOES DOS BOTOES
# =====================================================================

$actions = [ordered]@{
     "Ativação Windows"           = { Start-Process powershell -ArgumentList "-NoProfile -WindowStyle Hidden -Command `"& ([ScriptBlock]::Create((irm https://get.activated.win))) `"" ; Log "Tela de Ativacao do Windows foi Aberta" }
    "Instalar Google Chrome"     = { Start-Task "Chrome" (Lote @(Passo 1 1 "Chrome" (W "Google.Chrome"))) }
    "Instalar WinRAR"            = { Start-Task "WinRAR" (Lote @(Passo 1 1 "WinRAR" (W "RARLab.WinRAR"))) }
    "Instalar MSI Afterburner"   = { Start-Task "Afterburner" (Lote @(Passo 1 1 "MSI Afterburner" (W "Guru3D.Afterburner"))) }
    "Instalar Adobe Reader"     = { Start-Task "Adobe Reader" (Lote @(Passo 1 1 "Adobe Acrobat Reader" (W "Adobe.Acrobat.Reader.64-bit"))) }

    "Instalar Apenas o Office" = {
        Start-Task "Office e atalhos" (Lote @(Passo 1 1 "Office" $officeInstallAndShortcuts))
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

    "Kit Gamer Completo" = {
        Start-Task "Kit Gamer Completo" (Lote @(
            'Write-Host "##AGORA [1/4] Habilitando .NET Framework 3.5..."; DISM /Online /Enable-Feature /FeatureName:NetFx3 /All /NoRestart /Quiet; Write-Host "##OK .NET Framework 3.5"',
            'Write-Host "##AGORA [2/4] Instalando .NET Desktop Runtime..."; $ok = $false; try { winget install -e --id Microsoft.DotNet.DesktopRuntime.8 --source winget --accept-package-agreements --accept-source-agreements; $ok = $true } catch {}; if (-not $ok) { $urls = @("https://aka.ms/dotnet/8.0/windowsdesktop-runtime-win-x64.exe", "https://download.visualstudio.microsoft.com/download/pr/9a622a4b-9706-47b2-a43c-660c6e8cf3a7/1779e3774883f360ecb3f7f02d04a621/windowsdesktop-runtime-8.0.10-win-x64.exe"); foreach ($u in $urls) { try { $p = "$env:TEMP\dotnet.exe"; Invoke-WebRequest -Uri $u -OutFile $p; if ((Get-Item $p).Length -gt 1000000) { Start-Process -FilePath $p -ArgumentList "/install /quiet /norestart" -Wait; break } } catch {} } }; Write-Host "##OK .NET Desktop Runtime"',
            'Write-Host "##AGORA [3/4] Instalando Visual C++ Redistributable..."; $vcUrls = @("https://github.com/abbodi1406/vcredist/releases/latest/download/VisualCppRedist_AIO_x86_x64.exe", "https://github.com/ChrisTitusTech/winutil/raw/main/vcredist.exe"); foreach ($u in $vcUrls) { try { $p = "$env:TEMP\vcredist.exe"; Invoke-WebRequest -Uri $u -OutFile $p; if ((Get-Item $p).Length -gt 1000000) { Start-Process -FilePath $p -ArgumentList "-y /ai /q" -Wait; break } } catch {} }; Write-Host "##OK Visual C++"',
            'Write-Host "##AGORA [4/4] Instalando DirectX Runtimes..."; $dxUrls = @("https://download.microsoft.com/download/8/4/A/84A35BF1-DAFE-4AE8-B9BF-ACAF96D5B92F/directx_jun2010_redist.exe", "https://archive.org/download/directx_jun2010_redist/directx_jun2010_redist.exe"); foreach ($u in $dxUrls) { try { $d = "$env:TEMP\dxsetup.exe"; Invoke-WebRequest -Uri $u -OutFile $d; if ((Get-Item $d).Length -gt 1000000) { Start-Process -FilePath $d -ArgumentList "/Q /T:$env:TEMP\DX" -Wait; Start-Process -FilePath "$env:TEMP\DX\DXSETUP.exe" -ArgumentList "/silent" -Wait; break } } catch {} }; Write-Host "##OK DirectX"'
        )) -total 4
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
        $btn.Size = New-Object System.Drawing.Size(156, 112)
        $btn.Location = New-Object System.Drawing.Point((24 + (($actionNumber - 7) * 166)), 466)
        
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
            $btn.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
            $btn.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(52, 211, 153)
        } else {
            $btn.BackColor = [System.Drawing.Color]::FromArgb(120, 30, 30)
            $btn.ForeColor = [System.Drawing.Color]::FromArgb(255, 230, 230)
            $btn.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
            $btn.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(255, 80, 80)
        }
        $btn.FlatAppearance.BorderSize = 2
    }

    $btn.Tag = @{ Acao = $actions[$name]; Cor = $btn.BackColor }
    $btn.Add_MouseEnter({ $this.BackColor = [System.Drawing.Color]::FromArgb(40, 55, 80) })
    $btn.Add_MouseLeave({ $this.BackColor = $this.Tag.Cor })
    $btn.Add_Click({ try { & $this.Tag.Acao } catch { [System.Windows.Forms.MessageBox]::Show("Erro: $_") } })
    $form.Controls.Add($btn)
}

# Painel de status e log
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
$logBox.Size = New-Object System.Drawing.Size(416, 390)
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
$watermark.Location = New-Object System.Drawing.Point(680, 610)
$form.Controls.Add($watermark)

# TIMER: PROCESSAMENTO DO LOG E FILA
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
        elseif ($l -match '^##ERRO (.+)$') {
            $t.Erro++; Log ("  [ERRO] " + $matches[1])
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
# CONFIGURAÇÃO DE VERSÃO (FÁCIL ALTERAÇÃO AQUI NO FINAL DO CÓDIGO)
# =====================================================================
$versaoLabel = New-Object System.Windows.Forms.Label
$versaoLabel.Text = "VERSÃO 0.27"
$versaoLabel.Font = New-Object System.Drawing.Font("Segoe UI Black", 14, [System.Drawing.FontStyle]::Bold)
$versaoLabel.ForeColor = [System.Drawing.Color]::FromArgb(255, 220, 0)
$versaoLabel.AutoSize = $true
$versaoLabel.Location = New-Object System.Drawing.Point(950, 605)
$form.Controls.Add($versaoLabel)
# =====================================================================


# Mostra a janela e mantém ativo o loop de eventos do Windows Forms.
$form.Show()
[System.Windows.Forms.Application]::Run($form)

# Ao fechar o menu, para o timer e libera os recursos gráficos.
$timer.Stop()
$timer.Dispose()
$form.Dispose()
#PSEND
