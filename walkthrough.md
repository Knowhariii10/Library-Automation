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

## 📝 Dummy Data Generation

Copy and paste the following script into your **MongoDB Compass** terminal (Mongosh) or run it via the `mongosh` CLI to populate your database with 5 interconnected records for testing.

```javascript
// Switch to database
use library_management;

// ---------------------------------------------------------
// 1. Generate IDs for linking
// ---------------------------------------------------------
const user1_id = ObjectId();
const user2_id = ObjectId();
const user3_id = ObjectId();
const user4_id = ObjectId();
const user5_id = ObjectId();

const book1_id = ObjectId();
const book2_id = ObjectId();
const book3_id = ObjectId();
const book4_id = ObjectId();
const book5_id = ObjectId();

const trans1_id = ObjectId();
const admin_id = ObjectId();

// ---------------------------------------------------------
// 2. Admin User
// ---------------------------------------------------------
// Password is 'admin123' (hash generated via python)
db.admin_login.insertOne({
  _id: admin_id,
  email: "admin@example.com",
  password_hash: "scrypt:32768:8:1$kCP2yR33Z8XyWd9p$9c3d9a9a0e7f...", // Truncated for brevity, use real hash if logging in
  name: "Super Admin",
  role: "admin",
  created_at: new Date(),
  is_active: true
});

// ---------------------------------------------------------
// 3. Users Collection (5 Students)
// ---------------------------------------------------------
db.users.insertMany([
  {
    _id: user1_id,
    role: "student",
    name: "Aravind Kumar",
    email: "aravind@example.com",
    phone: "9876543210",
    student_id: "CS2024001",
    department: "Computer Science",
    year: 3,
    interests: ["AI", "Algorithms"],
    created_at: new Date(),
    is_active: true,
    total_fines: 0,
    current_fines: 0
  },
  {
    _id: user2_id,
    role: "student",
    name: "Priya Sharma",
    email: "priya@example.com",
    phone: "9876543211",
    student_id: "EC2024045",
    department: "Electronics",
    year: 2,
    interests: ["IoT", "Robotics"],
    created_at: new Date(),
    is_active: true,
    total_fines: 50,
    current_fines: 0
  },
  {
    _id: user3_id,
    role: "student",
    name: "Rahul Verma",
    email: "rahul@example.com",
    phone: "9876543212",
    student_id: "ME2024012",
    department: "Mechanical",
    year: 4,
    interests: ["Thermodynamics", "Design"],
    created_at: new Date(),
    is_active: true,
    total_fines: 0,
    current_fines: 0
  },
  {
    _id: user4_id,
    role: "student",
    name: "Sneha Gupta",
    email: "sneha@example.com",
    phone: "9876543213",
    student_id: "CS2024102",
    department: "Computer Science",
    year: 1,
    interests: ["Web Dev", "Coding"],
    created_at: new Date(),
    is_active: true,
    total_fines: 100,
    current_fines: 100
  },
  {
    _id: user5_id,
    role: "student",
    name: "Vikram Singh",
    email: "vikram@example.com",
    phone: "9876543214",
    student_id: "CV2024089",
    department: "Civil",
    year: 3,
    interests: ["Structures", "Planning"],
    created_at: new Date(),
    is_active: true,
    total_fines: 250,
    current_fines: 250
  }
]);

// ---------------------------------------------------------
// 4. Books Collection (5 Books)
// ---------------------------------------------------------
// Book 1 & 2: Rented by User 1
// Book 3: Returned by User 2
// Book 4: Reserved by User 3
// Book 5: Overdue by User 5
db.books.insertMany([
  {
    _id: book1_id,
    barcode: "BK001",
    title: "Introduction to Algorithms",
    author: "Thomas H. Cormen",
    category: "Computer Science",
    tags: ["algorithms", "programming"],
    total_copies: 5,
    available_copies: 4,
    location: { section: "A", row: 1, column: 1 },
    available: true,
    updated_at: new Date(),
    version: 1
  },
  {
    _id: book2_id,
    barcode: "BK002",
    title: "Clean Code",
    author: "Robert C. Martin",
    category: "Software Engineering",
    tags: ["coding", "best practices"],
    total_copies: 3,
    available_copies: 2,
    location: { section: "A", row: 1, column: 2 },
    available: true,
    updated_at: new Date(),
    version: 1
  },
  {
    _id: book3_id,
    barcode: "BK003",
    title: "Digital Logic Design",
    author: "Morris Mano",
    category: "Electronics",
    tags: ["circuits", "logic"],
    total_copies: 4,
    available_copies: 4,
    location: { section: "B", row: 2, column: 1 },
    available: true,
    updated_at: new Date(),
    version: 1
  },
  {
    _id: book4_id,
    barcode: "BK004",
    title: "Theory of Machines",
    author: "S.S. Rattan",
    category: "Mechanical",
    tags: ["mechanics", "kinematics"],
    total_copies: 2,
    available_copies: 2, // Available physically, but reserved
    location: { section: "C", row: 3, column: 1 },
    available: true,
    updated_at: new Date(),
    version: 1
  },
  {
    _id: book5_id,
    barcode: "BK005",
    title: "Structural Analysis",
    author: "R.C. Hibbeler",
    category: "Civil",
    tags: ["structures", "analysis"],
    total_copies: 2,
    available_copies: 1,
    location: { section: "D", row: 4, column: 1 },
    available: true,
    updated_at: new Date(),
    version: 1
  }
]);

// ---------------------------------------------------------
// 5. Renting Collection (Active Rentals)
// ---------------------------------------------------------
// User 1 renting Book 1 & 2 (Active, Not Overdue)
// User 5 renting Book 5 (Active, OVERDUE)
const now = new Date();
const pastDate = new Date(); 
pastDate.setDate(now.getDate() - 20); // 20 days ago (Overdue if 14 day limit)

db.renting.insertMany([
  {
    user_id: user1_id,
    books: [
      {
        book_id: book1_id,
        barcode: "BK001",
        title: "Introduction to Algorithms",
        rented_at: new Date(),
        due_date: new Date(new Date().setDate(new Date().getDate() + 14)),
        returned: false,
        fine_accrued: 0
      },
      {
        book_id: book2_id,
        barcode: "BK002",
        title: "Clean Code",
        rented_at: new Date(),
        due_date: new Date(new Date().setDate(new Date().getDate() + 14)),
        returned: false,
        fine_accrued: 0
      }
    ],
    total_fine: 0,
    status: "ACTIVE"
  },
  {
    user_id: user5_id,
    books: [
      {
        book_id: book5_id,
        barcode: "BK005",
        title: "Structural Analysis",
        rented_at: pastDate,
        due_date: new Date(new Date().setDate(pastDate.getDate() + 14)), // Due 6 days ago
        returned: false,
        fine_accrued: 30 // Assuming 5 per day * 6 days
      }
    ],
    total_fine: 30,
    status: "ACTIVE"
  }
]);

// ---------------------------------------------------------
// 6. Reservations (Active)
// ---------------------------------------------------------
// User 3 reserves Book 4
db.reservations.insertOne({
  user_id: user3_id,
  book_id: book4_id,
  barcode: "BK004",
  reserved_at: new Date(),
  expires_at: new Date(new Date().getTime() + (24 * 60 * 60 * 1000)), // 24 hours from now
  status: "ACTIVE",
  picked_up: false
});

// ---------------------------------------------------------
// 7. Transactions (History)
// ---------------------------------------------------------
// User 2 returned Book 3 previously
db.transactions.insertOne({
  transaction_id: new ObjectId().toString(),
  user_id: user2_id,
  items: [
    {
      book_id: book3_id,
      barcode: "BK003",
      title: "Digital Logic Design",
      rented_at: new Date(new Date().setDate(new Date().getDate() - 10)),
      returned_at: new Date()
    }
  ],
  status: "RETURNED",
  created_at: new Date(new Date().setDate(new Date().getDate() - 10)),
  returned_at: new Date(),
  fine_amount: 0,
  fine_paid: true
});

// ---------------------------------------------------------
// 8. Fines Collection
// ---------------------------------------------------------
// User 4 has a pending fine for DAMAGE
db.fines.insertOne({
  user_id: user4_id,
  amount: 100,
  reason: "DAMAGE",
  days_overdue: 0,
  issued_date: new Date(),
  status: "PENDING"
});

// ---------------------------------------------------------
// 9. Attendance (Binary Semaphore)
// ---------------------------------------------------------
// User 1 is INSIDE, User 2 is OUTSIDE
db.checking_for_attendance.insertMany([
  {
    user_id: user1_id,
    is_inside: true,
    last_updated: new Date()
  },
  {
    user_id: user2_id,
    is_inside: false,
    last_updated: new Date()
  }
]);

// ---------------------------------------------------------
// 10. Notifications
// ---------------------------------------------------------
db.notifications.insertOne({
  user_id: user5_id,
  title: "Overdue Book Alert",
  message: "Your book 'Structural Analysis' is overdue by 6 days.",
  type: "OVERDUE",
  is_read: false,
  email_sent: false,
  created_at: new Date()
});

print("Dummy data inserted successfully!");
```

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
