import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from pymongo import MongoClient
from config import Config

client = MongoClient(Config.MONGO_URI)
db = client[Config.DB_NAME]
book = db.books.find_one({'title': 'Elements of Mechanical Engineering'})

if book:
    print(f"TITLE: {book['title']}")
    print("COPIES:")
    for c in book.get('copies', []):
        rfid = c.get('rfid')
        barcode = c.get('barcode')
        print(f"  RFID: {rfid} ({type(rfid)}), Barcode: {barcode} ({type(barcode)}), Issued To: {c.get('issued_to')}")
else:
    print("Book not found")
