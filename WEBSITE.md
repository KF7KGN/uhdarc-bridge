# UHDARC Website — uhdarc.org

The UHDARC website is a full PHP/HTML/CSS/JS production site built and
maintained by KF7KGN. It serves as the public face of the bridge system
and provides tools for operators to connect.

## Live Pages

| Page | Description |
|------|-------------|
| uhdarc.org | Home dashboard — live status widgets, net schedule, system overview |
| uhdarc.org/connect-wizard.php | Step-by-step connection guide for all 4 digital modes |
| uhdarc.org/allstar.php | AllStar Node 573470 documentation and status |
| uhdarc.org/repeaters.php | Full Utah repeater directory |
| uhdarc.org/talkgroups.php | DMR talkgroup reference |
| uhdarc.org/p25.php | P25 reflector documentation |
| uhdarc.org/ysf.php | System Fusion / YSF documentation |
| uhdarc.org/clubs.php | Utah amateur radio club directory |
| uhdarc.org/operations-levels.php | Operating procedures and discipline guide |
| uhdarc.org/howtos-digital.php | Digital mode how-to guides |

## Technical Stack

- **Backend:** PHP 8.x with session management and security headers
- **Frontend:** Vanilla HTML/CSS/JS — no framework dependencies
- **Hosting:** Apache2 on Debian Linux (same server as bridge)
- **API:** Custom Node.js/Express API for member applications
- **Database:** Firebase Firestore for member management
- **Auth:** Firebase Authentication with role-based access control
- **CDN/Proxy:** Cloudflare with TLS
- **Monitoring:** Live status JSON endpoints consumed by dashboard widgets

## Key Features Built

- Live bridge status widgets on home page
- Connect wizard guiding users through EchoLink, DMR, P25, YSF setup
- Member application system with reCAPTCHA v3 bot protection
- Admin portal for approving members and managing roles
- Utah repeater directory with search and filtering
- DMR talkgroup reference database
- Photo gallery system
- How-to guides for all digital modes
- SEO-optimized with structured data / schema.org markup
- Mobile-responsive design with dark/light theme support
