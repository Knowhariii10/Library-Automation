from pymongo import MongoClient
import os
from bson import ObjectId
import sys

# Ensure UTF-8 output
if sys.platform == "win32":
    import codecs
    sys.stdout = codecs.getwriter("utf-8")(sys.stdout.detach())

MONGO_URI = 'mongodb://localhost:27017/'
DB_NAME = 'library_management'

client = MongoClient(MONGO_URI)
db = client[DB_NAME]

def log(msg):
    print(msg)
    with open('db_debug.log', 'a', encoding='utf-8') as f:
        f.write(msg + '\n')

# Clear log
with open('db_debug.log', 'w', encoding='utf-8') as f:
    f.write("--- DB STATE CHECK ---\n")

log("--- Users ---")
for user in db.users.find():
    log(f"User: {user.get('name')} | ID: {user['_id']} | Email: {user.get('email')}")

log("\n--- Reservations ---")
res_count = 0
for res in db.reservations.find():
    res_count += 1
    log(f"Res ID: {res['_id']} | User ID: {res.get('user_id')} ({type(res.get('user_id'))}) | Book ID: {res.get('book_id')} | Status: {res.get('status')}")
log(f"Total reservations found: {res_count}")

log("\n--- Sync Logic Test ---")
for user in db.users.find():
    uid = user['_id']
    from_db_active = list(db.reservations.find({'user_id': uid, 'status': 'ACTIVE'}))
    log(f"User {user.get('name')} ({uid}): Found {len(from_db_active)} ACTIVE reservations via find()")
    
    # Try string match if it was stored as string by mistake
    from_db_str = list(db.reservations.find({'user_id': str(uid), 'status': 'ACTIVE'}))
    if len(from_db_str) > 0:
        log(f"WARNING: User {user.get('name')} has {len(from_db_str)} reservations stored with STRING user_id!")
