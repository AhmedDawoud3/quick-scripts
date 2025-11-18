# Quick Scripts Manager

A lightweight PowerShell script manager for running quick terminal utilities with a simple command interface.

## Overview

Instead of memorizing complex commands or searching through scripts, use a single entry point `s` to access all your utilities:

```powershell
s compress video.mp4
s <future-command> <args>
```

## Installation

1. Clone this repository:
   ```powershell
   git clone https://github.com/AhmedDawoud3/quick-scripts.git c:\quick-scripts
   ```

2. Add the following to your PowerShell profile (`$PROFILE`):
   ```powershell
   # Script Manager (s) - Quick terminal scripts
   function s {
       param(
           [Parameter(Position=0)]
           [string]$Subcommand,
           
           [Parameter(Position=1, ValueFromRemainingArguments=$true)]
           [string[]]$Arguments
       )
       
       & "c:\quick-scripts\s.ps1" $Subcommand @Arguments
   }

   # Tab completion for s function
   Register-ArgumentCompleter -CommandName 's' -ParameterName 'Subcommand' -ScriptBlock {
       param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
       
       $ScriptsPath = "c:\quick-scripts\scripts"
       
       if (Test-Path $ScriptsPath) {
           Get-ChildItem -Path $ScriptsPath -Filter "*.ps1" | 
               Where-Object { $_.BaseName -like "$wordToComplete*" } |
               ForEach-Object {
                   [System.Management.Automation.CompletionResult]::new(
                       $_.BaseName,
                       $_.BaseName,
                       'ParameterValue',
                       $_.BaseName
                   )
               }
       }
   }
   ```

3. Reload your profile:
   ```powershell
   . $PROFILE
   ```

## Available Commands

### compress
Compress video files using ffmpeg with H.265 codec.

**Usage:**
```powershell
s compress video.mp4                    # Creates video_compressed.mp4
s compress input.mp4 output.mp4         # Custom output name
s compress --help                        # Show detailed help
```

**Features:**
- Uses H.265 (libx265) codec with CRF 28 quality
- Automatically generates output filename with `_compressed` suffix
- Copies audio without re-encoding
- Shows file size comparison and compression savings
- Validates input file and checks for ffmpeg installation

**Requirements:**
- [ffmpeg](https://ffmpeg.org/download.html) must be installed and in PATH

### ping-check
Monitor website or server uptime with continuous ping.

**Usage:**
```powershell
s ping-check google.com                 # Monitor with 5s interval
s ping-check 192.168.1.1 10             # Monitor with 10s interval
s ping-check --help                      # Show help
```

**Features:**
- Continuous monitoring with real-time status updates
- Shows response times, average ping, and uptime percentage
- Statistics summary on exit (Ctrl+C)
- Color-coded status indicators

### qr
Generate QR codes from text or URLs.

**Usage:**
```powershell
s qr "https://example.com"              # Generate from text
s qr "Hello World"                       # Generate from string
s qr                                     # Generate from clipboard
s qr --help                              # Show help
```

**Features:**
- Displays QR code directly in terminal
- Automatically uses clipboard content if no input provided
- Works with URLs, text, or any string
- Scannable with phone camera

### ip
Display IP address information.

**Usage:**
```powershell
s ip                                     # Show all IP info
s ip --public                            # Show only public IP
s ip --local                             # Show only local IPs
s ip --help                              # Show help
```

**Features:**
- Shows public IP address
- Lists all local network interfaces and their IPs
- Displays active network adapters
- Color-coded output for easy reading

## Adding New Commands

1. Create a new PowerShell script in the `scripts/` folder:
   ```powershell
   scripts/my-command.ps1
   ```

2. Your script will automatically be available:
   ```powershell
   s my-command <args>
   ```

3. Tab completion works automatically for new commands

## Project Structure

```
quick-scripts\
├── s.ps1                 # Main dispatcher script
├── scripts\
│   ├── compress.ps1      # Video compression
│   ├── ping-check.ps1    # Host monitoring
│   ├── qr.ps1            # QR code generator
│   └── ip.ps1            # IP address info
└── README.md
```

## Requirements

- Windows with PowerShell 5.1+ or PowerShell Core 7+
- Individual commands may have their own dependencies (e.g., ffmpeg for compress)

## License

MIT

## Contributing

Feel free to add your own utility scripts and submit pull requests!
