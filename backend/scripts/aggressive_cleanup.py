from pymongo import MongoClient

# Use local URI directly to be 100% sure
client = MongoClient("mongodb://localhost:27017/")
db = client["library_management"]

print("=" * 60)
print("AGGRESSIVE CLEANUP OF RFIDs AND BARCODES")
print("=" * 60)

books = list(db.books.find({}))
print(f"Checking {len(books)} books...")

total_fixed = 0

for book in books:
    modified = False
    copies = book.get('copies', [])
    for copy in copies:
        for field in ['rfid', 'barcode']:
            val = copy.get(field)
            if isinstance(val, str):
                cleaned = val.strip()
                if cleaned != val:
                    print(f"FIXED {field} in '{book.get('title')}': '{val}' -> '{cleaned}'")
                    copy[field] = cleaned
                    modified = True
                    total_fixed += 1
    
    if modified:
        db.books.update_one({'_id': book['_id']}, {'$set': {'copies': copies}})

print(f"\nCleanup complete. Total fields cleaned: {total_fixed}")
