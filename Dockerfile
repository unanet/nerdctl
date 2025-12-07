# Windows nerdctl container image
# Supports both Windows Server 2019 (ltsc2019) and 2022 (ltsc2022)
# Build with: docker build --build-arg WINDOWS_VERSION=ltsc2022 -t unanet/nerdctl:latest-ltsc2022 .

ARG WINDOWS_VERSION=ltsc2022
FROM mcr.microsoft.com/windows/servercore:${WINDOWS_VERSION}

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

ARG NERDCTL_VERSION=2.2.0

# Download and install nerdctl
RUN [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; \
    New-Item -ItemType Directory -Path 'C:\nerdctl' -Force | Out-Null; \
    Write-Host \"Downloading nerdctl $env:NERDCTL_VERSION...\"; \
    Invoke-WebRequest -Uri \"https://github.com/containerd/nerdctl/releases/download/v$env:NERDCTL_VERSION/nerdctl-$env:NERDCTL_VERSION-windows-amd64.tar.gz\" \
        -OutFile 'C:\nerdctl.tar.gz' -UseBasicParsing; \
    Write-Host 'Extracting nerdctl...'; \
    tar -xzf 'C:\nerdctl.tar.gz' -C 'C:\nerdctl'; \
    Remove-Item 'C:\nerdctl.tar.gz' -Force

# Configure nerdctl for EKS containerd
RUN New-Item -ItemType Directory -Path 'C:\ProgramData\nerdctl' -Force | Out-Null; \
    $config = \"address = `\"npipe:////./pipe/containerd-containerd`\"`nnamespace = `\"k8s.io`\"`nsnapshotter = `\"windows`\"`ncgroup_manager = `\"cgroupfs`\"\"; \
    Set-Content -Path 'C:\ProgramData\nerdctl\nerdctl.toml' -Value $config -Encoding UTF8

# Copy docker compatibility wrapper
COPY docker.cmd C:\\nerdctl\\docker.cmd

# Add nerdctl to PATH
USER ContainerAdministrator
RUN setx /M PATH \"C:\nerdctl;$env:PATH\"

ENTRYPOINT ["powershell", "-NoLogo", "-NoProfile"]
