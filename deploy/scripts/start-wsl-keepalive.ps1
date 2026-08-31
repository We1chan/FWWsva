param(
    [Parameter(Mandatory = $true)]
    [string]$Distro
)

$wslExecutable = Join-Path $env:WINDIR 'System32\wsl.exe'

& $wslExecutable -d $Distro -u root -- pgrep -f '^sleep infinity$' *> $null
if ($LASTEXITCODE -eq 0) {
    exit 0
}

$escapedWslExecutable = $wslExecutable.Replace("'", "''")
$escapedDistro = $Distro.Replace("'", "''")
$keepaliveCommand = "& '$escapedWslExecutable' -d '$escapedDistro' -u root -- sleep infinity"
$encodedCommand = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($keepaliveCommand))

$keepaliveProcess = Start-Process `
    -FilePath 'powershell.exe' `
    -ArgumentList @('-NoProfile', '-WindowStyle', 'Hidden', '-EncodedCommand', $encodedCommand) `
    -WindowStyle Hidden `
    -PassThru

Start-Sleep -Seconds 2

if ($keepaliveProcess.HasExited) {
    Write-Error "The WSL keepalive process exited immediately with code $($keepaliveProcess.ExitCode)."
    exit 1
}

exit 0
