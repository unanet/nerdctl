# Windows nerdctl Container Image

Docker-compatible CLI for containerd on Windows, pre-configured for EKS environments.

## Overview

This repository provides:
- A Windows container image with nerdctl pre-installed and configured for EKS containerd
- A PowerShell installation script for direct nerdctl installation on Windows nodes
- Multi-architecture support for Windows Server 2019 (ltsc2019) and 2022 (ltsc2022)

## Container Image

The image is published to Docker Hub: `unanet/nerdctl`

### Available Tags

| Tag | Windows Version |
|-----|-----------------|
| `latest` | Multi-arch manifest (2019 + 2022) |
| `latest-ltsc2019` | Windows Server 2019 |
| `latest-ltsc2022` | Windows Server 2022 |

### Usage

```powershell
docker run -it unanet/nerdctl:latest
```

## Installation Script

For direct installation on Windows nodes:

```powershell
# Install with defaults
./scripts/install-nerdctl.ps1

# Specify version
./scripts/install-nerdctl.ps1 -Version 2.2.0

# Custom install directory
./scripts/install-nerdctl.ps1 -InstallDir C:\nerdctl

# Skip PATH modification (for containers)
./scripts/install-nerdctl.ps1 -SkipPath
```

## Configuration

nerdctl is pre-configured to work with EKS containerd:

```toml
address = "npipe:////./pipe/containerd-containerd"
namespace = "k8s.io"
snapshotter = "windows"
cgroup_manager = "cgroupfs"
```

## Docker Compatibility

A `docker.cmd` wrapper is included, allowing you to use familiar `docker` commands that are transparently passed to nerdctl.

## Building Locally

```powershell
# Build for Windows Server 2022
docker build --build-arg WINDOWS_VERSION=ltsc2022 -t unanet/nerdctl:latest-ltsc2022 .

# Build for Windows Server 2019
docker build --build-arg WINDOWS_VERSION=ltsc2019 -t unanet/nerdctl:latest-ltsc2019 .
```

## CI/CD

GitHub Actions automatically builds and pushes images on:
- Push to `main` branch
- Tag creation (`v*`)
- Pull requests (build only, no push)
