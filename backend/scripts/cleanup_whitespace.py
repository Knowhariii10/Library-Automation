import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from pymongo import MongoClient
from config import Config

client = MongoClient(Config.MONGO_URI)
db = client[Config.DB_NAME]

print("=" * 60)
print("CLEANING UP WHITESPACE IN RFIDs AND BARCODES")
print("=" * 60)

books = db.books.find({})
total_books_updated = 0
total_copies_fixed = 0

for book in books:
    book_id = book['_id']
    title = book.get('title', 'Unknown')
    copies = book.get('copies', [])
    modified = False
    
    for copy in copies:
        rfid = copy.get('rfid')
        barcode = copy.get('barcode')
        
        if isinstance(rfid, str) and rfid != rfid.strip():
            print(f"Fixed RFID for '{title}': '{rfid}' -> '{rfid.strip()}'")
            copy['rfid'] = rfid.strip()
            total_copies_fixed += 1
            modified = True
            
        if isinstance(barcode, str) and barcode != barcode.strip():
            print(f"Fixed Barcode for '{title}': '{barcode}' -> '{barcode.strip()}'")
            copy['barcode'] = barcode.strip()
            total_copies_fixed += 1
            modified = True
            
    if modified:
        db.books.update_one({'_id': book_id}, {'$set': {'copies': copies}})
        total_books_updated += 1

print("\n" + "=" * 60)
print(f"Cleanup complete!")
print(f"Books updated: {total_books_updated}")
print(f"Copies fixed: {total_copies_fixed}")
print("=" * 60)
