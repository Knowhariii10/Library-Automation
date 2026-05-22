# Admin Portal & Backend Walkthrough

The **Admin Portal (React)** and **Backend (Flask)** have been successfully implemented. This system provides a comprehensive solution for managing library operations, including book tracking, rentals, reservations, and multi-purpose QR scanning.

## 🚀 Getting Started

### 1. Backend Setup

1.  **Navigate directly to the backend folder:**
    ```bash
    cd backend
    ```

2.  **Install Python dependencies:**
    ```bash
    pip install -r requirements.txt
    ```

3.  **Configure Environment:**
    - Rename `.env.example` to `.env`.
    - Update `MONGO_URI` if your MongoDB is not running on localhost.

4.  **Create an Admin User:**
    You need at least one admin user to log in. Run this Python script to create one:
    ```python
    # create_admin.py
    from pymongo import MongoClient
    from werkzeug.security import generate_password_hash
    from datetime import datetime

    client = MongoClient('mongodb://localhost:27017/')
    db = client['library_management']
    
    db.admin_login.insert_one({
        "email": "admin@example.com",
        "password_hash": generate_password_hash("admin123"),
        "name": "Super Admin",
        "role": "admin",
        "created_at": datetime.utcnow(),
        "is_active": True
    })
    print("Admin user created!")
    ```

5.  **Run the Server:**
    ```bash
    python app.py
    ```
    Server runs at `http://localhost:5000`.

### 2. Admin Portal Setup

1.  **Navigate to the admin-portal folder:**
    ```bash
    cd admin-portal
    ```

2.  **Install Dependencies:**
    ```bash
    npm install
    ```

3.  **Start Development Server:**
    ```bash
    npm run dev
    ```
    App runs at `http://localhost:5173`.

---

## 🌟 Key Features Implemented

### 1. Authentication
- Secure **Admin Login** using JWT.
- Automatic token expiration (24 hours).
- **Protected Routes** ensure only authenticated admins can access the dashboard.

### 2. Dashboard
- Real-time statistics:
  - Total Books
  - Currently Rented
  - Overdue Items
  - Active Reservations
  - Today's Attendance

### 3. Book Management
- **List View**: Paginated table of all books.
- **Add Book**:
  - Manual entry.
  - **Barcode Scanner** integration for quick entry.
  - **Image Upload** support.
- **Search**: Filter by title, author, or barcode.

### 4. Smart QR Scanner
The `/scanner` page is a full-screen, multi-purpose tool that handles:
- **Attendance**: Toggles users in/out (`checking_for_attendance` collection).
- **Renting**: Validates limits and creates rental records.
- **Returning**: Calculates fines automatically and updates inventory.
- **Transactions**: Look up past transaction details.

### 5. Overdue & Fines
- Tracks overdue books automatically via backend cron jobs.
- **Notify All**: One-click button to send reminders.
- Fine calculation logic based on configurable daily rates.

### 6. Reservations
- View active reservations.
- Auto-expiry logic (removes expired reservations hourly).
- Manual cancellation option.

---

## 🧪 Verification & Testing

### Manual Testing Steps

1.  **Login**:
    - Go to `/login`.
    - Enter `admin@example.com` / `admin123`.
    - Verify redirection to `/dashboard`.

2.  **Scan a Book**:
    - Go to **Books** → **Add Book**.
    - Click the Camera icon to scan a barcode.
    - Verify the barcode field is populated.

3.  **Test QR Scanner Logic**:
    - Go to **Scanner**.
    - Show an Attendance QR (JSON format): `{"purpose": "ATTENDANCE", "user_id": "..."}`.
    - Verify success message and database update.

4.  **Check Overdue**:
    - Go to **Overdue**.
    - Verify the calculation of fines for late books.
    - Click **Notify All** and check backend logs for "Notifications sent".

---

## 📂 Project Structure

### Backend (`/backend`)
- `app.py`: Entry point.
- `models/`: 10 MongoDB collection schemas.
- `routes/`: API endpoints (`admin`, `auth`, `scanner`).
- `utils/`: Logic for fines, QR handling, and scheduler.

### Frontend (`/admin-portal`)
- `src/pages/`: React components for each view.
- `src/services/`: Axios setup with JWT interceptors.
- `src/components/`: Reusable UI (Layout, Navbar, ProtectedRoute).
- `src/styles/`: Global CSS variables for theming.
