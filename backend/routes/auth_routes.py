from flask import Blueprint, request, jsonify
from flask_mail import Message
from models.admin_model import AdminModel
from models.user_model import UserModel
from models.transaction_model import TransactionModel
from models.notification_model import NotificationModel
from utils.jwt_utils import generate_token, token_required, generate_user_token
from datetime import datetime
from bson import ObjectId

auth_bp = Blueprint('auth', __name__, url_prefix='/auth/admin')

def init_auth_routes(db, mail, guest_db=None):
    """Initialize authentication routes with database and mail service"""
    admin_model = AdminModel(db)
    user_model = UserModel(db)
    guest_model = UserModel(guest_db) if guest_db is not None else user_model
    transaction_model = TransactionModel(db)
    notification_model = NotificationModel(db)
    
    @auth_bp.route('/login', methods=['POST'])
    def login():
        """Admin login endpoint"""
        try:
            data = request.get_json()
            
            if not data or not data.get('email') or not data.get('password'):
                return jsonify({'error': 'Email and password are required'}), 400
            
            # Find admin by email
            admin = admin_model.find_by_email(data['email'])
            
            if not admin:
                return jsonify({'error': 'Invalid credentials'}), 401
            
            # Check if account is active
            if not admin_model.is_active(admin):
                return jsonify({'error': 'Account is inactive'}), 403
            
            # Verify password
            if not admin_model.verify_password(admin, data['password']):
                return jsonify({'error': 'Invalid credentials'}), 401
            
            # Generate JWT token
            token = generate_token(admin['_id'], admin['email'])
            
            return jsonify({
                'success': True,
                'token': token,
                'admin': admin_model.to_dict(admin)
            }), 200
            
        except Exception as e:
            return jsonify({'error': str(e)}), 500
    
    @auth_bp.route('/logout', methods=['POST'])
    @token_required
    def logout():
        """Admin logout endpoint (client-side token removal)"""
        return jsonify({
            'success': True,
            'message': 'Logged out successfully'
        }), 200
    
    @auth_bp.route('/validate', methods=['GET'])
    @token_required
    def validate():
        """Validate JWT token"""
        admin = admin_model.find_by_id(request.admin_id)
        
        if not admin:
            return jsonify({'error': 'Admin not found'}), 404
        
        return jsonify({
            'success': True,
            'admin': admin_model.to_dict(admin)
        }), 200
    
    # --- Student Auth Routes ---

    @auth_bp.route('/student/login', methods=['POST'])
    def student_login():
        """Student login endpoint"""
        try:
            from models.book_model import BookModel
            book_model = BookModel(db)
            data = request.get_json()
            
            if not data or not data.get('email') or not data.get('password'):
                return jsonify({'error': 'Email and password are required'}), 400
            
            user = user_model.find_by_email(data['email'])
            if not user or not user_model.verify_password(user, data['password']):
                return jsonify({'error': 'Invalid credentials'}), 401
            
            token = generate_user_token(user['_id'], user['email'])
            
            # Fetch user-specific data for offline sync
            transactions = transaction_model.find_by_user(user['_id'])
            notifications = notification_model.find_by_user(user['_id'])
            
            # Fetch all books for initial sync
            books = book_model.find_all()
            
            # Fetch active reservations
            reservations = list(db.reservations.find({'user_id': user['_id'], 'status': 'ACTIVE'}))
            
            # Fetch active rentals
            active_rentals = list(db.renting.find({'user_id': user['_id'], 'status': 'ACTIVE'}))
            rented_books = []
            for rental in active_rentals:
                for b in rental.get('books', []):
                    if not b.get('returned', False):
                        book_info = db.books.find_one({'_id': b['book_id']})
                        rented_books.append({
                            'book_id': str(b['book_id']),
                            'book_title': book_info.get('title', 'Unknown') if book_info else 'Unknown',
                            'due_date': b['due_date'].isoformat() if isinstance(b.get('due_date'), datetime) else b.get('due_date'),
                            'rental_id': str(rental['_id'])
                        })
            
            # Fetch fines
            fines = list(db.fines.find({'user_id': user['_id']}))
            print(f"DEBUG: Found {len(fines)} fines for user {user['email']}.")
            for i, f in enumerate(fines):
                 print(f"DEBUG: Fine {i}: {f}")

            return jsonify({
                'success': True,
                'token': token,
                'user': user_model.to_dict(user),
                'transactions': [transaction_model.to_dict(t) for t in transactions],
                'notifications': [notification_model.to_dict(n) for n in notifications],
                'books': [book_model.to_dict(b) for b in books],
                'reservations': [{
                    'id': str(r['_id']),
                    'book_id': str(r['book_id']),
                    'book_title': db.books.find_one({'_id': r['book_id']}).get('title', 'Unknown') if db.books.find_one({'_id': r['book_id']}) else 'Unknown',
                    'reserved_at': r['reserved_at'].isoformat(),
                    'expires_at': r['expires_at'].isoformat(),
                    'status': r['status']
                } for r in reservations],
                'rentals': rented_books,
                'fines': [{
                    'id': str(f['_id']),
                    'amount': f.get('amount', 0.0),
                    'reason': f.get('reason', 'Fine'),
                    'status': f.get('status', 'PENDING'),
                    'date': f['issued_date'].isoformat() if isinstance(f.get('issued_date'), datetime) else f.get('issued_date'),
                    'paid_date': f['paid_date'].isoformat() if f.get('paid_date') and isinstance(f.get('paid_date'), datetime) else None,
                    'transaction_id': str(f.get('transaction_id', ''))
                } for f in fines]
            }), 200
        except Exception as e:
            import traceback
            traceback.print_exc()
            print(f"ERROR in student_login: {e}")
            return jsonify({'error': str(e)}), 500

    @auth_bp.route('/student/register', methods=['POST'])
    def student_register():
        """Student registration endpoint"""
        try:
            import re
            data = request.get_json()
            
            if not data or not data.get('email') or not data.get('password') or not data.get('name'):
                return jsonify({'error': 'Name, email and password are required'}), 400
            
            # Proper Workflow:
            # 1. Normalize and Validate Email (Case Preserved)
            email = data.get('email', '').strip()
            if not re.match(r"[^@]+@[^@]+\.[^@]+", email):
                return jsonify({'error': 'Invalid email format'}), 400
            
            # 2. Normalize and Validate Student ID (Case Preserved)
            student_id = data.get('student_id', '').strip()
            if not student_id:
                return jsonify({'error': 'Student ID is required'}), 400
            
            # DIAGNOSTIC LOGGING
            print(f"DEBUG: Checking uniqueness for Email: '{email}', SID: '{student_id}'")
            
            # 3. Step 3: Check Uniqueness (Case-Insensitive)
            # Check Email first
            existing_email = user_model.find_by_email(email)
            if existing_email:
                print(f"DEBUG: Email match found: {existing_email.get('email')}")
                return jsonify({'error': 'Email is already registered'}), 400
            
            # Check Student ID next
            existing_sid = user_model.find_by_student_id(student_id)
            if existing_sid:
                print(f"DEBUG: SID match found: {existing_sid.get('student_id')}")
                return jsonify({'error': 'Student ID is already registered'}), 400
            
            print("DEBUG: No duplicates found. Proceeding with registration.")
            
            # 4. Prepare data for creation
            data['email'] = email
            data['student_id'] = student_id
            
            from models.book_model import BookModel
            book_model = BookModel(db)
            user_id = user_model.create(data)
            user = user_model.find_by_id(user_id)
            token = generate_user_token(user_id, data['email'])
            
            # Fetch all books for initial sync
            books = book_model.find_all()
            
            return jsonify({
                'success': True,
                'token': token,
                'user': user_model.to_dict(user),
                'transactions': [],
                'notifications': [],
                'books': [book_model.to_dict(b) for b in books]
            }), 201
        except Exception as e:
            return jsonify({'error': str(e)}), 500

    @auth_bp.route('/student/guest-register', methods=['POST'])
    def guest_register():
        """Guest registration endpoint"""
        try:
            data = request.get_json()
            
            if not data or not data.get('email') or not data.get('name'):
                return jsonify({'error': 'Name and email are required'}), 400
            
            # Check if email is already registered in guest DB
            if guest_model.find_by_email(data['email']):
                return jsonify({'error': 'Email already registered as guest'}), 400
            
            # Prepare guest data
            guest_data = {
                'name': data['name'],
                'email': data['email'],
                'purpose': data.get('purpose', 'Library Visit'),
                'is_guest': True
            }
            
            from models.book_model import BookModel
            book_model = BookModel(db)
            user_id = guest_model.create(guest_data)
            user = guest_model.find_by_id(user_id)
            token = generate_user_token(user_id, data['email'])
            
            # Fetch all books for initial sync
            books = book_model.find_all()
            
            return jsonify({
                'success': True,
                'token': token,
                'user': guest_model.to_dict(user),
                'transactions': [],
                'notifications': [],
                'books': [book_model.to_dict(b) for b in books]
            }), 201
        except Exception as e:
            return jsonify({'error': str(e)}), 500

    @auth_bp.route('/student/forgot-password', methods=['POST'])
    def forgot_password():
        """Request an OTP for password reset"""
        try:
            data = request.get_json()
            user_model = UserModel(db)
            
            if not data or not data.get('email'):
                return jsonify({'error': 'Email is required'}), 400
                
            user = user_model.find_by_email(data['email'])
            if not user:
                # Security best practice: don't reveal if email exists
                return jsonify({'success': True, 'message': 'If the email is registered, an OTP has been sent'}), 200
                
            # Generate 6-digit OTP
            import random
            otp = "".join([str(random.randint(0, 9)) for _ in range(6)])
            
            # Save OTP to DB
            user_model.set_otp(user['_id'], otp)
            
            # Send real email using Flask-Mail
            try:
                msg = Message(
                    'Your Library Account OTP',
                    recipients=[data['email']]
                )
                msg.html = f"""
                <div style="font-family: sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 10px;">
                    <h2 style="color: #1A237E; text-align: center;">Library Management System</h2>
                    <hr style="border: 0; border-top: 1px solid #eee;">
                    <p>Hello {user.get('name', 'Student')},</p>
                    <p>You have requested a password reset for your library account. Please use the following One-Time Password (OTP) to proceed:</p>
                    <div style="background-color: #f5f5f5; padding: 15px; border-radius: 5px; text-align: center; font-size: 24px; font-weight: bold; letter-spacing: 5px; color: #1A237E; margin: 20px 0;">
                        {otp}
                    </div>
                    <p style="color: #666; font-size: 14px;">This OTP is valid for 10 minutes. If you did not request this, please ignore this email.</p>
                    <hr style="border: 0; border-top: 1px solid #eee;">
                    <p style="color: #888; font-size: 12px; text-align: center;">&copy; 2026 Library Management System | GCEDPI</p>
                </div>
                """
                mail.send(msg)
                print(f"[MAIL SUCCESS] OTP sent to {data['email']}")
            except Exception as mail_err:
                print(f"[MAIL ERROR] Failed to send email: {str(mail_err)}")
                # For development, we still log the OTP so the user can continue
                print(f"[FALLBACK LOG] OTP for {data['email']}: {otp}")
            
            return jsonify({
                'success': True,
                'message': 'OTP sent successfully'
            }), 200
        except Exception as e:
            return jsonify({'error': str(e)}), 500

    @auth_bp.route('/student/verify-otp', methods=['POST'])
    def verify_otp():
        """Endpoint to explicitly verify OTP before allowing password change"""
        try:
            data = request.get_json()
            user_model = UserModel(db)
            
            if not data or not all(k in data for k in ('email', 'otp')):
                return jsonify({'error': 'Email and OTP are required'}), 400
                
            user = user_model.find_by_email(data['email'])
            if not user:
                return jsonify({'error': 'User not found'}), 404
                
            if user_model.verify_otp(user['_id'], data['otp']):
                return jsonify({'success': True, 'message': 'OTP verified successfully'}), 200
            else:
                return jsonify({'error': 'Invalid or expired OTP'}), 400
        except Exception as e:
            return jsonify({'error': str(e)}), 500

    @auth_bp.route('/student/reset-password', methods=['POST'])
    def reset_password():
        """Verify OTP and reset password"""
        try:
            data = request.get_json()
            user_model = UserModel(db)
            
            if not data or not all(k in data for k in ('email', 'otp', 'new_password')):
                return jsonify({'error': 'Email, OTP and new password are required'}), 400
                
            user = user_model.find_by_email(data['email'])
            if not user:
                return jsonify({'error': 'User not found'}), 404
                
            if not user_model.verify_otp(user['_id'], data['otp']):
                return jsonify({'error': 'Invalid or expired OTP'}), 400
                
            user_model.reset_password(user['_id'], data['new_password'])
            
            return jsonify({
                'success': True,
                'message': 'Password reset successfully'
            }), 200
        except Exception as e:
            return jsonify({'error': str(e)}), 500

    @auth_bp.route('/student/rent-books', methods=['POST'])
    @token_required
    def student_rent_books():
        """Student endpoint to rent books online (creates PENDING transaction)"""
        try:
            from models.book_model import BookModel
            from utils.fine_calculator import calculate_rental_due_date
            from config import Config
            
            user_id = ObjectId(request.user_id)
            
            import logging
            logger = logging.getLogger(__name__)
            
            # Diagnostic logs (using logger for persistence in backend_debug.log)
            logger.info(f"DEBUG: student_rent_books - Content-Type: {request.content_type}")
            
            data = request.get_json(silent=True)
            logger.info(f"DEBUG: student_rent_books - Parsed JSON: {data}")
            
            if not data or not isinstance(data, dict):
                logger.error(f"DEBUG: student_rent_books - Invalid/Missing JSON")
                return jsonify({'error': 'Invalid request data format', 'success': False}), 400
            
            # Support both old 'book_ids' and new 'items' payload
            items_input = data.get('items', [])
            if not items_input and 'book_ids' in data:
                items_input = [{'book_id': bid} for bid in data.get('book_ids', [])]
            
            logger.info(f"DEBUG: student_rent_books - PROCESSED ITEMS: {items_input}")
            for idx, item in enumerate(items_input):
                 logger.info(f"DEBUG ITEM {idx}: ID={item.get('book_id')}, Barcode={item.get('barcode', 'N/A')}, RFID={item.get('rfid', 'N/A')}")

            if not items_input:
                error_msg = f"No books selected. Items: {len(items_input) if items_input else 0}. Keys: {list(data.keys())}"
                logger.error(f"DEBUG: student_rent_books ERROR - {error_msg}")
                return jsonify({
                    'success': False,
                    'error': error_msg,
                    'debug_data': data
                }), 400
                
            # 1. Check current limits (Rentals + Reservations + Pending Tx)
            active_rentals_count = db.renting.aggregate([
                {'$match': {'user_id': user_id, 'status': 'ACTIVE'}},
                {'$project': {'count': {'$size': {'$filter': {
                    'input': '$books',
                    'as': 'book',
                    'cond': {'$eq': ['$$book.returned', False]}
                }}}}},
                {'$group': {'_id': None, 'total': {'$sum': '$count'}}}
            ])
            rentals_count = list(active_rentals_count)[0]['total'] if active_rentals_count.alive else 0
            
            # Aggregate doesn't return count easily if empty, so let's do a simpler check
            rentals_count = 0
            active_rentals = list(db.renting.find({'user_id': user_id, 'status': 'ACTIVE'}))
            for r in active_rentals:
                rentals_count += len([b for b in r.get('books', []) if not b.get('returned', False)])

            reservations_count = db.reservations.count_documents({'user_id': user_id, 'status': 'ACTIVE'})
            pending_tx_count = db.transactions.count_documents({
                'user_id': user_id, 
                'status': 'PENDING',
                'type': 'RENTAL'
            })
            
            # Exclude reservations from the active loan count as per user request
            total_active = rentals_count + pending_tx_count
            incoming_count = len(items_input)
            
            if total_active + incoming_count > Config.MAX_BOOKS_PER_RENTAL:
                return jsonify({
                    'error': f'Limit reached! You can only have {Config.MAX_BOOKS_PER_RENTAL} active rentals total. '
                             f'Currently you have {total_active} (Rentals: {rentals_count}, '
                             f'Pending: {pending_tx_count}).'
                }), 400

            # 1.5 Check if user already has any of these books (no multiple copies)
            currently_held_ids = set()
            
            # From active rentals
            active_rentals = list(db.renting.find({'user_id': user_id, 'status': 'ACTIVE'}))
            logger.info(f"DEBUG: Found {len(active_rentals)} active rentals for user {user_id}")
            for r in active_rentals:
                for b in r.get('books', []):
                    if not b.get('returned', False):
                        currently_held_ids.add(str(b['book_id']))
                        
            # From active reservations
            active_reservations = list(db.reservations.find({'user_id': user_id, 'status': 'ACTIVE'}))
            logger.info(f"DEBUG: Found {len(active_reservations)} active reservations for user {user_id}")
            for res in active_reservations:
                currently_held_ids.add(str(res['book_id']))
                
            # From pending transactions
            pending_transactions = list(db.transactions.find({
                'user_id': user_id, 
                'status': 'PENDING',
                'type': 'RENTAL'
            }))
            logger.info(f"DEBUG: Found {len(pending_transactions)} pending transactions for user {user_id}")
            for tx in pending_transactions:
                for item in tx.get('items', []):
                    currently_held_ids.add(str(item['book_id']))
            
            logger.info(f"DEBUG: currently_held_ids in DB: {currently_held_ids}")
            
            # CRITICAL FIX: Also check if user already has a copy allocated in books.copies
            # BUT: We should ONLY block if the allocated copy is NOT the one they are trying to rent now.
            # Actually, the logic should be: You can only have ONE copy of each book TOTAL.
            for item in items_input:
                bid = item['book_id']
                book_doc = db.books.find_one({'_id': ObjectId(bid)})
                if book_doc:
                    # Check if any copy is already issued to this user
                    already_issued_copy = None
                    for copy in book_doc.get('copies', []):
                        if copy.get('issued_to') and str(copy.get('issued_to')) == str(user_id):
                            already_issued_copy = copy
                            break
                    
                    if already_issued_copy:
                        # If a copy is already issued to this user, we must check if it's the SAME RFID
                        # If they are trying to rent the SAME RFID they already have allocated, let it pass (adjust_availability will handle it)
                        # If they already have a DIFFERENT copy, block it.
                        requested_rfid = str(item.get('rfid', ''))
                        issued_rfid = str(already_issued_copy.get('rfid', ''))
                        
                        if requested_rfid and issued_rfid and requested_rfid != issued_rfid:
                            title = book_doc.get('title', 'Unknown Book')
                            logger.warning(f"User {user_id} already has a DIFFERENT copy of book {bid} allocated (Already has {issued_rfid}, requested {requested_rfid})")
                            return jsonify({
                                'error': f"You already have a different copy of '{title}' allocated (RFID: {issued_rfid}). "
                                         "Please return it before renting another copy."
                            }), 400
                        
                        # Note: If it's the same RFID, we allow it to proceed to adjust_availability, 
                        # which I've fixed to allow re-matching an already issued copy.

            # Check for duplicates in the new request against DB state
            for item in items_input:
                bid = item['book_id']
                if str(bid) in currently_held_ids:
                    # Find book title for better error message
                    book_info = db.books.find_one({'_id': ObjectId(bid)})
                    title = book_info.get('title', 'Unknown Book') if book_info else 'Unknown Book'
                    logger.warning(f"User {user_id} duplicate check failed for book {bid} (Already in currently_held_ids)")
                    return jsonify({
                        'error': f"You already have an active rental, reservation, or pending request for '{title}'. "
                                 "You can only have one copy of each book."
                    }), 400

            # 2. Process books and availability
            book_model = BookModel(db)
            items = []
            decremented_ids = []
            due_date = calculate_rental_due_date()
            
            try:
                for item in items_input:
                    bid = item['book_id']
                    barcode = item.get('barcode')
                    rfid = item.get('rfid')
                    
                    book = book_model.find_by_id(bid)
                    if not book:
                        raise ValueError(f"Book {bid} not found")
                    
                    # Atomic issue of specific copy if barcode/rfid is provided
                    allocation_result = book_model.adjust_availability(bid, -1, user_id=user_id, barcode=barcode, rfid=rfid)
                    
                    # Check if allocation was successful
                    if not allocation_result or not allocation_result.get('success'):
                        # Build a helpful error message
                        if rfid:
                            raise ValueError(f"Book '{book['title']}' with RFID '{rfid}' is not available. It may already be issued to someone else.")
                        elif barcode:
                            raise ValueError(f"Book '{book['title']}' with barcode '{barcode}' is not available. It may already be issued to someone else.")
                        else:
                            raise ValueError(f"Book '{book['title']}' is not available")
                    
                    # Get the allocated copy details from the result
                    allocated_copy = allocation_result.get('allocated_copy', {})
                    
                    # Verify that the allocated copy matches the requested RFID (if provided)
                    if rfid and allocated_copy.get('rfid') != rfid:
                        # This should not happen, but if it does, rollback and fail
                        logger.error(f"CRITICAL: Allocation Mismatch! Requested RFID {rfid} but allocated {allocated_copy.get('rfid')}")
                        raise ValueError(f"Failed to allocate the correct copy of '{book['title']}'. Please try again.")
                    
                    decremented_ids.append(bid)
                    items.append({
                        'book_id': str(bid),
                        'title': book['title'],
                        'author': book.get('author', ''),
                        'barcode': allocated_copy.get('barcode', ''),
                        'rfid': allocated_copy.get('rfid', '')
                    })
            except ValueError as ve:
                # Rollback availability
                for d_id in decremented_ids:
                    book_model.adjust_availability(d_id, 1, user_id=user_id)
                return jsonify({'error': str(ve)}), 400

            # 3. Create Transaction as APPROVED (Instant Rental)
            txn_data = {
                'user_id': str(user_id),
                'items': items,
                'type': 'RENTAL',
                'status': 'APPROVED',
                'approved_at': datetime.now(),
                'due_date': due_date,
                'message': f'Online rental for {len(items)} book(s)'
            }
            
            _, txn_id = transaction_model.create(txn_data)
            
            # 4. Immediately create/update Renting record
            books_to_rent = []
            for item in items:
                books_to_rent.append({
                    'book_id': ObjectId(item['book_id']),
                    'barcode': item.get('barcode', ''),
                    'rfid': item.get('rfid', ''),
                    'title': item['title'],
                    'author': item.get('author', ''),
                    'rented_at': datetime.now(),
                    'due_date': due_date,
                    'returned': False,
                    'fine_accrued': 0
                })

            active_rental = db.renting.find_one({
                'user_id': user_id,
                'status': 'ACTIVE'
            })
            
            if active_rental:
                db.renting.update_one(
                    {'_id': active_rental['_id']},
                    {'$push': {'books': {'$each': books_to_rent}}}
                )
            else:
                db.renting.insert_one({
                    'user_id': user_id,
                    'books': books_to_rent,
                    'total_fine': 0,
                    'status': 'ACTIVE'
                })

            # 5. Generate QR Payload for verification (not approval)
            qr_payload = {
                'purpose': 'VERIFICATION',
                'transaction_id': txn_id,
                'user_id': str(user_id)
            }
            db.transactions.update_one(
                {'transaction_id': txn_id},
                {'$set': {
                    'qr_payload': qr_payload,
                    'modified_at': datetime.now()
                }}
            )

            # Return full transaction object for immediate UI update
            full_transaction = transaction_model.find_by_id(txn_id)
            
            return jsonify({
                'success': True,
                'message': 'Rental completed successfully! You can pick up the books now.',
                'data': transaction_model.to_dict(full_transaction)
            }), 201

        except Exception as e:
            return jsonify({'error': str(e)}), 500

    @auth_bp.route('/student/sync', methods=['GET'])
    @token_required
    def student_sync():
        """Fetch delta updates for the authenticated student"""
        import datetime
        import logging
        import traceback
        from bson import ObjectId
        logger = logging.getLogger(__name__)
        try:
            user_id = ObjectId(request.user_id)
            last_sync_str = request.args.get('last_sync', '')
            
            # Fetch transactions and notifications (Restored)
            transactions = transaction_model.find_by_user(user_id)
            notifications = notification_model.find_by_user(user_id)
            
            # Fetch fines
            fines = list(db.fines.find({'user_id': user_id}))
            
            logger.info(f"DEBUG: Sync for user {user_id}. Found {len(transactions)} total transactions in DB.")
            
            if last_sync_str:
                try:
                    last_sync = datetime.datetime.fromisoformat(last_sync_str.replace('Z', '+00:00')).replace(tzinfo=None)
                    logger.info(f"DEBUG: Client last_sync: {last_sync} (Naive)")
                    
                    # Robust delta sync: check all relevant timestamps
                    def is_new(item):
                        for field in ['modified_at', 'approved_at', 'created_at', 'issued_date', 'paid_date']:
                            val = item.get(field)
                            if val and isinstance(val, datetime.datetime):
                                # Ensure val is naive for comparison
                                if val.tzinfo is not None:
                                    val = val.replace(tzinfo=None)
                                
                                if val > last_sync:
                                    logger.info(f"DEBUG: New Item Found! {item.get('_id')} {field}={val} > {last_sync}")
                                    return True
                        return False
                    
                    transactions = [t for t in transactions if is_new(t)]
                    notifications = [n for n in notifications if is_new(n)] # Using same is_new logic
                    # fines = [f for f in fines if is_new(f)] # ALWAYS sync all fines to ensure consistency
                    logger.info(f"DEBUG: After filtering, sending {len(transactions)} transactions.")
                except ValueError as ve:
                    logger.error(f"DEBUG: Date parsing error: {ve}")
                    pass
                except Exception as ex:
                    logger.error(f"DEBUG: Filter error: {ex}")
                    pass
            
            # Fetch active reservations (always sync reservations to ensure time limits are fresh)
            reservations = list(db.reservations.find({'user_id': user_id, 'status': 'ACTIVE'}))
            
            # Fetch active rentals
            active_rentals = list(db.renting.find({'user_id': user_id, 'status': 'ACTIVE'}))
            rented_books = []
            for rental in active_rentals:
                for b in rental.get('books', []):
                    if not b.get('returned', False):
                        book_info = db.books.find_one({'_id': b['book_id']})
                        rented_books.append({
                            'book_id': str(b['book_id']),
                            'book_title': book_info.get('title', 'Unknown') if book_info else 'Unknown',
                            'due_date': b['due_date'].isoformat() if hasattr(b.get('due_date'), 'isoformat') else b.get('due_date'),
                            'rental_id': str(rental['_id']),
                            'rfid': b.get('rfid', ''),
                            'barcode': b.get('barcode', '')
                        })

            logger.info(f"DEBUG: Student Sync - User ID: {user_id} - Found {len(reservations)} active reservations, {len(rented_books)} active rented books")
            
            return jsonify({
                'success': True,
                'transactions': [transaction_model.to_dict(t) for t in transactions],
                'notifications': [notification_model.to_dict(n) for n in notifications],
                'reservations': [{
                    'id': str(r['_id']),
                    'book_id': str(r['book_id']),
                    'book_title': db.books.find_one({'_id': r['book_id']}).get('title', 'Unknown') if db.books.find_one({'_id': r['book_id']}) else 'Unknown',
                    'reserved_at': r['reserved_at'].isoformat(),
                    'expires_at': r['expires_at'].isoformat(),
                    'status': r['status']
                } for r in reservations],
                'rentals': rented_books,
                'fines': [{
                    'id': str(f['_id']),
                    'amount': f.get('amount', 0.0),
                    'reason': f.get('reason', 'Fine'),
                    'status': f.get('status', 'PENDING'),
                    'date': f['issued_date'].isoformat() if isinstance(f.get('issued_date'), datetime.datetime) else f.get('issued_date'),
                    'paid_date': f['paid_date'].isoformat() if f.get('paid_date') and isinstance(f.get('paid_date'), datetime.datetime) else None,
                    'transaction_id': str(f.get('transaction_id', '')),
                    'book_id': str(f.get('book_id', '')),
                    'book_title': f.get('book_title', 'Unknown'),
                    'author': f.get('author', ''),
                    'rfid': f.get('rfid', '')
                } for f in fines],
                'server_time': datetime.datetime.now().isoformat()
            }), 200
        except Exception as e:
            return jsonify({'error': str(e)}), 500

    return auth_bp
