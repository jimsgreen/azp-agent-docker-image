ARG AZP_AGENT_IMAGE_VERSION=v1
ARG AZP_AGENT_BASE_IMAGE=base

ARG DISTRO=ubuntu
ARG DISTRO_VERSION=18.04
ARG DISTRO_FRIENDLY=bionic

ARG DOTNET_CURRENT_VERSION=3.0.100
ARG DOTNET_LTS_VERSION=2.1.802

FROM mcr.microsoft.com/dotnet/core/sdk:${DOTNET_CURRENT_VERSION}-${DISTRO_FRIENDLY} AS dotnet_current_official
FROM mcr.microsoft.com/dotnet/core/sdk:${DOTNET_LTS_VERSION}-${DISTRO_FRIENDLY} AS dotnet_lts_official

FROM gmaresca/azure-pipeline-agent:${DISTRO}-${DISTRO_VERSION}-${AZP_AGENT_BASE_IMAGE}-${AZP_AGENT_IMAGE_VERSION} AS dotnet

ARG DOTNET_CURRENT_VERSION=3.0.100
ARG DOTNET_LTS_VERSION=2.1.802

COPY --from=dotnet_current_official /usr/share/dotnet/sdk/${DOTNET_CURRENT_VERSION} /usr/share/dotnet/sdk/${DOTNET_CURRENT_VERSION}
COPY --from=dotnet_lts_official /usr/share/dotnet/sdk/${DOTNET_LTS_VERSION} /usr/share/dotnet/sdk/${DOTNET_LTS_VERSION}

# Install common tools
FROM dotnet AS dotnet_tools

RUN ln -s $HOME/.dotnet/tools /usr/local/bin/dotnet-tools
ENV PATH $PATH:/usr/local/bin/dotnet-tools

RUN dotnet tool install -g coverlet.console

RUN dotnet tool install -g dotnet-sqldb

RUN dotnet tool install -g dotnet-stryker

RUN dotnet tool install -g GitVersion.Tool

RUN dotnet tool install -g nbgv

ENV coverlet /usr/local/bin/dotnet-tools/coverlet
ENV dotnet-gitversion /usr/local/bin/dotnet-tools/dotnet-gitversion
ENV dotnet-sqldb /usr/local/bin/dotnet-tools/dotnet-sqldb
ENV dotnet-stryker /usr/local/bin/dotnet-tools/dotnet-stryker
ENV nbgv /usr/local/bin/dotnet-tools/nbgv

FROM dotnet_tools AS nuget

COPY dotnet/nuget.sh /usr/bin/nuget
RUN chmod +x /usr/bin/nuget

ENV nuget /usr/bin/nuget

# Cleanup
FROM nuget AS final
RUN apt-get clean && rm -rf /var/lib/apt/lists/* && rm -rf /etc/apt/sources.list.d/*
