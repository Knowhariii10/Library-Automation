from flask import Blueprint, request, jsonify
from datetime import datetime, timedelta
from bson import ObjectId
from models.book_model import BookModel
from utils.jwt_utils import token_required
from config import Config

user_bp = Blueprint('user', __name__, url_prefix='/user')

def init_user_routes(db):
    book_model = BookModel(db)
    
    @user_bp.route('/books', methods=['GET'])
    def get_public_books():
        """Get all books for public view"""
        try:
            books = book_model.find_all()
            result = [book_model.to_dict(book) for book in books]
            print(f"DEBUG: Returning {len(result)} books")
            return jsonify({
                'success': True,
                'books': result
            }), 200
        except Exception as e:
            print(f"DEBUG Error: {str(e)}")
            return jsonify({'error': str(e)}), 500

    @user_bp.route('/books/by-barcode/<barcode>', methods=['GET'])
    def get_book_by_barcode(barcode):
        """Get book details by barcode OR RFID including specific copy's info"""
        try:
            print(f"DEBUG: get_book_by_barcode called with '{barcode}' (len={len(barcode)})")
            
            # 1. Try to find by barcode
            book = book_model.find_by_barcode(barcode)
            found_by = 'barcode'
            
            # 2. If not found, try to find by RFID (since scanner might send RFID as 'barcode')
            if not book:
                book = book_model.find_by_rfid(barcode)
                found_by = 'rfid'
            
            if not book:
                return jsonify({
                    'success': False,
                    'error': 'Book not found for this code'
                }), 404
            
            # Find the specific copy
            specific_copy = None
            if found_by == 'barcode':
                specific_copy = next(
                    (c for c in book.get('copies', []) if c.get('barcode') == barcode),
                    None
                )
            else:
                specific_copy = next(
                    (c for c in book.get('copies', []) if c.get('rfid') == barcode),
                    None
                )
            
            if not specific_copy:
                return jsonify({
                    'success': False,
                    'error': 'Copy not found'
                }), 404
            
            # Check if this copy is already issued
            is_available = specific_copy.get('issued_to') is None
            
            # Prepare response with book details and specific copy info
            book_dict = book_model.to_dict(book)
            book_dict['scanned_copy'] = {
                'barcode': specific_copy.get('barcode', ''),
                'rfid': specific_copy.get('rfid', ''),
                'is_available': is_available,
                'issued_to': str(specific_copy['issued_to']) if specific_copy.get('issued_to') else None
            }
            
            return jsonify({
                'success': True,
                'book': book_dict
            }), 200
            
        except Exception as e:
            print(f"DEBUG Error in get_book_by_barcode: {str(e)}")
            return jsonify({'error': str(e)}), 500

    @user_bp.route('/reserve', methods=['POST'])
    @token_required
    def reserve_book():
        """
        Reserve a book for a user.
        Decreases availability immediately upon reservation.
        """
        try:
            data = request.get_json()
            if not data or 'book_id' not in data:
                return jsonify({'error': 'Book ID is required'}), 400
                
            user_id = ObjectId(request.user_id) # Set by token_required
            book_id = ObjectId(data['book_id'])
            
            # Check if user already possesses this book (rented or pending)
            
            # 1. Check active rentals
            active_rental = db.renting.find_one({
                'user_id': user_id,
                'status': 'ACTIVE',
                'books.book_id': book_id,
                'books.returned': False
            })
            if active_rental:
                return jsonify({'error': 'You already have this book rented. Return it before reserving again.'}), 400

            # 2. Check pending transactions
            pending_tx = db.transactions.find_one({
                'user_id': user_id,
                'status': 'PENDING',
                'type': 'RENTAL',
                'items.book_id': str(book_id)
            })
            if pending_tx:
                return jsonify({'error': 'You already have a pending checkout request for this book.'}), 400

            # 3. Check for existing active reservation for this book
            existing = db.reservations.find_one({
                'user_id': user_id,
                'book_id': book_id,
                'status': 'ACTIVE'
            })
            
            if existing:
                return jsonify({'error': 'You already have an active reservation for this book'}), 400

            # 4. Check max books limit (3 books total: active rentals + active reservations + pending transactions)
            # Count active rentals
            active_rentals = list(db.renting.find({
                'user_id': user_id,
                'status': 'ACTIVE'
            }))
            active_rental_count = 0
            for rental in active_rentals:
                active_rental_count += len([b for b in rental.get('books', []) if not b.get('returned', False)])
            
            # Count active reservations
            active_reservation_count = db.reservations.count_documents({
                'user_id': user_id,
                'status': 'ACTIVE'
            })
            
            # Count pending transactions
            pending_transactions = list(db.transactions.find({
                'user_id': user_id,
                'status': 'PENDING',
                'type': 'RENTAL'
            }))
            pending_count = 0
            for tx in pending_transactions:
                pending_count += len(tx.get('items', []))
            
            total_active = active_rental_count + active_reservation_count + pending_count
            
            if total_active >= Config.MAX_BOOKS_PER_RENTAL:
                return jsonify({
                    'error': f'You have reached the maximum limit of {Config.MAX_BOOKS_PER_RENTAL} books. '
                            f'You currently have {active_rental_count} rented, {active_reservation_count} reserved, '
                            f'and {pending_count} pending checkout. Please return or cancel some books first.'
                }), 400

            # Atomic check and decrement availability
            # This ensures availability is decreased exactly when reservation is made
            if not book_model.adjust_availability(book_id, -1, user_id):
                return jsonify({'error': 'Book is not available for reservation'}), 400
            
            # Fetch book title for notifications and UI
            book = book_model.find_by_id(book_id)
            book_title = book.get('title', 'Unknown Book') if book else 'Unknown Book'

            # Create reservation
            reservation = {
                'user_id': user_id,
                'book_id': book_id,
                'book_title': book_title,
                'reserved_at': datetime.now(),
                'expires_at': datetime.now() + timedelta(hours=Config.RESERVATION_EXPIRY_HOURS),
                'status': 'ACTIVE',
                'picked_up': False,
                'created_at': datetime.now()
            }
            
            result = db.reservations.insert_one(reservation)
            
            return jsonify({
                'success': True,
                'message': 'Book reserved successfully',
                'reservation_id': str(result.inserted_id),
                'expires_at': reservation['expires_at'].isoformat()
            }), 201
            
        except Exception as e:
            return jsonify({'error': str(e)}), 500

    @user_bp.route('/reserve/cancel', methods=['POST'])
    @token_required
    def cancel_reservation():
        """
        Cancel a reservation for a user.
        Increments availability back.
        """
        try:
            data = request.get_json()
            if not data or 'reservation_id' not in data:
                return jsonify({'error': 'Reservation ID is required'}), 400
                
            user_id = ObjectId(request.user_id)
            res_id = ObjectId(data['reservation_id'])
            
            # Find the reservation
            reservation = db.reservations.find_one({
                '_id': res_id,
                'user_id': user_id,
                'status': 'ACTIVE'
            })
            
            if not reservation:
                return jsonify({'error': 'Active reservation not found'}), 404
            
            # 1. Update reservation status
            db.reservations.update_one(
                {'_id': res_id},
                {'$set': {'status': 'CANCELLED', 'cancelled_at': datetime.now()}}
            )
            
            # 2. Increment book availability
            book_id = reservation['book_id']
            book_model.adjust_availability(book_id, 1, user_id)
            
            return jsonify({
                'success': True,
                'message': 'Reservation cancelled successfully'
            }), 200
            
        except Exception as e:
            return jsonify({'error': str(e)}), 500

    return user_bp

