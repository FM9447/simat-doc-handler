# Run backend + flutter in one command (PowerShell)
# Usage: .\run-dev.ps1 [deviceId]

param(
  [string]$Device = "chrome",
  [int]$WebPort = 3000
)

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$env:JAVA_HOME = "C:\Program Files\Java\jdk-21.0.10"
$env:Path = "$env:JAVA_HOME\bin;$env:Path"

Write-Host "Using JAVA_HOME=$env:JAVA_HOME"
Write-Host "Starting backend..."

Push-Location "$projectRoot\backend"
Start-Process -NoNewWindow -FilePath "node" -ArgumentList "server.js" -PassThru | Out-Null
Start-Sleep -Seconds 1

Write-Host "Starting flutter..."
Pop-Location
Push-Location "$projectRoot\flutter_app"

if ($Device -eq "chrome") {
  flutter run -d chrome --web-port $WebPort
} else {
  flutter run -d $Device
}

Pop-Location
