param()

$DataDir = "C:\music-server"
$MusicPath = "D:\music"
$EnvPath = Join-Path $DataDir ".env"
$ComposePath = Join-Path $DataDir "docker-compose.yml"
$CaddyDir = Join-Path $DataDir "caddy"
$Caddyfile = Join-Path $CaddyDir "Caddyfile"

# Create folders
New-Item -ItemType Directory -Path $DataDir -Force | Out-Null
New-Item -ItemType Directory -Path $CaddyDir -Force | Out-Null
New-Item -ItemType Directory -Path $MusicPath -Force | Out-Null

# Write .env
@"
MUSIC_PATH=$MusicPath
DATA_DIR=$DataDir
YOUR_EMAIL=you@example.com
"@ | Out-File -FilePath $EnvPath -Encoding UTF8

# Write docker-compose.yml
@"
version: "3.8"
services:
  jellyfin:
    image: jellyfin/jellyfin:latest
    container_name: jellyfin
    restart: unless-stopped
    expose:
      - "8096"
    volumes:
      - \${MUSIC_PATH}:/media/music:ro
      - \${DATA_DIR}/jellyfin/config:/config
      - \${DATA_DIR}/jellyfin/cache:/cache

  navidrome:
    image: deluan/navidrome:latest
    container_name: navidrome
    restart: unless-stopped
    environment:
      - ND_LOGLEVEL=info
      - ND_SCANINTERVAL=1m
    expose:
      - "4533"
    volumes:
      - \${MUSIC_PATH}:/data/music:ro
      - \${DATA_DIR}/navidrome/data:/data/db

  caddy:
    image: caddy:2
    container_name: caddy
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    environment:
      - ACME_AGREE=true
      - EMAIL=\${YOUR_EMAIL}
    volumes:
      - \${DATA_DIR}/caddy/Caddyfile:/etc/caddy/Caddyfile:ro
      - \${DATA_DIR}/caddy/data:/data
      - \${DATA_DIR}/caddy/config:/config
"@ | Out-File -FilePath $ComposePath -Encoding UTF8

# Write Caddyfile (edit domains)
@"
jellyfin.example.com {
  reverse_proxy jellyfin:8096
  tls \${YOUR_EMAIL}
  encode gzip
}

navidrome.example.com {
  reverse_proxy navidrome:4533
  tls \${YOUR_EMAIL}
  encode gzip
}
"@ | Out-File -FilePath $Caddyfile -Encoding UTF8

# Run docker compose
Push-Location $DataDir
docker compose up -d
Pop-Location

Write-Output "Deployment started. Edit $EnvPath and $Caddyfile if you need to change domains or paths."