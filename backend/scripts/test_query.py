import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from pymongo import MongoClient
from bson import ObjectId
from config import Config

client = MongoClient(Config.MONGO_URI)
db = client[Config.DB_NAME]

book_id = ObjectId('698cef56e0a893f7e0699297')
user_id = ObjectId('698f167ddf407e1887dcad67')
rfid = '1005'

filter_query = {
    '_id': book_id,
    'copies': {
        '$elemMatch': {
            '$or': [
                {'issued_to': None},
                {'issued_to': user_id}
            ],
            'rfid': rfid
        }
    }
}

print(f"Testing Query: {filter_query}")
book = db.books.find_one(filter_query)

if book:
    print("MATCH FOUND!")
    # Try the update 
    result = db.books.update_one(
        filter_query,
        {'$set': {'copies.$.issued_to': user_id}}
    )
    print(f"Update Result: Matched={result.matched_count}, Modified={result.modified_count}")
else:
    print("MATCH NOT FOUND")
    # Debug: Check why not found
    real_book = db.books.find_one({'_id': book_id})
    if real_book:
        print("Book exists. Checking copies...")
        for i, copy in enumerate(real_book.get('copies', [])):
            print(f"Copy {i}:")
            print(f"  rfid: '{copy.get('rfid')}' ({type(copy.get('rfid'))})")
            print(f"  issued_to: {copy.get('issued_to')} ({type(copy.get('issued_to'))})")
            
            # Match conditions
            rfid_match = (str(copy.get('rfid')) == rfid)
            issued_match = (copy.get('issued_to') is None or copy.get('issued_to') == user_id)
            print(f"  RFID Match: {rfid_match}")
            print(f"  Issued To Match: {issued_match}")
    else:
        print("Book ID not found in database.")
