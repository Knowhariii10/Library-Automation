"""
Test script to verify RFID allocation fix for online checkout.

This script tests that when a specific RFID is requested during checkout,
the system allocates that exact RFID instead of the first available one.
"""

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from pymongo import MongoClient
from bson import ObjectId
from models.book_model import BookModel
from config import Config

def test_rfid_allocation():
    """Test that specific RFID allocation works correctly"""
    
    # Connect to database
    client = MongoClient(Config.MONGO_URI)
    db = client[Config.DB_NAME]
    book_model = BookModel(db)
    
    print("=" * 60)
    print("RFID Allocation Test")
    print("=" * 60)
    
    # Create a test book with multiple copies
    test_book_data = {
        'title': 'Test Book for RFID Allocation',
        'author': 'Test Author',
        'department': 'Computer Science',
        'tags': ['test'],
        'difficulty_level': 'beginner',
        'copies': [
            {'barcode': 'TEST001', 'rfid': 'RFID001'},
            {'barcode': 'TEST002', 'rfid': 'RFID002'},
            {'barcode': 'TEST003', 'rfid': 'RFID003'}
        ],
        'location': {'section': 'A', 'row': 1, 'column': 1}
    }
    
    print("\n1. Creating test book with 3 copies...")
    book_id = book_model.create(test_book_data)
    print(f"   ✓ Created book with ID: {book_id}")
    
    # Test user ID
    test_user_id = ObjectId()
    print(f"\n2. Test user ID: {test_user_id}")
    
    # Test 1: Allocate specific RFID (RFID002)
    print("\n3. Test 1: Allocating specific RFID 'RFID002'...")
    result = book_model.adjust_availability(
        book_id, 
        -1, 
        user_id=test_user_id, 
        rfid='RFID002'
    )
    
    if result and result.get('success'):
        allocated_rfid = result['allocated_copy']['rfid']
        print(f"   ✓ Allocation successful!")
        print(f"   Allocated RFID: {allocated_rfid}")
        
        if allocated_rfid == 'RFID002':
            print("   ✅ PASS: Correct RFID was allocated!")
        else:
            print(f"   ❌ FAIL: Expected RFID002 but got {allocated_rfid}")
            cleanup(db, book_id)
            return False
    else:
        print("   ❌ FAIL: Allocation failed")
        cleanup(db, book_id)
        return False
    
    # Test 2: Try to allocate the same RFID again (should fail)
    print("\n4. Test 2: Trying to allocate RFID002 again (should fail)...")
    test_user_2 = ObjectId()
    result2 = book_model.adjust_availability(
        book_id,
        -1,
        user_id=test_user_2,
        rfid='RFID002'
    )
    
    if result2 is None or not result2.get('success'):
        print("   ✅ PASS: Correctly rejected allocation of already-issued RFID")
    else:
        print("   ❌ FAIL: Should not have allocated an already-issued RFID")
        cleanup(db, book_id)
        return False
    
    # Test 3: Allocate a different RFID (RFID001)
    print("\n5. Test 3: Allocating different RFID 'RFID001'...")
    result3 = book_model.adjust_availability(
        book_id,
        -1,
        user_id=test_user_2,
        rfid='RFID001'
    )
    
    if result3 and result3.get('success'):
        allocated_rfid = result3['allocated_copy']['rfid']
        print(f"   ✓ Allocation successful!")
        print(f"   Allocated RFID: {allocated_rfid}")
        
        if allocated_rfid == 'RFID001':
            print("   ✅ PASS: Correct RFID was allocated!")
        else:
            print(f"   ❌ FAIL: Expected RFID001 but got {allocated_rfid}")
            cleanup(db, book_id)
            return False
    else:
        print("   ❌ FAIL: Allocation failed")
        cleanup(db, book_id)
        return False
    
    # Test 4: Verify book state
    print("\n6. Test 4: Verifying book state...")
    book = book_model.find_by_id(book_id)
    copies = book.get('copies', [])
    
    print(f"   Total copies: {len(copies)}")
    for i, copy in enumerate(copies):
        issued_to = copy.get('issued_to')
        status = "ISSUED" if issued_to else "AVAILABLE"
        print(f"   Copy {i+1}: RFID={copy.get('rfid')}, Status={status}")
    
    # Verify RFID001 and RFID002 are issued, RFID003 is available
    rfid001_issued = any(c.get('rfid') == 'RFID001' and c.get('issued_to') is not None for c in copies)
    rfid002_issued = any(c.get('rfid') == 'RFID002' and c.get('issued_to') is not None for c in copies)
    rfid003_available = any(c.get('rfid') == 'RFID003' and c.get('issued_to') is None for c in copies)
    
    if rfid001_issued and rfid002_issued and rfid003_available:
        print("   ✅ PASS: Book state is correct!")
    else:
        print("   ❌ FAIL: Book state is incorrect")
        cleanup(db, book_id)
        return False
    
    # Cleanup
    cleanup(db, book_id)
    
    print("\n" + "=" * 60)
    print("✅ ALL TESTS PASSED!")
    print("=" * 60)
    return True

def cleanup(db, book_id):
    """Clean up test data"""
    print("\n7. Cleaning up test data...")
    db.books.delete_one({'_id': book_id})
    print("   ✓ Test book deleted")

if __name__ == '__main__':
    try:
        success = test_rfid_allocation()
        sys.exit(0 if success else 1)
    except Exception as e:
        print(f"\n❌ ERROR: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
