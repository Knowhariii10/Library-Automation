
import os
import sys
from pymongo import MongoClient
from bson import ObjectId
from datetime import datetime

# Add parent directory to path to import config
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from config import Config
from dotenv import load_dotenv

load_dotenv()

def test_allocation():
    try:
        mongo_uri = os.getenv('MONGO_URI', Config.MONGO_URI)
        db_name = os.getenv('DB_NAME', Config.DB_NAME)
        
        client = MongoClient(mongo_uri)
        db = client[db_name]
        
        print(f"Connected to database: {db_name}")
        
        # 1. Setup Test Data
        # Find a book with > 1 copy available
        book = db.books.find_one({'$where': 'this.copies.length > 1'})
        if not book:
            print("No suitable book found for testing.")
            return

        print(f"Testing with Book: {book['title']} (ID: {book['_id']})")
        
        # Ensure it has test copies
        # We will temporarily modify this book to have two distinct copies for testing
        original_copies = book.get('copies', [])
        
        test_copies = [
            {'barcode': 'TEST_A', 'rfid': 'RFID_A', 'issued_to': None},
            {'barcode': 'TEST_B', 'rfid': 'RFID_B', 'issued_to': None}
        ]
        
        db.books.update_one(
            {'_id': book['_id']},
            {'$set': {'copies': test_copies}}
        )
        print("Updated book with test copies: RFID_A and RFID_B")
        
        # 2. Simulate Rental of RFID_B
        user_id = ObjectId() # Random user ID
        target_rfid = 'RFID_B'
        
        print(f"Simulating rental request for RFID: {target_rfid}")
        
        # LOGIC FROM book_model.adjust_availability
        filter_query = {'_id': book['_id'], 'copies.issued_to': None}
        match_conditions = [{'rfid': target_rfid}]
        
        elem_match = {'issued_to': None}
        elem_match['$or'] = match_conditions
        filter_query['copies'] = {'$elemMatch': elem_match}
        
        print(f"Query: {filter_query}")
        
        result = db.books.update_one(
            filter_query,
            {'$set': {'copies.$.issued_to': user_id, 'updated_at': datetime.now()}}
        )
        
        print(f"Update Result - Matched: {result.matched_count}, Modified: {result.modified_count}")
        
        if result.modified_count > 0:
            print("SUCCESS: Database update successful.")
        else:
            print("FAILURE: Database update failed.")
            
        # 3. Verify Allocation
        updated_book = db.books.find_one({'_id': book['_id']})
        copies = updated_book['copies']
        
        copy_a = next((c for c in copies if c['rfid'] == 'RFID_A'), None)
        copy_b = next((c for c in copies if c['rfid'] == 'RFID_B'), None)
        
        print(f"Copy A (RFID_A) Issued To: {copy_a.get('issued_to')}")
        print(f"Copy B (RFID_B) Issued To: {copy_b.get('issued_to')}")
        
        if copy_b.get('issued_to') == user_id and copy_a.get('issued_to') is None:
             print("VERIFICATION PASSED: Correct copy allocated!")
        else:
             print("VERIFICATION FAILED: Incorrect allocation state.")

    except Exception as e:
        print(f"Error: {e}")
    finally:
        # Restore original state
        if 'original_copies' in locals() and 'book' in locals():
            db.books.update_one(
                {'_id': book['_id']},
                {'$set': {'copies': original_copies}}
            )
            print("Restored original book copies.")

if __name__ == "__main__":
    test_allocation()
