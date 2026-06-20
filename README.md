cat > README.md << 'EOF'
# 🎮 ArenaBet

> Real-time skill duels on the Sui blockchain. Connect your Phantom wallet, place a bet, and win SUI.

---


## 🚀 Features

- 👻 **Phantom Wallet Integration** — Connect your Sui wallet via Phantom's in-app browser
- ⚔️ **Real-time Matchmaking** — Get matched with opponents instantly
- 💰 **Bet SUI** — Wager 0.1, 0.5, or 1.0 SUI per match
- 🔥 **Firebase Backend** — Real-time game state, matchmaking, and user management
- 🔐 **Anonymous Auth** — No sign-up needed, just connect your wallet
- ⏱️ **Live Countdown** — Synchronized game timers across players
- 🏆 **Win & Earn** — Winners receive the full pot

---

## ⬇️ Download

[![Download APK](https://img.shields.io/badge/Download-APK-green?style=for-the-badge&logo=android)](https://github.com/wkuye/ArenaBet/releases/latest)

Head to the link above, scroll down to **Assets** and tap `app-release.apk` to download.

---

## 📲 Installation

1. Go to [Releases](https://github.com/wkuye/ArenaBet/releases/latest) and download `app-release.apk`
2. On your Android device go to **Settings → Install unknown apps** and allow your browser
3. Open the downloaded APK and install
4. Make sure **Phantom Wallet** is installed on your device
5. Open ArenaBet and tap **Connect Wallet**

> Requires Android 6.0+

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

## 🔗 Phantom Wallet Connection Flow

ArenaBet uses Phantom's in-app browser to connect Sui wallets since Phantom's mobile deeplink API currently only supports Solana.

1. User taps **Connect Wallet**
2. Phantom in-app browser opens
3. `window.phantom.sui.requestAccount()` is called
4. Phantom prompts user approval
5. Redirects to `arenabet://sui-connect?address=0x...`
6. App catches deeplink and saves to Firebase ✅

---

## 🗂️ Project Structure