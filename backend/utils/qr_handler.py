from datetime import datetime
from bson import ObjectId
import logging

logger = logging.getLogger(__name__)

def handle_qr_scan(qr_data, db, guest_db=None):
    """
    Handle QR code scanning with multi-purpose detection
    
    Args:
        qr_data: dict containing QR payload
        db: MongoDB database instance
        guest_db: MongoDB guest database instance (optional)
    
    Returns:
        dict: {
            'success': bool,
            'purpose': str,
            'message': str,
            'data': dict (optional)
        }
    """
    try:
        # Detect QR purpose
        purpose = qr_data.get('purpose', '').upper()
        
        if purpose == 'ATTENDANCE':
            return handle_attendance(qr_data, db, guest_db)
        elif purpose == 'TRANSACTION':
            return handle_transaction(qr_data, db)
        elif purpose == 'VERIFICATION':
            return handle_verification(qr_data, db)
        elif purpose == 'RENTING':
            return handle_renting(qr_data, db)
        elif purpose == 'RETURNING':
            return handle_returning(qr_data, db)
        else:
            return {
                'success': False,
                'purpose': 'UNKNOWN',
                'message': 'Unknown QR code purpose'
            }
    except Exception as e:
        return {
            'success': False,
            'purpose': 'ERROR',
            'message': f'Error processing QR code: {str(e)}'
        }

def handle_attendance(qr_data, db, guest_db=None):
    """Handle attendance QR scan - toggle is_inside"""
    user_id = qr_data.get('user_id')
    
    if not user_id:
        return {'success': False, 'purpose': 'ATTENDANCE', 'message': 'User ID missing'}
    
    # Get user information - Check both main DB and guest DB
    is_guest = False
    user = db.users.find_one({'_id': ObjectId(user_id)})
    
    if not user and guest_db is not None:
        user = guest_db.users.find_one({'_id': ObjectId(user_id)})
        if user:
            is_guest = True
            
    if not user:
        return {'success': False, 'purpose': 'ATTENDANCE', 'message': 'User not found'}
    
    # Get current attendance status
    attendance_check = db.checking_for_attendance.find_one({'user_id': ObjectId(user_id)})
    
    scan_time = datetime.now()
    
    if attendance_check:
        # Toggle is_inside
        new_status = not attendance_check.get('is_inside', False)
        db.checking_for_attendance.update_one(
            {'user_id': ObjectId(user_id)},
            {
                '$set': {
                    'is_inside': new_status,
                    'last_updated': scan_time
                }
            }
        )
    else:
        # Create new entry (entering library)
        new_status = True
        db.checking_for_attendance.insert_one({
            'user_id': ObjectId(user_id),
            'is_inside': new_status,
            'last_updated': scan_time 
        })
    
    # Log entry or exit
    if new_status:
        logger.info(f"User {user_id} ENTERED library. Inserting into attendance_entry.")
        db.attendance_entry.insert_one({
            'user_id': ObjectId(user_id),
            'scan_time': scan_time,
            'purpose': 'ATTENDANCE',
            'scanner_admin_id': qr_data.get('admin_id'),
            'is_guest': is_guest
        })
        message = f"Attendance marked for {user.get('name', 'User')}{' (Guest)' if is_guest else ''}"
    else:
        logger.info(f"User {user_id} LEFT library. Inserting into attendance_leaving.")
        db.attendance_leaving.insert_one({
            'user_id': ObjectId(user_id),
            'scan_time': scan_time,
            'purpose': 'ATTENDANCE',
            'scanner_admin_id': qr_data.get('admin_id'),
            'is_guest': is_guest
        })
        message = f"{user.get('name', 'User')}{' (Guest)' if is_guest else ''} left the library"
    
    return {
        'success': True,
        'purpose': 'ATTENDANCE',
        'message': message,
        'data': {
            'is_inside': new_status,
            'user_id': str(user_id),
            'user_name': user.get('name', 'N/A'),
            'student_id': user.get('student_id', 'N/A'),
            'dept': user.get('department', 'N/A'),
            'year': user.get('year', 'N/A'),
            'scan_time': scan_time.isoformat()
        }
    }

def handle_transaction(qr_data, db):
    """Handle transaction QR scan - retrieve and approve transaction details"""
    transaction_id = qr_data.get('transaction_id')
    user_id = qr_data.get('user_id')
    
    if not transaction_id:
        return {'success': False, 'purpose': 'TRANSACTION', 'message': 'Transaction ID missing'}
    
    transaction = db.transactions.find_one({'transaction_id': transaction_id})
    
    if not transaction:
        return {'success': False, 'purpose': 'TRANSACTION', 'message': 'Transaction not found'}
    
    # If the transaction is PENDING, approve it now that the user is at the counter
    current_status = transaction.get('status', 'PENDING')
    logger.info(f"Transaction {transaction_id} current status: {current_status}")
    
    if current_status == 'PENDING':
        logger.info(f"Approving transaction {transaction_id}")
        update_result = db.transactions.update_one(
            {'transaction_id': transaction_id},
            {
                '$set': {
                    'status': 'APPROVED',
                    'approved_at': datetime.now(),
                    'modified_at': datetime.now()
                }
            }
        )
        logger.info(f"Update result: matched={update_result.matched_count}, modified={update_result.modified_count}")
        
        # If it's a RENTAL, we need to create the record in db.renting 
        # to ensure compatibility with other parts of the system
        if transaction.get('type') == 'RENTAL':
            user_id_obj = transaction['user_id']
            books_to_rent = []
            due_date = transaction.get('due_date') or datetime.now() # Fallback
            
            from models.book_model import BookModel
            book_model = BookModel(db)
            
            for item in transaction.get('items', []):
                # Find the specific copy that was pre-assigned during online request
                # or just use the barcode/rfid from the item
                barcode = item.get('barcode', '')
                rfid = item.get('rfid', '')
                book_id = ObjectId(item['book_id']) if isinstance(item['book_id'], str) else item['book_id']
                
                # The copies are already "issued" to this user in BookModel.adjust_availability 
                # during the /rent-books request. We just need to make sure the renting collection
                # reflects the specific copy.
                
                if not barcode and not rfid:
                     # Fallback: Find the specific copy that is issued to this user
                     # This ensures we save the barcode for future returns
                     book_doc = db.books.find_one({'_id': book_id})
                     if book_doc:
                         copy = next((c for c in book_doc.get('copies', []) if str(c.get('issued_to')) == str(user_id_obj)), None)
                         if copy:
                             barcode = copy.get('barcode', '')
                             rfid = copy.get('rfid', '')
                
                books_to_rent.append({
                    'book_id': book_id,
                    'barcode': barcode,
                    'rfid': rfid,
                    'title': item['title'],
                    'author': item.get('author', ''),
                    'rented_at': datetime.now(),
                    'due_date': due_date,
                    'returned': False,
                    'fine_accrued': 0
                })
            
            # Create or update active rental
            active_rental = db.renting.find_one({
                'user_id': user_id_obj,
                'status': 'ACTIVE'
            })
            
            if active_rental:
                db.renting.update_one(
                    {'_id': active_rental['_id']},
                    {'$push': {'books': {'$each': books_to_rent}}}
                )
            else:
                db.renting.insert_one({
                    'user_id': user_id_obj,
                    'books': books_to_rent,
                    'total_fine': 0,
                    'status': 'ACTIVE'
                })

    # Force re-fetch to get literal state from DB
    transaction = db.transactions.find_one({'transaction_id': transaction_id})
    logger.info(f"Transaction {transaction_id} status after approval logic: {transaction.get('status')}")
    
    # Get user information
    user = None
    if user_id:
        user = db.users.find_one({'_id': ObjectId(user_id)})
    elif transaction.get('user_id'):
        user = db.users.find_one({'_id': transaction['user_id']})
    
    data = {
        'transaction_id': transaction['transaction_id'],
        'status': transaction['status'],
        'type': transaction.get('type', 'OTHER'),
        'items': transaction.get('items', []),
        'due_date': transaction.get('due_date').isoformat() if hasattr(transaction.get('due_date'), 'isoformat') else str(transaction.get('due_date')),
        'created_at': transaction['created_at'].isoformat()
    }
    
    if user:
        data.update({
            'user_id': str(user['_id']),
            'user_name': user.get('name', 'N/A'),
            'student_id': user.get('student_id', 'N/A'),
            'dept': user.get('department', 'N/A'),
            'year': user.get('year', 'N/A')
        })
    
    return {
        'success': True,
        'purpose': 'TRANSACTION',
        'message': f"Transaction {transaction['status'].lower()} successfully",
        'data': data
    }

def handle_verification(qr_data, db):
    """Handle verification QR scan - retrieve pre-approved rental details"""
    transaction_id = qr_data.get('transaction_id')
    user_id = qr_data.get('user_id')
    
    if not transaction_id:
        return {'success': False, 'purpose': 'VERIFICATION', 'message': 'Transaction ID missing'}
    
    transaction = db.transactions.find_one({'transaction_id': transaction_id})
    
    if not transaction:
        return {'success': False, 'purpose': 'VERIFICATION', 'message': 'Transaction not found'}
    
    # Get user information
    user = None
    if user_id:
        user = db.users.find_one({'_id': ObjectId(user_id)})
    elif transaction.get('user_id'):
        user = db.users.find_one({'_id': transaction['user_id']})
    
    data = {
        'transaction_id': transaction['transaction_id'],
        'status': transaction['status'],
        'type': transaction.get('type', 'OTHER'),
        'items': transaction.get('items', []),
        'due_date': transaction.get('due_date').isoformat() if hasattr(transaction.get('due_date'), 'isoformat') else str(transaction.get('due_date')),
        'created_at': transaction['created_at'].isoformat()
    }
    
    if user:
        data.update({
            'user_id': str(user['_id']),
            'user_name': user.get('name', 'N/A'),
            'student_id': user.get('student_id', 'N/A'),
            'dept': user.get('department', 'N/A'),
            'year': user.get('year', 'N/A')
        })
    
    return {
        'success': True,
        'purpose': 'VERIFICATION',
        'message': "Instant rental verified successfully",
        'data': data
    }

def handle_renting(qr_data, db):
    """Handle renting QR scan - create new rental"""
    from utils.fine_calculator import calculate_rental_due_date
    from config import Config
    
    user_id = qr_data.get('user_id')
    
    # New format: 'items' list of objects with specific details
    items = qr_data.get('items', [])
    # Legacy format: 'book_ids' list of strings
    book_ids = qr_data.get('book_ids', [])
    
    if not user_id or (not items and not book_ids):
        return {'success': False, 'purpose': 'RENTING', 'message': 'User ID or book IDs missing'}
    
    # Normalize input into a list of objects {book_id, barcode, rfid}
    # This unification layer allows us to handle both formats downstream
    books_to_process = []
    
    if items:
        for item in items:
            books_to_process.append({
                'book_id': item.get('book_id'),
                'barcode': item.get('barcode'),
                'rfid': item.get('rfid'),
                'identifier': item.get('book_id') # Default identifier is book_id unless specific provided
            })
    else:
        # Legacy: convert book_ids to objects with just book_id
        for bid in book_ids:
            books_to_process.append({
                'book_id': bid,
                'barcode': None,
                'rfid': None,
                'identifier': bid
            })
            
    # Check user's current rentals across all active sessions
    active_rentals = list(db.renting.find({
        'user_id': ObjectId(user_id),
        'status': 'ACTIVE'
    }))
    
    current_book_count = 0
    currently_rented_book_ids = []
    
    for rental in active_rentals:
        # Get list of currently rented books (not yet returned)
        currently_rented_books = [b for b in rental['books'] if not b.get('returned', False)]
        current_book_count += len(currently_rented_books)
        currently_rented_book_ids.extend([str(b['book_id']) for b in currently_rented_books])
    
    # Include active reservations in current book count to enforce total limit
    active_res_list = list(db.reservations.find({'user_id': ObjectId(user_id), 'status': 'ACTIVE'}))
    current_book_count += len(active_res_list)
    reserved_book_ids = [str(r['book_id']) for r in active_res_list]
    logger.info(f"User {user_id} possession count: Rentals={current_book_count - len(active_res_list)}, Reservations={len(active_res_list)}")
    
    # Deduplicate incoming books based on book_id
    # We use a dict keyed by book_id to keep the version with most info (barcode/rfid) if duplicate
    unique_books_map = {}
    for b in books_to_process:
        bid = str(b['book_id'])
        if bid not in unique_books_map:
             unique_books_map[bid] = b
        # If we already have it but the new one has specific info, overwrite? 
        # Actually usually duplicates shouldn't happen in one payload.
        
    unique_new_books = list(unique_books_map.values())
    incoming_count = len(unique_new_books)

    # Check if user is trying to rent a book they already have
    # Check if user is trying to rent a book they already have
    for book_obj in unique_new_books:
        book_id = str(book_obj['book_id'])
        if book_id in currently_rented_book_ids:
            # Get book title for better error message
            book = db.books.find_one({'_id': ObjectId(book_id)})
            book_title = book.get('title', 'this book') if book else 'this book'
            return {
                'success': False,
                'purpose': 'RENTING',
                'message': f'You already have "{book_title}" rented. Please return it before renting again.'
            }
    
    # Check if user can rent more books
    if current_book_count + incoming_count > Config.MAX_BOOKS_PER_RENTAL:
        remaining = Config.MAX_BOOKS_PER_RENTAL - current_book_count
        return {
            'success': False,
            'purpose': 'RENTING',
            'message': f'Total limit is {Config.MAX_BOOKS_PER_RENTAL} books. User already has {current_book_count}, so they can only rent {max(0, remaining)} more.'
        }
    
    # Prepare book entries
    books_to_rent = []
    decremented_books_ids = [] # Track IDs for rollback
    due_date = calculate_rental_due_date()
    
    from models.book_model import BookModel
    book_model = BookModel(db)

    try:
        for book_obj in unique_new_books:
            identifier = book_obj['book_id']
            specific_barcode = book_obj.get('barcode')
            specific_rfid = book_obj.get('rfid')
            
            # 1. Find the book and verify it exists
            # Defensive check for ObjectId validity for identifier
            from bson.errors import InvalidId
            book = None
            try:
                if identifier and len(str(identifier)) == 24: # Quick hex check
                    book = db.books.find_one({'_id': ObjectId(identifier)})
            except InvalidId:
                pass
            
            # If not found by ID, maybe identifier was actually a barcode/rfid string (legacy fallback)
            if not book:
                 query = {
                    '$or': [
                        {'copies.barcode': identifier},
                        {'copies.rfid': identifier}
                    ]
                }
                 book = db.books.find_one(query)
            
            if not book:
                # Rollback
                for d_id, d_ident in decremented_books_ids:
                    book_model.return_copy(d_id, d_ident)
                return {'success': False, 'purpose': 'RENTING', 'message': f'Book {identifier} not found'}
            
            book_id = book['_id']
            
            # CRITICAL CHECK: Does user already have a copy of this book allocated in books.copies?
            # This covers both reservations (which set issued_to) and any other active possession.
            already_allocated = False
            for copy in book.get('copies', []):
                if copy.get('issued_to') and str(copy.get('issued_to')) == str(user_id):
                    already_allocated = True
                    break
            
            if already_allocated:
                logger.warning(f"Blocking offline rental: User {user_id} already has a copy of book {book_id} allocated (reserved/issued).")
                return {
                    'success': False,
                    'purpose': 'RENTING',
                    'message': f'You already have a copy of "{book.get("title")}" allocated to you (either as a reservation or rental). Please use the specific pickup/return flow or cancel existing hold.'
                }
            
            # Determine best identifier for issuing
            # If we have specific barcode/rfid from frontend, use that!
            # Otherwise use what we have
            copy_identifier = specific_barcode or specific_rfid
            
            # Legacy fallback: if identifier was not the book_id, it might be the barcode
            if not copy_identifier and str(book_id) != identifier:
                 copy_identifier = identifier
            
            # 2. Check for active reservation

            reservation = db.reservations.find_one({
                'user_id': ObjectId(user_id),
                'book_id': ObjectId(book_id),
                'status': 'ACTIVE'
            })
            
            if reservation:
                logger.warning(f"Blocking offline rental for user {user_id} and book {book_id} because an active reservation exists: {reservation['_id']}")
                return {
                    'success': False,
                    'purpose': 'RENTING',
                    'message': f'You already have an active reservation for "{book.get("title")}". Please cancel it first or use the Reservation Verification flow.'
                }


            # 3. Issue the specific copy (or first available if identifier is book_id)
            if not book_model.issue_copy(book_id, copy_identifier, user_id):
                # Rollback
                for d_id, d_ident in decremented_books_ids:
                    book_model.return_copy(d_id, d_ident)
                return {'success': False, 'purpose': 'RENTING', 'message': f'Product is not available or already issued'}
            
            # Track for rollback - we need the specific identifier used or found
            # We'll fetch the book again to see which copy was issued if we didn't specify one
            if not copy_identifier:
                issued_book = db.books.find_one({'_id': book_id})
                issued_copy = next((c for c in issued_book.get('copies', []) if str(c.get('issued_to')) == str(user_id)), {})
                copy_identifier = issued_copy.get('barcode') or issued_copy.get('rfid')
            
            decremented_books_ids.append((book_id, copy_identifier))
            
            # 4. Prepare metadata for renting record
            issued_book = db.books.find_one({'_id': book_id})
            issued_copy = next((c for c in issued_book.get('copies', []) if (c.get('barcode') == copy_identifier or c.get('rfid') == copy_identifier) and str(c.get('issued_to')) == str(user_id)), {})
            
            books_to_rent.append({
                'book_id': book_id,
                'barcode': issued_copy.get('barcode', ''),
                'rfid': issued_copy.get('rfid', ''),
                'title': issued_book['title'],
                'author': issued_book.get('author', ''),
                'rented_at': datetime.now(),
                'due_date': due_date,
                'returned': False,
                'fine_accrued': 0
            })

    except Exception as e:
        logger.error(f"Error in handle_renting: {e}")
        # Rollback on unexpected error
        for d_id, d_ident in decremented_books_ids:
            book_model.return_copy(d_id, d_ident)
        raise e
    
    # Create or update rental
    if active_rentals:
        db.renting.update_one(
            {'_id': active_rentals[0]['_id']},
            {'$push': {'books': {'$each': books_to_rent}}}
        )
    else:
        db.renting.insert_one({
            'user_id': ObjectId(user_id),
            'books': books_to_rent,
            'total_fine': 0,
            'status': 'ACTIVE'
        })
    
    # Get user information
    user = db.users.find_one({'_id': ObjectId(user_id)})
    
    data = {
        'due_date': due_date.isoformat(),
        'books_count': len(books_to_rent)
    }
    
    if user:
        data.update({
            'user_id': str(user_id),
            'user_name': user.get('name', 'N/A'),
            'student_id': user.get('student_id', 'N/A'),
            'dept': user.get('department', 'N/A'),
            'year': user.get('year', 'N/A')
        })
    
    # Create notification for rental
    from utils.notification_service import create_notification
    
    notification_message = f"You have successfully rented {len(books_to_rent)} book(s). Due date: {due_date.strftime('%d-%m-%Y')}."
    create_notification(
        db,
        user_id,
        'Books Rented',
        notification_message,
        'RENTAL'
    )

    return {
        'success': True,
        'purpose': 'RENTING',
        'message': f'Successfully rented {len(books_to_rent)} book(s)',
        'data': data
    }

def handle_returning(qr_data, db):
    """Handle returning QR scan - process book return and calculate fines"""
    from utils.fine_calculator import calculate_fine
    
    user_id = qr_data.get('user_id')
    book_ids = qr_data.get('book_ids', [])
    
    if not user_id or not book_ids:
        return {'success': False, 'purpose': 'RETURNING', 'message': 'User ID or book IDs missing'}
    
    # Find active rental
    rental = db.renting.find_one({
        'user_id': ObjectId(user_id),
        'status': 'ACTIVE'
    })
    
    if not rental:
        return {'success': False, 'purpose': 'RETURNING', 'message': 'No active rental found'}
    
    total_fine = 0
    returned_books = []
    
    # 1. Pre-check: Verify if any books have unpaid fines BEFORE processing return
    for book_id in book_ids:
        for book in rental['books']:
            if str(book['book_id']) == str(book_id) and not book.get('returned', False):
                # Calculate fine
                fine_info = calculate_fine(book['due_date'])
                total_fine_accrued = fine_info['fine_amount']
                
                # Check for pre-paid fine
                pre_paid = book.get('pre_paid_fine', 0)
                fine_remaining = max(0, total_fine_accrued - pre_paid)
                
                # Check for existing manual/damaged fines in DB
                manual_fines = list(db.fines.find({
                    'transaction_id': rental['_id'],
                    'book_id': book['book_id'],
                    'status': 'PENDING'
                }))
                
                manual_fine_amount = sum(f.get('amount', 0) for f in manual_fines)
                
                total_blocking_amount = fine_remaining + manual_fine_amount

                # OLD BEHAVIOR: blocked if total_blocking_amount > 0
                # NEW BEHAVIOR: Allow return, but we will record the fine as PENDING later.
                # Just break here to proceed to processing
                break
    
    # 2. Process Return (only if no unpaid fines)
    for book_id in book_ids:
        # Find book in rental
        book_found = False
        for book in rental['books']:
            if str(book['book_id']) == str(book_id) and not book.get('returned', False):
                book_found = True
                
                # Calculate fine
                fine_info = calculate_fine(book['due_date'])
                total_fine_accrued = fine_info['fine_amount']
                
                # Check for pre-paid fine
                pre_paid = book.get('pre_paid_fine', 0)
                fine_remaining = max(0, total_fine_accrued - pre_paid)
                
                total_fine += fine_remaining # Only add remaining fine to trip total
                
                # Mark as returned in renting collection
                db.renting.update_one(
                    {'_id': rental['_id'], 'books.book_id': ObjectId(book_id)},
                    {
                        '$set': {
                            'books.$.returned': True,
                            'books.$.fine_accrued': total_fine_accrued,
                            'books.$.returned_at': datetime.now()
                        }
                    }
                )
                
                # Update book copy status safely
                # Update book copy status safely
                from models.book_model import BookModel
                # We need the barcode or rfid to return the correct copy
                copy_barcode = book.get('barcode', '')
                copy_rfid = book.get('rfid', '')
                
                if copy_barcode or copy_rfid:
                    BookModel(db).return_copy(book_id, copy_barcode if copy_barcode else copy_rfid)
                else:
                    # Fallback: If we don't know which copy (missing barcode),
                    # find ANY copy issued to this user and return it.
                    BookModel(db).adjust_availability(book_id, 1, user_id=ObjectId(user_id))
                
                returned_books.append({
                    'book_id': str(book_id),
                    'title': book['title'],
                    'fine': fine_remaining,
                    'total_fine': total_fine_accrued,
                    'pre_paid': pre_paid,
                    'days_overdue': fine_info['days_overdue']
                })
                
                # Create fine record if overdue AND there is a remaining balance
                if fine_info['is_overdue'] and fine_remaining > 0:
                    db.fines.insert_one({
                        'user_id': ObjectId(user_id),
                        'transaction_id': rental['_id'],
                        'book_id': ObjectId(book_id),
                        'book_title': book['title'],
                        'author': book.get('author', ''),
                        'rfid': book.get('rfid', ''),
                        'amount': fine_remaining,
                        'reason': 'OVERDUE',
                        'days_overdue': fine_info['days_overdue'],
                        'issued_date': datetime.now(),
                        'paid_date': None,
                        'status': 'PENDING'
                    })
                
                break
        
        if not book_found:
            return {'success': False, 'purpose': 'RETURNING', 'message': f'Book {book_id} not found in rental'}
    
    
    # Update related transactions if all books in them are returned
    try:
        updated_rental_record = db.renting.find_one({'_id': rental['_id']})
        if updated_rental_record:
            returned_book_ids_in_rental = {str(b['book_id']) for b in updated_rental_record['books'] if b.get('returned', False)}
            
            active_txns = list(db.transactions.find({
                'user_id': ObjectId(user_id),
                'status': 'APPROVED',
                'type': 'RENTAL'
            }))
            
            for txn in active_txns:
                txn_book_ids = {str(item['book_id']) for item in txn.get('items', [])}
                # Check if this transaction contains the book being returned
                if any(str(book_id) == str(item['book_id']) for item in txn.get('items', [])):
                    # Calculate new fine amount for this transaction based on current returned status
                    total_txn_fine = 0
                    # We need to re-fetch the rental to be sure we have latest returned states
                    latest_rental = db.renting.find_one({'_id': rental['_id']})
                    if latest_rental:
                        for b in latest_rental['books']:
                            if str(b['book_id']) in txn_book_ids:
                                total_txn_fine += b.get('fine_accrued', 0)
                    
                    update_data = {
                        'fine_amount': total_txn_fine,
                        'modified_at': datetime.now()
                    }
                    
                    # If all books for this transaction are returned, mark as RETURNED
                    if txn_book_ids.issubset(returned_book_ids_in_rental):
                        logger.info(f"All books for transaction {txn.get('transaction_id')} returned. Updating status to RETURNED.")
                        update_data['status'] = 'RETURNED'
                        update_data['returned_at'] = datetime.now()
                    
                    db.transactions.update_one({'_id': txn['_id']}, {'$set': update_data})
    except Exception as e:
        logger.error(f"Error updating transaction status: {e}")

    # Update rental total fine
    db.renting.update_one(
        {'_id': rental['_id']},
        {'$inc': {'total_fine': total_fine}}
    )
    
    # Check if all books returned
    updated_rental = db.renting.find_one({'_id': rental['_id']})
    all_returned = all(b.get('returned', False) for b in updated_rental['books'])
    
    if all_returned:
        db.renting.update_one(
            {'_id': rental['_id']},
            {'$set': {'status': 'COMPLETED'}}
        )
    
    # Get user information
    user = db.users.find_one({'_id': ObjectId(user_id)})
    
    data = {
        'returned_books': returned_books,
        'total_fine': total_fine,
        'all_returned': all_returned
    }
    
    if user:
        data.update({
            'user_id': str(user_id),
            'user_name': user.get('name', 'N/A'),
            'student_id': user.get('student_id', 'N/A'),
            'dept': user.get('department', 'N/A'),
            'year': user.get('year', 'N/A')
        })
    
    # Create notification for return
    from utils.notification_service import create_notification
    
    fine_msg = ""
    if total_fine > 0:
        fine_msg = f" A total fine of Rs.{total_fine} has been recorded."
    
    start_msg = "All books in this set returned." if all_returned else f"Returned {len(returned_books)} book(s)."
    notification_message = f"{start_msg}{fine_msg}"
    
    create_notification(
        db,
        user_id,
        'Books Returned',
        notification_message,
        'RETURN'
    )

    return {
        'success': True,
        'purpose': 'RETURNING',
        'message': f'Successfully returned {len(returned_books)} book(s)',
        'data': data
    }
