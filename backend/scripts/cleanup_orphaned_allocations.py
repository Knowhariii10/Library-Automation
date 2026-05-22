"""
Cleanup script to free up book copies that are allocated but not in any active rental.

This fixes the issue where copies got allocated to a user but the rental failed,
leaving the copies stuck in "issued_to" state.
"""

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from pymongo import MongoClient
from bson import ObjectId
from config import Config

def cleanup_orphaned_allocations():
    """Find and free copies that are allocated but not in any active rental"""
    
    client = MongoClient(Config.MONGO_URI)
    db = client[Config.DB_NAME]
    
    print("=" * 70)
    print("Cleaning up orphaned book allocations")
    print("=" * 70)
    
    # Get all books with allocated copies
    books_with_allocations = db.books.find({
        'copies.issued_to': {'$ne': None}
    })
    
    total_freed = 0
    
    for book in books_with_allocations:
        book_id = book['_id']
        title = book.get('title', 'Unknown')
        
        for copy in book.get('copies', []):
            issued_to = copy.get('issued_to')
            if issued_to is None:
                continue
            
            rfid = copy.get('rfid', 'N/A')
            barcode = copy.get('barcode', 'N/A')
            
            # Check if this copy is in any active rental
            active_rental = db.rentals.find_one({
                'user_id': issued_to,
                'status': 'ACTIVE',
                'books': {
                    '$elemMatch': {
                        'book_id': book_id,
                        'returned': False
                    }
                }
            })
            
            # Check if it's in a pending transaction
            pending_tx = db.transactions.find_one({
                'user_id': issued_to,
                'status': 'PENDING',
                'type': 'RENTAL',
                'items.book_id': str(book_id)
            })
            
            if not active_rental and not pending_tx:
                # This copy is orphaned - free it up
                print(f"\nFreeing orphaned copy:")
                print(f"  Book: {title}")
                print(f"  RFID: {rfid}, Barcode: {barcode}")
                print(f"  Was allocated to user: {issued_to}")
                
                # Free the copy
                db.books.update_one(
                    {
                        '_id': book_id,
                        'copies.rfid': rfid
                    },
                    {
                        '$set': {'copies.$.issued_to': None}
                    }
                )
                total_freed += 1
                print(f"  ✓ Freed!")
    
    print("\n" + "=" * 70)
    print(f"Cleanup complete! Freed {total_freed} orphaned copies.")
    print("=" * 70)

if __name__ == '__main__':
    try:
        cleanup_orphaned_allocations()
    except Exception as e:
        print(f"\n❌ ERROR: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
