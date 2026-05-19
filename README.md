# 🙈 dont-spoil-me — Jellyfin Plugin

Replaces episode thumbnail images with the series poster so spoiler screenshots never ruin your next watch.

- Unwatched episodes show the series poster instead of the episode thumbnail
- When you finish watching an episode the real thumbnail is automatically restored
- Works on any Jellyfin client (web, mobile, TV apps)

---

## Known Issue — Jellyfin 10.11.x Config Page

Jellyfin 10.11.x has a bug where third-party plugin config pages appear blank. The plugin works correctly with its default settings. To change settings manually edit the config file directly:

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

## Install via Jellyfin Catalog (Recommended)

This is the easiest method. Everything is automatic.

1. Open Jellyfin Dashboard
2. Go to Plugins, then Repositories
3. Click New Repository and add:
     Name: dont-spoil-me
     URL:  https://dirtymactruck.github.io/dont-spoil-me/manifest.json
4. Click Save
5. Go to Plugins, then Catalog
6. Find dont-spoil-me and click Install
7. Restart Jellyfin when prompted
8. Go to Dashboard, Scheduled Tasks, and run Refresh Metadata

---

## Install Manually

1. Download dont-spoil-me_1.1.2.0.zip from the releases page:
   https://github.com/DiRTYMacTruCK/dont-spoil-me/releases/latest

2. Unzip it to get Jellyfin.Plugin.DontSpoilMe.dll

3. Copy the DLL into your Jellyfin plugins folder:

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

4. Go to Dashboard, Scheduled Tasks, and run Refresh Metadata

---

## Build from Source

Only needed if you want to compile the plugin yourself, for example after a Jellyfin update.

Requirements: Docker or bare metal Jellyfin, internet access

  git clone https://github.com/DiRTYMacTruCK/dont-spoil-me.git
  cd dont-spoil-me
  bash build.sh

The script handles everything automatically:
- Installs dotnet 9 if missing
- Copies Jellyfin DLLs from your running instance
- Builds the plugin
- Installs and restarts Jellyfin

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
  Make sure OnlyUnwatched is set to true in the config XML then run a metadata refresh

Plugin not showing in dashboard:
  Check the DLL is in the correct folder and Jellyfin was restarted
  Docker:     docker logs jellyfin | grep -i "dont\|spoil"
  Bare metal: journalctl -u jellyfin | grep -i "dont\|spoil"

Developer and Repository show Unknown:
  Uninstall the plugin and reinstall it via the catalog method above
