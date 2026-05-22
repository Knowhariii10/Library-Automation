# Library Management System - Backend

Flask backend API for the Library Management System with JWT authentication, QR scanning, and MongoDB integration.

## Features

- ✅ JWT-based authentication for admin users
- ✅ Multi-purpose QR code scanning (attendance, renting, returning, transactions)
- ✅ Book management with barcode support
- ✅ Reservation system with auto-expiry
- ✅ Fine calculation for overdue books
- ✅ Automated daily notifications for overdue books
- ✅ Dashboard statistics
- ✅ RESTful API design

## Prerequisites

- Python 3.8+
- MongoDB 4.0+
- pip (Python package manager)

## Installation

1. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

2. **Configure environment variables:**
   ```bash
   cp .env.example .env
   ```
   
   Edit `.env` and update:
   - `MONGO_URI`: Your MongoDB connection string
   - `JWT_SECRET_KEY`: A secure random string
   - Other configuration as needed

3. **Create admin user in MongoDB:**
   
   First, generate a password hash:
   ```python
   from werkzeug.security import generate_password_hash
   print(generate_password_hash("your_password"))
   ```
   
   Then, add to MongoDB `admin_login` collection:
   ```javascript
   db.admin_login.insertOne({
     email: "admin@example.com",
     password_hash: "<generated_hash>",
     name: "Admin Name",
     role: "admin",
     created_at: new Date(),
     is_active: true
   })
   ```

## Running the Server

```bash
python app.py
```

The server will start on `http://localhost:5000`

## API Endpoints

### Authentication
- `POST /auth/admin/login` - Admin login
- `POST /auth/admin/logout` - Admin logout
- `GET /auth/admin/validate` - Validate JWT token

### Admin Routes (Protected)
- `GET /admin/dashboard/stats` - Get dashboard statistics
- `GET /admin/books` - List all books (with pagination)
- `POST /admin/books/add` - Add new book
- `POST /admin/books/upload_image/<book_id>` - Upload book image
- `PUT /admin/books/update/<id>` - Update book details
- `GET /admin/reservations` - List active reservations
- `DELETE /admin/reservations/cancel/<id>` - Cancel reservation
- `GET /admin/overdue` - List overdue books
- `POST /admin/notify/overdue` - Send overdue notifications
- `POST /admin/fines/waive/<id>` - Waive fine

### Scanner Routes (Protected)
- `POST /admin/scanner/scan_qr` - Scan QR code (multi-purpose)

## QR Code Format

QR codes should contain JSON with the following structure:

### Attendance QR
```json
{
  "purpose": "ATTENDANCE",
  "user_id": "user_object_id"
}
```

### Renting QR
```json
{
  "purpose": "RENTING",
  "user_id": "user_object_id",
  "book_ids": ["book_id_1", "book_id_2"]
}
```

### Returning QR
```json
{
  "purpose": "RETURNING",
  "user_id": "user_object_id",
  "book_ids": ["book_id_1", "book_id_2"]
}
```

### Transaction QR
```json
{
  "purpose": "TRANSACTION",
  "transaction_id": "transaction_id_string"
}
```

## Cron Jobs

The system runs automated tasks:
- **Daily at 9 AM**: Check overdue books and send notifications
- **Hourly**: Expire old reservations

## Project Structure

```
backend/
├── app.py                  # Main application
├── config.py               # Configuration
├── requirements.txt        # Dependencies
├── models/                 # Database models
│   ├── admin_model.py
│   └── book_model.py
├── routes/                 # API routes
│   ├── auth_routes.py
│   ├── admin_routes.py
│   └── scanner_routes.py
├── utils/                  # Utilities
│   ├── jwt_utils.py
│   ├── qr_handler.py
│   ├── fine_calculator.py
│   ├── notification_service.py
│   └── scheduler.py
└── books_img/              # Book images storage
```

## Testing

Test the API with curl:

```bash
# Login
curl -X POST http://localhost:5000/auth/admin/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@example.com","password":"your_password"}'

# Get dashboard stats (replace <TOKEN> with JWT from login)
curl -X GET http://localhost:5000/admin/dashboard/stats \
  -H "Authorization: Bearer <TOKEN>"
```
