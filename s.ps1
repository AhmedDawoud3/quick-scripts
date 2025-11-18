#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Script manager - dispatcher for quick terminal scripts
.DESCRIPTION
    Runs subcommands from the scripts/ folder
.EXAMPLE
    s compress video.mp4
    s --help
#>

param(
    [Parameter(Position=0)]
    [string]$Subcommand,
    
    [Parameter(Position=1, ValueFromRemainingArguments=$true)]
    [string[]]$Arguments
)

$ScriptsPath = Join-Path $PSScriptRoot "scripts"

# Show help if no subcommand provided
if (-not $Subcommand -or $Subcommand -eq "--help" -or $Subcommand -eq "-h") {
    Write-Host "Script Manager (s) - Quick Terminal Scripts" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Usage: s <subcommand> [arguments...]" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Available subcommands:" -ForegroundColor Green
    
    if (Test-Path $ScriptsPath) {
        Get-ChildItem -Path $ScriptsPath -Filter "*.ps1" | ForEach-Object {
            $cmdName = $_.BaseName
            Write-Host "  $cmdName" -ForegroundColor White
        }
    } else {
        Write-Host "  (no subcommands found)" -ForegroundColor DarkGray
    }
    
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Green
    Write-Host "  s compress video.mp4"
    Write-Host "  s <subcommand> --help"
    exit 0
}

# Build the path to the subcommand script
$SubcommandScript = Join-Path $ScriptsPath "$Subcommand.ps1"

# Check if the subcommand exists
if (-not (Test-Path $SubcommandScript)) {
    Write-Host "Error: Unknown subcommand '$Subcommand'" -ForegroundColor Red
    Write-Host "Run 's --help' to see available subcommands" -ForegroundColor Yellow
    exit 1
}

# Execute the subcommand script with remaining arguments
try {
    & $SubcommandScript @Arguments
    exit $LASTEXITCODE
} catch {
    Write-Host "Error executing '$Subcommand': $_" -ForegroundColor Red
    exit 1
}
