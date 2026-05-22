import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from pymongo import MongoClient
from config import Config

client = MongoClient(Config.MONGO_URI)
db = client[Config.DB_NAME]

print(f"DATABASE: {Config.DB_NAME}")

for coll_name in db.list_collection_names():
    count = db[coll_name].count_documents({})
    print(f"\nCollection: {coll_name} ({count} documents)")
    if count > 0:
        docs = list(db[coll_name].find().sort('_id', -1).limit(2))
        for d in docs:
            print(f"  - {d}")
