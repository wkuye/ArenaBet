# 🎮 ArenaBet

> Real-time skill duels on the Sui blockchain. Connect your Phantom wallet, place a bet, and win SUI.

---

## 📱 Screenshots

> Coming soon

---

## 🚀 Features

-  **Phantom Wallet Integration** — Connect your Sui wallet via Phantom's in-app browser
-  **Real-time Matchmaking** — Get matched with opponents instantly
-  **Bet SUI** — Wager 0.1, 0.5, or 1.0 SUI per match
-  **Firebase Backend** — Real-time game state, matchmaking, and user management
-  **Anonymous Auth** — No sign-up needed, just connect your wallet
-  **Live Countdown** — Synchronized game timers across players
-  **Win & Earn** — Winners receive the full pot

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter (Android) |
| Blockchain | Sui (Testnet) |
| Wallet | Phantom Wallet |
| Backend | Firebase Firestore |
| Auth | Firebase Anonymous Auth |
| Hosting | Firebase Hosting |
| RPC | Sui Fullnode (Testnet) |

---

## 📲 Platform

> **Android only** — built and tested as an APK

---

## 🔧 Getting Started

### Prerequisites

- Flutter SDK `>=3.0.0`
- Android device or emulator
- Firebase project set up
- Phantom Wallet app installed on your Android device

### Installation

```bash
# Clone the repo
git clone https://github.com/YOUR_USERNAME/arenabet.git
cd arenabet

## ⬇️ Download

## 📲 Installation

1. Go to [Releases](https://github.com/wkuye/ArenaBet/releases/latest) and download `app-release.apk`
2. On your Android device go to **Settings → Install unknown apps** and allow your browser
3. Open the downloaded APK and install
4. Make sure **Phantom Wallet** is installed on your device
5. Open ArenaBet and tap **Connect Wallet**



## 🔗 Phantom Wallet Connection Flow

ArenaBet uses Phantom's in-app browser to connect Sui wallets since Phantom's mobile deeplink API currently only supports Solana.

```
User taps Connect
       │
       ▼
Opens Phantom in-app browser
       │
       ▼
window.phantom.sui.requestAccount()
       │
       ▼
Phantom prompts user approval
       │
       ▼
Redirects to arenabet://sui-connect?address=0x...
       │
       ▼
App catches deeplink → saves to Firebase ✅
```

---

## 📦 Key Dependencies

```yaml
dependencies:
  firebase_core:
  firebase_auth:
  cloud_firestore:
  app_links:
  url_launcher:
  http:
  bs58:
  pinenacl:
  cryptography:
```

---

## 🗂️ Project Structure

```
lib/
├── main.dart
├── model/
│   ├── user_model.dart
│   └── match_model.dart
├── services/
│   ├── phantom_services.dart      # Sui wallet connection
│   ├── firestore_services.dart    # Firebase operations
│   └── matchmaking_service.dart   # Real-time matchmaking
└── screens/
    ├── lobby_screen.dart          # Main game lobby
    ├── countdown_screen.dart      # Match countdown
    └── username_page.dart         # New user setup
```

---

## ⚠️ Important Notes

- This app runs on **Sui Testnet** — no real funds are used
- **Android only** — no iOS build at this time
- Phantom Wallet must have **Sui network enabled** (Settings → Active Networks → Sui)
- The wallet connection page is hosted on Firebase Hosting and opened inside Phantom's browser

---

## 📄 License

MIT License — feel free to fork and build on it.

---

## 🙏 Acknowledgements

- [Sui Foundation](https://sui.io)
- [Phantom Wallet](https://phantom.app)
- [Firebase](https://firebase.google.com)
- [Flutter](https://flutter.dev)
