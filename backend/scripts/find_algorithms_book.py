import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from pymongo import MongoClient
from config import Config

client = MongoClient(Config.MONGO_URI)
search_title = "Introduction to Algorithms"

for db_name in client.list_database_names():
    db = client[db_name]
    try:
        book = db.books.find_one({'title': {'$regex': search_title, '$options': 'i'}})
        if book:
            print(f"FOUND IN DB: {db_name}")
            print(f"  Title: {book.get('title')}")
            print(f"  ID: {book.get('_id')}")
            print("  COPIES:")
            for c in book.get('copies', []):
                rfid = c.get('rfid')
                print(f"    RFID: '{rfid}' (len={len(rfid if rfid else '')})")
    except:
        pass
