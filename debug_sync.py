import requests
import jwt
from datetime import datetime, timedelta
import json

# Configuration (copied from backend/config.py)
JWT_SECRET_KEY = 'change-this-to-a-secure-random-string-in-production'
JWT_ALGORITHM = 'HS256'
BASE_URL = 'http://localhost:5001'

def generate_user_token(user_id, email):
    payload = {
        'user_id': str(user_id),
        'email': email,
        'exp': datetime.utcnow() + timedelta(hours=24),
        'iat': datetime.utcnow()
    }
    return jwt.encode(payload, JWT_SECRET_KEY, algorithm=JWT_ALGORITHM)

# User ID for Nandhini from check_db.py
user_id = '6981c4b1f21ca9af48a9b3a0'
email = 'nandhininambi85@gmail.com'

token = generate_user_token(user_id, email)
print(f"Token: {token[:20]}...")

headers = {
    'Authorization': f'Bearer {token}',
    'Content-Type': 'application/json'
}

print(f"Calling {BASE_URL}/auth/admin/student/sync...")
try:
    response = requests.get(f"{BASE_URL}/auth/admin/student/sync", headers=headers)
    print(f"Status: {response.statusCode if hasattr(response, 'statusCode') else response.status_code}")
    data = response.json()
    
    if data.get('success'):
        reservations = data.get('reservations', [])
        print(f"Success! Received {len(reservations)} reservations.")
        for res in reservations:
            print(f"- {res.get('book_title')} (Status: {res.get('status')}, Expires: {res.get('expires_at')})")
    else:
        print(f"Error: {data.get('error', 'Unknown error')}")
except Exception as e:
    print(f"Failed to call sync: {e}")
