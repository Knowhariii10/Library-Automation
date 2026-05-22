import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from pymongo import MongoClient
from config import Config

client = MongoClient(Config.MONGO_URI)
db = client[Config.DB_NAME]

search_rfid = "1005"
print(f"Searching for RFID: '{search_rfid}' (and versions with spaces)")

books = db.books.find({'copies.rfid': {'$regex': f'^{search_rfid}\\s*$', '$options': 'i'}})

for book in books:
    print(f"BOOK: {book.get('title')} (ID: {book.get('_id')})")
    for c in book.get('copies', []):
        rfid = c.get('rfid')
        if rfid and rfid.strip() == search_rfid:
            print(f"  MATCH: RFID='{rfid}' (len={len(rfid)})")
