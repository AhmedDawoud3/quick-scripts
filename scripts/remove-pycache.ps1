#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Remove Python cache folders
.DESCRIPTION
    Recursively removes __pycache__ folders and parent directories that only contain __pycache__
.EXAMPLE
    s remove-pycache
    s remove-pycache /path/to/project
#>

param(
    [Parameter(Position=0)]
    [string]$Path = "."
)

# Show help
if ($Path -eq "--help" -or $Path -eq "-h") {
    Write-Host "Remove-Pycache - Remove Python cache folders" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Usage: s remove-pycache [path]" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Arguments:" -ForegroundColor Green
    Write-Host "  path  - (Optional) Directory to search. Defaults to current directory"
    Write-Host ""
    Write-Host "Description:" -ForegroundColor Green
    Write-Host "  Recursively removes all __pycache__ folders"
    Write-Host "  Also removes parent folders that only contain __pycache__"
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Green
    Write-Host "  s remove-pycache"
    Write-Host "  s remove-pycache /path/to/project"
    Write-Host "  s remove-pycache ."
    exit 0
}

# Handle empty path
if ([string]::IsNullOrWhiteSpace($Path)) {
    $Path = "."
}

# Resolve and validate path
if (-not (Test-Path $Path)) {
    Write-Host "Error: Path '$Path' not found" -ForegroundColor Red
    exit 1
}

$TargetPath = Resolve-Path $Path
Write-Host "Searching for __pycache__ folders in: $TargetPath" -ForegroundColor Cyan
Write-Host ""

# Find all __pycache__ folders recursively
$pycacheFolders = Get-ChildItem -Path $TargetPath -Directory -Recurse -Force -Filter "__pycache__" -ErrorAction SilentlyContinue

if ($pycacheFolders.Count -eq 0) {
    Write-Host "No __pycache__ folders found" -ForegroundColor Yellow
    exit 0
}

Write-Host "Found $($pycacheFolders.Count) __pycache__ folder(s)" -ForegroundColor Green

# Store parent directories to check later
$parentDirsToCheck = @{}

# Remove __pycache__ folders
$removedCount = 0
foreach ($folder in $pycacheFolders) {
    try {
        $parentDir = Split-Path $folder.FullName -Parent
        
        Write-Host "Removing: $($folder.FullName)" -ForegroundColor White
        Remove-Item -Path $folder.FullName -Recurse -Force -ErrorAction Stop
        $removedCount++
        
        # Track parent directory for later checking
        if ($parentDir) {
            $parentDirsToCheck[$parentDir] = $true
        }
    } catch {
        Write-Host "  Failed to remove: $_" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Removed $removedCount __pycache__ folder(s)" -ForegroundColor Green

# Check and remove parent directories that are now empty or only contained __pycache__
$emptyParentsRemoved = 0
foreach ($parentDir in $parentDirsToCheck.Keys) {
    if (Test-Path $parentDir) {
        $contents = Get-ChildItem -Path $parentDir -Force -ErrorAction SilentlyContinue
        
        # If directory is empty, remove it
        if ($contents.Count -eq 0) {
            try {
                Write-Host "Removing empty parent directory: $parentDir" -ForegroundColor White
                Remove-Item -Path $parentDir -Force -ErrorAction Stop
                $emptyParentsRemoved++
            } catch {
                Write-Host "  Failed to remove: $_" -ForegroundColor Red
            }
        }
    }
}

if ($emptyParentsRemoved -gt 0) {
    Write-Host ""
    $dirText = if ($emptyParentsRemoved -eq 1) { "directory" } else { "directories" }
    Write-Host "Removed $emptyParentsRemoved empty parent $dirText" -ForegroundColor Green
}

Write-Host ""
Write-Host "Cleanup complete!" -ForegroundColor Green
