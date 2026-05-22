from pymongo import MongoClient
from bson import ObjectId

client = MongoClient("mongodb://localhost:27017/")
db = client["test_db"]
coll = db["test_books"]

coll.delete_many({})

# Scenario: Book with one copy, issued_to is None
book_id = ObjectId()
user_id = ObjectId()
rfid = "1005"

coll.insert_one({
    "_id": book_id,
    "title": "Test Book",
    "copies": [
        {"rfid": rfid, "issued_to": None}
    ]
})

print("Scenario 1: Issued To is None")
filter_q = {
    "_id": book_id,
    "copies": {
        "$elemMatch": {
            "$or": [
                {"issued_to": None},
                {"issued_to": user_id}
            ],
            "rfid": rfid
        }
    }
}

res = coll.update_one(filter_q, {"$set": {"copies.$.issued_to": user_id}})
print(f"Update Result: Matched={res.matched_count}, Modified={res.modified_count}")

updated = coll.find_one({"_id": book_id})
print(f"Updated Issued To: {updated['copies'][0]['issued_to']}")

print("\nScenario 2: Issued To is already user_id (re-allocating)")
res = coll.update_one(filter_q, {"$set": {"copies.$.issued_to": user_id}})
print(f"Update Result: Matched={res.matched_count}, Modified={res.modified_count}")
print(f"Updated Issued To: {updated['copies'][0]['issued_to']}")
