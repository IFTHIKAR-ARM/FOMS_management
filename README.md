# 🍽️ FOMS - Food Order Management System
### *Next-Gen Liquid OS & Frosted Glass Food Management Platform*

[![Flutter](https://img.shields.io/badge/Flutter-3.47.2-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Node.js](https://img.shields.io/badge/Node.js-18+-339933?style=for-the-badge&logo=nodedotjs&logoColor=white)](https://nodejs.org)
[![MySQL](https://img.shields.io/badge/MySQL-MariaDB-4479A1?style=for-the-badge&logo=mysql&logoColor=white)](https://www.mysql.com)
[![License](https://img.shields.io/badge/License-MIT-blue?style=for-the-badge)](LICENSE)

---

## ✨ Overview

**FOMS (Food Order Management System)** is a comprehensive food ordering and kitchen dispatch management solution featuring a futuristic **Liquid Glass / Liquid OS** user interface. Built with Flutter for cross-platform frontend fluidity and a Node.js + MySQL backend, it seamlessly connects customers, restaurant administrators, and delivery riders in real time.

---

## 🎨 Liquid OS UI Aesthetics

- **💧 Multi-Layered Specular Glass:** Real-time Gaussian blur (`BackdropFilter`, $\sigma = 28-36$) with curved surface specular highlights, directional gradient borders, and ambient backglow.
- **🌌 4-Point Animated Mesh Aurora:** Smooth sinusoidal breathing orbital mesh in Electric Sapphire, Neon Cyan, Radiant Magenta/Violet, and Sunset Amber.
- **🏝️ Dynamic Island Cart:** Floating pill bar at the bottom with real-time price updates and spring bounce physics.
- **⚡ Tactile Liquid Buttons:** Glossy capsule buttons with moving reflection light highlights and interactive touch feedback.
- **🔄 Sliding Water-Pill Selectors:** Fluid spring-animated segmented role and category switchers.

---

## 🚀 Key Features

### 👤 Customer Portal
- 🍱 **Explore Menu:** Rich liquid food cards with interactive quantity steppers (`-` / `+`).
- 🔍 **Live Search:** Instant filtering across food categories, rice dishes, and curries.
- 🛒 **Dynamic Cart & Checkout:** Floating liquid cart pill with address auto-fill and instant order confirmation.
- 📦 **Order Tracking:** Real-time order timeline with status color codes and cancellation requests.

### 🛡️ Admin & Kitchen Operations
- 📊 **Live Order Queue:** Stream of incoming orders with filters (`Pending`, `Preparing`, `Out for Delivery`, `Delivered`, `Canceled`).
- 🔄 **Status Management:** Single-click status update dropdown.
- ⚠️ **Cancel Approval:** One-tap approval or rejection of customer cancellation requests.
- 👥 **User Account Control:** Role switching (`Customer`, `Delivery`, `Admin`) and account deletion.

### 🛵 Delivery Dispatch Partner
- 🟢 **Online/Offline Switch:** Real-time dispatch availability toggle with glowing power badge.
- 📋 **Active Deliveries:** Filter orders by `Assigned & Active`, `Completed`, or `All`.
- 🚀 **One-Tap Actions:** Update order status from `Preparing` ➔ `Out for Delivery` ➔ `Delivered`.

---

## 📁 Repository Structure

```
FOMS/
├── api/                    # Node.js REST API route handlers
│   └── unified.js          # Authentication, orders, menu & user management
├── database/               # Database schemas & seed files
│   └── food_system.sql     # MySQL database structure & demo data
├── foms_app/               # Flutter cross-platform client
│   ├── lib/
│   │   ├── models/         # Data models (MenuItem, Order, AdminOrder, User)
│   │   ├── screens/
│   │   │   ├── admin/      # Admin dashboard & kitchen queue
│   │   │   ├── auth/       # Liquid Login, Register & Admin Portal
│   │   │   ├── customer/   # Food menu, cart & order history
│   │   │   └── delivery/   # Dispatch routes & delivery tracking
│   │   ├── services/       # REST API & session persistence
│   │   └── widgets/        # LiquidGlassCard, LiquidButton, PremiumBackground
│   └── pubspec.yaml        # Flutter dependencies
├── server.js               # Express API entrypoint (Port 3000)
└── README.md
```

---

## ⚙️ Installation & Setup

### Prerequisites
- [Node.js (v18+)](https://nodejs.org/)
- [XAMPP](https://www.apachefriends.org/) (Apache & MySQL)
- [Flutter SDK (3.47+)](https://flutter.dev/docs/get-started/install)

---

### 1. Database Setup
1. Start **MySQL** in the XAMPP Control Panel.
2. Open [phpMyAdmin](http://localhost/phpmyadmin) or MySQL CLI:
3. Create database and import schema:
   ```sql
   CREATE DATABASE food_system;
   ```
4. Import `database/food_system.sql` into `food_system`.

---

### 2. Backend Server Setup
```bash
# Navigate to the root directory
cd c:\xampp\htdocs\FOMS

# Install backend dependencies
npm install

# Start the API server
node server.js
```
*API will run on:* `http://localhost:3000`

---

### 3. Flutter Frontend Setup
```bash
# Navigate to the Flutter app directory
cd foms_app

# Fetch dependencies
flutter pub get

# Run on Chrome / Web
flutter run -d chrome

# Or run on Windows Desktop
flutter run -d windows
```

---

## 🔑 Default Credentials

| Role | Identifier / Username | Password |
| :--- | :--- | :--- |
| **Admin** | `restaurant` *(or `0771669638`)* | `123456` |
| **Customer** | *(Register new in-app)* | *(Your password)* |
| **Delivery** | *(Register as Delivery in-app)* | *(Your password)* |

---

## 🛠️ Tech Stack

- **Frontend:** Flutter, Dart, BackdropFilter Glassmorphism, Material 3
- **Backend:** Node.js, Express.js, CORS
- **Database:** MariaDB / MySQL (`mysql2/promise`)
- **State & Storage:** SharedPreferences Session Management

---

## 📄 License
This project is open-source and available under the [MIT License](LICENSE).
