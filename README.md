# 🙈 dont-spoil-me — Jellyfin Plugin

Replaces episode thumbnail images with the **series poster** so spoiler screenshots never ruin your next watch.

- Unwatched episodes → series poster shown instead of the episode thumbnail
- When you finish watching an episode → real thumbnail is automatically restored
- Works on any Jellyfin client (web, mobile, TV apps)

---

## Requirements

- Jellyfin 10.9 or newer
- .NET 9 SDK *(only needed to build — not needed to run)*

---

## Installing the Plugin

### Option A — Manual install (easiest, works everywhere)

1. Download `dont-spoil-me_1.0.0.0.zip`
2. Unzip it — you'll get `Jellyfin.Plugin.DontSpoilMe.dll`
3. Copy the DLL into your Jellyfin plugins folder:

**Bare metal Linux:**
```bash
mkdir -p /var/lib/jellyfin/plugins/DontSpoilMe
cp Jellyfin.Plugin.DontSpoilMe.dll /var/lib/jellyfin/plugins/DontSpoilMe/
chown -R jellyfin:jellyfin /var/lib/jellyfin/plugins/DontSpoilMe
systemctl restart jellyfin
```

**Docker (docker-compose):**
```bash
# Find where your plugins folder is mounted, e.g. ~/jellyfin/config/plugins
mkdir -p ~/jellyfin/config/plugins/DontSpoilMe
cp Jellyfin.Plugin.DontSpoilMe.dll ~/jellyfin/config/plugins/DontSpoilMe/
docker compose restart jellyfin
```

**Windows:**
```
Copy Jellyfin.Plugin.DontSpoilMe.dll to:
C:\ProgramData\Jellyfin\Server\plugins\DontSpoilMe\
Then restart the Jellyfin service.
```

4. Open the Jellyfin dashboard → **Plugins** → confirm **dont-spoil-me** is listed
5. Go to **Dashboard → Scheduled Tasks** and run **Refresh Metadata** to apply immediately

---

### Option B — Build from source

If you want to build the DLL yourself (e.g. after a Jellyfin update):

**Requirements:** .NET 9 SDK, Jellyfin installed on the same machine

```bash
# Clone or download this repo, then:
bash build.sh
```

The script will:
- Auto-detect your dotnet installation (installs it if missing)
- Auto-detect your Jellyfin DLL location (bare metal or Docker volume)
- Build the plugin
- Output `dist/dont-spoil-me_1.0.0.0.zip` ready to install

If your Jellyfin DLLs are in a non-standard location:
```bash
JELLYFIN_LIB=/path/to/jellyfin/lib bash build.sh
```

---

## Configuration

After installing, go to **Dashboard → Plugins → dont-spoil-me**:

| Setting | Default | Description |
|---|---|---|
| Enable dont-spoil-me | ✅ On | Master on/off switch |
| Only hide unwatched episodes | ✅ On | Watched episodes show their real thumbnail |

---

## Troubleshooting

**Thumbnails not changing after install**
Run a metadata refresh: Dashboard → Scheduled Tasks → Refresh Metadata

**Watched episodes still showing series poster**
Make sure "Only hide unwatched episodes" is enabled, then run a metadata refresh.

**Plugin not showing in dashboard**
- Check the DLL is in the right folder and Jellyfin was restarted
- Check logs: `journalctl -u jellyfin | grep -i "dont\|spoil"` (bare metal)
  or `docker logs jellyfin | grep -i "dont\|spoil"` (Docker)
