# 💎 FinanceTracker — Personal Wealth & Cash Flow Management

<p align="center">
  <img src="assets/images/logo.png" alt="FinanceTracker Logo" width="120" height="120" />
</p>

<p align="center">
  <b>A state-of-the-art cross-platform Personal Finance, Budgeting & Cash Flow Management mobile & web application built with Flutter & Dart.</b>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.47.1-02569B?logo=flutter&logoColor=white" alt="Flutter Version" />
  <img src="https://img.shields.io/badge/Dart-3.13.1-0175C2?logo=dart&logoColor=white" alt="Dart Version" />
  <img src="https://img.shields.io/badge/State_Management-Provider-blueviolet" alt="State Management" />
  <img src="https://img.shields.io/badge/Localization-English%20%7C%20සිංහල-success" alt="Localization" />
  <img src="https://img.shields.io/badge/Multi--Account-Supported-informational" alt="Multi-Account" />
  <img src="https://img.shields.io/badge/License-MIT-green" alt="License" />
</p>

---

## 📖 Overview

**FinanceTracker** is a modern, high-performance personal finance tracking mobile and web application designed to help individuals and businesses track daily incomes and expenses, budget across custom categories, achieve savings goals, analyze 12-month annual cash flows, and export official financial statements in PDF and CSV formats.

---

## ✨ Key Features

### 1. 🛡️ Luxury UI & Brand Identity
- **Rich Purple Gradient Splash Screen**: Ambient glowing animations, official shield and coin logo branding, and smooth transition.
- **Adaptive Dark / Light Themes**: Sleek dark mode (`#0B0F19`) and clean light mode (`#F8FAFC`) with smooth contrast and hover-lift cards.

### 2. 👥 Multi-Account Profile Switcher (FB & WhatsApp Style)
- Store and manage multiple user profiles on a single device (e.g., *Personal*, *Business*, *Family*).
- **1-Tap Fast Switching**: Seamlessly toggle between saved accounts without re-entering credentials.
- Add or remove accounts safely from device storage.

### 3. 🌐 Bilingual Translation System (English 🇺🇸 & Sinhala 🇱🇰)
- Full, real-time localized UI across all screens (Navigation, Dashboard, Budgets, Goals, Analytics, Dialogs).
- Instant language toggle switchers in the Top Header Bar, App Drawer, and Profile Settings.
- Persistent language preference saved in local storage.

### 4. 📊 Dynamic Interactive Dashboard
- **Monthly Overview**: Real-time KPI summaries for *Monthly Income*, *Monthly Expenses*, and *Net Savings*.
- **Category Breakdown**: Separate interactive Doughnut Charts for Income and Expense distributions.
- **6-Month Cash Flow Trend**: Dual-rod bar chart comparing month-by-month cash flows.
- **Quick Action Triggers**: `+ Add Category` modal and `+ Add Transaction` sheet with instant updates.
- **Recent Activities Log**: Quick transaction history list with edit/delete actions.

### 5. 🎯 Monthly Budgets & Spending Limits
- Set custom monthly spending limits per category.
- Visual progress meters with real-time percentage used and over-budget alerts.
- Filter budgets by specific month and year.

### 6. 🏆 Savings Goals & Target Tracking
- Create target-based savings funds (Vacation, Emergency Fund, Gadgets).
- Track target vs. saved amounts with interactive percentage rings and days remaining countdowns.
- **Quick Deposit**: Add funds directly into any goal with a single tap.

### 7. 📑 Financial Analytics & Official Statement Export
- **Monthly & Annual Views**: Switch between granular monthly logs and full 12-month annual progressions.
- **Official PDF Statements**: Containerized executive summaries, KPI statistics, 12-month tables, and itemized logs ready for printing or sharing.
- **CSV Data Export**: One-click export for Excel, Google Sheets, and accounting software.

---

## 🛠️ Technology Stack

| Layer | Technology |
| :--- | :--- |
| **Frontend Framework** | [Flutter](https://flutter.dev/) (v3.47+) & [Dart](https://dart.dev/) |
| **State Management** | [Provider](https://pub.dev/packages/provider) (MultiProvider Architecture) |
| **Charts & Graphs** | [fl_chart](https://pub.dev/packages/fl_chart) (Doughnut & Bar charts) |
| **PDF Generation** | [pdf](https://pub.dev/packages/pdf) & [printing](https://pub.dev/packages/printing) |
| **Animations** | [flutter_animate](https://pub.dev/packages/flutter_animate) |
| **Storage & Caching** | [shared_preferences](https://pub.dev/packages/shared_preferences) |
| **Backend API** | PHP REST API + MySQL (with Offline Demo fallback mode) |

---

## 🚀 Getting Started & Installation

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.20.0 or later)
- [Dart SDK](https://dart.dev/get-dart)
- Chrome / Edge (for Web testing) or Android / iOS Emulator

### 1. Clone the Repository
```bash
git clone https://github.com/your-username/personal-finance-tracker.git
cd personal-finance-tracker_mobile
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Run Locally (Web / Chrome)
```bash
flutter run -d chrome
```

### 4. Build Production Web Bundle
```bash
flutter build web --base-href /
```

---

## 📂 Project Structure

```
personal-finance-tracker_mobile/
├── assets/
│   └── images/               # Official logo and graphic assets
├── lib/
│   ├── core/
│   │   ├── constants/        # App colors, themes, API endpoints
│   │   ├── localization/     # Bilingual English & Sinhala dictionary (AppStrings)
│   │   ├── network/          # ApiClient & HTTP request handlers
│   │   ├── theme/            # Light & Dark theme definitions
│   │   └── utils/            # Formatters, CSV & PDF export helpers
│   ├── models/               # Transaction, Budget, Goal, Report, and User models
│   ├── providers/            # Auth, Transaction, Budget, Goal, Report, Language & Theme providers
│   ├── screens/
│   │   ├── auth/             # Login & Registration screens
│   │   ├── budgets/          # Budgets & Limits screens and dialogs
│   │   ├── dashboard/        # Dashboard overview & charts
│   │   ├── goals/            # Savings Goals screens and deposit sheets
│   │   ├── profile/          # Profile details, settings, and account switcher
│   │   ├── reports/          # Financial Analytics & Statement exports
│   │   ├── splash/           # Luxury Purple Gradient Splash screen
│   │   └── transactions/     # Itemized transactions list & filters
│   ├── widgets/              # Reusable UI cards, drawer, switcher sheets, avatars
│   └── main.dart             # Application root & MultiProvider initialization
├── web/                      # Web entrypoint, manifest, favicon & splash screen
└── pubspec.yaml              # Package dependencies and asset declarations
```

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

<p align="center">
  Made with ❤️ by <b>FinanceTracker Team</b>
</p>
