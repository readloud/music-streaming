# Self-hosted music streaming server (access your music from other devices)

Jellyfin (free, lightweight) plus optional Airsonic/Navidrome alternatives.

## Recommended stack (default)
- Jellyfin (media server with music support)
- Docker & Docker Compose (easy deployment)
- Reverse proxy (Caddy recommended for automatic HTTPS) — optional but recommended
- External storage or NAS for your music files

## Minimum requirements (suggested)
- CPU: x86_64 or ARM (Raspberry Pi 4+ OK)
- RAM: 2–4 GB+
- Storage: space for your music library
- Network: home LAN; optional public access through router port forwarding or Cloudflare Tunnel

## Steps — Docker Compose (Jellyfin) — presuming Linux host, Docker installed
1. Create a directory:
   - /srv/music-server

2. Place your music under /srv/music (or mount external drive).

3. Create docker-compose.yml in /srv/music-server with:
```
version: "3.8"
services:
  jellyfin:
    image: jellyfin/jellyfin:latest
    container_name: jellyfin
    network_mode: bridge
    ports:
      - "8096:8096"
      - "8920:8920" # optional HTTPS if enabled in container
    volumes:
      - /srv/music:/media/music:ro
      - /srv/music-server/config:/config
      - /srv/music-server/cache:/cache
    restart: unless-stopped
```
4. Start:
- cd /srv/music-server
- docker compose up -d

5. First-run:
- Open http://HOST:8096 in a browser.
- Create admin user, add library: path /media/music, choose Music library type.
- Let Jellyfin scan metadata.

## Optional: Add Caddy reverse proxy with automatic HTTPS (recommended if exposing to internet)
- Add to docker-compose.yml:
```
  caddy:
    image: caddy:2
    container_name: caddy
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /srv/music-server/caddy/Caddyfile:/etc/caddy/Caddyfile
      - caddy_data:/data
      - caddy_config:/config
    restart: unless-stopped
```
- Example Caddyfile:
```
your.domain.example {
  reverse_proxy host.docker.internal:8096
}
```
- Point DNS for your domain to your public IP; ensure ports 80/443 forwarded.

Alternative: use Cloudflare Tunnel or Nginx proxy if preferred.

## Optional alternatives (lighter or music-focused)
- Navidrome — lightweight, actively developed, great for large FLAC/MP3 libraries.
- Airsonic-Advanced — fork of Subsonic with many streaming clients.
Use similar Docker Compose but replace image with navidrome/navidrome or airsonic/airsonic-advanced and set music path.

## Mobile apps & clients
- Jellyfin: official apps for Android/iOS, web player, desktop clients.
- Navidrome: Doppler (Android), Navidrome web UI, third-party clients support Subsonic API.
- Airsonic: many Subsonic-compatible apps.

## Backups & maintenance
- Backup /config and /cache volumes regularly.
- Update containers with: docker compose pull && docker compose up -d
- Re-scan library if you add new music.
- Music files are on the host at /srv/music (Linux) or D:\music (Windows). Adjust paths if different.
- Caddyfile (place at ${DATA_DIR}/caddy/Caddyfile; replace domains)
- Replace music.example.com with your domain (and optionally jellyfin.example.com)

Deployment steps (Linux)
1. Create folders:
   - mkdir -p /srv/music-server/{jellyfin,navidrome,caddy}
   - place music under /srv/music
   - put Caddyfile at /srv/music-server/caddy/Caddyfile
2. Start:
   - cd /srv/music-server
   - docker compose up -d
3. Open:
   - http://HOST:8096 for Jellyfin initial setup (or https://jellyfin.domain if using Caddy/subdomain)
   - https://navidrome.domain:443 or http://HOST:4533 for Navidrome
4. In Jellyfin: Add library path /media/music as "Music".
5. In Navidrome: configure music directory /data/music and let it scan.

Deployment steps (Windows)
1. Create C:\music-server folders and Caddyfile at C:\music-server\caddy\Caddyfile
2. Ensure D:\music exists with your files.
3. Open PowerShell in C:\music-server and run:
   - docker compose -f docker-compose-windows.yml up -d
4. Access same URLs as above.

Firewall & Router
- If you want remote access, forward ports 80 and 443 to the host, or use Cloudflare Tunnel instead of opening ports.
- For LAN-only use, do not forward ports.

Backups & Updates
- Back up jelyfin and navidrome data folders (the host-mounted config/db paths).
- Update: docker compose pull && docker compose up -d

- Replace: YOUR_EMAIL, jellyfin.example.com, navidrome.example.com
- Adjust host music path: Linux use /srv/music, Windows use D:/music and update paths when running.

Notes:
- Compose uses internal Docker DNS so Caddy reverse_proxies to service names.
- For Windows, set MUSIC_PATH to D:/music and DATA_DIR to C:/music-server in .env.

PowerShell script (Windows) — creates folders, writes files, and runs Docker Compose
- `deploy.ps1` edit domain/email, then run PowerShell as Administrator.

Quick post-deploy tasks
- Point DNS A records for jellyfin.example.com and navidrome.example.com to your host public IP.
- If behind NAT, forward ports 80 and 443 to the host.
- On first run, open jellyfin.example.com and navidrome.example.com to complete setup.
- If LAN-only, skip DNS and use host IP + ports; remove Caddy for LAN-only.

```
version: "3.8"
services:
  jellyfin:
    image: jellyfin/jellyfin:latest
    container_name: jellyfin
    restart: unless-stopped
    ports:
      - "8096:8096"
    volumes:
      - /srv/music:/media/music:ro
      - /srv/music-server/jellyfin/config:/config
      - /srv/music-server/jellyfin/cache:/cache

  navidrome:
    image: deluan/navidrome:latest
    container_name: navidrome
    restart: unless-stopped
    environment:
      - ND_LOGLEVEL=info
      - ND_SCANINTERVAL=1m
    ports:
      - "4533:4533"
    volumes:
      - /srv/music:/data/music:ro
      - /srv/music-server/navidrome/data:/data/db
```

# Notes
# - Replace /srv/music and /srv/music-server with your host paths (Windows example: D:/music and C:/music-server).
# - This compose exposes Jellyfin on http://HOST:8096 and Navidrome on http://HOST:4533 for LAN access only.
# - Do not forward ports 80/443 on your router for LAN-only setup.


## Mounting Cloudstore (Google Drive, OneDrive, and Yandex.Disk)

Linux — steps (rclone)
1) Install rclone:
- Debian/Ubuntu: sudo apt install rclone
- Or use official install script from rclone if needed.

2) Configure remotes:
- Run: rclone config
- Create remotes named e.g., gdrive, onedrive, yandex following interactive prompts and OAuth flow.

3) Test listing:
- rclone ls gdrive:  (or rclone lsd onedrive: )

4) Create mount directories and set permissions:
- sudo mkdir -p /mnt/music/gdrive /mnt/music/onedrive /mnt/music/yandex
- sudo chown youruser:youruser /mnt/music/*

5) Mount read-only (foreground, for testing):
- rclone mount gdrive:Music /mnt/music/gdrive --vfs-cache-mode writes --read-only
- rclone mount onedrive:Music /mnt/music/onedrive --vfs-cache-mode writes --read-only
- rclone mount yandex:Music /mnt/music/yandex --vfs-cache-mode writes --read-only

6) Recommended systemd service (create /etc/systemd/system/rclone-gdrive.service — example for gdrive):

- Replace youruser and path to rclone.conf.
- Enable & start:
  - sudo systemctl daemon-reload
  - sudo systemctl enable --now rclone-gdrive

Notes: use --allow-other only if /etc/fuse.conf has user_allow_other and you trust local users. For strict read-only, include --read-only.

Windows — steps (rclone + WinFsp)
1) Install WinFsp (required) and rclone for Windows.

2) Configure remotes:
- Open PowerShell and run: rclone config
- Create remotes named gdrive, onedrive, yandex.

3) Create mount points (folders), e.g., D:\mounted\gdrive

4) Test mount (foreground):
- rclone mount gdrive:Music D:\mounted\gdrive --vfs-cache-mode writes --read-only

5) Run as background service (recommended):
- Use nssm (Non-Sucking Service Manager) or Task Scheduler to run at startup.
- Example with nssm:
  - nssm install rclone-gdrive "C:\path\to\rclone.exe" mount gdrive:Music D:\mounted\gdrive --vfs-cache-mode writes --read-only
  - Configure service to run under your user account.

Docker integration — point containers to mounts

- Update docker-compose volumes to use the mount paths:
  - Linux example:
    - volumes:
      - /mnt/music/gdrive:/data/music:ro
  - Windows example:
    - volumes:
      - D:\mounted\gdrive:C:\data\music:ro
	  
- For combined libraries, create a union mount or bind-mount multiple paths into containers and add multiple libraries in Jellyfin/Navidrome.

- Create union remote: rclone config create cloudmusic union remote gdrive:Music remote onedrive:Music remote yandex:Music
- Edit .env: set MUSIC_MERGE_MOUNT, DATA_DIR, HOST_USER, RCLONE_REMOTE (cloudmusic).
- Create mount dir and set ownership: sudo mkdir -p $(grep MUSIC_MERGE_MOUNT .env | cut -d= -f2) && sudo chown youruser:youruser $(grep MUSIC_MERGE_MOUNT .env | cut -d= -f2)
- Start systemd service or test mount manually:
  - Manual test: rclone mount cloudmusic: /mnt/music/union --vfs-cache-mode writes --read-only &
- Start Docker: docker compose up -d
- In Jellyfin add library path /media/music; in Navidrome set /data/music.

Better performance & stability tips
- Use --vfs-cache-mode writes for smoother access to many small files and metadata. Monitor disk usage of VFS cache.
- For large libraries, consider keeping a local cache or syncing frequently-played albums locally.
- Set appropriate rclone flags if you need streaming support:
	- --vfs-read-chunk-size 64M --vfs-read-chunk-size-limit 1G
- Avoid aggressive write flags if mounts are read-only.

Optional: union/merged view of multiple clouds
- Use rclone's union remote to merge multiple remotes into one mount:
  - rclone config create union union remote gdrive:Music onedrive:Music yandex:Music
  - then mount union: /mnt/music/all
- Or use OS-level unionfs/mergerfs on Linux after syncing.

Permissions & Docker notes
- Ensure the UID/GID of files seen in the mount is compatible with container users. Using --allow-other helps containers access mounts; ensure FUSE config allows it.
- Keep mounts stable before starting containers; systemd unit should handle startup ordering.

Security & quotas
- Cloud providers may have API quotas — avoid aggressive polling (set rclone --poll-interval or reduce scan frequency).
- Use OAuth tokens stored in rclone.conf; keep that file secure.

- Linux test mount:
  - rclone mount gdrive:Music /mnt/music/gdrive --vfs-cache-mode writes --read-only &
  
- Windows test mount (PowerShell):
  - Start-Process -NoNewWindow -FilePath "C:\path\to\rclone.exe" -ArgumentList "mount gdrive:Music D:\mounted\gdrive --vfs-cache-mode writes --read-only"
  
.env
```
MUSIC_MERGE_MOUNT=/home/svn/music-server/mount
DATA_DIR=/home/svn/music-server/data
HOST_USER=svn
RCLONE_REMOTE=cloudmusic
```

docker-compose.yml
```
version: "3.8"
services:
  jellyfin:
    image: jellyfin/jellyfin:latest
    container_name: jellyfin
    restart: unless-stopped
    ports:
      - "8096:8096"
    volumes:
      - /home/svn/music-server/mount:/media/music:ro
      - /home/svn/music-server/data/jellyfin/config:/config
      - /home/svn/music-server/data/jellyfin/cache:/cache

  navidrome:
    image: deluan/navidrome:latest
    container_name: navidrome
    restart: unless-stopped
    environment:
      - ND_LOGLEVEL=info
      - ND_SCANINTERVAL=1m
    ports:
      - "4533:4533"
    volumes:
      - /home/svn/music-server/mount:/data/music:ro
      - /home/svn/music-server/data/navidrome/data:/data/db
```

1) Ensure rclone remotes (gdrive, onedrive, yandex) exist and create union:
   rclone config create cloudmusic union remote gdrive:Music remote onedrive:Music remote yandex:Music

2) Create directories and set ownership:
   sudo mkdir -p /home/svn/music-server/mount
   sudo mkdir -p /home/svn/music-server/data/jellyfin/config /home/svn/music-server/data/jellyfin/cache /home/svn/music-server/data/navidrome/data
   sudo chown -R svn:svn /home/svn/music-server

3) Enable and start the mount:
   sudo systemctl daemon-reload
   sudo systemctl enable --now rclone-union

   (For testing without systemd: rclone mount cloudmusic: /home/svn/music-server/mount --vfs-cache-mode writes --read-only &)

4) Start containers:
   docker compose up -d

5) In Jellyfin add library path /media/music; in Navidrome set music dir /data/music.


# troubleshoot

Fixes (pick one):

1) Mount a host file (recommended)
- Ensure the host Caddyfile is a regular file:
  ```
  sudo mkdir -p /srv/music-server/caddy
  sudo touch /srv/music-server/caddy/Caddyfile
  sudo chown $(id -u):$(id -g) /srv/music-server/caddy/Caddyfile
  ```
  Edit that file with your Caddy config, then restart:
  ```
  docker compose up -d caddy
  ```

2) If you intended to mount a directory of Caddy config into /etc/caddy, change the compose volume to mount the whole directory:
  ```
  - ${DATA_DIR}/caddy:/etc/caddy:ro
  ```
  and ensure the host directory exists and contains a Caddyfile (or config/*.json).

3) If the host path is a symlink to a directory, replace it with a regular file or point to the correct file.

4) If running SELinux, after creating the file add label:
  ```
  sudo chcon -t svirt_sandbox_file_t /srv/music-server/caddy/Caddyfile
  ```

Apply one of the above and then run:
```
docker compose up -d caddy
```
Notes
- Adjust /usr/bin/rclone path if rclone is elsewhere.
- Ensure /etc/fuse.conf contains "user_allow_other" if using --allow-other.
- Monitor VFS cache usage; change --vfs-cache-mode or chunk sizes if needed.

