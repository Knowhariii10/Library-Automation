from werkzeug.security import check_password_hash, generate_password_hash
from bson import ObjectId
from datetime import datetime
import re

class UserModel:
    def __init__(self, db):
        self.collection = db.users
    
    def find_by_email(self, email):
        return self.collection.find_one({'email': {'$regex': f'^{re.escape(email)}$', '$options': 'i'}})
    
    def find_by_id(self, user_id):
        return self.collection.find_one({'_id': ObjectId(user_id)})
    
    def find_by_student_id(self, student_id):
        return self.collection.find_one({'student_id': {'$regex': f'^{re.escape(student_id)}$', '$options': 'i'}})
    
    def create(self, user_data):
        is_guest = user_data.get('is_guest', False)
        password = user_data.get('password', 'guest123') # Default password for guests
        
        user = {
            'name': user_data['name'],
            'email': user_data['email'],
            'password_hash': generate_password_hash(password),
            'student_id': user_data.get('student_id', ''),
            'department': user_data.get('department', ''),
            'year': user_data.get('year', ''),
            'phone': user_data.get('phone', ''),
            'purpose': user_data.get('purpose', ''),
            'is_guest': is_guest,
            'created_at': datetime.now(),
            'is_active': True
        }
        result = self.collection.insert_one(user)
        return result.inserted_id
    
    def verify_password(self, user, password):
        if 'password_hash' not in user:
            return False
        return check_password_hash(user['password_hash'], password)
    
    def to_dict(self, user):
        if not user:
            return None
        return {
            'id': str(user['_id']),
            'name': user['name'],
            'email': user['email'],
            'student_id': user.get('student_id', ''),
            'department': user.get('department', ''),
            'year': user.get('year', ''),
            'phone': user.get('phone', ''),
            'purpose': user.get('purpose', ''),
            'is_guest': user.get('is_guest', False),
            'created_at': user.get('created_at', datetime.now()).isoformat()
        }

    def set_otp(self, user_id, otp):
        """Set OTP and expiry (10 minutes) for a user"""
        from datetime import timedelta
        expiry = datetime.now() + timedelta(minutes=10)
        self.collection.update_one(
            {'_id': ObjectId(user_id)},
            {'$set': {
                'otp': otp,
                'otp_expiry': expiry
            }}
        )

    def verify_otp(self, user_id, otp):
        """Verify if the OTP is correct and not expired"""
        user = self.collection.find_one({
            '_id': ObjectId(user_id),
            'otp': otp,
            'otp_expiry': {'$gt': datetime.now()}
        })
        return user is not None

    def reset_password(self, user_id, new_password):
        """Reset password and clear OTP"""
        self.collection.update_one(
            {'_id': ObjectId(user_id)},
            {
                '$set': {'password_hash': generate_password_hash(new_password)},
                '$unset': {'otp': "", 'otp_expiry': ""}
            }
        )
