import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from pymongo import MongoClient
from bson import ObjectId
from config import Config

client = MongoClient(Config.MONGO_URI)
db = client[Config.DB_NAME]

book_id = ObjectId('698cef56e0a893f7e0699297')
book = db.books.find_one({'_id': book_id})

if book:
    print(f"TITLE: {book.get('title')}")
    for i, copy in enumerate(book.get('copies', [])):
        rfid = copy.get('rfid')
        print(f"Copy {i} RFID: '{rfid}' (len={len(rfid if rfid else '')})")
        if rfid:
            print(f"  Hex: {rfid.encode('utf-8').hex()}")
            print(f"  Chars: {[ord(c) for c in rfid]}")
else:
    print("Book not found")
