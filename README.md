# Home Assistant Add-on: Dispatcharr

[![GitHub Release](https://img.shields.io/github/v/release/esbnetworking/ha-dispatcharr-addon?style=flat-square)](https://github.com/esbnetworking/ha-dispatcharr-addon/releases)
[![License: AGPL-3.0](https://img.shields.io/badge/License-AGPL%203.0-blue.svg?style=flat-square)](https://github.com/Dispatcharr/Dispatcharr/blob/main/LICENSE)
[![Home Assistant Add-on](https://img.shields.io/badge/Home%20Assistant-Add--on-blue?style=flat-square&logo=home-assistant)](https://www.home-assistant.io)

Dispatcharr is an open-source stream and proxy management companion designed for IPTV, EPG data, and VOD workflows. This add-on packages [Dispatcharr](https://github.com/Dispatcharr/Dispatcharr) directly into Home Assistant OS / Supervised.

---

## Features

- **Stream Proxy & Relay:** Intercept, aggregate, and proxy IPTV streams with real-time connection handling and automatic failover.
- **EPG Integration:** XMLTV and Schedules Direct matching with auto-sync and custom schedule generation.
- **Media Server Emulation:** Exposes virtual HDHomeRun tuners to Plex, Emby, and Jellyfin.
- **Multi-Format Output:** Export channel lists as M3U, XMLTV EPG, Xtream Codes API, or HDHomeRun tuner endpoints.
- **Built-in DVR & Timeshift:** Schedule recordings directly from the guide and proxy catch-up streams.
- **Transcoding Profiles:** Output stream adjustments via FFmpeg profiles for low-bandwidth or specific audio/video codec compatibility.

---

## Installation

[![Open your Home Assistant instance and show the add add-on repository dialog with a specific repository URL pre-filled.](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Fesbnetworking%2Fha-dispatcharr-addon)

1. In Home Assistant, navigate to **Settings** -> **Add-ons** -> **Add-on Store**.
2. Click the **three dots (overflow menu)** in the top right and select **Repositories**.
3. Add your repository URL:
   ```text
   [https://github.com/esbnetworking/ha-dispatcharr-addon](https://github.com/esbnetworking/ha-dispatcharr-addon)
