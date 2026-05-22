from werkzeug.security import check_password_hash
from bson import ObjectId
from datetime import datetime

class AdminModel:
    def __init__(self, db):
        self.collection = db.admin_login
    
    def find_by_email(self, email):
        """Find admin by email"""
        return self.collection.find_one({'email': email})
    
    def find_by_id(self, admin_id):
        """Find admin by ID"""
        return self.collection.find_one({'_id': ObjectId(admin_id)})
    
    def verify_password(self, admin, password):
        """Verify admin password"""
        return check_password_hash(admin['password_hash'], password)
    
    def is_active(self, admin):
        """Check if admin account is active"""
        return admin.get('is_active', True)
    
    def to_dict(self, admin):
        """Convert admin document to dictionary"""
        if not admin:
            return None
        
        return {
            'id': str(admin['_id']),
            'email': admin['email'],
            'name': admin.get('name', ''),
            'role': admin.get('role', 'admin'),
            'created_at': admin.get('created_at', datetime.now()).isoformat()
        }
