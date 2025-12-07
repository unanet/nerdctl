# Install nerdctl - Docker-compatible CLI for containerd
# Works with existing EKS containerd without conflicts
#
# Usage:
#   ./install-nerdctl.ps1                           # Install with defaults
#   ./install-nerdctl.ps1 -Version 2.2.0            # Specify version
#   ./install-nerdctl.ps1 -InstallDir C:\nerdctl    # Custom install directory
#   ./install-nerdctl.ps1 -SkipPath                 # Skip PATH modification (for containers)

param(
    [string]$Version = $env:NERDCTL_VERSION ?? "2.2.0",
    [string]$InstallDir = "C:\Program Files\nerdctl",
    [string]$ConfigDir = "C:\ProgramData\nerdctl",
    [switch]$SkipPath,
    [switch]$SkipConfig
)

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Create installation directory
Write-Host "Creating installation directory: $InstallDir"
New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null

# Download nerdctl for Windows
$nerdctlUrl = "https://github.com/containerd/nerdctl/releases/download/v${Version}/nerdctl-${Version}-windows-amd64.tar.gz"
$tempFile = Join-Path $env:TEMP "nerdctl.tar.gz"

Write-Host "Downloading nerdctl ${Version}..."
Invoke-WebRequest -Uri $nerdctlUrl -OutFile $tempFile -UseBasicParsing

# Extract nerdctl
Write-Host "Extracting nerdctl to $InstallDir..."
tar -xzf $tempFile -C $InstallDir
Remove-Item $tempFile -Force

# Add nerdctl to PATH (unless skipped)
if (-not $SkipPath) {
    Write-Host "Adding nerdctl to PATH..."
    $currentPath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    if ($currentPath -notlike "*$InstallDir*") {
        $newPath = $currentPath + ";$InstallDir"
        [Environment]::SetEnvironmentVariable("Path", $newPath, [System.EnvironmentVariableTarget]::Machine)
        $env:Path = $newPath
    }
}

# Configure nerdctl to use EKS containerd (unless skipped)
if (-not $SkipConfig) {
    Write-Host "Configuring nerdctl for EKS containerd..."
    $nerdctlConfig = @"
address = "npipe:////./pipe/containerd-containerd"
namespace = "k8s.io"
snapshotter = "windows"
cgroup_manager = "cgroupfs"
"@

    New-Item -ItemType Directory -Path $ConfigDir -Force | Out-Null
    $nerdctlConfig | Out-File -FilePath (Join-Path $ConfigDir "nerdctl.toml") -Encoding UTF8
}

# Create docker.exe wrapper script for compatibility
Write-Host "Creating docker compatibility wrapper..."
$dockerWrapperScript = @'
@echo off
nerdctl.exe %*
'@
$dockerWrapperScript | Out-File -FilePath (Join-Path $InstallDir "docker.cmd") -Encoding ASCII

Write-Host "nerdctl installation complete!"
Write-Host "Installed to: $InstallDir"
Write-Host "You can now use 'nerdctl' or 'docker' commands"
