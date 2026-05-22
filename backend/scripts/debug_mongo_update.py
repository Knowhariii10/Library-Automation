"""
Simple debug script to test MongoDB update
"""

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from pymongo import MongoClient
from bson import ObjectId
from config import Config
from datetime import datetime

# Connect to database
client = MongoClient(Config.MONGO_URI)
db = client[Config.DB_NAME]

# Create a test book
test_book = {
    'title': 'Debug Test Book',
    'copies': [
        {'barcode': 'DEBUG001', 'rfid': 'DEBUGRFID001', 'issued_to': None}
    ],
    'updated_at': datetime.now()
}

book_id = db.books.insert_one(test_book).inserted_id
print(f"Created book: {book_id}")

# Try to update it
test_user_id = ObjectId()
print(f"Test user ID: {test_user_id}, type: {type(test_user_id)}")

filter_query = {
    '_id': book_id,
    'copies': {'$elemMatch': {'rfid': 'DEBUGRFID001', 'issued_to': None}}
}

print(f"\nFilter query: {filter_query}")

result = db.books.update_one(
    filter_query,
    {'$set': {'copies.$.issued_to': test_user_id, 'updated_at': datetime.now()}}
)

print(f"Matched: {result.matched_count}, Modified: {result.modified_count}")

# Fetch the book again
updated_book = db.books.find_one({'_id': book_id})
print(f"\nUpdated book copies:")
for copy in updated_book.get('copies', []):
    print(f"  RFID: {copy.get('rfid')}, issued_to: {copy.get('issued_to')}, type: {type(copy.get('issued_to'))}")

# Cleanup
db.books.delete_one({'_id': book_id})
print("\nCleaned up test book")
