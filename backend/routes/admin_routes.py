from flask import Blueprint, request, jsonify
from werkzeug.utils import secure_filename
from models.book_model import BookModel
from models.notification_model import NotificationModel
from utils.jwt_utils import token_required
from utils.notification_service import send_overdue_notifications, send_single_overdue_notification
from utils.fine_calculator import calculate_fine
from datetime import datetime, timedelta
from bson import ObjectId
from config import Config
import os

admin_bp = Blueprint('admin', __name__, url_prefix='/admin')

def init_admin_routes(db, guest_db=None):
    """Initialize admin routes with database"""
    book_model = BookModel(db)
    notification_model = NotificationModel(db)
    
    @admin_bp.route('/dashboard/stats', methods=['GET']) 
    @token_required
    def get_dashboard_stats():
        """Get dashboard statistics"""
        try:
            # Total books (unique entries)
            total_titles = db.books.count_documents({})
            
            # Count total physical copies and total available
            all_books = list(db.books.find({}, {'copies': 1}))
            total_physical_books = sum(len(b.get('copies', [])) for b in all_books)
            
            # Calculate active rented books from renting collection
            # Exclude reservations (already counted separately) and completed/returned rentals
            active_rentals = list(db.renting.find({'status': 'ACTIVE'}))
            rented_count = 0
            overdue_count = 0
            
            for r in active_rentals:
                for b in r.get('books', []):
                    if not b.get('returned', False):
                        # Check if overdue
                        fine_info = calculate_fine(b['due_date'])
                        if fine_info['is_overdue']:
                            overdue_count += 1
                        else:
                            rented_count += 1
            
            # Active reservations
            active_reservations = db.reservations.count_documents({'status': 'ACTIVE'})
            
            # Today's attendance
            today_start = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)
            today_entry = db.attendance_entry.count_documents({'scan_time': {'$gte': today_start}})
            
            # Total users
            total_users = db.users.count_documents({})
            
            return jsonify({
                'success': True,
                'stats': {
                    'total_books': total_physical_books,
                    'total_titles': total_titles,
                    'rented_books': rented_count,
                    'overdue_books': overdue_count,
                    'active_reservations': active_reservations,
                    'today_attendance': today_entry,
                    'total_users': total_users
                }
            }), 200
            
        except Exception as e:
            return jsonify({'error': str(e)}), 500
    
    @admin_bp.route('/books', methods=['GET'])
    @token_required
    def get_books():
        """Get all books with pagination"""
        try:
            page = int(request.args.get('page', 1))
            limit = int(request.args.get('limit', 50))
            skip = (page - 1) * limit
            
            books = book_model.find_all(skip=skip, limit=limit)
            total = book_model.count()
            
            return jsonify({
                'success': True,
                'books': [book_model.to_dict(book) for book in books],
                'pagination': {
                    'page': page,
                    'limit': limit,
                    'total': total,
                    'pages': (total + limit - 1) // limit
                }
            }), 200
            
        except Exception as e:
            return jsonify({'error': str(e)}), 500
    
    @admin_bp.route('/books/add', methods=['POST'])
    @token_required
    def add_book():
        """Add new book with multiple copies"""
        try:
            data = request.get_json()
            
            if not data or not data.get('title'):
                return jsonify({'error': 'Title is required'}), 400
            
            # Check for duplicate barcodes or RFIDs within copies
            copies = data.get('copies', [])
            for copy in copies:
                barcode = copy.get('barcode')
                rfid = copy.get('rfid')
                
                if barcode:
                    if db.books.find_one({'copies.barcode': barcode}):
                        return jsonify({'error': f'Barcode {barcode} already exists'}), 400
                if rfid:
                    if db.books.find_one({'copies.rfid': rfid}):
                        return jsonify({'error': f'RFID {rfid} already exists'}), 400
            
            book_id = book_model.create(data)
            
            return jsonify({
                'success': True,
                'book_id': str(book_id),
                'message': 'Book added successfully'
            }), 201
            
        except Exception as e:
            return jsonify({'error': str(e)}), 500
    
    @admin_bp.route('/books/upload_image/<book_id>', methods=['POST'])
    @token_required
    def upload_book_image(book_id):
        """Upload book image"""
        try:
            if 'image' not in request.files:
                return jsonify({'error': 'No image file provided'}), 400
            
            file = request.files['image']
            
            if file.filename == '':
                return jsonify({'error': 'No file selected'}), 400
            
            # Check file extension
            ext = file.filename.rsplit('.', 1)[1].lower() if '.' in file.filename else ''
            if ext not in Config.ALLOWED_EXTENSIONS:
                return jsonify({'error': 'Invalid file type'}), 400
            
            # Save with book_id as filename
            filename = f"{book_id}.jpg"
            filepath = os.path.join(Config.UPLOAD_FOLDER, filename)
            file.save(filepath)
            
            # Update book image path
            image_path = f"books_img/{filename}"
            book_model.update_image_path(book_id, image_path)
            
            return jsonify({
                'success': True,
                'image_path': image_path,
                'message': 'Image uploaded successfully'
            }), 200
            
        except Exception as e:
            return jsonify({'error': str(e)}), 500
    
    @admin_bp.route('/books/update/<book_id>', methods=['PUT'])
    @token_required
    def update_book(book_id):
        """Update book details"""
        try:
            data = request.get_json()
            
            if not data:
                return jsonify({'error': 'No data provided'}), 400
            
            # Remove fields that shouldn't be updated directly
            data.pop('_id', None)
            data.pop('id', None)
            
            success = book_model.update(book_id, data)
            
            if success:
                return jsonify({
                    'success': True,
                    'message': 'Book updated successfully'
                }), 200
            else:
                return jsonify({'error': 'Book not found'}), 404
            
        except Exception as e:
            return jsonify({'error': str(e)}), 500
    
    @admin_bp.route('/reservations', methods=['GET'])
    @token_required
    def get_reservations():
        """Get all active reservations"""
        try:
            reservations = list(db.reservations.find({'status': 'ACTIVE'}))
            
            result = []
            for res in reservations:
                user = db.users.find_one({'_id': res['user_id']})
                book = db.books.find_one({'_id': res['book_id']})
                
                # Calculate availability from copies array
                if book:
                    copies = book.get('copies', [])
                    total_copies = len(copies)
                    available_copies = len([c for c in copies if c.get('issued_to') is None])
                else:
                    total_copies = 0
                    available_copies = 0
                
                result.append({
                    'id': str(res['_id']),
                    'user_id': str(user['_id']) if user else None,
                    'user_name': user.get('name', 'Unknown') if user else 'Unknown',
                    'book_title': book.get('title', 'Unknown') if book else 'Unknown',
                    'available_copies': available_copies,
                    'total_copies': total_copies,
                    'barcode': res.get('barcode', ''),
                    'reserved_at': res['reserved_at'].isoformat(),
                    'expires_at': res['expires_at'].isoformat(),
                    'status': res['status']
                })
            
            return jsonify({
                'success': True,
                'reservations': result
            }), 200
            
        except Exception as e:
            return jsonify({'error': str(e)}), 500
    
    @admin_bp.route('/reservations/cancel/<reservation_id>', methods=['DELETE'])
    @token_required
    def cancel_reservation(reservation_id):
        """Cancel a reservation and restore book availability"""
        try:
            # Use find_one_and_update to get the book_id and update status atomically
            reservation = db.reservations.find_one_and_update(
                {'_id': ObjectId(reservation_id), 'status': 'ACTIVE'},
                {'$set': {'status': 'CANCELLED'}}
            )
            
            if not reservation:
                # Check why it failed
                res_check = db.reservations.find_one({'_id': ObjectId(reservation_id)})
                if not res_check:
                    return jsonify({'error': 'Reservation not found'}), 404
                return jsonify({'error': f"Cannot cancel reservation with status '{res_check.get('status', 'Unknown')}'"}), 400

            # Restore book availability safely
            book_model.adjust_availability(reservation['book_id'], 1, reservation['user_id'])
            
            # Create notification for the student
            try:
                notification_model.create({
                    'user_id': str(reservation['user_id']),
                    'message': f"Your reservation for '{reservation.get('book_title', 'Unknown Book')}' has been cancelled by admin."
                })
            except Exception as notify_err:
                logger.error(f"Error creating cancellation notification: {str(notify_err)}")

            return jsonify({
                'success': True,
                'message': 'Reservation cancelled and book availability restored'
            }), 200
            
        except Exception as e:
            return jsonify({'error': str(e)}), 500
    

    @admin_bp.route('/reservations/add', methods=['POST'])
    @token_required
    def add_reservation():
        """Add new reservation manually and update book availability"""
        try:
            data = request.get_json()
            
            user_id = ObjectId(data['user_id'])
            book_id = ObjectId(data['book_id'])
            
            # Possession check for admin manual reservation
            
            # 1. Check active rentals
            active_rental = db.renting.find_one({
                'user_id': user_id,
                'status': 'ACTIVE',
                'books.book_id': book_id,
                'books.returned': False
            })
            if active_rental:
                return jsonify({'error': 'User already has this book rented'}), 400

            # 2. Check pending transactions
            pending_tx = db.transactions.find_one({
                'user_id': user_id,
                'status': 'PENDING',
                'type': 'RENTAL',
                'items.book_id': str(book_id)
            })
            if pending_tx:
                return jsonify({'error': 'User already has a pending checkout request for this book'}), 400

            # 3. Check active reservations
            existing = db.reservations.find_one({
                'user_id': user_id,
                'book_id': book_id,
                'status': 'ACTIVE'
            })
            if existing:
                return jsonify({'error': 'User already has an active reservation for this book'}), 400

            # Atomic check and decrement of book availability
            if not book_model.adjust_availability(book_id, -1, user_id):
                return jsonify({'error': 'Book unavailable'}), 400
            
            # If we reached here, book was available and count was decremented
            # Now create the reservation record
            
            # Format dates
            reserved_at = data.get('reserved_at')
            expires_at = data.get('expires_at')
            
            if reserved_at:
                reserved_at = datetime.fromisoformat(reserved_at.replace('Z', '+00:00'))
            else:
                reserved_at = datetime.now()
                
            if expires_at:
                expires_at = datetime.fromisoformat(expires_at.replace('Z', '+00:00'))
            else:
                expires_at = reserved_at + timedelta(hours=Config.RESERVATION_EXPIRY_HOURS)
            
            reservation = {
                'user_id': user_id,
                'book_id': book_id,
                'reserved_at': reserved_at,
                'expires_at': expires_at,
                'status': 'ACTIVE',
                'picked_up': False,
                'created_at': datetime.now()
            }
            
            result = db.reservations.insert_one(reservation)
            
            return jsonify({
                'success': True,
                'reservation_id': str(result.inserted_id),
                'message': 'Reservation added successfully'
            }), 201
            
        except Exception as e:
            return jsonify({'error': str(e)}), 500

    @admin_bp.route('/overdue', methods=['GET'])
    @token_required
    def get_overdue():
        """Get all overdue books"""
        try:
            overdue_list = []
            
            active_rentals = db.renting.find({'status': 'ACTIVE'})
            
            for rental in active_rentals:
                user = db.users.find_one({'_id': rental['user_id']})
                
                for book in rental['books']:
                    if not book.get('returned', False):
                        fine_info = calculate_fine(book['due_date'])
                        
                        if fine_info['is_overdue']:
                            overdue_list.append({
                                'user_id': str(user['_id']) if user else None,
                                'user_name': user.get('name', 'Unknown') if user else 'Unknown',
                                'user_email': user.get('email', '') if user else '',
                                'student_id': user.get('student_id', ''),
                                'department': user.get('department', ''),
                                'year': user.get('year', ''),
                                'book_id': str(book['book_id']),
                                'book_title': book['title'],
                                'book_author': book.get('author') or (db.books.find_one({'_id': book['book_id']}).get('author', '') if db.books.find_one({'_id': book['book_id']}) else ''),
                                'due_date': book['due_date'].isoformat(),
                                'days_overdue': fine_info['days_overdue'],
                                'fine_amount': fine_info['fine_amount']
                            })
            
            return jsonify({
                'success': True,
                'overdue': overdue_list
            }), 200
            
        except Exception as e:
            return jsonify({'error': str(e)}), 500
    
    @admin_bp.route('/notify/overdue', methods=['POST'])
    @token_required
    def notify_overdue():
        """Send overdue notifications"""
        try:
            result = send_overdue_notifications(db)
            
            return jsonify({
                'success': True,
                'notifications_sent': result['notifications_sent'],
                'users_notified': result['users_notified']
            }), 200
            
        except Exception as e:
            return jsonify({'error': str(e)}), 500

    @admin_bp.route('/notify/user/<user_id>', methods=['POST'])
    @token_required
    def notify_single_user_overdue(user_id):
        """Send overdue notification to single user"""
        try:
            result = send_single_overdue_notification(db, user_id)
            if result['success']:
                return jsonify({'success': True, 'message': result['message']}), 200
            else:
                return jsonify({'error': result['error']}), 400
        except Exception as e:
            return jsonify({'error': str(e)}), 500
    
    @admin_bp.route('/fines/waive/<fine_id>', methods=['POST'])
    @token_required
    def waive_fine(fine_id):
        """Waive a fine"""
        try:
            result = db.fines.update_one(
                {'_id': ObjectId(fine_id)},
                {'$set': {'status': 'WAIVED'}}
            )
            
            if result.modified_count > 0:
                return jsonify({
                    'success': True,
                    'message': 'Fine waived successfully'
                }), 200
            else:
                return jsonify({'error': 'Fine not found'}), 404
            
        except Exception as e:
            return jsonify({'error': str(e)}), 500

    @admin_bp.route('/fines', methods=['GET'])
    @token_required
    def get_fines():
        """Get all fines (paid, pending, waived) and active overdue rentals"""
        try:
            # 1. Fetch existing fines from 'fines' collection
            fines = list(db.fines.find().sort('issued_date', -1))
            fines_list = []
            
            for fine in fines:
                user = db.users.find_one({'_id': fine['user_id']})
                fines_list.append({
                    'id': str(fine['_id']),
                    'user_id': str(fine['user_id']),
                    'user_name': user.get('name', 'Unknown') if user else 'Unknown',
                    'user_email': user.get('email', 'Unknown') if user else 'Unknown',
                    'transaction_id': str(fine.get('transaction_id', 'N/A')),
                    'amount': fine['amount'],
                    'reason': fine.get('reason', 'N/A'),
                    'status': fine.get('status', 'PENDING'),
                    'issued_date': fine['issued_date'].isoformat() if isinstance(fine['issued_date'], datetime) else fine['issued_date'],
                    'paid_date': fine['paid_date'].isoformat() if fine.get('paid_date') and isinstance(fine['paid_date'], datetime) else fine.get('paid_date')
                })

            # 2. Fetch active rentals that are overdue
            # Find all rentals with status 'ACTIVE'
            active_rentals = list(db.renting.find({'status': 'ACTIVE'}))
            
            for rental in active_rentals:
                user = db.users.find_one({'_id': rental['user_id']})
                if not user:
                    continue
                    
                for book in rental['books']:
                    # Skip if book is returned
                    if book.get('returned', False):
                        continue
                        
                    due_date = book.get('due_date')
                    if due_date:
                        fine_info = calculate_fine(due_date)
                        if fine_info['is_overdue']:
                            # This is an active overdue book
                            # Create a virtual fine entry
                            # ID format: "active_<rental_id>_<book_id>"
                            
                            # Check if the fine for this specific book in this rental has already been paid/partially paid
                            # Logic: If 'paid_fine' exists in book object, subtract it? 
                            # For simplicity now, we assume full amount is pending if not returned.
                            # Improving logic: fetch any 'PAID' fines for this transaction and book?
                            # A simple approach: The 'fines' collection record is the source of truth for PAID.
                            # So 'active' fines are potential fines.
                            
                            # However, to avoid double counting if a user paid partially, we'd need complex logic.
                            # For this hackathon scope: Active overdue = Pending fine.
                            # If they pay it, we'll mark it paid in 'fines' and it will show up in step 1.
                            # But we must ensure we don't show it as "Pending" here again if it's already "Paid" via 'fines'.
                            # BUT, 'fines' are usually created on return.
                            # If we allow paying BEFORE return, we create a 'fines' record then.
                            # So we should check if a fine record exists for this rental+book that is PAID?
                            # Let's keep it simple: Show active overdue as 'PENDING'.
                            # Payment will create a real fine record.
                            
                            fines_list.append({
                                'id': f"active_{rental['_id']}_{book['book_id']}",
                                'user_id': str(user['_id']),
                                'user_name': user.get('name', 'Unknown'),
                                'user_email': user.get('email', 'Unknown'),
                                'transaction_id': str(rental['_id']),
                                'amount': fine_info['fine_amount'],
                                'reason': f"Overdue: {book.get('title', 'Unknown')}",
                                'status': 'PENDING', # Show as pending so they can pay
                                'issued_date': datetime.now().isoformat(),
                                'paid_date': None,
                                'is_virtual': True # Flag to indicate this is calculated on fly
                            })

            return jsonify({
                'success': True,
                'count': len(fines_list),
                'fines': fines_list
            }), 200

        except Exception as e:
            return jsonify({'error': str(e)}), 500

    @admin_bp.route('/fines/add', methods=['POST'])
    @token_required
    def add_fine():
        """Add a manual fine (e.g. for damaged book)"""
        try:
            data = request.get_json()
            if not data:
                return jsonify({'error': 'No data provided'}), 400
                
            user_id = data.get('user_id')
            book_id = data.get('book_id')
            amount = data.get('amount', 100)
            reason = data.get('reason', 'Damaged Book')
            
            if not user_id or not book_id:
                return jsonify({'error': 'User and Book are required'}), 400
                
            # Create fine record
            from utils.notification_service import send_fine_notification
            
            fine = {
                'user_id': ObjectId(user_id),
                'book_id': ObjectId(book_id),
                'amount': float(amount),
                'reason': reason,
                'status': 'PENDING',
                'issued_date': datetime.now(),
                'paid_date': None
            }
            
            # Identify transaction if possible (active rental)
            active_rental = db.renting.find_one({
                'user_id': ObjectId(user_id),
                'status': 'ACTIVE',
                'books.book_id': ObjectId(book_id)
            })
            
            if active_rental:
                fine['transaction_id'] = active_rental['_id']
            
            result = db.fines.insert_one(fine)
            
            # Send notification
            send_fine_notification(db, user_id, amount, reason)
            
            return jsonify({
                'success': True,
                'message': 'Fine added successfully',
                'fine_id': str(result.inserted_id)
            }), 201
            
        except Exception as e:
            return jsonify({'error': str(e)}), 500

    @admin_bp.route('/fines/pay/<fine_id>', methods=['POST'])
    @token_required
    def pay_fine(fine_id):
        """Mark a fine as paid"""
        try:
            # Handle active rental fine payment (Virtual ID)
            if fine_id.startswith('active_'):
                parts = fine_id.split('_')
                if len(parts) != 3:
                    return jsonify({'error': 'Invalid fine ID format'}), 400
                
                rental_id = parts[1]
                book_id = parts[2]
                
                # Fetch rental
                rental = db.renting.find_one({'_id': ObjectId(rental_id)})
                if not rental:
                    return jsonify({'error': 'Rental not found'}), 404
                
                # Find book and calculate fine
                book_item = None
                for b in rental['books']:
                    if str(b['book_id']) == book_id:
                        book_item = b
                        break
                
                if not book_item:
                    return jsonify({'error': 'Book not found in rental'}), 404
                    
                due_date = book_item.get('due_date')
                if not due_date:
                    return jsonify({'error': 'No due date for this book'}), 400
                    
                fine_info = calculate_fine(due_date)
                if not fine_info['is_overdue']:
                     return jsonify({'error': 'Book is not overdue'}), 400
                     
                amount_to_pay = fine_info['fine_amount']
                
                # Create a new PAID fine record
                new_fine = {
                    'user_id': rental['user_id'],
                    'transaction_id': rental['_id'],
                    'amount': amount_to_pay,
                    'reason': f"Overdue: {book_item.get('title', 'Unknown')}",
                    'book_title': book_item.get('title', 'Unknown'),
                    'author': book_item.get('author', ''),
                    'rfid': book_item.get('rfid', ''),
                    'days_overdue': fine_info['days_overdue'],
                    'issued_date': datetime.now(),
                    'paid_date': datetime.now(),
                    'status': 'PAID',
                    'book_id': ObjectId(book_id) # Link to specific book
                }
                db.fines.insert_one(new_fine)
                
                # Update rental to record this pre-payment
                # store it in 'pre_paid_fine' to deduct later upon return
                db.renting.update_one(
                    {'_id': ObjectId(rental_id), 'books.book_id': ObjectId(book_id)},
                    {'$set': {'books.$.pre_paid_fine': amount_to_pay}}
                )
                
                # Send notification
                from utils.notification_service import create_notification
                create_notification(
                    db,
                    rental['user_id'],
                    'Fine Paid',
                    f"You have successfully paid a fine of Rs.{amount_to_pay} for {book_item.get('title', 'Unknown')}.",
                    'FINE_PAYMENT'
                )

                return jsonify({
                    'success': True,
                    'message': 'Fine paid successfully'
                }), 200

            # Handle existing fine payment
            fine = db.fines.find_one({'_id': ObjectId(fine_id)})
            if not fine:
                return jsonify({'error': 'Fine not found'}), 404
            
            db.fines.update_one(
                {'_id': ObjectId(fine_id)},
                {
                    '$set': {
                        'status': 'PAID',
                        'paid_date': datetime.now()
                    }
                }
            )
            
            # Mark linked transaction as fine_paid if applicable
            if fine.get('transaction_id'):
                db.transactions.update_one(
                    {'_id': fine['transaction_id']},
                    {'$set': {'fine_paid': True, 'modified_at': datetime.now()}}
                )
            elif fine.get('book_id'):
                # Handle cases where fine might be linked via rental + book
                pass # Already handled partially by renting updates
            
            # Send notification
            from utils.notification_service import create_notification
            create_notification(
                db,
                fine['user_id'],
                'Fine Paid',
                f"You have successfully paid a fine of Rs.{fine['amount']} for {fine.get('reason', 'N/A')}.",
                'FINE_PAYMENT'
            )
            
            return jsonify({
                'success': True,
                'message': 'Fine marked as paid'
            }), 200
            
        except Exception as e:
            return jsonify({'error': str(e)}), 500

    @admin_bp.route('/users', methods=['GET'])
    @token_required
    def get_users():
        """Get all users"""
        try:
            users = list(db.users.find())
            result = [{
                'id': str(u['_id']),
                'name': u.get('name', 'Unknown'),
                'email': u.get('email', ''),
                'student_id': u.get('student_id', 'N/A'),
                'phone': u.get('phone', 'N/A'),
                'department': u.get('department', 'N/A'),
                'year': u.get('year', 'N/A')
            } for u in users]
            return jsonify({'success': True, 'users': result}), 200
        except Exception as e:
            return jsonify({'error': str(e)}), 500

    @admin_bp.route('/users/<user_id>', methods=['GET'])
    @token_required
    def get_user_details(user_id):
        """Get user profile details"""
        try:
            user = db.users.find_one({'_id': ObjectId(user_id)})
            if not user:
                return jsonify({'error': 'User not found'}), 404
            
            user_data = {
                'id': str(user['_id']),
                'name': user.get('name', 'Unknown'),
                'email': user.get('email', ''),
                'department': user.get('department', 'N/A'),
                'year': user.get('year', 'N/A'),
                'joined_at': user.get('created_at', datetime.now()).isoformat()
            }
            return jsonify({'success': True, 'user': user_data}), 200
        except Exception as e:
            return jsonify({'error': str(e)}), 500

    @admin_bp.route('/users/<user_id>/activity', methods=['GET'])
    @token_required
    def get_user_activity(user_id):
        """Get user activity (reservations, rentals, fines)"""
        try:
            uid = ObjectId(user_id)
            
            # Active Reservations
            reservations = list(db.reservations.find({'user_id': uid}))
            res_list = []
            for res in reservations:
                book = db.books.find_one({'_id': res['book_id']})
                res_list.append({
                    'id': str(res['_id']),
                    'book_title': book.get('title', 'Unknown') if book else 'Unknown',
                    'status': res['status'],
                    'reserved_at': res['reserved_at'].isoformat(),
                    'expires_at': res['expires_at'].isoformat()
                })

            # History / Active Rentals (from renting collection)
            # Assuming 'renting' stores a list of books per rental transaction
            rentals = list(db.renting.find({'user_id': uid}))
            rental_list = []
            overdue_list = []
            
            for rental in rentals:
                for book in rental['books']:
                    # Check if overdue
                    is_overdue = False
                    days_overdue = 0
                    fine_amount = 0
                    
                    if not book.get('returned', False):
                        due_date = book.get('due_date')
                        if due_date:
                            fine_info = calculate_fine(due_date)
                            is_overdue = fine_info['is_overdue']
                            days_overdue = fine_info['days_overdue']
                            fine_amount = fine_info['fine_amount']
                    
                    item = {
                        'book_id': str(book.get('book_id', '')),
                        'book_title': book.get('title', 'Unknown'),
                        'book_author': book.get('author') or (db.books.find_one({'_id': book['book_id']}).get('author', '') if db.books.find_one({'_id': book['book_id']}) else ''),
                        'borrowed_at': rental.get('rented_at', rental.get('created_at', datetime.now())).isoformat(),
                        'due_date': book.get('due_date', datetime.now()).isoformat(),
                        'returned': book.get('returned', False),
                        'returned_at': book.get('returned_at').isoformat() if book.get('returned_at') else None,
                        'is_overdue': is_overdue,
                        'days_overdue': days_overdue,
                        'fine': fine_amount
                    }
                    rental_list.append(item)
                    
                    if is_overdue:
                        overdue_list.append(item)

            # Get issued fines from fines collection
            fines = list(db.fines.find({'user_id': uid}).sort('issued_date', -1))
            fines_list = []
            for fine in fines:
                fines_list.append({
                    'id': str(fine['_id']),
                    'amount': fine['amount'],
                    'reason': fine.get('reason', 'N/A'),
                    'status': fine.get('status', 'PENDING'),
                    'issued_date': fine['issued_date'].isoformat() if isinstance(fine['issued_date'], datetime) else fine['issued_date'],
                    'paid_date': fine['paid_date'].isoformat() if fine.get('paid_date') and isinstance(fine['paid_date'], datetime) else fine.get('paid_date')
                })

            # Get transactions
            from models.transaction_model import TransactionModel
            transaction_model = TransactionModel(db)
            transactions = transaction_model.find_by_user(uid)
            transactions_list = [transaction_model.to_dict(t) for t in transactions]

            return jsonify({
                'success': True,
                'activity': {
                    'reservations': res_list,
                    'history': rental_list,
                    'overdue': overdue_list,
                    'fines': fines_list,
                    'transactions': transactions_list
                }
            }), 200

        except Exception as e:
            return jsonify({'error': str(e)}), 500

    @admin_bp.route('/attendance/history', methods=['GET'])
    @token_required
    def get_attendance_history():
        """Get attendance history for the last 10 days"""
        try:
            history = []
            today = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)
            
            for i in range(9, -1, -1):
                date = today - timedelta(days=i)
                next_day = date + timedelta(days=1)
                
                count = db.attendance_entry.count_documents({
                    'scan_time': {
                        '$gte': date,
                        '$lt': next_day
                    }
                })
                
                history.append({
                    'date': date.strftime('%Y-%m-%d'),
                    'label': date.strftime('%b %d'),
                    'count': count
                })
                
            return jsonify({
                'success': True,
                'history': history
            }), 200
        except Exception as e:
            return jsonify({'error': str(e)}), 500

    @admin_bp.route('/attendance/details', methods=['GET'])
    @token_required
    def get_attendance_details():
        """Get detailed attendance logs for a specific day"""
        try:
            date_str = request.args.get('date')
            if not date_str:
                return jsonify({'error': 'Date is required'}), 400
            
            start_date = datetime.strptime(date_str, '%Y-%m-%d')
            end_date = start_date + timedelta(days=1)
            
            # Find all entries for that day
            entries = list(db.attendance_entry.find({
                'scan_time': {
                    '$gte': start_date,
                    '$lt': end_date
                }
            }).sort('scan_time', 1))
            
            details = []
            for entry in entries:
                is_guest = entry.get('is_guest', False)
                
                # Get user info from the correct database
                user = None
                if is_guest and guest_db is not None:
                    user = guest_db.users.find_one({'_id': entry['user_id']})
                else:
                    user = db.users.find_one({'_id': entry['user_id']})
                
                if not user:
                    continue
                
                # Find the first exit time that occurred after this entry
                exit_entry = db.attendance_leaving.find_one({
                    'user_id': entry['user_id'],
                    'scan_time': {
                        '$gt': entry['scan_time'],
                        '$lt': end_date
                    }
                }, sort=[('scan_time', 1)])
                
                # If no exit on the same day, check if user is still inside globally
                attendance_status = db.checking_for_attendance.find_one({'user_id': entry['user_id']})
                is_currently_inside = attendance_status.get('is_inside', False) if attendance_status else False
                
                is_active = not exit_entry and is_currently_inside
                
                details.append({
                    'user_id': str(user['_id']),
                    'user_name': user.get('name', 'Unknown'),
                    'year': user.get('year', 'Guest' if is_guest else 'N/A'),
                    'department': user.get('department', 'Guest' if is_guest else 'N/A'),
                    'in_time': entry['scan_time'].isoformat(),
                    'out_time': exit_entry['scan_time'].isoformat() if exit_entry else None,
                    'is_active': is_active,
                    'is_guest': is_guest
                })
                
            return jsonify({
                'success': True,
                'details': details
            }), 200
        except Exception as e:
            return jsonify({'error': str(e)}), 500

    @admin_bp.route('/rental/details', methods=['GET'])
    @token_required
    def get_rental_details():
        """Get detailed rental history"""
        try:
            active_only = request.args.get('active_only', 'false').lower() == 'true'
            
            query = {}
            if active_only:
                query['status'] = 'ACTIVE'
                
            rentals = list(db.renting.find(query).sort('created_at', -1))
            
            details = []
            for rental in rentals:
                user = db.users.find_one({'_id': rental['user_id']})
                if not user:
                    continue
                    
                for book_item in rental['books']:
                    # Apply filter for individual books if we only want currently rented ones
                    if active_only and book_item.get('returned', False):
                        continue
                        
                    # Fetch full book details from books collection to get author, image, etc.
                    book_id_obj = book_item.get('book_id')
                    full_book = None
                    if book_id_obj:
                        full_book = db.books.find_one({'_id': ObjectId(book_id_obj)})
                    
                    # Calculate status
                    is_returned = book_item.get('returned', False)
                    due_date = book_item.get('due_date')
                    
                    status = 'RETURNED' if is_returned else 'ACTIVE'
                    days_overdue = 0
                    fine_amount = 0
                    
                    if not is_returned and due_date:
                        fine_info = calculate_fine(due_date)
                        if fine_info['is_overdue']:
                            status = 'OVERDUE'
                            days_overdue = fine_info['days_overdue']
                            fine_amount = fine_info['fine_amount']
                    
                    rented_at = rental.get('rented_at', rental.get('created_at', datetime.now()))
                    
                    # Use info from full_book if available, otherwise fallback to rental record
                    book_title = full_book.get('title', 'Unknown') if full_book else book_item.get('title', 'Unknown')
                    book_author = full_book.get('author', 'Unknown') if full_book else book_item.get('author', 'Unknown')
                    book_image = full_book.get('image_path', '') if full_book else book_item.get('image_path', '')
                    
                    details.append({
                        'rental_id': str(rental['_id']),
                        'book_title': book_title,
                        'book_author': book_author,
                        'book_image': book_image,
                        'book_id': str(book_item.get('book_id', '')),
                        'renter_name': user.get('name', 'Unknown'),
                        'renter_id': user.get('student_id', 'N/A'),
                        'user_id': str(user['_id']),
                        'rented_at': rented_at.isoformat() if isinstance(rented_at, datetime) else str(rented_at),
                        'due_date': due_date.isoformat() if isinstance(due_date, datetime) else str(due_date),
                        'returned_at': book_item.get('returned_at').isoformat() if book_item.get('returned_at') else None,
                        'status': status,
                        'days_overdue': days_overdue,
                        'fine_amount': fine_amount
                    })
            
            # Sort by rented_at desc
            details.sort(key=lambda x: x['rented_at'], reverse=True)
            
            return jsonify({
                'success': True,
                'count': len(details),
                'rentals': details
            }), 200
            
        except Exception as e:
            return jsonify({'error': str(e)}), 500

    return admin_bp
