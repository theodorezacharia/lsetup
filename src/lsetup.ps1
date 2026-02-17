<#
Author: Theodore Zacharia
V0.1 - 19/07/2022 - Initial Release of Windows PowerShell version, from V0.2 Bourne shell version
V0.2 - 16/06/2023 - Change top level structure in cfg file to an array form
V0.5 - 17/02/2026 - Major update to use modern PS facilities and logic, but deviates a lot from the bash version

Execute instructions in the json config file
Config files are in order of preference: Machine name specific, o/s specific, default.

NO LONGER MANDATORY: This script used to use the excellent 'jq' utility,
        but the recent (2026) changes now use Windows internal features
        so no longer need js on the Windows platform

WINDOWS SPECIFIC:
You might need to do the following in an Admin Powershell script:
    Set-ExecutionPolicy Unrestricted
    or to avoid prompts each time you try to run
    Set-ExecutionPolicy Bypass -Scope CurrentUser
#>
param (
    [Parameter(Position = 0)]
    [string]$Service,

    [Parameter(Position = 1)]
    [string]$Type,

    # This captures EVERYTHING else after Service and Type into an array
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$ExtraArgs,    

    [Alias("c")]
    [string]$ConfigForce,

    [Alias("f")]
    [switch]$ForceIt,

    [Alias("t")]
    [switch]$Trace,

    [Alias("d")]
    [switch]$NoAutoConfig,

    [Alias("h")]
    [switch]$Help
)

if ( $TRACE ) {
    Write-Host "DEBUG: Service is [$Service]" -ForegroundColor Magenta
    Write-Host "DEBUG: Type is [$Type]" -ForegroundColor Magenta
    Write-Host "DEBUG: Remaining Args: $($ExtraArgs -join ', ')" -ForegroundColor Magenta
}

<# Globals #>
$LSETUPCFG='lsetup.cfg'    # the default lsetup config file
$MNTFILTR=""
$FINDCONFIGFILE=1
$LSETUPCFGFORCE=""
$POSARGSTART=0

# --- Functions ---
function Get-LSetupConfig {
    param($ForcedPath, $AutoLookup)

    # 1. If user forced a file via -c
    if ($ForcedPath) { return $ForcedPath }

    # 2. If Auto-lookup is disabled via -d
    $defaultFile = "lsetup.cfg"
    if (-not $AutoLookup) { return $defaultFile }

    # 3. Priority list: Machine > OS > Default
    $targets = @(
        "lsetup.$($env:COMPUTERNAME).cfg",
        "lsetup.$($env:OS).cfg",
        $defaultFile
    )

    foreach ($file in $targets) {
        if (Test-Path $file) { return $file }
    }

    return $defaultFile
}

# --- Mainline ---
<# Mainline #>

$LSETUPCFG = Get-LSetupConfig -ForcedPath $ConfigForce -AutoLookup (-not $NoAutoConfig)

if ($TRACE) {
    write-host "trace is on ($trace)"
    write-host "Starting at $(get-date -Format F)"
    write-host "Using config LSETUPCFG=$LSETUPCFG" -ForegroundColor Cyan
}

# Load data once
$Data = Get-Content -Raw $LSETUPCFG | ConvertFrom-Json
$MYARG1=$Service
$MYARG2=$Type

if ( $TRACE ) { write-host "MYARG1=${MYARG1} , MYARG2=${MYARG2}" }

if ([string]::IsNullOrWhiteSpace($MYARG2)) {
    # Only match if the JSON type is ALSO null or empty
    $TRUN = $Data | Where-Object { $_.service -eq $MYARG1 -and [string]::IsNullOrEmpty($_.type) }
} else {
    $TRUN = $Data | Where-Object { $_.service -eq $MYARG1 -and $_.type -eq $MYARG2 }
}

if ( $TRACE ) { $TRUN.steps | Out-String }

if ($null -ne $TRUN) {
    if ($TRACE) { Write-Host "Executing steps for $($TRUN.service)..." -ForegroundColor Cyan }
    
    foreach ($step in $TRUN.steps) {
        # Skip comments or empty lines
        if ($step.StartsWith("#") -or [string]::IsNullOrWhiteSpace($step)) { continue }
        if ( $TRACE ) { Write-Host "Running: $step" -ForegroundColor Gray }
        try {
            # Invoke-Expression runs the string as a PowerShell command
            Invoke-Expression $step
        } catch {
            Write-Error "Failed to execute step: $step. Error: $_"
        }
    }
}

