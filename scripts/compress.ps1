#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Compress video files using ffmpeg
.DESCRIPTION
    Compresses video files using H.265 (libx265) codec with CRF 28 quality
.EXAMPLE
    s compress video.mp4
    s compress input.mp4 output.mp4
#>

param(
    [Parameter(Position=0, Mandatory=$true)]
    [string]$InputFile,
    
    [Parameter(Position=1)]
    [string]$OutputFile
)

# Show help
if ($InputFile -eq "--help" -or $InputFile -eq "-h") {
    Write-Host "Compress - Video compression using ffmpeg" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Usage: s compress <input_file> [output_file]" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Arguments:" -ForegroundColor Green
    Write-Host "  input_file   - Path to the video file to compress"
    Write-Host "  output_file  - (Optional) Output file path. Defaults to <input>_compressed.ext"
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Green
    Write-Host "  s compress video.mp4"
    Write-Host "  s compress video.mp4 compressed_video.mp4"
    Write-Host ""
    Write-Host "Settings:" -ForegroundColor Green
    Write-Host "  Codec: libx265 (H.265)"
    Write-Host "  Quality: CRF 28 (lower = better quality)"
    Write-Host "  Audio: Copy without re-encoding"
    exit 0
}

# Check if ffmpeg is available
if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
    Write-Host "Error: ffmpeg is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install ffmpeg: https://ffmpeg.org/download.html" -ForegroundColor Yellow
    exit 1
}

# Resolve input file path
$InputPath = Resolve-Path $InputFile -ErrorAction SilentlyContinue
if (-not $InputPath) {
    Write-Host "Error: Input file '$InputFile' not found" -ForegroundColor Red
    exit 1
}

# Generate output filename if not provided
if (-not $OutputFile) {
    $InputDir = Split-Path $InputPath -Parent
    $InputName = [System.IO.Path]::GetFileNameWithoutExtension($InputPath)
    $InputExt = [System.IO.Path]::GetExtension($InputPath)
    $OutputFile = Join-Path $InputDir "${InputName}_compressed${InputExt}"
}

# Check if output file already exists
if (Test-Path $OutputFile) {
    $response = Read-Host "Output file '$OutputFile' already exists. Overwrite? (y/N)"
    if ($response -ne 'y' -and $response -ne 'Y') {
        Write-Host "Aborted." -ForegroundColor Yellow
        exit 0
    }
}

# Run ffmpeg compression
Write-Host "Compressing: $InputPath" -ForegroundColor Cyan
Write-Host "Output: $OutputFile" -ForegroundColor Cyan
Write-Host ""

$ffmpegArgs = @(
    "-i", $InputPath,
    "-c:v", "libx265",
    "-crf", "28",
    "-c:a", "copy",
    $OutputFile
)

& ffmpeg @ffmpegArgs

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "Compression complete!" -ForegroundColor Green
    
    # Show file sizes
    $InputSize = (Get-Item $InputPath).Length / 1MB
    $OutputSize = (Get-Item $OutputFile).Length / 1MB
    $Savings = (1 - ($OutputSize / $InputSize)) * 100
    
    Write-Host "Original: $([math]::Round($InputSize, 2)) MB" -ForegroundColor White
    Write-Host "Compressed: $([math]::Round($OutputSize, 2)) MB" -ForegroundColor White
    Write-Host "Savings: $([math]::Round($Savings, 1))%" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "Compression failed" -ForegroundColor Red
    exit 1
}
