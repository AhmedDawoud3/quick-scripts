#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Generate QR codes from text or URLs
.DESCRIPTION
    Creates QR codes and displays them in the terminal. Uses clipboard content if no input provided.
.EXAMPLE
    s qr "https://example.com"
    s qr "Hello World"
    s qr
#>

param(
    [Parameter(Position=0, ValueFromRemainingArguments=$true)]
    [string[]]$Text
)

# Show help
if ($Text -eq "--help" -or $Text -eq "-h") {
    Write-Host "QR - Generate QR codes" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Usage: s qr [text]" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Arguments:" -ForegroundColor Green
    Write-Host "  text  - Text or URL to encode (optional, uses clipboard if omitted)"
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Green
    Write-Host "  s qr https://example.com"
    Write-Host "  s qr `"Hello World`""
    Write-Host "  s qr                        # Uses clipboard content"
    exit 0
}

# Get text from clipboard if not provided
if (-not $Text -or $Text.Count -eq 0) {
    try {
        $clipboardContent = Get-Clipboard -Raw
        if (-not $clipboardContent) {
            Write-Host "Error: No text provided and clipboard is empty" -ForegroundColor Red
            Write-Host "Usage: s qr <text> or copy text to clipboard first" -ForegroundColor Yellow
            exit 1
        }
        # Preserve newlines from clipboard
        $Text = $clipboardContent
        Write-Host "Using clipboard content..." -ForegroundColor Cyan
    } catch {
        Write-Host "Error: Could not access clipboard" -ForegroundColor Red
        exit 1
    }
} else {
    # Join arguments with spaces but preserve explicit newlines if passed
    $Text = $Text -join " "
}

Write-Host ""
Write-Host "Generating QR code for: $Text" -ForegroundColor Green
Write-Host ""

# Set console encoding to UTF-8 to display QR code properly
$previousEncoding = [Console]::OutputEncoding
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# URL encode the text
$encodedText = [System.Uri]::EscapeDataString($Text)

# Use QR code API to generate ASCII art QR code
try {
    # Try using curl if available (works better with qrenco.de)
    $curlCmd = Get-Command curl.exe -ErrorAction SilentlyContinue
    
    if ($curlCmd) {
        $qrCode = & curl.exe -s "qrenco.de/$encodedText"
        if ($LASTEXITCODE -eq 0 -and $qrCode) {
            # Output directly to preserve newlines
            $qrCode | ForEach-Object { Write-Output $_ }
            Write-Host ""
            Write-Host "Scan with your phone camera" -ForegroundColor Cyan
        } else {
            throw "curl failed"
        }
    } else {
        # Fallback: Use goqr.me API which returns an image URL
        Write-Host "QR Code URL (open in browser):" -ForegroundColor Yellow
        $qrImageUrl = "https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=$encodedText"
        Write-Host $qrImageUrl -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Opening in browser..." -ForegroundColor Yellow
        Start-Process $qrImageUrl
    }
} catch {
    Write-Host "Error: Failed to generate QR code" -ForegroundColor Red
    Write-Host "Fallback - QR Code URL:" -ForegroundColor Yellow
    $qrImageUrl = "https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=$encodedText"
    Write-Host $qrImageUrl -ForegroundColor Cyan
    exit 1
} finally {
    # Restore previous encoding
    [Console]::OutputEncoding = $previousEncoding
}
