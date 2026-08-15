# 📦 DELHIVERY

### All your orders. One app. Zero mess.

Track every package from every platform — Amazon, Flipkart, Myntra, Ajio, Purplle, and more — in a single, beautifully simple dashboard.

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)](#license)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey?style=for-the-badge)](#)

**[📲 Get the App](#-your-app-link-here)**

</div>

---

## 🧩 The Problem

Order from five different platforms, and you're stuck juggling five different apps just to know where your packages are. Different UIs, different logins, different tracking pages — it's tedious, and it's easy to lose track of something.

## 💡 The Solution

**DELHIVERY** is a Flutter app that lets you paste *any* tracking ID or tracking link — no matter which platform or courier it came from — and see it tracked in one unified dashboard.

> Copy → Paste → Track. All your shipments, one screen, no missing, no mess.

---

## ✨ Features

- 📥 **Universal Add** — paste any tracking link or ID; the app auto-detects the courier
- 🗂️ **Unified Dashboard** — every shipment across every platform, in one list
- 🔎 **Live Timeline View** — visual status timeline: Ordered → Shipped → Out for Delivery → Delivered
- 🔔 **Local Status Alerts** — get notified when a shipment status changes
- 🎯 **Smart Filters** — sort by In Transit / Delivered / Delayed
- 🔒 **100% Local & Private** — no account, no cloud, all data stays on your device
- 🆓 **Fully Free** — built entirely on free, open-source tools and packages — no paid APIs

---

## 🎨 Design

DELHIVERY follows a clean, minimal **dark-mode-first** UI:

| | |
|---|---|
| 🖤 Background | Near-black, high contrast |
| 💚 Accent | Signature lime-yellow highlights |
| 🧊 Cards | Soft rounded, subtle-border shipment cards |
| 📊 Timeline | Elegant dot-and-line progress visualization |

---

## 🛠️ Tech Stack

- **Flutter** — cross-platform UI
- **Hive** — fast, local on-device storage
- **http + html** — courier tracking page parsing
- **webview_flutter** — fallback rendering for JS-based tracking pages
- **flutter_local_notifications** — status-change alerts
- **workmanager** — background shipment refresh

---

## 📱 Screens

| Home | Add Tracking | Shipment Detail | Settings |
|---|---|---|---|
| Dashboard of all shipments | Paste & auto-detect courier | Visual delivery timeline | Preferences & data export |

---

## 🚀 Getting Started

```bash
git clone https://github.com/Alan-m-varghese/delhivery.git
cd delhivery
flutter pub get
flutter run
```

---

## 📲 Download / Try It

<div align="center">

### 👉 [YOUR APP LINK HERE](#) 👈

</div>

---

## 🗺️ Roadmap

- [x] Local shipment tracking & manual add
- [x] Auto-detect courier from pasted link
- [ ] Auto-tracking adapters (Delhivery, India Post, DTDC, Ecom Express, Blue Dart)
- [ ] Background sync + status-change notifications
- [ ] Clipboard auto-detect prompt
- [ ] JSON backup / export

---

## 🤝 Contributing

Contributions, issues, and feature requests are welcome! Feel free to check the [issues page](../../issues).

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

<div align="center">

Made with 💚 using Flutter

</div>
