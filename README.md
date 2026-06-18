# UHDARC Digital Bridge
## Utah High Desert Amateur Radio Club
### Multi-Mode Digital Radio Convergence System

Built and maintained by Richie Hayes - KF7KGN

---

## What Is This?

UHDARC operates a production-grade digital radio bridge that acts as a central switching hub connecting four completely incompatible digital radio protocols so operators on different networks can talk to each other in real time.

- **DMR** - Digital Mobile Radio - most popular digital mode worldwide
- **P25** - Project 25 - public safety standard used by police, fire, EMS
- **YSF** - System Fusion - Yaesu proprietary digital format
- **EchoLink** - Amateur radio over the internet, connects worldwide

---

## Production Stats

| Metric | Value |
|--------|-------|
| AllStar Node | 573470 |
| Active Channels | 75 |
| Digital Modes Bridged | 4 |
| Remote IAX2 Peers | 20+ |
| Bridge Services | 9 |
| Server | Debian Linux |

---

## How It Works

A DMR user transmits on their radio. That audio hits Node 1999 via USRP, enters Asterisk, gets transcoded by Analog_Bridge through AMBE encoding, distributed to HBlink3 which sends it to 20+ DMR networks nationwide. Simultaneously P25 users, YSF users, and EchoLink users all hear the same transmission. Everyone talks, everyone hears, regardless of what radio or protocol they use.

---

## Technical Stack

- **Asterisk/AllStar** - Central IAX2 routing hub
- **HBlink3** - DMR Master Server (Python)
- **MMDVM_Bridge** - Multi-mode voice transcoding
- **P25Gateway + Quantar_Bridge** - P25 digital routing
- **YSFGateway** - System Fusion network gateway
- **theBridge (tbd)** - EchoLink conference server
- **Analog_Bridge** - FM analog to digital transcoding
- **Analog_Reflector** - Audio distribution
- **Allmon3** - AllStar web monitor
- **HBmonitor** - DMR dashboard
- **Node.js/Express** - Custom API dashboard
- **PostgreSQL x2** - Databases
- **MariaDB** - Database
- **Apache2** - HTTPS frontend
- **MediaMTX** - RTMP/HLS streaming
- **Mosquitto MQTT** - IoT messaging
- **Tailscale VPN** - Secure remote access
- **Monit + Promtail** - System monitoring

---

## Node Architecture

| Node | Mode | USRP RX | USRP TX | Duplex | Gain |
|------|------|---------|---------|--------|------|
| 573470 | Hub | Local/pseudo | Local/pseudo | Full (2) | - |
| 1999 | DMR | 34001 | 32001 | Half (0) | -3.0 dB |
| 1998 | P25 | 34002 | 32002 | Half (0) | -6.0 dB |
| 1997 | YSF | 34003 | 32003 | Half (0) | 0.0 dB |

---

## Key Ports

| Port | Service |
|------|---------|
| 5038 | Asterisk AMI |
| 62030 | HBlink3 DMR Master |
| 31100/31103 | AMBE Audio Transcoding |
| 34001-34003 | USRP Radio Input |
| 32001-32003 | USRP Radio Output |
| 42002 | YSF Reflector |
| 8443 | EchoLink/Analog Reflector |
| 16080 | Allmon3 Web Monitor |
| 3000 | UHDARC API Dashboard |
| 80/443 | Apache HTTPS |
| 1883 | MQTT |
| 5432/5433 | PostgreSQL |
| 3306 | MariaDB |
| 1994 | Quantar Bridge P25 |
| 2812 | Monit Health Monitor |

---

## License

GNU General Public License v3.0
