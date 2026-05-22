
import os
import sys
from pymongo import MongoClient
from bson import ObjectId

# Add parent directory to path to import config
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from config import Config
from dotenv import load_dotenv

load_dotenv()

def check_barcode(barcode):
    try:
        mongo_uri = os.getenv('MONGO_URI', Config.MONGO_URI)
        db_name = os.getenv('DB_NAME', Config.DB_NAME)
        
        client = MongoClient(mongo_uri)
        db = client[db_name]
        
        print(f"Connected to database: {db_name}")
        print(f"Searching for barcode: {barcode}")
        
        # Check ISBN
        book_by_isbn = db.books.find_one({'isbn': barcode})
        if book_by_isbn:
            print(f"FOUND by ISBN: {book_by_isbn.get('title')} (ID: {book_by_isbn.get('_id')})")
            return

        # Check copies.barcode
        book_by_copy = db.books.find_one({'copies.barcode': barcode})
        if book_by_copy:
            print(f"FOUND by Copy Barcode: {book_by_copy.get('title')} (ID: {book_by_copy.get('_id')})")
            # Find specific copy
            for copy in book_by_copy.get('copies', []):
                if copy.get('barcode') == barcode:
                    print(f"  Copy Details: {copy}")
                    print(f"  Barcode Type: {type(copy.get('barcode'))}")
            return

        print("NOT FOUND in database.")
        
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    if len(sys.argv) > 1:
        barcode = sys.argv[1]
    else:
        barcode = "8796516467874"
    check_barcode(barcode)
