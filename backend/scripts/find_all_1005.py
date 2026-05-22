import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from pymongo import MongoClient
from bson import ObjectId
from config import Config

client = MongoClient(Config.MONGO_URI)
db = client[Config.DB_NAME]

search_rfid = "1005"
print(f"Searching for RFID: '{search_rfid}' (and variants)")

books = db.books.find({})
total_matches = 0

for book in books:
    copies = book.get('copies', [])
    for c in copies:
        rfid = c.get('rfid')
        if rfid and rfid.strip() == search_rfid:
            print(f"MATCH FOUND!")
            print(f"  Book: {book.get('title')} (ID: {book.get('_id')})")
            print(f"  Copy RFID: '{rfid}' (len={len(rfid)})")
            print(f"  Issued To: {c.get('issued_to')}")
            total_matches += 1

print(f"\nTotal matches found: {total_matches}")
