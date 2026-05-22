import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from pymongo import MongoClient
from bson import ObjectId
from config import Config

client = MongoClient(Config.MONGO_URI)
user_id_str = '698f167ddf407e1887dcad67'
user_id = ObjectId(user_id_str)

print(f"Searching for User ID: {user_id_str}")

for db_name in client.list_database_names():
    db = client[db_name]
    try:
        for coll_name in db.list_collection_names():
            # Search with ObjectId
            doc = db[coll_name].find_one({'user_id': user_id})
            if doc:
                print(f"FOUND (as ObjectId) in DB: {db_name}, Collection: {coll_name}")
                print(f"  Doc ID: {doc.get('_id')}")
            
            # Search with string (sometimes IDs are stored as strings)
            doc_str = db[coll_name].find_one({'user_id': user_id_str})
            if doc_str:
                print(f"FOUND (as String) in DB: {db_name}, Collection: {coll_name}")
                print(f"  Doc ID: {doc_str.get('_id')}")
                
            # Search in books.copies.issued_to
            if coll_name == 'books':
                book = db.books.find_one({'copies.issued_to': user_id})
                if book:
                    print(f"FOUND as issued_to in DB: {db_name}, Collection: books")
                    print(f"  Book Title: {book.get('title')}")
    except Exception as e:
        pass

print("\nSearch complete.")
