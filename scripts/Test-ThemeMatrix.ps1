param(
    [string[]]$Themes = @(
        'jekyll-theme-chirpy',
        'minimal-mistakes',
        'al-folio',
        'jekyll-TeXt-theme',
        'just-the-docs'
    ),
    [string]$Configuration = 'Release',
    [int]$PortStart = 5100,
    [int]$DebugPortStart = 9222
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$env:DOTNET_CLI_HOME = Join-Path $repoRoot '.dotnet-home'
$env:DOTNET_SKIP_FIRST_TIME_EXPERIENCE = '1'

$themeMap = @{
    'jekyll-theme-chirpy' = [pscustomobject]@{ Name = 'jekyll-theme-chirpy'; Source = (Join-Path $repoRoot 'themes\jekyll-theme-chirpy'); Destination = (Join-Path $repoRoot 'artifacts\theme-builds\jekyll-theme-chirpy') }
    'minimal-mistakes'    = [pscustomobject]@{ Name = 'minimal-mistakes'; Source = (Join-Path $repoRoot 'themes\minimal-mistakes'); Destination = (Join-Path $repoRoot 'artifacts\theme-builds\minimal-mistakes') }
    'al-folio'            = [pscustomobject]@{ Name = 'al-folio'; Source = (Join-Path $repoRoot 'themes\al-folio'); Destination = (Join-Path $repoRoot 'artifacts\theme-builds\al-folio') }
    'jekyll-TeXt-theme'   = [pscustomobject]@{ Name = 'jekyll-TeXt-theme'; Source = (Join-Path $repoRoot 'themes\jekyll-TeXt-theme'); Destination = (Join-Path $repoRoot 'artifacts\theme-builds\jekyll-TeXt-theme') }
    'just-the-docs'       = [pscustomobject]@{ Name = 'just-the-docs'; Source = (Join-Path $repoRoot 'themes\just-the-docs'); Destination = (Join-Path $repoRoot 'artifacts\theme-builds\just-the-docs') }
}

$selectedThemes = foreach ($name in $Themes) {
    if (-not $themeMap.ContainsKey($name)) {
        throw "Unknown theme '$name'."
    }

    $themeMap[$name]
}

function Get-MimeType {
    param([string]$Path)

    switch ([IO.Path]::GetExtension($Path).ToLowerInvariant()) {
        '.css' { 'text/css; charset=utf-8' }
        '.js' { 'application/javascript; charset=utf-8' }
        '.json' { 'application/json; charset=utf-8' }
        '.svg' { 'image/svg+xml' }
        '.png' { 'image/png' }
        '.jpg' { 'image/jpeg' }
        '.jpeg' { 'image/jpeg' }
        '.gif' { 'image/gif' }
        '.webp' { 'image/webp' }
        '.ico' { 'image/x-icon' }
        '.xml' { 'application/xml; charset=utf-8' }
        '.txt' { 'text/plain; charset=utf-8' }
        default { 'text/html; charset=utf-8' }
    }
}

function Start-StaticSiteServer {
    param(
        [string]$Root,
        [int]$Port
    )

    Start-Job -ArgumentList $Root, $Port -ScriptBlock {
        param($Root, $Port)

        Set-StrictMode -Version Latest
        $ErrorActionPreference = 'Stop'

        Add-Type -AssemblyName System.Web
        $listener = [System.Net.HttpListener]::new()
        $listener.Prefixes.Add("http://127.0.0.1:$Port/")
        $listener.Start()

        try {
            while ($listener.IsListening) {
                $context = $listener.GetContext()
                try {
                    $relativePath = [System.Web.HttpUtility]::UrlDecode($context.Request.Url.AbsolutePath).TrimStart('/')
                    if ([string]::IsNullOrWhiteSpace($relativePath)) {
                        $relativePath = 'index.html'
                    }
                    else {
                        $candidateDirectory = Join-Path $Root ($relativePath -replace '/', [IO.Path]::DirectorySeparatorChar)
                        if (Test-Path -LiteralPath $candidateDirectory -PathType Container) {
                            $relativePath = [IO.Path]::Combine($relativePath, 'index.html')
                        }
                    }

                    $targetPath = Join-Path $Root ($relativePath -replace '/', [IO.Path]::DirectorySeparatorChar)
                    if (-not (Test-Path -LiteralPath $targetPath -PathType Leaf)) {
                        $notFoundPath = Join-Path $Root '404.html'
                        if (Test-Path -LiteralPath $notFoundPath -PathType Leaf) {
                            $context.Response.StatusCode = 404
                            $targetPath = $notFoundPath
                        }
                        else {
                            $context.Response.StatusCode = 404
                            $buffer = [Text.Encoding]::UTF8.GetBytes('Not Found')
                            $context.Response.ContentType = 'text/plain; charset=utf-8'
                            $context.Response.OutputStream.Write($buffer, 0, $buffer.Length)
                            $context.Response.Close()
                            continue
                        }
                    }

                    $bytes = [IO.File]::ReadAllBytes($targetPath)
                    $context.Response.ContentType = switch ([IO.Path]::GetExtension($targetPath).ToLowerInvariant()) {
                        '.css' { 'text/css; charset=utf-8' }
                        '.js' { 'application/javascript; charset=utf-8' }
                        '.json' { 'application/json; charset=utf-8' }
                        '.svg' { 'image/svg+xml' }
                        '.png' { 'image/png' }
                        '.jpg' { 'image/jpeg' }
                        '.jpeg' { 'image/jpeg' }
                        '.gif' { 'image/gif' }
                        '.webp' { 'image/webp' }
                        '.ico' { 'image/x-icon' }
                        '.xml' { 'application/xml; charset=utf-8' }
                        '.txt' { 'text/plain; charset=utf-8' }
                        default { 'text/html; charset=utf-8' }
                    }
                    $context.Response.OutputStream.Write($bytes, 0, $bytes.Length)
                    $context.Response.Close()
                }
                catch {
                    try { $context.Response.StatusCode = 500; $context.Response.Close() } catch {}
                }
            }
        }
        finally {
            $listener.Stop()
            $listener.Close()
        }
    }
}

function Read-CdpMessage {
    param(
        [System.Net.WebSockets.ClientWebSocket]$Socket,
        [int]$TimeoutMs = 1000
    )

    $buffer = New-Object byte[] 16384
    $segment = [ArraySegment[byte]]::new($buffer)
    $stream = New-Object IO.MemoryStream
    $timeout = [System.Threading.CancellationTokenSource]::new($TimeoutMs)

    try {
        do {
            $result = $Socket.ReceiveAsync($segment, $timeout.Token).GetAwaiter().GetResult()
            if ($result.MessageType -eq [System.Net.WebSockets.WebSocketMessageType]::Close) {
                return $null
            }

            $stream.Write($buffer, 0, $result.Count)
        }
        while (-not $result.EndOfMessage)
    }
    catch [System.OperationCanceledException] {
        return $null
    }
    finally {
        $timeout.Dispose()
    }

    return [Text.Encoding]::UTF8.GetString($stream.ToArray())
}

function Send-CdpCommand {
    param(
        [System.Net.WebSockets.ClientWebSocket]$Socket,
        [int]$Id,
        [string]$Method,
        [hashtable]$Params = @{}
    )

    $payload = @{ id = $Id; method = $Method }
    if ($Params.Count -gt 0) {
        $payload.params = $Params
    }

    $json = $payload | ConvertTo-Json -Compress -Depth 10
    $bytes = [Text.Encoding]::UTF8.GetBytes($json)
    $segment = [ArraySegment[byte]]::new($bytes)
    $Socket.SendAsync($segment, [System.Net.WebSockets.WebSocketMessageType]::Text, $true, [System.Threading.CancellationToken]::None).GetAwaiter().GetResult() | Out-Null
}

function Invoke-BrowserCheck {
    param(
        [string]$Name,
        [string]$Url,
        [int]$DebugPort
    )

    $edgeCandidates = @(
        'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe',
        'C:\Program Files\Microsoft\Edge\Application\msedge.exe'
    )
    $edgePath = $edgeCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
    if (-not $edgePath) {
        throw 'Microsoft Edge was not found.'
    }

    $arguments = @(
        '--headless=new',
        '--disable-gpu',
        '--no-first-run',
        '--no-default-browser-check',
        "--remote-debugging-port=$DebugPort",
        'about:blank'
    )

    $process = Start-Process -FilePath $edgePath -ArgumentList $arguments -PassThru -WindowStyle Hidden
    try {
        $targets = $null
        for ($attempt = 0; $attempt -lt 50; $attempt++) {
            try {
                $targets = Invoke-RestMethod -Uri "http://127.0.0.1:$DebugPort/json/list" -TimeoutSec 2
                if ($targets) { break }
            }
            catch {}

            Start-Sleep -Milliseconds 200
        }

        if (-not $targets) {
            throw "DevTools endpoint for $Name did not become ready."
        }

        $page = $targets | Where-Object { $_.type -eq 'page' } | Select-Object -First 1
        if (-not $page.webSocketDebuggerUrl) {
            throw "A debuggable page was not available for $Name."
        }

        $socket = [System.Net.WebSockets.ClientWebSocket]::new()
        try {
            $socket.ConnectAsync([Uri]$page.webSocketDebuggerUrl, [System.Threading.CancellationToken]::None).GetAwaiter().GetResult()

            $id = 1
            Send-CdpCommand -Socket $socket -Id $id -Method 'Runtime.enable'; $id++
            Send-CdpCommand -Socket $socket -Id $id -Method 'Page.enable'; $id++
            Send-CdpCommand -Socket $socket -Id $id -Method 'Log.enable'; $id++
            Send-CdpCommand -Socket $socket -Id $id -Method 'Network.enable'; $id++
            Send-CdpCommand -Socket $socket -Id $id -Method 'Page.navigate' -Params @{ url = $Url }; $id++

            $errors = New-Object System.Collections.Generic.List[string]
            $loaded = $false
            $deadline = [DateTime]::UtcNow.AddSeconds(20)
            $quietUntil = [DateTime]::UtcNow.AddSeconds(2)

            while ([DateTime]::UtcNow -lt $deadline) {
                $message = Read-CdpMessage -Socket $socket -TimeoutMs 500
                if (-not $message) {
                    if ($loaded -and [DateTime]::UtcNow -ge $quietUntil) {
                        break
                    }

                    continue
                }

                $payload = $message | ConvertFrom-Json
                if (-not $payload.method) {
                    continue
                }

                switch ($payload.method) {
                    'Page.loadEventFired' {
                        $loaded = $true
                        $quietUntil = [DateTime]::UtcNow.AddSeconds(2)
                    }
                    'Runtime.exceptionThrown' {
                        $description = $payload.params.exceptionDetails.exception.description
                        if (-not $description) {
                            $description = $payload.params.exceptionDetails.text
                        }
                        $errors.Add("Runtime exception: $description")
                        $quietUntil = [DateTime]::UtcNow.AddSeconds(2)
                    }
                    'Runtime.consoleAPICalled' {
                        if ($payload.params.type -in @('error', 'assert')) {
                            $values = @($payload.params.args | ForEach-Object { $_.value }) | Where-Object { $_ }
                            $errors.Add("Console $($payload.params.type): $($values -join ' ')")
                            $quietUntil = [DateTime]::UtcNow.AddSeconds(2)
                        }
                    }
                    'Log.entryAdded' {
                        if ($payload.params.entry.level -eq 'error') {
                            $errors.Add("Log error: $($payload.params.entry.text)")
                            $quietUntil = [DateTime]::UtcNow.AddSeconds(2)
                        }
                    }
                    'Network.loadingFailed' {
                        if (-not $payload.params.canceled) {
                            $errors.Add("Network failure: $($payload.params.errorText) ($($payload.params.requestId))")
                            $quietUntil = [DateTime]::UtcNow.AddSeconds(2)
                        }
                    }
                }
            }

            [pscustomobject]@{
                Name = $Name
                Url = $Url
                Errors = @($errors)
                Loaded = $loaded
            }
        }
        finally {
            if ($socket) {
                try { $socket.Dispose() } catch {}
            }
        }
    }
    finally {
        if ($process -and -not $process.HasExited) {
            Stop-Process -Id $process.Id -Force
        }
    }
}

$overallStopwatch = [Diagnostics.Stopwatch]::StartNew()
Write-Host "Building CLI in $Configuration..."
dotnet build (Join-Path $repoRoot 'JekyllNet.Cli\JekyllNet.Cli.csproj') -c $Configuration | Out-Host

$cliExe = Join-Path $repoRoot "JekyllNet.Cli\bin\$Configuration\net10.0\JekyllNet.Cli.exe"
if (-not (Test-Path -LiteralPath $cliExe)) {
    throw "CLI executable was not found at $cliExe"
}

Write-Host ''
Write-Host "Starting parallel theme builds..."
$buildJobs = foreach ($theme in $selectedThemes) {
    Start-Job -Name $theme.Name -ArgumentList $theme.Name, $theme.Source, $theme.Destination, $cliExe, $env:DOTNET_CLI_HOME -ScriptBlock {
        param($Name, $Source, $Destination, $CliExe, $DotnetHome)

        Set-StrictMode -Version Latest
        $ErrorActionPreference = 'Stop'
        $env:DOTNET_CLI_HOME = $DotnetHome
        $env:DOTNET_SKIP_FIRST_TIME_EXPERIENCE = '1'

        $stopwatch = [Diagnostics.Stopwatch]::StartNew()
        try {
            $output = & $CliExe build --source $Source --destination $Destination 2>&1 | Out-String
            $exitCode = $LASTEXITCODE
        }
        catch {
            $output = ($_ | Out-String)
            $exitCode = 1
        }
        finally {
            $stopwatch.Stop()
        }

        [pscustomobject]@{
            Name = $Name
            Source = $Source
            Destination = $Destination
            ExitCode = $exitCode
            Duration = $stopwatch.Elapsed
            Output = $output.TrimEnd()
        }
    }
}

$buildResults = @($buildJobs | Wait-Job | Receive-Job | Sort-Object Name)
$buildJobs | Remove-Job -Force | Out-Null

Write-Host ''
Write-Host 'Build results:'
foreach ($result in $buildResults) {
    $status = if ($result.ExitCode -eq 0) { 'OK' } else { 'FAIL' }
    Write-Host ("- {0}: {1} ({2:hh\:mm\:ss\.fff})" -f $result.Name, $status, $result.Duration)
}

$browserResults = New-Object System.Collections.Generic.List[object]
$successfulBuilds = @($buildResults | Where-Object ExitCode -eq 0)

if ($successfulBuilds.Count -gt 0) {
    Write-Host ''
    Write-Host 'Running browser checks...'

    for ($index = 0; $index -lt $successfulBuilds.Count; $index++) {
        $result = $successfulBuilds[$index]
        $port = $PortStart + $index
        $debugPort = $DebugPortStart + $index
        $serverJob = Start-StaticSiteServer -Root $result.Destination -Port $port
        try {
            Start-Sleep -Seconds 1
            $browserResults.Add((Invoke-BrowserCheck -Name $result.Name -Url "http://127.0.0.1:$port/" -DebugPort $debugPort)) | Out-Null
        }
        finally {
            if ($serverJob) {
                Stop-Job -Job $serverJob -ErrorAction SilentlyContinue | Out-Null
                Remove-Job -Job $serverJob -ErrorAction SilentlyContinue | Out-Null
            }
        }
    }
}

$overallStopwatch.Stop()
Write-Host ''
Write-Host 'Browser results:'
foreach ($result in $buildResults) {
    if ($result.ExitCode -ne 0) {
        Write-Host ("- {0}: skipped (build failed)" -f $result.Name)
        continue
    }

    $browser = $browserResults | Where-Object Name -eq $result.Name | Select-Object -First 1
    if (-not $browser) {
        Write-Host ("- {0}: no browser result" -f $result.Name)
        continue
    }

    if (-not $browser.Loaded) {
        Write-Host ("- {0}: page did not finish loading" -f $result.Name)
        continue
    }

    if ($browser.Errors.Count -eq 0) {
        Write-Host ("- {0}: no browser errors" -f $result.Name)
        continue
    }

    Write-Host ("- {0}: {1} browser error(s)" -f $result.Name, $browser.Errors.Count)
    foreach ($error in $browser.Errors) {
        Write-Host ("  * {0}" -f $error)
    }
}

Write-Host ''
Write-Host ("Total elapsed: {0:hh\:mm\:ss\.fff}" -f $overallStopwatch.Elapsed)

$failedBuilds = @($buildResults | Where-Object ExitCode -ne 0)
if ($failedBuilds.Count -gt 0) {
    Write-Host ''
    Write-Host 'Failed build logs:'
    foreach ($result in $failedBuilds) {
        Write-Host ("--- {0} ---" -f $result.Name)
        Write-Host $result.Output
    }
}
