#!/usr/bin/env bash
# =============================================================================
# dont-spoil-me — Jellyfin Plugin Build & Install Script
# =============================================================================
# Supports bare metal and Docker Jellyfin installs.
# Run once — builds, installs, and restarts Jellyfin automatically.
#
# Usage:
#   bash build.sh
# =============================================================================
set -euo pipefail
export DOTNET_CLI_TELEMETRY_OPTOUT=1

PLUGIN_NAME="dont-spoil-me"
ASSEMBLY="Jellyfin.Plugin.DontSpoilMe"
VERSION="1.1.2.0"
GUID="b2c3d4e5-f6a7-8901-bcde-f12345678901"
BUILD_DIR="/tmp/dontspoilme_build"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DIST_DIR="${SCRIPT_DIR}/dist"
TMP_DLL_DIR="/tmp/dontspoilme_dlls"

echo "🙈 dont-spoil-me build script"
echo "=============================="

# =============================================================================
# STEP 1 — Find or install dotnet 9
# =============================================================================
find_dotnet() {
    for candidate in \
        "$(which dotnet 2>/dev/null || true)" \
        "/usr/bin/dotnet" \
        "/usr/local/bin/dotnet" \
        "/usr/lib64/dotnet/dotnet" \
        "$HOME/.dotnet/dotnet"; do
        if [ -x "$candidate" ]; then
            local ver
            ver=$("$candidate" --version 2>/dev/null | cut -d. -f1 || echo "0")
            if [ "${ver:-0}" -ge 9 ] 2>/dev/null; then
                echo "$candidate"
                return 0
            fi
        fi
    done
    return 1
}

DOTNET=""
if DOTNET=$(find_dotnet); then
    echo "✅  Found dotnet at $DOTNET (v$("$DOTNET" --version))"
else
    echo "▶   dotnet 9 not found — installing to ~/.dotnet ..."
    curl -fsSL https://dot.net/v1/dotnet-install.sh | bash -s -- \
        --channel 9.0 \
        --install-dir "$HOME/.dotnet" \
        --no-path
    DOTNET="$HOME/.dotnet/dotnet"
    if [ ! -x "$DOTNET" ]; then
        echo "❌  dotnet install failed."
        echo "    Install manually: https://dotnet.microsoft.com/download/dotnet/9.0"
        exit 1
    fi
    echo "✅  Installed dotnet $("$DOTNET" --version)"
fi

# =============================================================================
# STEP 2 — Find Jellyfin DLLs (bare metal or Docker)
# =============================================================================
JELLYFIN_LIB=""
JELLYFIN_VERSION="10.11.0.0"
JELLYFIN_CONTAINER=""

# Check bare metal first
for candidate in \
    "/usr/lib64/jellyfin" \
    "/usr/lib/jellyfin" \
    "/usr/share/jellyfin" \
    "/opt/jellyfin"; do
    if [ -f "$candidate/MediaBrowser.Controller.dll" ]; then
        JELLYFIN_LIB="$candidate"
        break
    fi
done

# Fall back to Docker
if [ -z "$JELLYFIN_LIB" ]; then
    echo "▶   Bare metal Jellyfin not found — checking Docker..."

    JELLYFIN_CONTAINER=$(docker ps --format '{{.Names}}' 2>/dev/null \
        | grep -i jellyfin | head -1 || true)

    if [ -z "$JELLYFIN_CONTAINER" ]; then
        echo "❌  No running Jellyfin container found and no bare metal install detected."
        echo "    Make sure Jellyfin is running, then re-run this script."
        exit 1
    fi

    echo "✅  Found Jellyfin container: $JELLYFIN_CONTAINER"

    DLL_PATH=$(docker exec "$JELLYFIN_CONTAINER" \
        find / -name "MediaBrowser.Controller.dll" 2>/dev/null | head -1)

    if [ -z "$DLL_PATH" ]; then
        echo "❌  Could not find Jellyfin DLLs inside container $JELLYFIN_CONTAINER"
        exit 1
    fi

    CONTAINER_LIB=$(dirname "$DLL_PATH")
    echo "▶   Copying DLLs from container ($CONTAINER_LIB)..."

    rm -rf "$TMP_DLL_DIR"
    mkdir -p "$TMP_DLL_DIR"

    for dll in \
        MediaBrowser.Controller.dll \
        MediaBrowser.Common.dll \
        MediaBrowser.Model.dll \
        Jellyfin.Data.dll \
        Jellyfin.Database.Implementations.dll \
        Microsoft.AspNetCore.Authorization.dll \
        Microsoft.Extensions.Logging.Abstractions.dll \
        Microsoft.Extensions.DependencyInjection.Abstractions.dll; do
        docker cp "${JELLYFIN_CONTAINER}:${CONTAINER_LIB}/${dll}" "$TMP_DLL_DIR/" || {
            echo "❌  Failed to copy $dll from container"
            exit 1
        }
    done

    JELLYFIN_VERSION=$(strings "$TMP_DLL_DIR/MediaBrowser.Model.dll" \
        | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "10.11.0.0")

    JELLYFIN_LIB="$TMP_DLL_DIR"
    echo "✅  DLLs ready (Jellyfin $JELLYFIN_VERSION)"
fi

echo "✅  Jellyfin DLLs: $JELLYFIN_LIB"

# =============================================================================
# STEP 3 — Write source files
# =============================================================================
echo "▶   Writing source files..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"/{Configuration,Api}

cat > "$BUILD_DIR/DontSpoilMe.csproj" << CSPROJ
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net9.0</TargetFramework>
    <AssemblyName>${ASSEMBLY}</AssemblyName>
    <RootNamespace>Jellyfin.Plugin.DontSpoilMe</RootNamespace>
    <Nullable>enable</Nullable>
    <Version>1.1.2</Version>
    <Company>DiRTYMacTruCK</Company>
    <Authors>DiRTYMacTruCK</Authors>
    <CopyLocalLockFileAssemblies>false</CopyLocalLockFileAssemblies>
  </PropertyGroup>
  <ItemGroup>
    <Reference Include="MediaBrowser.Controller">
      <HintPath>${JELLYFIN_LIB}/MediaBrowser.Controller.dll</HintPath>
      <Private>false</Private>
    </Reference>
    <Reference Include="MediaBrowser.Common">
      <HintPath>${JELLYFIN_LIB}/MediaBrowser.Common.dll</HintPath>
      <Private>false</Private>
    </Reference>
    <Reference Include="MediaBrowser.Model">
      <HintPath>${JELLYFIN_LIB}/MediaBrowser.Model.dll</HintPath>
      <Private>false</Private>
    </Reference>
    <Reference Include="Jellyfin.Data">
      <HintPath>${JELLYFIN_LIB}/Jellyfin.Data.dll</HintPath>
      <Private>false</Private>
    </Reference>
    <Reference Include="Jellyfin.Database.Implementations">
      <HintPath>${JELLYFIN_LIB}/Jellyfin.Database.Implementations.dll</HintPath>
      <Private>false</Private>
    </Reference>
    <Reference Include="Microsoft.AspNetCore.Authorization">
      <HintPath>${JELLYFIN_LIB}/Microsoft.AspNetCore.Authorization.dll</HintPath>
      <Private>false</Private>
    </Reference>
    <Reference Include="Microsoft.Extensions.Logging.Abstractions">
      <HintPath>${JELLYFIN_LIB}/Microsoft.Extensions.Logging.Abstractions.dll</HintPath>
      <Private>false</Private>
    </Reference>
    <Reference Include="Microsoft.Extensions.DependencyInjection.Abstractions">
      <HintPath>${JELLYFIN_LIB}/Microsoft.Extensions.DependencyInjection.Abstractions.dll</HintPath>
      <Private>false</Private>
    </Reference>
  </ItemGroup>
  <ItemGroup>
    <EmbeddedResource Include="Configuration\configPage.html" />
  </ItemGroup>
  <ItemGroup>
    <FrameworkReference Include="Microsoft.AspNetCore.App" />
  </ItemGroup>
</Project>
CSPROJ

cat > "$BUILD_DIR/Plugin.cs" << 'CS'
using System;
using System.Collections.Generic;
using Jellyfin.Plugin.DontSpoilMe.Configuration;
using MediaBrowser.Common.Configuration;
using MediaBrowser.Common.Plugins;
using MediaBrowser.Model.Plugins;
using MediaBrowser.Model.Serialization;

namespace Jellyfin.Plugin.DontSpoilMe;

public class Plugin : BasePlugin<PluginConfiguration>, IHasWebPages
{
    public Plugin(IApplicationPaths applicationPaths, IXmlSerializer xmlSerializer)
        : base(applicationPaths, xmlSerializer)
    {
        Instance = this;
    }

    public override string Name => "dont-spoil-me";
    public override Guid Id => Guid.Parse("b2c3d4e5-f6a7-8901-bcde-f12345678901");
    public override string Description => "Replaces episode thumbnail images with the series poster to prevent spoilers.";
    public static Plugin? Instance { get; private set; }

    public IEnumerable<PluginPageInfo> GetPages()
    {
        yield return new PluginPageInfo
        {
            Name = "dont-spoil-me",
            EmbeddedResourcePath = $"{GetType().Namespace}.Configuration.configPage.html",
            EnableInMainMenu = false
        };
    }
}
CS

cat > "$BUILD_DIR/Configuration/PluginConfiguration.cs" << 'CS'
using MediaBrowser.Model.Plugins;

namespace Jellyfin.Plugin.DontSpoilMe.Configuration;

public class PluginConfiguration : BasePluginConfiguration
{
    public bool IsEnabled { get; set; } = true;
    public bool OnlyUnwatched { get; set; } = true;
}
CS

cat > "$BUILD_DIR/PluginServiceRegistrator.cs" << 'CS'
using MediaBrowser.Controller;
using MediaBrowser.Controller.Plugins;
using Microsoft.Extensions.DependencyInjection;

namespace Jellyfin.Plugin.DontSpoilMe;

public class PluginServiceRegistrator : IPluginServiceRegistrator
{
    public void RegisterServices(IServiceCollection serviceCollection, IServerApplicationHost applicationHost)
    {
        serviceCollection.AddHostedService<DontSpoilMeWatchedListener>();
    }
}
CS

cat > "$BUILD_DIR/DontSpoilMeImageProvider.cs" << 'CS'
using System.Collections.Generic;
using System.Linq;
using MediaBrowser.Controller.Entities;
using MediaBrowser.Controller.Entities.TV;
using MediaBrowser.Controller.Providers;
using MediaBrowser.Model.Entities;
using MediaBrowser.Model.IO;
using Microsoft.Extensions.Logging;

namespace Jellyfin.Plugin.DontSpoilMe;

public class DontSpoilMeImageProvider : ILocalImageProvider, IHasOrder
{
    private readonly ILogger<DontSpoilMeImageProvider> _logger;

    public DontSpoilMeImageProvider(ILogger<DontSpoilMeImageProvider> logger)
    {
        _logger = logger;
    }

    public int Order => 0;
    public string Name => "dont-spoil-me";
    public bool Supports(BaseItem item) => item is Episode;

    public IEnumerable<LocalImageInfo> GetImages(BaseItem item, IDirectoryService directoryService)
    {
        var config = Plugin.Instance?.Configuration;
        if (config is null || !config.IsEnabled)
            yield break;

        if (item is not Episode episode)
            yield break;

        if (config.OnlyUnwatched && episode.UserData != null && episode.UserData.Any(u => u.Played))
            yield break;

        var series = episode.Series;
        if (series is null)
        {
            _logger.LogDebug("dont-spoil-me: no series found for episode {Id}", episode.Id);
            yield break;
        }

        var seriesImageInfo = series.GetImageInfo(ImageType.Primary, 0);
        if (seriesImageInfo is null || string.IsNullOrEmpty(seriesImageInfo.Path))
        {
            _logger.LogDebug("dont-spoil-me: series {SeriesId} has no Primary image", series.Id);
            yield break;
        }

        _logger.LogDebug("dont-spoil-me: swapping episode {EpisodeId} thumb with series poster", episode.Id);

        yield return new LocalImageInfo
        {
            FileInfo = new FileSystemMetadata { FullName = seriesImageInfo.Path, IsDirectory = false },
            Type = ImageType.Primary
        };
    }
}
CS

cat > "$BUILD_DIR/DontSpoilMeWatchedListener.cs" << 'CS'
using System;
using System.Threading;
using System.Threading.Tasks;
using MediaBrowser.Controller.Entities.TV;
using MediaBrowser.Controller.Library;
using MediaBrowser.Model.Entities;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace Jellyfin.Plugin.DontSpoilMe;

public class DontSpoilMeWatchedListener : IHostedService
{
    private readonly IUserDataManager _userDataManager;
    private readonly ILogger<DontSpoilMeWatchedListener> _logger;

    public DontSpoilMeWatchedListener(
        IUserDataManager userDataManager,
        ILogger<DontSpoilMeWatchedListener> logger)
    {
        _userDataManager = userDataManager;
        _logger = logger;
    }

    public Task StartAsync(CancellationToken cancellationToken)
    {
        _userDataManager.UserDataSaved += OnUserDataSaved;
        return Task.CompletedTask;
    }

    public Task StopAsync(CancellationToken cancellationToken)
    {
        _userDataManager.UserDataSaved -= OnUserDataSaved;
        return Task.CompletedTask;
    }

    private void OnUserDataSaved(object? sender, UserDataSaveEventArgs e)
    {
        var config = Plugin.Instance?.Configuration;
        if (config is null || !config.IsEnabled || !config.OnlyUnwatched)
            return;

        if (e.Item is not Episode episode)
            return;

        if (!e.UserData.Played)
            return;

        _logger.LogInformation("dont-spoil-me: episode {Id} marked watched, removing image override", episode.Id);

        try
        {
            episode.DeleteImageAsync(ImageType.Primary, 0).GetAwaiter().GetResult();
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "dont-spoil-me: failed to delete image for episode {Id}", episode.Id);
        }
    }
}
CS

cat > "$BUILD_DIR/Api/DontSpoilMeController.cs" << 'CS'
using Jellyfin.Plugin.DontSpoilMe.Configuration;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace Jellyfin.Plugin.DontSpoilMe.Api;

[ApiController]
[Route("DontSpoilMe")]
[Authorize(Policy = "RequiresElevation")]
public class DontSpoilMeController : ControllerBase
{
    [HttpGet("Config")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    public ActionResult<PluginConfiguration> GetConfig()
        => Plugin.Instance?.Configuration ?? new PluginConfiguration();

    [HttpPost("Config")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public ActionResult SetConfig([FromBody] PluginConfiguration config)
    {
        if (Plugin.Instance is null)
            return StatusCode(StatusCodes.Status503ServiceUnavailable);
        Plugin.Instance.UpdateConfiguration(config);
        return NoContent();
    }
}
CS

cat > "$BUILD_DIR/Configuration/configPage.html" << 'HTML'
<div id="DontSpoilMeConfigPage">
    <div class="content-primary">
        <div class="verticalSection">
            <div class="sectionTitleContainer">
                <h2 class="sectionTitle">🙈 dont-spoil-me</h2>
            </div>
            <p>Shows the series poster instead of episode thumbnails to prevent spoilers.</p>
            <p><strong>Note:</strong> Jellyfin 10.11.x has a known issue where plugin config pages appear blank.
            Edit the config file directly until this is fixed by Jellyfin.
            See the README on GitHub for instructions.</p>
        </div>
    </div>
</div>
HTML

# =============================================================================
# STEP 4 — Build
# =============================================================================
echo "▶   Building..."
cd "$BUILD_DIR"
"$DOTNET" publish DontSpoilMe.csproj --configuration Release --output ./dist 2>&1

if [ ! -f "./dist/${ASSEMBLY}.dll" ]; then
    echo "❌  Build failed — DLL not found in dist/"
    exit 1
fi
echo "✅  Build succeeded"

# =============================================================================
# STEP 5 — Package into distributable zip
# =============================================================================
echo "▶   Packaging..."
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

ZIPFILE="${DIST_DIR}/${PLUGIN_NAME}_${VERSION}.zip"
mkdir -p /tmp/dontspoilme_pkg
cp "./dist/${ASSEMBLY}.dll" /tmp/dontspoilme_pkg/
cd /tmp/dontspoilme_pkg
zip "$ZIPFILE" "${ASSEMBLY}.dll"
rm -rf /tmp/dontspoilme_pkg

CHECKSUM=$(md5sum "$ZIPFILE" | awk '{print $1}')
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

cat > "${DIST_DIR}/manifest.json" << MANIFEST
[
  {
    "guid": "${GUID}",
    "name": "dont-spoil-me",
    "description": "Replaces episode thumbnail images with the series poster to prevent spoilers.",
    "overview": "Hides spoiler thumbnails for unwatched TV episodes by showing the series poster instead.",
    "owner": "DiRTYMacTruCK",
    "category": "General",
    "versions": [
      {
        "version": "${VERSION}",
        "changelog": "Auto-create default config file on install. Note Jellyfin 10.11.x config page issue.",
        "targetAbi": "${JELLYFIN_VERSION}",
        "sourceUrl": "https://github.com/DiRTYMacTruCK/dont-spoil-me/releases/download/v1.1.2/${PLUGIN_NAME}_${VERSION}.zip",
        "checksum": "${CHECKSUM}",
        "timestamp": "${TIMESTAMP}"
      }
    ]
  }
]
MANIFEST

echo "✅  Packaged: $ZIPFILE"

# =============================================================================
# STEP 6 — Install into Jellyfin
# =============================================================================
echo "▶   Installing plugin..."

write_default_config() {
    local config_file="$1"
    if [ ! -f "$config_file" ]; then
        echo "▶   Creating default config file..."
        cat > "$config_file" << 'XMLEOF'
<?xml version="1.0" encoding="utf-8"?>
<PluginConfiguration xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <IsEnabled>true</IsEnabled>
  <OnlyUnwatched>true</OnlyUnwatched>
</PluginConfiguration>
XMLEOF
        echo "✅  Default config created at $config_file"
    else
        echo "✅  Config file already exists, skipping"
    fi
}

write_meta_json() {
    local dest_dir="$1"
    cat > "${dest_dir}/meta.json" << METAEOF
{
  "category": "General",
  "changelog": "Auto-create default config file on install.",
  "description": "Replaces episode thumbnail images with the series poster to prevent spoilers.",
  "guid": "${GUID}",
  "name": "dont-spoil-me",
  "overview": "Hides spoiler thumbnails for unwatched TV episodes by showing the series poster instead.",
  "owner": "DiRTYMacTruCK",
  "targetAbi": "${JELLYFIN_VERSION}",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%S.0000000Z")",
  "version": "${VERSION}",
  "status": "Active",
  "autoUpdate": false,
  "assemblies": []
}
METAEOF
    echo "✅  meta.json written"
}

# Try bare metal install
if [ -d "/var/lib/jellyfin" ]; then
    DEST="/var/lib/jellyfin/plugins/DontSpoilMe"
    sudo mkdir -p "$DEST"
    sudo cp "${BUILD_DIR}/dist/${ASSEMBLY}.dll" "$DEST/"
    sudo bash -c "$(declare -f write_meta_json); GUID='${GUID}' JELLYFIN_VERSION='${JELLYFIN_VERSION}' VERSION='${VERSION}' write_meta_json '$DEST'"
    sudo chown -R jellyfin:jellyfin "$DEST"
    CONFIG_FILE="/var/lib/jellyfin/plugins/configurations/${ASSEMBLY}.xml"
    sudo bash -c "$(declare -f write_default_config); write_default_config '$CONFIG_FILE'"
    sudo chown jellyfin:jellyfin "$CONFIG_FILE" 2>/dev/null || true
    echo "✅  Installed to $DEST"
    echo "▶   Restarting Jellyfin..."
    sudo systemctl restart jellyfin

# Try Docker install
elif [ -n "$JELLYFIN_CONTAINER" ]; then
    CONFIG_DIR=$(docker inspect "$JELLYFIN_CONTAINER" \
        | python3 -c "
import sys, json
mounts = json.load(sys.stdin)[0]['Mounts']
for m in mounts:
    if m['Destination'] == '/config':
        print(m['Source'])
        break
" 2>/dev/null || true)

    if [ -z "$CONFIG_DIR" ]; then
        echo "⚠️  Could not determine config volume. Copy manually:"
        echo "    Unzip $ZIPFILE into your Jellyfin plugins folder"
    else
        DEST="${CONFIG_DIR}/plugins/DontSpoilMe"
        if [ ! -w "${CONFIG_DIR}/plugins" ]; then
            echo "▶   Fixing plugins folder ownership..."
            sudo chown -R "$(whoami):$(whoami)" "${CONFIG_DIR}/plugins"
        fi
        mkdir -p "$DEST"
        cp "${BUILD_DIR}/dist/${ASSEMBLY}.dll" "$DEST/"
        write_meta_json "$DEST"
        write_default_config "${CONFIG_DIR}/plugins/configurations/${ASSEMBLY}.xml"
        echo "✅  Installed to $DEST"
        echo "▶   Restarting Jellyfin container..."
        docker restart "$JELLYFIN_CONTAINER"
    fi
else
    echo "⚠️  Could not auto-install. Manual install:"
    echo "    Unzip $ZIPFILE into your Jellyfin plugins folder and restart Jellyfin"
fi

# Cleanup
rm -rf "$TMP_DLL_DIR"

echo ""
echo "🙈 Done!"
