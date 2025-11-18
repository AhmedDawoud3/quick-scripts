#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Display IP address information
.DESCRIPTION
    Shows local and public IP addresses with network interface details
.EXAMPLE
    s ip
    s ip --public
    s ip --local
#>

param(
    [Parameter(Position=0)]
    [string]$Mode
)

# Show help
if ($Mode -eq "--help" -or $Mode -eq "-h") {
    Write-Host "IP - Display IP address information" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Usage: s ip [option]" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Options:" -ForegroundColor Green
    Write-Host "  (none)    - Show all IP information (default)"
    Write-Host "  --public  - Show only public IP"
    Write-Host "  --local   - Show only local IPs"
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Green
    Write-Host "  s ip"
    Write-Host "  s ip --public"
    Write-Host "  s ip --local"
    exit 0
}

function Get-PublicIP {
    try {
        $ip = (Invoke-RestMethod -Uri "https://api.ipify.org?format=text" -TimeoutSec 5 -ErrorAction Stop).Trim()
        return $ip
    } catch {
        try {
            $ip = (Invoke-RestMethod -Uri "https://icanhazip.com" -TimeoutSec 5 -ErrorAction Stop).Trim()
            return $ip
        } catch {
            return $null
        }
    }
}

function Get-LocalIPs {
    $adapters = Get-NetIPAddress -AddressFamily IPv4 | 
        Where-Object { $_.IPAddress -notlike "127.*" -and $_.PrefixOrigin -eq "Dhcp" -or $_.PrefixOrigin -eq "Manual" } |
        Select-Object IPAddress, InterfaceAlias, PrefixLength
    
    return $adapters
}

# Show public IP
if ($Mode -ne "--local") {
    Write-Host "Public IP:" -ForegroundColor Cyan
    $publicIP = Get-PublicIP
    
    if ($publicIP) {
        Write-Host "  $publicIP" -ForegroundColor Green
    } else {
        Write-Host "  Unable to retrieve (check internet connection)" -ForegroundColor Red
    }
    
    Write-Host ""
}

# Show local IPs
if ($Mode -ne "--public") {
    Write-Host "Local IP Addresses:" -ForegroundColor Cyan
    
    $localIPs = Get-LocalIPs
    
    if ($localIPs) {
        foreach ($adapter in $localIPs) {
            Write-Host "  $($adapter.IPAddress)" -NoNewline -ForegroundColor Green
            Write-Host " ($($adapter.InterfaceAlias))" -ForegroundColor DarkGray
        }
    } else {
        Write-Host "  No local IP addresses found" -ForegroundColor Red
    }
    
    Write-Host ""
}

# Show additional info if no mode specified
if (-not $Mode) {
    Write-Host "Network Interfaces:" -ForegroundColor Cyan
    
    $activeAdapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
    
    foreach ($adapter in $activeAdapters) {
        $ip = (Get-NetIPAddress -InterfaceIndex $adapter.InterfaceIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue | 
               Where-Object { $_.IPAddress -notlike "127.*" }).IPAddress
        
        if ($ip) {
            Write-Host "  $($adapter.Name)" -NoNewline -ForegroundColor White
            Write-Host " - $ip" -ForegroundColor Green
        }
    }
}
