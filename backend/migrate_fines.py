from pymongo import MongoClient
from bson import ObjectId
import datetime

def migrate_fines():
    # Connect to MongoDB
    client = MongoClient("mongodb://localhost:27017")
    db = client.library_management
    
    print("Starting fine migration...")
    
    # Get all fines missing book details
    fines = list(db.fines.find({
        "$or": [
            {"book_title": {"$exists": False}},
            {"author": {"$exists": False}},
            {"rfid": {"$exists": False}}
        ]
    }))
    
    print(f"Found {len(fines)} fines to migrate.")
    
    updates = 0
    for fine in fines:
        book_id = fine.get('book_id')
        transaction_id = fine.get('transaction_id')
        
        book_title = "Unknown"
        author = ""
        rfid = ""
        
        # Try to get book info from books collection if book_id exists
        if book_id:
            book = db.books.find_one({"_id": ObjectId(book_id)})
            if book:
                book_title = book.get('title', "Unknown")
                author = book.get('author', "")
                # We can't easily know which rfid was used from just the book_id if multiple copies exist,
                # but we can try to find it in the transaction or renting record
        
        # Try to get more info from renting record (best source for rfid)
        if transaction_id:
            rental = db.renting.find_one({"_id": ObjectId(transaction_id)})
            if rental:
                for b in rental.get('books', []):
                    if str(b.get('book_id')) == str(book_id):
                        book_title = b.get('title', book_title)
                        author = b.get('author', author)
                        rfid = b.get('rfid', "")
                        break
        
        # If still unknown and we have a transaction_id, check transactions collection
        if book_title == "Unknown" and transaction_id:
            txn = db.transactions.find_one({"_id": transaction_id})
            if txn:
                for item in txn.get('items', []):
                    if str(item.get('book_id')) == str(book_id):
                        book_title = item.get('title', book_title)
                        author = item.get('author', author)
                        rfid = item.get('rfid', rfid)
                        break

        # Update the fine record
        db.fines.update_one(
            {"_id": fine["_id"]},
            {"$set": {
                "book_title": book_title,
                "author": author,
                "rfid": rfid
            }}
        )
        updates += 1
        
    print(f"Successfully updated {updates} fine records.")
    client.close()

if __name__ == "__main__":
    migrate_fines()
