# 📚 Intelligent Library Automation System

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![React](https://img.shields.io/badge/React-20232A?style=for-the-badge&logo=react&logoColor=61DAFB)](https://reactjs.org)
[![Flask](https://img.shields.io/badge/Flask-000000?style=for-the-badge&logo=flask&logoColor=white)](https://flask.palletsprojects.com/)
[![MongoDB](https://img.shields.io/badge/MongoDB-47A248?style=for-the-badge&logo=mongodb&logoColor=white)](https://www.mongodb.com/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

An advanced, end-to-end full-stack ecosystem designed to modernize library resource tracking, fine management, and user interactions. This project integrates a **cross-platform mobile/desktop client**, an **admin control portal**, and a **robust backend API** with simulated **RFID & Barcode hardware integration**.

---

## 🏗️ System Architecture

This ecosystem is composed of four specialized modules working in harmony:

```
                  ┌────────────────────────┐
                  │   React Admin Portal   │
                  │   (Vite Dashboard)     │
                  └───────────┬────────────┘
                              │ API Calls
                              ▼
┌──────────────┐    ┌──────────────────┐    ┌─────────────────┐
│ Student App  ├───>│ Flask REST API   │<───┤   RFID Gate     │
│ (Flutter)    │    │ (Backend Engine) │    │  (Simulation)   │
└──────────────┘    └────────┬─────────┘    └─────────────────┘
                             │ DB Queries
                             ▼
                    ┌──────────────────┐
                    │  MongoDB Atlas   │
                    └──────────────────┘
```

---

## ✨ Features by Module

### 📱 1. Student App (`Student-app`) — *Flutter*
* **Cross-Platform**: Compiles seamlessly to Android, iOS, Windows, macOS, and Web.
* **Smart Search**: Quickly find books, check real-time availability, and view ratings.
* **Borrowing History**: Track active rentals, past history, and due dates.
* **Profile & Fines**: View library profile details, active reservation statuses, and outstanding fines.

### 💻 2. Admin Portal (`admin-portal`) — *React & Vite*
* **Dynamic Dashboard**: Visual overview of library metrics (total books, active loans, overdue items).
* **Book & Copy Management**: Full CRUD operations for books and individual physical copies.
* **Reservation Approval & Returns**: Complete cycle handling with virtual scanner integration.
* **Fine Processing**: Automatically tracks, updates, and records fine balances.

### ⚙️ 3. Backend Engine (`backend`) — *Python & Flask*
* **Secure API**: Protected routes powered by JWT (JSON Web Tokens).
* **Automated Scheduler**: Background tasks that calculate daily fines for overdue books.
* **Database Driver**: MongoDB abstraction with custom script routines for cleanup and data migrations.

### 🚥 4. RFID Gate simulation (`rf-gate`) — *HTML5 & JS*
* Simulates physical security gates at library entry/exit points.
* Emits audio alarms and flags unauthorized checkouts instantly.

---

## 🛠️ Technology Stack

* **Frontend Dashboard**: React.js, Vite, CSS3
* **Mobile / Desktop App**: Dart, Flutter SDK
* **Backend API**: Python, Flask, PyMongo, JWT
* **Database**: MongoDB (NoSQL)
* **Testing & Tools**: Git, REST client verification scripts

---

## 🚀 Quick Start & Installation

### Prerequisites
* Python 3.10+
* Node.js & npm
* Flutter SDK
* MongoDB Local or Atlas Instance

### 1. Run the Backend Server
```bash
cd backend
pip install -r requirements.txt
# Configure your MongoDB URI in backend/.env
python app.py
```

### 2. Start the Admin Dashboard
```bash
cd admin-portal
npm install
npm run dev
```

### 3. Build & Run the Student App
```bash
cd Student-app
flutter pub get
flutter run
```

---

## 📝 License

Distributed under the MIT License. See `LICENSE` for more information.
