from pymongo import MongoClient
from config import Config

client = MongoClient(Config.MONGO_URI)
for db_name in client.list_database_names():
    db = client[db_name]
    try:
        collections = db.list_collection_names()
        print(f"DB: {db_name}")
        print(f"  Collections: {collections}")
        for coll_name in collections:
            count = db[coll_name].count_documents({})
            if count > 0:
                print(f"    - {coll_name}: {count} documents")
    except Exception as e:
        print(f"DB: {db_name} (Error listing collections: {e})")
