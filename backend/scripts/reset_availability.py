
from pymongo import MongoClient
import os
import sys

# Add parent directory to path to import config
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from config import Config
from dotenv import load_dotenv

load_dotenv()

def reset_books():
    try:
        mongo_uri = os.getenv('MONGO_URI', 'mongodb://localhost:27017/')
        db_name = os.getenv('DB_NAME', 'library_management')
        
        client = MongoClient(mongo_uri)
        db = client[db_name]
        
        print(f"Connected to database: {db_name}")
        
        # 1. Reset 'issued_to' in books collection
        print("Resetting 'issued_to' for all book copies...")
        result = db.books.update_many(
            {},
            {'$set': {'copies.$[].issued_to': None}}
        )
        print(f"Updated books: {result.modified_count} documents modified.")
        
        # 2. Optional: Mark all active rentals as RETURNED?
        # The user specifically asked for "issued to null".
        # If we leave rentals as ACTIVE, they will be inconsistent (Rental ACTIVE but Book AVAILABLE).
        # This might cause issues next time they try to rent/return.
        # But for now, let's just do what was asked to "clear" the book status.
        
        print("Done! All books are now marked as available (issued_to: null).")
        
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    reset_books()
