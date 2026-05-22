import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from pymongo import MongoClient
from bson import ObjectId
from config import Config
from models.book_model import BookModel

client = MongoClient(Config.MONGO_URI)
db = client[Config.DB_NAME]
book_model = BookModel(db)

barcode = "1005"
print(f"Testing lookup for barcode/RFID: '{barcode}'")

# 1. Try find_by_barcode
book_b = book_model.find_by_barcode(barcode)
if book_b:
    print(f"FOUND BY BARCODE: {book_b.get('title')} (ID: {book_b.get('_id')})")
else:
    print("NOT FOUND BY BARCODE")

# 2. Try find_by_rfid
book_r = book_model.find_by_rfid(barcode)
if book_r:
    print(f"FOUND BY RFID: {book_r.get('title')} (ID: {book_r.get('_id')})")
else:
    print("NOT FOUND BY RFID")

print("\nDirect MongoDB search for any copy with barcode or rfid '1005':")
all_books = db.books.find({
    '$or': [
        {'copies.barcode': barcode},
        {'copies.rfid': barcode}
    ]
})

for b in all_books:
    print(f"BOOK IN DB: {b.get('title')} (ID: {b.get('_id')})")
    for c in b.get('copies', []):
        if c.get('barcode') == barcode or c.get('rfid') == barcode:
            print(f"  MATCHED COPY: Barcode='{c.get('barcode')}', RFID='{c.get('rfid')}'")
