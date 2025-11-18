#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Monitor website/server uptime with continuous ping
.DESCRIPTION
    Continuously pings a host and reports connectivity status
.EXAMPLE
    s ping-check google.com
    s ping-check 192.168.1.1
#>

param(
    [Parameter(Position=0, Mandatory=$true)]
    [string]$Target,
    
    [Parameter(Position=1)]
    [int]$Interval = 5
)

# Show help
if ($Target -eq "--help" -or $Target -eq "-h") {
    Write-Host "Ping-Check - Monitor host uptime" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Usage: s ping-check <host> [interval]" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Arguments:" -ForegroundColor Green
    Write-Host "  host      - Hostname or IP address to monitor"
    Write-Host "  interval  - Seconds between pings (default: 5)"
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Green
    Write-Host "  s ping-check google.com"
    Write-Host "  s ping-check 192.168.1.1 10"
    Write-Host ""
    Write-Host "Press Ctrl+C to stop monitoring" -ForegroundColor Yellow
    exit 0
}

Write-Host "Monitoring: $Target (every $Interval seconds)" -ForegroundColor Cyan
Write-Host "Press Ctrl+C to stop" -ForegroundColor Yellow
Write-Host ""

$successCount = 0
$failureCount = 0
$totalPings = 0
$responseTimes = @()

try {
    while ($true) {
        $totalPings++
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        
        try {
            $pingResult = Test-Connection -ComputerName $Target -Count 1 -ErrorAction Stop
            
            # Get response time - handle both Latency (newer) and ResponseTime (older) properties
            $ping = if ($pingResult.Latency) { $pingResult.Latency } else { $pingResult.ResponseTime }
            
            if ($null -ne $ping) {
                $responseTimes += $ping
                $successCount++
                
                $avgResponse = ($responseTimes | Measure-Object -Average).Average
                $uptime = [math]::Round(($successCount / $totalPings) * 100, 2)
                
                Write-Host "[$timestamp] " -NoNewline -ForegroundColor DarkGray
                Write-Host "✓ UP" -NoNewline -ForegroundColor Green
                Write-Host " - Response: $ping ms | Avg: $([math]::Round($avgResponse, 2)) ms | Uptime: $uptime%" -ForegroundColor White
            } else {
                throw "No response time"
            }
        } catch {
            $failureCount++
            $uptime = [math]::Round(($successCount / $totalPings) * 100, 2)
            
            Write-Host "[$timestamp] " -NoNewline -ForegroundColor DarkGray
            Write-Host "✗ DOWN" -NoNewline -ForegroundColor Red
            Write-Host " - No response | Uptime: $uptime%" -ForegroundColor White
        }
        
        Start-Sleep -Seconds $Interval
    }
} catch {
    Write-Host ""
    Write-Host ""
    Write-Host "Monitoring stopped." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Statistics:" -ForegroundColor Cyan
    Write-Host "  Total pings: $totalPings" -ForegroundColor White
    Write-Host "  Successful: $successCount" -ForegroundColor Green
    Write-Host "  Failed: $failureCount" -ForegroundColor Red
    
    if ($responseTimes.Count -gt 0) {
        $avgResponse = ($responseTimes | Measure-Object -Average).Average
        $minResponse = ($responseTimes | Measure-Object -Minimum).Minimum
        $maxResponse = ($responseTimes | Measure-Object -Maximum).Maximum
        Write-Host "  Avg response: $([math]::Round($avgResponse, 2)) ms" -ForegroundColor White
        Write-Host "  Min response: $minResponse ms" -ForegroundColor White
        Write-Host "  Max response: $maxResponse ms" -ForegroundColor White
    }
    
    $uptime = [math]::Round(($successCount / $totalPings) * 100, 2)
    Write-Host "  Uptime: $uptime%" -ForegroundColor $(if ($uptime -ge 99) { "Green" } elseif ($uptime -ge 95) { "Yellow" } else { "Red" })
}
