import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from pymongo import MongoClient
from bson import ObjectId
from config import Config

client = MongoClient(Config.MONGO_URI)
db = client[Config.DB_NAME]

print("Searching for 'Introduction to Algorithms'...")
book = db.books.find_one({'title': {'$regex': 'Introduction to Algorithms', '$options': 'i'}})

if book:
    print(f"TITLE: {book.get('title')}")
    print(f"ID: {book.get('_id')}")
    print("COPIES:")
    for c in book.get('copies', []):
        print(f"  RFID: {c.get('rfid')} ({type(c.get('rfid'))}), Barcode: {c.get('barcode')}, Issued To: {c.get('issued_to')} ({type(c.get('issued_to'))})")
else:
    print("Book not found")

print("\nRecent Transactions for RFID 1005:")
# Search for any recent activity with this book
recent_tx = db.transactions.find({'items.rfid': '1005'}).sort('_id', -1).limit(5)
for tx in recent_tx:
    print(f"TX {tx.get('_id')}: Status={tx.get('status')}, Type={tx.get('type')}, User={tx.get('user_id')}")
