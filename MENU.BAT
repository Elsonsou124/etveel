
1	@echo off 
2	title Assistente de Formatacao 
3	color 0B 
4	 
5	REM ===================================================================== 
6	REM 1. ELEVAÇÃO ADMINISTRATIVA 
7	REM ===================================================================== 
8	net session >nul 2>&1 
9	if errorlevel 1 ( 
10	    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs" 
11	    exit /b 
12	) 
13	 
14	set "BATDRIVE=%~d0" 
15	set "INSTALLER_FILE=%~f0" 
16	set "APP_VER=v0.76" 
17	 
18	:ESCOLHA_MODO 
19	cls 
20	echo  %APP_VER% 
21	echo. 
22	echo  [1] Modo FULL 
23	echo  [2] Modo Lite 
24	echo. 
25	choice /c 12 /n /m "> " 
26	 
27	if errorlevel 2 goto INICIAR_CLI 
28	if errorlevel 1 goto INICIAR_GUI 
29	 
30	:INICIAR_GUI 
31	set "UI_MODE=GUI" 
32	powershell -NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -Command "$s=[IO.File]::ReadAllText($env:INSTALLER_FILE,[Text.Encoding]::UTF8); $a=$s.IndexOf('#'+'PSSTART'); $b=$s.IndexOf('#'+'PSEND'); try { iex $s.Substring($a, $b-$a) } catch { Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.MessageBox]::Show(\"Erro: $_\") }" 
33	exit /b 
34	 
35	:INICIAR_CLI 
36	cls 
37	set "UI_MODE=CLI" 
38	powershell -NoProfile -ExecutionPolicy Bypass -Command "$s=[IO.File]::ReadAllText($env:INSTALLER_FILE,[Text.Encoding]::UTF8); $a=$s.IndexOf('#'+'PSSTART'); $b=$s.IndexOf('#'+'PSEND'); try { iex $s.Substring($a, $b-$a) } catch { Write-Host \"Erro: $_\" -ForegroundColor Red; pause }" 
39	exit /b 
40	 
41	#PSSTART 
42	# ===================================================================== 
43	# SEÇÃO 1: VARIÁVEIS GLOBAIS E AJUSTES DE SISTEMA (COMPARTILHADOS) 
44	# ===================================================================== 
45	$VersaoAtual  = $env:APP_VER 
46	$ModoExecucao = $env:UI_MODE 
47	$drive        = $env:BATDRIVE 
48	$BASE         = "$drive\Windows\Tudo" 
49	$WINRARDIR    = "C:\Program Files\WinRAR" 
50	 
51	if ($ModoExecucao -eq 'CLI') { 
52	    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 
53	    $Host.UI.RawUI.WindowTitle = "Assistente de Formatacao Lite ($VersaoAtual) - Elson (Criatividade E Tudo)" 
54	    Write-Host "Aplicando ajustes iniciais do sistema (Energia, Icones, Visualizador)..." -ForegroundColor DarkCyan 
55	} 
56	 
57	# 1.1 - Configuração de Energia (Não suspender durante instalações) 
58	try { 
59	    powercfg /change monitor-timeout-ac 0 > $null 
60	    powercfg /change monitor-timeout-dc 0 > $null 
61	    powercfg /change standby-timeout-ac 0 > $null 
62	    powercfg /change standby-timeout-dc 0 > $null 
63	    powercfg /change hibernate-timeout-ac 0 > $null 
64	    powercfg /change hibernate-timeout-dc 0 > $null 
65	    powercfg /hibernate off > $null 
66	    powercfg /setactive SCHEME_CURRENT > $null 
67	} catch {} 
68	 
69	# 1.2 - Ativar ícones clássicos na Área de Trabalho (Este Computador, Usuário, Painel) 
70	$iconsPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" 
71	if (-not (Test-Path $iconsPath)) { New-Item -Path $iconsPath -Force | Out-Null } 
72	Set-ItemProperty -Path $iconsPath -Name "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" -Value 0 -Type DWord -Force 
73	Set-ItemProperty -Path $iconsPath -Name "{59031a47-3f72-44a7-89c5-5595fe6b30ee}" -Value 0 -Type DWord -Force 
74	Set-ItemProperty -Path $iconsPath -Name "{5399E694-6CE5-4D6C-8FCE-1D8870FDCBA0}" -Value 0 -Type DWord -Force 
75	 
76	# 1.3 - Ativar Visualizador de Fotos Clássico do Windows 
77	$photoPath = "HKLM:\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations" 
78	if (-not (Test-Path $photoPath)) { New-Item -Path $photoPath -Force | Out-Null } 
79	foreach ($ext in @('.jpg','.jpeg','.png','.bmp','.gif','.tif','.tiff')) { 
80	    New-ItemProperty -Path $photoPath -Name $ext -Value 'PhotoViewer.FileAssoc.Tiff' -PropertyType String -Force | Out-Null 
81	} 
82	 
83	# 1.4 - APIs Nativas (Atualização do Desktop + Scroll do Console GUI) 
84	$winApiCode = @' 
85	[System.Runtime.InteropServices.DllImport("Shell32.dll")] 
86	public static extern int SHChangeNotify(int eventId, int flags, IntPtr item1, IntPtr item2); 
87	public static void Atualizar() { SHChangeNotify(0x08000000, 0x1000, IntPtr.Zero, IntPtr.Zero); } 
88	 
89	[System.Runtime.InteropServices.DllImport("user32.dll", CharSet = System.Runtime.InteropServices.CharSet.Auto)] 
90	public static extern IntPtr SendMessage(IntPtr hWnd, int Msg, IntPtr wParam, IntPtr lParam); 
91	'@ 
92	Add-Type -MemberDefinition $winApiCode -Namespace "WinAPI" -Name "Desktop" -ErrorAction SilentlyContinue 
93	[WinAPI.Desktop]::Atualizar() 
94	 
95	# 1.5 - Gerador automático da chave de registro do WinRAR 
96	if (-not (Test-Path "$WINRARDIR\rarreg.key")) { 
97	    if (-not (Test-Path $WINRARDIR)) { New-Item -ItemType Directory -Force -Path $WINRARDIR | Out-Null } 
98	    $txtPath = "$WINRARDIR\rarreg.txt" 
99	    Set-Content -Path $txtPath -Value "RAR registration data`r`nchattchitto.com`r`nUnlimited Company License`r`nUID=45cf7e253572312b6995`r`n64122122506995900ddabb88b22559b8f25d88e1168dd8cea3bd59`r`nfe190143727199246a8460fce6cb5ffde62890079861be57638717`r`n7131ced835ed65cc743d9777f2ea71a8e32c7e593cf66794343565`r`nb41bcf56929486b8bcdac33d50ecf7739960e36503ffdcbcf7dbfc`r`n378eb1e8a5d96ddf9e5c7d6e7b122c103ee81bce156ee5ec1cf50d`r`n174c5a231523f967f5c53a4efdc7ecb9689f18a2ed6166f7608276`r`n7f5dd734a2736b2d5fb6eb5145b50ed0c7033251fe142027056408" -Force 
100	    Rename-Item -Path $txtPath -NewName "rarreg.key" -Force 
101	} 
102	 
103	# 1.6 - Desativar Proteções do Windows Defender temporariamente 
104	try { 
105	    Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue 
106	    Set-MpPreference -DisableBehaviorMonitoring $true -ErrorAction SilentlyContinue 
107	    Set-MpPreference -DisableBlockAtFirstSeen $true -ErrorAction SilentlyContinue 
108	    Set-MpPreference -DisableIOAVProtection $true -ErrorAction SilentlyContinue 
109	    Set-MpPreference -DisableScriptScanning $true -ErrorAction SilentlyContinue 
110	    Set-MpPreference -SubmitSamplesConsent 2 -ErrorAction SilentlyContinue 
111	    Set-MpPreference -MAPSReporting 0 -ErrorAction SilentlyContinue 
112	} catch {} 
113	 
114	 
115	# ===================================================================== 
116	# SEÇÃO 2: MOTOR DE INSTALAÇÃO COMPARTILHADO (COM TIMEOUT E FALLBACKS) 
117	# ===================================================================== 
118	$appInstallHelpers = @' 
119	$ProgressPreference = 'SilentlyContinue' 
120	[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 
121	 
122	function Invoke-ProcessWithTimeout { 
123	    param( 
124	        [string]$FilePath, 
125	        [string]$ArgumentList = "", 
126	        [int]$TimeoutSeconds = 180 
127	    ) 
128	    try { 
129	        $psi = New-Object System.Diagnostics.ProcessStartInfo 
130	        $psi.FileName = $FilePath 
131	        $psi.Arguments = $ArgumentList 
132	        $psi.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden 
133	        $psi.CreateNoWindow = $true 
134	        $psi.UseShellExecute = $false 
135	 
136	        $proc = [System.Diagnostics.Process]::Start($psi) 
137	        if (-not $proc.WaitForExit($TimeoutSeconds * 1000)) { 
138	            Write-Host "##INFO Tempo limite ($($TimeoutSeconds)s) atingido para $([IO.Path]::GetFileName($FilePath)). Encerrando processo para nao travar..." 
139	            try { $proc.Kill() } catch {} 
140	            return 1460 
141	        } 
142	        return [int]$proc.ExitCode 
143	    } catch { 
144	        return 1 
145	    } 
146	} 
147	 
148	function Get-WingetExecutable { 
149	    $wingetCommand = Get-Command winget.exe -ErrorAction SilentlyContinue | Select-Object -First 1 
150	    if ($wingetCommand) { return $wingetCommand.Source } 
151	    try { 
152	        $appInstaller = Get-AppxPackage -Name Microsoft.DesktopAppInstaller -ErrorAction SilentlyContinue | Sort-Object Version -Descending | Select-Object -First 1 
153	        if ($appInstaller) { 
154	            $candidate = Join-Path $appInstaller.InstallLocation 'winget.exe' 
155	            if (Test-Path $candidate) { return $candidate } 
156	        } 
157	    } catch {} 
158	    return $null 
159	} 
160	 
161	function Ensure-WinGetInstalled { 
162	    if (Get-WingetExecutable) { return } 
163	    Write-Host "##INFO WinGet nao detectado. Instalando App Installer..." 
164	    $tmpFile = Join-Path $env:TEMP ("WinGet_" + [guid]::NewGuid().ToString('N') + ".msixbundle") 
165	    try { 
166	        Invoke-WebRequest -Uri "https://aka.ms/getwinget" -OutFile $tmpFile -UseBasicParsing -TimeoutSec 90 -ErrorAction Stop 
167	        Add-AppxPackage -Path $tmpFile -ErrorAction Stop 
168	        Write-Host "##INFO WinGet instalado com sucesso!" 
169	    } catch { 
170	        Write-Host "##INFO WinGet indisponivel. Usando downloads diretos." 
171	    } finally { 
172	        Remove-Item -LiteralPath $tmpFile -Force -ErrorAction SilentlyContinue 
173	    } 
174	} 
175	 
176	function Invoke-WingetSafe { 
177	    param([string]$Id, [int]$TimeoutSeconds = 180) 
178	    $wg = Get-WingetExecutable 
179	    if (-not $wg) { return 1 } 
180	    $args = "install --exact --id $Id --source winget --silent --accept-package-agreements --accept-source-agreements --disable-interactivity" 
181	    return (Invoke-ProcessWithTimeout -FilePath $wg -ArgumentList $args -TimeoutSeconds $TimeoutSeconds) 
182	} 
183	 
184	function Download-FileSafe { 
185	    param([string]$Uri, [string]$OutFile, [int]$TimeoutSec = 120, [int]$MinBytes = 500000) 
186	    try { 
187	        Invoke-WebRequest -Uri $Uri -OutFile $OutFile -UseBasicParsing -TimeoutSec $TimeoutSec -ErrorAction Stop 
188	        if ((Test-Path $OutFile) -and (Get-Item $OutFile).Length -gt $MinBytes) { return $true } 
189	    } catch {} 
190	    try { 
191	        $curl = Get-Command curl.exe -ErrorAction SilentlyContinue 
192	        if ($curl) { 
193	            $code = Invoke-ProcessWithTimeout -FilePath $curl.Source -ArgumentList "--fail --location --silent --connect-timeout 20 --max-time $TimeoutSec --output `"$OutFile`" `"$Uri`"" -TimeoutSeconds ($TimeoutSec + 15) 
194	            if ($code -eq 0 -and (Test-Path $OutFile) -and (Get-Item $OutFile).Length -gt $MinBytes) { return $true } 
195	        } 
196	    } catch {} 
197	    return $false 
198	} 
199	 
200	# --- Funções Blindadas do Kit Gamer --- 
201	function Install-GamerPowerPlan { 
202	    try { 
203	        $guid = (powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61) 2>$null 
204	        if ($guid -match "([a-f0-9\-]{36})") { powercfg -setactive $Matches[1] 2>$null } 
205	        else { powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null } 
206	        $global:LASTEXITCODE = 0 
207	    } catch { $global:LASTEXITCODE = 0 } 
208	} 
209	 
210	function Install-GamerNetFx3 { 
211	    try { 
212	        $feat = Get-WindowsOptionalFeature -Online -FeatureName NetFx3 -ErrorAction SilentlyContinue 
213	        if ($feat -and $feat.State -eq 'Enabled') { $global:LASTEXITCODE = -1978335189; return } 
214	        Write-Host "##INFO Ativando recurso NetFx3 via DISM (limite 300s)..." 
215	        $code = Invoke-ProcessWithTimeout -FilePath "dism.exe" -ArgumentList "/Online /Enable-Feature /FeatureName:NetFx3 /All /NoRestart /Quiet" -TimeoutSeconds 300 
216	        if ($code -eq 0 -or $code -eq 3010) { $global:LASTEXITCODE = 0; return } 
217	        Write-Host "##INFO Tentando metodo alternativo via PowerShell..." 
218	        Enable-WindowsOptionalFeature -Online -FeatureName NetFx3 -All -NoRestart -ErrorAction SilentlyContinue | Out-Null 
219	        $global:LASTEXITCODE = 0 
220	    } catch { $global:LASTEXITCODE = 0 } 
221	} 
222	 
223	function Install-GamerDotNet8 { 
224	    Ensure-WinGetInstalled 
225	    Write-Host "##INFO Tentativa 1: Instalando .NET Desktop Runtime 8 via WinGet..." 
226	    $code = Invoke-WingetSafe -Id "Microsoft.DotNet.DesktopRuntime.8" -TimeoutSeconds 180 
227	    if ($code -eq 0 -or $code -eq -1978335189) { $global:LASTEXITCODE = $code; return } 
228	 
229	    Write-Host "##INFO Tentativa 2: Baixando instalador direto oficial da Microsoft..." 
230	    $urls = @( 
231	        "https://aka.ms/dotnet/8.0/windowsdesktop-runtime-win-x64.exe", 
232	        "https://download.visualstudio.microsoft.com/download/pr/9a622a4b-9706-47b2-a43c-660c6e8cf3a7/1779e3774883f360ecb3f7f02d04a621/windowsdesktop-runtime-8.0.10-win-x64.exe" 
233	    ) 
234	    foreach ($u in $urls) { 
235	        $p = Join-Path $env:TEMP ("dotnet8_" + [guid]::NewGuid().ToString('N') + ".exe") 
236	        try { 
237	            if (Download-FileSafe -Uri $u -OutFile $p -TimeoutSec 120) { 
238	                $exit = Invoke-ProcessWithTimeout -FilePath $p -ArgumentList "/install /quiet /norestart" -TimeoutSeconds 180 
239	                if ($exit -eq 0 -or $exit -eq 3010 -or $exit -eq 1638) { $global:LASTEXITCODE = 0; return } 
240	            } 
241	        } finally { Remove-Item -LiteralPath $p -Force -ErrorAction SilentlyContinue } 
242	    } 
243	    $global:LASTEXITCODE = 1 
244	} 
245	 
246	function Install-GamerVCRedist { 
247	    Ensure-WinGetInstalled 
248	    Write-Host "##INFO Tentativa 1: Instalando Visual C++ 2015-2022 (x64/x86) via WinGet..." 
249	    $c64 = Invoke-WingetSafe -Id "Microsoft.VCRedist.2015+.x64" -TimeoutSeconds 150 
250	    $c86 = Invoke-WingetSafe -Id "Microsoft.VCRedist.2015+.x86" -TimeoutSeconds 150 
251	    if (($c64 -eq 0 -or $c64 -eq -1978335189) -and ($c86 -eq 0 -or $c86 -eq -1978335189)) { 
252	        Write-Host "##INFO Visual C++ instalado via WinGet!" 
253	        $global:LASTEXITCODE = 0; return 
254	    } 
255	 
256	    Write-Host "##INFO Tentativa 2: Baixando Visual C++ AIO (limite 240s)..." 
257	    $aioUrls = @( 
258	        "https://github.com/abbodi1406/vcredist/releases/latest/download/VisualCppRedist_AIO_x86_x64.exe", 
259	        "https://github.com/ChrisTitusTech/winutil/raw/main/vcredist.exe" 
260	    ) 
261	    foreach ($u in $aioUrls) { 
262	        $p = Join-Path $env:TEMP ("vcredist_aio_" + [guid]::NewGuid().ToString('N') + ".exe") 
263	        try { 
264	            if (Download-FileSafe -Uri $u -OutFile $p -TimeoutSec 120) { 
265	                $exit = Invoke-ProcessWithTimeout -FilePath $p -ArgumentList "/ai /gm2" -TimeoutSeconds 240 
266	                if ($exit -eq 0 -or $exit -eq 3010) { $global:LASTEXITCODE = 0; return } 
267	            } 
268	        } finally { Remove-Item -LiteralPath $p -Force -ErrorAction SilentlyContinue } 
269	    } 
270	 
271	    Write-Host "##INFO Tentativa 3: Forcando instalacao direta oficial Microsoft (x64 e x86)..." 
272	    $msOk = $false 
273	    foreach ($arch in @("x64", "x86")) { 
274	        $msUrl = "https://aka.ms/vs/17/release/vc_redist.$arch.exe" 
275	        $msFile = Join-Path $env:TEMP ("vc_ms_$arch_" + [guid]::NewGuid().ToString('N') + ".exe") 
276	        try { 
277	            if (Download-FileSafe -Uri $msUrl -OutFile $msFile -TimeoutSec 90) { 
278	                $exit = Invoke-ProcessWithTimeout -FilePath $msFile -ArgumentList "/install /quiet /norestart" -TimeoutSeconds 120 
279	                if ($exit -eq 0 -or $exit -eq 3010 -or $exit -eq 1638) { $msOk = $true } 
280	            } 
281	        } finally { Remove-Item -LiteralPath $msFile -Force -ErrorAction SilentlyContinue } 
282	    } 
283	    $global:LASTEXITCODE = if ($msOk) { 0 } else { 1 } 
284	} 
285	 
286	function Install-GamerDirectX { 
287	    Ensure-WinGetInstalled 
288	    Write-Host "##INFO Tentativa 1: Instalando DirectX via WinGet..." 
289	    $wgCode = Invoke-WingetSafe -Id "Microsoft.DirectX" -TimeoutSeconds 180 
290	    if ($wgCode -eq 0 -or $wgCode -eq -1978335189) { $global:LASTEXITCODE = $wgCode; return } 
291	 
292	    Write-Host "##INFO Tentativa 2: Baixando DirectX Web Installer oficial..." 
293	    $webFile = Join-Path $env:TEMP ("dxweb_" + [guid]::NewGuid().ToString('N') + ".exe") 
294	    try { 
295	        if (Download-FileSafe -Uri "https://download.microsoft.com/download/1/7/1/1718CCC4-6315-4D8E-9543-8E28A4E18C4C/dxwebsetup.exe" -OutFile $webFile -TimeoutSec 90 -MinBytes 100000) { 
296	            $webCode = Invoke-ProcessWithTimeout -FilePath $webFile -ArgumentList "/Q" -TimeoutSeconds 180 
297	            if ($webCode -eq 0 -or $webCode -eq 3010) { $global:LASTEXITCODE = 0; return } 
298	        } 
299	    } finally { Remove-Item -LiteralPath $webFile -Force -ErrorAction SilentlyContinue } 
300	 
301	    Write-Host "##INFO Tentativa 3: Baixando pacote offline DirectX Jun 2010..." 
302	    $dxUrls = @( 
303	        "https://github.com/lucasg/Dependencies/releases/download/v1.11.1/directx_Jun2010_redist.exe", 
304	        "https://archive.org/download/directx_Jun2010_redist/directx_Jun2010_redist.exe" 
305	    ) 
306	    foreach ($u in $dxUrls) { 
307	        $id = [guid]::NewGuid().ToString('N') 
308	        $d = Join-Path $env:TEMP "dxsetup_$id.exe" 
309	        $dir = Join-Path $env:TEMP "DX_$id" 
310	        try { 
311	            if (Download-FileSafe -Uri $u -OutFile $d -TimeoutSec 120 -MinBytes 5000000) { 
312	                New-Item -ItemType Directory -Force -Path $dir | Out-Null 
313	                $null = Invoke-ProcessWithTimeout -FilePath $d -ArgumentList "/Q /T:`"$dir`"" -TimeoutSeconds 90 
314	                $setupExe = Join-Path $dir "DXSETUP.exe" 
315	                if (Test-Path $setupExe) { 
316	                    $insCode = Invoke-ProcessWithTimeout -FilePath $setupExe -ArgumentList "/silent" -TimeoutSeconds 180 
317	                    if ($insCode -eq 0 -or $insCode -eq 3010) { $global:LASTEXITCODE = 0; return } 
318	                } 
319	            } 
320	        } finally { 
321	            Remove-Item -LiteralPath $d -Force -ErrorAction SilentlyContinue 
322	            Remove-Item -LiteralPath $dir -Recurse -Force -ErrorAction SilentlyContinue 
323	        } 
324	    } 
325	    $global:LASTEXITCODE = 1 
326	} 
327	 
328	function Install-GamerGPUApp { 
329	    Ensure-WinGetInstalled 
330	    Write-Host "##INFO Detectando Hardware de Video (Intel/AMD/NVIDIA)..." 
331	    try { 
332	        $gpus = Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue 
333	        if (-not $gpus) { Write-Host "##INFO Nenhuma placa de video detectada."; $global:LASTEXITCODE = 0; return } 
334	        $gpuNames = $gpus | Select-Object -ExpandProperty Name 
335	        Write-Host "##INFO GPU(s) Detectada(s): $($gpuNames -join ' | ')" 
336	 
337	        foreach ($gpu in $gpus) { 
338	            $name = $gpu.Name 
339	            $appId = $null; $appName = $null; $directUrl = $null; $webUrl = $null 
340	            if ($name -match '(?i)NVIDIA') { 
341	                $appId = 'Nvidia.NVIDIAApp'; $appName = 'NVIDIA App (Oficial)'; $directUrl = 'https://dtm.nvidia.com/nvidia-app/direct-download'; $webUrl = 'https://www.nvidia.com/pt-br/software/nvidia-app/' 
342	            } elseif ($name -match '(?i)AMD|Radeon') { 
343	                $appId = 'AdvancedMicroDevices.AMDSoftware'; $appName = 'AMD Software Adrenalin'; $webUrl = 'https://www.amd.com/pt/support/download/drivers.html' 
344	            } elseif ($name -match '(?i)Intel') { 
345	                $appId = 'Intel.DriverAndSupportAssistant'; $appName = 'Intel Driver & Support Assistant'; $directUrl = 'https://dsadata.intel.com/installer'; $webUrl = 'https://www.intel.com.br/content/www/br/pt/support/intel-driver-support-assistant.html' 
346	            } 
347	 
348	            if ($appId) { 
349	                $success = $false 
350	                Write-Host "##INFO Processando $appName..." 
351	                $wgCode = Invoke-WingetSafe -Id $appId -TimeoutSeconds 240 
352	                if ($wgCode -eq 0 -or $wgCode -eq -1978335189) { $success = $true } 
353	                if (-not $success -and $directUrl) { 
354	                    $setupPath = Join-Path $env:TEMP ("gpu_setup_" + [guid]::NewGuid().ToString('N') + ".exe") 
355	                    try { 
356	                        if (Download-FileSafe -Uri $directUrl -OutFile $setupPath -TimeoutSec 150) { 
357	                            $exit = Invoke-ProcessWithTimeout -FilePath $setupPath -ArgumentList "/s /noreboot" -TimeoutSeconds 240 
358	                            if ($exit -eq 0 -or $exit -eq 3010) { $success = $true } 
359	                        } 
360	                    } finally { Remove-Item -LiteralPath $setupPath -Force -ErrorAction SilentlyContinue } 
361	                } 
362	                if (-not $success -and $webUrl) { 
363	                    Write-Host "##INFO Abrindo pagina oficial no navegador..." 
364	                    Start-Process $webUrl -ErrorAction SilentlyContinue 
365	                } 
366	            } 
367	        } 
368	        $global:LASTEXITCODE = 0 
369	    } catch { $global:LASTEXITCODE = 0 } 
370	} 
371	 
372	# --- Windows Update e Drivers --- 
373	function Invoke-WindowsUpdate { 
374	    Write-Host "##INFO Iniciando varredura de atualizacoes do Windows (aguarde)..." 
375	    try { 
376	        $session = New-Object -ComObject Microsoft.Update.Session 
377	        $searcher = $session.CreateUpdateSearcher() 
378	        $result = $searcher.Search("IsInstalled=0 and Type='Software'") 
379	        if ($result.Updates.Count -eq 0) { Write-Host "##INFO Nenhuma atualizacao pendente"; $global:LASTEXITCODE = 0; return } 
380	        Write-Host ("##INFO Encontradas " + $result.Updates.Count + " atualizacoes. Baixando...") 
381	        $downloader = $session.CreateUpdateDownloader(); $downloader.Updates = $result.Updates; $downloader.Download() | Out-Null 
382	        Write-Host "##INFO Baixado. Instalando agora (pode demorar)..." 
383	        $installer = $session.CreateUpdateInstaller(); $installer.Updates = $result.Updates; $installResult = $installer.Install() 
384	        $global:LASTEXITCODE = if ($installResult.ResultCode -eq 2) { 0 } else { $installResult.ResultCode } 
385	    } catch { Write-Host ("##INFO Erro interno: " + $_.Exception.Message); $global:LASTEXITCODE = 1 } 
386	} 
387	 
388	function Invoke-DriverUpdate { 
389	    Write-Host "##INFO Buscando drivers oficiais pelo Windows Update..." 
390	    try { 
391	        $session = New-Object -ComObject Microsoft.Update.Session 
392	        $searcher = $session.CreateUpdateSearcher() 
393	        $result = $searcher.Search("IsInstalled=0 and Type='Driver'") 
394	        if ($result.Updates.Count -eq 0) { Write-Host "##INFO Todos os drivers ja estao atualizados"; $global:LASTEXITCODE = 0; return } 
395	        Write-Host ("##INFO Encontrados " + $result.Updates.Count + " drivers pendentes. Baixando...") 
396	        $downloader = $session.CreateUpdateDownloader(); $downloader.Updates = $result.Updates; $downloader.Download() | Out-Null 
397	        Write-Host "##INFO Instalando drivers na maquina..." 
398	        $installer = $session.CreateUpdateInstaller(); $installer.Updates = $result.Updates; $installResult = $installer.Install() 
399	        $global:LASTEXITCODE = if ($installResult.ResultCode -eq 2) { 0 } else { $installResult.ResultCode } 
400	    } catch { Write-Host ("##INFO Erro ao buscar drivers: " + $_.Exception.Message); $global:LASTEXITCODE = 1 } 
401	} 
402	 
403	# --- Instaladores Verificados e Fallbacks --- 
404	function Get-VerifiedInstaller { 
405	    param([string]$Uri, [string]$FileName, [string]$PublisherPattern) 
406	    $path = Join-Path $env:TEMP $FileName 
407	    Invoke-WebRequest -Uri $Uri -OutFile $path -UseBasicParsing -TimeoutSec 180 -ErrorAction Stop 
408	    $signature = Get-AuthenticodeSignature -FilePath $path 
409	    if ($signature.Status -ne 'Valid' -or $signature.SignerCertificate.Subject -notmatch $PublisherPattern) { 
410	        Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue 
411	        throw "Assinatura digital invalida: $Uri" 
412	    } 
413	    return $path 
414	} 
415	 
416	function Test-AdobeReaderInstalled { 
417	    $roots = @($env:ProgramFiles, ${env:ProgramFiles(x86)}) | Where-Object { $_ } 
418	    foreach ($root in $roots) { 
419	        foreach ($relative in @('Adobe\Acrobat DC\Acrobat\Acrobat.exe','Adobe\Acrobat Reader DC\Reader\AcroRd32.exe')) { 
420	            if (Test-Path -LiteralPath (Join-Path $root $relative)) { return $true } 
421	        } 
422	    } 
423	    return $false 
424	} 
425	 
426	function Install-AdobeReaderDirect { 
427	    $global:LASTEXITCODE = 1 
428	    if (Test-AdobeReaderInstalled) { $global:LASTEXITCODE = -1978335189; return } 
429	    if (-not [Environment]::Is64BitOperatingSystem) { return } 
430	    $url = 'https://ardownload2.adobe.com/pub/adobe/acrobat/win/AcrobatDC/2600322075/AcroRdrDCx642600322075_MUI.exe' 
431	    $setup = Join-Path $env:TEMP ('AdobeReader_' + [guid]::NewGuid().ToString('N') + '.exe') 
432	    try { 
433	        if (Download-FileSafe -Uri $url -OutFile $setup -TimeoutSec 240) { 
434	            $sig = Get-AuthenticodeSignature -FilePath $setup 
435	            if ($sig.Status -eq 'Valid' -and $sig.SignerCertificate.Subject -match '(?i)(CN|O)=Adobe') { 
436	                $code = Invoke-ProcessWithTimeout -FilePath $setup -ArgumentList '-sfx_nu /sAll /rs /msi EULA_ACCEPT=YES' -TimeoutSeconds 240 
437	                if ($code -in @(0,3010,1641)) { $global:LASTEXITCODE = 0 } 
438	                elseif ($code -eq 1638 -and (Test-AdobeReaderInstalled)) { $global:LASTEXITCODE = -1978335189 } 
439	            } 
440	        } 
441	    } finally { Remove-Item -LiteralPath $setup -Force -ErrorAction SilentlyContinue } 
442	} 
443	 
444	function Test-MenuPackageInstalled { 
445	    param([string]$Id) 
446	    $roots = @($env:ProgramFiles, ${env:ProgramFiles(x86)}) | Where-Object { $_ } 
447	    $relative = if ($Id -eq 'RARLab.WinRAR') { 'WinRAR\WinRAR.exe' } else { 'MSI Afterburner\MSIAfterburner.exe' } 
448	    foreach ($root in $roots) { if (Test-Path -LiteralPath (Join-Path $root $relative)) { return $true } } 
449	    return $false 
450	} 
451	 
452	function Install-MenuPackageDirect { 
453	    param([string]$Id) 
454	    $global:LASTEXITCODE = 1 
455	    if (Test-MenuPackageInstalled -Id $Id) { $global:LASTEXITCODE = -1978335189; return } 
456	    if ($Id -eq 'RARLab.WinRAR') { 
457	        $url = 'https://www.rarlab.com/rar/winrar-x64-723br.exe' 
458	        $dl = Join-Path $env:TEMP ('WinRAR_' + [guid]::NewGuid().ToString('N') + '.exe') 
459	        try { 
460	            if (Download-FileSafe -Uri $url -OutFile $dl -TimeoutSec 180) { 
461	                $code = Invoke-ProcessWithTimeout -FilePath $dl -ArgumentList '-s1' -TimeoutSeconds 180 
462	                if ($code -in @(0,3010,1641) -and (Test-MenuPackageInstalled -Id $Id)) { $global:LASTEXITCODE = 0 } 
463	            } 
464	        } finally { Remove-Item -LiteralPath $dl -Force -ErrorAction SilentlyContinue } 
465	    } else { 
466	        $url = 'https://ftp.nluug.nl/pub/games/PC/guru3d/afterburner/%5BGuru3D%5D-MSIAfterburnerSetup466Build16757.zip' 
467	        $dl = Join-Path $env:TEMP ('AB_' + [guid]::NewGuid().ToString('N') + '.zip') 
468	        $dir = Join-Path $env:TEMP ('AB_' + [guid]::NewGuid().ToString('N')) 
469	        try { 
470	            if (Download-FileSafe -Uri $url -OutFile $dl -TimeoutSec 180) { 
471	                Expand-Archive -LiteralPath $dl -DestinationPath $dir -Force 
472	                $exe = Get-ChildItem -Path $dir -Filter "MSIAfterburnerSetup*.exe" | Select-Object -First 1 
473	                if ($exe) { 
474	                    $code = Invoke-ProcessWithTimeout -FilePath $exe.FullName -ArgumentList '/S' -TimeoutSeconds 180 
475	                    if ($code -in @(0,3010,1641) -and (Test-MenuPackageInstalled -Id $Id)) { $global:LASTEXITCODE = 0 } 
476	                } 
477	            } 
478	        } finally { 
479	            Remove-Item -LiteralPath $dl -Force -ErrorAction SilentlyContinue 
480	            Remove-Item -LiteralPath $dir -Recurse -Force -ErrorAction SilentlyContinue 
481	        } 
482	    } 
483	} 
484	 
485	function Install-AppFallback { 
486	    param([string]$Id) 
487	    $global:LASTEXITCODE = 1 
488	    Ensure-WinGetInstalled 
489	 
490	    if ($Id -in @('RARLab.WinRAR','Guru3D.Afterburner') -and (Test-MenuPackageInstalled -Id $Id)) { 
491	        $global:LASTEXITCODE = -1978335189; return 
492	    } 
493	    if ($Id -eq 'Adobe.Acrobat.Reader.64-bit' -and (Test-AdobeReaderInstalled)) { 
494	        $global:LASTEXITCODE = -1978335189; return 
495	    } 
496	try { 
497	        $wingetCode = Invoke-WingetSafe -Id $Id -TimeoutSeconds 240 
498	        if ($wingetCode -eq 0 -or $wingetCode -eq -1978335189) { 
499	            if ($Id -eq 'Google.Chrome') { Set-TaskbarChromeLayout } 
500	            $global:LASTEXITCODE = $wingetCode; return 
501	        } 
502	        switch ($Id) { 
503	            'Google.Chrome' { 
504	                $fileName = 'ChromeEnterprise_' + [guid]::NewGuid().ToString('N') + '.msi' 
505	                $setup = Get-VerifiedInstaller -Uri 'https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise64.msi' -FileName $fileName -PublisherPattern '(?i)(CN=Google LLC|O=Google LLC)' 
506	                $code = Invoke-ProcessWithTimeout -FilePath (Join-Path $env:SystemRoot 'System32\msiexec.exe') -ArgumentList "/i `"$setup`" /qn /norestart" -TimeoutSeconds 180 
507	                Remove-Item -LiteralPath $setup -Force -ErrorAction SilentlyContinue 
508	                if ($code -eq 0 -or $code -eq 3010) { Set-TaskbarChromeLayout } 
509	                $global:LASTEXITCODE = $code; return 
510	            } 
511	    } 
512	} 
513	    catch { 
514	        if ($Id -eq 'Adobe.Acrobat.Reader.64-bit') { Install-AdobeReaderDirect; return } 
515	        if ($Id -in @('RARLab.WinRAR','Guru3D.Afterburner')) { Install-MenuPackageDirect -Id $Id; return } 
516	        $global:LASTEXITCODE = 1 
517	    } 
518	} 
519	 
520	function Get-OfficeInstaller { 
521	    $ErrorActionPreference = 'Stop' 
522	    $ProgressPreference = 'SilentlyContinue' 
523	    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 
524	    $uri = 'https://raw.githubusercontent.com/Elsonsou124/etveel/main/OFF.bat' 
525	    $response = Invoke-WebRequest -Uri $uri -UseBasicParsing -TimeoutSec 180 -ErrorAction Stop 
526	    $txt = [string]$response.Content 
527	    $marker = '###' + 'PAYLOAD###' 
528	    $index = $txt.LastIndexOf($marker) 
529	    if ($index -lt 0) { throw 'Payload do Office nao encontrada.' } 
530	    $payload = $txt.Substring($index + $marker.Length) -replace '\s', '' 
531	    $bytes = [Convert]::FromBase64String($payload) 
532	    if ($bytes.Length -lt 2 -or $bytes[0] -ne 77 -or $bytes[1] -ne 90) { throw 'Executavel invalido' } 
533	    $exe = Join-Path $env:TEMP ('OfficeSetup_' + [guid]::NewGuid().ToString('N') + '.exe') 
534	    try { 
535	        [IO.File]::WriteAllBytes($exe, $bytes) 
536	        $signature = Get-AuthenticodeSignature -FilePath $exe 
537	        if ($signature.Status -ne 'Valid' -or -not $signature.SignerCertificate -or $signature.SignerCertificate.Subject -notmatch '(?i)(CN|O)=Microsoft Corporation(?:,|$)') { 
538	            throw 'Assinatura Microsoft invalida' 
539	        } 
540	        return $exe 
541	    } catch { 
542	        Remove-Item -LiteralPath $exe -Force -ErrorAction SilentlyContinue 
543	        throw 
544	    } 
545	} 
546	 
547	function Install-OfficeDeployment { 
548	    $exe = $null 
549	    try { 
550	        Write-Host "##INFO Baixando e validando instalador do Office..." 
551	        $exe = Get-OfficeInstaller 
552	 
553	        Write-Host "##INFO Executando instalador do Office..." 
554	        $processo = Start-Process -FilePath $exe -PassThru 
555	        $officePids = New-Object 'System.Collections.Generic.HashSet[int]' 
556	        [void]$officePids.Add([int]$processo.Id) 
557	        $officeUiaReady = $false 
558	        try { Add-Type -AssemblyName UIAutomationClient; Add-Type -AssemblyName UIAutomationTypes; $officeUiaReady = $true } catch {} 
559	        $officeConcluidoFechado = $false 
560	 
561	        while ($true) { 
562	            $listaProcessos = @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue) 
563	            $novos = $true 
564	            while ($novos) { 
565	                $novos = $false 
566	                foreach ($item in $listaProcessos) { 
567	                    if ($officePids.Contains([int]$item.ParentProcessId) -and -not $officePids.Contains([int]$item.ProcessId)) { 
568	                        [void]$officePids.Add([int]$item.ProcessId) 
569	                        $novos = $true 
570	                    } 
571	                } 
572	            } 
573	            $processosVivos = @($listaProcessos | Where-Object { $officePids.Contains([int]$_.ProcessId) }) 
574	            if ($processosVivos.Count -eq 0) { break } 
575	 
576	            if ($officeUiaReady -and -not $officeConcluidoFechado) { 
577	                try { 
578	                    $janelas = [System.Windows.Automation.AutomationElement]::RootElement.FindAll([System.Windows.Automation.TreeScope]::Children, [System.Windows.Automation.Condition]::TrueCondition) 
579	                    foreach ($janela in $janelas) { 
580	                        if (-not $officePids.Contains([int]$janela.Current.ProcessId)) { continue } 
581	                        $elementos = @($janela) + @($janela.FindAll([System.Windows.Automation.TreeScope]::Descendants, [System.Windows.Automation.Condition]::TrueCondition)) 
582	                        $nomes = New-Object System.Collections.Generic.List[string] 
583	                        $botoesFechar = New-Object System.Collections.ArrayList 
584	                        foreach ($elemento in $elementos) { 
585	                            try { 
586	                                $nome = [string]$elemento.Current.Name 
587	                                if ($nome) { [void]$nomes.Add($nome) } 
588	                                if ($elemento.Current.ControlType -eq [System.Windows.Automation.ControlType]::Button -and $nome -match '^(?i:Fechar|Close|Concluir|Finish|Finalizar|Done)$' -and $elemento.Current.IsEnabled) { 
589	                                    [void]$botoesFechar.Add($elemento) 
590	                                } 
591	                            } catch {} 
592	                        } 
593	                        $textoJanela = [string]::Join(' ', $nomes.ToArray()) 
594	                        $instalacaoConcluida = $textoJanela -match '(?i)(office|microsoft 365).{0,100}(installed|instalad[oa]|conclu[ií]d[oa])|(installation|instala[cç][aã]o).{0,60}(complete|completed|conclu[ií]d[oa]|finalizada)|(you.?re all set|all set|tudo pronto|pronto para usar)' 
595	                        if ($instalacaoConcluida -and $botoesFechar.Count -gt 0) { 
596	                            foreach ($botao in $botoesFechar) { 
597	                                try { 
598	                                    $padrao = $botao.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern) 
599	                                    $padrao.Invoke() 
600	                                    $officeConcluidoFechado = $true 
601	                                    break 
602	                                } catch {} 
603	                            } 
604	                        } 
605	                        if ($officeConcluidoFechado) { break } 
606	                    } 
607	                } catch {} 
608	            } 
609	            Start-Sleep -Seconds 2 
610	        } 
611	 
612	        $processo.Refresh() 
613	        $exitCode = [int]$processo.ExitCode 
614	        if ($exitCode -eq 3010) { $exitCode = 0 } 
615	        $global:LASTEXITCODE = $exitCode 
616	 
617	        if ($global:LASTEXITCODE -eq 0) { 
618	            $achou = $false 
619	            $desk = Join-Path ([Environment]::GetFolderPath("Desktop")) "Office 365" 
620	            $pastas = @("$env:ProgramData\Microsoft\Windows\Start Menu\Programs", "$env:APPDATA\Microsoft\Windows\Start Menu\Programs") 
621	            foreach ($app in @("*Word*.lnk", "*Excel*.lnk", "*PowerPoint*.lnk", "*Access*.lnk", "*Publisher*.lnk", "*OneNote*.lnk")) { 
622	                foreach ($dir in $pastas) { 
623	                    if (Test-Path $dir) { 
624	                        $arquivos = Get-ChildItem -Path $dir -Filter $app -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Name -notmatch "Wordpad|Voice" } 
625	                        foreach ($arq in $arquivos) { 
626	                            if (-not $achou) { 
627	                                if (-not (Test-Path $desk)) { New-Item -ItemType Directory -Force -Path $desk | Out-Null } 
628	                                $achou = $true 
629	                            } 
630	                            Copy-Item -Path $arq.FullName -Destination $desk -Force 
631	                        } 
632	                    } 
633	                } 
634	            } 
635	            if ($achou) { Write-Host "##INFO Atalhos do Office copiados com sucesso!" } 
636	            else { Write-Host "##INFO Nenhum atalho achado. O Office ja terminou de instalar?" } 
637	        } 
638	    } catch { 
639	        Write-Host "##INFO Erro na instalacao do Office: $($_.Exception.Message)" 
640	        $global:LASTEXITCODE = 1 
641	    } finally { 
642	        if ($exe) { Remove-Item -LiteralPath $exe -Force -ErrorAction SilentlyContinue } 
643	    } 
644	} 
645	 
646	 
647	function Set-TaskbarChromeLayout { 
648	 
649	    Write-Host "##INFO Configurando icones da barra de tarefas..." 
650	 
651	    # ------------------------------------------------ 
652	    # 1. LOCALIZAR CHROME 
653	    # ------------------------------------------------ 
654	 
655	    $chromePaths = @( 
656	        "$env:ProgramFiles\Google\Chrome\Application\chrome.exe", 
657	        "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe", 
658	        "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe" 
659	    ) 
660	 
661	    $chromeExe = $chromePaths | 
662	        Where-Object { $_ -and (Test-Path -LiteralPath $_) } | 
663	        Select-Object -First 1 
664	 
665	    # ------------------------------------------------ 
666	    # 2. LOCALIZAR OU CRIAR ATALHO DO CHROME 
667	    # ------------------------------------------------ 
668	 
669	    $chromeLnk = @( 
670	        "$env:ALLUSERSPROFILE\Microsoft\Windows\Start Menu\Programs\Google Chrome.lnk", 
671	        "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Google Chrome.lnk" 
672	    ) | Where-Object { 
673	        Test-Path -LiteralPath $_ 
674	    } | Select-Object -First 1 
675	 
676	    if (-not $chromeLnk -and $chromeExe) { 
677	 
678	        $chromeLnk = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Google Chrome.lnk" 
679	 
680	        $shell = New-Object -ComObject WScript.Shell 
681	        $shortcut = $shell.CreateShortcut($chromeLnk) 
682	 
683	        $shortcut.TargetPath = $chromeExe 
684	        $shortcut.WorkingDirectory = Split-Path $chromeExe 
685	        $shortcut.Description = "Google Chrome" 
686	        $shortcut.Save() 
687	    } 
688	 
689	    # ------------------------------------------------ 
690	    # 3. LOCALIZAR EXPLORADOR 
691	    # ------------------------------------------------ 
692	 
693	    $explorerLnk = @( 
694	        "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\System Tools\File Explorer.lnk", 
695	        "$env:ALLUSERSPROFILE\Microsoft\Windows\Start Menu\Programs\System Tools\File Explorer.lnk" 
696	    ) | Where-Object { 
697	        Test-Path -LiteralPath $_ 
698	    } | Select-Object -First 1 
699	 
700	    # Criar atalho próprio se não existir 
701	    if (-not $explorerLnk) { 
702	 
703	        $explorerLnk = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\File Explorer.lnk" 
704	 
705	        $shell = New-Object -ComObject WScript.Shell 
706	        $shortcut = $shell.CreateShortcut($explorerLnk) 
707	 
708	        $shortcut.TargetPath = "$env:WINDIR\explorer.exe" 
709	        $shortcut.WorkingDirectory = "$env:WINDIR" 
710	        $shortcut.Description = "Explorador de Arquivos" 
711	        $shortcut.Save() 
712	    } 
713	 
714	    # ------------------------------------------------ 
715	    # 4. IMPLEMENTACAO COM IPinnedList3 
716	    # ------------------------------------------------ 
717	 
718	    $pinCode = @" 
719	using System; 
720	using System.Runtime.InteropServices; 
721	 
722	public class TaskbarPinner 
723	{ 
724	    [DllImport("shell32.dll", CharSet = CharSet.Unicode)] 
725	    static extern IntPtr ILCreateFromPath(string path); 
726	 
727	    [DllImport("shell32.dll")] 
728	    static extern void ILFree(IntPtr pidl); 
729	 
730	    [ComImport] 
731	    [Guid("0DD79AE2-D156-45D4-9EEB-3B549769E940")] 
732	    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)] 
733	    interface IPinnedList3 
734	    { 
735	        void EnumObjects(); 
736	        void GetPinnableInfo(); 
737	        void IsPinnable(); 
738	        void Resolve(); 
739	        void LegacyModify(); 
740	        void GetChangeCount(); 
741	        void IsPinned(); 
742	        void GetPinnedItem(); 
743	        void GetAppIDForPinnedItem(); 
744	        void ItemChangeNotify(); 
745	        void UpdateForRemovedItemsAsNecessary(); 
746	        void PinShellLink(); 
747	        void GetPinnedItemForAppID(); 
748	        [PreserveSig] 
749	        int Modify(IntPtr unpin, IntPtr pin, int caller); 
750	    } 
751	 
752	    public static int Pin(string path) 
753	    { 
754	        IntPtr pidl = IntPtr.Zero; 
755	        IPinnedList3 list = null; 
756	 
757	        try 
758	        { 
759	            pidl = ILCreateFromPath(path); 
760	 
761	            if (pidl == IntPtr.Zero) 
762	                return unchecked((int)0x80070002); 
763	 
764	            Type t = Type.GetTypeFromCLSID( 
765	                new Guid("90AA3A4E-1CBA-4233-B8BB-535773D48449") 
766	            ); 
767	 
768	            list = (IPinnedList3)Activator.CreateInstance(t); 
769	 
770	            return list.Modify(IntPtr.Zero, pidl, 4); 
771	        } 
772	        catch (Exception ex) 
773	        { 
774	            return Marshal.GetHRForException(ex); 
775	        } 
776	        finally 
777	        { 
778	            if (list != null && Marshal.IsComObject(list)) 
779	                Marshal.ReleaseComObject(list); 
780	 
781	            if (pidl != IntPtr.Zero) 
782	                ILFree(pidl); 
783	        } 
784	    } 
785	} 
786	"@ 
787	 
788	    # ------------------------------------------------ 
789	    # 5. EXECUTAR 
790	    # ------------------------------------------------ 
791	 
792	    try { 
793	 
794	        Add-Type -TypeDefinition $pinCode -ErrorAction Stop 
795	 
796	        $items = @( 
797	            @{ Nome = "Explorador de Arquivos"; Caminho = $explorerLnk }, 
798	            @{ Nome = "Google Chrome"; Caminho = $chromeLnk } 
799	        ) 
800	 
801	        foreach ($item in $items) { 
802	 
803	            if (-not $item.Caminho -or 
804	                -not (Test-Path -LiteralPath $item.Caminho)) { 
805	 
806	                Write-Host "##ERRO $($item.Nome): atalho nao encontrado." 
807	                continue 
808	            } 
809	 
810	            $result = [TaskbarPinner]::Pin($item.Caminho) 
811	 
812	            if ($result -eq 0) { 
813	                Write-Host "##INFO $($item.Nome): solicitacao enviada." 
814	            } 
815	            else { 
816	                $hex = "0x{0:X8}" -f ($result -band 0xFFFFFFFF) 
817	                Write-Host "##ERRO $($item.Nome): $hex" 
818	            } 
819	        } 
820	 
821	    } 
822	    catch { 
823	        Write-Host "##ERRO COM: $($_.Exception.Message)" 
824	    } 
825	 
826	    Write-Host "##INFO Configuracao finalizada." 
827	} 
828	'@ 
829	 
830	function W($id) { "Install-AppFallback -Id '$id'" } 
831	 
832	 
833	# ===================================================================== 
834	# SEÇÃO 3: ROTEAMENTO DE INTERFACE (CARREGA APENAS O MODO ESCOLHIDO) 
835	# ===================================================================== 
836	if ($ModoExecucao -eq 'GUI') { 
837	    # ----------------------------------------------------------------- 
838	    # MODO 1: INTERFACE GRÁFICA PRO (WINDOWS FORMS 1120x690) 
839	    # ----------------------------------------------------------------- 
840	    Add-Type -AssemblyName System.Windows.Forms 
841	    Add-Type -AssemblyName System.Drawing 
842	    [System.Windows.Forms.Application]::EnableVisualStyles() 
843	 
844	    $global:tasks = New-Object System.Collections.ArrayList 
845	    $global:totalEtapas = 0 
846	    $global:etapaAtual = 0 
847	    $global:isBatchTask = $false 
848	 
849	    function Log($msg) {  
850	        $logBox.AppendText((Get-Date -Format 'HH:mm:ss') + "  " + $msg + "`r`n")  
851	        $logBox.SelectionStart = $logBox.Text.Length 
852	        $logBox.ScrollToCaret() 
853	        Update-CustomScroll 
854	    } 
855	 
856	    function Start-Task($titulo, $script, $total = 1) { 
857	        $taskId = [guid]::NewGuid().ToString('N') 
858	        $out = Join-Path $env:TEMP ("inst_" + $taskId + ".txt") 
859	        $worker = Join-Path $env:TEMP ("inst_" + $taskId + ".ps1") 
860	        $escapedOut = $out.Replace("'", "''") 
861	        $script = "& { " + $appInstallHelpers + "`r`n" + $script + " } *> '$escapedOut'; exit `$LASTEXITCODE" 
862	        [IO.File]::WriteAllText($worker, $script, (New-Object System.Text.UTF8Encoding($true))) 
863	        try { 
864	            $p = Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -STA -File `"$worker`"" -WindowStyle Hidden -PassThru -ErrorAction Stop 
865	        } catch { 
866	            Remove-Item -LiteralPath $worker -Force -ErrorAction SilentlyContinue 
867	            throw 
868	        } 
869	        [void]$global:tasks.Add(@{ Nome = $titulo; Proc = $p; Out = $out; Worker = $worker; Lido = 0; Ok = 0; Ja = 0; Erro = 0 }) 
870	 
871	        $global:totalEtapas = $total 
872	        $global:etapaAtual = 0 
873	        $progressBarFill.BackColor = [System.Drawing.Color]::FromArgb(0, 150, 240) 
874	        $progressPulse.Visible = $true 
875	 
876	        if ($total -gt 1) { 
877	            $global:isBatchTask = $true 
878	            $global:progressMax = $total 
879	            $global:progressVal = 0.2 
880	            $global:progressTarget = 0.8 
881	            Update-CustomProgress 0.2 
882	            $lblStatus.Text = "Instalando lote: $titulo (0/$total)..." 
883	            $lblStatus.ForeColor = [System.Drawing.Color]::FromArgb(0, 255, 180) 
884	        } else { 
885	            $global:isBatchTask = $false 
886	            $global:progressMax = 100 
887	            $global:progressVal = 15 
888	            $global:progressTarget = 92 
889	            Update-CustomProgress 15 
890	            $qtdFila = $global:tasks.Count 
891	            $lblStatus.Text = if ($qtdFila -gt 1) { "Instalando: $titulo (Fila: $qtdFila tarefas)..." } else { "Instalando: $titulo..." } 
892	            $lblStatus.ForeColor = [System.Drawing.Color]::FromArgb(0, 230, 255) 
893	        } 
894	        Log "=== Iniciando: $titulo ===" 
895	    } 
896	 
897	    function Passo($n, $tot, $nome, $cmd) { 
898	        "Write-Host '##AGORA [$n/$tot] $nome'; `$global:LASTEXITCODE = 0; $cmd; `$c = `$global:LASTEXITCODE; " + 
899	        "if (`$c -eq 0) { Write-Host '##OK $nome' } elseif (`$c -eq -1978335189) { Write-Host '##JA $nome' } " + 
900	        "else { Write-Host ('##ERRO $nome (codigo ' + `$c + ')'); `$global:falhou = 1 }" 
901	    } 
902	 
903	    function Lote($passos) { "`$global:falhou = 0; " + ($passos -join "; ") + "; `$global:LASTEXITCODE = [int]`$global:falhou" } 
904	 
905	    # Splash Screen 
906	    $splash = New-Object System.Windows.Forms.Form 
907	    $splash.ClientSize = New-Object System.Drawing.Size(460, 220) 
908	    $splash.StartPosition = "CenterScreen" 
909	    $splash.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None 
910	    $splash.BackColor = [System.Drawing.Color]::FromArgb(20, 22, 28) 
911	    $splash.Opacity = 0.0 
912	 
913	    $splashPanel = New-Object System.Windows.Forms.Panel 
914	    $splashPanel.Dock = "Fill" 
915	    $splashPanel.BackColor = [System.Drawing.Color]::FromArgb(20, 22, 28) 
916	    $splash.Controls.Add($splashPanel) 
917	 
918	    $lblSplashTitle = New-Object System.Windows.Forms.Label 
919	    $lblSplashTitle.Text = "ASSISTENTE DE FORMATAÇÃO PRO" 
920	    $lblSplashTitle.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold) 
921	    $lblSplashTitle.ForeColor = [System.Drawing.Color]::FromArgb(0, 180, 255) 
922	    $lblSplashTitle.AutoSize = $true 
923	    $lblSplashTitle.Location = New-Object System.Drawing.Point(65, 45) 
924	    $splashPanel.Controls.Add($lblSplashTitle) 
925	 
926	    $lblSplashSub = New-Object System.Windows.Forms.Label 
927	    $lblSplashSub.Text = "Desenvolvido por: Elson (Criatividade E Tudo)" 
928	    $lblSplashSub.Font = New-Object System.Drawing.Font("Segoe UI", 9.5) 
929	    $lblSplashSub.ForeColor = [System.Drawing.Color]::FromArgb(180, 190, 205) 
930	    $lblSplashSub.AutoSize = $true 
931	    $lblSplashSub.Location = New-Object System.Drawing.Point(85, 85) 
932	    $splashPanel.Controls.Add($lblSplashSub) 
933	 
934	    $lblSplashVer = New-Object System.Windows.Forms.Label 
935	    $lblSplashVer.Text = "Versão $VersaoAtual — Inicializando Ambiente..." 
936	    $lblSplashVer.Font = New-Object System.Drawing.Font("Segoe UI", 8.5) 
937	    $lblSplashVer.ForeColor = [System.Drawing.Color]::FromArgb(110, 125, 145) 
938	    $lblSplashVer.AutoSize = $true 
939	    $lblSplashVer.Location = New-Object System.Drawing.Point(130, 125) 
940	    $splashPanel.Controls.Add($lblSplashVer) 
941	 
942	    $splashBarBg = New-Object System.Windows.Forms.Panel 
943	    $splashBarBg.Location = New-Object System.Drawing.Point(50, 170) 
944	    $splashBarBg.Size = New-Object System.Drawing.Size(360, 4) 
945	    $splashBarBg.BackColor = [System.Drawing.Color]::FromArgb(35, 40, 50) 
946	    $splashPanel.Controls.Add($splashBarBg) 
947	 
948	    $splashBarFill = New-Object System.Windows.Forms.Panel 
949	    $splashBarFill.Location = New-Object System.Drawing.Point(0, 0) 
950	    $splashBarFill.Size = New-Object System.Drawing.Size(0, 4) 
951	    $splashBarFill.BackColor = [System.Drawing.Color]::FromArgb(0, 200, 255) 
952	    $splashBarBg.Controls.Add($splashBarFill) 
953	 
954	    $splashTimer = New-Object System.Windows.Forms.Timer 
955	    $splashTimer.Interval = 20 
956	    $global:splashCount = 0 
957	    $splashTimer.Add_Tick({ 
958	        $global:splashCount++ 
959	        if ($splash.Opacity -lt 1.0) { $splash.Opacity += 0.08 } 
960	        $currentWidth = [int](($global:splashCount / 60) * 360) 
961	        if ($currentWidth -le 360) { $splashBarFill.Width = $currentWidth } 
962	        if ($global:splashCount -gt 60) { $splashTimer.Stop(); $splash.Close() } 
963	    }) 
964	    $splash.Add_Shown({ $splashTimer.Start() }) 
965	    $splash.ShowDialog() 
966	    $splash.Dispose() 
967	 
968	    # Janela Principal (1120x690) 
969	    $form = New-Object System.Windows.Forms.Form 
970	    $form.Icon = [System.Drawing.SystemIcons]::Application 
971	    $form.ShowIcon = $true 
972	    $form.Text = "Assistente de Formatação Pro ($VersaoAtual)" 
973	    $form.ClientSize = New-Object System.Drawing.Size(1120, 690) 
974	    $form.StartPosition = "CenterScreen" 
975	    $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None 
976	    $form.BackColor = [System.Drawing.Color]::FromArgb(28, 30, 38) 
977	    $form.ForeColor = [System.Drawing.Color]::FromArgb(230, 230, 230) 
978	    $form.Font = New-Object System.Drawing.Font("Segoe UI", 10) 
979	 
980	    $global:mouseOffset = $null 
981	    $customTitleBar = New-Object System.Windows.Forms.Panel 
982	    $customTitleBar.Location = New-Object System.Drawing.Point(0, 0) 
983	    $customTitleBar.Size = New-Object System.Drawing.Size(1120, 35) 
984	    $customTitleBar.BackColor = [System.Drawing.Color]::FromArgb(15, 17, 22) 
985	    $form.Controls.Add($customTitleBar) 
986	 
987	    $customTitleBar.Add_MouseDown({ if ($_.Button -eq [System.Windows.Forms.MouseButtons]::Left) { $global:mouseOffset = New-Object System.Drawing.Point($_.X, $_.Y) } }) 
988	    $customTitleBar.Add_MouseMove({ 
989	        if ($_.Button -eq [System.Windows.Forms.MouseButtons]::Left) { 
990	            $mousePos = [System.Windows.Forms.Control]::MousePosition 
991	            $mousePos.Offset(-$global:mouseOffset.X, -$global:mouseOffset.Y) 
992	            $form.Location = $mousePos 
993	        } 
994	    }) 
995	 
996	    $lblWindowTitle = New-Object System.Windows.Forms.Label 
997	    $lblWindowTitle.Text = "  Assistente de Formatação Pro ($VersaoAtual)" 
998	    $lblWindowTitle.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold) 
999	    $lblWindowTitle.ForeColor = [System.Drawing.Color]::FromArgb(200, 210, 225) 
1000	    $lblWindowTitle.AutoSize = $true 
1001	    $lblWindowTitle.Location = New-Object System.Drawing.Point(5, 8) 
1002	    $customTitleBar.Controls.Add($lblWindowTitle) 
1003	 
1004	    $btnClose = New-Object System.Windows.Forms.Button 
1005	    $btnClose.Text = "✕" 
1006	    $btnClose.Size = New-Object System.Drawing.Size(45, 35) 
1007	    $btnClose.Location = New-Object System.Drawing.Point(1075, 0) 
1008	    $btnClose.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat 
1009	    $btnClose.FlatAppearance.BorderSize = 0 
1010	    $btnClose.BackColor = [System.Drawing.Color]::FromArgb(15, 17, 22) 
1011	    $btnClose.ForeColor = [System.Drawing.Color]::FromArgb(200, 200, 200) 
1012	    $btnClose.Cursor = [System.Windows.Forms.Cursors]::Hand 
1013	    $btnClose.Add_MouseEnter({ $this.BackColor = [System.Drawing.Color]::FromArgb(232, 17, 35); $this.ForeColor = [System.Drawing.Color]::White }) 
1014	    $btnClose.Add_MouseLeave({ $this.BackColor = [System.Drawing.Color]::FromArgb(15, 17, 22); $this.ForeColor = [System.Drawing.Color]::FromArgb(200, 200, 200) }) 
1015	    $btnClose.Add_Click({ $form.Close() }) 
1016	    $customTitleBar.Controls.Add($btnClose) 
1017	 
1018	    $btnMinimize = New-Object System.Windows.Forms.Button 
1019	    $btnMinimize.Text = "—" 
1020	    $btnMinimize.Size = New-Object System.Drawing.Size(45, 35) 
1021	    $btnMinimize.Location = New-Object System.Drawing.Point(1030, 0) 
1022	    $btnMinimize.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat 
1023	    $btnMinimize.FlatAppearance.BorderSize = 0 
1024	    $btnMinimize.BackColor = [System.Drawing.Color]::FromArgb(15, 17, 22) 
1025	    $btnMinimize.ForeColor = [System.Drawing.Color]::FromArgb(200, 200, 200) 
1026	    $btnMinimize.Cursor = [System.Windows.Forms.Cursors]::Hand 
1027	    $btnMinimize.Add_MouseEnter({ $this.BackColor = [System.Drawing.Color]::FromArgb(50, 55, 70); $this.ForeColor = [System.Drawing.Color]::White }) 
1028	    $btnMinimize.Add_MouseLeave({ $this.BackColor = [System.Drawing.Color]::FromArgb(15, 17, 22); $this.ForeColor = [System.Drawing.Color]::FromArgb(200, 200, 200) }) 
1029	    $btnMinimize.Add_Click({ $form.WindowState = [System.Windows.Forms.FormWindowState]::Minimized }) 
1030	    $customTitleBar.Controls.Add($btnMinimize) 
1031	 
1032	    $customToolTip = New-Object System.Windows.Forms.Panel 
1033	    $customToolTip.Size = New-Object System.Drawing.Size(340, 125) 
1034	    $customToolTip.BackColor = [System.Drawing.Color]::FromArgb(35, 39, 46) 
1035	    $customToolTip.Visible = $false 
1036	    $customToolTip.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle 
1037	 
1038	    $toolTipLabel = New-Object System.Windows.Forms.Label 
1039	    $toolTipLabel.Location = New-Object System.Drawing.Point(8, 8) 
1040	    $toolTipLabel.Size = New-Object System.Drawing.Size(322, 108) 
1041	    $toolTipLabel.ForeColor = [System.Drawing.Color]::FromArgb(220, 225, 235) 
1042	    $toolTipLabel.Font = New-Object System.Drawing.Font("Segoe UI", 8.5) 
1043	    $customToolTip.Controls.Add($toolTipLabel) 
1044	    $form.Controls.Add($customToolTip) 
1045	    $customToolTip.BringToFront() 
1046	 
1047	    $header = New-Object System.Windows.Forms.Panel 
1048	    $header.Location = New-Object System.Drawing.Point(0, 35) 
1049	    $header.Size = New-Object System.Drawing.Size(1120, 68) 
1050	    $header.BackColor = [System.Drawing.Color]::FromArgb(20, 22, 28) 
1051	    $form.Controls.Add($header) 
1052	 
1053	    $title = New-Object System.Windows.Forms.Label 
1054	    $title.Text = "ASSISTENTE DE FORMATAÇÃO PRO" 
1055	    $title.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold) 
1056	    $title.ForeColor = [System.Drawing.Color]::White 
1057	    $title.AutoSize = $true 
1058	    $title.Location = New-Object System.Drawing.Point(24, 9) 
1059	    $header.Controls.Add($title) 
1060	 
1061	    $subTitle = New-Object System.Windows.Forms.Label 
1062	    $subTitle.Text = "Central de Automação e Pós-Instalação • Modo Gráfico" 
1063	    $subTitle.Font = New-Object System.Drawing.Font("Segoe UI", 9) 
1064	    $subTitle.ForeColor = [System.Drawing.Color]::FromArgb(150, 160, 175) 
1065	    $subTitle.AutoSize = $true 
1066	    $subTitle.Location = New-Object System.Drawing.Point(28, 37) 
1067	    $header.Controls.Add($subTitle) 
1068	 
1069	    $netBadge = New-Object System.Windows.Forms.Panel 
1070	    $netBadge.Location = New-Object System.Drawing.Point(806, 14) 
1071	    $netBadge.Size = New-Object System.Drawing.Size(290, 40) 
1072	    $netBadge.BackColor = [System.Drawing.Color]::FromArgb(28, 32, 42) 
1073	    $netBadge.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle 
1074	    $header.Controls.Add($netBadge) 
1075	 
1076	    $netDot = New-Object System.Windows.Forms.Panel 
1077	    $netDot.Location = New-Object System.Drawing.Point(12, 14) 
1078	    $netDot.Size = New-Object System.Drawing.Size(12, 12) 
1079	    $netDot.BackColor = [System.Drawing.Color]::FromArgb(120, 130, 145) 
1080	    $netBadge.Controls.Add($netDot) 
1081	 
1082	    $lblNetStatus = New-Object System.Windows.Forms.Label 
1083	    $lblNetStatus.Text = "Verificando conexão..." 
1084	    $lblNetStatus.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold) 
1085	    $lblNetStatus.ForeColor = [System.Drawing.Color]::FromArgb(200, 210, 225) 
1086	    $lblNetStatus.AutoSize = $true 
1087	    $lblNetStatus.Location = New-Object System.Drawing.Point(32, 11) 
1088	    $netBadge.Controls.Add($lblNetStatus) 
1089	 
1090	    function Update-NetworkStatus { 
1091	        try { 
1092	            $nics = [System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces() | Where-Object { 
1093	                $_.OperationalStatus -eq [System.Net.NetworkInformation.OperationalStatus]::Up -and 
1094	                $_.NetworkInterfaceType -ne [System.Net.NetworkInformation.NetworkInterfaceType]::Loopback -and 
1095	                $_.NetworkInterfaceType -ne [System.Net.NetworkInformation.NetworkInterfaceType]::Tunnel -and 
1096	                $_.Description -notmatch '(?i)Virtual|Hyper-V|VMware|VirtualBox|TAP-|VPN|Pseudo|Bluetooth' 
1097	            } 
1098	            $eth = $nics | Where-Object { $_.NetworkInterfaceType -eq [System.Net.NetworkInformation.NetworkInterfaceType]::Ethernet } | Select-Object -First 1 
1099	            $wifi = $nics | Where-Object { $_.NetworkInterfaceType -eq [System.Net.NetworkInformation.NetworkInterfaceType]::Wireless80211 } | Select-Object -First 1 
1100	            if ($eth) { 
1101	                $mbps = [Math]::Round($eth.Speed / 1000000) 
1102	                $speedTxt = if ($mbps -ge 1000) { "$([Math]::Round($mbps / 1000, 1)) Gbps" } elseif ($mbps -gt 0) { "$mbps Mbps" } else { "Ativo" } 
1103	                $lblNetStatus.Text = "CABO ETHERNET • $speedTxt" 
1104	                $lblNetStatus.ForeColor = [System.Drawing.Color]::FromArgb(0, 255, 165) 
1105	                $netDot.BackColor = [System.Drawing.Color]::FromArgb(0, 230, 145) 
1106	                $netBadge.BackColor = [System.Drawing.Color]::FromArgb(22, 42, 36) 
1107	            } elseif ($wifi) { 
1108	                $lblNetStatus.Text = "WI-FI ATIVO • Conecte o Cabo" 
1109	                $lblNetStatus.ForeColor = [System.Drawing.Color]::FromArgb(255, 205, 65) 
1110	                $netDot.BackColor = [System.Drawing.Color]::FromArgb(255, 190, 40) 
1111	                $netBadge.BackColor = [System.Drawing.Color]::FromArgb(46, 38, 22) 
1112	            } else { 
1113	                $lblNetStatus.Text = "SEM REDE • Cabo Desconectado" 
1114	                $lblNetStatus.ForeColor = [System.Drawing.Color]::FromArgb(255, 95, 105) 
1115	                $netDot.BackColor = [System.Drawing.Color]::FromArgb(235, 65, 75) 
1116	                $netBadge.BackColor = [System.Drawing.Color]::FromArgb(48, 24, 28) 
1117	            } 
1118	        } catch { $lblNetStatus.Text = "Status de rede indisponível" } 
1119	    } 
1120	    Update-NetworkStatus 
1121	    $netTimer = New-Object System.Windows.Forms.Timer; $netTimer.Interval = 3000; $netTimer.Add_Tick({ Update-NetworkStatus }); $netTimer.Start() 
1122	 
1123	    $individualTitle = New-Object System.Windows.Forms.Label 
1124	    $individualTitle.Text = "AÇÕES INDIVIDUAIS" 
1125	    $individualTitle.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold) 
1126	    $individualTitle.ForeColor = [System.Drawing.Color]::FromArgb(100, 180, 255) 
1127	    $individualTitle.AutoSize = $true 
1128	    $individualTitle.Location = New-Object System.Drawing.Point(24, 112) 
1129	    $form.Controls.Add($individualTitle) 
1130	 
1131	    $bundleTitle = New-Object System.Windows.Forms.Label 
1132	    $bundleTitle.Text = "PACOTES & MANUTENÇÃO" 
1133	    $bundleTitle.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold) 
1134	    $bundleTitle.ForeColor = [System.Drawing.Color]::FromArgb(100, 180, 255) 
1135	    $bundleTitle.AutoSize = $true 
1136	    $bundleTitle.Location = New-Object System.Drawing.Point(24, 232) 
1137	    $form.Controls.Add($bundleTitle) 
1138	 
1139	    $actions = [ordered]@{ 
1140	        "Ativação Windows"           = { Start-Process powershell -ArgumentList "-NoProfile -WindowStyle Hidden -Command `"& ([ScriptBlock]::Create((irm https://get.activated.win))) `"" ; Log "Tela de Ativacao do Windows foi Aberta" } 
1141	        "Instalar Google Chrome"     = { Start-Task "Chrome" (Lote @(Passo 1 1 "Chrome" (W "Google.Chrome"))) } 
1142	        "Instalar WinRAR"            = { Start-Task "WinRAR" (Lote @(Passo 1 1 "WinRAR" (W "RARLab.WinRAR"))) } 
1143	        "Instalar MSI Afterburner"   = { Start-Task "Afterburner" (Lote @(Passo 1 1 "MSI Afterburner" (W "Guru3D.Afterburner"))) } 
1144	        "Instalar Adobe Reader"      = { Start-Task "Adobe Reader" (Lote @(Passo 1 1 "Adobe Acrobat Reader" (W "Adobe.Acrobat.Reader.64-bit"))) } 
1145	        "Instalar Apenas o Office" = { Start-Task "Office e atalhos" (Lote @(Passo 1 1 "Office" "Install-OfficeDeployment")) } 
1146	        "Kit Gamer" = { 
1147	            Start-Task "Kit Gamer" (Lote @( 
1148	                (Passo 1 6 "Desempenho Maximo" "Install-GamerPowerPlan"), 
1149	                (Passo 2 6 ".NET Framework 3.5" "Install-GamerNetFx3"), 
1150	                (Passo 3 6 ".NET Desktop Runtime 8" "Install-GamerDotNet8"), 
1151	                (Passo 4 6 "Visual C++ Redistributable" "Install-GamerVCRedist"), 
1152	                (Passo 5 6 "DirectX Runtimes" "Install-GamerDirectX"), 
1153	                (Passo 6 6 "Aplicativo Oficial da GPU" "Install-GamerGPUApp") 
1154	            )) -total 6 
1155	        } 
1156	        "TUDO (Sem MSI e sem Office)" = { 
1157	            Start-Task "TUDO Sem MSI e sem Office" (Lote @( 
1158	                (Passo 1 3 "Chrome" (W "Google.Chrome")), 
1159	                (Passo 2 3 "Acrobat Reader" (W "Adobe.Acrobat.Reader.64-bit")), 
1160	                (Passo 3 3 "WinRAR" (W "RARLab.WinRAR")) 
1161	            )) -total 3 
1162	        } 
1163	        "INSTALAR TUDO (Sem MSI)" = { 
1164	            Start-Task "INSTALAR TUDO (Sem MSI)" (Lote @( 
1165	                (Passo 1 4 "Chrome" (W "Google.Chrome")), 
1166	                (Passo 2 4 "Acrobat Reader" (W "Adobe.Acrobat.Reader.64-bit")), 
1167	                (Passo 3 4 "WinRAR" (W "RARLab.WinRAR")), 
1168	                (Passo 4 4 "Office" "Install-OfficeDeployment") 
1169	            )) -total 4 
1170	        } 
1171	        "INSTALAR TUDO + Office" = { 
1172	            Start-Task "TUDO com Office" (Lote @( 
1173	                (Passo 1 5 "Chrome" (W "Google.Chrome")), 
1174	                (Passo 2 5 "Acrobat Reader" (W "Adobe.Acrobat.Reader.64-bit")), 
1175	                (Passo 3 5 "WinRAR" (W "RARLab.WinRAR")), 
1176	                (Passo 4 5 "MSI Afterburner" (W "Guru3D.Afterburner")), 
1177	                (Passo 5 5 "Office" "Install-OfficeDeployment") 
1178	            )) -total 5 
1179	        } 
1180	        "Atualizar Windows" = { Start-Task "Atualizar Windows" (Lote @(Passo 1 1 "Windows Update" "Invoke-WindowsUpdate")) } 
1181	        "Atualizar Drivers" = { Start-Task "Atualizar Drivers" (Lote @(Passo 1 1 "Drivers Update" "Invoke-DriverUpdate")) } 
1182	    } 
1183	 
1184	    $packageTooltips = @{ 
1185	        "Kit Gamer"                     = "Otimização e Runtimes para Jogos:`n1. Desempenho Máximo de Energia`n2. .NET Framework 3.5`n3. .NET Desktop Runtime 8`n4. Visual C++ Redistributable (AIO/MS)`n5. DirectX Runtimes (WinGet/Web/Offline)`n6. App Oficial da GPU (NVIDIA App, AMD Adrenalin ou Intel)"; 
1186	        "TUDO (Sem MSI e sem Office)" = "Este pacote instala automaticamente:`n• Google Chrome`n• Adobe Acrobat Reader`n• WinRAR"; 
1187	        "INSTALAR TUDO (Sem MSI)"     = "Este pacote instala automaticamente:`n• Google Chrome`n• Adobe Acrobat Reader`n• WinRAR`n• Microsoft Office (com atalhos)"; 
1188	        "INSTALAR TUDO + Office"      = "Pacote Completo Avançado:`n• Google Chrome`n• Adobe Acrobat Reader`n• WinRAR`n• MSI Afterburner`n• Microsoft Office (com atalhos)"; 
1189	        "Atualizar Windows"           = "Varre, baixa e instala todas as atualizações de software pendentes do Windows Update."; 
1190	        "Atualizar Drivers"           = "Busca e instala atualizações de drivers oficiais disponíveis via Windows Update." 
1191	    } 
1192	 
1193	    $actionNumber = 0 
1194	    foreach ($name in $actions.Keys) { 
1195	        $actionNumber++ 
1196	        $lblNum = New-Object System.Windows.Forms.Label 
1197	        $lblNum.Text = ("{0:D2}" -f $actionNumber) 
1198	        $lblNum.Font = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Bold) 
1199	        $lblNum.ForeColor = [System.Drawing.Color]::FromArgb(120, 135, 155) 
1200	        $lblNum.AutoSize = $true 
1201	 
1202	        $btn = New-Object System.Windows.Forms.Button 
1203	        $btn.Text = $name 
1204	        $btn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat 
1205	        $btn.FlatAppearance.BorderSize = 0 
1206	        $btn.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9.5) 
1207	        $btn.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter 
1208	        $btn.Cursor = [System.Windows.Forms.Cursors]::Hand 
1209	 
1210	        $baseBg = [System.Drawing.Color]::FromArgb(45, 48, 58) 
1211	        $baseFg = [System.Drawing.Color]::FromArgb(230, 230, 230) 
1212	        $hoverBg = [System.Drawing.Color]::FromArgb(60, 65, 80) 
1213	 
1214	        if ($name -eq "Kit Gamer") { 
1215	            $baseBg = [System.Drawing.Color]::FromArgb(0, 120, 215); $baseFg = [System.Drawing.Color]::White; $hoverBg = [System.Drawing.Color]::FromArgb(20, 140, 240) 
1216	        } elseif ($name -match "INSTALAR TUDO") { 
1217	            $baseBg = [System.Drawing.Color]::FromArgb(50, 140, 90); $baseFg = [System.Drawing.Color]::White; $hoverBg = [System.Drawing.Color]::FromArgb(70, 160, 110) 
1218	        } 
1219	 
1220	        if ($packageTooltips.ContainsKey($name)) { 
1221	            $btn.Tag = @{ Acao = $actions[$name]; CorNormal = $baseBg; CorHover = $hoverBg; Tip = $packageTooltips[$name] } 
1222	            $btn.Add_MouseEnter({ 
1223	                $this.BackColor = $this.Tag.CorHover 
1224	                $toolTipLabel.Text = $this.Tag.Tip 
1225	                $pt = $form.PointToClient([System.Windows.Forms.Cursor]::Position) 
1226	                $customToolTip.Location = New-Object System.Drawing.Point(($pt.X + 15), ($pt.Y + 15)) 
1227	                $customToolTip.Visible = $true; $customToolTip.BringToFront() 
1228	            }) 
1229	            $btn.Add_MouseLeave({ $this.BackColor = $this.Tag.CorNormal; $customToolTip.Visible = $false }) 
1230	        } else { 
1231	            $btn.Tag = @{ Acao = $actions[$name]; CorNormal = $baseBg; CorHover = $hoverBg; Tip = $null } 
1232	            $btn.Add_MouseEnter({ $this.BackColor = $this.Tag.CorHover }) 
1233	            $btn.Add_MouseLeave({ $this.BackColor = $this.Tag.CorNormal }) 
1234	        } 
1235	 
1236	        if ($actionNumber -le 6) { 
1237	            $col = ($actionNumber - 1) % 3; $row = [int][Math]::Floor(($actionNumber - 1) / 3) 
1238	            $btn.Size = New-Object System.Drawing.Size(316, 38) 
1239	            $btn.Location = New-Object System.Drawing.Point((48 + ($col * 364)), (134 + ($row * 44))) 
1240	            $lblNum.Location = New-Object System.Drawing.Point((24 + ($col * 364)), (144 + ($row * 44))) 
1241	        } else { 
1242	            $colIdx = ($actionNumber - 7) % 3; $rowIdx = [int][Math]::Floor(($actionNumber - 7) / 3) 
1243	            $btn.Size = New-Object System.Drawing.Size(316, 38) 
1244	            $btn.Location = New-Object System.Drawing.Point((48 + ($colIdx * 364)), (254 + ($rowIdx * 44))) 
1245	            $lblNum.Location = New-Object System.Drawing.Point((24 + ($colIdx * 364)), (264 + ($rowIdx * 44))) 
1246	        } 
1247	 
1248	        $btn.BackColor = $baseBg; $btn.ForeColor = $baseFg 
1249	        $btn.Add_Click({ try { & $this.Tag.Acao } catch { [System.Windows.Forms.MessageBox]::Show("Erro: $_") } }) 
1250	        $form.Controls.Add($lblNum); $form.Controls.Add($btn) 
1251	    } 
1252	 
1253	    # Botões 13 e 14 (Modais) 
1254	    $modalDrag = { if ($_.Button -eq [System.Windows.Forms.MouseButtons]::Left) { $global:modalOffset = New-Object System.Drawing.Point($_.X, $_.Y) } } 
1255	 
1256	    $lblNum13 = New-Object System.Windows.Forms.Label; $lblNum13.Text = "13"; $lblNum13.Font = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Bold); $lblNum13.ForeColor = [System.Drawing.Color]::FromArgb(120, 135, 155); $lblNum13.AutoSize = $true; $lblNum13.Location = New-Object System.Drawing.Point(24, 352); $form.Controls.Add($lblNum13) 
1257	 
1258	    $btnOpenStoresModal = New-Object System.Windows.Forms.Button 
1259	    $btnOpenStoresModal.Text = "Lojas de Jogos" 
1260	    $btnOpenStoresModal.Size = New-Object System.Drawing.Size(316, 38) 
1261	    $btnOpenStoresModal.Location = New-Object System.Drawing.Point(48, 342) 
1262	    $btnOpenStoresModal.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat; $btnOpenStoresModal.FlatAppearance.BorderSize = 0 
1263	    $btnOpenStoresModal.BackColor = [System.Drawing.Color]::FromArgb(40, 44, 55); $btnOpenStoresModal.ForeColor = [System.Drawing.Color]::FromArgb(0, 200, 255) 
1264	    $btnOpenStoresModal.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9.5); $btnOpenStoresModal.Cursor = [System.Windows.Forms.Cursors]::Hand 
1265	    $btnOpenStoresModal.Add_MouseEnter({ $this.BackColor = [System.Drawing.Color]::FromArgb(55, 60, 75); $this.ForeColor = [System.Drawing.Color]::White }) 
1266	    $btnOpenStoresModal.Add_MouseLeave({ $this.BackColor = [System.Drawing.Color]::FromArgb(40, 44, 55); $this.ForeColor = [System.Drawing.Color]::FromArgb(0, 200, 255) }) 
1267	    $btnOpenStoresModal.Add_Click({ 
1268	        $modal = New-Object System.Windows.Forms.Form; $modal.ClientSize = New-Object System.Drawing.Size(460, 300); $modal.StartPosition = "CenterParent"; $modal.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None; $modal.BackColor = [System.Drawing.Color]::FromArgb(28, 30, 38); $modal.ForeColor = [System.Drawing.Color]::FromArgb(230, 230, 230) 
1269	        $modal.Add_MouseDown($modalDrag) 
1270	        $modal.Add_MouseMove({ if ($_.Button -eq [System.Windows.Forms.MouseButtons]::Left -and $global:modalOffset) { $cur = [System.Windows.Forms.Cursor]::Position; $modal.Location = New-Object System.Drawing.Point(($cur.X - $global:modalOffset.X), ($cur.Y - $global:modalOffset.Y)) } }) 
1271	        $btnCM = New-Object System.Windows.Forms.Button; $btnCM.Text = "✕"; $btnCM.Size = New-Object System.Drawing.Size(40, 30); $btnCM.Location = New-Object System.Drawing.Point(420, 0); $btnCM.FlatStyle = "Flat"; $btnCM.FlatAppearance.BorderSize = 0; $btnCM.Add_Click({ $modal.Close() }); $modal.Controls.Add($btnCM) 
1272	        $lblMT = New-Object System.Windows.Forms.Label; $lblMT.Text = "SELECIONE AS LOJAS PARA INSTALAÇÃO:"; $lblMT.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold); $lblMT.ForeColor = [System.Drawing.Color]::FromArgb(100, 180, 255); $lblMT.AutoSize = $true; $lblMT.Location = New-Object System.Drawing.Point(15, 15); $modal.Controls.Add($lblMT) 
1273	        $storeItems = [ordered]@{ "Steam" = "Valve.Steam"; "Epic Games Store" = "EpicGames.EpicGamesLauncher"; "GOG Galaxy" = "GOG.Galaxy"; "EA App" = "ElectronicArts.EAApp"; "Ubisoft Connect" = "Ubisoft.Connect"; "Battle.net" = "Blizzard.BattleNet" } 
1274	        $checkBoxes = @(); $idx = 0 
1275	        foreach ($sn in $storeItems.Keys) { 
1276	            $idx++; $colI = ($idx - 1) % 2; $rowI = [Math]::Floor(($idx - 1) / 2) 
1277	            $chk = New-Object System.Windows.Forms.CheckBox; $chk.Text = $sn; $chk.ForeColor = [System.Drawing.Color]::White; $chk.Size = New-Object System.Drawing.Size(195, 30); $chk.Location = New-Object System.Drawing.Point((25 + ($colI * 215)), (65 + ($rowI * 40))); $chk.Tag = $storeItems[$sn] 
1278	            $checkBoxes += $chk; $modal.Controls.Add($chk) 
1279	        } 
1280	        $chkAll = New-Object System.Windows.Forms.CheckBox; $chkAll.Text = "Marcar / Desmarcar Todos"; $chkAll.AutoSize = $true; $chkAll.Location = New-Object System.Drawing.Point(250, 205); $chkAll.ForeColor = [System.Drawing.Color]::FromArgb(180, 190, 200); $chkAll.Add_CheckedChanged({ foreach ($c in $checkBoxes) { $c.Checked = $this.Checked } }); $modal.Controls.Add($chkAll) 
1281	        $btnOk = New-Object System.Windows.Forms.Button; $btnOk.Text = "Instalar Selecionadas"; $btnOk.Size = New-Object System.Drawing.Size(400, 42); $btnOk.Location = New-Object System.Drawing.Point(30, 240); $btnOk.FlatStyle = "Flat"; $btnOk.FlatAppearance.BorderSize = 0; $btnOk.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215); $btnOk.ForeColor = [System.Drawing.Color]::White 
1282	        $btnOk.Add_Click({ 
1283	            $sel = @($checkBoxes | Where-Object { $_.Checked }) 
1284	            if ($sel.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show("Nenhuma loja selecionada!"); return } 
1285	            $passos = @(); $i = 0; foreach ($c in $sel) { $i++; $passos += Passo $i $sel.Count "$($c.Text)" (W "$($c.Tag)") } 
1286	            $modal.Close(); Start-Task "Launchers ($($sel.Count) lojas)" (Lote $passos) -total $sel.Count 
1287	        }) 
1288	        $modal.Controls.Add($btnOk); [void]$modal.ShowDialog($form); $modal.Dispose() 
1289	    }) 
1290	    $form.Controls.Add($btnOpenStoresModal) 
1291	 
1292	    $lblNum14 = New-Object System.Windows.Forms.Label; $lblNum14.Text = "14"; $lblNum14.Font = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Bold); $lblNum14.ForeColor = [System.Drawing.Color]::FromArgb(120, 135, 155); $lblNum14.AutoSize = $true; $lblNum14.Location = New-Object System.Drawing.Point(388, 352); $form.Controls.Add($lblNum14) 
1293	 
1294	    $btnWhatToDo = New-Object System.Windows.Forms.Button 
1295	    $btnWhatToDo.Text = "O que deseja fazer no PC?  (Instalação Personalizada Total)" 
1296	    $btnWhatToDo.Size = New-Object System.Drawing.Size(680, 38) 
1297	    $btnWhatToDo.Location = New-Object System.Drawing.Point(412, 342) 
1298	    $btnWhatToDo.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat; $btnWhatToDo.FlatAppearance.BorderSize = 0 
1299	    $btnWhatToDo.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215); $btnWhatToDo.ForeColor = [System.Drawing.Color]::White 
1300	    $btnWhatToDo.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9.5); $btnWhatToDo.Cursor = [System.Windows.Forms.Cursors]::Hand 
1301	    $btnWhatToDo.Add_MouseEnter({ $this.BackColor = [System.Drawing.Color]::FromArgb(20, 140, 240) }) 
1302	    $btnWhatToDo.Add_MouseLeave({ $this.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215) }) 
1303	    $btnWhatToDo.Add_Click({ 
1304	        $modalPC = New-Object System.Windows.Forms.Form; $modalPC.ClientSize = New-Object System.Drawing.Size(460, 530); $modalPC.StartPosition = "CenterParent"; $modalPC.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None; $modalPC.BackColor = [System.Drawing.Color]::FromArgb(28, 30, 38); $modalPC.ForeColor = [System.Drawing.Color]::FromArgb(230, 230, 230) 
1305	        $modalPC.Add_MouseDown($modalDrag) 
1306	        $modalPC.Add_MouseMove({ if ($_.Button -eq [System.Windows.Forms.MouseButtons]::Left -and $global:modalOffset) { $cur = [System.Windows.Forms.Cursor]::Position; $modalPC.Location = New-Object System.Drawing.Point(($cur.X - $global:modalOffset.X), ($cur.Y - $global:modalOffset.Y)) } }) 
1307	        $btnCMPC = New-Object System.Windows.Forms.Button; $btnCMPC.Text = "✕"; $btnCMPC.Size = New-Object System.Drawing.Size(40, 30); $btnCMPC.Location = New-Object System.Drawing.Point(420, 0); $btnCMPC.FlatStyle = "Flat"; $btnCMPC.FlatAppearance.BorderSize = 0; $btnCMPC.Add_Click({ $modalPC.Close() }); $modalPC.Controls.Add($btnCMPC) 
1308	        $lblMTPC = New-Object System.Windows.Forms.Label; $lblMTPC.Text = "INSTALAÇÃO PERSONALIZADA TOTAL:"; $lblMTPC.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold); $lblMTPC.ForeColor = [System.Drawing.Color]::FromArgb(100, 180, 255); $lblMTPC.AutoSize = $true; $lblMTPC.Location = New-Object System.Drawing.Point(15, 15); $modalPC.Controls.Add($lblMTPC) 
1309	 
1310	        $allCustomItems = [ordered]@{ 
1311	            "Google Chrome" = (W "Google.Chrome"); "WinRAR" = (W "RARLab.WinRAR"); "MSI Afterburner" = (W "Guru3D.Afterburner") 
1312	            "Adobe Acrobat Reader" = (W "Adobe.Acrobat.Reader.64-bit"); "Microsoft Office" = "Install-OfficeDeployment" 
1313	            "Desempenho Máximo" = "Install-GamerPowerPlan"; ".NET Framework 3.5" = "Install-GamerNetFx3" 
1314	            ".NET Desktop Runtime 8" = "Install-GamerDotNet8"; "Visual C++ Redist." = "Install-GamerVCRedist" 
1315	            "DirectX Runtimes" = "Install-GamerDirectX"; "App Oficial da GPU" = "Install-GamerGPUApp" 
1316	            "Steam" = (W "Valve.Steam"); "Epic Games Store" = (W "EpicGames.EpicGamesLauncher"); "GOG Galaxy" = (W "GOG.Galaxy") 
1317	            "EA App" = (W "ElectronicArts.EAApp"); "Ubisoft Connect" = (W "Ubisoft.Connect"); "Battle.net" = (W "Blizzard.BattleNet") 
1318	            "Atualizar Windows" = "Invoke-WindowsUpdate"; "Atualizar Drivers" = "Invoke-DriverUpdate" 
1319	        } 
1320	        $checkBoxesPC = @(); $idxPC = 0 
1321	        foreach ($in in $allCustomItems.Keys) { 
1322	            $idxPC++; $colI = ($idxPC - 1) % 2; $rowI = [Math]::Floor(($idxPC - 1) / 2) 
1323	            $chkPC = New-Object System.Windows.Forms.CheckBox; $chkPC.Text = $in; $chkPC.ForeColor = [System.Drawing.Color]::White; $chkPC.Size = New-Object System.Drawing.Size(200, 28); $chkPC.Location = New-Object System.Drawing.Point((25 + ($colI * 215)), (55 + ($rowI * 36))); $chkPC.Tag = $allCustomItems[$in] 
1324	            $checkBoxesPC += $chkPC; $modalPC.Controls.Add($chkPC) 
1325	        } 
1326	        $chkAllPC = New-Object System.Windows.Forms.CheckBox; $chkAllPC.Text = "Marcar / Desmarcar Todos"; $chkAllPC.AutoSize = $true; $chkAllPC.Location = New-Object System.Drawing.Point(250, 440); $chkAllPC.ForeColor = [System.Drawing.Color]::FromArgb(180, 190, 200); $chkAllPC.Add_CheckedChanged({ foreach ($c in $checkBoxesPC) { $c.Checked = $this.Checked } }); $modalPC.Controls.Add($chkAllPC) 
1327	        $btnOkPC = New-Object System.Windows.Forms.Button; $btnOkPC.Text = "Instalar Recursos Selecionados"; $btnOkPC.Size = New-Object System.Drawing.Size(400, 42); $btnOkPC.Location = New-Object System.Drawing.Point(30, 472); $btnOkPC.FlatStyle = "Flat"; $btnOkPC.FlatAppearance.BorderSize = 0; $btnOkPC.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215); $btnOkPC.ForeColor = [System.Drawing.Color]::White 
1328	        $btnOkPC.Add_Click({ 
1329	            $sel = @($checkBoxesPC | Where-Object { $_.Checked }) 
1330	            if ($sel.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show("Nenhum item selecionado!"); return } 
1331	            $passos = @(); $i = 0; foreach ($c in $sel) { $i++; $passos += Passo $i $sel.Count "$($c.Text)" $c.Tag } 
1332	            $modalPC.Close(); Start-Task "Personalizada ($($sel.Count) itens)" (Lote $passos) -total $sel.Count 
1333	        }) 
1334	        $modalPC.Controls.Add($btnOkPC); [void]$modalPC.ShowDialog($form); $modalPC.Dispose() 
1335	    }) 
1336	    $form.Controls.Add($btnWhatToDo) 
1337	 
1338	    # Console de Tarefas Full-Width (1072px) + Barra de Rolagem Real 
1339	    $logTitle = New-Object System.Windows.Forms.Label; $logTitle.Text = "CONSOLE DE TAREFAS"; $logTitle.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold); $logTitle.ForeColor = [System.Drawing.Color]::FromArgb(100, 180, 255); $logTitle.AutoSize = $true; $logTitle.Location = New-Object System.Drawing.Point(24, 396); $form.Controls.Add($logTitle) 
1340	    $lblStatus = New-Object System.Windows.Forms.Label; $lblStatus.Text = "Aguardando ação..."; $lblStatus.Font = New-Object System.Drawing.Font("Segoe UI", 9.5); $lblStatus.ForeColor = [System.Drawing.Color]::FromArgb(180, 190, 200); $lblStatus.AutoSize = $true; $lblStatus.Location = New-Object System.Drawing.Point(210, 395); $form.Controls.Add($lblStatus) 
1341	 
1342	    $progressBarBg = New-Object System.Windows.Forms.Panel; $progressBarBg.Location = New-Object System.Drawing.Point(24, 420); $progressBarBg.Size = New-Object System.Drawing.Size(1072, 8); $progressBarBg.BackColor = [System.Drawing.Color]::FromArgb(20, 22, 28); $form.Controls.Add($progressBarBg) 
1343	    $progressBarFill = New-Object System.Windows.Forms.Panel; $progressBarFill.Location = New-Object System.Drawing.Point(0, 0); $progressBarFill.Size = New-Object System.Drawing.Size(0, 8); $progressBarFill.BackColor = [System.Drawing.Color]::FromArgb(0, 150, 240); $progressBarBg.Controls.Add($progressBarFill) 
1344	    $progressPulse = New-Object System.Windows.Forms.Panel; $progressPulse.Location = New-Object System.Drawing.Point(-150, 0); $progressPulse.Size = New-Object System.Drawing.Size(150, 8); $progressPulse.BackColor = [System.Drawing.Color]::FromArgb(110, 235, 255); $progressPulse.Visible = $false; $progressBarBg.Controls.Add($progressPulse); $progressPulse.BringToFront() 
1345	 
1346	    $global:progressMax = 100.0; $global:progressVal = 0.0; $global:progressTarget = 0.0; $global:pulsePos = -150 
1347	    function Update-CustomProgress($val) { 
1348	        $global:progressVal = [Math]::Max(0.0, [Math]::Min([double]$val, [double]$global:progressMax)) 
1349	        if ($global:progressMax -gt 0) { $progressBarFill.Width = [int](($global:progressVal / $global:progressMax) * 1072) } 
1350	    } 
1351	 
1352	    $animTimer = New-Object System.Windows.Forms.Timer; $animTimer.Interval = 35 
1353	    $animTimer.Add_Tick({ 
1354	        if ($global:tasks.Count -gt 0) { 
1355	            if ($global:progressVal -lt $global:progressTarget) { 
1356	                $step = [Math]::Max(0.002, ($global:progressTarget - $global:progressVal) * 0.015) 
1357	                $global:progressVal = [Math]::Min($global:progressTarget, $global:progressVal + $step) 
1358	                Update-CustomProgress $global:progressVal 
1359	            } 
1360	            $progressPulse.Visible = $true; $global:pulsePos += 28 
1361	            if ($global:pulsePos -gt 1072) { $global:pulsePos = -150 } 
1362	            $progressPulse.Left = $global:pulsePos 
1363	        } else { $progressPulse.Visible = $false } 
1364	    }) 
1365	    $animTimer.Start() 
1366	 
1367	    $logContainer = New-Object System.Windows.Forms.Panel; $logContainer.Location = New-Object System.Drawing.Point(24, 436); $logContainer.Size = New-Object System.Drawing.Size(1072, 184); $logContainer.BackColor = [System.Drawing.Color]::FromArgb(20, 22, 28); $form.Controls.Add($logContainer) 
1368	    $logBox = New-Object System.Windows.Forms.TextBox; $logBox.Multiline = $true; $logBox.ReadOnly = $true; $logBox.WordWrap = $true; $logBox.ScrollBars = "None"; $logBox.Location = New-Object System.Drawing.Point(10, 6); $logBox.Size = New-Object System.Drawing.Size(1036, 172); $logBox.BackColor = [System.Drawing.Color]::FromArgb(20, 22, 28); $logBox.ForeColor = [System.Drawing.Color]::FromArgb(215, 220, 230); $logBox.Font = New-Object System.Drawing.Font("Consolas", 9.5); $logBox.BorderStyle = [System.Windows.Forms.BorderStyle]::None; $logContainer.Controls.Add($logBox) 
1369	 
1370	    $customScrollBg = New-Object System.Windows.Forms.Panel; $customScrollBg.Location = New-Object System.Drawing.Point(1054, 0); $customScrollBg.Size = New-Object System.Drawing.Size(18, 184); $customScrollBg.BackColor = [System.Drawing.Color]::FromArgb(26, 30, 40); $customScrollBg.Cursor = [System.Windows.Forms.Cursors]::Hand; $logContainer.Controls.Add($customScrollBg) 
1371	    $customScrollThumb = New-Object System.Windows.Forms.Panel; $customScrollThumb.Location = New-Object System.Drawing.Point(3, 2); $customScrollThumb.Size = New-Object System.Drawing.Size(12, 180); $customScrollThumb.BackColor = [System.Drawing.Color]::FromArgb(75, 85, 105); $customScrollThumb.Cursor = [System.Windows.Forms.Cursors]::Hand; $customScrollBg.Controls.Add($customScrollThumb) 
1372	 
1373	    $global:scrollDragging = $false; $global:scrollDragOffsetY = 0 
1374	    function Get-LogVisibleLines { return [Math]::Max(1, [int][Math]::Floor($logBox.ClientSize.Height / [Math]::Max(14, $logBox.Font.Height))) } 
1375	    function Update-CustomScroll { 
1376	        if (-not $logBox.IsHandleCreated) { return } 
1377	        $totalLines = [int][WinAPI.Desktop]::SendMessage($logBox.Handle, 0x00BA, [IntPtr]::Zero, [IntPtr]::Zero) 
1378	        $firstVisible = [int][WinAPI.Desktop]::SendMessage($logBox.Handle, 0x00CE, [IntPtr]::Zero, [IntPtr]::Zero) 
1379	        $visibleLines = Get-LogVisibleLines; $trackHeight = $customScrollBg.Height - 4 
1380	        if ($totalLines -le $visibleLines) { $customScrollThumb.Height = $trackHeight; $customScrollThumb.Top = 2; return } 
1381	        $thumbHeight = [Math]::Max(26, [int](($visibleLines / $totalLines) * $trackHeight)); $customScrollThumb.Height = $thumbHeight 
1382	        $ratio = [Math]::Max(0.0, [Math]::Min(1.0, $firstVisible / [Math]::Max(1, $totalLines - $visibleLines))) 
1383	        $customScrollThumb.Top = 2 + [int]($ratio * ($trackHeight - $thumbHeight)) 
1384	    } 
1385	    function Set-LogScrollByThumbTop([int]$desiredTop) { 
1386	        if (-not $logBox.IsHandleCreated) { return } 
1387	        $totalLines = [int][WinAPI.Desktop]::SendMessage($logBox.Handle, 0x00BA, [IntPtr]::Zero, [IntPtr]::Zero) 
1388	        $firstVisible = [int][WinAPI.Desktop]::SendMessage($logBox.Handle, 0x00CE, [IntPtr]::Zero, [IntPtr]::Zero) 
1389	        $visibleLines = Get-LogVisibleLines; if ($totalLines -le $visibleLines) { return } 
1390	        $maxThumbTop = [Math]::Max(1, ($customScrollBg.Height - 4) - $customScrollThumb.Height) 
1391	        $clampedTop = [Math]::Max(2, [Math]::Min(2 + $maxThumbTop, $desiredTop)); $customScrollThumb.Top = $clampedTop 
1392	        $targetLine = [int][Math]::Round((($clampedTop - 2) / $maxThumbTop) * ($totalLines - $visibleLines)) 
1393	        $delta = $targetLine - $firstVisible 
1394	        if ($delta -ne 0) { [void][WinAPI.Desktop]::SendMessage($logBox.Handle, 0x00B6, [IntPtr]::Zero, [IntPtr]$delta) } 
1395	    } 
1396	    $logBox.Add_MouseWheel({ param($s, $e) [void][WinAPI.Desktop]::SendMessage($logBox.Handle, 0x00B6, [IntPtr]::Zero, [IntPtr](if ($e.Delta -gt 0) { -3 } else { 3 })); Update-CustomScroll }) 
1397	    $logBox.Add_KeyUp({ Update-CustomScroll }); $logBox.Add_TextChanged({ Update-CustomScroll }) 
1398	    $customScrollThumb.Add_MouseDown({ param($s, $e) if ($e.Button -eq "Left") { $global:scrollDragging = $true; $global:scrollDragOffsetY = $e.Y } }) 
1399	    $customScrollThumb.Add_MouseMove({ if ($global:scrollDragging) { Set-LogScrollByThumbTop (($customScrollBg.PointToClient([System.Windows.Forms.Cursor]::Position)).Y - $global:scrollDragOffsetY) } }) 
1400	    $customScrollThumb.Add_MouseUp({ $global:scrollDragging = $false }) 
1401	    $customScrollBg.Add_MouseDown({ param($s, $e) if ($e.Button -eq "Left") { Set-LogScrollByThumbTop ($e.Y - [int]($customScrollThumb.Height / 2)) } }) 
1402	 
1403	    $timer = New-Object System.Windows.Forms.Timer; $timer.Interval = 800 
1404	    function Ler-Novas($t) { 
1405	        if (-not (Test-Path $t.Out)) { return } 
1406	        $linhas = @(Get-Content $t.Out -ErrorAction SilentlyContinue) 
1407	        for ($k = $t.Lido; $k -lt $linhas.Count; $k++) { 
1408	            $l = "$($linhas[$k])".Trim() 
1409	            if ($l -match '^##AGORA \[(\d+)/(\d+)\] (.+)$') { 
1410	                Log ("  > Instalando agora: " + $matches[3] + " (" + $matches[1] + "/" + $matches[2] + ")") 
1411	                $lblStatus.Text = "Instalando agora: " + $matches[3] + " (" + $matches[1] + "/" + $matches[2] + ")" 
1412	                $atual = [double]$matches[1]; $totalEtapas = [double]$matches[2] 
1413	                if ($totalEtapas -gt 1) { 
1414	                    $global:progressMax = $totalEtapas 
1415	                    $baseVal = [Math]::Max(0.2, $atual - 0.85) 
1416	                    if ($baseVal -gt $global:progressVal) { $global:progressVal = $baseVal } 
1417	                    $global:progressTarget = [Math]::Min($totalEtapas - 0.08, $atual - 0.05) 
1418	                    Update-CustomProgress $global:progressVal 
1419	                } 
1420	            } 
1421	            elseif ($l -match '^##OK (.+)$')   { $t.Ok++;   Log ("  [OK]   " + $matches[1] + " instalado") } 
1422	            elseif ($l -match '^##JA (.+)$')   { $t.Ja++;   Log ("  [JA]   " + $matches[1] + " ja estava instalado") } 
1423	            elseif ($l -match '^##ERRO (.+)$') { $t.Erro++; Log ("  [ERRO] " + $matches[1]) } 
1424	            elseif ($l -match '^##INFO (.+)$') { Log ("         " + $matches[1]) } 
1425	        } 
1426	        $t.Lido = $linhas.Count 
1427	    } 
1428	    $timer.Add_Tick({ 
1429	        foreach ($t in @($global:tasks)) { 
1430	            Ler-Novas $t 
1431	            if ($t.Proc.HasExited) { 
1432	                Start-Sleep -Milliseconds 200; Ler-Novas $t 
1433	                Log ("=== Fim: " + $t.Nome + " | instalados: " + $t.Ok + " | ja tinha: " + $t.Ja + " | erros: " + $t.Erro + " ===") 
1434	                Remove-Item -LiteralPath $t.Worker -Force -ErrorAction SilentlyContinue 
1435	                $global:tasks.Remove($t) 
1436	                if ($global:tasks.Count -gt 0) { $lblStatus.Text = "Em andamento: " + $global:tasks[0].Nome + " (" + $global:tasks.Count + " na fila)" } 
1437	                else { 
1438	                    $progressPulse.Visible = $false; $global:progressTarget = $global:progressMax; Update-CustomProgress $global:progressMax 
1439	                    if ($t.Erro -gt 0) { $lblStatus.Text = "Concluido com erros - veja o log"; $lblStatus.ForeColor = [System.Drawing.Color]::FromArgb(255, 90, 90); $progressBarFill.BackColor = [System.Drawing.Color]::FromArgb(220, 65, 75) } 
1440	                    else { $lblStatus.Text = "Concluido com sucesso!"; $lblStatus.ForeColor = [System.Drawing.Color]::FromArgb(0, 255, 160); $progressBarFill.BackColor = [System.Drawing.Color]::FromArgb(0, 210, 130) } 
1441	                    if ($chkReiniciar.Checked) { 
1442	                        Log "Reiniciar ao concluir marcado: o computador vai reiniciar em 60 segundos..." 
1443	                        shutdown.exe /r /t 60 /c "Assistente de Formatacao: tarefas concluidas. Reiniciando em 60 segundos." | Out-Null 
1444	                        $resp = [System.Windows.Forms.MessageBox]::Show("Todas as tarefas terminaram.`n`nO computador vai reiniciar em 60 segundos.`n`nOK = Reiniciar agora`nCancelar = NAO reiniciar", "Reiniciar o computador", [System.Windows.Forms.MessageBoxButtons]::OKCancel, [System.Windows.Forms.MessageBoxIcon]::Warning) 
1445	                        if ($resp -eq [System.Windows.Forms.DialogResult]::Cancel) { shutdown.exe /a | Out-Null; Log "Reinicio cancelado pelo usuario." } 
1446	                        else { shutdown.exe /a | Out-Null; shutdown.exe /r /t 0 | Out-Null; $form.Close() } 
1447	                    } 
1448	                    if ($chkSair.Checked) { Log "Sair ao concluir marcado: fechando a ferramenta..."; $form.Close() } 
1449	                } 
1450	            } 
1451	        } 
1452	    }) 
1453	    $timer.Start() 
1454	 
1455	    # Rodapé 
1456	    $sair = New-Object System.Windows.Forms.Button; $sair.Text = "Encerrar Ferramenta"; $sair.Size = New-Object System.Drawing.Size(170, 38); $sair.Location = New-Object System.Drawing.Point(24, 634); $sair.FlatStyle = "Flat"; $sair.FlatAppearance.BorderSize = 0; $sair.BackColor = [System.Drawing.Color]::FromArgb(180, 50, 60); $sair.ForeColor = [System.Drawing.Color]::White; $sair.Cursor = "Hand"; $sair.Add_Click({ $form.Close() }); $form.Controls.Add($sair) 
1457	    $chkSair = New-Object System.Windows.Forms.CheckBox; $chkSair.Text = "Sair ao concluir"; $chkSair.AutoSize = $true; $chkSair.Location = New-Object System.Drawing.Point(210, 655); $chkSair.ForeColor = [System.Drawing.Color]::FromArgb(200, 205, 215); $chkSair.Cursor = "Hand"; $form.Controls.Add($chkSair) 
1458	    $chkReiniciar = New-Object System.Windows.Forms.CheckBox; $chkReiniciar.Text = "Reiniciar ao concluir"; $chkReiniciar.AutoSize = $true; $chkReiniciar.Location = New-Object System.Drawing.Point(210, 633); $chkReiniciar.ForeColor = [System.Drawing.Color]::FromArgb(255, 190, 90); $chkReiniciar.Cursor = "Hand"; $form.Controls.Add($chkReiniciar) 
1459	    $watermark = New-Object System.Windows.Forms.Label; $watermark.Text = "Desenvolvido por: Elson (Criatividade E Tudo)"; $watermark.Font = New-Object System.Drawing.Font("Segoe UI", 8.5); $watermark.ForeColor = [System.Drawing.Color]::FromArgb(100, 110, 120); $watermark.AutoSize = $true; $watermark.Location = New-Object System.Drawing.Point(435, 645); $form.Controls.Add($watermark) 
1460	    $versaoLabel = New-Object System.Windows.Forms.Label; $versaoLabel.Text = $VersaoAtual; $versaoLabel.Font = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Bold); $versaoLabel.ForeColor = [System.Drawing.Color]::FromArgb(0, 180, 255); $versaoLabel.AutoSize = $true; $versaoLabel.Location = New-Object System.Drawing.Point(1055, 645); $form.Controls.Add($versaoLabel) 
1461	 
1462	    $form.Show(); Update-CustomScroll 
1463	    [System.Windows.Forms.Application]::Run($form) 
1464	    $netTimer.Stop(); $netTimer.Dispose(); $animTimer.Stop(); $animTimer.Dispose(); $timer.Stop(); $timer.Dispose(); $form.Dispose() 
1465	 
1466	} else { 
1467	    # ----------------------------------------------------------------- 
1468	    # MODO 2: TERMINAL LITE (CLI NUMÉRICO — ZERO WINDOWS FORMS) 
1469	    # ----------------------------------------------------------------- 
1470	    Invoke-Expression $appInstallHelpers 
1471	 
1472	    function Invoke-TaskBatchCLI { 
1473	        param([string]$Titulo, [array]$Passos) 
1474	        Write-Host "" 
1475	        Write-Host "========================================================================" -ForegroundColor Cyan 
1476	        Write-Host "  INICIANDO: $Titulo" -ForegroundColor White 
1477	        Write-Host "========================================================================" -ForegroundColor Cyan 
1478	 
1479	        $ok = 0; $ja = 0; $erro = 0; $total = $Passos.Count; $i = 0 
1480	        foreach ($p in $Passos) { 
1481	            $i++ 
1482	            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [$i/$total] Processando: $($p.Nome)..." -ForegroundColor Yellow 
1483	            $global:LASTEXITCODE = 0 
1484	            try { & $p.Cmd } catch { $global:LASTEXITCODE = 1 } 
1485	            $c = $global:LASTEXITCODE 
1486	            if ($c -eq 0) { $ok++; Write-Host "[$(Get-Date -Format 'HH:mm:ss')]   [OK]   $($p.Nome) concluido!" -ForegroundColor Green } 
1487	            elseif ($c -eq -1978335189) { $ja++; Write-Host "[$(Get-Date -Format 'HH:mm:ss')]   [JA]   $($p.Nome) ja estava instalado." -ForegroundColor Cyan } 
1488	            else { $erro++; Write-Host "[$(Get-Date -Format 'HH:mm:ss')]   [ERRO] $($p.Nome) falhou (codigo $c)." -ForegroundColor Red } 
1489	        } 
1490	        Write-Host "------------------------------------------------------------------------" -ForegroundColor DarkGray 
1491	        Write-Host "  RESUMO ($Titulo): Instalados: $ok | Ja tinha: $ja | Erros: $erro" -ForegroundColor White 
1492	        Write-Host "========================================================================" -ForegroundColor Cyan 
1493	        if ($global:ReiniciarAoConcluir) { 
1494	            shutdown.exe /r /t 60 /c "Assistente de Formatacao: tarefas concluidas. Reiniciando em 60 segundos." | Out-Null 
1495	            Write-Host "`nREINICIAR AO CONCLUIR: o computador vai reiniciar em 60 segundos!" -ForegroundColor Yellow 
1496	            $rr = (Read-Host "Digite C e ENTER para CANCELAR, ou apenas ENTER para reiniciar agora").Trim() 
1497	            if ($rr -match '^(?i)c') { shutdown.exe /a | Out-Null; Write-Host "Reinicio cancelado." -ForegroundColor Green; Start-Sleep -Seconds 2 } 
1498	            else { shutdown.exe /a | Out-Null; shutdown.exe /r /t 0 | Out-Null; exit } 
1499	        } 
1500	        if ($global:SairAoConcluir) { Write-Host "`nSair ao concluir ativado: fechando a ferramenta em 5 segundos..." -ForegroundColor Yellow; Start-Sleep -Seconds 5; exit } 
1501	        Read-Host "`nPressione ENTER para voltar ao menu" 
1502	    } 
1503	 
1504	    function Get-NetworkLineCLI { 
1505	        try { 
1506	            $nics = [System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces() | Where-Object { 
1507	                $_.OperationalStatus -eq [System.Net.NetworkInformation.OperationalStatus]::Up -and 
1508	                $_.NetworkInterfaceType -ne [System.Net.NetworkInformation.NetworkInterfaceType]::Loopback -and 
1509	                $_.NetworkInterfaceType -ne [System.Net.NetworkInformation.NetworkInterfaceType]::Tunnel -and 
1510	                $_.Description -notmatch '(?i)Virtual|Hyper-V|VMware|VirtualBox|TAP-|VPN|Pseudo|Bluetooth' 
1511	            } 
1512	            $eth = $nics | Where-Object { $_.NetworkInterfaceType -eq [System.Net.NetworkInformation.NetworkInterfaceType]::Ethernet } | Select-Object -First 1 
1513	            $wifi = $nics | Where-Object { $_.NetworkInterfaceType -eq [System.Net.NetworkInformation.NetworkInterfaceType]::Wireless80211 } | Select-Object -First 1 
1514	            if ($eth) { 
1515	                $mbps = [Math]::Round($eth.Speed / 1000000) 
1516	                $spd = if ($mbps -ge 1000) { "$([Math]::Round($mbps / 1000, 1)) Gbps" } elseif ($mbps -gt 0) { "$mbps Mbps" } else { "Ativo" } 
1517	                return @{ Text = "CABO ETHERNET ($spd)"; Color = "Green" } 
1518	            } elseif ($wifi) { return @{ Text = "WI-FI ATIVO (Recomendado usar Cabo)"; Color = "Yellow" } } 
1519	        } catch {} 
1520	        return @{ Text = "SEM REDE / DESCONECTADO"; Color = "Red" } 
1521	    } 
1522	 
1523	    $global:SairAoConcluir = $false 
1524	    $global:ReiniciarAoConcluir = $false 
1525	    while ($true) { 
1526	        Clear-Host 
1527	        $net = Get-NetworkLineCLI 
1528	        Write-Host "========================================================================" -ForegroundColor Cyan 
1529	        Write-Host "   ASSISTENTE DE FORMATACAO LITE ($VersaoAtual - MODO CONSOLE)" -ForegroundColor White 
1530	        Write-Host "   Desenvolvido por: Elson (Criatividade E Tudo)" -ForegroundColor DarkGray 
1531	        Write-Host "========================================================================" -ForegroundColor Cyan 
1532	        Write-Host "   Status da Rede: " -NoNewline -ForegroundColor Gray; Write-Host $net.Text -ForegroundColor $net.Color 
1533	        Write-Host "------------------------------------------------------------------------" -ForegroundColor DarkGray 
1534	        Write-Host "   ACOES INDIVIDUAIS:" -ForegroundColor Cyan 
1535	        Write-Host "   [01] Ativacao Windows             [04] Instalar MSI Afterburner" -ForegroundColor White 
1536	        Write-Host "   [02] Instalar Google Chrome       [05] Instalar Adobe Reader" -ForegroundColor White 
1537	        Write-Host "   [03] Instalar WinRAR              [06] Instalar Apenas o Office" -ForegroundColor White 
1538	        Write-Host "" 
1539	        Write-Host "   PACOTES & MANUTENCAO:" -ForegroundColor Cyan 
1540	        Write-Host "   [07] Kit Gamer (Runtimes + GPU)   [10] INSTALAR TUDO + Office" -ForegroundColor Green 
1541	        Write-Host "   [08] TUDO (Sem MSI e sem Office)  [11] Atualizar Windows" -ForegroundColor White 
1542	        Write-Host "   [09] INSTALAR TUDO (Sem MSI)      [12] Atualizar Drivers" -ForegroundColor White 
1543	        Write-Host "" 
1544	        Write-Host "   PERSONALIZADOS:" -ForegroundColor Cyan 
1545	        Write-Host "   [13] Lojas de Jogos (Steam, Epic, GOG, EA, Ubisoft, Battle.net)" -ForegroundColor Yellow 
1546	        Write-Host "   [14] Instalacao Personalizada Total (Escolher itens por numero)" -ForegroundColor Yellow 
1547	        Write-Host "------------------------------------------------------------------------" -ForegroundColor DarkGray 
1548	        $estadoSair = if ($global:SairAoConcluir) { "[X] LIGADO" } else { "[ ] DESLIGADO" } 
1549	        Write-Host "   [99] Sair ao concluir: $estadoSair" -ForegroundColor $(if ($global:SairAoConcluir) { "Green" } else { "DarkGray" }) 
1550	        $estadoRein = if ($global:ReiniciarAoConcluir) { "[X] LIGADO" } else { "[ ] DESLIGADO" } 
1551	        Write-Host "   [98] Reiniciar ao concluir: $estadoRein" -ForegroundColor $(if ($global:ReiniciarAoConcluir) { "Yellow" } else { "DarkGray" }) 
1552	        Write-Host "   [00] Encerrar Ferramenta" -ForegroundColor Red 
1553	        Write-Host "========================================================================" -ForegroundColor Cyan 
1554	        $op = (Read-Host "`nDigite o numero da opcao desejada e pressione ENTER").Trim() 
1555	 
1556	        switch -Regex ($op) { 
1557	            '^0?1$' { powershell.exe -Command ("irm https://get.activated.win | iex")} 
1558	            '^0?2$' { Invoke-TaskBatchCLI "Google Chrome" @(@{ Nome = "Google Chrome"; Cmd = { Install-AppFallback -Id "Google.Chrome" } }) } 
1559	            '^0?3$' { Invoke-TaskBatchCLI "WinRAR" @(@{ Nome = "WinRAR"; Cmd = { Install-AppFallback -Id "RARLab.WinRAR" } }) } 
1560	            '^0?4$' { Invoke-TaskBatchCLI "MSI Afterburner" @(@{ Nome = "MSI Afterburner"; Cmd = { Install-AppFallback -Id "Guru3D.Afterburner" } }) } 
1561	            '^0?5$' { Invoke-TaskBatchCLI "Adobe Acrobat Reader" @(@{ Nome = "Adobe Reader"; Cmd = { Install-AppFallback -Id "Adobe.Acrobat.Reader.64-bit" } }) } 
1562	            '^0?6$' { Invoke-TaskBatchCLI "Microsoft Office" @(@{ Nome = "Microsoft Office + Atalhos"; Cmd = { Install-OfficeDeployment } }) } 
1563	            '^0?7$' { 
1564	                Invoke-TaskBatchCLI "Kit Gamer Completo" @( 
1565	                    @{ Nome = "Plano Desempenho Maximo"; Cmd = { Install-GamerPowerPlan } }, 
1566	                    @{ Nome = ".NET Framework 3.5"; Cmd = { Install-GamerNetFx3 } }, 
1567	                    @{ Nome = ".NET Desktop Runtime 8"; Cmd = { Install-GamerDotNet8 } }, 
1568	                    @{ Nome = "Visual C++ Redistributable"; Cmd = { Install-GamerVCRedist } }, 
1569	                    @{ Nome = "DirectX Runtimes"; Cmd = { Install-GamerDirectX } }, 
1570	                    @{ Nome = "Aplicativo Oficial da GPU"; Cmd = { Install-GamerGPUApp } } 
1571	                ) 
1572	            } 
1573	            '^0?8$' { 
1574	                Invoke-TaskBatchCLI "TUDO (Sem MSI e sem Office)" @( 
1575	                    @{ Nome = "Google Chrome"; Cmd = { Install-AppFallback -Id "Google.Chrome" } }, 
1576	                    @{ Nome = "Adobe Reader"; Cmd = { Install-AppFallback -Id "Adobe.Acrobat.Reader.64-bit" } }, 
1577	                    @{ Nome = "WinRAR"; Cmd = { Install-AppFallback -Id "RARLab.WinRAR" } } 
1578	                ) 
1579	            } 
1580	            '^0?9$' { 
1581	                Invoke-TaskBatchCLI "INSTALAR TUDO (Sem MSI)" @( 
1582	                    @{ Nome = "Google Chrome"; Cmd = { Install-AppFallback -Id "Google.Chrome" } }, 
1583	                    @{ Nome = "Adobe Reader"; Cmd = { Install-AppFallback -Id "Adobe.Acrobat.Reader.64-bit" } }, 
1584	                    @{ Nome = "WinRAR"; Cmd = { Install-AppFallback -Id "RARLab.WinRAR" } }, 
1585	                    @{ Nome = "Microsoft Office + Atalhos"; Cmd = { Install-OfficeDeployment } } 
1586	                ) 
1587	            } 
1588	            '^10$' { 
1589	                Invoke-TaskBatchCLI "INSTALAR TUDO + Office" @( 
1590	                    @{ Nome = "Google Chrome"; Cmd = { Install-AppFallback -Id "Google.Chrome" } }, 
1591	                    @{ Nome = "Adobe Reader"; Cmd = { Install-AppFallback -Id "Adobe.Acrobat.Reader.64-bit" } }, 
1592	                    @{ Nome = "WinRAR"; Cmd = { Install-AppFallback -Id "RARLab.WinRAR" } }, 
1593	                    @{ Nome = "MSI Afterburner"; Cmd = { Install-AppFallback -Id "Guru3D.Afterburner" } }, 
1594	                    @{ Nome = "Microsoft Office + Atalhos"; Cmd = { Install-OfficeDeployment } } 
1595	                ) 
1596	            } 
1597	            '^11$' { Invoke-TaskBatchCLI "Atualizar Windows" @(@{ Nome = "Windows Update"; Cmd = { Invoke-WindowsUpdate } }) } 
1598	            '^12$' { Invoke-TaskBatchCLI "Atualizar Drivers" @(@{ Nome = "Drivers Update"; Cmd = { Invoke-DriverUpdate } }) } 
1599	            '^13$' { 
1600	                Clear-Host 
1601	                $lojas = @( 
1602	                    @{ Num = 1; Nome = "Steam"; Id = "Valve.Steam" }, @{ Num = 2; Nome = "Epic Games Store"; Id = "EpicGames.EpicGamesLauncher" }, 
1603	                    @{ Num = 3; Nome = "GOG Galaxy"; Id = "GOG.Galaxy" }, @{ Num = 4; Nome = "EA App"; Id = "ElectronicArts.EAApp" }, 
1604	                    @{ Num = 5; Nome = "Ubisoft Connect"; Id = "Ubisoft.Connect" }, @{ Num = 6; Nome = "Battle.net"; Id = "Blizzard.BattleNet" } 
1605	                ) 
1606	                Write-Host "========================================================================" -ForegroundColor Cyan 
1607	                Write-Host "   LOJAS DE JOGOS ($VersaoAtual) - SEPARE OS NUMEROS POR VIRGULA OU ESPACO" -ForegroundColor White 
1608	                Write-Host "========================================================================" -ForegroundColor Cyan 
1609	                foreach ($l in $lojas) { Write-Host ("   [{0}] {1}" -f $l.Num, $l.Nome) -ForegroundColor White } 
1610	                Write-Host "   [T] Todas as Lojas   |   [0] Voltar" -ForegroundColor Yellow 
1611	                $sel = (Read-Host "`nEscolha (ex: 1, 2, 6)").Trim() 
1612	                if ($sel -ne '0' -and $sel -ne '') { 
1613	                    $fila = @() 
1614	                    if ($sel -match '^(?i)T$') { 
1615	                        foreach ($l in $lojas) { $idC = $l.Id; $fila += @{ Nome = $l.Nome; Cmd = { Install-AppFallback -Id $idC }.GetNewClosure() } } 
1616	                    } else { 
1617	                        foreach ($n in ($sel -split '[,\s;]+' | Where-Object { $_ -match '^\d+$' } | Select-Object -Unique)) { 
1618	                            $it = $lojas | Where-Object { $_.Num -eq [int]$n } | Select-Object -First 1 
1619	                            if ($it) { $idC = $it.Id; $fila += @{ Nome = $it.Nome; Cmd = { Install-AppFallback -Id $idC }.GetNewClosure() } } 
1620	                        } 
1621	                    } 
1622	                    if ($fila.Count -gt 0) { Invoke-TaskBatchCLI "Lojas de Jogos ($($fila.Count))" $fila } 
1623	                } 
1624	            } 
1625	            '^14$' { 
1626	                Clear-Host 
1627	                $itensPers = @( 
1628	                    @{ Num = 1;  Nome = "Google Chrome"; Cmd = { Install-AppFallback -Id "Google.Chrome" } }, 
1629	                    @{ Num = 2;  Nome = "WinRAR"; Cmd = { Install-AppFallback -Id "RARLab.WinRAR" } }, 
1630	                    @{ Num = 3;  Nome = "MSI Afterburner"; Cmd = { Install-AppFallback -Id "Guru3D.Afterburner" } }, 
1631	                    @{ Num = 4;  Nome = "Adobe Acrobat Reader"; Cmd = { Install-AppFallback -Id "Adobe.Acrobat.Reader.64-bit" } }, 
1632	                    @{ Num = 5;  Nome = "Microsoft Office"; Cmd = { Install-OfficeDeployment } }, 
1633	                    @{ Num = 6;  Nome = "Desempenho Maximo"; Cmd = { Install-GamerPowerPlan } }, 
1634	                    @{ Num = 7;  Nome = ".NET Framework 3.5"; Cmd = { Install-GamerNetFx3 } }, 
1635	                    @{ Num = 8;  Nome = ".NET Desktop Runtime 8"; Cmd = { Install-GamerDotNet8 } }, 
1636	                    @{ Num = 9;  Nome = "Visual C++ Redist."; Cmd = { Install-GamerVCRedist } }, 
1637	                    @{ Num = 10; Nome = "DirectX Runtimes"; Cmd = { Install-GamerDirectX } }, 
1638	                    @{ Num = 11; Nome = "App Oficial da GPU"; Cmd = { Install-GamerGPUApp } }, 
1639	                    @{ Num = 12; Nome = "Steam"; Cmd = { Install-AppFallback -Id "Valve.Steam" } }, 
1640	                    @{ Num = 13; Nome = "Epic Games Store"; Cmd = { Install-AppFallback -Id "EpicGames.EpicGamesLauncher" } }, 
1641	                    @{ Num = 14; Nome = "GOG Galaxy"; Cmd = { Install-AppFallback -Id "GOG.Galaxy" } }, 
1642	                    @{ Num = 15; Nome = "EA App"; Cmd = { Install-AppFallback -Id "ElectronicArts.EAApp" } }, 
1643	                    @{ Num = 16; Nome = "Ubisoft Connect"; Cmd = { Install-AppFallback -Id "Ubisoft.Connect" } }, 
1644	                    @{ Num = 17; Nome = "Battle.net"; Cmd = { Install-AppFallback -Id "Blizzard.BattleNet" } }, 
1645	                    @{ Num = 18; Nome = "Atualizar Windows"; Cmd = { Invoke-WindowsUpdate } }, 
1646	                    @{ Num = 19; Nome = "Atualizar Drivers"; Cmd = { Invoke-DriverUpdate } } 
1647	                ) 
1648	                Write-Host "========================================================================" -ForegroundColor Cyan 
1649	                Write-Host "   INSTALACAO PERSONALIZADA TOTAL ($VersaoAtual)" -ForegroundColor White 
1650	                Write-Host "========================================================================" -ForegroundColor Cyan 
1651	                for ($idx = 0; $idx -lt 10; $idx++) { 
1652	                    $leftStr = ("[{0:D2}] {1}" -f $itensPers[$idx].Num, $itensPers[$idx].Nome).PadRight(36) 
1653	                    $rightStr = if (($idx + 10) -lt $itensPers.Count) { "[{0:D2}] {1}" -f $itensPers[$idx + 10].Num, $itensPers[$idx + 10].Nome } else { "" } 
1654	                    Write-Host "   $leftStr $rightStr" -ForegroundColor White 
1655	                } 
1656	                Write-Host "   [00] Voltar ao Menu Principal" -ForegroundColor Red 
1657	                $selPC = (Read-Host "`nDigite os numeros desejados (ex: 1 2 4 5)").Trim() 
1658	                if ($selPC -ne '0' -and $selPC -ne '00' -and $selPC -ne '') { 
1659	                    $filaP = @() 
1660	                    foreach ($n in ($selPC -split '[,\s;]+' | Where-Object { $_ -match '^\d+$' } | Select-Object -Unique)) { 
1661	                        $it = $itensPers | Where-Object { $_.Num -eq [int]$n } | Select-Object -First 1 
1662	                        if ($it) { $filaP += @{ Nome = $it.Nome; Cmd = $it.Cmd } } 
1663	                    } 
1664	                    if ($filaP.Count -gt 0) { Invoke-TaskBatchCLI "Personalizada ($($filaP.Count) itens)" $filaP } 
1665	                } 
1666	            } 
1667	            '^98$' { $global:ReiniciarAoConcluir = -not $global:ReiniciarAoConcluir } 
1668	            '^99$' { $global:SairAoConcluir = -not $global:SairAoConcluir } 
1669	            '^0?0$' { exit } 
1670	            default { Write-Host "Opcao invalida!" -ForegroundColor Red; Start-Sleep -Seconds 1 } 
1671	        } 
1672	    } 
1673	} 
1674	#PSEND