# Anoa Browser Docker (VNC + CDP)

Container Docker ringan berbasis `debian:bookworm-slim` untuk menjalankan **Anoa Browser v0.19.1** lengkap dengan desktop virtual (**Xvfb + Fluxbox + noVNC**) dan endpoint **Chrome DevTools Protocol (CDP)** untuk kebutuhan otomasi maupun scraping.

## Fitur
- **Multi-Arch Ready:** Otomatis mendeteksi arsitektur `x86_64` dan `aarch64`.
- **Akses Web VNC (noVNC):** Pantau dan login akun secara visual langsung lewat browser di port `6900`.
- **Endpoint CDP:** Mendukung koneksi WebSocket (`ws://`) di port `9224` (dengan opsi `--auth-token`) maupun HTTP proxy (`http://`) di port `9225`.
- **Persistent Profile:** Data sesi login, cookie, dan konfigurasi browser tersimpan di volume lokal.

## Cara Menjalankan

### 1. Menggunakan Pre-built Image (`ghcr.io`)
Pastikan `docker-compose.yml` mengarah ke `ghcr.io/dwihard/anoa-fluxbox:0.1.0`, lalu jalankan:
```bash
docker compose up -d
```

### 2. Build Manual dari Source
```bash
docker compose up -d --build
```

## Konfigurasi Environment Variable

| Variabel | Default | Keterangan |
| :--- | :--- | :--- |
| `DISPLAY` | `:0` | Display virtual Xvfb |
| `RESOLUTION` | `1366x768` | Resolusi layar desktop VNC |
| `VNC_PASSWORD` | `rahasia` | Password login noVNC (kosongkan untuk tanpa password) |
| `CDP_AUTH_TOKEN` | *(kosong)* | Token autentikasi WebSocket CDP di port `9224` |

## Akses Layanan

- **noVNC (Web Desktop):** `http://localhost:6900/vnc.html`
- **CDP WebSocket Proxy:** `ws://localhost:9224/` *(atau `ws://localhost:9224/?token=<CDP_AUTH_TOKEN>`)*
- **CDP HTTP Endpoint:** `http://localhost:9225`

## Contoh Koneksi Playwright

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

## Catatan Penggunaan
- Container membutuhkan akses perangkat `/dev/fuse` dan kapabilitas `SYS_ADMIN` untuk menjalankan binary AppImage secara langsung.
- Gunakan `shm_size: "1gb"` pada `docker-compose.yml` agar tab browser tetap stabil saat merender halaman berat.
