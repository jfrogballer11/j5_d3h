<#
  Windows Wi-Fi hotspot (Windows 10 / 11).
  Shares this PC's internet connection over Wi-Fi using the built-in Mobile Hotspot.

  Usage (or just double-click hotspot.bat):
    .\hotspot.ps1 start [-Ssid NAME] [-Password PASS] [-Band 5|2.4|auto]
    .\hotspot.ps1 stop
    .\hotspot.ps1 status
    .\hotspot.ps1 clients

  Must run in Windows PowerShell 5.1 (powershell.exe), not PowerShell 7 (pwsh).
#>
param(
  [Parameter(Position = 0)][ValidateSet('start', 'stop', 'status', 'clients')][string]$Action = 'start',
  [string]$Ssid = 'J5-Hotspot',
  [string]$Password,
  [ValidateSet('5', '2.4', 'auto')][string]$Band = '5'
)
$ErrorActionPreference = 'Stop'

if ($PSVersionTable.PSEdition -eq 'Core') {
  Write-Host "Re-launching in Windows PowerShell 5.1 (needed for the hotspot API)..."
  & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $PSCommandPath @PSBoundParameters
  exit $LASTEXITCODE
}

# --- WinRT async helpers --------------------------------------------------
Add-Type -AssemblyName System.Runtime.WindowsRuntime
$asTaskGeneric = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object {
    $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and
    $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' })[0]
$asTaskAction = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object {
    $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and !$_.IsGenericMethod })[0]

function Await($op, [Type]$resultType) {
  $t = $asTaskGeneric.MakeGenericMethod($resultType).Invoke($null, @($op))
  $t.Wait(-1) | Out-Null
  $t.Result
}
function AwaitAction($op) {
  $t = $asTaskAction.Invoke($null, @($op))
  $t.Wait(-1) | Out-Null
}

[void][Windows.Networking.Connectivity.NetworkInformation, Windows.Networking.Connectivity, ContentType = WindowsRuntime]
[void][Windows.Networking.NetworkOperators.NetworkOperatorTetheringManager, Windows.Networking.NetworkOperators, ContentType = WindowsRuntime]
$ResultType = [Windows.Networking.NetworkOperators.NetworkOperatorTetheringOperationResult]

function Get-Manager {
  $connProfile = [Windows.Networking.Connectivity.NetworkInformation]::GetInternetConnectionProfile()
  if (-not $connProfile) { throw "This PC has no internet connection to share. Connect to Wi-Fi or Ethernet first." }
  [Windows.Networking.NetworkOperators.NetworkOperatorTetheringManager]::CreateFromConnectionProfile($connProfile)
}

function New-Password {
  -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 12 | ForEach-Object { [char]$_ })
}

function Start-Hotspot {
  $tm = Get-Manager
  if (-not $Password) { $Password = New-Password; Write-Host "No password given, generated one." }
  if ($Password.Length -lt 8) { throw "Password must be at least 8 characters." }

  $cfg = $tm.GetCurrentAccessPointConfiguration()
  $cfg.Ssid = $Ssid
  $cfg.Passphrase = $Password
  $bandName = 'Auto'
  try {
    $bands = [Windows.Networking.NetworkOperators.TetheringWiFiBand]
    $want = switch ($Band) { '5' { $bands::FiveGigahertz } '2.4' { $bands::TwoPointFourGigahertz } default { $bands::Auto } }
    if ($want -eq $bands::Auto -or $cfg.IsBandSupported($want)) { $cfg.Band = $want; $bandName = "$want" }
    else { Write-Host "Your Wi-Fi adapter can't host on $Band GHz, using Auto." }
  } catch { Write-Host "Band selection not supported on this Windows version, using default." }

  AwaitAction ($tm.ConfigureAccessPointAsync($cfg))

  if ($tm.TetheringOperationalState -eq 'On') { Await ($tm.StopTetheringAsync()) $ResultType | Out-Null }
  $r = Await ($tm.StartTetheringAsync()) $ResultType
  if ($r.Status -ne 'Success') {
    throw "Hotspot failed to start: $($r.Status) $($r.AdditionalErrorMessage)
Common causes: Wi-Fi is turned off, or the adapter can't share and host on the same band (try -Band 2.4 or -Band auto)."
  }

  Write-Host ""
  Write-Host "Hotspot is ON" -ForegroundColor Green
  Write-Host "  Name (SSID): $Ssid"
  Write-Host "  Password:    $Password"
  Write-Host "  Band:        $bandName"
  Write-Host ""
  Write-Host "Tip: turn off 'When no devices are connected, automatically turn off mobile hotspot'"
  Write-Host "     in Settings > Network & internet > Mobile hotspot, and keep this PC from sleeping."
}

function Stop-Hotspot {
  $tm = Get-Manager
  $r = Await ($tm.StopTetheringAsync()) $ResultType
  Write-Host "Hotspot stopped ($($r.Status))."
}

function Show-Status {
  $tm = Get-Manager
  $cfg = $tm.GetCurrentAccessPointConfiguration()
  Write-Host "Hotspot: $($tm.TetheringOperationalState)"
  Write-Host "  SSID:    $($cfg.Ssid)"
  Write-Host "  Clients: $($tm.ClientCount) / $($tm.MaxClientCount)"
}

function Show-Clients {
  $tm = Get-Manager
  $list = $tm.GetTetheringClients()
  if (-not $list -or $list.Count -eq 0) { Write-Host "No devices connected."; return }
  foreach ($c in $list) {
    $names = ($c.HostNames | ForEach-Object { $_.DisplayName }) -join ', '
    Write-Host "  $($c.MacAddress)  $names"
  }
}

switch ($Action) {
  'start'   { Start-Hotspot }
  'stop'    { Stop-Hotspot }
  'status'  { Show-Status }
  'clients' { Show-Clients }
}
