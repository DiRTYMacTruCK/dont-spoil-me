# 🙈 dont-spoil-me — Jellyfin Plugin

Replaces episode thumbnail images with the series poster so spoiler screenshots never ruin your next watch.

- Unwatched episodes show the series poster instead of the episode thumbnail
- When you finish watching an episode the real thumbnail is automatically restored
- Works on any Jellyfin client (web, mobile, TV apps)

---

## Known Issue — Jellyfin 10.11.x Config Page

Jellyfin 10.11.x broke the plugin config page system for third-party plugins. The settings page will appear blank when clicked. This is a Jellyfin bug, not a plugin bug. The plugin itself works correctly with its default settings.

To change settings manually, edit the config file directly:

Docker:
  nano ~/docker/jellyfin/config/plugins/configurations/Jellyfin.Plugin.DontSpoilMe.xml

Bare metal Linux:
  sudo nano /var/lib/jellyfin/plugins/configurations/Jellyfin.Plugin.DontSpoilMe.xml

The config file looks like this:

  <?xml version="1.0" encoding="utf-8"?>
  <PluginConfiguration>
    <IsEnabled>true</IsEnabled>
    <OnlyUnwatched>true</OnlyUnwatched>
  </PluginConfiguration>

---

## Requirements

- Jellyfin 10.9 or newer
- Docker or bare metal Jellyfin install
- .NET 9 SDK (only needed to build, not to run)

---

## Building and Installing

  git clone https://github.com/DiRTYMacTruCK/dont-spoil-me.git
  cd dont-spoil-me
  bash build.sh

The build script handles everything automatically:
- Finds dotnet 9 and installs it to ~/.dotnet if missing
- Auto-detects Jellyfin DLLs whether bare metal or Docker
- Builds the plugin
- Installs the DLL to your Jellyfin plugins folder
- Restarts Jellyfin

---

## Manual Install

1. Download dont-spoil-me_1.1.0.0.zip from the releases page
2. Unzip it to get Jellyfin.Plugin.DontSpoilMe.dll
3. Copy the DLL into your Jellyfin plugins folder

Docker:
  mkdir -p ~/docker/jellyfin/config/plugins/DontSpoilMe
  cp Jellyfin.Plugin.DontSpoilMe.dll ~/docker/jellyfin/config/plugins/DontSpoilMe/
  docker restart jellyfin

Bare metal Linux:
  sudo mkdir -p /var/lib/jellyfin/plugins/DontSpoilMe
  sudo cp Jellyfin.Plugin.DontSpoilMe.dll /var/lib/jellyfin/plugins/DontSpoilMe/
  sudo chown -R jellyfin:jellyfin /var/lib/jellyfin/plugins/DontSpoilMe
  sudo systemctl restart jellyfin

Windows:
  Copy Jellyfin.Plugin.DontSpoilMe.dll to:
  C:\ProgramData\Jellyfin\Server\plugins\DontSpoilMe\
  Then restart the Jellyfin service.

4. Open the Jellyfin dashboard and go to Plugins to confirm dont-spoil-me is listed
5. Go to Dashboard, Scheduled Tasks, and run Refresh Metadata to apply immediately

---

## Default Settings

IsEnabled: true
  Master on/off switch

OnlyUnwatched: true
  Watched episodes show their real thumbnail, unwatched episodes show the series poster

---

## Troubleshooting

Thumbnails not changing after install:
  Run a metadata refresh from Dashboard, Scheduled Tasks, Refresh Metadata

Watched episodes still showing series poster:
  Make sure OnlyUnwatched is set to true in the config XML, then run a metadata refresh

Plugin not showing in dashboard:
  Check the DLL is in the correct folder and Jellyfin was restarted
  Docker:     docker logs jellyfin | grep -i "dont\|spoil"
  Bare metal: journalctl -u jellyfin | grep -i "dont\|spoil"
