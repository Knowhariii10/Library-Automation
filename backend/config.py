import os
from dotenv import load_dotenv

load_dotenv()

class Config:
    # MongoDB Configuration
    MONGO_URI = os.getenv('MONGO_URI', 'mongodb://localhost:27017/')
    DB_NAME = os.getenv('DB_NAME', 'library_management')
    GUEST_DB_NAME = os.getenv('GUEST_DB_NAME', 'guest_management')
    
    # JWT Configuration
    JWT_SECRET_KEY = os.getenv('JWT_SECRET_KEY', 'your-secret-key-change-in-production')
    JWT_ALGORITHM = 'HS256'
    JWT_EXPIRATION_HOURS = 24
    
    # Application Configuration
    DEBUG = os.getenv('DEBUG', 'True') == 'True'
    HOST = os.getenv('HOST', '0.0.0.0')
    PORT = int(os.getenv('PORT', 5001))
    
    # CORS Configuration
    CORS_ORIGINS = os.getenv('CORS_ORIGINS', '*').split(',')
    
    # File Upload Configuration
    UPLOAD_FOLDER = os.path.join(os.path.dirname(__file__), 'books_img')
    MAX_CONTENT_LENGTH = 16 * 1024 * 1024  # 16MB max file size
    ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif'}
    
    # Fine Configuration
    FINE_PER_DAY = float(os.getenv('FINE_PER_DAY', 5.0))  # ₹5 per day
    
    # Rental Configuration
    MAX_BOOKS_PER_RENTAL = int(os.getenv('MAX_BOOKS_PER_RENTAL', 3))
    RENTAL_DURATION_DAYS = int(os.getenv('RENTAL_DURATION_DAYS', 14))
    
    # Reservation Configuration
    RESERVATION_EXPIRY_HOURS = int(os.getenv('RESERVATION_EXPIRY_HOURS', 1)) # Explicitly 1 hour

    # Email Configuration (Flask-Mail standard)
    MAIL_SERVER = os.getenv('MAIL_SERVER', 'smtp.gmail.com')
    MAIL_PORT = int(os.getenv('MAIL_PORT', 587))
    MAIL_USE_TLS = os.getenv('MAIL_USE_TLS', 'True') == 'True'
    MAIL_USERNAME = os.getenv('MAIL_USERNAME', 'gcedpilibrary6135@gmail.com')
    MAIL_PASSWORD = os.getenv('MAIL_PASSWORD', 'cidfpufwcwzdtvfn')
    MAIL_DEFAULT_SENDER = (
        os.getenv('EMAIL_FROM_NAME', 'Library Management System'),
        os.getenv('MAIL_USERNAME', 'gcedpilibrary6135@gmail.com')
    )

    # SMTP Configuration Aliases (for notification_service.py)
    EMAIL_FROM_NAME = os.getenv('EMAIL_FROM_NAME', 'Library Management System')
    SMTP_SERVER = MAIL_SERVER
    SMTP_PORT = MAIL_PORT
    SMTP_USER = MAIL_USERNAME
    SMTP_PASSWORD = MAIL_PASSWORD
    
    @staticmethod
    def init_app():
        """Initialize application directories"""
        os.makedirs(Config.UPLOAD_FOLDER, exist_ok=True)
