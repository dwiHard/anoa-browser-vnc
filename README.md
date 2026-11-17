# Anoa Fluxbox (`anoa-fluxbox`)

Container Docker ringan berbasis `debian:bookworm-slim` untuk menjalankan **Anoa Browser latest** lengkap dengan desktop virtual responsif (**Xvfb + Fluxbox + noVNC**) dan endpoint **Chrome DevTools Protocol (CDP)** untuk kebutuhan otomasi maupun scraping.

## Fitur Utama

* **Multi-Arch Support:** Otomatis mendeteksi dan mengunduh binary yang sesuai untuk arsitektur `x86_64` (`amd64`) dan `aarch64` (`arm64`).
* **Layar Responsif & Fullscreen:** Mendukung *remote resizing* melalui ekstensi `RANDR` pada `Xvfb` + `x11vnc`, serta konfigurasi Fluxbox otomatis *maximized* tanpa border jendela agar tidak terpotong di berbagai ukuran monitor.
* **Akses Web VNC (noVNC):** Pantau aktivitas browser atau lakukan login akun secara visual langsung lewat web browser pada port `6900`.
* **Endpoint CDP WebSocket:** Terintegrasi dengan `CdpProxy` bawaan Anoa Browser pada port `9224` (`ws://`) dengan dukungan token autentikasi opsional (`--auth-token`).
* **Persistent Profile:** Data sesi login, cookie, cache, dan konfigurasi browser tersimpan aman di volume lokal agar tidak hilang saat container di-restart.

## Prasyarat Sistem

* **Docker Engine** & **Docker Compose** terinstal di mesin host (Linux).
* Kernel host mendukung modul **FUSE** (`/dev/fuse` tersedia di host) untuk menjalankan format AppImage di dalam container.

---

## Cara Menjalankan

### Opsi 1: Menggunakan Docker Compose (Direkomendasikan)

1. **Siapkan file `docker-compose.yml`:**
   Buat atau sesuaikan file `docker-compose.yml` di direktori proyek Anda:

   ```yaml
   services:
     anoa-browser:
       image: ghcr.io/dwihard/anoa-fluxbox:latest
       container_name: anoa-desktop
       restart: unless-stopped
       shm_size: "1gb"
       devices:
         - /dev/fuse:/dev/fuse
       cap_add:
         - SYS_ADMIN
       security_opt:
         - apparmor:unconfined
       ports:
         - "6900:6900"
         - "9224:9224"
       environment:
         - DISPLAY=:0
         - RESOLUTION=1920x1080
         - VNC_PASSWORD=rahasia
         - CDP_AUTH_TOKEN=
         - HOME=/root
       volumes:
         - ./anoa-profile:/root/.local/share
         - ./anoa-config:/root/.config
   ```

2. **Jalankan container di background:**
   ```bash
   docker compose up -d
   ```

3. **Cek status dan log container:**
   ```bash
   docker compose ps
   docker logs -f anoa-desktop
   ```
   Pastikan muncul log `CdpProxy: listening on ws://0.0.0.0: 9224` dan `Listen on :6900` yang menandakan layanan sudah siap.

---

### Opsi 2: Menggunakan `docker run` (Tanpa Compose)

Jika Anda ingin menjalankan langsung melalui satu baris perintah CLI:

```bash
docker run -d \
  --name anoa-desktop \
  --restart unless-stopped \
  --shm-size="1gb" \
  --device /dev/fuse:/dev/fuse \
  --cap-add SYS_ADMIN \
  --security-opt apparmor:unconfined \
  -p 6900:6900 \
  -p 9224:9224 \
  -e DISPLAY=:0 \
  -e RESOLUTION=1920x1080 \
  -e VNC_PASSWORD=rahasia \
  -e CDP_AUTH_TOKEN="" \
  -v $(pwd)/anoa-profile:/root/.local/share \
  -v $(pwd)/anoa-config:/root/.config \
  ghcr.io/dwihard/anoa-fluxbox:latest
```

---

### Opsi 3: Build Manual dari Source Code

Jika Anda melakukan modifikasi pada `Dockerfile` atau `entry.sh`:

1. **Clone repository ini:**
   ```bash
   git clone https://github.com/dwihard/anoa-fluxbox.git
   cd anoa-fluxbox
   ```

2. **Build dan jalankan container:**
   ```bash
   docker compose up -d --build
   ```

---

## Konfigurasi Environment Variable

| Variabel | Default | Keterangan |
| :--- | :--- | :--- |
| `DISPLAY` | `:0` | Nomor display virtual X11 (`Xvfb`). |
| `RESOLUTION` | `1920x1080` | Resolusi canvas maksimum layar virtual (mendukung *auto-resize* saat jendela noVNC diubah ukurannya). |
| `VNC_PASSWORD` | `rahasia` | Password untuk login ke Web VNC (`noVNC`). Kosongkan (`VNC_PASSWORD=`) jika ingin mengakses tanpa password. |
| `CDP_AUTH_TOKEN` | *(kosong)* | Token autentikasi untuk WebSocket CDP di port `9224`. Jika diisi, klien wajib menyertakan token saat terhubung. |

---

## Mengakses Layanan

### 1. Akses Desktop Virtual (noVNC)
Buka URL berikut di web browser Anda (gunakan parameter `resize=remote` agar resolusi desktop otomatis menyesuaikan ukuran layar browser):

```text
http://localhost:6900/vnc.html?resize=remote&autoconnect=true
```
*(Ganti `localhost` dengan IP server jika dijalankan di VPS/server remote, lalu masukkan password VNC yang telah diatur).*

### 2. Koneksi Otomasi via Playwright (`connect_over_cdp`)

#### Tanpa Token (`CDP_AUTH_TOKEN` kosong):
```python
from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    browser = p.chromium.connect_over_cdp("ws://localhost:9224/")
    context = browser.contexts[0]
    page = context.new_page()
    page.goto("https://example.com")
    print(page.title())
    browser.close()
```

#### Dengan Token (`CDP_AUTH_TOKEN` diisi):
```python
from playwright.sync_api import sync_playwright

TOKEN = "token-rahasia-cdp"

with sync_playwright() as p:
    browser = p.chromium.connect_over_cdp(
        f"ws://localhost:9224/?token={TOKEN}",
        headers={"Authorization": f"Bearer {TOKEN}"},
    )
    context = browser.contexts[0]
    page = context.new_page()
    page.goto("https://example.com")
    print(page.title())
    browser.close()
```

---

## Menghentikan & Membersihkan Container

* **Menghentikan sementara (data sesi di volume tetap aman):**
  ```bash
  docker compose stop
  ```
* **Menghapus container (data sesi di `./anoa-profile` tetap tersimpan):**
  ```bash
  docker compose down
  ```

## Catatan Keamanan & Performa

* **Keamanan Port CDP:** Jika server Anda memiliki IP publik, jangan ekspos port `9224` secara terbuka tanpa `CDP_AUTH_TOKEN`, atau ikat port hanya ke localhost (`"127.0.0.1:9224:9224"`) / jaringan internal Docker.
* **Alokasi Shared Memory:** Pertahankan `shm_size: "1gb"` (atau lebih besar) agar proses rendering QtWebEngine tidak mengalami crash saat membuka banyak tab.
